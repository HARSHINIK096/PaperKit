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
import 'models/video_frame_models.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> with SingleTickerProviderStateMixin {
  File? _selectedFile;
  VideoProbeInfo? _videoInfo;
  bool _isProbing = false;
  bool _isExporting = false;
  File? _editedResult;

  late TabController _tabController;

  // Trim controls
  double _startTime = 0.0;
  double _endTime = 0.0;

  // Crop & Transform
  String _cropPreset = 'original'; // original, 1:1, 4:5, 16:9, 9:16, 4:3
  int _rotation = 0; // 0, 90, 180, 270
  bool _flipH = false;
  bool _flipV = false;

  // Speed & Audio
  double _speed = 1.0;
  double _volume = 1.0;
  bool _mute = false;
  double _fadeIn = 0.0;
  double _fadeOut = 0.0;

  // Filters & Text
  String _filterPreset = 'none'; // none, grayscale, bright, contrast, sharpen, blur
  final TextEditingController _textOverlayController = TextEditingController();
  String _textPosition = 'bottom'; // top, center, bottom
  String _textColor = 'white';

  // Export Settings
  String _exportResolution = 'original'; // original, 720p, 480p
  int _exportCrf = 23;

  final List<String> _allowedExtensions = [
    'mp4', 'mov', 'webm', 'avi', 'mkv', 'flv', 'wmv', 'm4v', '3gp', 'ts'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textOverlayController.dispose();
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
        _editedResult = null;
        _isProbing = true;
      });

      try {
        final info = await ApiService().probeVideoInfo(file);
        if (mounted) {
          setState(() {
            _videoInfo = info;
            _startTime = 0.0;
            _endTime = info.duration;
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

  Future<void> _exportVideo() async {
    if (_selectedFile == null) return;
    setState(() => _isExporting = true);

    try {
      final outputFile = await ApiService().editVideo(
        file: _selectedFile!,
        startTime: _startTime,
        endTime: _endTime,
        cropPreset: _cropPreset,
        rotation: _rotation,
        flipH: _flipH,
        flipV: _flipV,
        speed: _speed,
        volume: _volume,
        mute: _mute,
        fadeIn: _fadeIn,
        fadeOut: _fadeOut,
        filterPreset: _filterPreset,
        textOverlay: _textOverlayController.text.trim(),
        textPosition: _textPosition,
        textColor: _textColor,
        exportResolution: _exportResolution,
        exportCrf: _exportCrf,
      );

      final fileSize = await outputFile.length();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outName = outputFile.uri.pathSegments.last;

      final doc = DocumentFile(
        id: 'videdit_$timestamp',
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
                id: 'hist_edit_$timestamp',
                toolId: 'video-editor',
                toolName: 'Video Editor (Render MP4)',
                fileName: outName,
                outputPath: outputFile.path,
                fileSize: fileSize,
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _editedResult = outputFile;
          _isExporting = false;
        });

        FileSuccessDialog.show(
          context,
          title: 'Export Complete!',
          message: 'Video edited and exported successfully.',
          file: outputFile,
          fileSize: '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video editing export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Video Editor',
      showBottomNav: false,
      child: Column(
        children: [
          // Top Info Banner & Picker
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const HowItWorksCarousel(
                  toolId: 'video-editor',
                  color: AppColors.toolOrange,
                  padding: EdgeInsets.only(bottom: 12),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: _selectedFile == null
                      ? Center(
                          child: OutlinedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(LucideIcons.video, size: 20),
                            label: const Text('Choose Video to Edit'),
                          ),
                        )
                      : Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.toolOrange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(LucideIcons.clapperboard, color: AppColors.toolOrange, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFile!.uri.pathSegments.last,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_isProbing)
                                    const Text('Probing video...', style: TextStyle(fontSize: 11, color: AppColors.toolBlue))
                                  else if (_videoInfo != null)
                                    Text(
                                      '${_videoInfo!.durationFormatted} • ${_videoInfo!.resolutionStr} • ${_videoInfo!.sizeFormatted}',
                                      style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                            TextButton(onPressed: _pickFile, child: const Text('Change')),
                          ],
                        ),
                ),
              ],
            ),
          ),

          if (_selectedFile != null) ...[
            // Tab Bar
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark ? Colors.grey : Colors.black54,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(icon: Icon(LucideIcons.scissors, size: 16), text: 'Trim'),
                Tab(icon: Icon(LucideIcons.crop, size: 16), text: 'Crop & Rotate'),
                Tab(icon: Icon(LucideIcons.gauge, size: 16), text: 'Speed & Audio'),
                Tab(icon: Icon(LucideIcons.sparkles, size: 16), text: 'Filters & Text'),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Trim & Cut
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Trim & Cut Segment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                        'Select the start and end timestamp of the video segment to export.',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      if (_videoInfo != null && _videoInfo!.duration > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Start: ${_startTime.toStringAsFixed(1)}s', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Duration: ${(_endTime - _startTime).toStringAsFixed(1)}s', style: const TextStyle(color: AppColors.toolBlue, fontWeight: FontWeight.bold)),
                            Text('End: ${_endTime.toStringAsFixed(1)}s', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        RangeSlider(
                          values: RangeValues(_startTime, _endTime > _startTime ? _endTime : _videoInfo!.duration),
                          min: 0.0,
                          max: _videoInfo!.duration,
                          divisions: (_videoInfo!.duration * 2).round().clamp(1, 200),
                          onChanged: (values) {
                            setState(() {
                              _startTime = values.start;
                              _endTime = values.end;
                            });
                          },
                        ),
                      ],
                    ],
                  ),

                  // Tab 2: Crop & Rotate
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Aspect Ratio Preset', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['original', '1:1', '4:5', '16:9', '9:16', '4:3'].map((ratio) {
                          final isSel = _cropPreset == ratio;
                          return ChoiceChip(
                            label: Text(ratio.toUpperCase()),
                            selected: isSel,
                            onSelected: (_) => setState(() => _cropPreset = ratio),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      const Text('Rotation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [0, 90, 180, 270].map((deg) {
                          final isSel = _rotation == deg;
                          return ChoiceChip(
                            label: Text(deg == 0 ? '0° (Normal)' : '$deg°'),
                            selected: isSel,
                            onSelected: (_) => setState(() => _rotation = deg),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      const Text('Flip', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('Flip Horizontal'),
                            selected: _flipH,
                            onSelected: (v) => setState(() => _flipH = v),
                          ),
                          const SizedBox(width: 10),
                          FilterChip(
                            label: const Text('Flip Vertical'),
                            selected: _flipV,
                            onSelected: (v) => setState(() => _flipV = v),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Tab 3: Speed & Audio
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Video Speed', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((sp) {
                          final isSel = _speed == sp;
                          return ChoiceChip(
                            label: Text('${sp}x'),
                            selected: isSel,
                            onSelected: (_) => setState(() => _speed = sp),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      const Text('Audio Controls', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Mute Audio'),
                        value: _mute,
                        onChanged: (v) => setState(() => _mute = v),
                      ),
                      if (!_mute) ...[
                        Row(
                          children: [
                            Text('Volume: ${(_volume * 100).toInt()}%'),
                            Expanded(
                              child: Slider(
                                value: _volume,
                                min: 0.0,
                                max: 2.0,
                                divisions: 20,
                                onChanged: (v) => setState(() => _volume = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            FilterChip(
                              label: Text('Fade-In (${_fadeIn.toInt()}s)'),
                              selected: _fadeIn > 0,
                              onSelected: (v) => setState(() => _fadeIn = v ? 1.0 : 0.0),
                            ),
                            const SizedBox(width: 10),
                            FilterChip(
                              label: Text('Fade-Out (${_fadeOut.toInt()}s)'),
                              selected: _fadeOut > 0,
                              onSelected: (v) => setState(() => _fadeOut = v ? 1.0 : 0.0),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  // Tab 4: Filters & Text Overlay
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Filter Preset', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'none', 'grayscale', 'bright', 'contrast', 'sharpen', 'blur'
                        ].map((fp) {
                          final isSel = _filterPreset == fp;
                          return ChoiceChip(
                            label: Text(fp[0].toUpperCase() + fp.substring(1)),
                            selected: isSel,
                            onSelected: (_) => setState(() => _filterPreset = fp),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      const Text('Text Overlay', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _textOverlayController,
                        decoration: const InputDecoration(
                          labelText: 'Overlay Text (e.g. Title, Caption)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Position: '),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Top'),
                            selected: _textPosition == 'top',
                            onSelected: (_) => setState(() => _textPosition = 'top'),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('Center'),
                            selected: _textPosition == 'center',
                            onSelected: (_) => setState(() => _textPosition = 'center'),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('Bottom'),
                            selected: _textPosition == 'bottom',
                            onSelected: (_) => setState(() => _textPosition = 'bottom'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Color: '),
                          const SizedBox(width: 8),
                          ...['white', 'yellow', 'cyan', 'red'].map((c) {
                            final isSel = _textColor == c;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(c[0].toUpperCase() + c.substring(1)),
                                selected: isSel,
                                onSelected: (_) => setState(() => _textColor = c),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Export Actions Bottom Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('Resolution: ', style: TextStyle(fontSize: 12.5)),
                          DropdownButton<String>(
                            value: _exportResolution,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'original', child: Text('Original', style: TextStyle(fontSize: 12.5))),
                              DropdownMenuItem(value: '720p', child: Text('720p HD', style: TextStyle(fontSize: 12.5))),
                              DropdownMenuItem(value: '480p', child: Text('480p SD', style: TextStyle(fontSize: 12.5))),
                            ],
                            onChanged: (v) => setState(() => _exportResolution = v ?? 'original'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Quality: ', style: TextStyle(fontSize: 12.5)),
                          DropdownButton<int>(
                            value: _exportCrf,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 20, child: Text('High', style: TextStyle(fontSize: 12.5))),
                              DropdownMenuItem(value: 23, child: Text('Medium', style: TextStyle(fontSize: 12.5))),
                              DropdownMenuItem(value: 28, child: Text('Compressed', style: TextStyle(fontSize: 12.5))),
                            ],
                            onChanged: (v) => setState(() => _exportCrf = v ?? 23),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ActionButton(
                    label: 'Export Edited Video',
                    icon: LucideIcons.clapperboard,
                    isLoading: _isExporting,
                    onPressed: _exportVideo,
                  ),
                  if (_editedResult != null) ...[
                    const SizedBox(height: 10),
                    ActionButton(
                      label: 'Open Exported Video',
                      icon: LucideIcons.externalLink,
                      isSecondary: true,
                      onPressed: () => OpenFilex.open(_editedResult!.path),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
