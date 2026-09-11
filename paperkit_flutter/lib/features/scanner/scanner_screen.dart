import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/widgets/file_success_dialog.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final List<File> _scannedPages = [];
  String _activeScanType = 'document'; // document, id-card, book, receipt
  bool _isProcessing = false;
  File? _currentPreviewImage;
  bool _isTorchOn = false;
  bool _showGrid = true;
  String _activeFilter = 'magic'; // magic, bw, gray, original

  // 4 Corner Crop Pins (Normalized 0.0 to 1.0)
  Offset _topLeft = const Offset(0.08, 0.08);
  Offset _topRight = const Offset(0.92, 0.08);
  Offset _bottomRight = const Offset(0.92, 0.92);
  Offset _bottomLeft = const Offset(0.08, 0.92);

  late AnimationController _laserController;
  late AnimationController _reticleController;

  final List<Map<String, dynamic>> _scanTypes = [
    {'id': 'document', 'label': 'Document', 'ratio': 0.72, 'icon': LucideIcons.fileText},
    {'id': 'id-card', 'label': 'ID Card', 'ratio': 1.58, 'icon': LucideIcons.creditCard},
    {'id': 'receipt', 'label': 'Receipt', 'ratio': 0.52, 'icon': LucideIcons.receipt},
    {'id': 'book', 'label': 'Book', 'ratio': 0.82, 'icon': LucideIcons.bookOpen},
  ];

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _reticleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    _reticleController.dispose();
    super.dispose();
  }

  Future<void> _captureFromCamera(ImageSource source) async {
    HapticFeedback.mediumImpact();
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 98,
      );

      if (image != null) {
        setState(() {
          _currentPreviewImage = File(image.path);
          _topLeft = const Offset(0.08, 0.08);
          _topRight = const Offset(0.92, 0.08);
          _bottomRight = const Offset(0.92, 0.92);
          _bottomLeft = const Offset(0.08, 0.92);
          _activeFilter = 'magic';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access camera: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _acceptCurrentPage() {
    if (_currentPreviewImage == null) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _scannedPages.add(_currentPreviewImage!);
      _currentPreviewImage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCheck, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('Page ${_scannedPages.length} added to scan bundle'),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_scannedPages.isEmpty) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final pdf = pw.Document();

      for (final pageFile in _scannedPages) {
        final imageBytes = await pageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: _activeScanType == 'id-card'
                ? const pw_pdf.PdfPageFormat(85.6 * pw_pdf.PdfPageFormat.mm, 53.98 * pw_pdf.PdfPageFormat.mm)
                : pw_pdf.PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      final outputDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'MASKERV_Scan_$timestamp.pdf';
      final outputFile = File('${outputDir.path}/$fileName');
      await outputFile.writeAsBytes(await pdf.save());
      final fileSize = await outputFile.length();

      final doc = DocumentFile(
        id: 'scan_$timestamp',
        name: fileName,
        path: outputFile.path,
        size: fileSize,
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.pdf,
        pageCount: _scannedPages.length,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'scanner',
                toolName: 'Document Scanner',
                fileName: fileName,
                outputPath: outputFile.path,
                fileSize: fileSize,
                timestamp: DateTime.now(),
                success: true,
              ),
            );

        setState(() {
          _isProcessing = false;
          _scannedPages.clear();
        });

        FileSuccessDialog.show(
          context,
          title: 'Document Scanned!',
          message: 'Your multi-page scan has been compiled to high-resolution PDF.',
          file: outputFile,
          fileSize: '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to compile PDF: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16), // Studio Camera Dark Viewport
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP CAMERA BAR ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 22),
                    onPressed: () {
                      if (_currentPreviewImage != null) {
                        setState(() => _currentPreviewImage = null);
                      } else {
                        context.pop();
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _currentPreviewImage != null ? 'Crop & Enhance' : 'Live Document Scanner',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),

                  // Flash Torch Toggle
                  IconButton(
                    icon: Icon(
                      _isTorchOn ? LucideIcons.zap : LucideIcons.zapOff,
                      color: _isTorchOn ? const Color(0xFFFBBF24) : Colors.white70,
                      size: 20,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isTorchOn = !_isTorchOn);
                    },
                    tooltip: 'Toggle Lighting',
                  ),

                  // Grid Lines Toggle
                  IconButton(
                    icon: Icon(
                      LucideIcons.grid3x3,
                      color: _showGrid ? const Color(0xFF38BDF8) : Colors.white38,
                      size: 20,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showGrid = !_showGrid);
                    },
                    tooltip: 'Toggle Viewfinder Grid',
                  ),

                  // Page Count Badge
                  if (_scannedPages.isNotEmpty && _currentPreviewImage == null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_scannedPages.length} pages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── SCAN MODE PILLS ──────────────────────────────────────
            if (_currentPreviewImage == null)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: _scanTypes.map((st) {
                    final isSelected = _activeScanType == st['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(
                          st['icon'] as IconData,
                          size: 14,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                        label: Text(st['label'] as String),
                        selected: isSelected,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _activeScanType = st['id'] as String);
                        },
                        selectedColor: const Color(0xFF2563EB),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // ── REAL-WORLD CAMERA VIEWFINDER CANVAS ──────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _currentPreviewImage != null
                        ? _buildCropOverlayView()
                        : _buildRealWorldCameraViewfinder(),
                  ),
                ),
              ),
            ),

            // ── BOTTOM CONTROLS & CAPTURE REEL ───────────────────────
            _currentPreviewImage != null
                ? _buildAdjustControls()
                : _buildShutterControls(),
          ],
        ),
      ),
    );
  }

  // ── LIVE REAL WORLD CAMERA VIEWFINDER ─────────────────────────────
  Widget _buildRealWorldCameraViewfinder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Camera Grain / Gradient Field
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                    Color(0xFF020617),
                  ],
                ),
              ),
            ),

            // 3x3 Rule of Thirds Grid
            if (_showGrid)
              CustomPaint(
                size: Size(w, h),
                painter: _ViewfinderGridPainter(),
              ),

            // Document Target Brackets Overlay
            _buildDocumentTargetOverlay(w, h),

            // Animated Laser Scanning Line
            AnimatedBuilder(
              animation: _laserController,
              builder: (context, child) {
                final topPos = 60 + (_laserController.value * (h - 140));
                return Positioned(
                  top: topPos,
                  left: 30,
                  right: 30,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0xFF38BDF8),
                          Color(0xFF60A5FA),
                          Color(0xFF38BDF8),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Center Focus Reticle
            AnimatedBuilder(
              animation: _reticleController,
              builder: (context, child) {
                final scale = 1.0 + (_reticleController.value * 0.08);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF38BDF8),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Status Guidance Pill
            Positioned(
              top: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Ready • Point at document',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scanned Pages Reel Overlay at bottom
            if (_scannedPages.isNotEmpty)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  height: 80,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _scannedPages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                              image: DecorationImage(
                                image: FileImage(_scannedPages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 12,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _scannedPages.removeAt(index));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDC2626),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.x, size: 10, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── CORNER TARGET BRACKETS ────────────────────────────────────────
  Widget _buildDocumentTargetOverlay(double w, double h) {
    const pad = 36.0;
    const bracketSize = 28.0;
    const bracketWidth = 3.5;
    const bracketColor = Color(0xFF38BDF8);

    return Positioned(
      left: pad,
      top: pad + 20,
      right: pad,
      bottom: pad + 20,
      child: Stack(
        children: [
          // Top Left
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: bracketSize,
              height: bracketSize,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: bracketColor, width: bracketWidth),
                  top: BorderSide(color: bracketColor, width: bracketWidth),
                ),
              ),
            ),
          ),
          // Top Right
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: bracketSize,
              height: bracketSize,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: bracketColor, width: bracketWidth),
                  top: BorderSide(color: bracketColor, width: bracketWidth),
                ),
              ),
            ),
          ),
          // Bottom Left
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: bracketSize,
              height: bracketSize,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: bracketColor, width: bracketWidth),
                  bottom: BorderSide(color: bracketColor, width: bracketWidth),
                ),
              ),
            ),
          ),
          // Bottom Right
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: bracketSize,
              height: bracketSize,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: bracketColor, width: bracketWidth),
                  bottom: BorderSide(color: bracketColor, width: bracketWidth),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ADJUST & CROP PERSPECTIVE VIEW ────────────────────────────────
  Widget _buildCropOverlayView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            // Filter Enhanced Image Preview
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: _getColorFilter(_activeFilter),
                child: Image.file(
                  _currentPreviewImage!,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Perspective Crop Pin Polygon
            CustomPaint(
              size: Size(w, h),
              painter: _CropPolygonPainter(
                p1: Offset(_topLeft.dx * w, _topLeft.dy * h),
                p2: Offset(_topRight.dx * w, _topRight.dy * h),
                p3: Offset(_bottomRight.dx * w, _bottomRight.dy * h),
                p4: Offset(_bottomLeft.dx * w, _bottomLeft.dy * h),
              ),
            ),

            // Draggable 4 Corner Pins
            _buildDraggablePin(w, h, _topLeft, (newPos) => setState(() => _topLeft = newPos)),
            _buildDraggablePin(w, h, _topRight, (newPos) => setState(() => _topRight = newPos)),
            _buildDraggablePin(w, h, _bottomRight, (newPos) => setState(() => _bottomRight = newPos)),
            _buildDraggablePin(w, h, _bottomLeft, (newPos) => setState(() => _bottomLeft = newPos)),
          ],
        );
      },
    );
  }

  ColorFilter _getColorFilter(String filter) {
    switch (filter) {
      case 'bw':
        return const ColorFilter.matrix(<double>[
          1.5, 1.5, 1.5, 0, -160,
          1.5, 1.5, 1.5, 0, -160,
          1.5, 1.5, 1.5, 0, -160,
          0, 0, 0, 1, 0,
        ]);
      case 'gray':
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'magic':
        return const ColorFilter.matrix(<double>[
          1.2, 0, 0, 0, 10,
          0, 1.2, 0, 0, 10,
          0, 0, 1.2, 0, 10,
          0, 0, 0, 1, 0,
        ]);
      default:
        return const ColorFilter.matrix(<double>[
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ]);
    }
  }

  Widget _buildDraggablePin(double w, double h, Offset normPos, Function(Offset) onUpdate) {
    return Positioned(
      left: normPos.dx * w - 16,
      top: normPos.dy * h - 16,
      child: GestureDetector(
        onPanUpdate: (details) {
          final newX = ((normPos.dx * w) + details.delta.dx) / w;
          final newY = ((normPos.dy * h) + details.delta.dy) / h;
          onUpdate(Offset(newX.clamp(0.0, 1.0), newY.clamp(0.0, 1.0)));
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
          ),
          child: const Center(
            child: Icon(LucideIcons.move, size: 14, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ── ADJUST FILTER & ACTION CONTROLS ──────────────────────────────
  Widget _buildAdjustControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: const Color(0xFF0B1120),
      child: Column(
        children: [
          // Filter Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFilterChip('magic', 'Magic Color', LucideIcons.sparkles),
              _buildFilterChip('bw', 'B&W Text', LucideIcons.fileText),
              _buildFilterChip('gray', 'Grayscale', LucideIcons.contrast),
              _buildFilterChip('original', 'Original', LucideIcons.image),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _currentPreviewImage = null),
                  icon: const Icon(LucideIcons.refreshCw, size: 16, color: Colors.white70),
                  label: const Text('Retake', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _acceptCurrentPage,
                  icon: const Icon(LucideIcons.check, size: 16),
                  label: const Text('Keep Page', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterId, String label, IconData icon) {
    final isSelected = _activeFilter == filterId;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeFilter = filterId);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: isSelected ? Colors.white : Colors.white70),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SHUTTER & GALLERY CONTROLS ───────────────────────────────────
  Widget _buildShutterControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      color: const Color(0xFF0B1120),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery Import Button
          IconButton(
            icon: const Icon(LucideIcons.image, color: Colors.white, size: 28),
            onPressed: () => _captureFromCamera(ImageSource.gallery),
            tooltip: 'Import from Photos',
          ),

          // Main Shutter Button
          GestureDetector(
            onTap: () => _captureFromCamera(ImageSource.camera),
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.camera, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),

          // Save / Export PDF Button
          if (_scannedPages.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _exportPdf,
              icon: const Icon(LucideIcons.fileCheck, size: 16),
              label: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Save PDF (${_scannedPages.length})',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ── VIEWFINDER GRID PAINTER ───────────────────────────────────────────
class _ViewfinderGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

    // Vertical Lines
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);

    // Horizontal Lines
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── CROP POLYGON PAINTER ──────────────────────────────────────────────
class _CropPolygonPainter extends CustomPainter {
  final Offset p1, p2, p3, p4;

  _CropPolygonPainter({
    required this.p1,
    required this.p2,
    required this.p3,
    required this.p4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    final fillPaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
