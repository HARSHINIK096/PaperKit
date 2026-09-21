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
  final String deviceType; // 'phone', 'tablet', 'laptop', 'desktop'
  final double distanceMeters;
  final double signalStrength; // 0.0 to 1.0
  final double angleRadians; // 0 to 2*PI for radar positioning
  final String deviceModel;
  final bool isAvailable;

  PeerDevice({
    required this.id,
    required this.deviceName,
    required this.ipAddress,
    this.port = 8080,
    DateTime? lastSeen,
    this.deviceType = 'phone',
    this.distanceMeters = 2.5,
    this.signalStrength = 0.85,
    this.angleRadians = 0.0,
    this.deviceModel = 'Android Device',
    this.isAvailable = true,
  }) : lastSeen = lastSeen ?? DateTime.now();

  String get distanceLabel {
    if (distanceMeters < 2.0) {
      return '${distanceMeters.toStringAsFixed(1)}m (Immediate)';
    } else if (distanceMeters < 5.0) {
      return '${distanceMeters.toStringAsFixed(1)}m (Same Room)';
    } else if (distanceMeters < 10.0) {
      return '${distanceMeters.toStringAsFixed(1)}m (Nearby)';
    } else {
      return '${distanceMeters.toStringAsFixed(1)}m (Area)';
    }
  }

  factory PeerDevice.fromJson(Map<String, dynamic> json) => PeerDevice(
        id: json['id'] as String,
        deviceName: json['deviceName'] as String? ?? 'Peer Device',
        ipAddress: json['ipAddress'] as String? ?? '',
        port: json['port'] as int? ?? 8080,
        lastSeen: json['lastSeen'] != null
            ? DateTime.parse(json['lastSeen'] as String)
            : DateTime.now(),
        deviceType: json['deviceType'] as String? ?? 'phone',
        distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 2.5,
        signalStrength: (json['signalStrength'] as num?)?.toDouble() ?? 0.85,
        angleRadians: (json['angleRadians'] as num?)?.toDouble() ?? 0.0,
        deviceModel: json['deviceModel'] as String? ?? 'Android Device',
        isAvailable: json['isAvailable'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceName': deviceName,
        'ipAddress': ipAddress,
        'port': port,
        'lastSeen': lastSeen.toIso8601String(),
        'deviceType': deviceType,
        'distanceMeters': distanceMeters,
        'signalStrength': signalStrength,
        'angleRadians': angleRadians,
        'deviceModel': deviceModel,
        'isAvailable': isAvailable,
      };
}

class DirectTransferInvite {
  final String senderDeviceId;
  final String senderDeviceName;
  final String senderIp;
  final int senderPort;
  final String sessionToken;
  final String documentName;
  final int fileSize;
  final String sha256;
  final String passkey;

  DirectTransferInvite({
    required this.senderDeviceId,
    required this.senderDeviceName,
    required this.senderIp,
    required this.senderPort,
    required this.sessionToken,
    required this.documentName,
    required this.fileSize,
    required this.sha256,
    this.passkey = '8492',
  });

  factory DirectTransferInvite.fromJson(Map<String, dynamic> json) => DirectTransferInvite(
        senderDeviceId: json['senderDeviceId'] as String? ?? 'unknown',
        senderDeviceName: json['senderDeviceName'] as String? ?? 'Nearby Peer',
        senderIp: json['senderIp'] as String? ?? '',
        senderPort: json['senderPort'] as int? ?? 8080,
        sessionToken: json['sessionToken'] as String? ?? '',
        documentName: json['documentName'] as String? ?? 'document.pdf',
        fileSize: json['fileSize'] as int? ?? 0,
        sha256: json['sha256'] as String? ?? '',
        passkey: json['passkey'] as String? ?? '8492',
      );

  Map<String, dynamic> toJson() => {
        'senderDeviceId': senderDeviceId,
        'senderDeviceName': senderDeviceName,
        'senderIp': senderIp,
        'senderPort': senderPort,
        'sessionToken': sessionToken,
        'documentName': documentName,
        'fileSize': fileSize,
        'sha256': sha256,
        'passkey': passkey,
      };

  QrSessionPayload toQrSessionPayload() {
    return QrSessionPayload(
      sessionId: 'p2p_${DateTime.now().millisecondsSinceEpoch}',
      hostIp: senderIp,
      port: senderPort,
      secretToken: sessionToken,
      documentName: documentName,
      passkey: passkey,
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );
  }
}


class QrSessionPayload {
  final String protocolVersion;
  final String sessionId;
  final String hostIp;
  final int port;
  final String secretToken;
  final String documentName;
  final String passkey;
  final DateTime expiresAt;

  QrSessionPayload({
    this.protocolVersion = '1.0',
    required this.sessionId,
    required this.hostIp,
    required this.port,
    required this.secretToken,
    required this.documentName,
    this.passkey = '8492',
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
        passkey: json['passkey'] as String? ?? '8492',
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
        'passkey': passkey,
        'expiresAt': expiresAt.toIso8601String(),
      };

  String toEncodedUrl() {
    return 'maskerv://airshare?session=$sessionId&ip=$hostIp&port=$port&token=$secretToken&name=$documentName&pin=$passkey&exp=${expiresAt.millisecondsSinceEpoch}';
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

  double? get laserX => pointerX > 0 ? pointerX : null;
  double? get laserY => pointerY > 0 ? pointerY : null;

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

class MaskerVProjectBundleManifest {
  final String version;
  final String projectName;
  final String createdBy;
  final DateTime createdAt;
  final List<String> pdfFiles;
  final List<String> noteFiles;
  final List<String> flashcardsFiles;
  final List<String> mindMapFiles;
  final String checksumSha256;

  MaskerVProjectBundleManifest({
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

  factory MaskerVProjectBundleManifest.fromJson(Map<String, dynamic> json) =>
      MaskerVProjectBundleManifest(
        version: json['version'] as String? ?? '1.0.0',
        projectName: json['projectName'] as String? ?? 'MaskerV Project',
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

/// Backward compatibility alias
typedef PaperKitProjectBundleManifest = MaskerVProjectBundleManifest;
