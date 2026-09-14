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

class ExtractPagesScreen extends StatefulWidget {
  const ExtractPagesScreen({super.key});

  @override
  State<ExtractPagesScreen> createState() => _ExtractPagesScreenState();
}

class _ExtractPagesScreenState extends State<ExtractPagesScreen> {
  File? _selectedFile;
  int _totalPages = 0;
  final Set<int> _selectedPages = {};
  bool _isProcessing = false;
  File? _extractedResult;

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
        _totalPages = count;
        _selectedPages.clear();
        _extractedResult = null;
      });
    }
  }

  Future<void> _extractSelected() async {
    if (_selectedFile == null || _selectedPages.isEmpty) return;
    setState(() => _isProcessing = true);

    try {
      final sortedList = _selectedPages.toList()..sort();
      final outputFile = await PdfEngine.organizePages(
        inputFile: _selectedFile!,
        pageOrderZeroIndexed: sortedList,
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Extracted_${_selectedPages.length}_pages_$timestamp.pdf';

      final doc = DocumentFile(
        id: 'ext_$timestamp',
        name: fileName,
        path: outputFile.path,
        size: await outputFile.length(),
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.pdf,
        pageCount: _selectedPages.length,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'extract-pages',
                toolName: 'Extract Pages',
                fileName: fileName,
                outputPath: outputFile.path,
                fileSize: await outputFile.length(),
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _extractedResult = outputFile;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extracted ${_selectedPages.length} pages to new PDF!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extraction failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Extract Pages',
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
                    label: const Text('Choose PDF to Extract Pages'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(18)),
                  ),
                ),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected ${_selectedPages.length} / $_totalPages pages',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            if (_selectedPages.length == _totalPages) {
                              _selectedPages.clear();
                            } else {
                              _selectedPages.addAll(List.generate(_totalPages, (i) => i));
                            }
                          });
                        },
                        child: Text(_selectedPages.length == _totalPages ? 'Deselect All' : 'Select All'),
                      ),
                      TextButton(onPressed: _pickFile, child: const Text('Change')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Expanded(
                child: GridView.builder(
                  itemCount: _totalPages,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedPages.contains(index);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedPages.remove(index);
                          } else {
                            _selectedPages.add(index);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.15)
                              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                              color: isSelected ? AppColors.primary : AppColors.textMutedLight,
                              size: 26,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Page ${index + 1}',
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              ActionButton(
                label: 'Extract (${_selectedPages.length} pages)',
                icon: LucideIcons.fileOutput,
                isLoading: _isProcessing,
                onPressed: _selectedPages.isNotEmpty ? _extractSelected : null,
              ),

              if (_extractedResult != null) ...[
                const SizedBox(height: 10),
                ActionButton(
                  label: 'Open Extracted PDF',
                  icon: LucideIcons.externalLink,
                  isSecondary: true,
                  onPressed: () => OpenFilex.open(_extractedResult!.path),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
