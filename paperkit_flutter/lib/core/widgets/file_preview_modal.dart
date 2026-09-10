import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../models/document_file.dart';
import '../theme/app_colors.dart';

class FilePreviewModal extends StatefulWidget {
  final DocumentFile file;

  const FilePreviewModal({super.key, required this.file});

  static void show(BuildContext context, DocumentFile file) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FilePreviewModal(file: file),
    );
  }

  @override
  State<FilePreviewModal> createState() => _FilePreviewModalState();
}

class _FilePreviewModalState extends State<FilePreviewModal> {
  String? _textContent;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFileContent();
  }

  Future<void> _loadFileContent() async {
    final path = widget.file.path;
    final ext = widget.file.name.split('.').last.toLowerCase();

    if (['txt', 'md', 'json', 'csv', 'log', 'yaml', 'yml', 'xml', 'html', 'js', 'py', 'dart'].contains(ext)) {
      setState(() => _isLoading = true);
      try {
        final file = File(path);
        if (await file.exists()) {
          final content = await file.readAsString();
          setState(() {
            _textContent = content;
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = widget.file.name.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'].contains(ext);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Top Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      Text(
                        widget.file.formattedSize,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.share2, size: 20),
                  onPressed: () {
                    Share.shareXFiles([XFile(widget.file.path)]);
                  },
                  tooltip: 'Share',
                ),
                IconButton(
                  icon: const Icon(LucideIcons.externalLink, size: 20),
                  onPressed: () {
                    OpenFilex.open(widget.file.path);
                  },
                  tooltip: 'Open in Default App',
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Preview Area
          Expanded(
            child: Container(
              color: isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9),
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : isImage
                        ? InteractiveViewer(
                            child: Image.file(
                              File(widget.file.path),
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Text('Could not render image preview'),
                            ),
                          )
                        : _textContent != null
                            ? SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: SelectableText(
                                  _textContent!,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.fileText, size: 48, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    widget.file.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${widget.file.formattedSize} • Tap below to open in native viewer',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () => OpenFilex.open(widget.file.path),
                                    icon: const Icon(LucideIcons.externalLink, size: 16),
                                    label: const Text('Open in Native Viewer'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
