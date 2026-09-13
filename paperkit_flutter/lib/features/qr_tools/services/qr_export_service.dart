import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:qr/qr.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/qr_design_config.dart';
import '../widgets/qr_custom_painter.dart';

enum QrExportFormat {
  png('PNG Image (.png)'),
  jpg('JPEG Image (.jpg)'),
  svg('Vector SVG (.svg)'),
  pdf('PDF Document (.pdf)');

  final String label;
  const QrExportFormat(this.label);
}

class QrExportService {
  const QrExportService._();

  static Future<Directory> _getPublicStorageDirectory() async {
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download/MaskerV');
      try {
        if (!downloadDir.existsSync()) {
          downloadDir.createSync(recursive: true);
        }
        return downloadDir;
      } catch (_) {}

      final fallbackDownload = Directory('/storage/emulated/0/Download');
      if (fallbackDownload.existsSync()) {
        return fallbackDownload;
      }

      try {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (extDirs != null && extDirs.isNotEmpty) {
          return extDirs.first;
        }
      } catch (_) {}
    }

    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        final pkDir = Directory('${downloads.path}/MaskerV');
        if (!pkDir.existsSync()) pkDir.createSync(recursive: true);
        return pkDir;
      }
    } catch (_) {}

    return await getApplicationDocumentsDirectory();
  }

  /// Export QR code to target format and write to disk.
  static Future<File> export({
    required String data,
    required QrDesignConfig config,
    required QrExportFormat format,
    int? resolution,
  }) async {
    final targetRes = resolution ?? config.exportResolution;
    final exportDir = await _getPublicStorageDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    switch (format) {
      case QrExportFormat.png:
        final pngBytes = await renderToPngBytes(data: data, config: config, size: targetRes.toDouble());
        final file = File('${exportDir.path}/qr_code_$timestamp.png');
        await file.writeAsBytes(pngBytes);
        return file;

      case QrExportFormat.jpg:
        final pngBytes = await renderToPngBytes(data: data, config: config, size: targetRes.toDouble());
        final decoded = img.decodeImage(pngBytes);
        final jpgBytes = img.encodeJpg(decoded ?? img.Image(width: targetRes, height: targetRes), quality: 95);
        final file = File('${exportDir.path}/qr_code_$timestamp.jpg');
        await file.writeAsBytes(jpgBytes);
        return file;

      case QrExportFormat.svg:
        final svgString = generateSvg(data: data, config: config);
        final file = File('${exportDir.path}/qr_code_$timestamp.svg');
        await file.writeAsString(svgString);
        return file;

      case QrExportFormat.pdf:
        final pngBytes = await renderToPngBytes(data: data, config: config, size: targetRes.toDouble());
        final file = File('${exportDir.path}/qr_code_$timestamp.pdf');
        final pdfBytes = await _createPdfDocument(pngBytes: pngBytes, title: config.frameLabel, data: data);
        await file.writeAsBytes(pdfBytes);
        return file;
    }
  }

  /// Renders the QR code directly to PNG bytes using Flutter Canvas & PictureRecorder
  static Future<Uint8List> renderToPngBytes({
    required String data,
    required QrDesignConfig config,
    required double size,
  }) async {
    final effectiveErrorLevel = config.recommendedErrorCorrectionLevel;
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: effectiveErrorLevel,
    );
    final qrImage = QrImage(qrCode);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    final painter = QrCustomPainter(
      qrImage: qrImage,
      config: config,
      isExport: true,
    );

    painter.paint(canvas, Size(size, size));

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Generates clean, resolution-independent vector SVG XML
  static String generateSvg({
    required String data,
    required QrDesignConfig config,
  }) {
    final effectiveErrorLevel = config.recommendedErrorCorrectionLevel;
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: effectiveErrorLevel,
    );
    final qrImage = QrImage(qrCode);
    final moduleCount = qrImage.moduleCount;

    const double moduleSize = 10.0;
    final quietZone = config.quietZone * moduleSize;
    final qrMatrixSize = moduleCount * moduleSize;

    double topExtra = 0;
    double bottomExtra = 0;
    if (config.frameStyle != QrFrameStyle.none) {
      if (config.framePosition == QrFramePosition.top) {
        topExtra = 40;
      } else {
        bottomExtra = 40;
      }
    }

    final totalWidth = qrMatrixSize + (quietZone * 2);
    final totalHeight = qrMatrixSize + (quietZone * 2) + topExtra + bottomExtra;

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $totalWidth $totalHeight" width="$totalWidth" height="$totalHeight">');

    // Background
    if (!config.transparentBackground) {
      final bgHex = _colorToHex(config.backgroundColor);
      buffer.writeln('  <rect width="100%" height="100%" fill="$bgHex" />');
    }

    // Frame styling if present
    if (config.frameStyle != QrFrameStyle.none) {
      final frameBorderHex = _colorToHex(config.frameBorderColor);
      final frameBgHex = _colorToHex(config.frameBackgroundColor);
      final rx = config.frameStyle == QrFrameStyle.roundedFrame ? '16' : '4';
      buffer.writeln('  <rect x="4" y="4" width="${totalWidth - 8}" height="${totalHeight - 8}" rx="$rx" fill="$frameBgHex" stroke="$frameBorderHex" stroke-width="${config.frameBorderWidth}" />');

      // Frame text
      if (config.frameLabel.isNotEmpty) {
        final textHex = _colorToHex(config.frameTextColor);
        final textY = config.framePosition == QrFramePosition.top ? 26 : totalHeight - 14;
        buffer.writeln('  <text x="${totalWidth / 2}" y="$textY" font-family="Arial, sans-serif" font-size="${config.frameLabelSize}" font-weight="bold" text-anchor="middle" fill="$textHex">${_escapeXml(config.frameLabel)}</text>');
      }
    }

    // Modules
    final fgHex = _colorToHex(config.foregroundColor);
    final qrOriginX = quietZone;
    final qrOriginY = quietZone + topExtra;

    double rx = 0;
    if (config.moduleShape == QrModuleShape.rounded) rx = moduleSize * 0.3;
    if (config.moduleShape == QrModuleShape.dots) rx = moduleSize * 0.5;
    if (config.moduleShape == QrModuleShape.softRounded) rx = moduleSize * 0.2;

    buffer.writeln('  <g fill="$fgHex">');
    for (int y = 0; y < moduleCount; y++) {
      for (int x = 0; x < moduleCount; x++) {
        if (qrImage.isDark(y, x)) {
          final mx = qrOriginX + x * moduleSize;
          final my = qrOriginY + y * moduleSize;
          if (rx > 0) {
            buffer.writeln('    <rect x="$mx" y="$my" width="$moduleSize" height="$moduleSize" rx="$rx" />');
          } else {
            buffer.writeln('    <rect x="$mx" y="$my" width="$moduleSize" height="$moduleSize" />');
          }
        }
      }
    }
    buffer.writeln('  </g>');

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  static Future<List<int>> _createPdfDocument({
    required Uint8List pngBytes,
    required String title,
    required String data,
  }) async {
    final pdfDocument = PdfDocument();
    final page = pdfDocument.pages.add();

    final image = PdfBitmap(pngBytes);
    const double qrDisplaySize = 320;
    final double x = (page.getClientSize().width - qrDisplaySize) / 2;
    const double y = 80;

    // Draw Title
    final fontTitle = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final fontSubtitle = PdfStandardFont(PdfFontFamily.helvetica, 10);

    final displayTitle = title.isNotEmpty ? title : 'MaskerV QR Code Document';
    page.graphics.drawString(
      displayTitle,
      fontTitle,
      bounds: Rect.fromLTWH(0, 30, page.getClientSize().width, 30),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Draw QR Code
    page.graphics.drawImage(image, Rect.fromLTWH(x, y, qrDisplaySize, qrDisplaySize));

    // Draw Payload text below QR
    final previewText = data.length > 80 ? '${data.substring(0, 80)}...' : data;
    page.graphics.drawString(
      previewText,
      fontSubtitle,
      bounds: Rect.fromLTWH(40, y + qrDisplaySize + 25, page.getClientSize().width - 80, 40),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    final bytes = await pdfDocument.save();
    pdfDocument.dispose();
    return bytes;
  }

  static String _colorToHex(Color color) {
    return '#${color.r.toInt().toRadixString(16).padLeft(2, '0')}${color.g.toInt().toRadixString(16).padLeft(2, '0')}${color.b.toInt().toRadixString(16).padLeft(2, '0')}';
  }

  static String _escapeXml(String string) {
    return string
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
