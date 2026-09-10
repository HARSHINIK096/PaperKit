import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfEngine {
  // Merge multiple PDF files into one
  static Future<File> mergePdfFiles(List<File> files, String outputFileName) async {
    final PdfDocument finalDocument = PdfDocument();

    for (final file in files) {
      final bytes = await file.readAsBytes();
      final PdfDocument inputDocument = PdfDocument(inputBytes: bytes);
      
      for (int i = 0; i < inputDocument.pages.count; i++) {
        final PdfTemplate template = inputDocument.pages[i].createTemplate();
        final PdfPage page = finalDocument.pages.add();
        page.graphics.drawPdfTemplate(template, const Offset(0, 0));
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
  static Future<List<File>> splitPdf(File inputFile, List<List<int>> ranges) async {
    final bytes = await inputFile.readAsBytes();
    final PdfDocument inputDocument = PdfDocument(inputBytes: bytes);
    final outputDir = await getApplicationDocumentsDirectory();
    final List<File> resultFiles = [];

    int partIndex = 1;
    for (final range in ranges) {
      final PdfDocument splitDocument = PdfDocument();
      for (final pageIndex in range) {
        if (pageIndex >= 0 && pageIndex < inputDocument.pages.count) {
          final PdfTemplate template = inputDocument.pages[pageIndex].createTemplate();
          final PdfPage newPage = splitDocument.pages.add();
          newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
        }
      }

      final fileName = '${inputFile.uri.pathSegments.last.replaceAll('.pdf', '')}_part_$partIndex.pdf';
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
  static Future<File> rotatePdf(File inputFile, int rotationAngleDegrees) async {
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
    final brush = PdfSolidBrush(PdfColor(128, 128, 128, (opacity * 255).round()));

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
        bounds: Rect.fromLTWH(-textSize.width / 2, -textSize.height / 2, textSize.width, textSize.height),
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
        final PdfTemplate template = inputDocument.pages[pageIndex].createTemplate();
        final PdfPage newPage = newDocument.pages.add();
        newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
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
}
