class AuditEvent {
  final String id;
  final DateTime timestamp;
  final String eventType; // e.g. 'imported', 'modified', 'exported', 'signed', 'viewed'
  final String documentId;
  final String documentName;
  final String contentHash;
  final String previousHash;
  final String actorId;
  final Map<String, dynamic> metadata;

  AuditEvent({
    required this.id,
    DateTime? timestamp,
    required this.eventType,
    required this.documentId,
    required this.documentName,
    required this.contentHash,
    required this.previousHash,
    required this.actorId,
    Map<String, dynamic>? metadata,
  })  : timestamp = timestamp ?? DateTime.now(),
        metadata = metadata ?? {};

  factory AuditEvent.fromJson(Map<String, dynamic> json) => AuditEvent(
        id: json['id'] as String,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
        eventType: json['eventType'] as String? ?? 'unknown',
        documentId: json['documentId'] as String? ?? '',
        documentName: json['documentName'] as String? ?? '',
        contentHash: json['contentHash'] as String? ?? '',
        previousHash: json['previousHash'] as String? ?? '',
        actorId: json['actorId'] as String? ?? '',
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'eventType': eventType,
        'documentId': documentId,
        'documentName': documentName,
        'contentHash': contentHash,
        'previousHash': previousHash,
        'actorId': actorId,
        'metadata': metadata,
      };
}

class ContractClause {
  final String category; // e.g. Party, Obligation, Termination, Liability, SLA
  final String title;
  final String snippet;
  final int pageNumber;
  final String confidence; // detected, inferred

  ContractClause({
    required this.category,
    required this.title,
    required this.snippet,
    required this.pageNumber,
    this.confidence = 'detected',
  });

  factory ContractClause.fromJson(Map<String, dynamic> json) => ContractClause(
        category: json['category'] as String? ?? 'General',
        title: json['title'] as String? ?? '',
        snippet: json['snippet'] as String? ?? '',
        pageNumber: json['pageNumber'] as int? ?? 1,
        confidence: json['confidence'] as String? ?? 'detected',
      );

  Map<String, dynamic> toJson() => {
        'category': category,
        'title': title,
        'snippet': snippet,
        'pageNumber': pageNumber,
        'confidence': confidence,
      };
}

class BatesConfig {
  final String prefix;
  final int startNumber;
  final int digitPadding;
  final String position; // top-left, top-right, bottom-left, bottom-right
  final double fontSize;
  final int textColorHex;

  const BatesConfig({
    this.prefix = 'EXHIBIT-',
    this.startNumber = 1,
    this.digitPadding = 6,
    this.position = 'bottom-right',
    this.fontSize = 10.0,
    this.textColorHex = 0xFF000000,
  });

  String formatNumber(int index) {
    final numStr = (startNumber + index).toString().padLeft(digitPadding, '0');
    return '$prefix$numStr';
  }

  factory BatesConfig.fromJson(Map<String, dynamic> json) => BatesConfig(
        prefix: json['prefix'] as String? ?? 'EXHIBIT-',
        startNumber: json['startNumber'] as int? ?? 1,
        digitPadding: json['digitPadding'] as int? ?? 6,
        position: json['position'] as String? ?? 'bottom-right',
        fontSize: (json['fontSize'] as num? ?? 10.0).toDouble(),
        textColorHex: json['textColorHex'] as int? ?? 0xFF000000,
      );

  Map<String, dynamic> toJson() => {
        'prefix': prefix,
        'startNumber': startNumber,
        'digitPadding': digitPadding,
        'position': position,
        'fontSize': fontSize,
        'textColorHex': textColorHex,
      };
}

class ExhibitIndexItem {
  final String exhibitId;
  final String documentName;
  final String batesRange;
  final int pageCount;
  final String description;

  ExhibitIndexItem({
    required this.exhibitId,
    required this.documentName,
    required this.batesRange,
    required this.pageCount,
    required this.description,
  });

  factory ExhibitIndexItem.fromJson(Map<String, dynamic> json) => ExhibitIndexItem(
        exhibitId: json['exhibitId'] as String? ?? '',
        documentName: json['documentName'] as String? ?? '',
        batesRange: json['batesRange'] as String? ?? '',
        pageCount: json['pageCount'] as int? ?? 0,
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'exhibitId': exhibitId,
        'documentName': documentName,
        'batesRange': batesRange,
        'pageCount': pageCount,
        'description': description,
      };
}
