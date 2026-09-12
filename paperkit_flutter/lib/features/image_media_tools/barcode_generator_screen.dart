import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/how_it_works_carousel.dart';

class BarcodeGeneratorScreen extends StatelessWidget {
  const BarcodeGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Barcode Generator',
      showBottomNav: false,
      child: Column(
        children: const [
          HowItWorksCarousel(
            toolId: 'barcode-generator',
            padding: EdgeInsets.all(16),
          ),
          Expanded(
            child: EmptyStateView(
              icon: LucideIcons.barChart,
              title: 'Barcode Generator',
              description: 'This tool is currently in development. Please check back soon.',
            ),
          ),
        ],
      ),
    );
  }
}
