import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ToolCategory {
  pdf,
  ai,
  scanner,
  security,
  convert,
  image,
  video,
  audio,
  archive,
  academic,
  forms,
  utilities,
  media,
}

class ToolItem {
  final String id;
  final String label;
  final String description;
  final String route;
  final IconData icon;
  final Color color;
  final Color softColor;
  final ToolCategory category;
  final bool isNew;
  final bool isPro;
  final bool isAi;
  /// Searchable keywords for tool discovery (in addition to label/description)
  final List<String> tags;

  const ToolItem({
    required this.id,
    required this.label,
    required this.description,
    required this.route,
    required this.icon,
    required this.color,
    required this.softColor,
    required this.category,
    this.isNew = false,
    this.isPro = false,
    this.isAi = false,
    this.tags = const [],
  });

  static Color getSoftColor(Color baseColor) {
    if (baseColor == AppColors.toolBlue) return AppColors.toolBlueSoft;
    if (baseColor == AppColors.toolRed) return AppColors.toolRedSoft;
    if (baseColor == AppColors.toolGreen) return AppColors.toolGreenSoft;
    if (baseColor == AppColors.toolOrange) return AppColors.toolOrangeSoft;
    if (baseColor == AppColors.toolPurple) return AppColors.toolPurpleSoft;
    if (baseColor == AppColors.toolTeal) return AppColors.toolTealSoft;
    if (baseColor == AppColors.toolPink) return AppColors.toolPinkSoft;
    if (baseColor == AppColors.toolIndigo) return AppColors.toolIndigoSoft;
    return AppColors.primarySoft;
  }
}

