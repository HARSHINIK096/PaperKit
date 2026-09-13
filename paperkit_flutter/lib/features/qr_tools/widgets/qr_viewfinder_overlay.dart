import 'package:flutter/material.dart';

class QrViewfinderOverlay extends StatefulWidget {
  final double scanBoxSize;

  const QrViewfinderOverlay({
    super.key,
    this.scanBoxSize = 260.0,
  });

  @override
  State<QrViewfinderOverlay> createState() => _QrViewfinderOverlayState();
}

class _QrViewfinderOverlayState extends State<QrViewfinderOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ViewfinderPainter(
            scanBoxSize: widget.scanBoxSize,
            scanProgress: _animController.value,
          ),
        );
      },
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  final double scanBoxSize;
  final double scanProgress;

  _ViewfinderPainter({
    required this.scanBoxSize,
    required this.scanProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 30);
    final scanRect = Rect.fromCenter(center: center, width: scanBoxSize, height: scanBoxSize);

    // 1. Surrounding Dark Mask
    final maskPaint = Paint()..color = Colors.black.withValues(alpha: 0.65);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, maskPaint);

    // 2. Corner Brackets
    final cornerPaint = Paint()
      ..color = const Color(0xFF38BDF8) // Light Sky Blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const cornerLength = 26.0;

    // Top-Left
    canvas.drawLine(scanRect.topLeft, scanRect.topLeft + const Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(scanRect.topLeft, scanRect.topLeft + const Offset(0, cornerLength), cornerPaint);

    // Top-Right
    canvas.drawLine(scanRect.topRight, scanRect.topRight - const Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(scanRect.topRight, scanRect.topRight + const Offset(0, cornerLength), cornerPaint);

    // Bottom-Left
    canvas.drawLine(scanRect.bottomLeft, scanRect.bottomLeft + const Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(scanRect.bottomLeft, scanRect.bottomLeft - const Offset(0, cornerLength), cornerPaint);

    // Bottom-Right
    canvas.drawLine(scanRect.bottomRight, scanRect.bottomRight - const Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(scanRect.bottomRight, scanRect.bottomRight - const Offset(0, cornerLength), cornerPaint);

    // 3. Animated Laser Beam
    final laserY = scanRect.top + (scanRect.height * scanProgress);
    final laserPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: 0.0),
          const Color(0xFF38BDF8),
          const Color(0xFF38BDF8).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(scanRect.left, laserY - 1, scanRect.width, 2))
      ..strokeWidth = 2.5;

    canvas.drawLine(Offset(scanRect.left + 8, laserY), Offset(scanRect.right - 8, laserY), laserPaint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress || oldDelegate.scanBoxSize != scanBoxSize;
  }
}
