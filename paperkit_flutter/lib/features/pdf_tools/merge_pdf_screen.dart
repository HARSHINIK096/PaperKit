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
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class MergePDFScreen extends StatefulWidget {
  const MergePDFScreen({super.key});

  @override
  State<MergePDFScreen> createState() => _MergePDFScreenState();
}

class _MergePDFScreenState extends State<MergePDFScreen> {
  final List<File> _selectedFiles = [];
  bool _isProcessing = false;
  File? _mergedResult;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        for (final p in result.paths) {
          if (p != null) _selectedFiles.add(File(p));
        }
      });
    }
  }

  Future<void> _mergeFiles() async {
    if (_selectedFiles.length < 2) return;

    setState(() => _isProcessing = true);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Merged_$timestamp';
      final outputFile = await PdfEngine.mergePdfFiles(_selectedFiles, fileName);

      final doc = DocumentFile(
        id: 'merged_$timestamp',
        name: '$fileName.pdf',
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
                toolId: 'merge-pdf',
                toolName: 'Merge PDF',
                fileName: '$fileName.pdf',
                outputPath: outputFile.path,
                fileSize: await outputFile.length(),
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _mergedResult = outputFile;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully merged ${_selectedFiles.length} files!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Merge failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Merge PDF',
      showBottomNav: false,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Instructions
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.primaryBorder,
                ),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.info, color: AppColors.primary, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select two or more PDF documents to merge into a single unified file.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Files List or Add Prompt
            Expanded(
              child: _selectedFiles.isEmpty
                  ? Center(
                      child: OutlinedButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(LucideIcons.plus, size: 20),
                        label: const Text('Add PDF Documents'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      itemCount: _selectedFiles.length,
                      onReorder: (oldIdx, newIdx) {
                        setState(() {
                          if (oldIdx < newIdx) newIdx -= 1;
                          final item = _selectedFiles.removeAt(oldIdx);
                          _selectedFiles.insert(newIdx, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        final name = file.uri.pathSegments.last;

                        return Container(
                          key: ValueKey(file.path),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.toolBlue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.toolBlue,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                                  onPressed: () => setState(() => _selectedFiles.removeAt(index)),
                                ),
                                const Icon(LucideIcons.gripVertical, size: 18, color: AppColors.textMutedLight),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            // Controls
            if (_selectedFiles.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      label: 'Add More',
                      icon: LucideIcons.plus,
                      isSecondary: true,
                      onPressed: _pickFiles,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ActionButton(
                      label: 'Merge (${_selectedFiles.length})',
                      icon: LucideIcons.files,
                      isLoading: _isProcessing,
                      onPressed: _selectedFiles.length >= 2 ? _mergeFiles : null,
                    ),
                  ),
                ],
              ),
            ],
            if (_mergedResult != null) ...[
              const SizedBox(height: 12),
              ActionButton(
                label: 'Open Merged PDF',
                icon: LucideIcons.externalLink,
                isSecondary: true,
                onPressed: () => OpenFilex.open(_mergedResult!.path),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
