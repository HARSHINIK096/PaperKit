import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maskerv_flutter/core/i18n/app_dictionary.dart';
import 'package:maskerv_flutter/core/i18n/app_language.dart';
import 'package:maskerv_flutter/core/providers/i18n_provider.dart';
import 'package:maskerv_flutter/core/widgets/language_selector_sheet.dart';
import 'package:maskerv_flutter/features/welcome/landing_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('I18n Architecture Tests (Matched to I18nContext.jsx)', () {
    test('AppLanguage contains all 7 supported languages matching I18nContext.jsx', () {
      final codes = AppLanguage.supportedLanguages.map((l) => l.code).toList();
      expect(codes, containsAll(['en', 'es', 'fr', 'de', 'zh', 'ja', 'hi']));
      expect(AppLanguage.supportedLanguages.length, equals(7));

      final es = AppLanguage.findByCode('es');
      expect(es.name, equals('Spanish'));
      expect(es.nativeName, equals('Español'));
      expect(es.flag, equals('🇪🇸'));
      expect(es.countryCode, equals('ES'));

      final hi = AppLanguage.findByCode('hi');
      expect(hi.name, equals('Hindi'));
      expect(hi.nativeName, equals('हिन्दी'));
      expect(hi.flag, equals('🇮🇳'));

      // Unknown code defaults to English
      final fallback = AppLanguage.findByCode('unknown');
      expect(fallback.code, equals('en'));
    });

    test('AppDictionary contains 176 translation keys per language', () {
      for (final lang in ['en', 'es', 'fr', 'de', 'zh', 'ja', 'hi']) {
        expect(AppDictionary.dictionary.containsKey(lang), isTrue);
        expect(AppDictionary.dictionary[lang]!.length, equals(176));
      }

      // Check specific translations
      expect(AppDictionary.lookup('en', 'home'), equals('Home'));
      expect(AppDictionary.lookup('es', 'home'), equals('Inicio'));
      expect(AppDictionary.lookup('fr', 'home'), equals('Accueil'));
      expect(AppDictionary.lookup('de', 'home'), equals('Startseite'));
      expect(AppDictionary.lookup('zh', 'home'), equals('主页'));
      expect(AppDictionary.lookup('ja', 'home'), equals('ホーム'));
      expect(AppDictionary.lookup('hi', 'home'), equals('मुख्य पृष्ठ'));

      // Check key fallback
      expect(AppDictionary.lookup('es', 'non_existent_key_xyz'), equals('non_existent_key_xyz'));
    });

    test('I18nProvider manages language change and persistence', () async {
      final provider = I18nProvider();
      expect(provider.currentLanguage, equals('en'));
      expect(provider.t('tools'), equals('All Tools'));

      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      await provider.setLanguage('es');
      expect(notified, isTrue);
      expect(provider.currentLanguage, equals('es'));
      expect(provider.currentLocale.languageCode, equals('es'));
      expect(provider.currentAppLanguage.nativeName, equals('Español'));
      expect(provider.t('tools'), equals('Herramientas'));

      // Check persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('maskerv_lang'), equals('es'));

      // Switch to Hindi
      await provider.setLanguage('hi');
      expect(provider.currentLanguage, equals('hi'));
      expect(provider.t('tools'), equals('सभी टूल्स'));
      expect(prefs.getString('maskerv_lang'), equals('hi'));
    });

    testWidgets('LanguageSelectorSheet displays all languages and switches language on tap', (tester) async {
      final i18n = I18nProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<I18nProvider>.value(
          value: i18n,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => LanguageSelectorSheet.show(context),
                  child: const Text('Open Picker'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Check sheet displays languages
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
      expect(find.text('Deutsch'), findsOneWidget);

      // Tap Español
      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();

      expect(i18n.currentLanguage, equals('es'));
    });

    testWidgets('LandingScreen updates UI reactively when language changes', (tester) async {
      final i18n = I18nProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<I18nProvider>.value(
          value: i18n,
          child: const MaterialApp(
            home: LandingScreen(),
          ),
        ),
      );

      await tester.pump();

      // Default English headline
      expect(find.text('Clear speed.\nPure calm.'), findsOneWidget);

      // Switch to Spanish
      await i18n.setLanguage('es');
      await tester.pump();

      expect(find.text('Velocidad clara.\nCalma total.'), findsOneWidget);

      // Switch to Hindi
      await i18n.setLanguage('hi');
      await tester.pump();

      expect(find.text('अति तीव्र गति।\nपूर्ण शांति।'), findsOneWidget);
    });
  });
}
