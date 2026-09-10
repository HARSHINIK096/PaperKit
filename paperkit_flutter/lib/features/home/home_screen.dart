import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_tools.dart';
import '../../core/models/tool_item.dart';
import '../../core/providers/backend_provider.dart';
import '../../core/providers/files_provider.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/file_list_item.dart';
import '../../core/widgets/tool_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _droppedFile;
  Map<String, int>? _storageBreakdown;

  @override
  void initState() {
    super.initState();
    _loadStorageStats();
  }

  Future<void> _loadStorageStats() async {
    try {
      final breakdown = await StorageService().getStorageBreakdown();
      if (mounted) {
        setState(() => _storageBreakdown = breakdown);
      }
    } catch (_) {}
  }

  Future<void> _pickDropzoneFile() async {
    HapticFeedback.lightImpact();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _droppedFile = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backend = context.watch<BackendProvider>();
    final filesProv = context.watch<FilesProvider>();

    return AppShell(
      title: 'PaperKit',
      actions: [
        // Live Server Sync Beacon (Green = Online, Red = Offline)
        InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            final online = await backend.checkHealth();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        online ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(backend.statusMessage),
                    ],
                  ),
                  backgroundColor: online ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: backend.statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: backend.statusColor.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: backend.statusColor,
                    boxShadow: [
                      BoxShadow(
                        color: backend.statusColor.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  backend.isConnected ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    color: backend.statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(LucideIcons.history, size: 20),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.push('/history');
          },
          tooltip: 'Processing History',
        ),
        const SizedBox(width: 6),
      ],
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // ── Header Greeting ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PaperKit Intelligent Platform',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Process, summarize, compare, and protect your documents with zero friction.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // ── Smart Document Dropzone & Recommendation Engine ──────
          _buildSmartDropzone(context, isDark),
          const SizedBox(height: 14),

          // ── Storage Overview Bar ─────────────────────────────────
          if (_storageBreakdown != null) _buildStorageBar(context, isDark),
          const SizedBox(height: 14),

          // ── Smart Scanner Hero Banner ────────────────────────────
          _buildScannerBanner(context, isDark),
          const SizedBox(height: 20),

          // ── Categories Horizontal Filter Pills ───────────────────
          _buildCategoryPills(context, isDark),
          const SizedBox(height: 24),

          // ── 1. Featured Quick Launch Grid ───────────────────────
          _buildCategorySection(
            context,
            isDark: isDark,
            title: 'Featured Tools',
            categoryId: 'all',
            tools: AppTools.featuredTools,
            customRoute: '/tools',
            viewAllLabel: 'See All (40+)',
          ),
          const SizedBox(height: 26),

          // ── 2. AI Document Intelligence Category Section ─────────
          _buildCategorySection(
            context,
            isDark: isDark,
            title: 'AI Document Intelligence',
            categoryId: 'ai',
            tools: AppTools.aiTools,
          ),
          const SizedBox(height: 26),

          // ── 3. PDF Processing & Pages Category Section ───────────
          _buildCategorySection(
            context,
            isDark: isDark,
            title: 'PDF Processing & Pages',
            categoryId: 'pdf',
            tools: AppTools.pdfTools,
          ),
          const SizedBox(height: 26),

          // ── 4. Security & Privacy Category Section ───────────────
          _buildCategorySection(
            context,
            isDark: isDark,
            title: 'Security & Privacy',
            categoryId: 'security',
            tools: AppTools.securityTools,
          ),
          const SizedBox(height: 26),

          // ── 5. Document Conversions Category Section ─────────────
          _buildCategorySection(
            context,
            isDark: isDark,
            title: 'Conversions',
            categoryId: 'conversions',
            tools: AppTools.conversionTools,
          ),
          const SizedBox(height: 26),

          // ── 6. Image Format Converter Section ────────────────────
          _buildCategorySection(
            context,
            isDark: isDark,
            title: 'Image Format Converter',
            categoryId: 'image',
            tools: AppTools.imageFormatTools,
          ),
          const SizedBox(height: 26),

          // ── 7. Image Compressor ⭐ Section ───────────────────────
          _buildCategorySection(
            context,
            isDark: isDark,
            title: 'Image Compressor ⭐',
            categoryId: 'image',
            tools: AppTools.imageCompressorTools,
          ),
          const SizedBox(height: 26),

          // ── 8. Media Downloader (YouTube & Spotify) Section ──────
          _buildCategorySection(
            context,
            isDark: isDark,
            title: 'Media Downloader (YouTube & Spotify)',
            categoryId: 'media',
            tools: AppTools.mediaDownloaderTools,
          ),
          const SizedBox(height: 26),

          // ── 9. Video Format Converter Section ────────────────────
          _buildCategorySection(
            context,
            isDark: isDark,
            title: 'Video Format Converter',
            categoryId: 'video',
            tools: AppTools.videoConverterTools,
          ),
          const SizedBox(height: 26),

          // ── 10. Video Compressor Section ─────────────────────────
          _buildCategorySection(
            context,
            isDark: isDark,
            title: 'Video Compressor',
            categoryId: 'video',
            tools: AppTools.videoCompressorTools,
          ),
          const SizedBox(height: 26),

          // ── 11. Archive & Compression Section ────────────────────
          _buildCategorySection(
            context,
            isDark: isDark,
            title: 'Archive & Compression (.ZIP, .RAR, .TAR, .GZ, .7Z, .BZ2)',
            categoryId: 'archive',
            tools: AppTools.archiveTools,
          ),
          const SizedBox(height: 26),

          // ── 12. Audio Format Converter Section ───────────────────
          _buildCategorySection(
            context,
            isDark: isDark,
            title: 'Audio Format Converter',
            categoryId: 'audio',
            tools: AppTools.audioConverterTools,
          ),
          const SizedBox(height: 26),

          // ── Recent Documents Section ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Documents',
                style: TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              if (filesProv.files.isNotEmpty)
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.go('/files');
                  },
                  child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (filesProv.recentFiles.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceElevatedDark : AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.filePlus,
                        size: 24,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No recent documents processed',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scan a page or pick any tool above to get started',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filesProv.recentFiles.map(
              (file) => FileListItem(
                file: file,
                onFavoriteToggle: () => filesProv.toggleFavorite(file.id),
                onDelete: () => filesProv.deleteFile(file.id),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSmartDropzone(BuildContext context, bool isDark) {
    if (_droppedFile == null) {
      return InkWell(
        onTap: _pickDropzoneFile,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(LucideIcons.sparkles, size: 22, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Drop or Pick Any Document / File',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Auto-detects PDFs, Images, Word, & Archives',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMutedLight),
            ],
          ),
        ),
      );
    }

    final fileName = _droppedFile!.path.split(Platform.pathSeparator).last;
    final fileBytes = _droppedFile!.lengthSync();
    final fileKb = (fileBytes / 1024).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.fileText, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '($fileKb KB)',
                style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _droppedFile = null),
                child: const Text('Clear', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'RECOMMENDED 1-CLICK OPERATIONS:',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDropzoneAction(
                label: 'Quick Preview',
                icon: LucideIcons.eye,
                color: AppColors.primary,
                onTap: () => OpenFilex.open(_droppedFile!.path),
              ),
              _buildDropzoneAction(
                label: 'AI Summary',
                icon: LucideIcons.sparkles,
                color: AppColors.toolPurple,
                onTap: () => context.push('/ai/summarize'),
              ),
              _buildDropzoneAction(
                label: 'Compress',
                icon: LucideIcons.minimize2,
                color: AppColors.toolOrange,
                onTap: () => context.push('/tools/compress'),
              ),
              _buildDropzoneAction(
                label: 'OCR Text',
                icon: LucideIcons.scanLine,
                color: AppColors.toolBlue,
                onTap: () => context.push('/ai/ocr'),
              ),
              _buildDropzoneAction(
                label: 'Password Lock',
                icon: LucideIcons.lock,
                color: AppColors.toolRed,
                onTap: () => context.push('/security/protect'),
              ),
              _buildDropzoneAction(
                label: 'Archive Studio',
                icon: LucideIcons.archive,
                color: AppColors.toolTeal,
                onTap: () => context.push('/tools/archive'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropzoneAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageBar(BuildContext context, bool isDark) {
    final totalBytes = _storageBreakdown!['total'] ?? 0;
    final totalMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
    final ratio = (totalBytes / (500 * 1024 * 1024)).clamp(0.0, 1.0);

    return InkWell(
      onTap: () => context.push('/storage'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Local Storage: $totalMb MB used',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  'View Breakdown',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.toDouble(),
                minHeight: 6,
                backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context, {
    required bool isDark,
    required String title,
    required String categoryId,
    required List<ToolItem> tools,
    String? customRoute,
    String viewAllLabel = 'View All',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                if (customRoute != null) {
                  context.push(customRoute);
                } else {
                  context.push('/category/$categoryId');
                }
              },
              child: Text(viewAllLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tools.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.74,
            crossAxisSpacing: 6,
            mainAxisSpacing: 14,
          ),
          itemBuilder: (context, index) {
            return ToolCard(tool: tools[index]);
          },
        ),
      ],
    );
  }

  Widget _buildScannerBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'SMART SCANNER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Scan Documents Instantly',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Edge-detection, perspective correction & export to PDF',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.go('/scanner');
                  },
                  icon: const Icon(LucideIcons.camera, size: 16, color: AppColors.primary),
                  label: const Text('Start Scanning', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.scanLine,
              size: 34,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPills(BuildContext context, bool isDark) {
    final categories = [
      {'name': 'PDF Tools', 'cat': 'pdf', 'icon': LucideIcons.fileText, 'color': AppColors.toolBlue},
      {'name': 'AI Intelligence', 'cat': 'ai', 'icon': LucideIcons.sparkles, 'color': AppColors.toolPurple},
      {'name': 'Conversions', 'cat': 'conversions', 'icon': LucideIcons.fileSpreadsheet, 'color': AppColors.toolGreen},
      {'name': 'Security', 'cat': 'security', 'icon': LucideIcons.shieldCheck, 'color': AppColors.toolRed},
      {'name': 'Images', 'cat': 'image', 'icon': LucideIcons.image, 'color': AppColors.toolPink},
      {'name': 'Video & Audio', 'cat': 'video', 'icon': LucideIcons.video, 'color': AppColors.toolIndigo},
      {'name': 'Archive Studio', 'cat': 'archive', 'icon': LucideIcons.archive, 'color': AppColors.toolOrange},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final color = cat['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                context.push('/category/${cat['cat']}');
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(cat['icon'] as IconData, size: 17, color: color),
                    const SizedBox(width: 9),
                    Text(
                      cat['name'] as String,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

