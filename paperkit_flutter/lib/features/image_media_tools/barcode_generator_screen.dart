import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/empty_state_view.dart';

class BarcodeGeneratorScreen extends StatelessWidget {
  const BarcodeGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'Barcode Generator Screen',
      showBottomNav: false,
      child: EmptyStateView(
        icon: LucideIcons.fileText,
        title: 'Barcode Generator Screen',
        description: 'This tool is currently in development. Please check back soon.',
      ),
    );
  }
}
