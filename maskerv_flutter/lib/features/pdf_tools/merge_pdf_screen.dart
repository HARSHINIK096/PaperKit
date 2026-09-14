import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/pdf_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/tool_flow_scaffold.dart';

class MergePDFScreen extends StatefulWidget {
  const MergePDFScreen({super.key});

  @override
  State<MergePDFScreen> createState() => _MergePDFScreenState();
}

class _MergePDFScreenState extends State<MergePDFScreen> {
  final List<File> _selectedFiles = [];
  String _outputName = 'Merged_Document';

  Future<void> _pickFiles() async {
    HapticFeedback.lightImpact();
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

  Future<File?> _executeMerge() async {
    if (_selectedFiles.length < 2) {
      throw Exception('Please select at least 2 PDF files to merge.');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = _outputName.trim().isEmpty ? 'Merged_$timestamp' : '${_outputName.trim()}_$timestamp';
    final outputFile = await PdfEngine.mergePdfFiles(_selectedFiles, sanitizedName);
    final fileSize = await outputFile.length();

    final doc = DocumentFile(
      id: 'merged_$timestamp',
      name: '$sanitizedName.pdf',
      path: outputFile.path,
      size: fileSize,
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
              fileName: '$sanitizedName.pdf',
              outputPath: outputFile.path,
              fileSize: fileSize,
              timestamp: DateTime.now(),
            ),
          );
    }

    return outputFile;
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2563EB); // Royal Blue

    return ToolFlowScaffold(
      title: 'Merge PDF',
      toolId: 'merge-pdf',
      primaryColor: primaryColor,
      toolIcon: LucideIcons.layers,
      processingMessage: 'Merging ${_selectedFiles.length} PDF documents...',
      canProceedToEdition: _selectedFiles.length >= 2,
      onProcess: _executeMerge,
      onReset: () {
        setState(() {
          _selectedFiles.clear();
          _outputName = 'Merged_Document';
        });
      },
      // ── Step 1: Upload Widget ──
      uploadWidget: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.files, size: 36, color: primaryColor),
            ),
            const SizedBox(height: 14),
            const Text(
              'Select PDF Files to Merge',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose two or more PDF files from your device.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(
                _selectedFiles.isEmpty
                    ? 'Choose Files'
                    : 'Add More Files (${_selectedFiles.length} selected)',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            if (_selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedFiles.length,
                itemBuilder: (context, index) {
                  final f = _selectedFiles[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${index + 1}.',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: primaryColor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f.uri.pathSegments.last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                          onPressed: () => setState(() => _selectedFiles.removeAt(index)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),

      // ── Step 2: Edition Widget ──
      editionWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reorder & Configure Sequence',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          const Text(
            'Drag and drop files to rearrange page merge sequence:',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          // Reorderable list of selected files
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedFiles.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) newIndex -= 1;
                final item = _selectedFiles.removeAt(oldIndex);
                _selectedFiles.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final f = _selectedFiles[index];
              return Container(
                key: ValueKey(f.path),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  title: Text(
                    f.uri.pathSegments.last,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(LucideIcons.gripVertical, size: 18, color: Color(0xFF94A3B8)),
                ),
              ),
            );
            },
          ),
          const SizedBox(height: 16),

          // Output Filename
          TextField(
            onChanged: (val) => _outputName = val,
            decoration: InputDecoration(
              labelText: 'Output Filename',
              hintText: 'Merged_Document',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(LucideIcons.fileSignature, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
