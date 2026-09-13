import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class CloudTransitionPage<T> extends CustomTransitionPage<T> {
  CloudTransitionPage({
    required super.child,
    Color cloudColor = AppColors.primary,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
          transitionDuration: const Duration(milliseconds: 750),
          reverseTransitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final baseCloudColor = isDark ? const Color(0xFF1E293B) : Colors.white;

            return Stack(
              children: [
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
                  ),
                  child: child,
                ),
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) {
                    final progress = animation.value;
                    if (progress <= 0.0 || progress >= 1.0) {
                      return const SizedBox.shrink();
                    }

                    return IgnorePointer(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _CloudSweepPainter(
                          progress: progress,
                          themeColor: cloudColor,
                          baseColor: baseCloudColor,
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
}

class _CloudSweepPainter extends CustomPainter {
  final double progress;
  final Color themeColor;
  final Color baseColor;

  _CloudSweepPainter({
    required this.progress,
    required this.themeColor,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final cloudPaint1 = Paint()
      ..color = themeColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final cloudPaint2 = Paint()
      ..color = baseColor.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    final cloudPaint3 = Paint()
      ..color = themeColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final cloudOffset = progress <= 0.5 ? (progress / 0.5) : (1.0 - (progress - 0.5) / 0.5);

    if (cloudOffset > 0.01) {
      final rect = Rect.fromLTWH(0, 0, w, h);

      final path1 = Path();
      path1.addRect(rect);
      canvas.drawPath(path1, cloudPaint1);

      final numPuffs = 8;
      final puffRadius = h / 4.5;
      final stepY = h / (numPuffs - 1);

      final path2 = Path();
      for (int i = 0; i < numPuffs; i++) {
        final y = stepY * i;
        final wobble = math.sin(i * 1.5 + progress * 6) * 40;
        final x = (w * (1.0 - cloudOffset)) + wobble;

        path2.addOval(Rect.fromCircle(
          center: Offset(x, y),
          radius: puffRadius * (0.8 + 0.4 * math.cos(i)),
        ));
      }
      canvas.drawPath(path2, cloudPaint2);

      final path3 = Path();
      for (int i = 0; i < numPuffs; i++) {
        final y = stepY * i + 30;
        final x = (w * (1.0 - cloudOffset)) - 20;

        path3.addOval(Rect.fromCircle(
          center: Offset(x, y),
          radius: puffRadius * 0.6,
        ));
      }
      canvas.drawPath(path3, cloudPaint3);
    }
  }

  @override
  bool shouldRepaint(covariant _CloudSweepPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
