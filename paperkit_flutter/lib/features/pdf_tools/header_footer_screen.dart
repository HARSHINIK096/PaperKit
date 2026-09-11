import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/empty_state_view.dart';

class HeaderFooterScreen extends StatelessWidget {
  const HeaderFooterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'Header Footer Screen',
      showBottomNav: false,
      child: EmptyStateView(
        icon: LucideIcons.fileText,
        title: 'Header Footer Screen',
        description: 'This tool is currently in development. Please check back soon.',
      ),
    );
  }
}
