import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/providers/backend_provider.dart';
import 'core/providers/files_provider.dart';
import 'core/providers/history_provider.dart';
import 'core/providers/i18n_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set edge-to-edge transparent system overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BackendProvider()),
        ChangeNotifierProvider(create: (_) => FilesProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => I18nProvider()),
      ],
      child: const MaskerVApp(),
    ),
  );
}

class MaskerVApp extends StatelessWidget {
  const MaskerVApp({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.watch<I18nProvider>();

    return MaterialApp.router(
      title: 'MASKERV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      locale: i18n.currentLocale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: i18n.supportedLanguages.map((l) => Locale(l.code)),
      routerConfig: AppRouter.router,
    );
  }
}

/// Backward compatibility alias
typedef PaperKitApp = MaskerVApp;
