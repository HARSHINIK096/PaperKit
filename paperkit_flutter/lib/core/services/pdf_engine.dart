import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'api_service.dart';

class PdfEngine {
  // Merge multiple PDF files into one
  static Future<File> mergePdfFiles(
    List<File> files,
    String outputFileName,
  ) async {
    final PdfDocument finalDocument = PdfDocument();

    for (final file in files) {
      final bytes = await file.readAsBytes();
      final PdfDocument inputDocument = PdfDocument(inputBytes: bytes);

      for (int i = 0; i < inputDocument.pages.count; i++) {
        final PdfPage inputPage = inputDocument.pages[i];
        final PdfTemplate template = inputPage.createTemplate();
        finalDocument.pageSettings.margins.all = 0;
        finalDocument.pageSettings.size = inputPage.size;
        final PdfPage page = finalDocument.pages.add();
        page.rotation = inputPage.rotation;
        page.graphics.drawPdfTemplate(
          template,
          const Offset(0, 0),
          Size(inputPage.size.width, inputPage.size.height),
        );
      }
      inputDocument.dispose();
    }

    final outputDir = await getApplicationDocumentsDirectory();
    final outputFile = File('${outputDir.path}/$outputFileName.pdf');
    await outputFile.writeAsBytes(finalDocument.saveSync());
    finalDocument.dispose();

    return outputFile;
  }

  // Split PDF by page ranges or extract all pages
  static Future<List<File>> splitPdf(
    File inputFile,
    List<List<int>> ranges,
  ) async {
    final bytes = await inputFile.readAsBytes();
    final PdfDocument inputDocument = PdfDocument(inputBytes: bytes);
    final outputDir = await getApplicationDocumentsDirectory();
    final List<File> resultFiles = [];

    int partIndex = 1;
    for (final range in ranges) {
      final PdfDocument splitDocument = PdfDocument();
      for (final pageIndex in range) {
        if (pageIndex >= 0 && pageIndex < inputDocument.pages.count) {
          final PdfTemplate template = inputDocument.pages[pageIndex]
              .createTemplate();
          final PdfPage newPage = splitDocument.pages.add();
          newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
        }
      }

      final fileName =
          '${inputFile.uri.pathSegments.last.replaceAll('.pdf', '')}_part_$partIndex.pdf';
      final outputFile = File('${outputDir.path}/$fileName');
      await outputFile.writeAsBytes(splitDocument.saveSync());
      splitDocument.dispose();
      resultFiles.add(outputFile);
      partIndex++;
    }

    inputDocument.dispose();
    return resultFiles;
  }

  // Rotate PDF Pages
  static Future<File> rotatePdf(
    File inputFile,
    int rotationAngleDegrees,
  ) async {
    final bytes = await inputFile.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    PdfPageRotateAngle angle;
    if (rotationAngleDegrees == 90) {
      angle = PdfPageRotateAngle.rotateAngle90;
    } else if (rotationAngleDegrees == 180) {
      angle = PdfPageRotateAngle.rotateAngle180;
    } else if (rotationAngleDegrees == 270) {
      angle = PdfPageRotateAngle.rotateAngle270;
    } else {
      angle = PdfPageRotateAngle.rotateAngle0;
    }

    for (int i = 0; i < document.pages.count; i++) {
      document.pages[i].rotation = angle;
    }

    final outputDir = await getApplicationDocumentsDirectory();
    final baseName = inputFile.uri.pathSegments.last.replaceAll('.pdf', '');
    final outputFile = File('${outputDir.path}/${baseName}_rotated.pdf');
    await outputFile.writeAsBytes(document.saveSync());
    document.dispose();

    return outputFile;
  }

