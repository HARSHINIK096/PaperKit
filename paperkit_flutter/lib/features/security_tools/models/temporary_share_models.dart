class TemporaryShareCreationResult {
  final bool success;
  final String shareId;
  final String shareUrl;
  final String accessUrl;
  final String filename;
  final int fileSize;
  final String contentType;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int expiresInSeconds;

  const TemporaryShareCreationResult({
    required this.success,
    required this.shareId,
    required this.shareUrl,
    required this.accessUrl,
    required this.filename,
    required this.fileSize,
    required this.contentType,
    required this.createdAt,
    required this.expiresAt,
    required this.expiresInSeconds,
  });

  factory TemporaryShareCreationResult.fromJson(Map<String, dynamic> json) {
    return TemporaryShareCreationResult(
      success: json['success'] as bool? ?? false,
      shareId: json['share_id'] as String? ?? '',
      shareUrl: json['share_url'] as String? ?? '',
      accessUrl: json['access_url'] as String? ?? '',
      filename: json['original_filename'] as String? ?? 'file',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      contentType: json['content_type'] as String? ?? 'application/octet-stream',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : DateTime.now().add(const Duration(minutes: 10)),
      expiresInSeconds: (json['expires_in_seconds'] as num?)?.toInt() ?? 600,
    );
  }
}

class TemporaryShareMetadata {
  final String shareId;
  final String filename;
  final int fileSize;
  final String contentType;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int remainingSeconds;
  final String status;
  final bool requiresPassword;

  const TemporaryShareMetadata({
    required this.shareId,
    required this.filename,
    required this.fileSize,
    required this.contentType,
    required this.createdAt,
    required this.expiresAt,
    required this.remainingSeconds,
    required this.status,
    required this.requiresPassword,
  });

  factory TemporaryShareMetadata.fromJson(Map<String, dynamic> json) {
    return TemporaryShareMetadata(
      shareId: json['share_id'] as String? ?? '',
      filename: json['original_filename'] as String? ?? 'Shared File',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      contentType: json['content_type'] as String? ?? 'application/octet-stream',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : DateTime.now(),
      remainingSeconds: (json['remaining_seconds'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'active',
      requiresPassword: json['requires_password'] as bool? ?? true,
    );
  }

  bool get isExpired => remainingSeconds <= 0 || status != 'active';

  String get fileSizeFormatted {
    if (fileSize >= 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(fileSize / 1024).toStringAsFixed(1)} KB';
  }
}
