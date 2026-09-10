import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class SummarizePDFScreen extends StatefulWidget {
  const SummarizePDFScreen({super.key});

  @override
  State<SummarizePDFScreen> createState() => _SummarizePDFScreenState();
}

class _SummarizePDFScreenState extends State<SummarizePDFScreen> {
  File? _selectedFile;
  String _summaryLength = 'detailed'; // 'concise', 'detailed', 'bullets', 'actions'
  bool _isProcessing = false;
  String _summaryResult = '';

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _summaryResult = '';
      });
    }
  }

  Future<void> _generateSummary() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      final res = await ApiService().summarizePDF(
        file: _selectedFile!,
        mode: _summaryLength,
      );
      final summary = res['summary'] ?? res['result'] ?? '';
      if (summary.trim().isEmpty) {
        throw Exception('PaperKit server did not return a valid summary. Please check your network connection.');
      }

      if (mounted) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'summarize-pdf',
                toolName: 'AI Summary ($_summaryLength)',
                fileName: _selectedFile!.uri.pathSegments.last,
                fileSize: await _selectedFile!.length(),
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _summaryResult = summary;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Summary generated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Summarization failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'AI Document Summary',
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
                      icon: const Icon(LucideIcons.fileText, size: 20),
                      label: const Text('Choose Document to Summarize'),
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
                        child: const Icon(LucideIcons.sparkles, color: AppColors.toolPurple, size: 24),
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
              'Summary Style',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              children: [
                _buildStyleChip('Detailed Overview', 'detailed'),
                _buildStyleChip('Concise (Short)', 'concise'),
                _buildStyleChip('Key Bullets', 'bullets'),
                _buildStyleChip('Action Items', 'actions'),
              ],
            ),
            const SizedBox(height: 24),

            ActionButton(
              label: 'Generate AI Summary',
              icon: LucideIcons.sparkles,
              isLoading: _isProcessing,
              onPressed: _generateSummary,
            ),
          ],

          if (_summaryResult.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Summary Result',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _summaryResult));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Summary copied to clipboard!')),
                    );
                  },
                  icon: const Icon(LucideIcons.copy, size: 16),
                  label: const Text('Copy'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: SelectableText(
                _summaryResult,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStyleChip(String label, String value) {
    final isSelected = _summaryLength == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (_) => setState(() => _summaryLength = value),
    );
  }
}
