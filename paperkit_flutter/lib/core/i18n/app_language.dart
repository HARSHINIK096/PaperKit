class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final String countryCode;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.countryCode,
  });

  static const List<AppLanguage> supportedLanguages = [
    AppLanguage(code: 'en', name: 'English', nativeName: 'English', flag: '🇺🇸', countryCode: 'US'),
    AppLanguage(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸', countryCode: 'ES'),
    AppLanguage(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷', countryCode: 'FR'),
    AppLanguage(code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪', countryCode: 'DE'),
    AppLanguage(code: 'zh', name: 'Chinese', nativeName: '简体中文', flag: '🇨🇳', countryCode: 'CN'),
    AppLanguage(code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵', countryCode: 'JP'),
    AppLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳', countryCode: 'IN'),
  ];

  static AppLanguage findByCode(String code) {
    return supportedLanguages.firstWhere(
      (l) => l.code == code,
      orElse: () => supportedLanguages.first,
    );
  }
}
