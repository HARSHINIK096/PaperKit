import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/empty_state_view.dart';

class BookletPdfScreen extends StatelessWidget {
  const BookletPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'Booklet Pdf Screen',
      showBottomNav: false,
      child: EmptyStateView(
        icon: LucideIcons.fileText,
        title: 'Booklet Pdf Screen',
        description: 'This tool is currently in development. Please check back soon.',
      ),
    );
  }
}
