import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import 'particle_background.dart';

class FileSuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final File file;
  final String? fileSize;

  const FileSuccessDialog({
    super.key,
    required this.title,
    required this.message,
    required this.file,
    this.fileSize,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required File file,
    String? fileSize,
  }) {
    HapticFeedback.mediumImpact();
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => FileSuccessDialog(
        title: title,
        message: message,
        file: file,
        fileSize: fileSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fileName = file.path.split(Platform.pathSeparator).last;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Particle Canvas effect on success dialog
            const Positioned.fill(
              child: ParticleBackground(
                numberOfParticles: 20,
                particleColor: Color(0xFF10B981),
                enableLines: true,
                maxSpeed: 0.25,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Green Success Glow Icon
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.checkCheck,
                      color: Color(0xFF10B981),
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // File Info Pill Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark.withValues(alpha: 0.8)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            LucideIcons.fileCheck,
                            size: 20,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              if (fileSize != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  fileSize!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Primary Action: Open File
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        OpenFilex.open(file.path);
                      },
                      icon: const Icon(LucideIcons.externalLink, size: 18),
                      label: const Text(
                        'Open Downloaded File',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Secondary Actions: Share & Close
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Share.shareXFiles([XFile(file.path)]);
                          },
                          icon: const Icon(LucideIcons.share2, size: 16),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : const Color(0xFF334155),
                            side: BorderSide(
                              color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Dismiss'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
