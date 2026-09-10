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
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/file_success_dialog.dart';

class VideoCompressorScreen extends StatefulWidget {
  final String? initialPreset;

  const VideoCompressorScreen({super.key, this.initialPreset});

  @override
  State<VideoCompressorScreen> createState() => _VideoCompressorScreenState();
}

class _VideoCompressorScreenState extends State<VideoCompressorScreen> {
  File? _selectedFile;
  int _originalSize = 0;
  String _preset = 'medium'; // 'low', 'medium', 'high'
  bool _isProcessing = false;
  File? _compressedResult;

  @override
  void initState() {
    super.initState();
    if (widget.initialPreset != null) _preset = widget.initialPreset!;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'webm', 'mkv'],
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

  Future<void> _compressVideo() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      final outputFile = await ApiService().compressVideo(
        file: _selectedFile!,
        preset: _preset,
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outName = outputFile.uri.pathSegments.last;
      final fileSize = await outputFile.length();

      final doc = DocumentFile(
        id: 'vidcomp_$timestamp',
        name: outName,
        path: outputFile.path,
        size: fileSize,
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.video,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'video-compressor',
                toolName: 'Video Compressor (${_preset.toUpperCase()})',
                fileName: outName,
                outputPath: outputFile.path,
                fileSize: fileSize,
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _compressedResult = outputFile;
          _isProcessing = false;
        });

        FileSuccessDialog.show(
          context,
          title: 'Compression Complete!',
          message: 'Video compressed using ${_preset.toUpperCase()} optimization.',
          file: outputFile,
          fileSize: '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
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
      title: 'Video Compressor',
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
                      icon: const Icon(LucideIcons.video, size: 20),
                      label: const Text('Choose Video to Compress'),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.toolOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.minimize, color: AppColors.toolOrange, size: 24),
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
            Text(
              'Compression Level',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),

            RadioListTile<String>(
              title: const Text('Low Compression (High Bitrate & Quality)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              value: 'low',
              groupValue: _preset,
              onChanged: (val) => setState(() => _preset = val!),
            ),
            RadioListTile<String>(
              title: const Text('Medium Compression (Balanced Quality & Size)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              value: 'medium',
              groupValue: _preset,
              onChanged: (val) => setState(() => _preset = val!),
            ),
            RadioListTile<String>(
              title: const Text('High Compression (Smallest File Size)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              value: 'high',
              groupValue: _preset,
              onChanged: (val) => setState(() => _preset = val!),
            ),
            const SizedBox(height: 24),

            ActionButton(
              label: 'Compress Video',
              icon: LucideIcons.minimize,
              isLoading: _isProcessing,
              onPressed: _compressVideo,
            ),
          ],

          if (_compressedResult != null) ...[
            const SizedBox(height: 20),
            ActionButton(
              label: 'Open Compressed Video',
              icon: LucideIcons.externalLink,
              isSecondary: true,
              onPressed: () => OpenFilex.open(_compressedResult!.path),
            ),
          ],
        ],
      ),
    );
  }
}
