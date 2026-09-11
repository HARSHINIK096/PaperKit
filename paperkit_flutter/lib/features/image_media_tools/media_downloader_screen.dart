import 'dart:io';
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
      File outputFile;
      if (_mediaType == 'youtube') {
        outputFile = await ApiService().downloadYouTube(url: url);
      } else {
        outputFile = await ApiService().downloadSpotify(url: url);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = outputFile.uri.pathSegments.last;
      final fileSize = await outputFile.length();

      final doc = DocumentFile(
        id: 'media_$timestamp',
        name: fileName,
        path: outputFile.path,
        size: fileSize,
        modifiedAt: DateTime.now(),
        type: _mediaType == 'youtube' ? FileTypeCategory.video : FileTypeCategory.audio,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'media-downloader',
                toolName: 'Media Downloader (${_mediaType.toUpperCase()})',
                fileName: fileName,
                outputPath: outputFile.path,
                fileSize: fileSize,
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _downloadedResult = outputFile;
          _isDownloading = false;
        });

        FileSuccessDialog.show(
          context,
          title: 'Download Successful!',
          message: 'Your ${_mediaType.toUpperCase()} file is ready and saved locally.',
          file: outputFile,
          fileSize: '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
        );
      }
    } on MediaDownloadException catch (mde) {
      if (mounted) {
        setState(() => _isDownloading = false);
        String userMessage = mde.message;
        if (mde.errorCode == 'YOUTUBE_BOT_PROTECTION') {
          userMessage = 'YouTube Bot Protection: The video request was challenged. Please try again in a few moments.';
        } else if (mde.errorCode == 'YOUTUBE_FORMAT_UNAVAILABLE') {
          userMessage = 'Format Unavailable: The requested video quality is not available.';
        } else if (mde.errorCode == 'YOUTUBE_EXTRACTION_TIMEOUT') {
          userMessage = 'Download Timed Out: Video took too long to process. Try a shorter video or retry later.';
        } else if (mde.errorCode == 'YOUTUBE_PRIVATE_VIDEO' || mde.errorCode == 'YOUTUBE_AUTH_REQUIRED') {
          userMessage = 'Access Restricted: This video is private, age-restricted, or requires authentication.';
        } else if (mde.errorCode == 'YOUTUBE_VIDEO_UNAVAILABLE') {
          userMessage = 'Video Not Found: The video does not exist or has been removed from YouTube.';
        } else if (mde.errorCode == 'YOUTUBE_URL_INVALID') {
          userMessage = 'Invalid Link: Please paste a valid YouTube video link.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: AppColors.toolRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: AppColors.toolRed,
            duration: const Duration(seconds: 4),
          ),
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
                  label: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.video, size: 16),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'YouTube Video',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  selected: _mediaType == 'youtube',
                  selectedColor: AppColors.toolRed.withOpacity(0.2),
                  onSelected: (_) => setState(() => _mediaType = 'youtube'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.music, size: 16),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Spotify Audio',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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
