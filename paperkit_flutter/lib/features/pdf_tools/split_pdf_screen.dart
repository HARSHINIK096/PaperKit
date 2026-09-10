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

class SplitPDFScreen extends StatefulWidget {
  const SplitPDFScreen({super.key});

  @override
  State<SplitPDFScreen> createState() => _SplitPDFScreenState();
}

class _SplitPDFScreenState extends State<SplitPDFScreen> {
  File? _selectedFile;
  int _totalPages = 0;
  bool _splitAllSingle = true;
  String _customRanges = '1-2, 3-5';
  bool _isProcessing = false;
  List<File> _splitResults = [];

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
        _splitResults.clear();
      });
    }
  }

  Future<void> _splitPdf() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      List<List<int>> ranges = [];
      if (_splitAllSingle) {
        for (int i = 0; i < _totalPages; i++) {
          ranges.add([i]);
        }
      } else {
        // Parse custom ranges e.g. "1-2, 3-5"
        final parts = _customRanges.split(',');
        for (final p in parts) {
          final trimmed = p.trim();
          if (trimmed.contains('-')) {
            final nums = trimmed.split('-');
            final start = (int.tryParse(nums[0].trim()) ?? 1) - 1;
            final end = (int.tryParse(nums[1].trim()) ?? _totalPages) - 1;
            final r = <int>[];
            for (int i = start; i <= end; i++) {
              if (i >= 0 && i < _totalPages) r.add(i);
            }
            if (r.isNotEmpty) ranges.add(r);
          } else {
            final page = (int.tryParse(trimmed) ?? 1) - 1;
            if (page >= 0 && page < _totalPages) ranges.add([page]);
          }
        }
      }

      final files = await PdfEngine.splitPdf(_selectedFile!, ranges);
      final filesProv = context.read<FilesProvider>();
      final histProv = context.read<HistoryProvider>();

      for (final f in files) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final name = f.uri.pathSegments.last;
        await filesProv.addFile(
          DocumentFile(
            id: 'split_$timestamp',
            name: name,
            path: f.path,
            size: await f.length(),
            modifiedAt: DateTime.now(),
            type: FileTypeCategory.pdf,
          ),
        );
        await histProv.addRecord(
          HistoryItem(
            id: 'hist_$timestamp',
            toolId: 'split-pdf',
            toolName: 'Split PDF',
            fileName: name,
            outputPath: f.path,
            fileSize: await f.length(),
            timestamp: DateTime.now(),
          ),
        );
      }

      setState(() {
        _splitResults = files;
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Split into ${files.length} parts successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Split failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Split PDF',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Select File Tile
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          color: AppColors.toolRed.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.fileText, color: AppColors.toolRed, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile!.uri.pathSegments.last,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_totalPages total pages',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
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
              'Split Mode',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),

            RadioListTile<bool>(
              title: const Text('Extract Every Single Page', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('Creates $_totalPages separate single-page PDF documents', style: const TextStyle(fontSize: 12)),
              value: true,
              groupValue: _splitAllSingle,
              onChanged: (val) => setState(() => _splitAllSingle = val!),
            ),
            RadioListTile<bool>(
              title: const Text('Custom Page Ranges', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Split by specified page ranges (e.g. 1-3, 4-7)', style: TextStyle(fontSize: 12)),
              value: false,
              groupValue: _splitAllSingle,
              onChanged: (val) => setState(() => _splitAllSingle = val!),
            ),

            if (!_splitAllSingle) ...[
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Page Ranges',
                  hintText: 'e.g. 1-2, 3-5',
                ),
                onChanged: (val) => _customRanges = val,
              ),
            ],

            const SizedBox(height: 24),
            ActionButton(
              label: 'Split Document',
              icon: LucideIcons.scissors,
              isLoading: _isProcessing,
              onPressed: _splitPdf,
            ),
          ],

          if (_splitResults.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Generated Files (${_splitResults.length})',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),
            ..._splitResults.map(
              (f) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: ListTile(
                  leading: const Icon(LucideIcons.fileCheck, color: AppColors.success),
                  title: Text(f.uri.pathSegments.last, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                  trailing: const Icon(LucideIcons.externalLink, size: 16),
                  onTap: () => OpenFilex.open(f.path),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
