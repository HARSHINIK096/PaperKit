import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Column(
        children: [
          // Top User Gradient Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 16,
              bottom: 22,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF1D4ED8),
                  Color(0xFF4338CA),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with Avatar & Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // OS Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'OS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // Close button
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.white, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Open Source User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'user@paperkit.local',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                // Studio Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.shieldCheck, size: 13, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        'OPEN SOURCE STUDIO',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Drawer Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                // Section Title: EXCLUSIVE AVAILABLE TOOLS
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text(
                    'EXCLUSIVE AVAILABLE TOOLS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Tool 1: PDF Editor
                _buildExclusiveToolTile(
                  context,
                  icon: LucideIcons.fileText,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF2563EB),
                  title: 'PDF Editor',
                  badge: '3 Edits/Day',
                  route: '/tools/pdf-editor',
                  isDark: isDark,
                ),
                // Tool 2: AI Assistant
                _buildExclusiveToolTile(
                  context,
                  icon: LucideIcons.bot,
                  iconBg: const Color(0xFFF5F3FF),
                  iconColor: const Color(0xFF7C3AED),
                  title: 'AI Assistant',
                  badge: '5 AI/Day',
                  route: '/tools/ai-chat',
                  isDark: isDark,
                ),
                // Tool 3: Image Adjuster
                _buildExclusiveToolTile(
                  context,
                  icon: LucideIcons.slidersHorizontal,
                  iconBg: const Color(0xFFFDF2F8),
                  iconColor: const Color(0xFFDB2777),
                  title: 'Image Adjuster',
                  badge: 'Unlimited',
                  route: '/tools/image-adjust',
                  isDark: isDark,
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                ),

                // Navigation Items
                _buildNavTile(
                  context,
                  icon: LucideIcons.home,
                  title: 'Home',
                  route: '/',
                  isDark: isDark,
                ),
                _buildNavTile(
                  context,
                  icon: LucideIcons.sparkles,
                  title: 'Welcome & Feature Tour',
                  route: '/welcome',
                  isDark: isDark,
                ),
                _buildNavTile(
                  context,
                  icon: LucideIcons.files,
                  title: 'My Files',
                  route: '/files',
                  isDark: isDark,
                ),
                _buildNavTile(
                  context,
                  icon: LucideIcons.clock,
                  title: 'Recent Files',
                  route: '/history',
                  isDark: isDark,
                ),
                _buildNavTile(
                  context,
                  icon: LucideIcons.star,
                  title: 'Favorites',
                  route: '/files',
                  isDark: isDark,
                ),
                _buildNavTile(
                  context,
                  icon: LucideIcons.trash2,
                  title: 'Trash',
                  route: '/files',
                  isDark: isDark,
                ),
                _buildNavTile(
                  context,
                  icon: LucideIcons.settings,
                  title: 'Settings',
                  route: '/profile',
                  isDark: isDark,
                ),
                _buildNavTile(
                  context,
                  icon: LucideIcons.helpCircle,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('MASKERV Open Source PDF Studio • Offline First & AI Powered'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                _buildNavTile(
                  context,
                  icon: LucideIcons.share2,
                  title: 'Share MASKERV',
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sharing MASKERV PDF & Media Studio...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Drawer Bottom Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
                ),
              ),
            ),
            child: Text(
              'MASKERV Open-Source PDF Suite',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExclusiveToolTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String badge,
    required String route,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        dense: true,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              badge,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFFCBD5E1)),
          ],
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
          context.push(route);
        },
      ),
    );
  }

  Widget _buildNavTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      dense: true,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 17, color: const Color(0xFF3B82F6)),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF334155),
        ),
      ),
      trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFFCBD5E1)),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop();
        if (onTap != null) {
          onTap();
        } else if (route != null) {
          context.go(route);
        }
      },
    );
  }
}
