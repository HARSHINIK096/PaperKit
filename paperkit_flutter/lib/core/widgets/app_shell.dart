import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_tools.dart';
import '../theme/app_colors.dart';
import 'app_drawer.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showAppBar;
  final bool? showBottomNav;
  final List<Widget>? actions;

  const AppShell({
    super.key,
    required this.child,
    this.title,
    this.showAppBar = true,
    this.showBottomNav,
    this.actions,
  });

  bool _isIndividualToolRoute(String path) {
    // Check if the path is an individual tool execution screen
    const toolPrefixes = [
      '/tools/merge',
      '/tools/split',
      '/tools/compress',
      '/tools/convert',
      '/tools/rotate',
      '/tools/watermark',
      '/tools/organize',
      '/tools/extract',
      '/tools/pdf-to-pdfa',
      '/tools/pdf-editor',
      '/tools/protect',
      '/tools/smart-redaction',
      '/tools/digital-signature',
      '/tools/metadata',
      '/tools/image-converter',
      '/tools/image-compressor',
      '/tools/image-manipulator',
      '/tools/media-downloader',
      '/tools/audio-converter',
      '/tools/video-converter',
      '/tools/video-compressor',
      '/tools/archive-studio',
      '/ai/ask',
      '/ai/summarize',
      '/ai/ocr',
      '/ai/compare',
      '/ai/similarity-matrix',
      '/ai/search',
      '/ai/classify',
      '/ai/extract-info',
      '/ai/translate',
      '/ai/writing-assistant',
      '/ai/quality-checker',
      '/ai/extract-tables',
      '/ai/image-enhancer',
    ];

    for (final prefix in toolPrefixes) {
      if (path.startsWith(prefix)) return true;
    }
    return false;
  }

  String? _detectActiveCategory(String path) {
    if (path.startsWith('/category/') || path.startsWith('/tools/category/')) {
      final segments = Uri.parse(path).pathSegments;
      if (segments.isNotEmpty) {
        return segments.last;
      }
    }
    if (path == '/ai' || path == '/ai/hub') return 'ai';
    return null;
  }

  String _safeGetLocation(BuildContext context) {
    try {
      return GoRouterState.of(context).uri.path;
    } catch (_) {
      return '/';
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = _safeGetLocation(context);
    if (location.startsWith('/tools') || location.startsWith('/category')) return 1;
    if (location.startsWith('/scanner')) return 2;
    if (location.startsWith('/files')) return 3;
    if (location.startsWith('/profile') || location.startsWith('/history') || location.startsWith('/storage')) return 4;
    return 0; // Home
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.selectionClick();
    try {
      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/tools');
          break;
        case 2:
          context.go('/scanner');
          break;
        case 3:
          context.go('/files');
          break;
        case 4:
          context.go('/profile');
          break;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = _safeGetLocation(context);
    final isTool = _isIndividualToolRoute(location);
    final activeCategory = _detectActiveCategory(location);

    // Bottom nav bar hides automatically when inside any individual tool workflow
    final effectiveShowBottomNav = showBottomNav ?? (!isTool);
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: showAppBar
          ? AppBar(
              title: Text(
                title ?? 'PaperKit',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18.5, letterSpacing: -0.3),
              ),
              leading: Builder(
                builder: (scaffoldContext) => IconButton(
                  icon: const Icon(LucideIcons.menu, size: 22),
                  onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                  tooltip: 'Open Menu',
                ),
              ),
              actions: actions,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1.0),
                child: Container(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  height: 1.0,
                ),
              ),
            )
          : null,
      body: SafeArea(
        top: !showAppBar,
        bottom: !effectiveShowBottomNav,
        child: child,
      ),
      bottomNavigationBar: effectiveShowBottomNav
          ? (activeCategory != null
              ? _buildCategoryContextualNav(context, activeCategory, isDark)
              : _buildCustomBottomNav(context, selectedIndex, isDark))
          : null,
    );
  }

  // Dynamic Contextual Bottom Navigation Bar for Category Suites (Top 4 Tools)
  Widget _buildCategoryContextualNav(BuildContext context, String categoryKey, bool isDark) {
    final bgColor = isDark ? AppColors.surfaceDark : Colors.white;
    const activeColor = Color(0xFF2563EB);
    const inactiveColor = Color(0xFF64748B);
    final topTools = AppTools.getTopToolsForCategory(categoryKey);

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 4 Contextual Tools from this Suite
          ...topTools.map((tool) {
            return Expanded(
              child: _buildNavItem(
                icon: tool.icon,
                label: tool.label,
                isSelected: false,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push(tool.route);
                },
              ),
            );
          }),

          // 5. Exit / All Tools Tab
          Expanded(
            child: _buildNavItem(
              icon: LucideIcons.layoutGrid,
              label: 'All Tools',
              isSelected: false,
              activeColor: activeColor,
              inactiveColor: AppColors.primary,
              onTap: () {
                HapticFeedback.selectionClick();
                context.go('/tools');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBottomNav(BuildContext context, int selectedIndex, bool isDark) {
    final bgColor = isDark ? AppColors.surfaceDark : Colors.white;
    const activeColor = Color(0xFF2563EB);
    const inactiveColor = Color(0xFF94A3B8);

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              // 1. Home
              Expanded(
                child: _buildNavItem(
                  icon: LucideIcons.home,
                  label: 'Home',
                  isSelected: selectedIndex == 0,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () => _onItemTapped(0, context),
                ),
              ),
              // 2. Tools
              Expanded(
                child: _buildNavItem(
                  icon: LucideIcons.grid2x2,
                  label: 'Tools',
                  isSelected: selectedIndex == 1,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () => _onItemTapped(1, context),
                ),
              ),
              // Center Spacer for Camera FAB
              const SizedBox(width: 54),
              // 4. Files
              Expanded(
                child: _buildNavItem(
                  icon: LucideIcons.files,
                  label: 'Files',
                  isSelected: selectedIndex == 3,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () => _onItemTapped(3, context),
                ),
              ),
              // 5. Settings / Profile
              Expanded(
                child: _buildNavItem(
                  icon: LucideIcons.settings,
                  label: 'Settings',
                  isSelected: selectedIndex == 4,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () => _onItemTapped(4, context),
                ),
              ),
            ],
          ),

          // Center Floating Elevated Blue Camera Button
          Positioned(
            top: -16,
            child: GestureDetector(
              onTap: () => _onItemTapped(2, context),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.45),
                      blurRadius: 14,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white,
                    width: 3.5,
                  ),
                ),
                child: const Icon(
                  LucideIcons.camera,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? activeColor : inactiveColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 21,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
