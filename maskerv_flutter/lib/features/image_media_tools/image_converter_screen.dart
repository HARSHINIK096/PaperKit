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

class ImageConverterScreen extends StatefulWidget {
  final String? initialTo;

  const ImageConverterScreen({super.key, this.initialTo});

  @override
  State<ImageConverterScreen> createState() => _ImageConverterScreenState();
}

class _ImageConverterScreenState extends State<ImageConverterScreen> {
  File? _selectedFile;
  late String _targetFormat;

  final List<String> _formats = ['png', 'jpg', 'webp', 'bmp', 'gif'];

  @override
  void initState() {
    super.initState();
    _targetFormat = widget.initialTo ?? 'png';
  }

  Future<void> _pickFile() async {
    HapticFeedback.lightImpact();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'bmp', 'gif'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<File?> _executeConvert() async {
    if (_selectedFile == null) return null;

    final outputFile = await ImageEngine.convertFormat(
      inputFile: _selectedFile!,
      targetFormat: _targetFormat,
    );

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = outputFile.uri.pathSegments.last;
    final fileSize = await outputFile.length();

    final doc = DocumentFile(
      id: 'imgconv_$timestamp',
      name: fileName,
      path: outputFile.path,
      size: fileSize,
      modifiedAt: DateTime.now(),
      type: FileTypeCategory.image,
    );

    if (mounted) {
      await context.read<FilesProvider>().addFile(doc);
      await context.read<HistoryProvider>().addRecord(
            HistoryItem(
              id: 'hist_$timestamp',
              toolId: 'image-converter',
              toolName: 'Image Converter (${_targetFormat.toUpperCase()})',
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
    const primaryColor = Color(0xFF8B5CF6); // Purple

    return ToolFlowScaffold(
      title: 'Image Converter',
      toolId: 'image-converter',
      primaryColor: primaryColor,
      toolIcon: LucideIcons.image,
      processingMessage: 'Converting image to ${_targetFormat.toUpperCase()} format...',
      canProceedToEdition: _selectedFile != null,
      onProcess: _executeConvert,
      onReset: () {
        setState(() {
          _selectedFile = null;
          _targetFormat = widget.initialTo ?? 'png';
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
                color: Color(0xFFF5F3FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.image, size: 36, color: primaryColor),
            ),
            const SizedBox(height: 14),
            const Text(
              'Select Image to Convert',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            const SizedBox(height: 6),
            const Text(
              'Supports JPG, PNG, WebP, HEIC, BMP and GIF formats.',
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
            'Select Target Image Format',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          const SizedBox(height: 14),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _formats.map((fmt) {
              final isSelected = _targetFormat == fmt;
              return ChoiceChip(
                label: Text(
                  fmt.toUpperCase(),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                  ),
                ),
                selected: isSelected,
                selectedColor: primaryColor,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isSelected ? primaryColor : const Color(0xFFCBD5E1),
                  ),
                ),
                onSelected: (_) => setState(() => _targetFormat = fmt),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