  // Add Watermark to PDF
  static Future<File> addWatermark({
    required File inputFile,
    required String watermarkText,
    double opacity = 0.3,
    double fontSize = 40,
    double angle = -45,
  }) async {
    final bytes = await inputFile.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    final font = PdfStandardFont(PdfFontFamily.helvetica, fontSize);
    final brush = PdfSolidBrush(
      PdfColor(128, 128, 128, (opacity * 255).round()),
    );

    for (int i = 0; i < document.pages.count; i++) {
      final PdfPage page = document.pages[i];
      final PdfGraphics graphics = page.graphics;

      final state = graphics.save();
      graphics.translateTransform(page.size.width / 2, page.size.height / 2);
      graphics.rotateTransform(angle);

      final textSize = font.measureString(watermarkText);
      graphics.drawString(
        watermarkText,
        font,
        brush: brush,
        bounds: Rect.fromLTWH(
          -textSize.width / 2,
          -textSize.height / 2,
          textSize.width,
          textSize.height,
        ),
      );
      graphics.restore(state);
    }

    final outputDir = await getApplicationDocumentsDirectory();
    final baseName = inputFile.uri.pathSegments.last.replaceAll('.pdf', '');
    final outputFile = File('${outputDir.path}/${baseName}_watermarked.pdf');
    await outputFile.writeAsBytes(document.saveSync());
    document.dispose();

    return outputFile;
  }

  // Password Protect PDF
  static Future<File> protectPdf({
    required File inputFile,
    required String userPassword,
    String? ownerPassword,
  }) async {
    final bytes = await inputFile.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    final PdfSecurity security = document.security;
    security.userPassword = userPassword;
    security.ownerPassword = ownerPassword ?? userPassword;
    security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;
    security.permissions.addAll([
      PdfPermissionsFlags.print,
      PdfPermissionsFlags.copyContent,
    ]);

    final outputDir = await getApplicationDocumentsDirectory();
    final baseName = inputFile.uri.pathSegments.last.replaceAll('.pdf', '');
    final outputFile = File('${outputDir.path}/${baseName}_protected.pdf');
    await outputFile.writeAsBytes(document.saveSync());
    document.dispose();

    return outputFile;
  }

  // Extract Text from PDF (Local OCR / text layer)
  static Future<String> extractText(File inputFile) async {
    final bytes = await inputFile.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final PdfTextExtractor extractor = PdfTextExtractor(document);
    final String text = extractor.extractText();
    document.dispose();
    return text;
  }

  // Organize, reorder, and remove pages
  static Future<File> organizePages({
    required File inputFile,
    required List<int> pageOrderZeroIndexed,
  }) async {
    final bytes = await inputFile.readAsBytes();
    final PdfDocument inputDocument = PdfDocument(inputBytes: bytes);
    final PdfDocument newDocument = PdfDocument();

    for (final pageIndex in pageOrderZeroIndexed) {
      if (pageIndex >= 0 && pageIndex < inputDocument.pages.count) {
        final PdfPage inputPage = inputDocument.pages[pageIndex];
        final PdfTemplate template = inputPage.createTemplate();
        newDocument.pageSettings.margins.all = 0;
        newDocument.pageSettings.size = inputPage.size;
        final PdfPage newPage = newDocument.pages.add();
        newPage.rotation = inputPage.rotation;
        newPage.graphics.drawPdfTemplate(
          template,
          const Offset(0, 0),
          Size(inputPage.size.width, inputPage.size.height),
        );
      }
    }

    final outputDir = await getApplicationDocumentsDirectory();
    final baseName = inputFile.uri.pathSegments.last.replaceAll('.pdf', '');
    final outputFile = File('${outputDir.path}/${baseName}_organized.pdf');
    await outputFile.writeAsBytes(newDocument.saveSync());

    inputDocument.dispose();
    newDocument.dispose();
    return outputFile;
  }

  // Modify / Sanitize Metadata
  static Future<File> updateMetadata({
    required File inputFile,
    String? title,
    String? author,
    String? subject,
    String? keywords,
  }) async {
    final bytes = await inputFile.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    if (title != null) document.documentInformation.title = title;
    if (author != null) document.documentInformation.author = author;
    if (subject != null) document.documentInformation.subject = subject;
    if (keywords != null) document.documentInformation.keywords = keywords;

    final outputDir = await getApplicationDocumentsDirectory();
    final baseName = inputFile.uri.pathSegments.last.replaceAll('.pdf', '');
    final outputFile = File('${outputDir.path}/${baseName}_metadata.pdf');
    await outputFile.writeAsBytes(document.saveSync());
    document.dispose();

    return outputFile;
  }

