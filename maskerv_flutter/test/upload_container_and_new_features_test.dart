import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maskerv_flutter/core/constants/tool_registry.dart';
import 'package:maskerv_flutter/core/widgets/compact_upload_container.dart';
import 'package:maskerv_flutter/features/ai_tools/resume_scanner_screen.dart';

void main() {
  group('CompactUploadContainer & New Feature Screens Tests', () {
    test('ToolRegistry routes for Biometric App Lock & Resume Scanner are authoritative', () {
      final resumeTool = ToolRegistry.getById('parse-cv');
      expect(resumeTool, isNotNull);
      expect(resumeTool!.route, equals('/ai/resume'));
      expect(resumeTool.domainNumber, equals(3));
    });

    testWidgets('CompactUploadContainer renders in empty state with shader and browse pill', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactUploadContainer(
              files: const [],
              title: 'Upload Legal Document',
              subtitle: 'Select PDF or contract file',
              allowedExtensions: const ['pdf'],
              useShader: true,
              onFilesSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Upload Legal Document'), findsOneWidget);
      expect(find.text('Select PDF or contract file'), findsOneWidget);
      expect(find.text('.PDF'), findsOneWidget);
      expect(find.text('Browse'), findsOneWidget);
    });

    testWidgets('CompactUploadContainer renders selected file state with Ready pill', (tester) async {
      final testFile = File('test_document.pdf');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactUploadContainer(
              files: [testFile],
              title: 'Upload Legal Document',
              onFilesSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('test_document.pdf'), findsOneWidget);
      expect(find.text('READY'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
    });

    testWidgets('ResumeScannerScreen renders ATS Diagnostic features and 5-stage bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResumeScannerScreen(),
        ),
      );

      expect(find.text('1. Upload'), findsOneWidget);
      expect(find.text('2. Scan'), findsOneWidget);
      expect(find.text('3. Audit View'), findsOneWidget);
      expect(find.text('4. Download'), findsOneWidget);
      expect(find.text('5. Success'), findsOneWidget);
      expect(find.text('ATS Diagnostic Features'), findsOneWidget);
    });
  });
}
