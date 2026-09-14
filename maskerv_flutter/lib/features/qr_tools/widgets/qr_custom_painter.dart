import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';
import '../models/qr_design_config.dart';

class QrCustomPainter extends CustomPainter {
  final QrImage qrImage;
  final QrDesignConfig config;
  final bool isExport;

  QrCustomPainter({
    required this.qrImage,
    required this.config,
    this.isExport = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final moduleCount = qrImage.moduleCount;
    if (moduleCount == 0) return;

    // Frame layout computations
    double topExtra = 0;
    double bottomExtra = 0;
    const double frameTextHeight = 36.0;

    if (config.frameStyle != QrFrameStyle.none && config.frameLabel.isNotEmpty) {
      if (config.framePosition == QrFramePosition.top) {
        topExtra = frameTextHeight;
      } else {
        bottomExtra = frameTextHeight;
      }
    }

    final frameRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Draw Background
    if (!config.transparentBackground) {
      final bgPaint = Paint()..color = config.backgroundColor;
      canvas.drawRect(frameRect, bgPaint);
    }

    // 2. Draw Frame Box if enabled
    if (config.frameStyle != QrFrameStyle.none) {
      _paintFrame(canvas, frameRect, topExtra, bottomExtra);
    }

    // QR Code drawing dimensions inside frame
    final padding = config.quietZone * 4.0 + 12.0;
    final availableWidth = size.width - (padding * 2);
    final availableHeight = size.height - (padding * 2) - topExtra - bottomExtra;
    final qrSize = math.min(availableWidth, availableHeight);

    final qrLeft = (size.width - qrSize) / 2;
    final qrTop = padding + topExtra + ((availableHeight - qrSize) / 2);
    final qrRect = Rect.fromLTWH(qrLeft, qrTop, qrSize, qrSize);
    final moduleSize = qrSize / moduleCount;

    // 3. Draw Background Watermark / Symbol behind QR
    if (config.hasBackgroundWatermark) {
      _paintBackgroundWatermark(canvas, qrRect);
    }

    // 4. Setup Foreground Paint (Solid or Gradient)
    final fgPaint = Paint()..isAntiAlias = true;
    if (config.colorMode == QrColorMode.solid) {
      fgPaint.color = config.foregroundColor;
    } else if (config.colorMode == QrColorMode.linearGradient) {
      fgPaint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [config.foregroundColor, config.foregroundGradientEnd],
      ).createShader(qrRect);
    } else {
      fgPaint.shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [config.foregroundColor, config.foregroundGradientEnd],
      ).createShader(qrRect);
    }

    // 5. Center Logo reservation area
    Rect? logoReservedRect;
    if (config.hasCenterLogo) {
      final logoDim = qrSize * config.logoSizeRatio.clamp(0.10, 0.22);
      final center = qrRect.center;
      logoReservedRect = Rect.fromCenter(
        center: center,
        width: logoDim + (config.logoPadding * 2),
        height: logoDim + (config.logoPadding * 2),
      );
    }

    // 6. Draw Modules (Separating Finder Eyes from Standard Data Modules)
    for (int y = 0; y < moduleCount; y++) {
      for (int x = 0; x < moduleCount; x++) {
        if (_isFinderPattern(x, y, moduleCount)) {
          // Handled separately by eye painter
          continue;
        }

        if (!qrImage.isDark(y, x)) continue;

        final moduleRect = Rect.fromLTWH(
          qrLeft + x * moduleSize,
          qrTop + y * moduleSize,
          moduleSize,
          moduleSize,
        );

        // Skip modules covered by center logo
        if (logoReservedRect != null && logoReservedRect.overlaps(moduleRect)) {
          continue;
        }

        _paintModule(canvas, moduleRect, fgPaint);
      }
    }

