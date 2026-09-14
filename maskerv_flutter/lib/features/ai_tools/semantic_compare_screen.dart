import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class SemanticCompareScreen extends StatefulWidget {
  const SemanticCompareScreen({super.key});

  @override
  State<SemanticCompareScreen> createState() => _SemanticCompareScreenState();
}

class _SemanticCompareScreenState extends State<SemanticCompareScreen> {
  File? _fileA;
  File? _fileB;
  bool _isProcessing = false;
  Map<String, dynamic>? _compareResult;

  Future<void> _pickFile(bool isFileA) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        if (isFileA) {
          _fileA = File(result.files.single.path!);
        } else {
          _fileB = File(result.files.single.path!);
        }
        _compareResult = null;
      });
    }
  }

  Future<void> _runCompare() async {
    if (_fileA == null || _fileB == null) return;
    setState(() => _isProcessing = true);

    try {
      final result = await ApiService().compareDocuments(
        fileA: _fileA!,
        fileB: _fileB!,
      );

      setState(() {
        _compareResult = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Comparison failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Semantic Compare',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _buildFilePickerBox('Document A (Original)', _fileA, () => _pickFile(true), isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildFilePickerBox('Document B (Modified)', _fileB, () => _pickFile(false), isDark)),
            ],
          ),
          const SizedBox(height: 24),

          ActionButton(
            label: 'Run Semantic AI Comparison',
            icon: LucideIcons.gitCompare,
            isLoading: _isProcessing,
            onPressed: (_fileA != null && _fileB != null) ? _runCompare : null,
          ),

          if (_compareResult != null) ...[
            const SizedBox(height: 24),
            // Similarity Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryBorder),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.percent, color: AppColors.primary, size: 24),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Semantic Match Score', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(
                        '${_compareResult!['similarity_score']}% Semantic Alignment',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary Differences
            Text('Differences Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Text(
                _compareResult!['summary_differences'] ?? '',
                style: TextStyle(fontSize: 13.5, height: 1.45, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
            const SizedBox(height: 16),

            // Key changes list
            Text('Key Detected Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            const SizedBox(height: 8),
            ...?(_compareResult!['key_changes'] as List?)?.map(
              (c) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.checkCircle2, size: 16, color: AppColors.toolPurple),
                    const SizedBox(width: 10),
                    Expanded(child: Text(c.toString(), style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilePickerBox(String title, File? file, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(
          children: [
            Icon(file != null ? LucideIcons.fileCheck : LucideIcons.filePlus, color: file != null ? AppColors.success : AppColors.primary, size: 26),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              file != null ? file.uri.pathSegments.last : 'Tap to select',
              style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
