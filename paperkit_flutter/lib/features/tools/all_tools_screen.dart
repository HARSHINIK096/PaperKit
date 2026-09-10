import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_tools.dart';
import '../../core/models/tool_item.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/particle_background.dart';
import '../../core/widgets/tool_card.dart';

class AllToolsScreen extends StatefulWidget {
  const AllToolsScreen({super.key});

  @override
  State<AllToolsScreen> createState() => _AllToolsScreenState();
}

class _AllToolsScreenState extends State<AllToolsScreen> {
  String _searchQuery = '';

  // Custom tool sub-lists for Organize PDF & Convert to/from PDF matching Image 1
  static const List<ToolItem> _organizePdfTools = [
    ToolItem(
      id: 'merge-pdf',
      label: 'Merge PDF',
      description: 'Combine multiple PDFs into one',
      route: '/tools/merge',
      icon: LucideIcons.scan,
      color: Color(0xFF2563EB),
      softColor: Color(0xFFEFF6FF),
      category: ToolCategory.pdf,
    ),
    ToolItem(
      id: 'split-pdf',
      label: 'Split PDF',
      description: 'Split by ranges or single pages',
      route: '/tools/split',
      icon: LucideIcons.split,
      color: Color(0xFFEF4444),
      softColor: Color(0xFFFEF2F2),
      category: ToolCategory.pdf,
    ),
    ToolItem(
      id: 'extract-pages',
      label: 'Extract Pages',
      description: 'Extract specific pages into new PDF',
      route: '/tools/extract-pages',
      icon: LucideIcons.checkSquare,
      color: Color(0xFF0D9488),
      softColor: Color(0xFFF0FDFA),
      category: ToolCategory.pdf,
    ),
    ToolItem(
      id: 'remove-pages',
      label: 'Remove Pages',
      description: 'Delete unwanted pages from PDF',
      route: '/tools/organize-pages',
      icon: LucideIcons.trash2,
      color: Color(0xFFDC2626),
      softColor: Color(0xFFFEF2F2),
      category: ToolCategory.pdf,
    ),
    ToolItem(
      id: 'reorder-pages',
      label: 'Reorder Pages',
      description: 'Rearrange page sequences',
      route: '/tools/organize-pages',
      icon: LucideIcons.menu,
      color: Color(0xFF3B82F6),
      softColor: Color(0xFFEFF6FF),
      category: ToolCategory.pdf,
    ),
    ToolItem(
      id: 'rotate-pdf',
      label: 'Rotate PDF',
      description: 'Rotate pages orientation',
      route: '/tools/rotate',
      icon: LucideIcons.rotateCw,
      color: Color(0xFF2563EB),
      softColor: Color(0xFFEFF6FF),
      category: ToolCategory.pdf,
    ),
  ];

  static const List<ToolItem> _convertToPdfTools = [
    ToolItem(
      id: 'word-to-pdf',
      label: 'Word to PDF',
      description: 'Convert Word docs to PDF',
      route: '/tools/convert?from=word&to=pdf',
      icon: LucideIcons.fileText,
      color: Color(0xFF2563EB),
      softColor: Color(0xFFEFF6FF),
      category: ToolCategory.convert,
    ),
    ToolItem(
      id: 'excel-to-pdf',
      label: 'Excel to PDF',
      description: 'Convert Excel spreadsheets to PDF',
      route: '/tools/convert?from=excel&to=pdf',
      icon: LucideIcons.fileSpreadsheet,
      color: Color(0xFF10B981),
      softColor: Color(0xFFECFDF5),
      category: ToolCategory.convert,
    ),
    ToolItem(
      id: 'ppt-to-pdf',
      label: 'PPT to PDF',
      description: 'Convert PowerPoint slides to PDF',
      route: '/tools/convert?from=ppt&to=pdf',
      icon: LucideIcons.monitor,
      color: Color(0xFFF59E0B),
      softColor: Color(0xFFFFFBEB),
      category: ToolCategory.convert,
    ),
    ToolItem(
      id: 'image-to-pdf',
      label: 'Image to PDF',
      description: 'Convert images to PDF format',
      route: '/tools/convert?from=image&to=pdf',
      icon: LucideIcons.image,
      color: Color(0xFF8B5CF6),
      softColor: Color(0xFFF5F3FF),
      category: ToolCategory.convert,
    ),
    ToolItem(
      id: 'txt-to-pdf',
      label: 'TXT to PDF',
      description: 'Convert text files to PDF',
      route: '/tools/convert?from=txt&to=pdf',
      icon: LucideIcons.fileText,
      color: Color(0xFF6366F1),
      softColor: Color(0xFFEEF2FF),
      category: ToolCategory.convert,
    ),
    ToolItem(
      id: 'html-to-pdf',
      label: 'HTML to PDF',
      description: 'Convert web pages to PDF',
      route: '/tools/convert?from=html&to=pdf',
      icon: LucideIcons.code,
      color: Color(0xFF14B8A6),
      softColor: Color(0xFFF0FDFA),
      category: ToolCategory.convert,
    ),
  ];

