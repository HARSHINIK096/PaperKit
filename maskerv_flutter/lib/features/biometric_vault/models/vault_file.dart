import 'dart:convert';

/// Metadata record for a file stored in the Biometric Vault.
/// Contains ONLY non-sensitive metadata — never file contents or encryption keys.
class VaultFile {
  final String id;
  final String originalName;
  final String encryptedFileName;
  final String mimeType;
  final int sizeBytes;
  final DateTime createdAt;

  const VaultFile({
    required this.id,
    required this.originalName,
    required this.encryptedFileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalName': originalName,
        'encryptedFileName': encryptedFileName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory VaultFile.fromJson(Map<String, dynamic> json) => VaultFile(
        id: json['id'] as String,
        originalName: json['originalName'] as String,
        encryptedFileName: json['encryptedFileName'] as String,
        mimeType: json['mimeType'] as String,
        sizeBytes: json['sizeBytes'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  static List<VaultFile> listFromJson(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list.map((e) => VaultFile.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<VaultFile> files) {
    return jsonEncode(files.map((e) => e.toJson()).toList());
  }

  /// Human-readable file extension derived from original name.
  String get extension {
    final parts = originalName.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : 'FILE';
  }

  /// Human-readable file size string.
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
