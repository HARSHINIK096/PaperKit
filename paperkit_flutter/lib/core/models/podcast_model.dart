class DialogueLine {
  final String speaker; // e.g. "Alex (Host)", "Dr. Sam (Expert)"
  final String text;
  final String timestamp;

  DialogueLine({
    required this.speaker,
    required this.text,
    this.timestamp = '00:00',
  });

  factory DialogueLine.fromJson(Map<String, dynamic> json) => DialogueLine(
        speaker: json['speaker'] as String? ?? 'Host',
        text: json['text'] as String? ?? '',
        timestamp: json['timestamp'] as String? ?? '00:00',
      );

  Map<String, dynamic> toJson() => {
        'speaker': speaker,
        'text': text,
        'timestamp': timestamp,
      };
}

class PodcastScript {
  final String title;
  final String summary;
  final List<DialogueLine> dialogue;
  final String documentPath;
  final int totalWords;

  PodcastScript({
    required this.title,
    required this.summary,
    required this.dialogue,
    this.documentPath = '',
    required this.totalWords,
  });

  factory PodcastScript.fromJson(Map<String, dynamic> json) => PodcastScript(
        title: json['title'] as String? ?? 'Untitled Podcast',
        summary: json['summary'] as String? ?? '',
        dialogue: (json['dialogue'] as List? ?? [])
            .map((d) => DialogueLine.fromJson(Map<String, dynamic>.from(d)))
            .toList(),
        documentPath: json['documentPath'] as String? ?? '',
        totalWords: json['totalWords'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'summary': summary,
        'dialogue': dialogue.map((d) => d.toJson()).toList(),
        'documentPath': documentPath,
        'totalWords': totalWords,
      };
}

class VoiceAnnotation {
  final String id;
  final String documentPath;
  final int pageIndex;
  final String audioFilePath;
  final Duration duration;
  final DateTime createdAt;
  final String noteText;

  VoiceAnnotation({
    required this.id,
    required this.documentPath,
    required this.pageIndex,
    required this.audioFilePath,
    required this.duration,
    DateTime? createdAt,
    this.noteText = '',
  }) : createdAt = createdAt ?? DateTime.now();

  factory VoiceAnnotation.fromJson(Map<String, dynamic> json) => VoiceAnnotation(
        id: json['id'] as String,
        documentPath: json['documentPath'] as String? ?? '',
        pageIndex: json['pageIndex'] as int? ?? 0,
        audioFilePath: json['audioFilePath'] as String? ?? '',
        duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        noteText: json['noteText'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'documentPath': documentPath,
        'pageIndex': pageIndex,
        'audioFilePath': audioFilePath,
        'durationMs': duration.inMilliseconds,
        'createdAt': createdAt.toIso8601String(),
        'noteText': noteText,
      };
}
