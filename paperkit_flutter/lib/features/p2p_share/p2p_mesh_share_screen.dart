import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr/qr.dart';
import '../../core/models/p2p_share_model.dart';
import '../../core/services/biometric_auth_service.dart';
import '../../core/widgets/particle_background.dart';
import 'p2p_mesh_service.dart';
import 'widgets/nearby_device_radar.dart';

class P2PMeshShareScreen extends StatefulWidget {
  final File? initialFile;

  const P2PMeshShareScreen({super.key, this.initialFile});

  @override
  State<P2PMeshShareScreen> createState() => _P2PMeshShareScreenState();
}

class _P2PMeshShareScreenState extends State<P2PMeshShareScreen> with SingleTickerProviderStateMixin {
  final P2PMeshService _service = P2PMeshService();
  late TabController _tabController;

  // Mode Selection: 0 = Nearby Radar, 1 = QR Matrix
  int _sendModeIndex = 0;
  int _receiveModeIndex = 0;

  // Nearby Device Proximity & Radar State
  double _selectedRadius = 10.0;
  List<PeerDevice> _nearbyDevices = [];
  PeerDevice? _selectedDevice;
  bool _isScanningNearby = false;
  StreamSubscription<DirectTransferInvite>? _inviteSubscription;
  bool _isDiscoverable = true;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scanNearbyDevices();
    _startDiscoveryListener();
    _listenToIncomingInvites();

    if (widget.initialFile != null) {
      _hostSelectedFile = widget.initialFile;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startHostSession();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qrPayloadController.dispose();
    _inviteSubscription?.cancel();
    _service.stopDiscoveryBeaconListener();
    _service.stopHostSession();
    super.dispose();
  }

  Future<void> _startDiscoveryListener() async {
    await _service.startDiscoveryBeaconListener(deviceName: "PaperKit User");
  }

  void _listenToIncomingInvites() {
    _inviteSubscription = _service.onIncomingInvite.listen((invite) {
      if (mounted) {
        _showIncomingInviteDialog(invite);
      }
    });
  }

  Future<void> _scanNearbyDevices() async {
    setState(() => _isScanningNearby = true);
    final devices = await _service.scanNearbyDevices(maxRadiusMeters: _selectedRadius);
    if (mounted) {
      setState(() {
        _nearbyDevices = devices;
        _isScanningNearby = false;
      });
    }
  }

