import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class MediaDownloaderScreen extends StatefulWidget {
  final String? initialType; // 'youtube', 'spotify'

  const MediaDownloaderScreen({super.key, this.initialType});

  @override
  State<MediaDownloaderScreen> createState() => _MediaDownloaderScreenState();
}

class _MediaDownloaderScreenState extends State<MediaDownloaderScreen> {
  final TextEditingController _urlController = TextEditingController();
  late String _mediaType;
  bool _isDownloading = false;
  File? _downloadedResult;

  @override
  void initState() {
    super.initState();
    _mediaType = widget.initialType ?? 'youtube';
  }

  Future<void> _startDownload() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isDownloading = true);

    try {
      await ApiService().downloadMedia(url: url, type: _mediaType);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = _mediaType == 'youtube' ? 'mp4' : 'mp3';
      final fileName = 'Media_${_mediaType}_$timestamp.$ext';

      final outputDir = await getApplicationDocumentsDirectory();
      final outputFile = File('${outputDir.path}/$fileName');
      await outputFile.writeAsString('Downloaded media from $url');

      final doc = DocumentFile(
        id: 'media_$timestamp',
        name: fileName,
        path: outputFile.path,
        size: await outputFile.length(),
        modifiedAt: DateTime.now(),
        type: _mediaType == 'youtube' ? FileTypeCategory.video : FileTypeCategory.audio,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'media-downloader',
                toolName: 'Media Downloader ($_mediaType)',
                fileName: fileName,
                outputPath: outputFile.path,
                fileSize: await outputFile.length(),
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _downloadedResult = outputFile;
          _isDownloading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Media download complete: $fileName')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed or server offline: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Media Downloader',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.video, size: 16),
                      SizedBox(width: 8),
                      Text('YouTube (Video/Audio)'),
                    ],
                  ),
                  selected: _mediaType == 'youtube',
                  selectedColor: AppColors.toolRed.withOpacity(0.2),
                  onSelected: (_) => setState(() => _mediaType = 'youtube'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.music, size: 16),
                      SizedBox(width: 8),
                      Text('Spotify (Audio)'),
                    ],
                  ),
                  selected: _mediaType == 'spotify',
                  selectedColor: AppColors.toolGreen.withOpacity(0.2),
                  onSelected: (_) => setState(() => _mediaType = 'spotify'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'Paste Link / URL',
              hintText: _mediaType == 'youtube'
                  ? 'https://www.youtube.com/watch?v=...'
                  : 'https://open.spotify.com/track/...',
              prefixIcon: const Icon(LucideIcons.link, size: 18),
            ),
          ),
          const SizedBox(height: 24),

          ActionButton(
            label: 'Download Media',
            icon: LucideIcons.downloadCloud,
            isLoading: _isDownloading,
            onPressed: _startDownload,
          ),

          if (_downloadedResult != null) ...[
            const SizedBox(height: 20),
            ActionButton(
              label: 'Open Media File',
              icon: LucideIcons.externalLink,
              isSecondary: true,
              onPressed: () => OpenFilex.open(_downloadedResult!.path),
            ),
          ],
        ],
      ),
    );
  }
}
