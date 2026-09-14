import 'package:flutter/material.dart';

class ToolIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? softColor;
  final double size;
  final double iconSize;
  final double borderRadius;

  const ToolIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.softColor,
    this.size = 58,
    this.iconSize = 27,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveSoft = softColor ?? color.withOpacity(0.12);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  color.withOpacity(0.25),
                  color.withOpacity(0.10),
                ]
              : [
                  effectiveSoft,
                  Colors.white.withOpacity(0.90),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : color.withOpacity(0.20),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? color.withOpacity(0.35) : color.withOpacity(0.15),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: iconSize,
        ),
      ),
    );
  }
}
