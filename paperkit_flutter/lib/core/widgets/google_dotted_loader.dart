import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GoogleDottedLoader extends StatefulWidget {
  final double size;
  final String? message;
  final int? progressPercent;

  const GoogleDottedLoader({
    super.key,
    this.size = 64.0,
    this.message,
    this.progressPercent,
  });

  @override
  State<GoogleDottedLoader> createState() => _GoogleDottedLoaderState();
}

class _GoogleDottedLoaderState extends State<GoogleDottedLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.googleBlue,
      AppColors.googleRed,
      AppColors.googleYellow,
      AppColors.googleGreen,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _GoogleDottedPainter(
                  animationValue: _controller.value,
                  dotColors: colors,
                ),
              );
            },
          ),
        ),
        if (widget.progressPercent != null || widget.message != null) ...[
          const SizedBox(height: 20),
          if (widget.progressPercent != null)
            Text(
              '${widget.progressPercent}%',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.textPrimaryLight,
              ),
            ),
          if (widget.message != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _GoogleDottedPainter extends CustomPainter {
  final double animationValue;
  final List<Color> dotColors;

  _GoogleDottedPainter({
    required this.animationValue,
    required this.dotColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.8;
    final dotRadius = size.width / 9.5;

    final baseAngle = animationValue * 2 * math.pi;

    for (int i = 0; i < dotColors.length; i++) {
      final angle = baseAngle + (i * (math.pi / 2));
      final dx = center.dx + radius * math.cos(angle);
      final dy = center.dy + radius * math.sin(angle);

      final pulse = 1.0 + 0.2 * math.sin(baseAngle * 2 + i);

      final paint = Paint()
        ..color = dotColors[i]
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), dotRadius * pulse, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GoogleDottedPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class GreyscaleOverlayLoader extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final int? progressPercent;
  final Widget child;

  const GreyscaleOverlayLoader({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        ColorFiltered(
          colorFilter: isLoading
              ? const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0,      0,      0,      1, 0,
                ])
              : const ColorFilter.matrix(<double>[
                  1, 0, 0, 0, 0,
                  0, 1, 0, 0, 0,
                  0, 0, 1, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
          child: child,
        ),
        if (isLoading) ...[
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                color: isDark
                    ? AppColors.greyscaleOverlayDark
                    : AppColors.greyscaleOverlayLight,
                alignment: Alignment.center,
                child: GoogleDottedLoader(
                  message: message ?? 'Processing...',
                  progressPercent: progressPercent,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
