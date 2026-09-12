class ChapterItem {
  final String id;
  final String title;
  final String htmlContent;
  final int pageStart;

  ChapterItem({
    required this.id,
    required this.title,
    required this.htmlContent,
    this.pageStart = 1,
  });

  factory ChapterItem.fromJson(Map<String, dynamic> json) => ChapterItem(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Chapter',
        htmlContent: json['htmlContent'] as String? ?? '',
        pageStart: json['pageStart'] as int? ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'htmlContent': htmlContent,
        'pageStart': pageStart,
      };
}

class CoverConfig {
  final String title;
  final String subtitle;
  final String author;
  final int backgroundColorHex;
  final int textColorHex;
  final String? backgroundImagePath;

  const CoverConfig({
    this.title = 'Untitled E-Book',
    this.subtitle = '',
    this.author = 'PaperKit Publisher',
    this.backgroundColorHex = 0xFF1E88E5,
    this.textColorHex = 0xFFFFFFFF,
    this.backgroundImagePath,
  });

  factory CoverConfig.fromJson(Map<String, dynamic> json) => CoverConfig(
        title: json['title'] as String? ?? 'Untitled E-Book',
        subtitle: json['subtitle'] as String? ?? '',
        author: json['author'] as String? ?? 'PaperKit Publisher',
        backgroundColorHex: json['backgroundColorHex'] as int? ?? 0xFF1E88E5,
        textColorHex: json['textColorHex'] as int? ?? 0xFFFFFFFF,
        backgroundImagePath: json['backgroundImagePath'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'author': author,
        'backgroundColorHex': backgroundColorHex,
        'textColorHex': textColorHex,
        'backgroundImagePath': backgroundImagePath,
      };
}

class PreflightReport {
  final int pageCount;
  final String pageSize;
  final int estimatedDpi;
  final String colorSpace;
  final bool fontsEmbedded;
  final List<String> warnings;
  final bool isPrintReady;

  PreflightReport({
    required this.pageCount,
    required this.pageSize,
    required this.estimatedDpi,
    required this.colorSpace,
    required this.fontsEmbedded,
    required this.warnings,
    required this.isPrintReady,
  });

  factory PreflightReport.fromJson(Map<String, dynamic> json) => PreflightReport(
        pageCount: json['pageCount'] as int? ?? 0,
        pageSize: json['pageSize'] as String? ?? 'A4',
        estimatedDpi: json['estimatedDpi'] as int? ?? 300,
        colorSpace: json['colorSpace'] as String? ?? 'RGB',
        fontsEmbedded: json['fontsEmbedded'] as bool? ?? true,
        warnings: (json['warnings'] as List? ?? []).cast<String>(),
        isPrintReady: json['isPrintReady'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'pageCount': pageCount,
        'pageSize': pageSize,
        'estimatedDpi': estimatedDpi,
        'colorSpace': colorSpace,
        'fontsEmbedded': fontsEmbedded,
        'warnings': warnings,
        'isPrintReady': isPrintReady,
      };
}