  static const List<ToolItem> _convertFromPdfTools = [
    ToolItem(
      id: 'pdf-to-word',
      label: 'PDF to Word',
      description: 'Convert PDF to editable DOCX',
      route: '/tools/convert?from=pdf&to=word',
      icon: LucideIcons.fileText,
      color: Color(0xFF2563EB),
      softColor: Color(0xFFEFF6FF),
      category: ToolCategory.convert,
    ),
    ToolItem(
      id: 'pdf-to-excel',
      label: 'PDF to Excel',
      description: 'Extract tables to XLSX',
      route: '/tools/convert?from=pdf&to=excel',
      icon: LucideIcons.fileSpreadsheet,
      color: Color(0xFF10B981),
      softColor: Color(0xFFECFDF5),
      category: ToolCategory.convert,
    ),
    ToolItem(
      id: 'pdf-to-ppt',
      label: 'PDF to PPT',
      description: 'Convert PDF pages to PPT slides',
      route: '/tools/convert?from=pdf&to=ppt',
      icon: LucideIcons.presentation,
      color: Color(0xFFF59E0B),
      softColor: Color(0xFFFFFBEB),
      category: ToolCategory.convert,
    ),
    ToolItem(
      id: 'pdf-to-image',
      label: 'PDF to Image',
      description: 'Extract PDF pages as images',
      route: '/tools/convert?from=pdf&to=image',
      icon: LucideIcons.images,
      color: Color(0xFF8B5CF6),
      softColor: Color(0xFFF5F3FF),
      category: ToolCategory.convert,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isSearching = _searchQuery.trim().isNotEmpty;
    final searchResults = isSearching
        ? AppTools.allTools.where((t) {
            final q = _searchQuery.toLowerCase();
            return t.label.toLowerCase().contains(q) ||
                t.description.toLowerCase().contains(q);
          }).toList()
        : <ToolItem>[];

    return AppShell(
      title: 'Tools',
      child: Stack(
        children: [
          // Background Particle Effect
          const Positioned.fill(
            child: ParticleBackground(
              numberOfParticles: 35,
              particleColor: Color(0xFF3B82F6),
              enableLines: true,
              maxSpeed: 0.25,
            ),
          ),

          // Main Scrollable Area
          Column(
            children: [
              // Search Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search 40+ PDF, AI, Media & Studio tools...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(LucideIcons.search, size: 19, color: Color(0xFF64748B)),
                    suffixIcon: isSearching
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Body Content
              Expanded(
                child: isSearching
                    ? _buildSearchResults(searchResults, isDark)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                        children: [
                          // 1. Organize PDF (Matching Image 1)
                          _buildFunctionalCard(
                            context,
                            title: 'Organize PDF',
                            viewAllRoute: '/category/pdf',
                            tools: _organizePdfTools,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),

                          // 2. Convert to PDF (Matching Image 1)
                          _buildFunctionalCard(
                            context,
                            title: 'Convert to PDF',
                            viewAllRoute: '/category/convert',
                            tools: _convertToPdfTools,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),

                          // 3. Convert from PDF
                          _buildFunctionalCard(
                            context,
                            title: 'Convert from PDF',
                            viewAllRoute: '/category/convert',
                            tools: _convertFromPdfTools,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),

                          // 4. Security & Privacy
                          _buildFunctionalCard(
                            context,
                            title: 'Security & Privacy',
                            viewAllRoute: '/category/security',
                            tools: AppTools.securityTools,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),

                          // 5. AI Document Intelligence
                          _buildFunctionalCard(
                            context,
                            title: 'AI Document Intelligence',
                            viewAllRoute: '/category/ai',
                            tools: AppTools.aiTools,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),

                          // 6. Image Format Converter & Manipulator
                          _buildFunctionalCard(
                            context,
                            title: 'Image Format Converter',
                            viewAllRoute: '/category/image',
                            tools: AppTools.imageFormatTools,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),

                          // 7. Image Compressor ⭐
                          _buildFunctionalCard(
                            context,
                            title: 'Image Compressor ⭐',
                            viewAllRoute: '/category/image-compressor',
                            tools: AppTools.imageCompressorTools,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),

                          // 8. Media Downloader (YouTube & Spotify)
                          _buildFunctionalCard(
                            context,
                            title: 'Media Downloader (YouTube & Spotify)',
                            viewAllRoute: '/category/media-downloader',
                            tools: AppTools.mediaDownloaderTools,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),

                          // 9. Video Format Converter & Compressor
                          _buildFunctionalCard(
                            context,
                            title: 'Video Format Converter & Compressor',
                            viewAllRoute: '/category/video',
                            tools: [
                              ...AppTools.videoConverterTools,
                              ...AppTools.videoCompressorTools,
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),

                          // 10. Archive & Compression
                          _buildFunctionalCard(
                            context,
                            title: 'Archive & Compression',
                            viewAllRoute: '/category/archive',
                            tools: AppTools.archiveTools,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),

                          // 11. Audio Format Converter
                          _buildFunctionalCard(
                            context,
                            title: 'Audio Format Converter',
                            viewAllRoute: '/category/audio',
                            tools: AppTools.audioConverterTools,
                            isDark: isDark,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<ToolItem> results, bool isDark) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.searchX, size: 48, color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'No tools match "$_searchQuery"',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: results.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.72,
        crossAxisSpacing: 8,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (context, index) {
        return ToolCard(tool: results[index], compact: true);
      },
    );
  }

  Widget _buildFunctionalCard(
    BuildContext context, {
    required String title,
    required String viewAllRoute,
    required List<ToolItem> tools,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Title + View All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(viewAllRoute);
                },
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Inner 4-column tool items grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tools.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.72,
              crossAxisSpacing: 6,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, index) {
              return ToolCard(tool: tools[index], compact: true);
            },
          ),
        ],
      ),
    );
  }
}
