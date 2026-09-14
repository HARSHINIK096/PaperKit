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

import '../../core/widgets/how_it_works_carousel.dart';

class VideoConverterScreen extends StatefulWidget {
  final String? initialTo;

  const VideoConverterScreen({super.key, this.initialTo});

  @override
  State<VideoConverterScreen> createState() => _VideoConverterScreenState();
}

class _VideoConverterScreenState extends State<VideoConverterScreen> {
  File? _selectedFile;
  late String _targetFormat;
  bool _isProcessing = false;
  File? _convertedResult;

  final List<String> _videoFormats = ['mp4', 'webm', 'mov', 'avi', 'mkv', 'flv', 'wmv', '3gp', 'gif', 'ogv', 'ts'];
  final List<String> _audioFormats = ['mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg'];

  @override
  void initState() {
    super.initState();
    _targetFormat = widget.initialTo ?? 'mp4';
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'webm', 'avi', 'mkv', 'flv', 'wmv', 'm4v', '3gp', 'ogv', 'ts', 'mts', 'm2ts'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _convertedResult = null;
      });
    }
  }

  Future<void> _convertVideo() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      final outputFile = await ApiService().convertVideo(
        file: _selectedFile!,
        targetFormat: _targetFormat,
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outName = outputFile.uri.pathSegments.last;
      final fileSize = await outputFile.length();

      final doc = DocumentFile(
        id: 'vidconv_$timestamp',
        name: outName,
        path: outputFile.path,
        size: fileSize,
        modifiedAt: DateTime.now(),
        type: _targetFormat == 'gif' ? FileTypeCategory.image : FileTypeCategory.video,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'video-converter',
                toolName: 'Video Converter (${_targetFormat.toUpperCase()})',
                fileName: outName,
                outputPath: outputFile.path,
                fileSize: fileSize,
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _convertedResult = outputFile;
          _isProcessing = false;
        });

        FileSuccessDialog.show(
          context,
          title: 'Conversion Complete!',
          message: 'Video successfully converted to ${_targetFormat.toUpperCase()}.',
          file: outputFile,
          fileSize: '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conversion failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Video Converter',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HowItWorksCarousel(
            toolId: 'video-converter',
            color: AppColors.toolBlue,
            padding: EdgeInsets.only(bottom: 16),
          ),
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
                      label: const Text('Choose Video File'),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.toolBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.video, color: AppColors.toolBlue, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _selectedFile!.uri.pathSegments.last,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
              'Target Video Format',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: _videoFormats.map((fmt) {
                final isSelected = _targetFormat == fmt;
                return ChoiceChip(
                  label: Text(fmt.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : null)),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  onSelected: (_) => setState(() => _targetFormat = fmt),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            Text(
              'Extract Audio from Video',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: _audioFormats.map((fmt) {
                final isSelected = _targetFormat == fmt;
                return ChoiceChip(
                  label: Text('${fmt.toUpperCase()} (Audio)', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : null)),
                  selected: isSelected,
                  selectedColor: AppColors.toolGreen,
                  onSelected: (_) => setState(() => _targetFormat = fmt),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            ActionButton(
              label: 'Convert to ${_targetFormat.toUpperCase()}',
              icon: LucideIcons.refreshCw,
              isLoading: _isProcessing,
              onPressed: _convertVideo,
            ),
          ],

          if (_convertedResult != null) ...[
            const SizedBox(height: 20),
            ActionButton(
              label: 'Open Video',
              icon: LucideIcons.externalLink,
              isSecondary: true,
              onPressed: () => OpenFilex.open(_convertedResult!.path),
            ),
          ],
        ],
      ),
    );
  }
}
