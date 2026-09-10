class HistoryItem {
  final String id;
  final String toolId;
  final String toolName;
  final String fileName;
  final String? outputPath;
  final int fileSize;
  final DateTime timestamp;
  final bool success;
  final String? details;

  HistoryItem({
    required this.id,
    required this.toolId,
    required this.toolName,
    required this.fileName,
    this.outputPath,
    required this.fileSize,
    required this.timestamp,
    this.success = true,
    this.details,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'toolId': toolId,
    'toolName': toolName,
    'fileName': fileName,
    'outputPath': outputPath,
    'fileSize': fileSize,
    'timestamp': timestamp.toIso8601String(),
    'success': success,
    'details': details,
  };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
    id: json['id'],
    toolId: json['toolId'],
    toolName: json['toolName'],
    fileName: json['fileName'],
    outputPath: json['outputPath'],
    fileSize: json['fileSize'],
    timestamp: DateTime.parse(json['timestamp']),
    success: json['success'] ?? true,
    details: json['details'],
  );
}
