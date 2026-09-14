import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

class MarkdownViewer extends StatefulWidget {
  final String markdown;
  final String? title;
  final bool showHeader;
  final EdgeInsetsGeometry padding;

  const MarkdownViewer({
    super.key,
    required this.markdown,
    this.title,
    this.showHeader = true,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<MarkdownViewer> createState() => _MarkdownViewerState();
}

class _MarkdownViewerState extends State<MarkdownViewer> {
  bool _showRaw = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHeader) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.sparkles, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        widget.title ?? 'Markdown Preview',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_showRaw ? LucideIcons.eye : LucideIcons.code, size: 16),
                        tooltip: _showRaw ? 'Rendered View' : 'Raw Markdown',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => _showRaw = !_showRaw),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.copy, size: 16),
                        tooltip: 'Copy Text',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.markdown));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: widget.padding,
            child: _showRaw
                ? SelectableText(
                    widget.markdown,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      height: 1.5,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  )
                : MarkdownBody(
                    data: widget.markdown,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                      ),
                      h1: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      h2: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      h3: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      ),
                      strong: const TextStyle(fontWeight: FontWeight.w700),
                      em: const TextStyle(fontStyle: FontStyle.italic),
                      listBullet: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.primary : AppColors.primary,
                      ),
                      code: TextStyle(
                        fontSize: 12.5,
                        fontFamily: 'monospace',
                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      codeblockPadding: const EdgeInsets.all(12),
                      blockquote: TextStyle(
                        fontSize: 13.5,
                        fontStyle: FontStyle.italic,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: AppColors.primary.withOpacity(0.5), width: 3),
                        ),
                      ),
                      blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                      tableBorder: TableBorder.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1,
                      ),
                      tableHead: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      tableBody: const TextStyle(fontSize: 12.5),
                      tablePadding: const EdgeInsets.all(8),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
