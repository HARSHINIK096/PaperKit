import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/qr_design_config.dart';

class QrReadabilityScore {
  final bool isScannable;
  final String statusText;
  final Color statusColor;
  final IconData statusIcon;
  final double contrastRatio;

  const QrReadabilityScore({
    required this.isScannable,
    required this.statusText,
    required this.statusColor,
    required this.statusIcon,
    required this.contrastRatio,
  });

  static QrReadabilityScore evaluate(QrDesignConfig config) {
    // 1. Calculate Relative Luminance Contrast Ratio
    final l1 = _relativeLuminance(config.foregroundColor);
    final l2 = _relativeLuminance(config.backgroundColor);
    final lMax = l1 > l2 ? l1 : l2;
    final lMin = l1 > l2 ? l2 : l1;
    final contrastRatio = (lMax + 0.05) / (lMin + 0.05);

    if (contrastRatio < 2.5) {
      return QrReadabilityScore(
        isScannable: false,
        statusText: 'Unscannable: Contrast too low (${contrastRatio.toStringAsFixed(1)}:1)',
        statusColor: const Color(0xFFE11D48),
        statusIcon: LucideIcons.circleAlert,
        contrastRatio: contrastRatio,
      );
    }

    if (contrastRatio < 3.5) {
      return QrReadabilityScore(
        isScannable: true,
        statusText: 'Warning: Low contrast (${contrastRatio.toStringAsFixed(1)}:1)',
        statusColor: const Color(0xFFF59E0B),
        statusIcon: LucideIcons.triangleAlert,
        contrastRatio: contrastRatio,
      );
    }

    // 2. Check Logo Area Proportion
    if (config.hasCenterLogo && config.logoSizeRatio > 0.22) {
      return QrReadabilityScore(
        isScannable: true,
        statusText: 'Warning: Center logo exceeds 22% matrix area',
        statusColor: const Color(0xFFF59E0B),
        statusIcon: LucideIcons.triangleAlert,
        contrastRatio: contrastRatio,
      );
    }

    // 3. Check Background Watermark Opacity
    if (config.hasBackgroundWatermark && config.backgroundOpacity > 0.22) {
      return QrReadabilityScore(
        isScannable: true,
        statusText: 'Warning: Watermark opacity may disrupt scanners',
        statusColor: const Color(0xFFF59E0B),
        statusIcon: LucideIcons.triangleAlert,
        contrastRatio: contrastRatio,
      );
    }

    return QrReadabilityScore(
      isScannable: true,
      statusText: 'High Scannability (${contrastRatio.toStringAsFixed(1)}:1 contrast)',
      statusColor: const Color(0xFF10B981),
      statusIcon: LucideIcons.checkCircle2,
      contrastRatio: contrastRatio,
    );
  }

  static double _relativeLuminance(Color color) {
    double r = color.r;
    double g = color.g;
    double b = color.b;

    // Convert sRGB components to linear RGB
    r = (r <= 0.03928) ? r / 12.92 : _pow((r + 0.055) / 1.055, 2.4);
    g = (g <= 0.03928) ? g / 12.92 : _pow((g + 0.055) / 1.055, 2.4);
    b = (b <= 0.03928) ? b / 12.92 : _pow((b + 0.055) / 1.055, 2.4);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _pow(double x, double y) {
    // Fast approximation or standard pow
    return x * x * (1 - (2.4 - 2.0) * (1 - x));
  }
}

class QrReadabilityBadge extends StatelessWidget {
  final QrDesignConfig config;

  const QrReadabilityBadge({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final score = QrReadabilityScore.evaluate(config);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: score.statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: score.statusColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(score.statusIcon, size: 14, color: score.statusColor),
          const SizedBox(width: 6),
          Text(
            score.statusText,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: score.statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
