class MindMapNode {
  final String id;
  String title;
  String? parentId;
  final List<String> childrenIds;
  double x;
  double y;
  int colorHex;

  MindMapNode({
    required this.id,
    required this.title,
    this.parentId,
    List<String>? childrenIds,
    this.x = 0.0,
    this.y = 0.0,
    this.colorHex = 0xFF4A90E2,
  }) : childrenIds = childrenIds ?? [];

  factory MindMapNode.fromJson(Map<String, dynamic> json) => MindMapNode(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'New Node',
        parentId: json['parentId'] as String?,
        childrenIds: (json['childrenIds'] as List? ?? []).cast<String>(),
        x: (json['x'] as num? ?? 0.0).toDouble(),
        y: (json['y'] as num? ?? 0.0).toDouble(),
        colorHex: json['colorHex'] as int? ?? 0xFF4A90E2,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'parentId': parentId,
        'childrenIds': childrenIds,
        'x': x,
        'y': y,
        'colorHex': colorHex,
      };
}

enum VectorToolType { pen, highlighter, line, arrow, rectangle, circle, text, stickyNote }

class VectorAnnotation {
  final String id;
  final int pageIndex;
  final VectorToolType toolType;
  final List<Map<String, double>> points; // [{x: 0.1, y: 0.2}]
  final int colorHex;
  final double strokeWidth;
  final String text;

  VectorAnnotation({
    required this.id,
    required this.pageIndex,
    required this.toolType,
    required this.points,
    this.colorHex = 0xFFFF0000,
    this.strokeWidth = 3.0,
    this.text = '',
  });

  factory VectorAnnotation.fromJson(Map<String, dynamic> json) => VectorAnnotation(
        id: json['id'] as String,
        pageIndex: json['pageIndex'] as int? ?? 0,
        toolType: VectorToolType.values.firstWhere(
          (e) => e.name == json['toolType'],
          orElse: () => VectorToolType.pen,
        ),
        points: (json['points'] as List? ?? [])
            .map((p) => Map<String, double>.from(p as Map))
            .toList(),
        colorHex: json['colorHex'] as int? ?? 0xFFFF0000,
        strokeWidth: (json['strokeWidth'] as num? ?? 3.0).toDouble(),
        text: json['text'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'pageIndex': pageIndex,
        'toolType': toolType.name,
        'points': points,
        'colorHex': colorHex,
        'strokeWidth': strokeWidth,
        'text': text,
      };
}

class SlideItem {
  final String slideTitle;
  final List<String> bulletPoints;
  final String speakerNotes;

  SlideItem({
    required this.slideTitle,
    required this.bulletPoints,
    this.speakerNotes = '',
  });

  factory SlideItem.fromJson(Map<String, dynamic> json) => SlideItem(
        slideTitle: json['slideTitle'] as String? ?? 'Slide',
        bulletPoints: (json['bulletPoints'] as List? ?? []).cast<String>(),
        speakerNotes: json['speakerNotes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'slideTitle': slideTitle,
        'bulletPoints': bulletPoints,
        'speakerNotes': speakerNotes,
      };
}

class PresentationDeck {
  final String title;
  final List<SlideItem> slides;

  PresentationDeck({required this.title, required this.slides});

  factory PresentationDeck.fromJson(Map<String, dynamic> json) => PresentationDeck(
        title: json['title'] as String? ?? 'Presentation',
        slides: (json['slides'] as List? ?? [])
            .map((s) => SlideItem.fromJson(Map<String, dynamic>.from(s)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'slides': slides.map((s) => s.toJson()).toList(),
      };
}
