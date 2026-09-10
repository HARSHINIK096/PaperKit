import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/image_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

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
  bool _isProcessing = false;
  File? _compressedResult;
  int _compressedSize = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialPreset == 'low') _quality = 85;
    if (widget.initialPreset == 'medium') _quality = 65;
    if (widget.initialPreset == 'high') _quality = 40;
  }

  Future<void> _pickFile() async {
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
        _compressedResult = null;
      });
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _compressImage() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
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

        setState(() {
          _compressedResult = outputFile;
          _compressedSize = newSize;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image compressed successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Compression failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Image Compressor',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
              children: [
                if (_selectedFile == null)
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(LucideIcons.image, size: 20),
                      label: const Text('Choose Image to Compress'),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(_selectedFile!),
                            fit: BoxFit.cover,
                          ),
                        ),
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
                              'Original: ${_formatSize(_originalSize)}',
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
            Text('Quality Level: $_quality%', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Slider(
              value: _quality.toDouble(),
              min: 10,
              max: 95,
              divisions: 17,
              onChanged: (val) => setState(() => _quality = val.toInt()),
            ),
            const SizedBox(height: 16),

            Text(
              'Max Dimension Constraint',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              children: [
                _buildDimensionChip('Original (No Resize)', null),
                _buildDimensionChip('1920px (FHD)', 1920),
                _buildDimensionChip('1280px (HD)', 1280),
                _buildDimensionChip('800px (Web)', 800),
              ],
            ),
            const SizedBox(height: 24),

            ActionButton(
              label: 'Compress Image',
              icon: LucideIcons.minimize2,
              isLoading: _isProcessing,
              onPressed: _compressImage,
            ),
          ],

          if (_compressedResult != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Original:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(_formatSize(_originalSize), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Compressed:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        _formatSize(_compressedSize),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ActionButton(
                    label: 'Open Compressed Image',
                    icon: LucideIcons.externalLink,
                    onPressed: () => OpenFilex.open(_compressedResult!.path),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDimensionChip(String label, int? dimension) {
    final isSelected = _maxDimension == dimension;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (_) => setState(() => _maxDimension = dimension),
    );
  }
}
