import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

enum QrModuleShape {
  square('Square'),
  rounded('Rounded Squircle'),
  dots('Dots / Circular'),
  softRounded('Soft Rounded');

  final String label;
  const QrModuleShape(this.label);
}

enum QrEyeShape {
  square('Square'),
  rounded('Rounded'),
  circle('Circular');

  final String label;
  const QrEyeShape(this.label);
}

enum QrColorMode {
  solid('Solid Color'),
  linearGradient('Linear Gradient'),
  radialGradient('Radial Gradient');

  final String label;
  const QrColorMode(this.label);
}

enum QrFrameStyle {
  none('No Frame'),
  simpleBorder('Simple Border'),
  roundedFrame('Rounded Frame'),
  squareFrame('Square Frame'),
  badgeFrame('Badge Frame'),
  labelFrame('Label Frame'),
  scanMeFrame('Scan Me Frame'),
  socialFrame('Social Media Frame'),
  posterFrame('Poster Frame'),
  modernFrame('Modern Frame'),
  minimalFrame('Minimal Frame');

  final String label;
  const QrFrameStyle(this.label);
}

enum QrFramePosition {
  bottom('Bottom'),
  top('Top');

  final String label;
  const QrFramePosition(this.label);
}

enum QrLogoBackgroundShape {
  circle('Circle'),
  roundedSquare('Rounded Square'),
  square('Square'),
  transparent('Transparent');

  final String label;
  const QrLogoBackgroundShape(this.label);
}

class QrDesignConfig {
  // Module Styling
  final QrModuleShape moduleShape;
  final QrEyeShape eyeOuterShape;
  final QrEyeShape eyeInnerShape;

  // Colors
  final QrColorMode colorMode;
  final Color foregroundColor;
  final Color foregroundGradientEnd;
  final Color backgroundColor;
  final bool transparentBackground;
  final Color? eyeOuterColor;
  final Color? eyeInnerColor;

  // Frame
  final QrFrameStyle frameStyle;
  final String frameLabel;
  final double frameLabelSize;
  final QrFramePosition framePosition;
  final TextAlign frameAlignment;
  final double frameBorderWidth;
  final Color frameBorderColor;
  final Color frameBackgroundColor;
  final Color frameTextColor;

  // Center Logo
  final IconData? centerIcon;
  final File? centerLogoFile;
  final double logoSizeRatio; // 0.10 to 0.22
  final double logoPadding;
  final QrLogoBackgroundShape logoBackgroundShape;
  final Color logoBackgroundColor;
  final double logoBorderWidth;
  final Color logoBorderColor;

  // Background Watermark / Symbol
  final IconData? backgroundIcon;
  final File? backgroundImageFile;
  final double backgroundOpacity; // 0.05 to 0.25
  final double backgroundScale; // 0.5 to 1.5

  // QR Parameters
  final int errorCorrectionLevel; // QrErrorCorrectLevel.L / M / Q / H
  final int quietZone; // 1 to 4
  final int exportResolution; // 512, 1024, 2048

  const QrDesignConfig({
    this.moduleShape = QrModuleShape.square,
    this.eyeOuterShape = QrEyeShape.square,
    this.eyeInnerShape = QrEyeShape.square,
    this.colorMode = QrColorMode.solid,
    this.foregroundColor = const Color(0xFF0F172A),
    this.foregroundGradientEnd = const Color(0xFF2563EB),
    this.backgroundColor = Colors.white,
    this.transparentBackground = false,
    this.eyeOuterColor,
    this.eyeInnerColor,
    this.frameStyle = QrFrameStyle.none,
    this.frameLabel = 'SCAN ME',
    this.frameLabelSize = 13.0,
    this.framePosition = QrFramePosition.bottom,
    this.frameAlignment = TextAlign.center,
    this.frameBorderWidth = 3.0,
    this.frameBorderColor = const Color(0xFF0F172A),
    this.frameBackgroundColor = Colors.white,
    this.frameTextColor = const Color(0xFF0F172A),
    this.centerIcon,
    this.centerLogoFile,
    this.logoSizeRatio = 0.18,
    this.logoPadding = 4.0,
    this.logoBackgroundShape = QrLogoBackgroundShape.circle,
    this.logoBackgroundColor = Colors.white,
    this.logoBorderWidth = 2.0,
    this.logoBorderColor = const Color(0xFFE2E8F0),
    this.backgroundIcon,
    this.backgroundImageFile,
    this.backgroundOpacity = 0.12,
    this.backgroundScale = 0.85,
    this.errorCorrectionLevel = QrErrorCorrectLevel.M,
    this.quietZone = 2,
    this.exportResolution = 1024,
  });