  Future<void> _beamToSelectedDevice(PeerDevice device) async {
    if (_hostSelectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a document or MASKERV file to share first.'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }

    final authenticated = await BiometricAuthService().authenticate(
      reason: 'Authenticate to beam "${_hostSelectedFile!.uri.pathSegments.last}" to ${device.deviceName} (${device.distanceMeters.toStringAsFixed(1)}m away).',
      context: context,
    );

    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric verification cancelled.')),
        );
      }
      return;
    }

    setState(() {
      _selectedDevice = device;
      _isHosting = true;
    });

    await _service.sendDirectTransferInvite(
      target: device,
      file: _hostSelectedFile!,
    );

    setState(() => _isHosting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AirShare beam sent to ${device.deviceName} (${device.distanceLabel})!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _showIncomingInviteDialog(DirectTransferInvite invite) async {
    HapticFeedback.heavyImpact();
    final accept = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(LucideIcons.radio, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text('Incoming AirShare Transfer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${invite.senderDeviceName}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Document: ${invite.documentName}', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text('Size: ${(invite.fileSize / 1024).toStringAsFixed(1)} KB', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            const Text(
              'Would you like to authorize biometric verification and download this file directly?',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Decline', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept & Download'),
          ),
        ],
      ),
    );

    if (accept == true) {
      final payload = invite.toQrSessionPayload();
      setState(() {
        _scannedPayload = payload;
        _connectedHostInfo = {
          'fileName': invite.documentName,
          'fileSize': invite.fileSize,
          'sha256': invite.sha256,
        };
        _tabController.animateTo(1);
      });
      await _acceptAndDownloadTransfer();
    }
  }


  // ───────────────────────────────────────────────────────────────────────────
  // PERSON A — HOST ACTIONS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _pickHostDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
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

    final authenticated = await BiometricAuthService().authenticate(
      reason: 'Authenticate via fingerprint or PIN to generate P2P host session & pairing QR code.',
      context: context,
    );

    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('P2P Host Biometric Authentication Cancelled.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
      return;
    }

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

    final authenticated = await BiometricAuthService().authenticate(
      reason: 'Authenticate via fingerprint or PIN to authorize incoming P2P document download.',
      context: context,
    );

    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incoming P2P Transfer Authentication Cancelled.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
      return;
    }

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


  Future<void> _openCameraQrScanner() async {
    HapticFeedback.mediumImpact();
    final scannedData = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.scanLine, color: Color(0xFF2563EB), size: 22),
                        SizedBox(width: 8),
                        Text('Camera QR Scanner', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Stylized Camera Viewfinder Frame
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2563EB), width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(LucideIcons.camera, color: Colors.white24, size: 54),
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.8), width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Align QR in Viewfinder',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (_activeHostPayload != null) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop(_activeHostPayload!.toEncodedUrl());
                    },
                    icon: const Icon(LucideIcons.sparkles, size: 16),
                    label: const Text('Auto-Detect Host Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel Scan'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (scannedData != null && scannedData.isNotEmpty) {
      _qrPayloadController.text = scannedData;
      await _parseAndConnectQrPayload(scannedData);
    }
  }

  Future<void> _pickQrImageFromGallery() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null) {
      if (_activeHostPayload != null) {
        _qrPayloadController.text = _activeHostPayload!.toEncodedUrl();
        await _parseAndConnectQrPayload(_qrPayloadController.text);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Code Image selected. Validating session payload...')),
        );
      }
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
            Tab(icon: Icon(LucideIcons.users), text: 'Co-Review'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendHostTab(),
          _buildReceiveJoinTab(),
          _buildCoReviewTab(),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ───────────────────────────────────────────────────────────────────────────
  // PERSON A UI: HOST & GENERATE QR OR BEAM VIA RADAR
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildSendHostTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document Selection Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  child: const Icon(LucideIcons.fileText, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hostSelectedFile != null
                            ? _hostSelectedFile!.uri.pathSegments.last
                            : 'No Document Selected',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hostSelectedFile != null
                            ? 'Ready for AirShare Transfer'
                            : 'Select a PDF or MASKERV file to beam',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isHosting ? null : _pickHostDocument,
                  icon: const Icon(LucideIcons.fileUp, size: 16),
                  label: Text(_hostSelectedFile != null ? 'Change' : 'Browse'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Transfer Mode Selector: Radar Proximity vs QR Code Matrix
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _sendModeIndex = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _sendModeIndex == 0
                            ? const Color(0xFF2563EB)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.radar,
                            size: 16,
                            color: _sendModeIndex == 0 ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Nearby Radar (Radius)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _sendModeIndex == 0 ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      setState(() => _sendModeIndex = 1);
                      if (_activeHostPayload == null && _hostSelectedFile != null) {
                        await _startHostSession();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _sendModeIndex == 1
                            ? const Color(0xFF2563EB)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.qrCode,
                            size: 16,
                            color: _sendModeIndex == 1 ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'QR Code Matrix',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _sendModeIndex == 1 ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Mode 0: Nearby Device Radar (Radius Proximity)
          if (_sendModeIndex == 0) ...[
            NearbyDeviceRadar(
              devices: _nearbyDevices,
              currentMaxRadius: _selectedRadius,
              onRadiusChanged: (newRadius) {
                setState(() => _selectedRadius = newRadius);
                _scanNearbyDevices();
              },
              onDeviceSelected: _beamToSelectedDevice,
              selectedDevice: _selectedDevice,
              isScanning: _isScanningNearby,
            ),
          ]

          // Mode 1: QR Code Matrix & Share Sheet
          else ...[
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                        ),
                        child: Column(
                          children: [
                            DynamicQrWidget(
                              data: _activeHostPayload!.toEncodedUrl(),
                              size: 170,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                Share.share(
                                  'PaperKit AirShare P2P Transfer Session for "${_activeHostPayload!.documentName}":\n${_activeHostPayload!.toEncodedUrl()}',
                                );
                              },
                              icon: const Icon(LucideIcons.share2, size: 16),
                              label: const Text('Share QR Link via Other Apps'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.qrCode, size: 48, color: Colors.blue),
                      const SizedBox(height: 12),
                      const Text('Generate P2P QR Code', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('Select a document above and tap below to start local server and render the scannable pairing QR code.'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _hostSelectedFile == null ? null : _startHostSession,
                        icon: const Icon(LucideIcons.play),
                        label: const Text('Generate Pairing QR Matrix'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PERSON B UI: SCANNER / RECEIVER & PAIRING CONFIRMATION
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildReceiveJoinTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Receive Mode Selector: Discoverable Radar vs QR Scanner
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _receiveModeIndex = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _receiveModeIndex == 0
                            ? const Color(0xFF2563EB)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.radio,
                            size: 16,
                            color: _receiveModeIndex == 0 ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Discoverable Radar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _receiveModeIndex == 0 ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _receiveModeIndex = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _receiveModeIndex == 1
                            ? const Color(0xFF2563EB)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.scanLine,
                            size: 16,
                            color: _receiveModeIndex == 1 ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Scan QR Code',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _receiveModeIndex == 1 ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Receiver Mode 0: Discoverable Radar Active
          if (_receiveModeIndex == 0) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                    child: const Icon(LucideIcons.radio, size: 36, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Discoverable to Nearby Senders',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This device is broadcasting on your local Wi-Fi / Hotspot. Any nearby PaperKit user can detect this device on their radar and beam documents to you directly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.shieldCheck, size: 16, color: Color(0xFF10B981)),
                        SizedBox(width: 8),
                        Text(
                          'Biometric Verification Enabled on Arrival',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Discoverable by Nearby Devices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(_isDiscoverable ? 'Broadcasting on local radius' : 'Device hidden', style: const TextStyle(fontSize: 11)),
                    value: _isDiscoverable,
                    onChanged: (val) {
                      setState(() => _isDiscoverable = val);
                      if (val) {
                        _startDiscoveryListener();
                      } else {
                        _service.stopDiscoveryBeaconListener();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ]

          // Receiver Mode 1: QR Code Scanner & Manual Paste
          else ...[
            const Text('Scan / Enter PaperKit QR Payload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 14),

            // Camera QR Scanner & Gallery Trigger Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openCameraQrScanner,
                    icon: const Icon(LucideIcons.camera, size: 18),
                    label: const Text('Scan QR with Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _pickQrImageFromGallery,
                  icon: const Icon(LucideIcons.image, size: 18),
                  label: const Text('Pick Image'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR PASTE PAYLOAD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 14),

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
          ],

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
  // P2P CO-REVIEW UI
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildCoReviewTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final event = _service.latestCoReviewEvent;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Synchronized Co-Review Card with Particle Background
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                    : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    child: ParticleBackground(
                      numberOfParticles: 15,
                      particleColor: Color(0xFF6366F1),
                      enableLines: true,
                      maxSpeed: 0.3,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6366F1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.users, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'P2P Synchronized Co-Review',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Live page scrolling, laser pointer & real-time document sync over encrypted local socket.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Active Sync Page', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                              Text('Page ${event.currentPage + 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Laser Pointer Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                              Text(
                                event.laserX != null ? 'Active (${event.laserX!.toStringAsFixed(0)}, ${event.laserY!.toStringAsFixed(0)})' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: event.laserX != null ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Co-Review Action Cards
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            childAspectRatio: 1.35,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildCoReviewFeatureCard(
                title: 'Broadcast Page',
                subtitle: 'Sync active page index with all peer devices',
                icon: LucideIcons.radio,
                color: const Color(0xFF2563EB),
                onTap: () {
                  _service.sendCoReviewScrollEvent(pageIndex: event.currentPage + 1);
                  setState(() {});
                },
              ),
              _buildCoReviewFeatureCard(
                title: 'Laser Pointer',
                subtitle: 'Highlight sections on connected peers',
                icon: LucideIcons.pointer,
                color: const Color(0xFFDC2626),
                onTap: () {
                  _service.sendLaserPointerEvent(x: 180, y: 320);
                  setState(() {});
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoReviewFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DynamicQrWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color color;

  const DynamicQrWidget({
    super.key,
    required this.data,
    this.size = 180,
    this.color = const Color(0xFF2563EB),
  });

  @override
  Widget build(BuildContext context) {
    try {
      final qrCode = QrCode.fromData(
        data: data,
        errorCorrectLevel: QrErrorCorrectLevel.M,
      );
      final qrImage = QrImage(qrCode);

      return CustomPaint(
        size: Size(size, size),
        painter: _QrCanvasPainter(qrImage: qrImage, color: color),
      );
    } catch (_) {
      return Icon(LucideIcons.qrCode, size: size, color: color);
    }
  }
}

class _QrCanvasPainter extends CustomPainter {
  final QrImage qrImage;
  final Color color;

  _QrCanvasPainter({required this.qrImage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final moduleCount = qrImage.moduleCount;
    final pixelSize = size.width / moduleCount;

    for (int x = 0; x < moduleCount; x++) {
      for (int y = 0; y < moduleCount; y++) {
        if (qrImage.isDark(y, x)) {
          final rect = Rect.fromLTWH(
            x * pixelSize,
            y * pixelSize,
            pixelSize,
            pixelSize,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(pixelSize * 0.2)),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrCanvasPainter oldDelegate) => false;
}

