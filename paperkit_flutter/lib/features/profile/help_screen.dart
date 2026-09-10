import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_shell.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final faqs = [
      {
        'q': 'Does PaperKit work completely offline?',
        'a': 'Yes! All core PDF operations (Merge, Split, Rotate, Watermark, Reorder, Metadata, Protect) run 100% locally on your device without sending any data over the network.',
      },
      {
        'q': 'How do AI Document tools work?',
        'a': 'AI tools (Summarization, Chat, OCR, Semantic Search, Translations) connect to the PaperKit FastAPI backend or local AI pipeline for inference.',
      },
      {
        'q': 'Is my data secure?',
        'a': 'PaperKit uses 256-bit AES encryption for PDF password protection and zero persistent data collection on third-party servers.',
      },
      {
        'q': 'What file formats are supported?',
        'a': 'PDF, Word (DOCX), Excel (XLSX), PowerPoint (PPTX), JPG, PNG, WEBP, HEIC, MP4, WebM, MP3, WAV, ZIP, TAR, GZ, and more.',
      },
    ];

    return AppShell(
      title: 'Help & FAQ',
      showBottomNav: false,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final item = faqs[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: ExpansionTile(
              leading: const Icon(LucideIcons.helpCircle, color: AppColors.primary, size: 20),
              title: Text(
                item['q']!,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    item['a']!,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
