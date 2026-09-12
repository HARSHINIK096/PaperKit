import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/models/form_field_model.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class FormCreatorScreen extends StatefulWidget {
  const FormCreatorScreen({super.key});

  @override
  State<FormCreatorScreen> createState() => _FormCreatorScreenState();
}

class _FormCreatorScreenState extends State<FormCreatorScreen> {
  final TextEditingController _formTitleController = TextEditingController(text: 'Application Registration Form');
  final List<CustomFormField> _fields = [
    CustomFormField(id: 'f1', label: 'Full Name', type: FormFieldType.text),
    CustomFormField(id: 'f2', label: 'Email Address', type: FormFieldType.text),
    CustomFormField(id: 'f3', label: 'Agree to Terms & Conditions', type: FormFieldType.checkbox),
  ];

  bool _isProcessing = false;
  File? _outputFile;

  void _addField(FormFieldType type) {
    final count = _fields.length + 1;
    final label = type == FormFieldType.text
        ? 'Text Field $count'
        : (type == FormFieldType.checkbox ? 'Checkbox Option $count' : 'Signature Field');

    setState(() {
      _fields.add(CustomFormField(
        id: 'field_${DateTime.now().millisecondsSinceEpoch}',
        label: label,
        type: type,
      ));
    });
  }

  void _removeField(int index) {
    setState(() => _fields.removeAt(index));
  }

  Future<void> _exportPdfForm() async {
    if (_fields.isEmpty) return;
    setState(() => _isProcessing = true);

    try {
      final document = PdfDocument();
      final page = document.pages.add();
      final fontBold = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
      final fontRegular = PdfStandardFont(PdfFontFamily.helvetica, 11);
      final fontSmall = PdfStandardFont(PdfFontFamily.helvetica, 9);

      double y = 20;

      // Form Header Title
      page.graphics.drawString(
        _formTitleController.text.trim(),
        fontBold,
        bounds: Rect.fromLTWH(20, y, page.size.width - 40, 30),
      );
      y += 40;

      // Draw Form Fields
      for (int i = 0; i < _fields.length; i++) {
        final field = _fields[i];

        page.graphics.drawString(
          field.label,
          fontRegular,
          bounds: Rect.fromLTWH(20, y, page.size.width - 40, 20),
        );
        y += 22;

        if (field.type == FormFieldType.text) {
          final textBox = PdfTextBoxField(page, 'field_${i}_text', Rect.fromLTWH(20, y, page.size.width - 40, 26));
          document.form.fields.add(textBox);
          y += 36;
        } else if (field.type == FormFieldType.checkbox) {
          final checkBox = PdfCheckBoxField(page, 'field_${i}_chk', Rect.fromLTWH(20, y, 18, 18));
          document.form.fields.add(checkBox);
          y += 30;
        } else {
          final textBox = PdfTextBoxField(page, 'field_${i}_sig', Rect.fromLTWH(20, y, 220, 45));
          document.form.fields.add(textBox);
          page.graphics.drawString('(Sign inside box)', fontSmall, bounds: Rect.fromLTWH(20, y + 47, 200, 15));
          y += 65;
        }

        if (y > page.size.height - 80) break;
      }

      final outputBytes = document.saveSync();
      document.dispose();

      final tempDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/custom_form_$timestamp.pdf');
      await file.writeAsBytes(outputBytes);

      setState(() {
        _outputFile = file;
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fillable PDF form generated successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Form Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Interactive Form Creator',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _formTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Form Title',
                      prefixIcon: Icon(LucideIcons.fileEdit, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Form Fields', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      PopupMenuButton<FormFieldType>(
                        icon: const Icon(LucideIcons.plusCircle, color: Colors.blue),
                        onSelected: _addField,
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: FormFieldType.text, child: Text('Add Text Field')),
                          PopupMenuItem(value: FormFieldType.checkbox, child: Text('Add Checkbox')),
                          PopupMenuItem(value: FormFieldType.signature, child: Text('Add Signature Box')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _fields.length,
                    onReorder: (oldIdx, newIdx) {
                      setState(() {
                        if (newIdx > oldIdx) newIdx--;
                        final item = _fields.removeAt(oldIdx);
                        _fields.insert(newIdx, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final field = _fields[index];
                      return Card(
                        key: ValueKey(field.id),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            field.type == FormFieldType.text
                                ? LucideIcons.type
                                : (field.type == FormFieldType.checkbox ? LucideIcons.checkSquare : LucideIcons.penTool),
                            size: 20,
                          ),
                          title: Text(field.label),
                          subtitle: Text(field.type.name.toUpperCase()),
                          trailing: IconButton(
                            icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 18),
                            onPressed: () => _removeField(index),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    label: 'Export Fillable PDF Form',
                    icon: LucideIcons.fileCheck,
                    isLoading: _isProcessing,
                    onPressed: _exportPdfForm,
                  ),
                ],
              ),
            ),
          ),
          if (_outputFile != null) ...[
            const SizedBox(height: 16),
            ActionButton(
              label: 'Open Form PDF',
              icon: LucideIcons.externalLink,
              isSecondary: true,
              onPressed: () => OpenFilex.open(_outputFile!.path),
            ),
          ],
        ],
      ),
    );
  }
}
