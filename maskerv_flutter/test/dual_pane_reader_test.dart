import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:maskerv_flutter/core/providers/files_provider.dart';
import 'package:maskerv_flutter/features/workspace/dual_pane_workspace_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dual-Pane Workspace & Reader UI Tests', () {
    testWidgets('DualPaneWorkspaceScreen renders 5-card swiping carousel, toolbar, and empty pane cards', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => FilesProvider(),
          child: const MaterialApp(
            home: DualPaneWorkspaceScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check AppBar tabs
      expect(find.text('Dual-Pane Reader'), findsOneWidget);
      expect(find.text('Syllabus Tracker'), findsOneWidget);

      // Check 5-Card Swiping Carousel header
      expect(find.textContaining('How it works'), findsOneWidget);

      // Check action toolbar buttons & chips
      expect(find.text('Load Pane A'), findsOneWidget);
      expect(find.text('Load Pane B'), findsOneWidget);
      expect(find.text('Sync Scroll'), findsOneWidget);
      expect(find.text('AI Comparison Mode'), findsOneWidget);

      // Check interactive empty cards for Pane A & Pane B
      expect(find.text('Pane A (Primary Document)'), findsOneWidget);
      expect(find.text('Pane B (Reference Document)'), findsOneWidget);
      expect(find.text('Import Document'), findsNWidgets(2));
    });

    testWidgets('Tapping empty Pane A opens DocumentPickerSheet', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => FilesProvider(),
          child: const MaterialApp(
            home: DualPaneWorkspaceScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Pane A empty card button
      final paneAButton = find.text('Pane A (Primary Document)');
      expect(paneAButton, findsOneWidget);

      await tester.tap(paneAButton);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify DocumentPickerSheet opens
      expect(find.text('Import Document (Pane A)'), findsOneWidget);
      expect(find.text('App Storage'), findsOneWidget);
      expect(find.text('Device Storage'), findsOneWidget);
    });
  });
}