  bool get hasCenterLogo => centerIcon != null || centerLogoFile != null;
  bool get hasBackgroundWatermark => backgroundIcon != null || backgroundImageFile != null;

  /// Effective error correction level recommended automatically
  int get recommendedErrorCorrectionLevel {
    if (hasCenterLogo || hasBackgroundWatermark) {
      // High or Quartile needed when center logo or watermark is active
      return QrErrorCorrectLevel.H;
    }
    return errorCorrectionLevel;
  }

  QrDesignConfig copyWith({
    QrModuleShape? moduleShape,
    QrEyeShape? eyeOuterShape,
    QrEyeShape? eyeInnerShape,
    QrColorMode? colorMode,
    Color? foregroundColor,
    Color? foregroundGradientEnd,
    Color? backgroundColor,
    bool? transparentBackground,
    Color? eyeOuterColor,
    Color? eyeInnerColor,
    QrFrameStyle? frameStyle,
    String? frameLabel,
    double? frameLabelSize,
    QrFramePosition? framePosition,
    TextAlign? frameAlignment,
    double? frameBorderWidth,
    Color? frameBorderColor,
    Color? frameBackgroundColor,
    Color? frameTextColor,
    IconData? centerIcon,
    File? centerLogoFile,
    bool clearCenterLogo = false,
    double? logoSizeRatio,
    double? logoPadding,
    QrLogoBackgroundShape? logoBackgroundShape,
    Color? logoBackgroundColor,
    double? logoBorderWidth,
    Color? logoBorderColor,
    IconData? backgroundIcon,
    File? backgroundImageFile,
    bool clearBackgroundWatermark = false,
    double? backgroundOpacity,
    double? backgroundScale,
    int? errorCorrectionLevel,
    int? quietZone,
    int? exportResolution,
  }) {
    return QrDesignConfig(
      moduleShape: moduleShape ?? this.moduleShape,
      eyeOuterShape: eyeOuterShape ?? this.eyeOuterShape,
      eyeInnerShape: eyeInnerShape ?? this.eyeInnerShape,
      colorMode: colorMode ?? this.colorMode,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      foregroundGradientEnd: foregroundGradientEnd ?? this.foregroundGradientEnd,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      transparentBackground: transparentBackground ?? this.transparentBackground,
      eyeOuterColor: eyeOuterColor ?? this.eyeOuterColor,
      eyeInnerColor: eyeInnerColor ?? this.eyeInnerColor,
      frameStyle: frameStyle ?? this.frameStyle,
      frameLabel: frameLabel ?? this.frameLabel,
      frameLabelSize: frameLabelSize ?? this.frameLabelSize,
      framePosition: framePosition ?? this.framePosition,
      frameAlignment: frameAlignment ?? this.frameAlignment,
      frameBorderWidth: frameBorderWidth ?? this.frameBorderWidth,
      frameBorderColor: frameBorderColor ?? this.frameBorderColor,
      frameBackgroundColor: frameBackgroundColor ?? this.frameBackgroundColor,
      frameTextColor: frameTextColor ?? this.frameTextColor,
      centerIcon: clearCenterLogo ? null : (centerIcon ?? this.centerIcon),
      centerLogoFile: clearCenterLogo ? null : (centerLogoFile ?? this.centerLogoFile),
      logoSizeRatio: logoSizeRatio ?? this.logoSizeRatio,
      logoPadding: logoPadding ?? this.logoPadding,
      logoBackgroundShape: logoBackgroundShape ?? this.logoBackgroundShape,
      logoBackgroundColor: logoBackgroundColor ?? this.logoBackgroundColor,
      logoBorderWidth: logoBorderWidth ?? this.logoBorderWidth,
      logoBorderColor: logoBorderColor ?? this.logoBorderColor,
      backgroundIcon: clearBackgroundWatermark ? null : (backgroundIcon ?? this.backgroundIcon),
      backgroundImageFile: clearBackgroundWatermark ? null : (backgroundImageFile ?? this.backgroundImageFile),
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      backgroundScale: backgroundScale ?? this.backgroundScale,
      errorCorrectionLevel: errorCorrectionLevel ?? this.errorCorrectionLevel,
      quietZone: quietZone ?? this.quietZone,
      exportResolution: exportResolution ?? this.exportResolution,
    );
  }
}
