import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/pdf_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/platform_file_ext.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/how_it_works_carousel.dart';

class SmartRedactionScreen extends StatefulWidget {
  const SmartRedactionScreen({super.key});

  @override
  State<SmartRedactionScreen> createState() => _SmartRedactionScreenState();
}

class _SmartRedactionScreenState extends State<SmartRedactionScreen> {
  File? _selectedFile;
  final TextEditingController _keywordsController = TextEditingController(text: 'SSN, password, confidential, secret');
  bool _redactEmails = true;
  bool _redactPhones = true;
  bool _isProcessing = false;
  File? _redactedResult;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty && result.files.single.hasValidFile) {
      final pf = result.files.single;
      setState(() {
        _selectedFile = pf.asFile ?? File(pf.name);
        _redactedResult = null;
      });
    }
  }

  Future<void> _applyRedaction() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final keywords = _keywordsController.text
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty)
          .toList();

      final outputFile = await PdfEngine.smartRedactPdf(
        inputFile: _selectedFile!,
        keywords: keywords,
        redactEmails: _redactEmails,
        redactPhones: _redactPhones,
      );

      final doc = DocumentFile(
        id: 'redact_$timestamp',
        name: outputFile.uri.pathSegments.last,
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
                toolId: 'smart-redaction',
                toolName: 'Redact Data',
                fileName: doc.name,
                outputPath: outputFile.path,
                fileSize: await outputFile.length(),
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _redactedResult = outputFile;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sensitive data permanently redacted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Redaction failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Smart Redaction',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HowItWorksCarousel(
            toolId: 'smart-redaction',
            padding: EdgeInsets.only(bottom: 14),
          ),
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
                          color: AppColors.toolOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.eyeOff, color: AppColors.toolOrange, size: 24),
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
              'Redaction Settings',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _keywordsController,
              decoration: const InputDecoration(
                labelText: 'Target Keywords (comma-separated)',
                hintText: 'e.g. SSN, credit card, confidential',
                prefixIcon: Icon(LucideIcons.search, size: 18),
              ),
            ),
            const SizedBox(height: 12),

            CheckboxListTile(
              title: const Text('Auto-detect Email Addresses', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              value: _redactEmails,
              onChanged: (val) => setState(() => _redactEmails = val!),
            ),
            CheckboxListTile(
              title: const Text('Auto-detect Phone & Identity Numbers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              value: _redactPhones,
              onChanged: (val) => setState(() => _redactPhones = val!),
            ),
            const SizedBox(height: 24),

            ActionButton(
              label: 'Permanently Blackout Data',
              icon: LucideIcons.eyeOff,
              isDanger: true,
              isLoading: _isProcessing,
              onPressed: _applyRedaction,
            ),
          ],

          if (_redactedResult != null) ...[
            const SizedBox(height: 20),
            ActionButton(
              label: 'Open Redacted PDF',
              icon: LucideIcons.externalLink,
              isSecondary: true,
              onPressed: () => OpenFilex.open(_redactedResult!.path),
            ),
          ],
        ],
      ),
    );
  }
}