  // Helper to resolve font family from PDF embedded font name
  static PdfFontFamily resolveFontFamily(String? fontName) {
    if (fontName == null || fontName.isEmpty) return PdfFontFamily.helvetica;
    final fn = fontName.toLowerCase();
    if (fn.contains('times') ||
        fn.contains('serif') ||
        fn.contains('roman') ||
        fn.contains('georgia') ||
        fn.contains('cambria') ||
        fn.contains('garamond') ||
        fn.contains('minion') ||
        fn.contains('baskerville') ||
        fn.contains('palatino') ||
        fn.contains('century') ||
        fn.contains('bookman') ||
        fn.contains('tiro') ||
        fn.contains('tibo')) {
      return PdfFontFamily.timesRoman;
    }
    if (fn.contains('courier') ||
        fn.contains('mono') ||
        fn.contains('consolas') ||
        fn.contains('menlo') ||
        fn.contains('code') ||
        fn.contains('typewriter') ||
        fn.contains('source code') ||
        fn.contains('cour') ||
        fn.contains('cobo')) {
      return PdfFontFamily.courier;
    }
    if (fn.contains('symbol')) {
      return PdfFontFamily.symbol;
    }
    if (fn.contains('zapf') || fn.contains('dingbat')) {
      return PdfFontFamily.zapfDingbats;
    }
    return PdfFontFamily.helvetica;
  }

