import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DisclaimerBanner extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const DisclaimerBanner({
    super.key,
    required this.title,
    required this.message,
    this.icon = LucideIcons.shieldAlert,
    this.backgroundColor = const Color(0xFFFEF3C7),
    this.borderColor = const Color(0xFFF59E0B),
    this.textColor = const Color(0xFF92400E),
  });

  factory DisclaimerBanner.legal({Key? key}) {
    return DisclaimerBanner(
      key: key,
      title: 'Legal Disclaimer Required',
      message:
          'This audit log and clause extraction tool is provided for informational and assistance purposes only. Always cross-verify all legal outputs, contracts, and compliance data with a licensed attorney or authorized legal professional.',
      icon: LucideIcons.scale,
      backgroundColor: const Color(0xFFFFF7ED),
      borderColor: const Color(0xFFF97316),
      textColor: const Color(0xFFC2410C),
    );
  }

  factory DisclaimerBanner.publishing({Key? key}) {
    return DisclaimerBanner(
      key: key,
      title: 'Publishing Contract Disclaimer',
      message:
          'Please carefully verify all formatting, pre-flight specs, margin bleeds, and contract terms directly with your publisher contract and official publishing guidelines before final print or publication.',
      icon: LucideIcons.bookOpenCheck,
      backgroundColor: const Color(0xFFF0FDF4),
      borderColor: const Color(0xFF22C55E),
      textColor: const Color(0xFF15803D),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: textColor.withOpacity(0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
