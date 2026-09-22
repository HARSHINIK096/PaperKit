import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Interactive section for sharing processed files directly to online social platforms
/// (WhatsApp, Telegram, Instagram, Email, and System Share Sheet).
class SocialPlatformShareSection extends StatelessWidget {
  final File? file;
  final String? text;
  final String? subject;
  final EdgeInsetsGeometry padding;

  const SocialPlatformShareSection({
    super.key,
    this.file,
    this.text,
    this.subject,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  Future<void> _shareToWhatsApp(BuildContext context) async {
    HapticFeedback.lightImpact();
    final msg = text ?? 'Check out this document processed with MaskerV!';
    final encodedMsg = Uri.encodeComponent(msg);
    final whatsappUri = Uri.parse('whatsapp://send?text=$encodedMsg');
    
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // Fallback if direct app scheme is unavailable
    if (file != null) {
      await Share.shareXFiles(
        [XFile(file!.path)],
        text: msg,
        subject: subject ?? 'MaskerV Document',
      );
    } else {
      await Share.share(msg, subject: subject ?? 'MaskerV Text');
    }
  }

  Future<void> _shareToTelegram(BuildContext context) async {
    HapticFeedback.lightImpact();
    final msg = text ?? 'Document processed with MaskerV';
    final encodedMsg = Uri.encodeComponent(msg);
    final telegramUri = Uri.parse('tg://msg?text=$encodedMsg');

    try {
      if (await canLaunchUrl(telegramUri)) {
        await launchUrl(telegramUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    final webTelegramUri = Uri.parse('https://t.me/share/url?url=$encodedMsg');
    try {
      if (await canLaunchUrl(webTelegramUri)) {
        await launchUrl(webTelegramUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // Fallback
    if (file != null) {
      await Share.shareXFiles(
        [XFile(file!.path)],
        text: msg,
        subject: subject ?? 'MaskerV Document',
      );
    } else {
      await Share.share(msg, subject: subject ?? 'MaskerV Text');
    }
  }

  Future<void> _shareToInstagram(BuildContext context) async {
    HapticFeedback.lightImpact();
    final instagramUri = Uri.parse('instagram://');
    try {
      if (await canLaunchUrl(instagramUri)) {
        await launchUrl(instagramUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // Fallback
    if (file != null) {
      await Share.shareXFiles([XFile(file!.path)], text: text ?? 'MaskerV Document Share');
    } else if (text != null) {
      await Share.share(text!);
    }
  }

  Future<void> _shareToEmail(BuildContext context) async {
    HapticFeedback.lightImpact();
    final sub = Uri.encodeComponent(subject ?? 'Exported Document - MaskerV');
    final body = Uri.encodeComponent(text ?? 'Attached is your document processed with MaskerV.');
    final mailtoUri = Uri.parse('mailto:?subject=$sub&body=$body');

    try {
      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // Fallback
    if (file != null) {
      await Share.shareXFiles(
        [XFile(file!.path)],
        subject: subject ?? 'Exported Document - MaskerV',
        text: text ?? 'Attached is your document processed with MaskerV.',
      );
    } else if (text != null) {
      await Share.share(text!, subject: subject ?? 'Exported Content - MaskerV');
    }
  }

  Future<void> _shareToSystemApps(BuildContext context) async {
    HapticFeedback.mediumImpact();
    if (file != null) {
      await Share.shareXFiles(
        [XFile(file!.path)],
        subject: subject ?? 'MaskerV Document',
        text: text ?? 'Here is your document exported from MaskerV.',
      );
    } else if (text != null) {
      await Share.share(text!, subject: subject ?? 'MaskerV Content');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.share2,
                size: 14,
                color: Color(0xFF6366F1),
              ),
              const SizedBox(width: 6),
              Text(
                'SHARE TO ONLINE PLATFORMS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 🟢 WhatsApp Button
                _buildPlatformChip(
                  label: 'WhatsApp',
                  icon: LucideIcons.messageSquare,
                  gradientColors: const [Color(0xFF25D366), Color(0xFF128C7E)],
                  onTap: () => _shareToWhatsApp(context),
                ),
                const SizedBox(width: 8),

                // 💙 Telegram Button
                _buildPlatformChip(
                  label: 'Telegram',
                  icon: LucideIcons.send,
                  gradientColors: const [Color(0xFF0088CC), Color(0xFF229ED9)],
                  onTap: () => _shareToTelegram(context),
                ),
                const SizedBox(width: 8),

                // 💖 Instagram Button
                _buildPlatformChip(
                  label: 'Instagram',
                  icon: LucideIcons.camera,
                  gradientColors: const [Color(0xFF833AB4), Color(0xFFFD1D1D)],
                  onTap: () => _shareToInstagram(context),
                ),
                const SizedBox(width: 8),

                // 📧 Email Button
                _buildPlatformChip(
                  label: 'Email',
                  icon: LucideIcons.mail,
                  gradientColors: const [Color(0xFFEA4335), Color(0xFFC5221F)],
                  onTap: () => _shareToEmail(context),
                ),
                const SizedBox(width: 8),

                // 🌐 System Share / More Apps
                _buildPlatformChip(
                  label: 'More Apps',
                  icon: LucideIcons.share,
                  gradientColors: const [Color(0xFF4F46E5), Color(0xFF3730A3)],
                  onTap: () => _shareToSystemApps(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformChip({
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
