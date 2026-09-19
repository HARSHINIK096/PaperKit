import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:maskerv_flutter/core/providers/files_provider.dart';
import 'package:maskerv_flutter/core/widgets/document_picker_sheet.dart';
import 'package:maskerv_flutter/features/p2p_share/widgets/airshare_file_selector_sheet.dart';
import 'package:maskerv_flutter/features/p2p_share/p2p_mesh_share_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentPickerSheet & AirShare P2P File Selector Tests', () {
    testWidgets('DocumentPickerSheet renders title, tabs, search, and sample docs', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => FilesProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: DocumentPickerSheet(
                title: 'Select Document to AirShare',
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Header title
      expect(find.text('Select Document to AirShare'), findsOneWidget);

      // Tabs
      expect(find.text('App Storage'), findsOneWidget);
      expect(find.text('Device Storage'), findsOneWidget);
      expect(find.text('Sample Docs'), findsOneWidget);
      expect(find.text('Paste Text'), findsOneWidget);

      // Search bar hint
      expect(find.text('Search stored documents...'), findsOneWidget);
    });

    testWidgets('Switching to Sample Docs tab displays sample papers', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => FilesProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: DocumentPickerSheet(
                title: 'Import / Select Document',
                initialTab: 2, // Sample Docs
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.textContaining('Academic Research Paper'), findsOneWidget);
      expect(find.textContaining('Computer Science Syllabus'), findsOneWidget);
      expect(find.textContaining('Legal Agreement Template'), findsOneWidget);
    });

    testWidgets('AirShareFileSelectorSheet.show opens DocumentPickerSheet', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => FilesProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => AirShareFileSelectorSheet.show(context),
                  child: const Text('Open AirShare Selector'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open AirShare Selector'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Select Document to AirShare'), findsOneWidget);
    });

    testWidgets('P2PMeshShareScreen renders CompactUploadContainer and Quick Jump Pills', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => FilesProvider(),
          child: const MaterialApp(
            home: P2PMeshShareScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the Send/Host tab contains upload container and jump buttons
      expect(find.text('AirShare Document Beam'), findsOneWidget);
      expect(find.text('In-App Files'), findsOneWidget);
      expect(find.text('Phone Storage'), findsOneWidget);
    });
  });
}