  // Extract Text Lines/Spans with exact Bounding Boxes and full font attributes for in-place selection and editing
  static Future<List<PdfExistingTextSpan>> extractPageTextSpans({
    File? inputFile,
    Uint8List? bytes,
    String? filename,
    required int pageIndex,
  }) async {
    // 1. Try PyMuPDF backend extraction for 100% font accuracy & span details
    try {
      final backendRes = await ApiService().extractPdfSpans(
        file: inputFile,
        bytes: bytes,
        filename: filename,
        pageNumber: pageIndex + 1,
      );
      if (backendRes != null && backendRes['spans'] is List) {
        final List<PdfExistingTextSpan> spans = [];
        final pWidth = (backendRes['page_width'] as num?)?.toDouble() ?? 595.28;
        final pHeight = (backendRes['page_height'] as num?)?.toDouble() ?? 841.89;
        final rawSpans = backendRes['spans'] as List;

        for (final item in rawSpans) {
          if (item is Map) {
            final bbox = item['bbox'] as List;
            final norm = item['normalized_rect'] as List;
            final fontName = item['font_name']?.toString() ?? 'Helvetica';
            final colorArr = item['color'] as List? ?? [0, 0, 0];
            final r = (colorArr.isNotEmpty ? (colorArr[0] as num).toInt() : 0);
            final g = (colorArr.length > 1 ? (colorArr[1] as num).toInt() : 0);
            final b = (colorArr.length > 2 ? (colorArr[2] as num).toInt() : 0);

            spans.add(
              PdfExistingTextSpan(
                id: item['id']?.toString() ?? 'span_${spans.length}',
                originalText: item['text']?.toString() ?? '',
                currentText: item['text']?.toString() ?? '',
                pdfBounds: Rect.fromLTRB(
                  (bbox[0] as num).toDouble(),
                  (bbox[1] as num).toDouble(),
                  (bbox[2] as num).toDouble(),
                  (bbox[3] as num).toDouble(),
                ),
                normalizedRect: Rect.fromLTWH(
                  (norm[0] as num).toDouble(),
                  (norm[1] as num).toDouble(),
                  (norm[2] as num).toDouble(),
                  (norm[3] as num).toDouble(),
                ),
                originalPageSize: Size(pWidth, pHeight),
                fontSize: (item['font_size'] as num?)?.toDouble() ?? 12.0,
                fontName: fontName,
                fontFamily: resolveFontFamily(fontName),
                color: Color.fromRGBO(r, g, b, 1.0),
                isBold: item['is_bold'] == true,
                isItalic: item['is_italic'] == true,
              ),
            );
          }
        }
        if (spans.isNotEmpty) {
          return spans;
        }
      }
    } catch (_) {}

    // 2. Fallback to local Syncfusion extraction
    final pdfBytes = bytes ?? await inputFile?.readAsBytes();
    if (pdfBytes == null) return [];
    final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
    final List<PdfExistingTextSpan> spans = [];

    try {
      if (pageIndex >= 0 && pageIndex < document.pages.count) {
        final page = document.pages[pageIndex];
        final pageSize = page.size;
        final extractor = PdfTextExtractor(document);
        final lines = extractor.extractTextLines(
          startPageIndex: pageIndex,
          endPageIndex: pageIndex,
        );

        final seenRects = <Rect>[];
        int idx = 0;
        for (final line in lines) {
          final trimmed = line.text.trim();
          if (trimmed.isEmpty) continue;

          final bounds = line.bounds;
          bool isDuplicate = false;
          for (final prev in seenRects) {
            if ((prev.left - bounds.left).abs() < 1.5 &&
                (prev.top - bounds.top).abs() < 1.5 &&
                (prev.width - bounds.width).abs() < 3.0) {
              isDuplicate = true;
              break;
            }
          }
          if (isDuplicate) continue;
          seenRects.add(bounds);

          final normLeft = (bounds.left / pageSize.width).clamp(0.0, 1.0);
          final normTop = (bounds.top / pageSize.height).clamp(0.0, 1.0);
          final normWidth = (bounds.width / pageSize.width).clamp(0.005, 1.0);
          final normHeight = (bounds.height / pageSize.height).clamp(
            0.005,
            1.0,
          );

          final rawFontName = line.fontName.isNotEmpty
              ? line.fontName
              : (line.wordCollection.isNotEmpty &&
                      line.wordCollection.first.glyphs.isNotEmpty
                  ? line.wordCollection.first.glyphs.first.fontName
                  : 'Helvetica');
          final fontSize = line.fontSize > 0
              ? line.fontSize
              : (line.wordCollection.isNotEmpty &&
                      line.wordCollection.first.glyphs.isNotEmpty &&
                      line.wordCollection.first.glyphs.first.fontSize > 0
                  ? line.wordCollection.first.glyphs.first.fontSize
                  : 12.0);
          final fontStyle = line.fontStyle.isNotEmpty
              ? line.fontStyle
              : (line.wordCollection.isNotEmpty &&
                      line.wordCollection.first.glyphs.isNotEmpty
                  ? line.wordCollection.first.glyphs.first.fontStyle
                  : <PdfFontStyle>[]);

          final fnLower = rawFontName.toLowerCase();
          final isBold =
              fontStyle.contains(PdfFontStyle.bold) ||
              anySubstring(fnLower, [
                'bold',
                'black',
                'heavy',
                'semibold',
                'medium',
                'tibo',
                'hebo',
                'cobo',
                'bd',
              ]);
          final isItalic =
              fontStyle.contains(PdfFontStyle.italic) ||
              anySubstring(fnLower, [
                'italic',
                'oblique',
                'slanted',
                'tiit',
                'heit',
                'coit',
                'it',
              ]);
          final resolvedFamily = resolveFontFamily(rawFontName);

          spans.add(
            PdfExistingTextSpan(
              id: 'span_${pageIndex}_$idx',
              originalText: line.text,
              currentText: line.text,
              pdfBounds: bounds,
              normalizedRect: Rect.fromLTWH(
                normLeft,
                normTop,
                normWidth,
                normHeight,
              ),
              originalPageSize: Size(pageSize.width, pageSize.height),
              fontSize: fontSize,
              fontName: rawFontName,
              fontFamily: resolvedFamily,
              isBold: isBold,
              isItalic: isItalic,
            ),
          );
          idx++;
        }
      }
    } catch (e) {
      print('Extract text spans error: $e');
    } finally {
      document.dispose();
    }

    return spans;
  }

  static bool anySubstring(String str, List<String> needles) {
    for (final n in needles) {
      if (str.contains(n)) return true;
    }
    return false;
  }

