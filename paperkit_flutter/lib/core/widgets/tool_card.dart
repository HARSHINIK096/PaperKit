import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../models/tool_item.dart';
import '../theme/app_colors.dart';
import 'tool_icon_badge.dart';

class ToolCard extends StatelessWidget {
  final ToolItem tool;
  final bool compact;

  const ToolCard({
    super.key,
    required this.tool,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(tool.route);
        },
        borderRadius: BorderRadius.circular(20),
        splashColor: tool.color.withOpacity(0.12),
        highlightColor: tool.color.withOpacity(0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Soft Glowing Squircle Badge ──
              ToolIconBadge(
                icon: tool.icon,
                color: tool.color,
                softColor: tool.softColor,
                size: compact ? 48 : 58,
                iconSize: compact ? 23 : 27,
                borderRadius: compact ? 16 : 20,
              ),
              const SizedBox(height: 8),

              // ── Centered Label Underneath ──
              Text(
                tool.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  letterSpacing: -0.2,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
