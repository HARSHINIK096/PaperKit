import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/history_provider.dart';
import '../../core/widgets/app_shell.dart';
import 'models/qr_parsed_payload.dart';
import 'models/qr_scan_history_item.dart';
import 'services/qr_image_decoder.dart';
import 'services/qr_payload_parser.dart';
import 'services/qr_scan_history_service.dart';
import 'widgets/qr_scan_result_sheet.dart';
import 'widgets/qr_viewfinder_overlay.dart';

class QrScannerScreen extends StatefulWidget {
  final bool isModalPicker;

  const QrScannerScreen({super.key, this.isModalPicker = false});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with WidgetsBindingObserver {
  late MobileScannerController _cameraController;
  bool _isCameraSupported = true;
  bool _hasCameraPermission = false;
  bool _isCheckingPermission = true;
  bool _isScanning = true;
  bool _isTorchOn = false;
  CameraFacing _facing = CameraFacing.back;
  QrParsedPayload? _activeResult;
  List<QrScanHistoryItem> _scanHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: _facing,
      torchEnabled: false,
    );
    _checkCameraSupportAndPermissions();
    _loadScanHistory();
  }

  Future<void> _checkCameraSupportAndPermissions() async {
    // Windows and Linux desktop typically don't have mobile_scanner camera driver
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      if (mounted) {
        setState(() {
          _isCameraSupported = false;
          _isCheckingPermission = false;
        });
      }
      return;
    }

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final status = await Permission.camera.status;
      if (status.isGranted) {
        if (mounted) {
          setState(() {
            _hasCameraPermission = true;
            _isCheckingPermission = false;
          });
        }
      } else {
        final result = await Permission.camera.request();
        if (mounted) {
          setState(() {
            _hasCameraPermission = result.isGranted;
            _isCheckingPermission = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _hasCameraPermission = true;
          _isCheckingPermission = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isCameraSupported || !_hasCameraPermission) return;
    if (state == AppLifecycleState.resumed) {
      _cameraController.start();
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraController.stop();
    }
  }

  Future<void> _loadScanHistory() async {
    final history = await QrScanHistoryService.getHistory();
    if (mounted) {
      setState(() => _scanHistory = history);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning || _activeResult != null) return;

    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        _handleDecodedRawString(rawValue);
        break;
      }
    }
  }

  Future<void> _handleDecodedRawString(String raw) async {
    HapticFeedback.mediumImpact();
    setState(() => _isScanning = false);

    if (widget.isModalPicker) {
      Navigator.of(context).pop(raw);
      return;
    }

    final payload = QrPayloadParser.parse(raw);

    // Record to local Scan History
    await QrScanHistoryService.recordScan(payload);

    // Log to global PaperKit History
    if (mounted) {
      await context.read<HistoryProvider>().addRecord(
            HistoryItem(
              id: 'qr_scan_${DateTime.now().millisecondsSinceEpoch}',
              toolId: 'qr-scanner',
              toolName: 'QR Code Scanner',
              fileName: payload.title,
              fileSize: raw.length,
              timestamp: DateTime.now(),
              success: true,
              details: '${payload.type.displayName} • Decoded',
            ),
          );
      _loadScanHistory();
    }

    setState(() {
      _activeResult = payload;
    });

    _showResultBottomSheet(payload);
  }

  void _showResultBottomSheet(QrParsedPayload payload) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QrScanResultSheet(
        payload: payload,
        onDismiss: () {
          Navigator.of(ctx).pop();
          setState(() {
            _activeResult = null;
            _isScanning = true;
          });
        },
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _activeResult = null;
          _isScanning = true;
        });
      }
    });
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final payload = await QrImageDecoder.decodeFile(file);

        if (payload != null) {
          _handleDecodedRawString(payload.rawData);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No decodable QR code detected in the selected image.'),
                backgroundColor: Color(0xFFE11D48),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _cameraController.toggleTorch();
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    try {
      await _cameraController.switchCamera();
      setState(() {
        _facing = _facing == CameraFacing.back ? CameraFacing.front : CameraFacing.back;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (!_isCameraSupported) {
      content = _buildDesktopFallbackView();
    } else if (_isCheckingPermission) {
      content = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF2563EB)),
            SizedBox(height: 16),
            Text('Checking camera permissions...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    } else if (!_hasCameraPermission) {
      content = _buildPermissionDeniedView();
    } else {
      content = _buildCameraScannerView();
    }

    if (widget.isModalPicker) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan QR Code'),
          leading: IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.history, size: 20),
              tooltip: 'Scan History',
              onPressed: _openScanHistorySheet,
            ),
          ],
        ),
        body: content,
      );
    }

    return AppShell(
      title: 'QR Code Scanner',
      showBottomNav: false,
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.history, size: 20),
          tooltip: 'Scan History',
          onPressed: _openScanHistorySheet,
        ),
      ],
      child: content,
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.cameraOff, size: 48, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Camera Permission Required',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'PaperKit needs camera access to scan QR codes with your device sensor.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final status = await Permission.camera.request();
                if (status.isGranted) {
                  setState(() => _hasCameraPermission = true);
                } else if (status.isPermanentlyDenied) {
                  await openAppSettings();
                }
              },
              icon: const Icon(LucideIcons.shieldAlert, size: 18),
              label: const Text('Grant Camera Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _pickImageFromGallery,
              icon: const Icon(LucideIcons.image, size: 16),
              label: const Text('Or Scan from Gallery Image'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraScannerView() {
    return Stack(
      children: [
        // 1. Live Camera Feed
        MobileScanner(
          controller: _cameraController,
          onDetect: _onDetect,
          placeholderBuilder: (context) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2563EB)),
                  SizedBox(height: 16),
                  Text(
                    'Starting camera sensor...',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            );
          },
          errorBuilder: (context, error) {
            return _buildCameraErrorView(error);
          },
        ),

        // 2. Viewfinder Overlay with Animated Laser Line
        const QrViewfinderOverlay(scanBoxSize: 260),

        // 3. Top Action Controls (Torch & Camera Flip)
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: IconButton(
                  icon: Icon(
                    _isTorchOn ? LucideIcons.zap : LucideIcons.zapOff,
                    color: _isTorchOn ? Colors.yellow : Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Toggle Flashlight',
                  onPressed: _toggleTorch,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: IconButton(
                  icon: const Icon(LucideIcons.switchCamera, color: Colors.white, size: 20),
                  tooltip: 'Switch Camera',
                  onPressed: _switchCamera,
                ),
              ),
            ],
          ),
        ),

        // 4. Bottom Quick Actions (Image Pick from Gallery)
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Point camera at QR code to scan instantly',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(LucideIcons.image, size: 18),
                label: const Text('Scan QR from Image / Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopFallbackView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.scanLine, size: 40, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Desktop Image QR Scanner',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Direct camera feed is unavailable on this desktop system.\nImport an image, screenshot, or photo to instantly decode the QR payload.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickImageFromGallery,
              icon: const Icon(LucideIcons.fileImage, size: 18),
              label: const Text('Select QR Image to Decode'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraErrorView(MobileScannerException error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.cameraOff, size: 48, color: Color(0xFFE11D48)),
            const SizedBox(height: 16),
            const Text(
              'Camera Access Unavailable',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Could not start camera feed: ${error.errorDetails?.message ?? error.errorCode.name}.\nYou can still scan QR codes directly from images.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImageFromGallery,
              icon: const Icon(LucideIcons.image),
              label: const Text('Scan QR from Image'),
            ),
          ],
        ),
      ),
    );
  }

  void _openScanHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Scan History',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (_scanHistory.isNotEmpty)
                        TextButton.icon(
                          onPressed: () async {
                            await QrScanHistoryService.clearHistory();
                            setSheetState(() => _scanHistory.clear());
                            setState(() => _scanHistory.clear());
                          },
                          icon: const Icon(LucideIcons.trash2, size: 14),
                          label: const Text('Clear All', style: TextStyle(color: Color(0xFFE11D48))),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_scanHistory.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text('No QR scan history recorded yet.', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: _scanHistory.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _scanHistory[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
                              child: const Icon(LucideIcons.scanLine, size: 18, color: Color(0xFF2563EB)),
                            ),
                            title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                            subtitle: Text('${item.type.displayName} • ${item.timestamp.toLocal().toString().substring(0, 16)}', style: const TextStyle(fontSize: 11)),
                            trailing: IconButton(
                              icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.grey),
                              onPressed: () async {
                                await QrScanHistoryService.deleteItem(item.id);
                                setSheetState(() => _scanHistory.removeAt(index));
                                setState(() => _scanHistory.removeWhere((h) => h.id == item.id));
                              },
                            ),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              final payload = QrPayloadParser.parse(item.rawData);
                              _showResultBottomSheet(payload);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