  // Apply In-Place Annotations, Freehand Drawings, Text Overlays, and Existing Text Replacements
  static Future<File> applyPdfAnnotations({
    required File inputFile,
    required Map<int, List<PdfDrawPath>> drawPathsByPage,
    required Map<int, List<PdfTextEdit>> textEditsByPage,
    required Map<int, List<PdfHighlightBox>> highlightsByPage,
    Map<int, List<PdfExistingTextSpan>>? modifiedSpansByPage,
  }) async {
    File targetInputFile = inputFile;

    // 1. Try PyMuPDF backend in-place redaction + replacement for 100% font/layout fidelity
    bool hasModifiedTextSpans = false;
    final List<Map<String, dynamic>> editsPayload = [];

    if (modifiedSpansByPage != null) {
      modifiedSpansByPage.forEach((pageIdx, spans) {
        final List<Map<String, dynamic>> pageEdits = [];
        for (final span in spans) {
          if (!span.isModified) continue;
          hasModifiedTextSpans = true;
          pageEdits.add({
            'type': 'text',
            'bbox': [
              span.pdfBounds.left,
              span.pdfBounds.top,
              span.pdfBounds.right,
              span.pdfBounds.bottom,
            ],
            'new_text': span.currentText,
            'font_name': span.fontName,
            'font_size': span.fontSize,
            'is_bold': span.isBold,
            'is_italic': span.isItalic,
            'color': [
              span.color.red,
              span.color.green,
              span.color.blue,
            ],
          });
        }
        if (pageEdits.isNotEmpty) {
          editsPayload.add({
            'page_number': pageIdx + 1,
            'edits': pageEdits,
          });
        }
      });
    }

    if (hasModifiedTextSpans && editsPayload.isNotEmpty) {
      try {
        final editedFile = await ApiService().applyPdfInPlaceEdits(
          file: targetInputFile,
          editsPayload: editsPayload,
        );
        bool hasOtherAnnotations = drawPathsByPage.values.any((l) => l.isNotEmpty) ||
            textEditsByPage.values.any((l) => l.isNotEmpty) ||
            highlightsByPage.values.any((l) => l.isNotEmpty);

        if (!hasOtherAnnotations) {
          return editedFile;
        }
        targetInputFile = editedFile;
      } catch (_) {}
    }

    final bytes = await targetInputFile.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    for (int pageIdx = 0; pageIdx < document.pages.count; pageIdx++) {
      final page = document.pages[pageIdx];
      final pageSize = page.size;

      // 1. In-place Replacement of Existing Text Objects (Redact original + Draw replacement)
      final modifiedSpans = modifiedSpansByPage?[pageIdx] ?? [];
      for (final span in modifiedSpans) {
        if (!span.isModified) continue;

        // Use exact PDF points bounding box for sub-pixel accuracy with normalized fallback
        final hasExactBounds =
            span.pdfBounds.width > 0 && span.pdfBounds.height > 0;
        final coverLeft = hasExactBounds
            ? (span.pdfBounds.left - 1.5)
            : (span.normalizedRect.left * pageSize.width - 2);
        final coverTop = hasExactBounds
            ? (span.pdfBounds.top - 1.0)
            : (span.normalizedRect.top * pageSize.height - 1);
        final coverWidth = hasExactBounds
            ? (span.pdfBounds.width + 3.0)
            : (span.normalizedRect.width * pageSize.width + 4);
        final coverHeight = hasExactBounds
            ? (span.pdfBounds.height + 2.0)
            : (span.normalizedRect.height * pageSize.height + 2);

        // Cover / redact original text with crisp white background
        final coverBrush = PdfSolidBrush(PdfColor(255, 255, 255));
        page.graphics.drawRectangle(
          brush: coverBrush,
          bounds: Rect.fromLTWH(coverLeft, coverTop, coverWidth, coverHeight),
        );

        // Draw the new updated text exactly in place preserving font family, style, and size
        final family = span.fontFamily;
        final isBold = span.isBold;
        final isItalic = span.isItalic;

        PdfStandardFont font;
        if (isBold && isItalic) {
          font = PdfStandardFont(
            family,
            span.fontSize,
            multiStyle: [PdfFontStyle.bold, PdfFontStyle.italic],
          );
        } else if (isBold) {
          font = PdfStandardFont(
            family,
            span.fontSize,
            style: PdfFontStyle.bold,
          );
        } else if (isItalic) {
          font = PdfStandardFont(
            family,
            span.fontSize,
            style: PdfFontStyle.italic,
          );
        } else {
          font = PdfStandardFont(
            family,
            span.fontSize,
            style: PdfFontStyle.regular,
          );
        }

        final textBrush = PdfSolidBrush(
          PdfColor(span.color.red, span.color.green, span.color.blue),
        );

        final textLeft = hasExactBounds
            ? span.pdfBounds.left
            : (span.normalizedRect.left * pageSize.width);
        final textTop = hasExactBounds
            ? span.pdfBounds.top
            : (span.normalizedRect.top * pageSize.height);

        page.graphics.drawString(
          span.currentText,
          font,
          brush: textBrush,
          bounds: Rect.fromLTWH(
            textLeft,
            textTop,
            pageSize.width - textLeft,
            span.fontSize * 2.5,
          ),
        );
      }

      // 2. Draw Highlights / Rectangles
      final highlights = highlightsByPage[pageIdx] ?? [];
      for (final h in highlights) {
        final brush = PdfSolidBrush(
          PdfColor(
            h.color.red,
            h.color.green,
            h.color.blue,
            (h.opacity * 255).toInt(),
          ),
        );
        page.graphics.drawRectangle(
          brush: brush,
          bounds: Rect.fromLTWH(
            h.normalizedRect.left * pageSize.width,
            h.normalizedRect.top * pageSize.height,
            h.normalizedRect.width * pageSize.width,
            h.normalizedRect.height * pageSize.height,
          ),
        );
      }

      // 3. Draw Freehand Pen Paths
      final paths = drawPathsByPage[pageIdx] ?? [];
      for (final path in paths) {
        if (path.normalizedPoints.length < 2) continue;
        final pen = PdfPen(
          PdfColor(path.color.red, path.color.green, path.color.blue),
          width: path.strokeWidth,
        );
        for (int i = 0; i < path.normalizedPoints.length - 1; i++) {
          final p1 = path.normalizedPoints[i];
          final p2 = path.normalizedPoints[i + 1];
          page.graphics.drawLine(
            pen,
            Offset(p1.dx * pageSize.width, p1.dy * pageSize.height),
            Offset(p2.dx * pageSize.width, p2.dy * pageSize.height),
          );
        }
      }

      // 4. Draw Text Annotations
      final textEdits = textEditsByPage[pageIdx] ?? [];
      for (final t in textEdits) {
        final font = PdfStandardFont(
          PdfFontFamily.helvetica,
          t.fontSize,
          style: t.isBold ? PdfFontStyle.bold : PdfFontStyle.regular,
        );
        final brush = PdfSolidBrush(
          PdfColor(t.color.red, t.color.green, t.color.blue),
        );
        page.graphics.drawString(
          t.text,
          font,
          brush: brush,
          bounds: Rect.fromLTWH(
            t.normalizedPosition.dx * pageSize.width,
            t.normalizedPosition.dy * pageSize.height,
            pageSize.width - (t.normalizedPosition.dx * pageSize.width),
            t.fontSize * 3,
          ),
        );
      }
    }

    final outputDir = await getApplicationDocumentsDirectory();
    final baseName = inputFile.uri.pathSegments.last.replaceAll('.pdf', '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputFile = File(
      '${outputDir.path}/edited_${baseName}_$timestamp.pdf',
    );
    await outputFile.writeAsBytes(document.saveSync());
    document.dispose();

    return outputFile;
  }

