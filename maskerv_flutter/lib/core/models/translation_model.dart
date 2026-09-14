class TranslationSegment {
  final int pageNumber;
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;

  TranslationSegment({
    required this.pageNumber,
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  factory TranslationSegment.fromJson(Map<String, dynamic> json) => TranslationSegment(
        pageNumber: json['pageNumber'] as int? ?? 1,
        originalText: json['originalText'] as String? ?? '',
        translatedText: json['translatedText'] as String? ?? '',
        sourceLanguage: json['sourceLanguage'] as String? ?? 'en',
        targetLanguage: json['targetLanguage'] as String? ?? 'es',
      );

  Map<String, dynamic> toJson() => {
        'pageNumber': pageNumber,
        'originalText': originalText,
        'translatedText': translatedText,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
      };
}

class GlossaryTerm {
  final String id;
  final String sourceTerm;
  final String targetTerm;
  final String sourceLanguage;
  final String targetLanguage;
  final String domainCategory;

  GlossaryTerm({
    required this.id,
    required this.sourceTerm,
    required this.targetTerm,
    this.sourceLanguage = 'en',
    this.targetLanguage = 'es',
    this.domainCategory = 'General',
  });

  factory GlossaryTerm.fromJson(Map<String, dynamic> json) => GlossaryTerm(
        id: json['id'] as String,
        sourceTerm: json['sourceTerm'] as String? ?? '',
        targetTerm: json['targetTerm'] as String? ?? '',
        sourceLanguage: json['sourceLanguage'] as String? ?? 'en',
        targetLanguage: json['targetLanguage'] as String? ?? 'es',
        domainCategory: json['domainCategory'] as String? ?? 'General',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceTerm': sourceTerm,
        'targetTerm': targetTerm,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
        'domainCategory': domainCategory,
      };
}
