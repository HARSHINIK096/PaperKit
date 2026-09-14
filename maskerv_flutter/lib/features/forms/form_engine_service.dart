import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/models/form_field_model.dart';
import '../../core/services/storage_service.dart';

class FormEngineService {
  final StorageService _storage = StorageService();

  // Detect existing form fields in a PDF
  Future<List<CustomFormField>> detectFormFields(File inputFile) async {
    final bytes = await inputFile.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final List<CustomFormField> detected = [];

    for (int i = 0; i < document.form.fields.count; i++) {
      final field = document.form.fields[i];
      FormFieldType type = FormFieldType.text;
      if (field is PdfCheckBoxField) {
        type = FormFieldType.checkbox;
      } else if (field is PdfRadioButtonListField) {
        type = FormFieldType.radio;
      } else if (field is PdfComboBoxField) {
        type = FormFieldType.dropdown;
      }

      String fieldValue = '';
      if (field is PdfTextBoxField) {
        fieldValue = field.text;
      }

      detected.add(
        CustomFormField(
          id: 'field_${field.name}_$i',
          label: field.name ?? 'Field ${i + 1}',
          type: type,
          pageIndex: 0,
          xRatio: 0.1 + (i * 0.05) % 0.6,
          yRatio: 0.1 + (i * 0.08) % 0.7,
          widthRatio: 0.4,
          heightRatio: 0.04,
          value: fieldValue,
        ),
      );
    }
    document.dispose();
    return detected;
  }

  // Flatten interactive form fields into permanent PDF page content
  Future<File> flattenPdfForm(File inputFile, List<CustomFormField> fields) async {
    final bytes = await inputFile.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    // 1. Flatten native PDF form fields
    if (document.form.fields.count > 0) {
      document.form.flattenAllFields();
    }

    // 2. Render user-placed fields onto target pages
    for (final field in fields) {
      if (field.value.isNotEmpty && field.pageIndex < document.pages.count) {
        final page = document.pages[field.pageIndex];
        final font = PdfStandardFont(PdfFontFamily.helvetica, 11);
        final brush = PdfSolidBrush(PdfColor(0, 0, 0));

        final rect = Rect.fromLTWH(
          field.xRatio * page.size.width,
          field.yRatio * page.size.height,
          field.widthRatio * page.size.width,
          field.heightRatio * page.size.height,
        );

        if (field.type == FormFieldType.checkbox) {
          final isChecked = field.value.toLowerCase() == 'true' || field.value == '1';
          page.graphics.drawString(isChecked ? '[X]' : '[ ]', font, brush: brush, bounds: rect);
        } else {
          page.graphics.drawString(field.value, font, brush: brush, bounds: rect);
        }
      }
    }

    final outputDir = await getApplicationDocumentsDirectory();
    final outputFile = File('${outputDir.path}/flattened_${inputFile.uri.pathSegments.last}');
    await outputFile.writeAsBytes(document.saveSync());
    document.dispose();
    return outputFile;
  }

  // Manage Profiles
  Future<List<UserFormProfile>> loadProfiles() async {
    final rawList = await _storage.getFormProfiles();
    return rawList.map((m) => UserFormProfile.fromJson(m)).toList();
  }

  Future<void> saveProfile(UserFormProfile profile) async {
    final profiles = await loadProfiles();
    profiles.removeWhere((p) => p.id == profile.id);
    profiles.insert(0, profile);
    await _storage.saveFormProfiles(profiles.map((p) => p.toJson()).toList());
  }

  // Auto-fill fields from profile
  List<CustomFormField> autoFillFields(List<CustomFormField> fields, UserFormProfile profile) {
    return fields.map((field) {
      final label = field.label.toLowerCase();
      String newValue = field.value;

      if (label.contains('name') || label.contains('full name')) {
        newValue = profile.fullName;
      } else if (label.contains('email')) {
        newValue = profile.email;
      } else if (label.contains('phone') || label.contains('mobile')) {
        newValue = profile.phone;
      } else if (label.contains('address')) {
        newValue = profile.address;
      } else if (label.contains('institution') || label.contains('school') || label.contains('university')) {
        newValue = profile.institution;
      } else if (label.contains('id') || label.contains('student')) {
        newValue = profile.studentId;
      } else if (profile.customFields.containsKey(field.label)) {
        newValue = profile.customFields[field.label]!;
      }

      return CustomFormField(
        id: field.id,
        label: field.label,
        type: field.type,
        pageIndex: field.pageIndex,
        xRatio: field.xRatio,
        yRatio: field.yRatio,
        widthRatio: field.widthRatio,
        heightRatio: field.heightRatio,
        value: newValue.isNotEmpty ? newValue : field.value,
        options: field.options,
      );
    }).toList();
  }
}
