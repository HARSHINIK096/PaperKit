import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class PDFToPDFAScreen extends StatefulWidget {
  const PDFToPDFAScreen({super.key});

  @override
  State<PDFToPDFAScreen> createState() => _PDFToPDFAScreenState();
}

class _PDFToPDFAScreenState extends State<PDFToPDFAScreen> {
  File? _selectedFile;
  String _conformance = 'PDF/A-1b'; // 'PDF/A-1b', 'PDF/A-2b', 'PDF/A-3b'
  bool _isProcessing = false;
  File? _pdfaResult;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _pdfaResult = null;
      });
    }
  }

  Future<void> _convertToPdfA() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      final bytes = await _selectedFile!.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outName = 'PDFA_${_selectedFile!.uri.pathSegments.last}';
      final outPath = '${_selectedFile!.parent.path}/$outName';
      final outFile = File(outPath);
      await outFile.writeAsBytes(document.saveSync());
      document.dispose();

      final doc = DocumentFile(
        id: 'pdfa_$timestamp',
        name: outName,
        path: outFile.path,
        size: await outFile.length(),
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.pdf,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'pdf-to-pdfa',
                toolName: 'PDF to PDF/A',
                fileName: outName,
                outputPath: outFile.path,
                fileSize: await outFile.length(),
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _pdfaResult = outFile;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Converted to $_conformance archival standard!')),
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
      title: 'PDF to PDF/A',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                      label: const Text('Choose PDF Document'),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.toolPurple.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.archive, color: AppColors.toolPurple, size: 24),
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
          const SizedBox(height: 20),

          if (_selectedFile != null) ...[
            Text(
              'Archival ISO Conformance',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),

            _buildConformanceTile('PDF/A-1b', 'Standard ISO 19005-1 (Long-term preservation)', isDark),
            _buildConformanceTile('PDF/A-2b', 'ISO 19005-2 (Supports JPEG 2000 & transparency)', isDark),
            _buildConformanceTile('PDF/A-3b', 'ISO 19005-3 (Embedded file attachments permitted)', isDark),

            const SizedBox(height: 24),
            ActionButton(
              label: 'Convert to Archival PDF/A',
              icon: LucideIcons.archive,
              isLoading: _isProcessing,
              onPressed: _convertToPdfA,
            ),
          ],

          if (_pdfaResult != null) ...[
            const SizedBox(height: 20),
            ActionButton(
              label: 'Open Archival PDF/A',
              icon: LucideIcons.externalLink,
              isSecondary: true,
              onPressed: () => OpenFilex.open(_pdfaResult!.path),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConformanceTile(String standard, String desc, bool isDark) {
    return RadioListTile<String>(
      title: Text(standard, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
      value: standard,
      groupValue: _conformance,
      onChanged: (val) => setState(() => _conformance = val!),
    );
  }
}
