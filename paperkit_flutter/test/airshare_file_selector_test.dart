import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:maskerv_flutter/core/widgets/compact_upload_container.dart';
import 'package:maskerv_flutter/features/p2p_share/widgets/airshare_file_selector_sheet.dart';
import 'package:maskerv_flutter/features/p2p_share/p2p_mesh_share_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AirShare WhatsApp-Style In-App & In-Phone File Selector', () {
    testWidgets('AirShareFileSelectorSheet renders search, dual tabs, and category filters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AirShareFileSelectorSheet(
              initialTab: 0,
            ),
          ),
        ),
      );

      await tester.pump();

      // Check header and search bar
      expect(find.text('Select Document to AirShare'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search documents by name or extension...'), findsOneWidget);

      // Check dual-source tabs
      expect(find.textContaining('In-App Files'), findsOneWidget);
      expect(find.textContaining('Phone Files'), findsOneWidget);

      // Check category filter chips
      expect(find.text('All Files'), findsOneWidget);
      expect(find.text('PDFs'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Images'), findsOneWidget);
      expect(find.text('Sheets'), findsOneWidget);
    });

    testWidgets('Switching to Phone Files tab displays browse device files tile and phone files', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AirShareFileSelectorSheet(
              initialTab: 1, // Phone Files Tab
              customPhoneFiles: [
                AirShareFileItem(
                  name: 'contract_sample.pdf',
                  path: '/storage/download/contract_sample.pdf',
                  size: 1024 * 500,
                  modifiedAt: DateTime.now(),
                  isInApp: false,
                  extension: 'pdf',
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();

      // Check that "Browse More Files on Phone" tile is rendered
      expect(find.text('Browse More Files on Phone'), findsOneWidget);
      expect(find.text('Open device storage to select any document or file'), findsOneWidget);
      expect(find.text('contract_sample.pdf'), findsOneWidget);
    });

    testWidgets('CompactUploadContainer with onTap triggers custom callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactUploadContainer(
              files: const [],
              onFilesSelected: (_) {},
              onTap: () {
                tapped = true;
              },
              title: 'AirShare Document Beam',
              subtitle: 'Tap to select from In-App Files or Phone Storage',
            ),
          ),
        ),
      );

      expect(find.text('AirShare Document Beam'), findsOneWidget);
      expect(find.text('Tap to select from In-App Files or Phone Storage'), findsOneWidget);

      // Tap container
      await tester.tap(find.text('AirShare Document Beam'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('P2PMeshShareScreen renders CompactUploadContainer and Quick Jump Pills', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: P2PMeshShareScreen(),
        ),
      );

      await tester.pump();

      // Verify the Send/Host tab contains the new upload container and source jump buttons
      expect(find.text('AirShare Document Beam'), findsOneWidget);
      expect(find.text('In-App Files'), findsOneWidget);
      expect(find.text('Phone Storage'), findsOneWidget);
    });
  });
}
