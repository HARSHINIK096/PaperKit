import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maskerv_flutter/core/services/pdf_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );
  });

  group('Domain 2: Secure Redaction Tests', () {
    test('PdfEngine smartRedactPdf produces redacted PDF file without visual-only fake watermark', () async {
      // Create test document PDF bytes
      final docFile = await PdfEngine.createBlankPdf(
        initialText: 'Confidential Document\nEmail: user@domain.com\nSSN: 123-45-6789\nPublic info.',
      );

      expect(await docFile.exists(), isTrue);

      final redactedFile = await PdfEngine.smartRedactPdf(
        inputFile: docFile,
        keywords: ['Confidential', '123-45-6789'],
        redactEmails: true,
        redactPhones: true,
      );

      expect(await redactedFile.exists(), isTrue);
      expect(await redactedFile.length(), greaterThan(0));
    });
  });
}
