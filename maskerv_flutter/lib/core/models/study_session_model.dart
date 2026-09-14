enum CardDifficulty { easy, medium, hard, forgotten }

class RecallItem {
  final String id;
  final String term;
  final String definition;
  final String sourceDocumentPath;
  final int pageIndex;
  bool isBlurred;
  int reviewCount;
  int successCount;
  DateTime? lastReviewedAt;
  DateTime nextReviewAt;
  int leitnerBox; // 1 to 5

  RecallItem({
    required this.id,
    required this.term,
    required this.definition,
    required this.sourceDocumentPath,
    this.pageIndex = 0,
    this.isBlurred = true,
    this.reviewCount = 0,
    this.successCount = 0,
    this.lastReviewedAt,
    DateTime? nextReviewAt,
    this.leitnerBox = 1,
  }) : nextReviewAt = nextReviewAt ?? DateTime.now();

  factory RecallItem.fromJson(Map<String, dynamic> json) => RecallItem(
        id: json['id'] as String,
        term: json['term'] as String,
        definition: json['definition'] as String,
        sourceDocumentPath: json['sourceDocumentPath'] as String? ?? '',
        pageIndex: json['pageIndex'] as int? ?? 0,
        isBlurred: json['isBlurred'] as bool? ?? true,
        reviewCount: json['reviewCount'] as int? ?? 0,
        successCount: json['successCount'] as int? ?? 0,
        lastReviewedAt: json['lastReviewedAt'] != null
            ? DateTime.parse(json['lastReviewedAt'] as String)
            : null,
        nextReviewAt: json['nextReviewAt'] != null
            ? DateTime.parse(json['nextReviewAt'] as String)
            : DateTime.now(),
        leitnerBox: json['leitnerBox'] as int? ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'term': term,
        'definition': definition,
        'sourceDocumentPath': sourceDocumentPath,
        'pageIndex': pageIndex,
        'isBlurred': isBlurred,
        'reviewCount': reviewCount,
        'successCount': successCount,
        'lastReviewedAt': lastReviewedAt?.toIso8601String(),
        'nextReviewAt': nextReviewAt.toIso8601String(),
        'leitnerBox': leitnerBox,
      };
}

class StudyDeck {
  final String id;
  final String name;
  final String documentPath;
  final List<RecallItem> cards;
  final DateTime createdAt;

  StudyDeck({
    required this.id,
    required this.name,
    required this.documentPath,
    required this.cards,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory StudyDeck.fromJson(Map<String, dynamic> json) => StudyDeck(
        id: json['id'] as String,
        name: json['name'] as String,
        documentPath: json['documentPath'] as String? ?? '',
        cards: (json['cards'] as List? ?? [])
            .map((c) => RecallItem.fromJson(Map<String, dynamic>.from(c)))
            .toList(),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'documentPath': documentPath,
        'cards': cards.map((c) => c.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };
}

class PomodoroSession {
  final int focusDurationMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  int completedSessions;
  int totalTimeSpentSeconds;

  PomodoroSession({
    this.focusDurationMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.completedSessions = 0,
    this.totalTimeSpentSeconds = 0,
  });

  factory PomodoroSession.fromJson(Map<String, dynamic> json) => PomodoroSession(
        focusDurationMinutes: json['focusDurationMinutes'] as int? ?? 25,
        shortBreakMinutes: json['shortBreakMinutes'] as int? ?? 5,
        longBreakMinutes: json['longBreakMinutes'] as int? ?? 15,
        completedSessions: json['completedSessions'] as int? ?? 0,
        totalTimeSpentSeconds: json['totalTimeSpentSeconds'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'focusDurationMinutes': focusDurationMinutes,
        'shortBreakMinutes': shortBreakMinutes,
        'longBreakMinutes': longBreakMinutes,
        'completedSessions': completedSessions,
        'totalTimeSpentSeconds': totalTimeSpentSeconds,
      };
}
