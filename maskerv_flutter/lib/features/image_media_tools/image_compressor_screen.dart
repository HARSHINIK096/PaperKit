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
import '../../core/services/image_engine.dart';
import '../../core/widgets/tool_flow_scaffold.dart';

class ImageCompressorScreen extends StatefulWidget {
  final String? initialPreset;

  const ImageCompressorScreen({super.key, this.initialPreset});

  @override
  State<ImageCompressorScreen> createState() => _ImageCompressorScreenState();
}

class _ImageCompressorScreenState extends State<ImageCompressorScreen> {
  File? _selectedFile;
  int _originalSize = 0;
  int _quality = 70; // 10 to 90
  int? _maxDimension;

  @override
  void initState() {
    super.initState();
    if (widget.initialPreset == 'low') _quality = 85;
    if (widget.initialPreset == 'medium') _quality = 65;
    if (widget.initialPreset == 'high') _quality = 40;
  }

  Future<void> _pickFile() async {
    HapticFeedback.lightImpact();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
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

    final outputFile = await ImageEngine.compressImage(
      inputFile: _selectedFile!,
      quality: _quality,
      maxDimension: _maxDimension,
    );

    final newSize = await outputFile.length();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = outputFile.uri.pathSegments.last;

    final doc = DocumentFile(
      id: 'imgcomp_$timestamp',
      name: fileName,
      path: outputFile.path,
      size: newSize,
      modifiedAt: DateTime.now(),
      type: FileTypeCategory.image,
    );

    if (mounted) {
      await context.read<FilesProvider>().addFile(doc);
      await context.read<HistoryProvider>().addRecord(
            HistoryItem(
              id: 'hist_$timestamp',
              toolId: 'image-compressor',
              toolName: 'Image Compressor ($_quality% quality)',
              fileName: fileName,
              outputPath: outputFile.path,
              fileSize: newSize,
              timestamp: DateTime.now(),
            ),
          );
    }

    return outputFile;
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF10B981); // Emerald Green

    return ToolFlowScaffold(
      title: 'Image Compressor ⭐',
      toolId: 'image-compressor',
      primaryColor: primaryColor,
      toolIcon: LucideIcons.minimize2,
      processingMessage: 'Compressing image with $_quality% quality preset...',
      canProceedToEdition: _selectedFile != null,
      onProcess: _executeCompress,
      onReset: () {
        setState(() {
          _selectedFile = null;
          _originalSize = 0;
          _quality = 70;
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
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.minimize2, size: 36, color: primaryColor),
            ),
            const SizedBox(height: 14),
            const Text(
              'Select Image to Compress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            const SizedBox(height: 6),
            const Text(
              'Shrink image sizes for instant sharing and web publishing.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(LucideIcons.filePlus, size: 18),
              label: Text(
                _selectedFile == null ? 'Choose Image' : 'Change Selected Image',
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
                    const Icon(LucideIcons.image, color: primaryColor, size: 22),
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
            'Configure Compression Quality',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          const SizedBox(height: 14),

          // Quality Slider Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Target Quality', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('$_quality%', style: const TextStyle(fontWeight: FontWeight.w800, color: primaryColor)),
                  ],
                ),
                Slider(
                  value: _quality.toDouble(),
                  min: 15,
                  max: 95,
                  divisions: 16,
                  activeColor: primaryColor,
                  onChanged: (val) => setState(() => _quality = val.toInt()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Presets row
          Row(
            children: [
              _buildPresetChip('Low (85%)', 85),
              const SizedBox(width: 8),
              _buildPresetChip('Balanced (65%)', 65),
              const SizedBox(width: 8),
              _buildPresetChip('High (40%)', 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, int q) {
    final isSelected = _quality == q;
    const primaryColor = Color(0xFF10B981);

    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _quality = q),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? primaryColor.withValues(alpha: 0.12) : Colors.white,
          side: BorderSide(
            color: isSelected ? primaryColor : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? primaryColor : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
