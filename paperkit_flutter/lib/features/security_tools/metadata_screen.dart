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
import '../../core/services/pdf_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class MetadataScreen extends StatefulWidget {
  const MetadataScreen({super.key});

  @override
  State<MetadataScreen> createState() => _MetadataScreenState();
}

class _MetadataScreenState extends State<MetadataScreen> {
  File? _selectedFile;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _keywordsController = TextEditingController();
  bool _isProcessing = false;
  File? _savedResult;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);
      final info = doc.documentInformation;

      setState(() {
        _selectedFile = file;
        _titleController.text = info.title;
        _authorController.text = info.author;
        _subjectController.text = info.subject;
        _keywordsController.text = info.keywords;
        _savedResult = null;
      });
      doc.dispose();
    }
  }

  Future<void> _saveMetadata() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      final outputFile = await PdfEngine.updateMetadata(
        inputFile: _selectedFile!,
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        subject: _subjectController.text.trim(),
        keywords: _keywordsController.text.trim(),
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = outputFile.uri.pathSegments.last;

      final doc = DocumentFile(
        id: 'meta_$timestamp',
        name: fileName,
        path: outputFile.path,
        size: await outputFile.length(),
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.pdf,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'metadata-manager',
                toolName: 'Metadata Manager',
                fileName: fileName,
                outputPath: outputFile.path,
                fileSize: await outputFile.length(),
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _savedResult = outputFile;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document metadata updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  void _sanitizeAll() {
    setState(() {
      _titleController.clear();
      _authorController.clear();
      _subjectController.clear();
      _keywordsController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Metadata Manager',
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
                          color: AppColors.toolBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.info, color: AppColors.toolBlue, size: 24),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Document Properties',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                TextButton.icon(
                  onPressed: _sanitizeAll,
                  icon: const Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.toolOrange),
                  label: const Text('Wipe All (Sanitize)', style: TextStyle(color: AppColors.toolOrange)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(LucideIcons.type, size: 18)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(labelText: 'Author / Organization', prefixIcon: Icon(LucideIcons.user, size: 18)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Subject', prefixIcon: Icon(LucideIcons.tag, size: 18)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _keywordsController,
              decoration: const InputDecoration(labelText: 'Keywords', prefixIcon: Icon(LucideIcons.hash, size: 18)),
            ),
            const SizedBox(height: 24),

            ActionButton(
              label: 'Save & Sanitize Metadata',
              icon: LucideIcons.save,
              isLoading: _isProcessing,
              onPressed: _saveMetadata,
            ),
          ],

          if (_savedResult != null) ...[
            const SizedBox(height: 20),
            ActionButton(
              label: 'Open Cleaned PDF',
              icon: LucideIcons.externalLink,
              isSecondary: true,
              onPressed: () => OpenFilex.open(_savedResult!.path),
            ),
          ],
        ],
      ),
    );
  }
}