  // Stamp Signature Image / Vector at exact normalized Rect coordinates on target PDF page
  static Future<File> stampSignatureOnPdf({
    required File inputFile,
    required Uint8List signaturePngBytes,
    required int pageIndex,
    required Rect normalizedRect,
  }) async {
    final bytes = await inputFile.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    if (pageIndex >= 0 && pageIndex < document.pages.count) {
      final page = document.pages[pageIndex];
      final pageSize = page.size;

      final stampRect = Rect.fromLTWH(
        normalizedRect.left * pageSize.width,
        normalizedRect.top * pageSize.height,
        normalizedRect.width * pageSize.width,
        normalizedRect.height * pageSize.height,
      );

      final PdfBitmap bitmap = PdfBitmap(signaturePngBytes);
      page.graphics.drawImage(bitmap, stampRect);
    }

    final outputDir = await getApplicationDocumentsDirectory();
    final baseName = inputFile.uri.pathSegments.last.replaceAll('.pdf', '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputFile = File('${outputDir.path}/${baseName}_signed_$timestamp.pdf');
    await outputFile.writeAsBytes(document.saveSync());
    document.dispose();

    return outputFile;
  }
}

class PdfExistingTextSpan {
  final String id;
  final String originalText;
  String currentText;
  final Rect pdfBounds;
  final Rect normalizedRect;
  final Size originalPageSize;
  double fontSize;
  Color color;
  bool isBold;
  bool isItalic;
  String fontName;
  PdfFontFamily fontFamily;
  bool isModified;

