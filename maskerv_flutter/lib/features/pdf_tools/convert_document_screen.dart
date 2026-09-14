import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/how_it_works_carousel.dart';

class ConvertDocumentScreen extends StatefulWidget {
  final String? initialFrom;
  final String? initialTo;

  const ConvertDocumentScreen({super.key, this.initialFrom, this.initialTo});

  @override
  State<ConvertDocumentScreen> createState() => _ConvertDocumentScreenState();
}

class _ConvertDocumentScreenState extends State<ConvertDocumentScreen> {
  File? _selectedFile;
  late String _fromFormat;
  late String _toFormat;
  bool _isProcessing = false;
  File? _convertedResult;

  final List<String> _formats = ['pdf', 'word', 'excel', 'ppt', 'image', 'txt', 'html'];

  @override
  void initState() {
    super.initState();
    _fromFormat = widget.initialFrom ?? 'word';
    _toFormat = widget.initialTo ?? 'pdf';
  }

  Future<void> _pickFile() async {
    HapticFeedback.lightImpact();
    List<String> allowed = [];
    if (_fromFormat == 'pdf') allowed = ['pdf'];
    if (_fromFormat == 'word') allowed = ['doc', 'docx'];
    if (_fromFormat == 'excel') allowed = ['xls', 'xlsx'];
    if (_fromFormat == 'ppt') allowed = ['ppt', 'pptx'];
    if (_fromFormat == 'image') allowed = ['jpg', 'jpeg', 'png', 'webp', 'bmp'];
    if (_fromFormat == 'txt') allowed = ['txt'];
    if (_fromFormat == 'html') allowed = ['html', 'htm'];

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowed,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _convertedResult = null;
      });
    }
  }

  Future<void> _convertDocument() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outName = 'Converted_$timestamp';
      File outputFile;

      if (_fromFormat == 'image' && _toFormat == 'pdf') {
        // Local conversion for image -> PDF
        final pdf = pw.Document();
        final imgBytes = await _selectedFile!.readAsBytes();
        final image = pw.MemoryImage(imgBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: pw_pdf.PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
            },
          ),
        );

        outputFile = File('${_selectedFile!.parent.path}/$outName.pdf');
        await outputFile.writeAsBytes(await pdf.save());
      } else {
        // High-Fidelity backend conversion
        outputFile = await ApiService().convertDocument(
          file: _selectedFile!,
          fromFormat: _fromFormat,
          toFormat: _toFormat,
        );
      }

      final doc = DocumentFile(
        id: 'conv_$timestamp',
        name: outputFile.uri.pathSegments.last,
        path: outputFile.path,
        size: await outputFile.length(),
        modifiedAt: DateTime.now(),
        type: DocumentFile.getTypeFromExtension(_toFormat),
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'convert-document',
                toolName: 'Convert Document (${_fromFormat.toUpperCase()} to ${_toFormat.toUpperCase()})',
                fileName: doc.name,
                outputPath: outputFile.path,
                fileSize: await outputFile.length(),
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _convertedResult = outputFile;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Converted to ${_toFormat.toUpperCase()} successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conversion failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Convert Document',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HowItWorksCarousel(
            toolId: _fromFormat == 'pdf' ? 'pdf-to-word' : 'word-to-pdf',
            padding: const EdgeInsets.only(bottom: 14),
          ),
          // Format Selectors
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DropdownButton<String>(
                  value: _fromFormat,
                  underline: const SizedBox(),
                  items: _formats
                      .map((f) => DropdownMenuItem(value: f, child: Text(f.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _fromFormat = val!;
                      _selectedFile = null;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(LucideIcons.arrowRight, color: AppColors.primary),
                  onPressed: () {
                    setState(() {
                      final temp = _fromFormat;
                      _fromFormat = _toFormat;
                      _toFormat = temp;
                      _selectedFile = null;
                    });
                  },
                ),
                DropdownButton<String>(
                  value: _toFormat,
                  underline: const SizedBox(),
                  items: _formats
                      .map((f) => DropdownMenuItem(value: f, child: Text(f.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))))
                      .toList(),
                  onChanged: (val) => setState(() => _toFormat = val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // File Picker Tile
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              children: [
                if (_selectedFile == null)
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(LucideIcons.filePlus, size: 20),
                      label: Text('Select ${_fromFormat.toUpperCase()} Document'),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.toolGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.fileSpreadsheet, color: AppColors.toolGreen, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _selectedFile!.uri.pathSegments.last,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(onPressed: _pickFile, child: const Text('Change')),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_selectedFile != null)
            ActionButton(
              label: 'Convert ${_fromFormat.toUpperCase()} to ${_toFormat.toUpperCase()}',
              icon: LucideIcons.refreshCw,
              isLoading: _isProcessing,
              onPressed: _convertDocument,
            ),

          if (_convertedResult != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    label: 'Open File',
                    icon: LucideIcons.externalLink,
                    isSecondary: true,
                    onPressed: () => OpenFilex.open(_convertedResult!.path),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionButton(
                    label: 'Share',
                    icon: LucideIcons.share2,
                    isSecondary: true,
                    onPressed: () => Share.shareXFiles([XFile(_convertedResult!.path)]),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
