import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/pdf_engine.dart';
import '../../core/widgets/tool_flow_scaffold.dart';

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
  List<File> _splitResults = [];

  Future<void> _pickFile() async {
    HapticFeedback.lightImpact();
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

  Future<File?> _executeSplit() async {
    if (_selectedFile == null) return null;

    List<List<int>> ranges = [];
    if (_splitAllSingle) {
      for (int i = 0; i < _totalPages; i++) {
        ranges.add([i]);
      }
    } else {
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
    });

    return files.isNotEmpty ? files.first : null;
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFEF4444); // Red/Coral

    return ToolFlowScaffold(
      title: 'Split PDF',
      toolId: 'split-pdf',
      primaryColor: primaryColor,
      toolIcon: LucideIcons.scissors,
      processingMessage: 'Splitting document into ${_splitAllSingle ? '$_totalPages pages' : 'ranges'}...',
      canProceedToEdition: _selectedFile != null,
      onProcess: _executeSplit,
      onReset: () {
        setState(() {
          _selectedFile = null;
          _totalPages = 0;
          _splitResults.clear();
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
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.scissors, size: 36, color: primaryColor),
            ),
            const SizedBox(height: 14),
            const Text(
              'Select PDF to Split',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            const SizedBox(height: 6),
            const Text(
              'Extract specific page ranges or burst all pages individually.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(LucideIcons.filePlus, size: 18),
              label: Text(
                _selectedFile == null ? 'Choose PDF File' : 'Change Selected PDF',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            if (_selectedFile != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.fileText, color: primaryColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFile!.uri.pathSegments.last,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_totalPages total pages detected',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
            'Select Split Strategy',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          const SizedBox(height: 14),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                RadioListTile<bool>(
                  title: const Text(
                    'Extract Every Single Page',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Creates $_totalPages separate single-page PDF files',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  activeColor: primaryColor,
                  value: true,
                  groupValue: _splitAllSingle,
                  onChanged: (val) => setState(() => _splitAllSingle = val!),
                ),
                const Divider(height: 1),
                RadioListTile<bool>(
                  title: const Text(
                    'Custom Page Ranges',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Segment by specified intervals (e.g. 1-2, 3-5)',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  activeColor: primaryColor,
                  value: false,
                  groupValue: _splitAllSingle,
                  onChanged: (val) => setState(() => _splitAllSingle = val!),
                ),
              ],
            ),
          ),

          if (!_splitAllSingle) ...[
            const SizedBox(height: 14),
            TextField(
              decoration: InputDecoration(
                labelText: 'Enter Custom Ranges (e.g. 1-2, 3-5)',
                hintText: '1-2, 3-$_totalPages',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(LucideIcons.sliders, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => _customRanges = val,
            ),
          ],
        ],
      ),
    );
  }
}
