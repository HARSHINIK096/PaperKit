import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:paperkit_flutter/core/providers/backend_provider.dart';
import 'package:paperkit_flutter/core/providers/files_provider.dart';
import 'package:paperkit_flutter/core/providers/history_provider.dart';
import 'package:paperkit_flutter/core/providers/theme_provider.dart';
import 'package:paperkit_flutter/main.dart';

void main() {
  testWidgets('PaperKit app launches smoke test', (WidgetTester tester) async {
    final backend = BackendProvider();
    final theme = ThemeProvider();
    final files = FilesProvider();
    final history = HistoryProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider.value(value: backend),
          ChangeNotifierProvider.value(value: files),
          ChangeNotifierProvider.value(value: history),
        ],
        child: const PaperKitApp(),
      ),
    );

    expect(find.byType(PaperKitApp), findsOneWidget);

    // Dispose and settle
    backend.dispose();
    await tester.pump(const Duration(milliseconds: 1500));
  });
}
