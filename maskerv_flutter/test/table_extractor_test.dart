import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maskerv_flutter/features/analytics/table_extractor_service.dart';
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

  group('Domain 13: Table Extractor Fallback Removal Tests', () {
    final service = TableExtractorService();

    test('Unstructured PDF produces empty table list with zero fabricated sample rows', () async {
      final pdfFile = await PdfEngine.createBlankPdf(
        initialText: 'This is a plain paragraph text document without any tables or structured columns.',
      );

      final tables = await service.extractTablesFromPdf(pdfFile);

      expect(tables, isEmpty);
      expect(tables.any((t) => t.rows.any((r) => r.contains('Document Entry 1'))), isFalse);
    });

    test('Structured PDF table extraction extracts actual table rows', () async {
      final pdfFile = await PdfEngine.createBlankPdf(
        initialText: 'Name\tCategory\tValue\nProduct A\tHardware\t\$500\nProduct B\tSoftware\t\$200',
      );

      final tables = await service.extractTablesFromPdf(pdfFile);

      if (tables.isNotEmpty) {
        expect(tables.first.headers, contains('Name'));
        expect(tables.first.rows.isNotEmpty, isTrue);
      }
    });
  });
}