  PdfExistingTextSpan({
    required this.id,
    required this.originalText,
    required this.currentText,
    required this.pdfBounds,
    required this.normalizedRect,
    this.originalPageSize = const Size(595.28, 841.89),
    required this.fontSize,
    this.color = const Color(0xFF000000),
    this.fontName = 'Helvetica',
    this.fontFamily = PdfFontFamily.helvetica,
    this.isBold = false,
    this.isItalic = false,
    this.isModified = false,
  });

  String get fontFamilyDisplayName {
    switch (fontFamily) {
      case PdfFontFamily.timesRoman:
        return 'Times Roman (Serif)';
      case PdfFontFamily.courier:
        return 'Courier (Monospace)';
      case PdfFontFamily.symbol:
        return 'Symbol';
      case PdfFontFamily.zapfDingbats:
        return 'ZapfDingbats';
      case PdfFontFamily.helvetica:
        return 'Helvetica / Arial (Sans)';
    }
  }

  List<String> get flutterFontFamilyFallback {
    switch (fontFamily) {
      case PdfFontFamily.timesRoman:
        return const ['Times New Roman', 'Times', 'Georgia', 'serif'];
      case PdfFontFamily.courier:
        return const ['Courier New', 'Courier', 'Menlo', 'monospace'];
      case PdfFontFamily.helvetica:
      default:
        return const ['Helvetica', 'Arial', 'sans-serif'];
    }
  }

  PdfExistingTextSpan copyWith({
    String? currentText,
    double? fontSize,
    Color? color,
    bool? isBold,
    bool? isItalic,
    String? fontName,
    PdfFontFamily? fontFamily,
    Size? originalPageSize,
    bool? isModified,
  }) {
    return PdfExistingTextSpan(
      id: id,
      originalText: originalText,
      currentText: currentText ?? this.currentText,
      pdfBounds: pdfBounds,
      normalizedRect: normalizedRect,
      originalPageSize: originalPageSize ?? this.originalPageSize,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      fontName: fontName ?? this.fontName,
      fontFamily: fontFamily ?? this.fontFamily,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isModified: isModified ?? this.isModified,
    );
  }
}

class PdfTextEdit {
  final String text;
  final Offset normalizedPosition;
  final double fontSize;
  final Color color;
  final bool isBold;

  PdfTextEdit({
    required this.text,
    required this.normalizedPosition,
    this.fontSize = 14,
    this.color = const Color(0xFF000000),
    this.isBold = false,
  });
}

class PdfDrawPath {
  final List<Offset> normalizedPoints;
  final Color color;
  final double strokeWidth;

  PdfDrawPath({
    required this.normalizedPoints,
    required this.color,
    this.strokeWidth = 3.0,
  });
}

class PdfHighlightBox {
  final Rect normalizedRect;
  final Color color;
  final double opacity;

  PdfHighlightBox({
    required this.normalizedRect,
    required this.color,
    this.opacity = 0.35,
  });
}
