class PageAnchorNote {
  final String id;
  final String documentPath;
  final int pageIndex;
  final String title;
  final String content;
  final DateTime createdAt;

  PageAnchorNote({
    required this.id,
    required this.documentPath,
    required this.pageIndex,
    required this.title,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory PageAnchorNote.fromJson(Map<String, dynamic> json) => PageAnchorNote(
        id: json['id'] as String,
        documentPath: json['documentPath'] as String? ?? '',
        pageIndex: json['pageIndex'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'documentPath': documentPath,
        'pageIndex': pageIndex,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };
}

class SyllabusTopic {
  final String id;
  final String title;
  bool isCompleted;
  final List<String> associatedDocumentPaths;

  SyllabusTopic({
    required this.id,
    required this.title,
    this.isCompleted = false,
    List<String>? associatedDocumentPaths,
  }) : associatedDocumentPaths = associatedDocumentPaths ?? [];

  factory SyllabusTopic.fromJson(Map<String, dynamic> json) => SyllabusTopic(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        isCompleted: json['isCompleted'] as bool? ?? false,
        associatedDocumentPaths:
            (json['associatedDocumentPaths'] as List? ?? []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'associatedDocumentPaths': associatedDocumentPaths,
      };
}

class SyllabusCourse {
  final String id;
  final String courseName;
  final String courseCode;
  final List<SyllabusTopic> topics;

  SyllabusCourse({
    required this.id,
    required this.courseName,
    required this.courseCode,
    required this.topics,
  });

  double get progressPercentage {
    if (topics.isEmpty) return 0.0;
    final completed = topics.where((t) => t.isCompleted).length;
    return completed / topics.length;
  }

  factory SyllabusCourse.fromJson(Map<String, dynamic> json) => SyllabusCourse(
        id: json['id'] as String,
        courseName: json['courseName'] as String? ?? '',
        courseCode: json['courseCode'] as String? ?? '',
        topics: (json['topics'] as List? ?? [])
            .map((t) => SyllabusTopic.fromJson(Map<String, dynamic>.from(t)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseName': courseName,
        'courseCode': courseCode,
        'topics': topics.map((t) => t.toJson()).toList(),
      };
}
