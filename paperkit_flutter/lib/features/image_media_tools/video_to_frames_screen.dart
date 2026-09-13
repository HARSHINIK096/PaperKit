import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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
import 'models/video_frame_models.dart';

class VideoToFramesScreen extends StatefulWidget {
  const VideoToFramesScreen({super.key});

  @override
  State<VideoToFramesScreen> createState() => _VideoToFramesScreenState();
}

class _VideoToFramesScreenState extends State<VideoToFramesScreen> {
  File? _selectedFile;
  VideoProbeInfo? _videoInfo;
  bool _isProbing = false;
  bool _isExtracting = false;
  bool _isDownloadingZip = false;

  // Extraction Mode: 'every_frame', 'fps', 'interval', 'timestamps'
  String _mode = 'fps';
  double _fps = 1.0;
  double _interval = 1.0;
  final TextEditingController _customFpsController = TextEditingController(text: '1.0');
  final TextEditingController _customIntervalController = TextEditingController(text: '1.0');
  final TextEditingController _timestampsController = TextEditingController(text: '00:00:01, 00:00:02');

  // Format & Quality
  String _imageFormat = 'jpg'; // 'jpg' or 'png'
  double _jpegQuality = 85;
  double _pngCompression = 6;

  // Extraction Results
  FrameExtractionResult? _extractionResult;
  File? _downloadedZipFile;

  final List<String> _allowedExtensions = [
    'mp4', 'mov', 'webm', 'avi', 'mkv', 'flv', 'wmv', 'm4v', '3gp', 'ts', 'mts'
  ];

  @override
  void dispose() {
    _customFpsController.dispose();
    _customIntervalController.dispose();
    _timestampsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() {
        _selectedFile = file;
        _videoInfo = null;
        _extractionResult = null;
        _downloadedZipFile = null;
        _isProbing = true;
      });

