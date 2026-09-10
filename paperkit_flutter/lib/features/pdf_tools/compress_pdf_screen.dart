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
import '../../core/widgets/tool_flow_scaffold.dart';

class CompressPDFScreen extends StatefulWidget {
  const CompressPDFScreen({super.key});

  @override
  State<CompressPDFScreen> createState() => _CompressPDFScreenState();
}

class _CompressPDFScreenState extends State<CompressPDFScreen> {
  File? _selectedFile;
  int _originalSize = 0;
  String _compressionLevel = 'recommended'; // 'extreme', 'recommended', 'less'

  Future<void> _pickFile() async {
    HapticFeedback.lightImpact();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final len = await file.length();
      setState(() {
        _selectedFile = file;
        _originalSize = len;
      });
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<File?> _executeCompress() async {
    if (_selectedFile == null) return null;

    final bytes = await _selectedFile!.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    document.compressionLevel = _compressionLevel == 'extreme'
        ? PdfCompressionLevel.best
        : (_compressionLevel == 'recommended'
            ? PdfCompressionLevel.normal
            : PdfCompressionLevel.belowNormal);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outName = 'Compressed_${_selectedFile!.uri.pathSegments.last}';
    final outPath = '${_selectedFile!.parent.path}/$outName';
    final outFile = File(outPath);
    await outFile.writeAsBytes(document.saveSync());
    document.dispose();

    final newSize = await outFile.length();

    final doc = DocumentFile(
      id: 'comp_$timestamp',
      name: outName,
      path: outFile.path,
      size: newSize,
      modifiedAt: DateTime.now(),
      type: FileTypeCategory.pdf,
    );

    if (mounted) {
      await context.read<FilesProvider>().addFile(doc);
      await context.read<HistoryProvider>().addRecord(
            HistoryItem(
              id: 'hist_$timestamp',
              toolId: 'compress-pdf',
              toolName: 'Compress PDF',
              fileName: outName,
              outputPath: outFile.path,
              fileSize: newSize,
              timestamp: DateTime.now(),
            ),
          );
    }

    return outFile;
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF97316); // Vibrant Orange

    return ToolFlowScaffold(
      title: 'Compress PDF',
      toolId: 'compress-pdf',
      primaryColor: primaryColor,
      toolIcon: LucideIcons.minimize2,
      processingMessage: 'Compressing PDF with ${_compressionLevel.toUpperCase()} optimization...',
      canProceedToEdition: _selectedFile != null,
      onProcess: _executeCompress,
      onReset: () {
        setState(() {
          _selectedFile = null;
          _originalSize = 0;
          _compressionLevel = 'recommended';
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
                color: Color(0xFFFFF7ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.minimize2, size: 36, color: primaryColor),
            ),
            const SizedBox(height: 14),
            const Text(
              'Select PDF to Compress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            const SizedBox(height: 6),
            const Text(
              'Reduce document file size with high visual quality.',
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
                            'Original Size: ${_formatSize(_originalSize)}',
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
            'Select Compression Level',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          const SizedBox(height: 14),

          _buildPresetOption(
            level: 'extreme',
            title: 'Extreme Compression',
            desc: 'Smallest file size, maximum byte reduction',
            icon: LucideIcons.zap,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 8),

          _buildPresetOption(
            level: 'recommended',
            title: 'Recommended Compression',
            desc: 'Optimal balance of high visual clarity and file size',
            icon: LucideIcons.checkCircle2,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 8),

          _buildPresetOption(
            level: 'less',
            title: 'Low Compression',
            desc: 'Highest vector quality with minor compression',
            icon: LucideIcons.shieldCheck,
            primaryColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetOption({
    required String level,
    required String title,
    required String desc,
    required IconData icon,
    required Color primaryColor,
  }) {
    final isSelected = _compressionLevel == level;

    return InkWell(
      onTap: () => setState(() => _compressionLevel = level),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.12)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isSelected ? primaryColor : const Color(0xFF64748B), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: level,
              groupValue: _compressionLevel,
              activeColor: primaryColor,
              onChanged: (val) => setState(() => _compressionLevel = val!),
            ),
          ],
        ),
      ),
    );
  }
}
