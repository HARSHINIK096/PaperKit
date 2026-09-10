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

class OrganizePagesScreen extends StatefulWidget {
  const OrganizePagesScreen({super.key});

  @override
  State<OrganizePagesScreen> createState() => _OrganizePagesScreenState();
}

class _OrganizePagesScreenState extends State<OrganizePagesScreen> {
  File? _selectedFile;
  List<int> _pageIndices = [];
  bool _isProcessing = false;
  File? _organizedResult;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);
      final count = doc.pages.count;
      doc.dispose();

      setState(() {
        _selectedFile = file;
        _pageIndices = List.generate(count, (i) => i);
        _organizedResult = null;
      });
    }
  }

  Future<void> _saveOrganizedPdf() async {
    if (_selectedFile == null || _pageIndices.isEmpty) return;
    setState(() => _isProcessing = true);

    try {
      final outputFile = await PdfEngine.organizePages(
        inputFile: _selectedFile!,
        pageOrderZeroIndexed: _pageIndices,
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = outputFile.uri.pathSegments.last;

      final doc = DocumentFile(
        id: 'org_$timestamp',
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
                toolId: 'organize-pages',
                toolName: 'Organize Pages',
                fileName: fileName,
                outputPath: outputFile.path,
                fileSize: await outputFile.length(),
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _organizedResult = outputFile;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pages reorganized and saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reorganize failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Organize Pages',
      showBottomNav: false,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_selectedFile == null)
              Expanded(
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(LucideIcons.filePlus, size: 20),
                    label: const Text('Choose PDF to Organize'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_pageIndices.length} Pages (Drag to reorder)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  TextButton(onPressed: _pickFile, child: const Text('Change File')),
                ],
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ReorderableListView.builder(
                  itemCount: _pageIndices.length,
                  onReorder: (oldIdx, newIdx) {
                    setState(() {
                      if (oldIdx < newIdx) newIdx -= 1;
                      final item = _pageIndices.removeAt(oldIdx);
                      _pageIndices.insert(newIdx, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final pageNum = _pageIndices[index] + 1;
                    return Container(
                      key: ValueKey('page_${_pageIndices[index]}_$index'),
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.toolIndigo.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '#$pageNum',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.toolIndigo,
                              ),
                            ),
                          ),
                        ),
                        title: Text('Page $pageNum', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.copy, size: 18, color: AppColors.primary),
                              tooltip: 'Duplicate Page',
                              onPressed: () {
                                setState(() {
                                  _pageIndices.insert(index + 1, _pageIndices[index]);
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                              tooltip: 'Delete Page',
                              onPressed: () {
                                setState(() {
                                  _pageIndices.removeAt(index);
                                });
                              },
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

              ActionButton(
                label: 'Save Reorganized PDF (${_pageIndices.length} pages)',
                icon: LucideIcons.save,
                isLoading: _isProcessing,
                onPressed: _pageIndices.isNotEmpty ? _saveOrganizedPdf : null,
              ),

              if (_organizedResult != null) ...[
                const SizedBox(height: 10),
                ActionButton(
                  label: 'Open Result',
                  icon: LucideIcons.externalLink,
                  isSecondary: true,
                  onPressed: () => OpenFilex.open(_organizedResult!.path),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
