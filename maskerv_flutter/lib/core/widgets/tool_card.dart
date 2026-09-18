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

    final badgeSize = compact ? 44.0 : 48.0;
    final iconSize = compact ? 21.0 : 23.0;
    final radius = compact ? 13.0 : 15.0;
    final fontSize = compact ? 11.5 : 12.5;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(tool.route);
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: tool.color.withValues(alpha: 0.12),
        highlightColor: tool.color.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
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
                size: badgeSize,
                iconSize: iconSize,
                borderRadius: radius,
              ),
              const SizedBox(height: 5),

              // ── Centered Fluid Label Underneath ──
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  tool.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    letterSpacing: -0.15,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
