import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../i18n/app_dictionary.dart';
import '../i18n/app_language.dart';

class I18nProvider extends ChangeNotifier {
  static const String _langKey = 'maskerv_lang';
  static const String _legacyLangKey = 'paperkit_lang';

  String _currentLanguage = 'en';
  bool _isInitialized = false;

  String get currentLanguage => _currentLanguage;
  Locale get currentLocale => Locale(_currentLanguage);
  AppLanguage get currentAppLanguage => AppLanguage.findByCode(_currentLanguage);
  List<AppLanguage> get supportedLanguages => AppLanguage.supportedLanguages;
  bool get isInitialized => _isInitialized;

  I18nProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_langKey) ?? prefs.getString(_legacyLangKey);
      if (saved != null && AppDictionary.dictionary.containsKey(saved)) {
        _currentLanguage = saved;
      }
    } catch (_) {
      // safe fallback
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    if (!AppDictionary.dictionary.containsKey(code)) return;
    if (_currentLanguage == code) return;

    _currentLanguage = code;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_langKey, code);
      await prefs.setString(_legacyLangKey, code);
    } catch (_) {
      // safe fallback
    }
  }

  String t(String key) {
    return AppDictionary.lookup(_currentLanguage, key);
  }
}

extension I18nContextExtension on BuildContext {
  String t(String key) => Provider.of<I18nProvider>(this, listen: true).t(key);
  I18nProvider get i18n => Provider.of<I18nProvider>(this, listen: false);
  I18nProvider get i18nWatch => Provider.of<I18nProvider>(this, listen: true);
}
