import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'domain_item.dart';

export 'domain_item.dart';

enum ToolCategory {
  pdf,
  security,
  academic,
  scanner,
  cognitive,
  voice,
  accessibility,
  legal,
  forms,
  diagram,
  workspace,
  p2p,
  analytics,
  translation,
  publishing,
  ai,
  convert,
  image,
  video,
  audio,
  archive,
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

  /// Primary functional domain number (1..15, or null for general utilities)
  final int? domainNumber;
  /// Primary functional domain name (e.g. 'Domain 8 — Legal & Forensic Compliance Audit Suite')
  final String? domainName;
  /// Primary functional domain enum ID
  final DomainId? domainId;

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
    this.domainNumber,
    this.domainName,
    this.domainId,
  });

  /// Formatted badge string for search and listings: e.g. "Domain 8: Legal & Forensic"
  String get domainBadge {
    if (domainNumber != null && domainNumber! >= 1 && domainNumber! <= 15) {
      final domain = DomainRegistry.getByNumber(domainNumber!);
      if (domain != null) {
        return 'Domain $domainNumber: ${domain.shortName}';
      }
      return 'Domain $domainNumber';
    }
    return 'General Utility';
  }

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
