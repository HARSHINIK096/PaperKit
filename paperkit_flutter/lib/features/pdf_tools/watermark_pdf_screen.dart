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
import '../../core/widgets/tool_flow_scaffold.dart';

class WatermarkPDFScreen extends StatefulWidget {
  const WatermarkPDFScreen({super.key});

  @override
  State<WatermarkPDFScreen> createState() => _WatermarkPDFScreenState();
}

class _WatermarkPDFScreenState extends State<WatermarkPDFScreen> {
  File? _selectedFile;
  final TextEditingController _watermarkController = TextEditingController(text: 'CONFIDENTIAL');
  double _opacity = 0.3;
  double _fontSize = 40;
  double _angle = -45;

  @override
  void dispose() {
    _watermarkController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    HapticFeedback.lightImpact();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<File?> _executeWatermark() async {
    final text = _watermarkController.text.trim();
    if (_selectedFile == null || text.isEmpty) {
      throw Exception('Please specify watermark text.');
    }

    final outputFile = await PdfEngine.addWatermark(
      inputFile: _selectedFile!,
      watermarkText: text,
      opacity: _opacity,
      fontSize: _fontSize,
      angle: _angle,
    );

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = outputFile.uri.pathSegments.last;
    final fileSize = await outputFile.length();

    final doc = DocumentFile(
      id: 'wm_$timestamp',
      name: fileName,
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
              toolId: 'watermark',
              toolName: 'Watermark PDF',
              fileName: fileName,
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
    const primaryColor = Color(0xFF0D9488); // Teal

    return ToolFlowScaffold(
      title: 'Watermark PDF',
      toolId: 'watermark',
      primaryColor: primaryColor,
      toolIcon: LucideIcons.stamp,
      processingMessage: 'Applying custom watermark to PDF pages...',
      canProceedToEdition: _selectedFile != null,
      onProcess: _executeWatermark,
      onReset: () {
        setState(() {
          _selectedFile = null;
          _watermarkController.text = 'CONFIDENTIAL';
          _opacity = 0.3;
          _fontSize = 40;
          _angle = -45;
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
                color: Color(0xFFF0FDFA),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.stamp, size: 36, color: primaryColor),
            ),
            const SizedBox(height: 14),
            const Text(
              'Select PDF to Watermark',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            const SizedBox(height: 6),
            const Text(
              'Stamp text watermarks, draft notices, or custom logos.',
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
                    const Icon(LucideIcons.fileCheck, color: primaryColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedFile!.uri.pathSegments.last,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
            'Configure Watermark Stamp',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _watermarkController,
            decoration: InputDecoration(
              labelText: 'Watermark Text',
              hintText: 'e.g. CONFIDENTIAL, DRAFT, SAMPLE',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(LucideIcons.type, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 18),

          // Opacity Slider
          Text(
            'Opacity: ${(_opacity * 100).toInt()}%',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          Slider(
            value: _opacity,
            min: 0.1,
            max: 0.9,
            divisions: 8,
            activeColor: primaryColor,
            onChanged: (val) => setState(() => _opacity = val),
          ),
          const SizedBox(height: 10),

          // Font Size Slider
          Text(
            'Font Size: ${_fontSize.toInt()} pt',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          Slider(
            value: _fontSize,
            min: 20,
            max: 80,
            divisions: 12,
            activeColor: primaryColor,
            onChanged: (val) => setState(() => _fontSize = val),
          ),
          const SizedBox(height: 14),

          // Live Watermark Preview Card
          const Text(
            'Live Preview',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          const SizedBox(height: 8),
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Simulated Document page lines
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(height: 6, width: 80, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(3))),
                      Container(height: 4, width: 220, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(2))),
                      Container(height: 4, width: 180, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(2))),
                      Container(height: 4, width: 140, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(2))),
                    ],
                  ),
                ),
                // Rotated Watermark Stamp
                Transform.rotate(
                  angle: _angle * (3.14159265359 / 180),
                  child: Text(
                    _watermarkController.text.trim().isEmpty ? 'WATERMARK' : _watermarkController.text.trim(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: (_fontSize * 0.45).clamp(12.0, 32.0),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: primaryColor.withOpacity(_opacity),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
