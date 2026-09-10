import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showAppBar;
  final bool showBottomNav;
  final List<Widget>? actions;

  const AppShell({
    super.key,
    required this.child,
    this.title,
    this.showAppBar = true,
    this.showBottomNav = true,
    this.actions,
  });

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/tools') || location.startsWith('/category')) return 1;
    if (location.startsWith('/scanner')) return 2;
    if (location.startsWith('/files')) return 3;
    if (location.startsWith('/profile') || location.startsWith('/history') || location.startsWith('/storage')) return 4;
    return 0; // Home
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.selectionClick();
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(
                title ?? 'PaperKit',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18.5, letterSpacing: -0.3),
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
        bottom: !showBottomNav,
        child: child,
      ),
      bottomNavigationBar: showBottomNav
          ? Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1,
                  ),
                ),
              ),
              child: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (idx) => _onItemTapped(idx, context),
                backgroundColor: Colors.transparent,
                indicatorColor: AppColors.primary.withValues(alpha: 0.12),
                elevation: 0,
                height: 64,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(LucideIcons.home, size: 21),
                    selectedIcon: Icon(LucideIcons.home, size: 21, color: AppColors.primary),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(LucideIcons.grid, size: 21),
                    selectedIcon: Icon(LucideIcons.grid, size: 21, color: AppColors.primary),
                    label: 'Tools',
                  ),
                  NavigationDestination(
                    icon: Icon(LucideIcons.scanLine, size: 21),
                    selectedIcon: Icon(LucideIcons.scanLine, size: 21, color: AppColors.primary),
                    label: 'Scanner',
                  ),
                  NavigationDestination(
                    icon: Icon(LucideIcons.folder, size: 21),
                    selectedIcon: Icon(LucideIcons.folder, size: 21, color: AppColors.primary),
                    label: 'Files',
                  ),
                  NavigationDestination(
                    icon: Icon(LucideIcons.user, size: 21),
                    selectedIcon: Icon(LucideIcons.user, size: 21, color: AppColors.primary),
                    label: 'Profile',
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
