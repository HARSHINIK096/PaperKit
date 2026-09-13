import 'qr_parsed_payload.dart';

class QrScanHistoryItem {
  final String id;
  final DateTime timestamp;
  final QrPayloadType type;
  final String rawData;
  final String title;
  final String? subtitle;

  const QrScanHistoryItem({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.rawData,
    required this.title,
    this.subtitle,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'rawData': rawData,
    'title': title,
    'subtitle': subtitle,
  };

  factory QrScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return QrScanHistoryItem(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: QrPayloadType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => QrPayloadType.unknown,
      ),
      rawData: json['rawData'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
    );
  }
}
