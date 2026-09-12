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
import '../../core/services/storage_service.dart';

class P2PMeshService {
  final StorageService _storage = StorageService();

  HttpServer? _hostServer;
  QrSessionPayload? _currentHostSession;
  File? _currentSharingFile;
  AirShareSessionState _sessionState = AirShareSessionState.idle;

  CoReviewEvent _latestCoReviewEvent = CoReviewEvent(
    senderId: 'host',
    currentPage: 0,
  );

  AirShareSessionState get sessionState => _sessionState;
  QrSessionPayload? get currentHostSession => _currentHostSession;
  CoReviewEvent get latestCoReviewEvent => _latestCoReviewEvent;

  // Compute SHA-256 Checksum
  Future<String> _computeSha256(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  // Get local network IPv4 address
  Future<String> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1';
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
    final rnd = Random.secure();
    final secretToken = List.generate(16, (_) => rnd.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final sessionId = 'pk_session_${DateTime.now().millisecondsSinceEpoch}';

    // Bind local socket HTTP server
    _hostServer = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
    final port = _hostServer!.port;

    _currentHostSession = QrSessionPayload(
      protocolVersion: '1.0',
      sessionId: sessionId,
      hostIp: localIp,
      port: port,
      secretToken: secretToken,
      documentName: file.uri.pathSegments.last,
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );

    _sessionState = AirShareSessionState.qrReady;

    // Handle Incoming P2P Requests
    _hostServer!.listen((HttpRequest request) async {
      final token = request.headers.value('X-PaperKit-Session-Token');

      if (_currentHostSession == null || _currentHostSession!.isExpired) {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..write(jsonEncode({'error': 'Session expired or closed'}))
          ..close();
        return;
      }

      if (token != _currentHostSession!.secretToken && request.uri.path != '/health') {
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
  // STAGE 2, 4 & 6: RECEIVER CLIENT & FILE VERIFICATION
  // ───────────────────────────────────────────────────────────────────────────

  // Validate QR Payload
  QrSessionPayload? parseAndValidateQrPayload(String rawQrContent) {
    try {
      if (rawQrContent.startsWith('paperkit://airshare')) {
        final uri = Uri.parse(rawQrContent);
        final payload = QrSessionPayload(
          sessionId: uri.queryParameters['session'] ?? '',
          hostIp: uri.queryParameters['ip'] ?? '',
          port: int.tryParse(uri.queryParameters['port'] ?? '8080') ?? 8080,
          secretToken: uri.queryParameters['token'] ?? '',
          documentName: uri.queryParameters['name'] ?? '',
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

  // Connect to Host & Fetch Shared File Info
  Future<Map<String, dynamic>> connectToHost(QrSessionPayload payload) async {
    if (payload.isExpired) {
      throw Exception('Session expired');
    }

    final dio = Dio();
    final url = 'http://${payload.hostIp}:${payload.port}/session/info';

    final response = await dio.get(
      url,
      options: Options(
        headers: {'X-PaperKit-Session-Token': payload.secretToken},
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return Map<String, dynamic>.from(response.data);
    } else {
      throw Exception('Failed to pair with host device.');
    }
  }

  // Download & Verify File Integrity with SHA-256
  Future<File> downloadAndVerifyFile({
    required QrSessionPayload payload,
    required String expectedSha256,
    required Function(double progress, int transferredBytes, int totalBytes) onProgress,
  }) async {
    final dio = Dio();
    final url = 'http://${payload.hostIp}:${payload.port}/transfer/download';

    final outputDir = await getApplicationDocumentsDirectory();
    final localPath = '${outputDir.path}/airshare_${payload.documentName}';

    await dio.download(
      url,
      localPath,
      options: Options(
        headers: {'X-PaperKit-Session-Token': payload.secretToken},
      ),
      onReceiveProgress: (count, total) {
        if (total > 0) {
          onProgress(count / total, count, total);
        }
      },
    );

    final downloadedFile = File(localPath);
    if (!await downloadedFile.exists()) {
      throw Exception('File download failed or incomplete.');
    }

    // Cryptographic Checksum Verification
    final actualHash = await _computeSha256(downloadedFile);
    if (expectedSha256.isNotEmpty && actualHash.toLowerCase() != expectedSha256.toLowerCase()) {
      await downloadedFile.delete();
      throw Exception('Integrity check failed: Cryptographic SHA-256 checksum mismatch.');
    }

    // Save into PaperKit Document Tracker
    final doc = DocumentFile(
      id: 'airshare_${DateTime.now().millisecondsSinceEpoch}',
      name: payload.documentName,
      path: downloadedFile.path,
      size: await downloadedFile.length(),
      modifiedAt: DateTime.now(),
      type: FileTypeCategory.pdf,
    );
    await _storage.saveFile(doc);

    return downloadedFile;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 10: .PAPERKIT PROJECT BUNDLE CREATOR & UNPACKER
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

    final manifest = PaperKitProjectBundleManifest(
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
    final outputFile = File('${outputDir.path}/$projectName.paperkit');
    await outputFile.writeAsBytes(encodedBytes);
    return outputFile;
  }

  Future<PaperKitProjectBundleManifest?> unpackProjectBundle(File bundleFile) async {
    final bytes = await bundleFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) return null;

    final manifestText = utf8.decode(manifestFile.content as List<int>);
    final jsonMap = jsonDecode(manifestText) as Map<String, dynamic>;
    final manifest = PaperKitProjectBundleManifest.fromJson(jsonMap);

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
}
