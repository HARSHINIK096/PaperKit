import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/compact_upload_container.dart';
import '../../core/widgets/how_it_works_carousel.dart';
import '../../core/widgets/markdown_viewer.dart';

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
        throw Exception('MASKERV server did not return a valid summary. Please check your network connection.');
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
          const HowItWorksCarousel(
            toolId: 'ai-summary',
            padding: EdgeInsets.only(bottom: 14),
          ),
          CompactUploadContainer(
            files: _selectedFile != null ? [_selectedFile!] : [],
            title: 'Upload Document to Summarize',
            subtitle: 'Drop PDF, DOCX or TXT for multi-length AI executive brief',
            icon: LucideIcons.sparkles,
            primaryColor: AppColors.toolPurple,
            allowedExtensions: const ['pdf', 'docx', 'txt'],
            useShader: true,
            enabled: !_isProcessing,
            onFilesSelected: (files) {
              if (files.isNotEmpty) {
                setState(() {
                  _selectedFile = files.first;
                  _summaryResult = '';
                });
              }
            },
            onClear: () {
              setState(() {
                _selectedFile = null;
                _summaryResult = '';
              });
            },
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
            MarkdownViewer(
              markdown: _summaryResult,
              title: 'AI Summary (${_summaryLength.toUpperCase()})',
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
