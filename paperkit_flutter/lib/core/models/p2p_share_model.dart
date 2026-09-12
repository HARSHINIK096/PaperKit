enum AirShareSessionState {
  idle,
  creatingSession,
  qrReady,
  waitingForScan,
  deviceDetected,
  authenticating,
  connected,
  transferring,
  verifying,
  completed,
  failed,
}

class PeerDevice {
  final String id;
  final String deviceName;
  final String ipAddress;
  final int port;
  final DateTime lastSeen;

  PeerDevice({
    required this.id,
    required this.deviceName,
    required this.ipAddress,
    this.port = 8080,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  factory PeerDevice.fromJson(Map<String, dynamic> json) => PeerDevice(
        id: json['id'] as String,
        deviceName: json['deviceName'] as String? ?? 'Peer Device',
        ipAddress: json['ipAddress'] as String? ?? '127.0.0.1',
        port: json['port'] as int? ?? 8080,
        lastSeen: json['lastSeen'] != null
            ? DateTime.parse(json['lastSeen'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceName': deviceName,
        'ipAddress': ipAddress,
        'port': port,
        'lastSeen': lastSeen.toIso8601String(),
      };
}

class QrSessionPayload {
  final String protocolVersion;
  final String sessionId;
  final String hostIp;
  final int port;
  final String secretToken;
  final String documentName;
  final DateTime expiresAt;

  QrSessionPayload({
    this.protocolVersion = '1.0',
    required this.sessionId,
    required this.hostIp,
    required this.port,
    required this.secretToken,
    required this.documentName,
    DateTime? expiresAt,
  }) : expiresAt = expiresAt ?? DateTime.now().add(const Duration(minutes: 10));

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory QrSessionPayload.fromJson(Map<String, dynamic> json) => QrSessionPayload(
        protocolVersion: json['protocolVersion'] as String? ?? '1.0',
        sessionId: json['sessionId'] as String? ?? '',
        hostIp: json['hostIp'] as String? ?? '',
        port: json['port'] as int? ?? 8080,
        secretToken: json['secretToken'] as String? ?? '',
        documentName: json['documentName'] as String? ?? '',
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : DateTime.now().add(const Duration(minutes: 10)),
      );

  Map<String, dynamic> toJson() => {
        'protocolVersion': protocolVersion,
        'sessionId': sessionId,
        'hostIp': hostIp,
        'port': port,
        'secretToken': secretToken,
        'documentName': documentName,
        'expiresAt': expiresAt.toIso8601String(),
      };

  String toEncodedUrl() {
    return 'paperkit://airshare?session=$sessionId&ip=$hostIp&port=$port&token=$secretToken&name=$documentName&exp=${expiresAt.millisecondsSinceEpoch}';
  }
}

class CoReviewEvent {
  final String senderId;
  final int currentPage;
  final double pointerX;
  final double pointerY;
  final String annotationText;

  CoReviewEvent({
    required this.senderId,
    required this.currentPage,
    this.pointerX = 0.5,
    this.pointerY = 0.5,
    this.annotationText = '',
  });

  factory CoReviewEvent.fromJson(Map<String, dynamic> json) => CoReviewEvent(
        senderId: json['senderId'] as String? ?? 'peer',
        currentPage: json['currentPage'] as int? ?? 0,
        pointerX: (json['pointerX'] as num? ?? 0.5).toDouble(),
        pointerY: (json['pointerY'] as num? ?? 0.5).toDouble(),
        annotationText: json['annotationText'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'currentPage': currentPage,
        'pointerX': pointerX,
        'pointerY': pointerY,
        'annotationText': annotationText,
      };
}

class PaperKitProjectBundleManifest {
  final String version;
  final String projectName;
  final String createdBy;
  final DateTime createdAt;
  final List<String> pdfFiles;
  final List<String> noteFiles;
  final List<String> flashcardsFiles;
  final List<String> mindMapFiles;
  final String checksumSha256;

  PaperKitProjectBundleManifest({
    this.version = '1.0.0',
    required this.projectName,
    required this.createdBy,
    DateTime? createdAt,
    required this.pdfFiles,
    required this.noteFiles,
    required this.flashcardsFiles,
    required this.mindMapFiles,
    required this.checksumSha256,
  }) : createdAt = createdAt ?? DateTime.now();

  factory PaperKitProjectBundleManifest.fromJson(Map<String, dynamic> json) =>
      PaperKitProjectBundleManifest(
        version: json['version'] as String? ?? '1.0.0',
        projectName: json['projectName'] as String? ?? 'PaperKit Project',
        createdBy: json['createdBy'] as String? ?? 'Anonymous',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        pdfFiles: (json['pdfFiles'] as List? ?? []).cast<String>(),
        noteFiles: (json['noteFiles'] as List? ?? []).cast<String>(),
        flashcardsFiles: (json['flashcardsFiles'] as List? ?? []).cast<String>(),
        mindMapFiles: (json['mindMapFiles'] as List? ?? []).cast<String>(),
        checksumSha256: json['checksumSha256'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'projectName': projectName,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'pdfFiles': pdfFiles,
        'noteFiles': noteFiles,
        'flashcardsFiles': flashcardsFiles,
        'mindMapFiles': mindMapFiles,
        'checksumSha256': checksumSha256,
      };
}
