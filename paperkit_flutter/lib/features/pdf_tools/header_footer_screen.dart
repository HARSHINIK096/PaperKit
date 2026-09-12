import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class HeaderFooterScreen extends StatefulWidget {
  const HeaderFooterScreen({super.key});

  @override
  State<HeaderFooterScreen> createState() => _HeaderFooterScreenState();
}

class _HeaderFooterScreenState extends State<HeaderFooterScreen> {
  File? _selectedFile;
  final TextEditingController _headerController = TextEditingController(text: 'CONFIDENTIAL DOCUMENT');
  final TextEditingController _footerController = TextEditingController(text: 'Page {page} of {total}');
  double _fontSize = 10.0;
  bool _isProcessing = false;
  File? _outputFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _outputFile = null;
      });
    }
  }

  Future<void> _applyHeaderFooter() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      final bytes = await _selectedFile!.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final font = PdfStandardFont(PdfFontFamily.helvetica, _fontSize);
      final brush = PdfSolidBrush(PdfColor(100, 100, 100));

      final headerText = _headerController.text.trim();
      final footerTemplate = _footerController.text.trim();
      final totalPages = document.pages.count;

      for (int i = 0; i < totalPages; i++) {
        final page = document.pages[i];
        final pageSize = page.size;

        if (headerText.isNotEmpty) {
          page.graphics.drawString(
            headerText,
            font,
            brush: brush,
            bounds: Rect.fromLTWH(20, 10, pageSize.width - 40, 20),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
        }

        if (footerTemplate.isNotEmpty) {
          final footerText = footerTemplate
              .replaceAll('{page}', '${i + 1}')
              .replaceAll('{total}', '$totalPages');

          page.graphics.drawString(
            footerText,
            font,
            brush: brush,
            bounds: Rect.fromLTWH(20, pageSize.height - 25, pageSize.width - 40, 20),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
        }
      }

      final outputBytes = document.saveSync();
      document.dispose();

      final tempDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/header_footer_$timestamp.pdf');
      await file.writeAsBytes(outputBytes);

      setState(() {
        _outputFile = file;
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Header & Footer applied successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Header/Footer Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'PDF Headers & Footers',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_selectedFile == null)
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(LucideIcons.filePlus),
                      label: const Text('Choose PDF Document'),
                    )
                  else ...[
                    Row(
                      children: [
                        const Icon(LucideIcons.fileText, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_selectedFile!.uri.pathSegments.last, style: const TextStyle(fontWeight: FontWeight.bold))),
                        TextButton(onPressed: _pickFile, child: const Text('Change')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _headerController,
                      decoration: const InputDecoration(
                        labelText: 'Header Text',
                        hintText: 'e.g. CONFIDENTIAL',
                        prefixIcon: Icon(LucideIcons.panelTop, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _footerController,
                      decoration: const InputDecoration(
                        labelText: 'Footer Text / Page Template',
                        hintText: 'e.g. Page {page} of {total}',
                        prefixIcon: Icon(LucideIcons.panelBottom, size: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ActionButton(
                      label: 'Apply Header & Footer',
                      icon: LucideIcons.check,
                      isLoading: _isProcessing,
                      onPressed: _applyHeaderFooter,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_outputFile != null) ...[
            const SizedBox(height: 16),
            ActionButton(
              label: 'Open Stamp PDF',
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
