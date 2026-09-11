import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:maskerv_flutter/core/providers/backend_provider.dart';
import 'package:maskerv_flutter/core/providers/files_provider.dart';
import 'package:maskerv_flutter/core/providers/history_provider.dart';
import 'package:maskerv_flutter/core/providers/theme_provider.dart';
import 'package:maskerv_flutter/core/theme/app_theme.dart';
import 'package:maskerv_flutter/features/pdf_tools/pdf_editor_screen.dart';
import 'package:maskerv_flutter/features/home/home_screen.dart';
import 'package:maskerv_flutter/features/tools/all_tools_screen.dart';

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

      expect(find.text('MASKERV'), findsWidgets);
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
