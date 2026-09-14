import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maskerv_flutter/core/providers/backend_provider.dart';
import 'package:maskerv_flutter/core/providers/files_provider.dart';
import 'package:maskerv_flutter/core/providers/history_provider.dart';
import 'package:maskerv_flutter/core/providers/i18n_provider.dart';
import 'package:maskerv_flutter/core/providers/theme_provider.dart';
import 'package:maskerv_flutter/main.dart';

void main() {
  testWidgets('MaskerV app launches smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final backend = BackendProvider();
    final theme = ThemeProvider();
    final files = FilesProvider();
    final history = HistoryProvider();
    final i18n = I18nProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider.value(value: backend),
          ChangeNotifierProvider.value(value: files),
          ChangeNotifierProvider.value(value: history),
          ChangeNotifierProvider.value(value: i18n),
        ],
        child: const MaskerVApp(),
      ),
    );

    expect(find.byType(MaskerVApp), findsOneWidget);

    // Dispose and settle
    backend.dispose();
    await tester.pump(const Duration(milliseconds: 1500));
  });
}
