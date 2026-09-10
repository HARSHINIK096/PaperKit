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

class RotatePDFScreen extends StatefulWidget {
  const RotatePDFScreen({super.key});

  @override
  State<RotatePDFScreen> createState() => _RotatePDFScreenState();
}

class _RotatePDFScreenState extends State<RotatePDFScreen> {
  File? _selectedFile;
  int _rotationDegrees = 90;

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

  Future<File?> _executeRotate() async {
    if (_selectedFile == null) return null;

    final outputFile = await PdfEngine.rotatePdf(_selectedFile!, _rotationDegrees);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = outputFile.uri.pathSegments.last;
    final fileSize = await outputFile.length();

    final doc = DocumentFile(
      id: 'rot_$timestamp',
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
              toolId: 'rotate-pdf',
              toolName: 'Rotate PDF',
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
    const primaryColor = Color(0xFF2563EB); // Royal Blue

    return ToolFlowScaffold(
      title: 'Rotate PDF',
      toolId: 'rotate-pdf',
      primaryColor: primaryColor,
      toolIcon: LucideIcons.rotateCw,
      processingMessage: 'Rotating PDF pages by $_rotationDegrees°...',
      canProceedToEdition: _selectedFile != null,
      onProcess: _executeRotate,
      onReset: () {
        setState(() {
          _selectedFile = null;
          _rotationDegrees = 90;
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
              child: const Icon(LucideIcons.rotateCw, size: 36, color: primaryColor),
            ),
            const SizedBox(height: 14),
            const Text(
              'Select PDF to Rotate',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            const SizedBox(height: 6),
            const Text(
              'Rotate page orientation permanently (90°, 180°, 270°).',
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
            'Select Rotation Angle',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              _buildRotationOption(90, '90° Clockwise', LucideIcons.rotateCw),
              const SizedBox(width: 10),
              _buildRotationOption(180, '180° Flip', LucideIcons.refreshCw),
              const SizedBox(width: 10),
              _buildRotationOption(270, '270° Counter', LucideIcons.rotateCcw),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRotationOption(int deg, String label, IconData icon) {
    final isSelected = _rotationDegrees == deg;
    const primaryColor = Color(0xFF2563EB);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _rotationDegrees = deg),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? primaryColor : const Color(0xFF64748B), size: 28),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
