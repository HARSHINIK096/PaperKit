import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/models/document_file.dart';
import '../../core/models/p2p_share_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';

class P2PMeshService {
  final StorageService _storage = StorageService();

  HttpServer? _hostServer;
  HttpServer? _discoveryServer;
  QrSessionPayload? _currentHostSession;
  File? _currentSharingFile;
  AirShareSessionState _sessionState = AirShareSessionState.idle;

  final StreamController<DirectTransferInvite> _inviteController =
      StreamController<DirectTransferInvite>.broadcast();

  CoReviewEvent _latestCoReviewEvent = CoReviewEvent(
    senderId: 'host',
    currentPage: 0,
  );

  AirShareSessionState get sessionState => _sessionState;
  QrSessionPayload? get currentHostSession => _currentHostSession;
  CoReviewEvent get latestCoReviewEvent => _latestCoReviewEvent;
  Stream<DirectTransferInvite> get onIncomingInvite => _inviteController.stream;

  // Compute SHA-256 Checksum
  Future<String> _computeSha256(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  RawDatagramSocket? _udpBeaconSocket;
  Timer? _udpBroadcastTimer;
  final Map<String, PeerDevice> _udpDiscoveredDevices = {};

  // Get local network IPv4 address prioritizing Wi-Fi & Hotspot LAN subnets while excluding virtual interfaces
  Future<List<String>> getAllLocalIpAddresses() async {
    final ips = <String>[];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        if (_isVirtualInterface(interface)) continue;
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.address != '127.0.0.1') {
            ips.add(addr.address);
          }
        }
      }
    } catch (_) {}

    ips.sort((a, b) {
      final scoreA = _getIpPriorityScore(a);
      final scoreB = _getIpPriorityScore(b);
      return scoreB.compareTo(scoreA);
    });

    return ips;
  }

  bool _isVirtualInterface(NetworkInterface interface) {
    final name = interface.name.toLowerCase();
    return name.contains('wsl') ||
        name.contains('veth') ||
        name.contains('docker') ||
        name.contains('virtual') ||
        name.contains('vmnet') ||
        name.contains('hyper-v') ||
        name.contains('box') ||
        name.contains('tunnel') ||
        name.contains('tap') ||
        name.contains('tun') ||
        name.contains('ppp') ||
        name.contains('vethernet');
  }

  int _getIpPriorityScore(String ip) {
    if (ip.startsWith('192.168.43.') || ip.startsWith('192.168.178.')) return 120; // Mobile Hotspot
    if (ip.startsWith('172.20.10.')) return 120; // iOS Personal Hotspot
    if (ip.startsWith('192.168.')) return 100; // Standard Wi-Fi
    if (ip.startsWith('10.0.0.')) return 90;

    if (ip.startsWith('172.')) {
      final parts = ip.split('.');
      if (parts.length > 1) {
        final second = int.tryParse(parts[1]) ?? 0;
        // Low score for virtual adapters in 172.16.0.0 - 172.31.255.255
        if (second >= 16 && second <= 31) return 20;
      }
    }
    if (ip.startsWith('10.')) return 40;
    return 10;
  }

  Future<String> _getLocalIpAddress() async {
    final ips = await getAllLocalIpAddresses();
    return ips.isNotEmpty ? ips.first : '';
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 1 & 3: HOST SESSION CREATION & LOCAL SERVER
  // ───────────────────────────────────────────────────────────────────────────

  Future<QrSessionPayload> startHostSession({
    required File file,
  }) async {
    await stopHostSession();

    _sessionState = AirShareSessionState.creatingSession;
    _currentSharingFile = file;

    final localIp = await _getLocalIpAddress();
    final backendUrl = ApiService().baseUrl.replaceAll(RegExp(r'/+$'), '');

    final rnd = Random.secure();
    final secretToken = List.generate(16, (_) => rnd.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final sessionId = 'pk_session_${DateTime.now().millisecondsSinceEpoch}';

    // Bind local socket HTTP server with fallback port binding & shared socket
    HttpServer? server;
    int boundPort = 8080;
    for (int p = 8080; p <= 8088; p++) {
      try {
        server = await HttpServer.bind(InternetAddress.anyIPv4, p, shared: true);
        boundPort = p;
        break;
      } catch (_) {}
    }

    if (server == null) {
      _sessionState = AirShareSessionState.idle;
      throw Exception('Failed to bind P2P host socket server.');
    }
    _hostServer = server;

    final passkey = (1000 + Random().nextInt(9000)).toString();
    final hostIpAddress = localIp.isNotEmpty ? localIp : (Uri.tryParse(backendUrl)?.host ?? 'backend.maskerv');

    _currentHostSession = QrSessionPayload(
      protocolVersion: '1.0',
      sessionId: sessionId,
      hostIp: hostIpAddress,
      port: boundPort,
      secretToken: secretToken,
      documentName: file.uri.pathSegments.last,
      passkey: passkey,
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );

    // Register session to Backend URL pairing server
    try {
      final dio = Dio();
      await dio.post(
        '$backendUrl/p2p/session/create',
        data: {
          'sessionId': sessionId,
          'hostIp': hostIpAddress,
          'port': boundPort,
          'secretToken': secretToken,
          'documentName': file.uri.pathSegments.last,
          'passkey': passkey,
        },
        options: Options(receiveTimeout: const Duration(seconds: 4)),
      );
    } catch (_) {}

    _sessionState = AirShareSessionState.qrReady;

    // Handle Incoming P2P Requests
    _hostServer!.listen((HttpRequest request) async {
      final token = request.headers.value('X-MaskerV-Session-Token') ??
          request.headers.value('X-PaperKit-Session-Token');

      if (_currentHostSession == null || _currentHostSession!.isExpired) {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..write(jsonEncode({'error': 'Session expired or closed'}))
          ..close();
        return;
      }

      if (token != _currentHostSession!.secretToken &&
          request.uri.path != '/health' &&
          request.uri.path != '/p2p/invite' &&
          request.uri.path != '/p2p/ping') {
        request.response
          ..statusCode = HttpStatus.unauthorized
          ..write(jsonEncode({'error': 'Invalid session token'}))
          ..close();
        return;
      }

      if (request.uri.path == '/session/info') {
        _sessionState = AirShareSessionState.deviceDetected;
        final fileHash = await _computeSha256(_currentSharingFile!);
        final fileSize = await _currentSharingFile!.length();

        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'sessionId': _currentHostSession!.sessionId,
            'fileName': _currentHostSession!.documentName,
            'fileSize': fileSize,
            'sha256': fileHash,
            'status': 'ready',
          }))
          ..close();
        _sessionState = AirShareSessionState.connected;
      } else if (request.uri.path == '/transfer/download') {
        _sessionState = AirShareSessionState.transferring;
        final bytes = await _currentSharingFile!.readAsBytes();
        final fileHash = sha256.convert(bytes).toString();

        request.response.headers.contentType = ContentType.binary;
        request.response.headers.set('X-MaskerV-SHA256', fileHash);
        request.response.headers.set('X-PaperKit-SHA256', fileHash);
        request.response.headers.set('Content-Length', bytes.length.toString());
        request.response.add(bytes);
        await request.response.close();
        _sessionState = AirShareSessionState.completed;
      } else if (request.uri.path == '/co-review/sync') {
        if (request.method == 'POST') {
          final bodyStr = await utf8.decoder.bind(request).join();
          final jsonMap = jsonDecode(bodyStr) as Map<String, dynamic>;
          _latestCoReviewEvent = CoReviewEvent.fromJson(jsonMap);
          request.response
            ..statusCode = HttpStatus.ok
            ..write(jsonEncode({'status': 'synced'}))
            ..close();
        } else {
          request.response
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(_latestCoReviewEvent.toJson()))
            ..close();
        }
      } else if (request.uri.path == '/p2p/invite' && request.method == 'POST') {
        try {
          final bodyStr = await utf8.decoder.bind(request).join();
          final jsonMap = jsonDecode(bodyStr) as Map<String, dynamic>;
          final invite = DirectTransferInvite.fromJson(jsonMap);

          final localIps = await getAllLocalIpAddresses();
          if (localIps.contains(invite.senderIp)) {
            request.response
              ..statusCode = HttpStatus.ok
              ..write(jsonEncode({'status': 'ignored_self'}))
              ..close();
            return;
          }

          _inviteController.add(invite);
          request.response
            ..statusCode = HttpStatus.ok
            ..write(jsonEncode({'status': 'received', 'message': 'Invitation accepted'}))
            ..close();
        } catch (_) {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..close();
        }
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
      }
    });

    return _currentHostSession!;
  }

  Future<void> stopHostSession() async {
    if (_hostServer != null) {
      await _hostServer!.close(force: true);
      _hostServer = null;
    }
    _currentHostSession = null;
    _currentSharingFile = null;
    _sessionState = AirShareSessionState.idle;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // NEARBY RADIUS DISCOVERY & DIRECT BEACON LISTENER
  // ───────────────────────────────────────────────────────────────────────────

  Future<int> startDiscoveryBeaconListener({String deviceName = 'MaskerV Device'}) async {
    await stopDiscoveryBeaconListener();

    // 1. Bind HTTP Discovery Server on port 8089 with socket sharing
    try {
      _discoveryServer = await HttpServer.bind(InternetAddress.anyIPv4, 8089, shared: true);
      _discoveryServer!.listen((HttpRequest request) async {
        if (request.uri.path == '/p2p/invite' && request.method == 'POST') {
          try {
            final bodyStr = await utf8.decoder.bind(request).join();
            final jsonMap = jsonDecode(bodyStr) as Map<String, dynamic>;
            final invite = DirectTransferInvite.fromJson(jsonMap);
            _inviteController.add(invite);
            request.response
              ..statusCode = HttpStatus.ok
              ..write(jsonEncode({'status': 'received'}))
              ..close();
          } catch (_) {
            request.response
              ..statusCode = HttpStatus.badRequest
              ..close();
          }
        } else if (request.uri.path == '/p2p/ping') {
          request.response
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'status': 'available',
              'deviceName': deviceName,
              'app': 'MaskerV',
              'version': '1.0.0',
            }))
            ..close();
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..close();
        }
      });
    } catch (_) {}

    // 2. Bind UDP Broadcast Socket & Timer for instant zero-latency peer discovery
    try {
      _udpBeaconSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        8089,
        reuseAddress: true,
        reusePort: true,
      );
      _udpBeaconSocket!.broadcastEnabled = true;

      _udpBeaconSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpBeaconSocket!.receive();
          if (datagram != null) {
            final raw = utf8.decode(datagram.data).trim();
            if (raw.startsWith('MASKERV_BEACON:')) {
              _handleIncomingUdpBeacon(raw.substring('MASKERV_BEACON:'.length), datagram.address.address);
            }
          }
        }
      });

      _udpBroadcastTimer?.cancel();
      _udpBroadcastTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _broadcastUdpBeacon(deviceName);
      });
      _broadcastUdpBeacon(deviceName);
    } catch (_) {}

    return _discoveryServer?.port ?? 8089;
  }

  void _handleIncomingUdpBeacon(String payloadJson, String senderIp) {
    try {
      final jsonMap = jsonDecode(payloadJson) as Map<String, dynamic>;
      final name = jsonMap['deviceName'] as String? ?? 'MaskerV Peer';
      final ip = jsonMap['ipAddress'] as String? ?? senderIp;

      if (ip.isNotEmpty && ip != '127.0.0.1') {
        _udpDiscoveredDevices[ip] = PeerDevice(
          id: 'peer_$ip',
          deviceName: name,
          deviceModel: 'MaskerV Device',
          deviceType: 'phone',
          ipAddress: ip,
          port: 8089,
          distanceMeters: 2.0,
          signalStrength: 0.95,
          angleRadians: (ip.hashCode.abs() % 360) * (pi / 180),
          isAvailable: true,
        );
      }
    } catch (_) {}
  }

  void _broadcastUdpBeacon(String deviceName) async {
    try {
      final localIp = await _getLocalIpAddress();
      if (localIp.isEmpty || _udpBeaconSocket == null) return;

      final payload = jsonEncode({
        'type': 'MASKERV_BEACON',
        'deviceName': deviceName,
        'ipAddress': localIp,
        'port': 8089,
        'app': 'MaskerV',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final data = utf8.encode('MASKERV_BEACON:$payload');

      _udpBeaconSocket?.send(data, InternetAddress('255.255.255.255'), 8089);

      if (localIp.contains('.')) {
        final baseSubnet = localIp.substring(0, localIp.lastIndexOf('.'));
        _udpBeaconSocket?.send(data, InternetAddress('$baseSubnet.255'), 8089);
      }
    } catch (_) {}
  }

  Future<void> stopDiscoveryBeaconListener() async {
    _udpBroadcastTimer?.cancel();
    _udpBroadcastTimer = null;
    if (_udpBeaconSocket != null) {
      _udpBeaconSocket!.close();
      _udpBeaconSocket = null;
    }
    if (_discoveryServer != null) {
      await _discoveryServer!.close(force: true);
      _discoveryServer = null;
    }
  }

  Future<List<PeerDevice>> scanNearbyDevices({
    double maxRadiusMeters = 20.0,
  }) async {
    final localIps = await getAllLocalIpAddresses();
    final backendUrl = ApiService().baseUrl.replaceAll(RegExp(r'/+$'), '');

    // Trigger immediate UDP broadcast probe
    _broadcastUdpBeacon('MaskerV Scanner');

    final Map<String, PeerDevice> foundDevices = Map.from(_udpDiscoveredDevices);

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(milliseconds: 500),
      receiveTimeout: const Duration(milliseconds: 500),
    ));

    // 1. Process ping via Backend URL (/p2p/ping)
    try {
      final resp = await dio.get<dynamic>('$backendUrl/p2p/ping');
      if (resp.statusCode == 200 && resp.data != null) {
        if (resp.data is Map<String, dynamic>) {
          final data = resp.data as Map<String, dynamic>;
          final peers = data['devices'] as List<dynamic>? ?? data['peers'] as List<dynamic>? ?? [];
          for (final p in peers) {
            if (p is Map<String, dynamic>) {
              final ip = p['ipAddress'] as String? ?? p['ip'] as String? ?? '';
              final name = p['deviceName'] as String? ?? p['name'] as String? ?? 'MaskerV Peer';
              if (ip.isNotEmpty && ip != '127.0.0.1') {
                foundDevices[ip] = PeerDevice(
                  id: 'peer_$ip',
                  deviceName: name,
                  deviceModel: 'MaskerV Device',
                  deviceType: 'phone',
                  ipAddress: ip,
                  port: int.tryParse(p['port']?.toString() ?? '8089') ?? 8089,
                  distanceMeters: 2.0,
                  signalStrength: 0.95,
                  angleRadians: (ip.hashCode.abs() % 360) * (pi / 180),
                  isAvailable: true,
                );
              }
            }
          }
          if (data['app'] == 'MaskerV' || data['status'] == 'available') {
            final name = data['deviceName'] as String? ?? 'MaskerV Peer';
            final hostUri = Uri.tryParse(backendUrl);
            final ip = hostUri?.host ?? 'backend_peer';
            foundDevices[ip] = PeerDevice(
              id: 'peer_$ip',
              deviceName: name,
              deviceModel: 'MaskerV Device',
              deviceType: 'phone',
              ipAddress: ip,
              port: hostUri?.port ?? 8089,
              distanceMeters: 1.5,
              signalStrength: 0.98,
              angleRadians: 0,
              isAvailable: true,
            );
          }
        }
      }
    } catch (_) {}

    // 2. Process target IP pings via Backend URL route
    if (localIps.isNotEmpty) {
      for (final localIp in localIps) {
        if (localIp.isEmpty || localIp == '127.0.0.1' || !localIp.contains('.')) continue;

        final baseSubnet = localIp.substring(0, localIp.lastIndexOf('.'));
        final myLastOctet = int.tryParse(localIp.substring(localIp.lastIndexOf('.') + 1)) ?? 0;

        final targets = <int>[];
        for (int i = 1; i <= 254; i++) {
          if (i != myLastOctet) targets.add(i);
        }

        const batchSize = 30;
        for (int i = 0; i < targets.length; i += batchSize) {
          final batch = targets.sublist(i, min(i + batchSize, targets.length));
          await Future.wait(
            batch.map((octet) async {
              final targetIp = '$baseSubnet.$octet';
              try {
                final resp = await dio.get<Map<String, dynamic>>(
                  '$backendUrl/p2p/ping',
                  queryParameters: {'target_ip': targetIp, 'local_ip': localIp},
                );
                if (resp.statusCode == 200 && resp.data != null) {
                  final data = resp.data!;
                  if (data['app'] == 'MaskerV' || data['app'] == 'PaperKit' || data['status'] == 'available') {
                    final name = data['deviceName'] as String? ?? 'MaskerV Peer';
                    foundDevices[targetIp] = PeerDevice(
                      id: 'peer_$targetIp',
                      deviceName: name,
                      deviceModel: 'MaskerV Device',
                      deviceType: 'phone',
                      ipAddress: targetIp,
                      port: 8089,
                      distanceMeters: 2.0,
                      signalStrength: 0.92,
                      angleRadians: (targetIp.hashCode.abs() % 360) * (pi / 180),
                      isAvailable: true,
                    );
                  }
                }
              } catch (_) {
                try {
                  final localResp = await dio.get<Map<String, dynamic>>('http://$targetIp:8089/p2p/ping');
                  if (localResp.statusCode == 200 && localResp.data != null) {
                    final data = localResp.data!;
                    if (data['app'] == 'MaskerV' || data['app'] == 'PaperKit') {
                      final name = data['deviceName'] as String? ?? 'MaskerV Peer';
                      foundDevices[targetIp] = PeerDevice(
                        id: 'peer_$targetIp',
                        deviceName: name,
                        deviceModel: 'MaskerV Device',
                        deviceType: 'phone',
                        ipAddress: targetIp,
                        port: 8089,
                        distanceMeters: 2.0,
                        signalStrength: 0.92,
                        angleRadians: (targetIp.hashCode.abs() % 360) * (pi / 180),
                        isAvailable: true,
                      );
                    }
                  }
                } catch (_) {}
              }
            }),
          );
        }
      }
    }

    return foundDevices.values
        .where((d) => d.distanceMeters <= maxRadiusMeters)
        .toList();
  }

  Future<bool> sendDirectTransferInvite({
    required PeerDevice target,
    required File file,
  }) async {
    final payload = await startHostSession(file: file);
    final fileHash = await _computeSha256(file);
    final fileSize = await file.length();
    final invite = DirectTransferInvite(
      senderDeviceId: 'pk_host_${payload.sessionId}',
      senderDeviceName: 'MaskerV AirShare',
      senderIp: payload.hostIp,
      senderPort: payload.port,
      sessionToken: payload.secretToken,
      documentName: payload.documentName,
      fileSize: fileSize,
      sha256: fileHash,
      passkey: payload.passkey,
    );

    final backendUrl = ApiService().baseUrl.replaceAll(RegExp(r'/+$'), '');

    // 1. Send invite through Backend URL signaling hub
    try {
      final dio = Dio();
      await dio.post(
        '$backendUrl/p2p/invite',
        data: invite.toJson(),
        options: Options(receiveTimeout: const Duration(seconds: 3)),
      );
    } catch (_) {}

    // 2. Direct send to target IP if available
    if (target.ipAddress.isNotEmpty && target.ipAddress != '127.0.0.1') {
      try {
        final dio = Dio();
        await dio.post(
          'http://${target.ipAddress}:${target.port}/p2p/invite',
          data: invite.toJson(),
          options: Options(receiveTimeout: const Duration(seconds: 3)),
        );
      } catch (_) {}
    }

    return true;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 2, 4 & 6: RECEIVER CLIENT & FILE VERIFICATION
  // ───────────────────────────────────────────────────────────────────────────

  // Validate QR Payload
  QrSessionPayload? parseAndValidateQrPayload(String rawQrContent) {
    try {
      if (rawQrContent.startsWith('maskerv://airshare') ||
          rawQrContent.startsWith('paperkit://airshare')) {
        final uri = Uri.parse(rawQrContent);
        final payload = QrSessionPayload(
          sessionId: uri.queryParameters['session'] ?? '',
          hostIp: uri.queryParameters['ip'] ?? '',
          port: int.tryParse(uri.queryParameters['port'] ?? '8080') ?? 8080,
          secretToken: uri.queryParameters['token'] ?? '',
          documentName: uri.queryParameters['name'] ?? '',
          passkey: uri.queryParameters['pin'] ?? uri.queryParameters['passkey'] ?? '8492',
          expiresAt: DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(uri.queryParameters['exp'] ?? '0') ?? 0,
          ),
        );
        if (!payload.isExpired) return payload;
      } else {
        final jsonMap = jsonDecode(rawQrContent) as Map<String, dynamic>;
        final payload = QrSessionPayload.fromJson(jsonMap);
        if (!payload.isExpired) return payload;
      }
    } catch (_) {}
    return null;
  }

  // Connect to Host & Fetch Shared File Info via Backend URL or Direct IP
  Future<Map<String, dynamic>> connectToHost(QrSessionPayload payload) async {
    if (payload.isExpired) {
      throw Exception('Session code has expired. Please ask sender to generate a fresh QR session.');
    }

    final backendUrl = ApiService().baseUrl.replaceAll(RegExp(r'/+$'), '');
    final dio = Dio();

    // 1. Try Backend URL session pairing first
    try {
      final response = await dio.get(
        '$backendUrl/p2p/session/info',
        queryParameters: {
          'sessionId': payload.sessionId,
          'token': payload.secretToken,
        },
        options: Options(
          headers: {
            'X-MaskerV-Session-Token': payload.secretToken,
            'X-PaperKit-Session-Token': payload.secretToken,
          },
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (_) {}

    // 2. Direct local socket pairing
    try {
      final url = 'http://${payload.hostIp}:${payload.port}/session/info';
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'X-MaskerV-Session-Token': payload.secretToken,
            'X-PaperKit-Session-Token': payload.secretToken,
          },
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Failed to pair with host device (${response.statusCode}).');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection to host timed out. Ensure both devices are on the same network or connected to Backend Server.');
      }
      throw Exception('Cannot connect to ${payload.hostIp}:${payload.port}. Ensure both devices are on the same network or connected to Backend Server.');
    } catch (e) {
      throw Exception('P2P connection error: $e');
    }
  }

  // Download & Verify File Integrity with SHA-256 via Backend URL or Direct Stream
  Future<File> downloadAndVerifyFile({
    required QrSessionPayload payload,
    required String expectedSha256,
    required Function(double progress, int transferredBytes, int totalBytes) onProgress,
  }) async {
    final outputDir = await getApplicationDocumentsDirectory();
    final localPath = '${outputDir.path}/airshare_${payload.documentName}';
    final targetFile = File(localPath);

    final backendUrl = ApiService().baseUrl.replaceAll(RegExp(r'/+$'), '');
    final dio = Dio();

    String downloadUrl = 'http://${payload.hostIp}:${payload.port}/transfer/download';

    // Check if Backend URL download endpoint is active
    try {
      final checkResp = await dio.get(
        '$backendUrl/p2p/transfer/check?sessionId=${payload.sessionId}',
        options: Options(
          headers: {
            'X-MaskerV-Session-Token': payload.secretToken,
            'X-PaperKit-Session-Token': payload.secretToken,
          },
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      if (checkResp.statusCode == 200) {
        downloadUrl = '$backendUrl/p2p/transfer/download?sessionId=${payload.sessionId}';
      }
    } catch (_) {}

    await dio.download(
      downloadUrl,
      localPath,
      options: Options(
        headers: {
          'X-MaskerV-Session-Token': payload.secretToken,
          'X-PaperKit-Session-Token': payload.secretToken,
        },
        receiveTimeout: const Duration(seconds: 45),
      ),
      onReceiveProgress: (count, total) {
        if (total > 0) {
          onProgress(count / total, count, total);
        }
      },
    );

    if (!await targetFile.exists() || await targetFile.length() == 0) {
      throw Exception('P2P File download failed or output file is empty.');
    }

    // Cryptographic Checksum Verification
    if (expectedSha256.isNotEmpty && expectedSha256.length == 64) {
      final actualHash = await _computeSha256(targetFile);
      if (actualHash.toLowerCase() != expectedSha256.toLowerCase()) {
        await targetFile.delete();
        throw Exception('Cryptographic SHA-256 checksum mismatch: File integrity verification failed.');
      }
    }

    // Register into MaskerV Document Tracker
    final doc = DocumentFile(
      id: 'airshare_${DateTime.now().millisecondsSinceEpoch}',
      name: payload.documentName,
      path: targetFile.path,
      size: await targetFile.length(),
      modifiedAt: DateTime.now(),
      type: FileTypeCategory.pdf,
    );
    await _storage.saveFile(doc);

    return targetFile;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 10: .MASKERV / .PAPERKIT PROJECT BUNDLE CREATOR & UNPACKER
  // ───────────────────────────────────────────────────────────────────────────

  Future<File> createProjectBundle({
    required String projectName,
    required String createdBy,
    required List<File> pdfFiles,
    required List<File> noteFiles,
  }) async {
    final archive = Archive();

    final List<String> pdfNames = [];
    for (final pdf in pdfFiles) {
      if (await pdf.exists()) {
        final bytes = await pdf.readAsBytes();
        final name = pdf.uri.pathSegments.last;
        archive.addFile(ArchiveFile('documents/$name', bytes.length, bytes));
        pdfNames.add(name);
      }
    }

    final List<String> noteNames = [];
    for (final note in noteFiles) {
      if (await note.exists()) {
        final bytes = await note.readAsBytes();
        final name = note.uri.pathSegments.last;
        archive.addFile(ArchiveFile('notes/$name', bytes.length, bytes));
        noteNames.add(name);
      }
    }

    final jsonContent = jsonEncode({
      'projectName': projectName,
      'pdfFiles': pdfNames,
      'noteFiles': noteNames,
    });
    final checksum = sha256.convert(utf8.encode(jsonContent)).toString();

    final manifest = MaskerVProjectBundleManifest(
      projectName: projectName,
      createdBy: createdBy,
      pdfFiles: pdfNames,
      noteFiles: noteNames,
      flashcardsFiles: [],
      mindMapFiles: [],
      checksumSha256: checksum,
    );

    final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    final zipEncoder = ZipEncoder();
    final encodedBytes = zipEncoder.encode(archive);

    final outputDir = await getApplicationDocumentsDirectory();
    final outputFile = File('${outputDir.path}/$projectName.maskerv');
    await outputFile.writeAsBytes(encodedBytes);
    return outputFile;
  }

  Future<MaskerVProjectBundleManifest?> unpackProjectBundle(File bundleFile) async {
    final bytes = await bundleFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) return null;

    final manifestText = utf8.decode(manifestFile.content as List<int>);
    final jsonMap = jsonDecode(manifestText) as Map<String, dynamic>;
    final manifest = MaskerVProjectBundleManifest.fromJson(jsonMap);

    final outputDir = await getApplicationDocumentsDirectory();
    final extractFolder = Directory('${outputDir.path}/extracted_${manifest.projectName}');
    if (!await extractFolder.exists()) {
      await extractFolder.create(recursive: true);
    }

    for (final file in archive) {
      if (file.isFile) {
        final outFile = File('${extractFolder.path}/${file.name}');
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }
    }

    return manifest;
  }

  void sendCoReviewScrollEvent({required int pageIndex}) {
    _latestCoReviewEvent = CoReviewEvent(
      senderId: 'host',
      currentPage: pageIndex,
      pointerX: _latestCoReviewEvent.pointerX,
      pointerY: _latestCoReviewEvent.pointerY,
    );
  }

  void sendLaserPointerEvent({required double x, required double y}) {
    _latestCoReviewEvent = CoReviewEvent(
      senderId: 'host',
      currentPage: _latestCoReviewEvent.currentPage,
      pointerX: x,
      pointerY: y,
    );
  }
}
