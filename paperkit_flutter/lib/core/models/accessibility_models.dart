enum ReadingProfileType {
  standard,
  dyslexiaFriendly,
  highContrast,
  lowVisualFatigue,
  sepia,
  dark,
  largeText,
}

class ReadingProfile {
  final ReadingProfileType type;
  final String name;
  final double fontSize;
  final double lineHeight;
  final double letterSpacing;
  final String fontFamily;
  final int backgroundColorValue;
  final int textColorValue;
  final bool bionicReadingEnabled;

  const ReadingProfile({
    required this.type,
    required this.name,
    required this.fontSize,
    required this.lineHeight,
    required this.letterSpacing,
    required this.fontFamily,
    required this.backgroundColorValue,
    required this.textColorValue,
    this.bionicReadingEnabled = false,
  });

  factory ReadingProfile.standard() => const ReadingProfile(
        type: ReadingProfileType.standard,
        name: 'Standard',
        fontSize: 16.0,
        lineHeight: 1.5,
        letterSpacing: 0.0,
        fontFamily: 'Roboto',
        backgroundColorValue: 0xFFFFFFFF,
        textColorValue: 0xFF212121,
      );

  factory ReadingProfile.dyslexiaFriendly() => const ReadingProfile(
        type: ReadingProfileType.dyslexiaFriendly,
        name: 'Dyslexia Friendly',
        fontSize: 18.0,
        lineHeight: 1.8,
        letterSpacing: 1.2,
        fontFamily: 'OpenDyslexic',
        backgroundColorValue: 0xFFFDFBF7,
        textColorValue: 0xFF111111,
        bionicReadingEnabled: true,
      );

  factory ReadingProfile.highContrast() => const ReadingProfile(
        type: ReadingProfileType.highContrast,
        name: 'High Contrast',
        fontSize: 18.0,
        lineHeight: 1.6,
        letterSpacing: 0.5,
        fontFamily: 'Roboto',
        backgroundColorValue: 0xFF000000,
        textColorValue: 0xFFFFFF00,
      );

  factory ReadingProfile.sepia() => const ReadingProfile(
        type: ReadingProfileType.sepia,
        name: 'Warm Sepia',
        fontSize: 16.0,
        lineHeight: 1.5,
        letterSpacing: 0.2,
        fontFamily: 'Serif',
        backgroundColorValue: 0xFFF4ECD8,
        textColorValue: 0xFF3D3226,
      );

  factory ReadingProfile.dark() => const ReadingProfile(
        type: ReadingProfileType.dark,
        name: 'Midnight Dark',
        fontSize: 16.0,
        lineHeight: 1.5,
        letterSpacing: 0.2,
        fontFamily: 'Roboto',
        backgroundColorValue: 0xFF121212,
        textColorValue: 0xFFE0E0E0,
      );

  factory ReadingProfile.fromJson(Map<String, dynamic> json) => ReadingProfile(
        type: ReadingProfileType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ReadingProfileType.standard,
        ),
        name: json['name'] as String? ?? 'Standard',
        fontSize: (json['fontSize'] as num? ?? 16.0).toDouble(),
        lineHeight: (json['lineHeight'] as num? ?? 1.5).toDouble(),
        letterSpacing: (json['letterSpacing'] as num? ?? 0.0).toDouble(),
        fontFamily: json['fontFamily'] as String? ?? 'Roboto',
        backgroundColorValue: json['backgroundColorValue'] as int? ?? 0xFFFFFFFF,
        textColorValue: json['textColorValue'] as int? ?? 0xFF212121,
        bionicReadingEnabled: json['bionicReadingEnabled'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'name': name,
        'fontSize': fontSize,
        'lineHeight': lineHeight,
        'letterSpacing': letterSpacing,
        'fontFamily': fontFamily,
        'backgroundColorValue': backgroundColorValue,
        'textColorValue': textColorValue,
        'bionicReadingEnabled': bionicReadingEnabled,
      };
}
