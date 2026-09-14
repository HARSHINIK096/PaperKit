import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/providers/files_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_shell.dart';

class StorageScreen extends StatelessWidget {
  const StorageScreen({super.key});

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filesProv = context.watch<FilesProvider>();
    final breakdown = filesProv.storageBreakdown;
    final total = breakdown['total'] ?? 0;

    return AppShell(
      title: 'Storage Breakdown',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total Storage Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.hardDrive, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Local App Storage',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _formatBytes(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${filesProv.files.length} managed documents & assets',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Categories Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),

          _buildBreakdownTile(
            label: 'PDF Documents',
            bytes: breakdown['pdf'] ?? 0,
            icon: LucideIcons.fileText,
            color: AppColors.toolRed,
            isDark: isDark,
          ),
          _buildBreakdownTile(
            label: 'Images & Photos',
            bytes: breakdown['image'] ?? 0,
            icon: LucideIcons.image,
            color: AppColors.toolBlue,
            isDark: isDark,
          ),
          _buildBreakdownTile(
            label: 'Media & Audio',
            bytes: breakdown['media'] ?? 0,
            icon: LucideIcons.video,
            color: AppColors.toolPurple,
            isDark: isDark,
          ),
          _buildBreakdownTile(
            label: 'Archives & Other',
            bytes: breakdown['other'] ?? 0,
            icon: LucideIcons.archive,
            color: AppColors.toolOrange,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownTile({
    required String label,
    required int bytes,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Text(
            _formatBytes(bytes),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