    // 7. Draw the 3 Finder Pattern Eyes (Top-Left, Top-Right, Bottom-Left)
    _paintFinderEye(canvas, qrLeft, qrTop, moduleSize, 0, 0);
    _paintFinderEye(canvas, qrLeft, qrTop, moduleSize, moduleCount - 7, 0);
    _paintFinderEye(canvas, qrLeft, qrTop, moduleSize, 0, moduleCount - 7);

    // 8. Draw Center Logo / Icon if enabled
    if (config.hasCenterLogo && logoReservedRect != null) {
      _paintCenterLogo(canvas, logoReservedRect);
    }
  }

  bool _isFinderPattern(int x, int y, int count) {
    // Top-left 7x7
    if (x < 7 && y < 7) return true;
    // Top-right 7x7
    if (x >= count - 7 && y < 7) return true;
    // Bottom-left 7x7
    if (x < 7 && y >= count - 7) return true;
    return false;
  }

  void _paintModule(Canvas canvas, Rect rect, Paint paint) {
    switch (config.moduleShape) {
      case QrModuleShape.square:
        canvas.drawRect(rect, paint);
        break;
      case QrModuleShape.rounded:
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.35));
        canvas.drawRRect(rrect, paint);
        break;
      case QrModuleShape.dots:
        canvas.drawCircle(rect.center, rect.width * 0.45, paint);
        break;
      case QrModuleShape.softRounded:
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.20));
        canvas.drawRRect(rrect, paint);
        break;
    }
  }

  void _paintFinderEye(Canvas canvas, double qrLeft, double qrTop, double moduleSize, int originX, int originY) {
    final outerRect = Rect.fromLTWH(
      qrLeft + originX * moduleSize,
      qrTop + originY * moduleSize,
      7 * moduleSize,
      7 * moduleSize,
    );

    final innerRect = Rect.fromLTWH(
      qrLeft + (originX + 2) * moduleSize,
      qrTop + (originY + 2) * moduleSize,
      3 * moduleSize,
      3 * moduleSize,
    );

    final outerEyeColor = config.eyeOuterColor ?? config.foregroundColor;
    final innerEyeColor = config.eyeInnerColor ?? config.foregroundColor;

    // Clear outer 7x7 area to background color first
    if (!config.transparentBackground) {
      final bgPaint = Paint()..color = config.backgroundColor;
      canvas.drawRect(outerRect, bgPaint);
    }

    // Draw Outer Eye Border (Thickness = 1 module)
    final outerPaint = Paint()
      ..color = outerEyeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = moduleSize
      ..isAntiAlias = true;

    final outerBorderRect = outerRect.deflate(moduleSize / 2);

    switch (config.eyeOuterShape) {
      case QrEyeShape.square:
        canvas.drawRect(outerBorderRect, outerPaint);
        break;
      case QrEyeShape.rounded:
        final rrect = RRect.fromRectAndRadius(outerBorderRect, Radius.circular(moduleSize * 1.6));
        canvas.drawRRect(rrect, outerPaint);
        break;
      case QrEyeShape.circle:
        canvas.drawOval(outerBorderRect, outerPaint);
        break;
    }

    // Draw Inner Eye (Solid 3x3)
    final innerPaint = Paint()
      ..color = innerEyeColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    switch (config.eyeInnerShape) {
      case QrEyeShape.square:
        canvas.drawRect(innerRect, innerPaint);
        break;
      case QrEyeShape.rounded:
        final rrect = RRect.fromRectAndRadius(innerRect, Radius.circular(moduleSize * 0.9));
        canvas.drawRRect(rrect, innerPaint);
        break;
      case QrEyeShape.circle:
        canvas.drawOval(innerRect, innerPaint);
        break;
    }
  }

  void _paintFrame(Canvas canvas, Rect rect, double topExtra, double bottomExtra) {
    final frameBorderPaint = Paint()
      ..color = config.frameBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.frameBorderWidth
      ..isAntiAlias = true;

    final frameBgPaint = Paint()
      ..color = config.frameBackgroundColor
      ..style = PaintingStyle.fill;

    final inset = config.frameBorderWidth / 2 + 2;
    final boxRect = rect.deflate(inset);

    Radius radius;
    switch (config.frameStyle) {
      case QrFrameStyle.roundedFrame:
      case QrFrameStyle.modernFrame:
        radius = const Radius.circular(20);
        break;
      case QrFrameStyle.badgeFrame:
        radius = const Radius.circular(28);
        break;
      default:
        radius = const Radius.circular(8);
        break;
    }

    final rrect = RRect.fromRectAndRadius(boxRect, radius);
    canvas.drawRRect(rrect, frameBgPaint);
    canvas.drawRRect(rrect, frameBorderPaint);

    // Draw Frame Text Label
    if (config.frameLabel.isNotEmpty) {
      final textSpan = TextSpan(
        text: config.frameLabel.toUpperCase(),
        style: TextStyle(
          color: config.frameTextColor,
          fontSize: config.frameLabelSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: config.frameAlignment,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: boxRect.width - 24);

      double textY;
      if (config.framePosition == QrFramePosition.top) {
        textY = boxRect.top + 10;
      } else {
        textY = boxRect.bottom - textPainter.height - 10;
      }

      double textX = boxRect.left + (boxRect.width - textPainter.width) / 2;
      if (config.frameAlignment == TextAlign.left) {
        textX = boxRect.left + 16;
      } else if (config.frameAlignment == TextAlign.right) {
        textX = boxRect.right - textPainter.width - 16;
      }

      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  void _paintCenterLogo(Canvas canvas, Rect reservedRect) {
    // 1. Logo Background
    final bgPaint = Paint()
      ..color = config.logoBackgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = config.logoBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.logoBorderWidth
      ..isAntiAlias = true;

    final innerLogoRect = reservedRect.deflate(config.logoBorderWidth / 2);

    if (config.logoBackgroundShape == QrLogoBackgroundShape.circle) {
      canvas.drawOval(innerLogoRect, bgPaint);
      if (config.logoBorderWidth > 0) {
        canvas.drawOval(innerLogoRect, borderPaint);
      }
    } else if (config.logoBackgroundShape == QrLogoBackgroundShape.roundedSquare) {
      final rrect = RRect.fromRectAndRadius(innerLogoRect, Radius.circular(innerLogoRect.width * 0.28));
      canvas.drawRRect(rrect, bgPaint);
      if (config.logoBorderWidth > 0) {
        canvas.drawRRect(rrect, borderPaint);
      }
    } else if (config.logoBackgroundShape == QrLogoBackgroundShape.square) {
      canvas.drawRect(innerLogoRect, bgPaint);
      if (config.logoBorderWidth > 0) {
        canvas.drawRect(innerLogoRect, borderPaint);
      }
    }

    // 2. Draw Icon Glyph if present
    if (config.centerIcon != null) {
      final iconSize = innerLogoRect.width * 0.60;
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(config.centerIcon!.codePoint),
          style: TextStyle(
            inherit: false,
            color: config.foregroundColor,
            fontSize: iconSize,
            fontFamily: config.centerIcon!.fontFamily,
            package: config.centerIcon!.fontPackage,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(
        innerLogoRect.center.dx - textPainter.width / 2,
        innerLogoRect.center.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }
  }

  void _paintBackgroundWatermark(Canvas canvas, Rect qrRect) {
    if (config.backgroundIcon == null) return;

    final iconSize = qrRect.width * config.backgroundScale.clamp(0.4, 1.2);
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(config.backgroundIcon!.codePoint),
        style: TextStyle(
          inherit: false,
          color: config.foregroundColor.withValues(alpha: config.backgroundOpacity.clamp(0.04, 0.25)),
          fontSize: iconSize,
          fontFamily: config.backgroundIcon!.fontFamily,
          package: config.backgroundIcon!.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = Offset(
      qrRect.center.dx - textPainter.width / 2,
      qrRect.center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant QrCustomPainter oldDelegate) {
    return oldDelegate.qrImage != qrImage || oldDelegate.config != config;
  }
}
