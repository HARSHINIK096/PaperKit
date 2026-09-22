import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:maskerv_flutter/core/providers/files_provider.dart';
import 'package:maskerv_flutter/core/providers/history_provider.dart';
import 'package:maskerv_flutter/features/diagram_studio/diagram_service.dart';
import 'package:maskerv_flutter/features/diagram_studio/mind_map_diagram_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FilesProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('NotebookLM Mind Map Generation & Visual Graph Tests', () {
    test('DiagramService generates NotebookLM mindmap tree nodes', () async {
      final service = DiagramService();
      final testFile = File('/tmp/test_paper.pdf');
      final nodes = await service.generateMindMapFromDocument(testFile);

      expect(nodes.isNotEmpty, isTrue);
      final rootNode = nodes.first;
      expect(rootNode.parentId, isNull);
      expect(rootNode.children.isNotEmpty, isTrue);
    });

    testWidgets('MindMapDiagramScreen renders NotebookLM AI Mind Map Studio', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const MindMapDiagramScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Mind Map Graph'), findsWidgets);
      expect(
        find.textContaining('AI Analysis: Generate Mind Map'),
        findsOneWidget,
      );
    });
  });
}
