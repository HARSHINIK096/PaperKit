import 'package:flutter/material.dart';
import 'how_it_works_carousel.dart';

class ToolHowItWorksItem {
  final IconData icon;
  final String title;
  final String description;
  final Color? accentColor;

  const ToolHowItWorksItem({
    required this.icon,
    required this.title,
    required this.description,
    this.accentColor,
  });
}

class ToolHowItWorksCard extends StatelessWidget {
  final String toolId;
  final Color primaryColor;
  final List<ToolHowItWorksItem>? customItems;

  const ToolHowItWorksCard({
    super.key,
    required this.toolId,
    required this.primaryColor,
    this.customItems,
  });

  @override
  Widget build(BuildContext context) {
    return HowItWorksCarousel(
      toolId: toolId,
      color: primaryColor,
      padding: EdgeInsets.zero,
    );
  }
}

