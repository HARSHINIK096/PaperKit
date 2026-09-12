import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/models/p2p_share_model.dart';
import '../../core/services/share_service.dart';
import 'p2p_mesh_service.dart';

class P2PMeshShareScreen extends StatefulWidget {
  const P2PMeshShareScreen({super.key});

  @override
  State<P2PMeshShareScreen> createState() => _P2PMeshShareScreenState();
}

class _P2PMeshShareScreenState extends State<P2PMeshShareScreen> with SingleTickerProviderStateMixin {
  final P2PMeshService _service = P2PMeshService();
  late TabController _tabController;

  // Person A (Host) State
  File? _hostSelectedFile;
  QrSessionPayload? _activeHostPayload;
  bool _isHosting = false;

  // Person B (Receiver) State
  final TextEditingController _qrPayloadController = TextEditingController();
  QrSessionPayload? _scannedPayload;
  Map<String, dynamic>? _connectedHostInfo;
  bool _isConnecting = false;

  double _transferProgress = 0.0;
  int _transferredBytes = 0;
  int _totalBytes = 0;
  bool _isTransferring = false;
  File? _receivedFile;
  String? _transferError;

  // Project Bundle State
  List<File> _bundleFiles = [];
  PaperKitProjectBundleManifest? _unpackedManifest;
  bool _isBundleLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qrPayloadController.dispose();
    _service.stopHostSession();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PERSON A — HOST ACTIONS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _pickHostDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'paperkit'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() {
        _hostSelectedFile = file;
      });
      await _startHostSession();
    }
  }

  Future<void> _startHostSession() async {
    if (_hostSelectedFile == null) return;
    setState(() => _isHosting = true);

    final payload = await _service.startHostSession(file: _hostSelectedFile!);
    setState(() {
      _activeHostPayload = payload;
      _isHosting = false;
    });
  }

  Future<void> _stopHostSession() async {
    await _service.stopHostSession();
    setState(() {
      _activeHostPayload = null;
      _hostSelectedFile = null;
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PERSON B — RECEIVER ACTIONS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _parseAndConnectQrPayload(String rawPayload) async {
    setState(() {
      _isConnecting = true;
      _transferError = null;
      _scannedPayload = null;
      _connectedHostInfo = null;
    });

    try {
      final payload = _service.parseAndValidateQrPayload(rawPayload);
      if (payload == null) {
        throw Exception('Invalid or expired QR session code.');
      }

      final hostInfo = await _service.connectToHost(payload);

      setState(() {
        _scannedPayload = payload;
        _connectedHostInfo = hostInfo;
        _isConnecting = false;
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _transferError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _acceptAndDownloadTransfer() async {
    if (_scannedPayload == null || _connectedHostInfo == null) return;

    setState(() {
      _isTransferring = true;
      _transferProgress = 0.0;
      _transferError = null;
    });

    try {
      final expectedSha = _connectedHostInfo!['sha256'] as String? ?? '';

      final file = await _service.downloadAndVerifyFile(
        payload: _scannedPayload!,
        expectedSha256: expectedSha,
        onProgress: (progress, transferred, total) {
          setState(() {
            _transferProgress = progress;
            _transferredBytes = transferred;
            _totalBytes = total;
          });
        },
      );

      setState(() {
        _isTransferring = false;
        _receivedFile = file;
      });
    } catch (e) {
      setState(() {
        _isTransferring = false;
        _transferError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BUNDLE ACTIONS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _pickBundleFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        _bundleFiles = result.files.where((f) => f.path != null).map((f) => File(f.path!)).toList();
      });
    }
  }

  Future<void> _exportBundle() async {
    if (_bundleFiles.isEmpty) return;
    setState(() => _isBundleLoading = true);

    final bundle = await _service.createProjectBundle(
      projectName: 'PaperKit_Project_${DateTime.now().millisecondsSinceEpoch}',
      createdBy: 'PaperKit User',
      pdfFiles: _bundleFiles,
      noteFiles: [],
    );

    setState(() => _isBundleLoading = false);
    ShareService.shareFile(filePath: bundle.path);
  }

  Future<void> _importBundle() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['paperkit', 'zip'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _isBundleLoading = true);
      final manifest = await _service.unpackProjectBundle(File(result.files.single.path!));
      setState(() {
        _unpackedManifest = manifest;
        _isBundleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Air-Share P2P Workspace'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(LucideIcons.arrowUpRight), text: 'Send / Host'),
            Tab(icon: Icon(LucideIcons.arrowDownLeft), text: 'Receive / Join'),
            Tab(icon: Icon(LucideIcons.package), text: '.paperkit Bundle'),
            Tab(icon: Icon(LucideIcons.users), text: 'Co-Review'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendHostTab(),
          _buildReceiveJoinTab(),
          _buildBundleTab(),
          _buildCoReviewTab(),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PERSON A UI: HOST & GENERATE QR
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildSendHostTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _isHosting ? null : _pickHostDocument,
            icon: const Icon(LucideIcons.fileUp),
            label: const Text('Select Document to Host & Share'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),
          if (_activeHostPayload != null) ...[
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          avatar: const Icon(LucideIcons.wifi, size: 16),
                          label: Text('Host IP: ${_activeHostPayload!.hostIp}:${_activeHostPayload!.port}'),
                        ),
                        OutlinedButton(
                          onPressed: _stopHostSession,
                          child: const Text('Cancel Host'),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text('PAIRING QR CODE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
                    const SizedBox(height: 12),
                    // QR Code visual container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                      child: Column(
                        children: [
                          Icon(LucideIcons.qrCode, size: 140, color: Theme.of(context).primaryColor),
                          const SizedBox(height: 8),
                          SelectableText(
                            _activeHostPayload!.toEncodedUrl(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10, fontFamily: 'Monospace', color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Document: ${_activeHostPayload!.documentName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const Text('Person B: Open PaperKit Air-Share ➔ Scan QR to pair and receive file.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ] else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(LucideIcons.share2, size: 48, color: Colors.blue),
                    SizedBox(height: 12),
                    Text('PaperKit-to-PaperKit Offline P2P Sharing', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('Select a document to create an offline local socket session and display your pairing QR code.'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PERSON B UI: SCANNER / RECEIVER & PAIRING CONFIRMATION
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildReceiveJoinTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Scan / Enter PaperKit QR Payload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          TextField(
            controller: _qrPayloadController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Paste or scan paperkit://airshare?session=...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: const Icon(LucideIcons.qrCode),
                onPressed: () {
                  if (_activeHostPayload != null) {
                    _qrPayloadController.text = _activeHostPayload!.toEncodedUrl();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isConnecting ? null : () => _parseAndConnectQrPayload(_qrPayloadController.text.trim()),
            icon: const Icon(LucideIcons.link),
            label: const Text('Validate & Pair Session'),
          ),
          const SizedBox(height: 20),
          if (_isConnecting)
            const Center(child: CircularProgressIndicator())
          else if (_transferError != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertTriangle, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_transferError!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            )
          else if (_connectedHostInfo != null) ...[
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.checkCircle2, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Pairing Connected to Host', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                      ],
                    ),
                    const Divider(height: 20),
                    Text('File Name: ${_connectedHostInfo!['fileName']}'),
                    Text('Size: ${((_connectedHostInfo!['fileSize'] as int? ?? 0) / 1024).toStringAsFixed(1)} KB'),
                    Text('SHA-256 Checksum: ${(_connectedHostInfo!['sha256'] as String? ?? '').substring(0, 16)}...'),
                    const SizedBox(height: 16),
                    if (_isTransferring) ...[
                      LinearProgressIndicator(value: _transferProgress),
                      const SizedBox(height: 8),
                      Text('Transferring: ${(_transferProgress * 100).toStringAsFixed(1)}% (${(_transferredBytes / 1024).toStringAsFixed(0)} / ${(_totalBytes / 1024).toStringAsFixed(0)} KB)'),
                    ] else ...[
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _acceptAndDownloadTransfer,
                            icon: const Icon(LucideIcons.download),
                            label: const Text('Accept & Receive File'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => setState(() => _connectedHostInfo = null),
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (_receivedFile != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.green.shade50,
              child: ListTile(
                leading: const Icon(LucideIcons.fileCheck, color: Colors.green),
                title: Text('Imported: ${_receivedFile!.uri.pathSegments.last}'),
                subtitle: const Text('Verified SHA-256 digest & saved to PaperKit Workspace.'),
                trailing: ElevatedButton(
                  onPressed: () => OpenFilex.open(_receivedFile!.path),
                  child: const Text('Open'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PROJECT BUNDLE UI
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildBundleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickBundleFiles,
                icon: const Icon(LucideIcons.files),
                label: const Text('Select Files for Bundle'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _importBundle,
                icon: const Icon(LucideIcons.fileInput),
                label: const Text('Import .paperkit'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_bundleFiles.isNotEmpty) ...[
            Text('Selected Files (${_bundleFiles.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bundleFiles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(LucideIcons.fileText),
                  title: Text(_bundleFiles[index].uri.pathSegments.last),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isBundleLoading ? null : _exportBundle,
              icon: const Icon(LucideIcons.archive),
              label: const Text('Export .paperkit Package'),
            ),
          ],
          if (_unpackedManifest != null) ...[
            const Divider(height: 32),
            Card(
              child: ListTile(
                title: Text('Imported Project: ${_unpackedManifest!.projectName}'),
                subtitle: Text('PDF Documents: ${_unpackedManifest!.pdfFiles.length}\nChecksum: ${_unpackedManifest!.checksumSha256.substring(0, 16)}...'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // P2P CO-REVIEW UI
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildCoReviewTab() {
    return const Center(child: Text('Synchronized Co-Review session over local P2P socket (page position & laser pointer).'));
  }
}
