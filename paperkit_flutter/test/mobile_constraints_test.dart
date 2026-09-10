import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:paperkit_flutter/core/providers/backend_provider.dart';
import 'package:paperkit_flutter/core/providers/files_provider.dart';
import 'package:paperkit_flutter/core/providers/history_provider.dart';
import 'package:paperkit_flutter/core/providers/theme_provider.dart';
import 'package:paperkit_flutter/core/theme/app_theme.dart';
import 'package:paperkit_flutter/features/image_media_tools/media_downloader_screen.dart';
import 'package:paperkit_flutter/features/pdf_tools/pdf_editor_screen.dart';
import 'package:paperkit_flutter/features/home/home_screen.dart';
import 'package:paperkit_flutter/features/tools/all_tools_screen.dart';

Widget createMobileTestApp(Widget child, {Size mobileSize = const Size(390, 844)}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => BackendProvider()),
      ChangeNotifierProvider(create: (_) => FilesProvider()),
      ChangeNotifierProvider(create: (_) => HistoryProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(
          size: mobileSize,
          padding: const EdgeInsets.only(top: 44, bottom: 34),
          devicePixelRatio: 3.0,
        ),
        child: SizedBox(
          width: mobileSize.width,
          height: mobileSize.height,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Mobile Phone Constraints Tests (360px & 390px Viewports)', () {
    testWidgets('MediaDownloaderScreen - YouTube & Spotify UI on mobile constraints (360x780)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340); // 360 x 780 @ 3.0x
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createMobileTestApp(
          const MediaDownloaderScreen(initialType: 'youtube'),
          mobileSize: const Size(360, 780),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and UI render without overflow
      expect(find.text('Media Downloader'), findsOneWidget);
      expect(find.text('YouTube Video'), findsOneWidget);
      expect(find.text('Spotify Audio'), findsOneWidget);
      expect(find.text('Download Media'), findsOneWidget);

      // Enter YouTube URL
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'https://youtu.be/SoZu9nu6m0o');
      await tester.pumpAndSettle();
      expect(find.text('https://youtu.be/SoZu9nu6m0o'), findsOneWidget);

      // Switch to Spotify on mobile touch
      await tester.tap(find.text('Spotify Audio'));
      await tester.pumpAndSettle();

      // Enter Spotify URL
      await tester.enterText(textField, 'https://open.spotify.com/track/47RTQoh3pzjhWLUMllNRRJ');
      await tester.pumpAndSettle();
      expect(find.text('https://open.spotify.com/track/47RTQoh3pzjhWLUMllNRRJ'), findsOneWidget);

      // Verify no RenderFlex overflows
      expect(tester.takeException(), isNull);
    });

    testWidgets('PDFEditorScreen - Mobile Phone Constraints (390x844)', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532); // 390 x 844 @ 3.0x
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createMobileTestApp(
          const PDFEditorScreen(),
          mobileSize: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      // Verify PDF Editor placeholder renders on mobile without overflow
      expect(find.text('PDF Editor'), findsOneWidget);
      expect(find.text('Select a PDF Document to Edit'), findsOneWidget);
      expect(find.text('Browse Files'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('HomeScreen & AllToolsScreen - Mobile Phone Constraints', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createMobileTestApp(
          const HomeScreen(),
          mobileSize: const Size(360, 800),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('PaperKit'), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        createMobileTestApp(
          const AllToolsScreen(),
          mobileSize: const Size(360, 800),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Tools'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
