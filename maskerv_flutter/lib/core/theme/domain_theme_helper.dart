import 'package:flutter/material.dart';
import 'app_colors.dart';

class DomainTheme {
  final String domainId;
  final String name;
  final Color primaryColor;
  final Color softBgColor;
  final Color particleColor;
  final Color cloudSweepColor;
  final IconData defaultIcon;

  const DomainTheme({
    required this.domainId,
    required this.name,
    required this.primaryColor,
    required this.softBgColor,
    required this.particleColor,
    required this.cloudSweepColor,
    required this.defaultIcon,
  });
}

class DomainThemeHelper {
  static const Map<String, DomainTheme> domainThemes = {
    'pdf': DomainTheme(
      domainId: 'pdf',
      name: 'PDF Tools',
      primaryColor: AppColors.domainPdf,
      softBgColor: Color(0xFFEFF6FF),
      particleColor: Color(0xFF3B82F6),
      cloudSweepColor: Color(0xFF60A5FA),
      defaultIcon: Icons.picture_as_pdf,
    ),
    'image': DomainTheme(
      domainId: 'image',
      name: 'Image & Media',
      primaryColor: AppColors.domainImage,
      softBgColor: Color(0xFFF0FDF4),
      particleColor: Color(0xFF10B981),
      cloudSweepColor: Color(0xFF34D399),
      defaultIcon: Icons.image,
    ),
    'security': DomainTheme(
      domainId: 'security',
      name: 'Security & Redaction',
      primaryColor: AppColors.domainSecurity,
      softBgColor: Color(0xFFFEF2F2),
      particleColor: Color(0xFFEF4444),
      cloudSweepColor: Color(0xFFF87171),
      defaultIcon: Icons.security,
    ),
    'ai': DomainTheme(
      domainId: 'ai',
      name: 'AI Intelligence',
      primaryColor: AppColors.domainAi,
      softBgColor: Color(0xFFF5F3FF),
      particleColor: Color(0xFF8B5CF6),
      cloudSweepColor: Color(0xFFA78BFA),
      defaultIcon: Icons.auto_awesome,
    ),
    'forms': DomainTheme(
      domainId: 'forms',
      name: 'Smart Forms',
      primaryColor: AppColors.domainForms,
      softBgColor: Color(0xFFFFFBEB),
      particleColor: Color(0xFFF59E0B),
      cloudSweepColor: Color(0xFFFBBF24),
      defaultIcon: Icons.assignment,
    ),
    'accessibility': DomainTheme(
      domainId: 'accessibility',
      name: 'Accessibility & Reader',
      primaryColor: AppColors.domainAccessibility,
      softBgColor: Color(0xFFF0F9FF),
      particleColor: Color(0xFF06B6D4),
      cloudSweepColor: Color(0xFF38BDF8),
      defaultIcon: Icons.accessibility_new,
    ),
    'cognitive': DomainTheme(
      domainId: 'cognitive',
      name: 'Cognitive Retention',
      primaryColor: AppColors.domainCognitive,
      softBgColor: Color(0xFFFF1744),
      particleColor: Color(0xFFE11D48),
      cloudSweepColor: Color(0xFFFB7185),
      defaultIcon: Icons.psychology,
    ),
    'diagram': DomainTheme(
      domainId: 'diagram',
      name: 'Diagram Studio',
      primaryColor: AppColors.domainDiagram,
      softBgColor: Color(0xFFF7FEE7),
      particleColor: Color(0xFF84CC16),
      cloudSweepColor: Color(0xFFA3E635),
      defaultIcon: Icons.account_tree,
    ),
    'legal': DomainTheme(
      domainId: 'legal',
      name: 'Legal Audit & Chain',
      primaryColor: AppColors.domainLegal,
      softBgColor: Color(0xFFF8FAFC),
      particleColor: Color(0xFF64748B),
      cloudSweepColor: Color(0xFF94A3B8),
      defaultIcon: Icons.gavel,
    ),
    'p2p': DomainTheme(
      domainId: 'p2p',
      name: 'AirShare P2P Mesh',
      primaryColor: AppColors.domainP2p,
      softBgColor: Color(0xFFEEF2FF),
      particleColor: Color(0xFF6366F1),
      cloudSweepColor: Color(0xFF818CF8),
      defaultIcon: Icons.share,
    ),
    'publishing': DomainTheme(
      domainId: 'publishing',
      name: 'Publishing Studio',
      primaryColor: AppColors.domainPublishing,
      softBgColor: Color(0xFFFFF7ED),
      particleColor: Color(0xFFF97316),
      cloudSweepColor: Color(0xFFFB923C),
      defaultIcon: Icons.menu_book,
    ),
    'translation': DomainTheme(
      domainId: 'translation',
      name: 'Translation Hub',
      primaryColor: AppColors.domainTranslation,
      softBgColor: Color(0xFFEFF6FF),
      particleColor: Color(0xFF3B82F6),
      cloudSweepColor: Color(0xFF60A5FA),
      defaultIcon: Icons.g_translate,
    ),
    'podcast': DomainTheme(
      domainId: 'podcast',
      name: 'Voice Podcast',
      primaryColor: AppColors.domainPodcast,
      softBgColor: Color(0xFFFAF5FF),
      particleColor: Color(0xFFA855F7),
      cloudSweepColor: Color(0xFFC084FC),
      defaultIcon: Icons.podcasts,
    ),
    'workspace': DomainTheme(
      domainId: 'workspace',
      name: 'Dual-Pane Workspace',
      primaryColor: AppColors.domainWorkspace,
      softBgColor: Color(0xFFECFDF5),
      particleColor: Color(0xFF10B981),
      cloudSweepColor: Color(0xFF34D399),
      defaultIcon: Icons.view_sidebar,
    ),
    'analytics': DomainTheme(
      domainId: 'analytics',
      name: 'Tabular Analytics',
      primaryColor: AppColors.domainAnalytics,
      softBgColor: Color(0xFFEEF2FF),
      particleColor: Color(0xFF1E40AF),
      cloudSweepColor: Color(0xFF3B82F6),
      defaultIcon: Icons.table_chart,
    ),
  };

  static DomainTheme getThemeForDomain(String domainId) {
    return domainThemes[domainId.toLowerCase()] ?? domainThemes['pdf']!;
  }
}