      try {
        final info = await ApiService().probeVideoInfo(file);
        if (mounted) {
          setState(() {
            _videoInfo = info;
            _isProbing = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isProbing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not read video metadata: $e')),
          );
        }
      }
    }
  }

  Future<void> _extractFrames() async {
    if (_selectedFile == null) return;
    setState(() => _isExtracting = true);

    try {
      double effectiveFps = _fps;
      if (_mode == 'fps') {
        effectiveFps = double.tryParse(_customFpsController.text.trim()) ?? _fps;
      }

      double effectiveInterval = _interval;
      if (_mode == 'interval') {
        effectiveInterval = double.tryParse(_customIntervalController.text.trim()) ?? _interval;
      }

      final result = await ApiService().extractVideoFrames(
        file: _selectedFile!,
        mode: _mode,
        fps: effectiveFps,
        interval: effectiveInterval,
        timestamps: _timestampsController.text.trim(),
        imageFormat: _imageFormat,
        jpegQuality: _jpegQuality.round(),
        pngCompression: _pngCompression.round(),
      );

      if (mounted) {
        setState(() {
          _extractionResult = result;
          _isExtracting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully extracted ${result.totalFrames} frames!'),
            backgroundColor: AppColors.toolGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExtracting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Frame extraction failed: $e')),
        );
      }
    }
  }

  Future<void> _downloadAllAsZip() async {
    if (_selectedFile == null) return;
    setState(() => _isDownloadingZip = true);

    try {
      File zipFile;
      if (_extractionResult != null && _extractionResult!.jobId.isNotEmpty) {
        zipFile = await ApiService().downloadExistingFramesZip(_extractionResult!.jobId);
      } else {
        zipFile = await ApiService().downloadFramesZip(
          file: _selectedFile!,
          mode: _mode,
          fps: _fps,
          interval: _interval,
          timestamps: _timestampsController.text.trim(),
          imageFormat: _imageFormat,
          jpegQuality: _jpegQuality.round(),
          pngCompression: _pngCompression.round(),
        );
      }

      final fileSize = await zipFile.length();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outName = zipFile.uri.pathSegments.last;

      final doc = DocumentFile(
        id: 'frames_zip_$timestamp',
        name: outName,
        path: zipFile.path,
        size: fileSize,
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.archive,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_frames_$timestamp',
                toolId: 'video-to-frames',
                toolName: 'Video to Frames (ZIP)',
                fileName: outName,
                outputPath: zipFile.path,
                fileSize: fileSize,
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _downloadedZipFile = zipFile;
          _isDownloadingZip = false;
        });

        FileSuccessDialog.show(
          context,
          title: 'Frames Exported!',
          message: 'All frames successfully packed into ZIP archive.',
          file: zipFile,
          fileSize: '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloadingZip = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download ZIP: $e')),
        );
      }
    }
  }

  void _showFramePreviewDialog(ExtractedFrameItem frame) {
    Uint8List? imageBytes;
    if (frame.dataUrl.contains(',')) {
      final b64 = frame.dataUrl.split(',').last;
      imageBytes = base64Decode(b64);
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Text('Frame #${frame.frameNumber}'),
              const Spacer(),
              Text(
                frame.timestampFormatted,
                style: const TextStyle(fontSize: 13, color: AppColors.toolBlue, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.contain,
                    height: 240,
                  ),
                )
              else
                const SizedBox(height: 120, child: Center(child: Icon(LucideIcons.image, size: 48))),
              const SizedBox(height: 12),
              Text(
                '${frame.filename} • ${(frame.fileSize / 1024).toStringAsFixed(1)} KB',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                if (imageBytes != null) {
                  final tempFile = File('${Directory.systemTemp.path}/${frame.filename}');
                  await tempFile.writeAsBytes(imageBytes);
                  await Share.shareXFiles([XFile(tempFile.path)], text: 'Frame #${frame.frameNumber}');
                }
              },
              icon: const Icon(LucideIcons.share2, size: 16),
              label: const Text('Share'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                if (_extractionResult != null) {
                  final ext = _imageFormat == 'png' ? 'png' : 'jpg';
                  final savedFile = await ApiService().downloadSingleFrame(
                    _extractionResult!.jobId,
                    frame.frameNumber,
                    ext,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Saved ${frame.filename} to documents'),
                        action: SnackBarAction(
                          label: 'Open',
                          onPressed: () => OpenFilex.open(savedFile.path),
                        ),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(LucideIcons.download, size: 16),
              label: const Text('Download'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Video to Frames',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HowItWorksCarousel(
            toolId: 'video-to-frames',
            color: AppColors.toolIndigo,
            padding: EdgeInsets.only(bottom: 16),
          ),

          // File Picker & Video Probe Container
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          color: AppColors.toolIndigo.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.film, color: AppColors.toolIndigo, size: 24),
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
                            if (_isProbing)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text('Probing video streams...', style: TextStyle(fontSize: 12, color: AppColors.toolBlue)),
                              )
                            else if (_videoInfo != null)
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  '${_videoInfo!.durationFormatted} • ${_videoInfo!.resolutionStr} • ${_videoInfo!.fps} fps • ${_videoInfo!.sizeFormatted}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
            // Extraction Mode Selector
            Text(
              'Extraction Mode',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Extract at FPS'),
                  selected: _mode == 'fps',
                  onSelected: (_) => setState(() => _mode = 'fps'),
                ),
                ChoiceChip(
                  label: const Text('By Interval'),
                  selected: _mode == 'interval',
                  onSelected: (_) => setState(() => _mode = 'interval'),
                ),
                ChoiceChip(
                  label: const Text('Every Frame'),
                  selected: _mode == 'every_frame',
                  onSelected: (_) => setState(() => _mode = 'every_frame'),
                ),
                ChoiceChip(
                  label: const Text('Specific Timestamps'),
                  selected: _mode == 'timestamps',
                  onSelected: (_) => setState(() => _mode = 'timestamps'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Mode specific controls
            if (_mode == 'fps') ...[
              Wrap(
                spacing: 8,
                children: [1.0, 2.0, 5.0, 10.0].map((f) {
                  final isSel = _fps == f;
                  return ActionChip(
                    label: Text('${f.toInt()} FPS'),
                    backgroundColor: isSel ? AppColors.primary.withOpacity(0.2) : null,
                    onPressed: () {
                      setState(() {
                        _fps = f;
                        _customFpsController.text = f.toString();
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _customFpsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Custom FPS (Frames Per Second)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ] else if (_mode == 'interval') ...[
              Wrap(
                spacing: 8,
                children: [1.0, 2.0, 5.0].map((sec) {
                  final isSel = _interval == sec;
                  return ActionChip(
                    label: Text('Every ${sec.toInt()}s'),
                    backgroundColor: isSel ? AppColors.primary.withOpacity(0.2) : null,
                    onPressed: () {
                      setState(() {
                        _interval = sec;
                        _customIntervalController.text = sec.toString();
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _customIntervalController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Interval (seconds between frames)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ] else if (_mode == 'every_frame') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.toolOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.toolOrange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, color: AppColors.toolOrange, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Extract Every Frame exports 100% of video frames (subject to safe 300 frame ceiling to prevent Render memory limit crashes).',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_mode == 'timestamps') ...[
              TextField(
                controller: _timestampsController,
                decoration: const InputDecoration(
                  labelText: 'Timestamps (comma-separated, e.g. 00:00:01.5, 00:00:03)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
            const SizedBox(height: 18),

            // Image Format Selection
            Text(
              'Output Image Format',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                ChoiceChip(
                  label: const Text('JPEG (.jpg)'),
                  selected: _imageFormat == 'jpg',
                  onSelected: (_) => setState(() => _imageFormat = 'jpg'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('PNG (.png)'),
                  selected: _imageFormat == 'png',
                  onSelected: (_) => setState(() => _imageFormat = 'png'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_imageFormat == 'jpg') ...[
              Row(
                children: [
                  Text('JPEG Quality: ${_jpegQuality.round()}%'),
                  Expanded(
                    child: Slider(
                      value: _jpegQuality,
                      min: 10,
                      max: 100,
                      divisions: 18,
                      onChanged: (v) => setState(() => _jpegQuality = v),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Text('PNG Compression: ${_pngCompression.round()}'),
                  Expanded(
                    child: Slider(
                      value: _pngCompression,
                      min: 0,
                      max: 9,
                      divisions: 9,
                      onChanged: (v) => setState(() => _pngCompression = v),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Primary Action Button
            ActionButton(
              label: 'Extract Frames',
              icon: LucideIcons.film,
              isLoading: _isExtracting,
              onPressed: _extractFrames,
            ),
          ],

          // Extracted Frames Grid & ZIP Download
          if (_extractionResult != null) ...[
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Extracted Frames (${_extractionResult!.frames.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                TextButton.icon(
                  onPressed: _downloadAllAsZip,
                  icon: const Icon(LucideIcons.archive, size: 16),
                  label: const Text('Download All as ZIP'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: _extractionResult!.frames.length,
              itemBuilder: (context, index) {
                final frame = _extractionResult!.frames[index];
                Uint8List? thumbBytes;
                if (frame.dataUrl.contains(',')) {
                  thumbBytes = base64Decode(frame.dataUrl.split(',').last);
                }

                return InkWell(
                  onTap: () => _showFramePreviewDialog(frame),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: thumbBytes != null
                              ? Image.memory(
                                  thumbBytes,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey.withOpacity(0.2),
                                  child: const Icon(LucideIcons.image, size: 24),
                                ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '#${frame.frameNumber}',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                frame.timestampFormatted,
                                style: const TextStyle(fontSize: 10, color: AppColors.toolBlue),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            ActionButton(
              label: 'Download All Frames as ZIP',
              icon: LucideIcons.download,
              isLoading: _isDownloadingZip,
              onPressed: _downloadAllAsZip,
            ),
            if (_downloadedZipFile != null) ...[
              const SizedBox(height: 10),
              ActionButton(
                label: 'Open Frames ZIP',
                icon: LucideIcons.externalLink,
                isSecondary: true,
                onPressed: () => OpenFilex.open(_downloadedZipFile!.path),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
