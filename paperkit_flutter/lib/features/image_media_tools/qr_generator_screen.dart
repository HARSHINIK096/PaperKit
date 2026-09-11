import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/empty_state_view.dart';

class QrGeneratorScreen extends StatelessWidget {
  const QrGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'Qr Generator Screen',
      showBottomNav: false,
      child: EmptyStateView(
        icon: LucideIcons.fileText,
        title: 'Qr Generator Screen',
        description: 'This tool is currently in development. Please check back soon.',
      ),
    );
  }
}
