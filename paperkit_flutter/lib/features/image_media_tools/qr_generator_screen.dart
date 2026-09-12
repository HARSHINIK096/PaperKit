import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/how_it_works_carousel.dart';

class QrGeneratorScreen extends StatelessWidget {
  const QrGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'QR Code Generator',
      showBottomNav: false,
      child: Column(
        children: const [
          HowItWorksCarousel(
            toolId: 'qr-generator',
            padding: EdgeInsets.all(16),
          ),
          Expanded(
            child: EmptyStateView(
              icon: LucideIcons.qrCode,
              title: 'QR Code Generator',
              description: 'This tool is currently in development. Please check back soon.',
            ),
          ),
        ],
      ),
    );
  }
}
