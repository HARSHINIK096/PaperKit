import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_tools.dart';
import '../../core/models/tool_item.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/tool_card.dart';

class CategoryHubScreen extends StatefulWidget {
  final String categoryId;

  const CategoryHubScreen({super.key, required this.categoryId});

  @override
  State<CategoryHubScreen> createState() => _CategoryHubScreenState();
}

class _CategoryHubScreenState extends State<CategoryHubScreen> {
  String _searchQuery = '';

  String get _catKey => widget.categoryId.toLowerCase().trim();

  String get _title {
    switch (_catKey) {
      case 'pdf':
        return 'PDF Processing & Page Manager';
      case 'conversion':
      case 'conversions':
      case 'convert':
        return 'Document Conversions Studio';
      case 'image':
      case 'images':
      case 'image-compressor':
        return 'Image Converter & Compressor Studio';
      case 'ai':
      case 'intelligence':
        return 'AI Document Intelligence Suite';
      case 'security':
      case 'privacy':
        return 'Security & Privacy Suite';
      case 'archive':
      case 'compression':
        return 'Archive & Compression Studio';
      case 'video':
        return 'Video Conversion & Compression Suite';
      case 'media':
      case 'audio':
        return 'Media Downloader & Audio Studio';
      default:
        return 'Tools Studio';
    }
  }

  String get _subtitle {
    switch (_catKey) {
      case 'pdf':
        return 'Edit, merge, split, compress, reorder, and permanently protect PDF documents with zero cloud uploads.';
      case 'conversion':
      case 'conversions':
      case 'convert':
        return 'Bidirectional document conversions between PDF, Word, Excel, PowerPoint, and high-resolution images.';
      case 'image':
      case 'images':
      case 'image-compressor':
        return 'Convert between PNG, JPG, WebP, HEIC & BMP formats, plus multi-level lossless & lossy image compression.';
      case 'ai':
      case 'intelligence':
        return 'Multimodal OCR, semantic comparison, document Q&A, translation & automated classification.';
      case 'security':
      case 'privacy':
        return 'AES-256 password encryption, permanent smart redaction, cryptographic digital signatures & metadata sanitization.';
      case 'archive':
      case 'compression':
        return 'Extract, inspect, create, and convert .ZIP, .RAR, .TAR, .GZ, .7Z, and .BZ2 archives with multi-level compression.';
      case 'video':
        return 'Convert videos between MP4, WebM, MOV, and animated GIF formats with fast GPU-backed presets.';
      case 'media':
      case 'audio':
        return 'Download audio/video from YouTube & Spotify, plus high-fidelity audio format conversion.';
      default:
        return 'Process and transform documents with local and cloud-accelerated intelligence.';
    }
  }

  String get _searchPlaceholder {
    switch (_catKey) {
      case 'pdf':
        return 'Search PDF Processing & Page Manager...';
      case 'conversion':
      case 'conversions':
      case 'convert':
        return 'Search Document Conversions Studio...';
      case 'image':
      case 'images':
      case 'image-compressor':
        return 'Search Image Converter & Compressor Studio...';
      case 'ai':
      case 'intelligence':
        return 'Search AI Document Intelligence Suite...';
      case 'security':
      case 'privacy':
        return 'Search Security & Privacy Suite...';
      case 'archive':
      case 'compression':
        return 'Search Archive & Compression Studio...';
      case 'video':
        return 'Search Video Conversion & Compression Suite...';
      default:
        return 'Search $_title...';
    }
  }

  List<ToolItem> get _categoryTools {
    switch (_catKey) {
      case 'pdf':
        return AppTools.pdfTools;
      case 'conversion':
      case 'conversions':
      case 'convert':
        return AppTools.conversionTools;
      case 'image':
      case 'images':
      case 'image-compressor':
        return [...AppTools.imageFormatTools, ...AppTools.imageCompressorTools];
      case 'ai':
      case 'intelligence':
        return AppTools.aiTools;
      case 'security':
      case 'privacy':
        return AppTools.securityTools;
      case 'archive':
      case 'compression':
        return AppTools.archiveTools;
      case 'video':
        return [...AppTools.videoConverterTools, ...AppTools.videoCompressorTools];
      case 'media':
      case 'audio':
        return AppTools.audioConverterTools;
      default:
        return AppTools.pdfTools;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredTools = _categoryTools.where((tool) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return tool.label.toLowerCase().contains(q) || tool.description.toLowerCase().contains(q);
    }).toList();

    return AppShell(
      title: _title,
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ],
      child: Column(
        children: [
          // Studio Hero Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
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
                  Text(
                    _title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: _searchPlaceholder,
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Tools Grid
          Expanded(
            child: filteredTools.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.searchX,
                          size: 36,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No tools found for "$_searchQuery"',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredTools.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.74,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 14,
                    ),
                    itemBuilder: (context, index) {
                      return ToolCard(tool: filteredTools[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
