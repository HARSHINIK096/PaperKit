import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maskerv_flutter/core/services/api_service.dart';
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

  group('Invoice AI Parser & AI STT/TTS Tests', () {
    final apiService = ApiService();

    test('parseInvoiceDetails extracts structured fields from PDF document', () async {
      final pdfFile = await PdfEngine.createBlankPdf(
        initialText: 'ACME Supplies Ltd.\nInvoice #: INV-2026-99\nDate: 09/12/2026\nSubtotal: \$450.00\nTax: \$45.00\nTotal: \$495.00',
      );

      final data = await apiService.parseInvoiceDetails(pdfFile);

      expect(data, isNotNull);
      expect(data['invoiceNumber'], contains('INV-2026-99'));
      expect(data['totalAmount'], equals('\$495.00'));
    });

    test('transcribeSpeechAi handles audio transcription safely', () async {
      final audioFile = File('${Directory.systemTemp.path}/test_audio.m4a');
      await audioFile.writeAsBytes(List<int>.generate(64, (i) => i % 256));

      final transcription = await apiService.transcribeSpeechAi(audioFile: audioFile);
      expect(transcription, isNotEmpty);
    });

    test('synthesizeSpeechAi returns speech audio url/status', () async {
      final audioUrl = await apiService.synthesizeSpeechAi(text: 'Hello PaperKit AI speech synthesis.');
      expect(audioUrl, isA<String>());
    });
  });
}
