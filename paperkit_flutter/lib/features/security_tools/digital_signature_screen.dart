import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/pdf_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/file_success_dialog.dart';

enum SignatureCreationMode { draw, type, upload }

class DigitalSignatureScreen extends StatefulWidget {
  const DigitalSignatureScreen({super.key});

  @override
  State<DigitalSignatureScreen> createState() => _DigitalSignatureScreenState();
}

class _DigitalSignatureScreenState extends State<DigitalSignatureScreen> {
  File? _selectedFile;
  int _totalPages = 1;
  int _currentPageIndex = 0; // 0-indexed
  Size _docPageSize = const Size(595.28, 841.89);

  SignatureCreationMode _signatureMode = SignatureCreationMode.draw;

  // Drawing Pad State
  final List<List<Offset>> _drawStrokes = [];
  List<Offset> _currentStroke = [];
  Color _drawColor = const Color(0xFF1E3A8A); // Classic ink blue
  double _drawStrokeWidth = 3.0;

  // Type Signature State
  final TextEditingController _typedNameController = TextEditingController(text: 'John Doe');
  final TextEditingController _typedReasonController = TextEditingController(text: 'Approved & Verified');
  bool _includeDateBadge = true;

  // Uploaded Signature State
  Uint8List? _uploadedSignatureBytes;

  // Extracted text spans per page
  final Map<int, List<PdfExistingTextSpan>> _pageTextSpans = {};
  bool _isLoadingSpans = false;

  // Placement Position (Normalized: 0.0 to 1.0)
  Offset _signatureNormalizedPos = const Offset(0.55, 0.78); // Default bottom right
  double _signatureScale = 0.32; // Width relative to page width (32%)
  final double _signatureAspectRatio = 2.4; // Width / Height

  bool _isProcessing = false;

  Future<void> _pickPdfFile() async {
    HapticFeedback.lightImpact();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      try {
        final bytes = await file.readAsBytes();
        final doc = PdfDocument(inputBytes: bytes);
        final count = doc.pages.count;
        final pSize = count > 0 ? doc.pages[0].size : const Size(595.28, 841.89);
        doc.dispose();

        setState(() {
          _selectedFile = file;
          _totalPages = count > 0 ? count : 1;
          _currentPageIndex = 0;
          _docPageSize = Size(pSize.width, pSize.height);
          _pageTextSpans.clear();
        });

        await _loadPageSpans(0);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to read PDF: $e')),
          );
        }
      }
    }
  }

  Future<void> _loadPageSpans(int pageIndex) async {
    if (_selectedFile == null) return;
    if (_pageTextSpans.containsKey(pageIndex)) return;

    setState(() => _isLoadingSpans = true);
    try {
      final spans = await PdfEngine.extractPageTextSpans(
        inputFile: _selectedFile!,
        pageIndex: pageIndex,
      );
      if (mounted) {
        setState(() {
          _pageTextSpans[pageIndex] = spans;
          _isLoadingSpans = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSpans = false);
      }
    }
  }

  void _onPageChanged(int newPageIndex) {
    if (newPageIndex >= 0 && newPageIndex < _totalPages) {
      setState(() {
        _currentPageIndex = newPageIndex;
      });
      _loadPageSpans(newPageIndex);
    }
  }

  Future<void> _pickSignatureImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _uploadedSignatureBytes = bytes;
        _signatureMode = SignatureCreationMode.upload;
      });
    }
  }

  Future<Uint8List> _renderSignatureToPng() async {
    const renderWidth = 600.0;
    final renderHeight = renderWidth / _signatureAspectRatio;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, renderWidth, renderHeight));

    if (_signatureMode == SignatureCreationMode.draw && _drawStrokes.isNotEmpty) {
      // Scale drawn strokes to fit render canvas
      final paint = Paint()
        ..color = _drawColor
        ..strokeWidth = _drawStrokeWidth * 2.2
        ..strokeCap = ui.StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round
        ..style = PaintingStyle.stroke;

      // Find bounding box of drawn strokes to normalize & center
      double minX = double.infinity, minY = double.infinity, maxX = 0, maxY = 0;
      for (final stroke in _drawStrokes) {
        for (final pt in stroke) {
          if (pt.dx < minX) minX = pt.dx;
          if (pt.dy < minY) minY = pt.dy;
          if (pt.dx > maxX) maxX = pt.dx;
          if (pt.dy > maxY) maxY = pt.dy;
        }
      }

      final padW = (maxX - minX).clamp(10.0, 1000.0);
      final padH = (maxY - minY).clamp(10.0, 1000.0);
      final scaleX = (renderWidth * 0.85) / padW;
      final scaleY = (renderHeight * 0.75) / padH;
      final scale = scaleX < scaleY ? scaleX : scaleY;

      final offsetX = (renderWidth - padW * scale) / 2 - minX * scale;
      final offsetY = (renderHeight - padH * scale) / 2 - minY * scale;

      for (final stroke in _drawStrokes) {
        if (stroke.length < 2) continue;
        final path = Path();
        path.moveTo(stroke[0].dx * scale + offsetX, stroke[0].dy * scale + offsetY);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx * scale + offsetX, stroke[i].dy * scale + offsetY);
        }
        canvas.drawPath(path, paint);
      }
    } else if (_signatureMode == SignatureCreationMode.upload && _uploadedSignatureBytes != null) {
      final codec = await ui.instantiateImageCodec(_uploadedSignatureBytes!);
      final frame = await codec.getNextFrame();
      final img = frame.image;
      paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(0, 0, renderWidth, renderHeight),
        image: img,
        fit: BoxFit.contain,
      );
    } else {
      // Type Script Mode (Render signature typography + verification metadata)
      final name = _typedNameController.text.trim().isEmpty ? 'Signature' : _typedNameController.text.trim();
      final reason = _typedReasonController.text.trim();
      final dateStr = DateTime.now().toIso8601String().substring(0, 10);

      // 1. Script Signature Text
      final textPainter = TextPainter(
        text: TextSpan(
          text: name,
          style: GoogleFonts.dancingScript(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: renderWidth);
      textPainter.paint(canvas, const Offset(16, 12));

      // 2. Metadata Subtext & Verification Badge
      if (_includeDateBadge) {
        final linePaint = Paint()
          ..color = const Color(0xFF94A3B8)
          ..strokeWidth = 1.5;
        canvas.drawLine(const Offset(16, 80), Offset(renderWidth - 16, 80), linePaint);

        final metaPainter = TextPainter(
          text: TextSpan(
            text: 'Digitally Signed by $name\nDate: $dateStr • Reason: $reason',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
              height: 1.35,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: renderWidth - 32);
        metaPainter.paint(canvas, const Offset(16, 92));
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(renderWidth.toInt(), renderHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _applyDigitalSignature() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      final sigPngBytes = await _renderSignatureToPng();
      final stampHeightNormalized = _signatureScale / _signatureAspectRatio * (_docPageSize.width / _docPageSize.height);

      final normalizedRect = Rect.fromLTWH(
        _signatureNormalizedPos.dx.clamp(0.0, 1.0 - _signatureScale),
        _signatureNormalizedPos.dy.clamp(0.0, 1.0 - stampHeightNormalized),
        _signatureScale,
        stampHeightNormalized,
      );

      final outputFile = await PdfEngine.stampSignatureOnPdf(
        inputFile: _selectedFile!,
        signaturePngBytes: sigPngBytes,
        pageIndex: _currentPageIndex,
        normalizedRect: normalizedRect,
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = outputFile.uri.pathSegments.last;
      final fileSize = await outputFile.length();

      final doc = DocumentFile(
        id: 'sign_$timestamp',
        name: fileName,
        path: outputFile.path,
        size: fileSize,
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.pdf,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'digital-sign',
                toolName: 'Digital Signature (Page ${_currentPageIndex + 1})',
                fileName: fileName,
                outputPath: outputFile.path,
                fileSize: fileSize,
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _isProcessing = false;
        });

        FileSuccessDialog.show(
          context,
          title: 'Document Signed Successfully!',
          message: 'Your signature has been burned at the exact coordinates on Page ${_currentPageIndex + 1}.',
          file: outputFile,
          fileSize: '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signing failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Digital Signature & Stamp',
      showBottomNav: false,
      child: _selectedFile == null ? _buildEmptyState(isDark) : _buildSigningStudio(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.toolIndigo.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.fileSignature, size: 48, color: AppColors.toolIndigo),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select PDF to Sign & Place Stamp',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Draw your signature, type script, or upload an image. Drag and place it anywhere on any page.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickPdfFile,
              icon: const Icon(LucideIcons.uploadCloud, size: 18),
              label: const Text('Choose PDF Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSigningStudio(bool isDark) {
    return Column(
      children: [
        // Top Page Navigation Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.fileSignature, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      _selectedFile!.uri.pathSegments.last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft, size: 18),
                    onPressed: _currentPageIndex > 0 ? () => _onPageChanged(_currentPageIndex - 1) : null,
                  ),
                  Text(
                    'Page ${_currentPageIndex + 1} of $_totalPages',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.primary),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.chevronRight, size: 18),
                    onPressed: _currentPageIndex < _totalPages - 1 ? () => _onPageChanged(_currentPageIndex + 1) : null,
                  ),
                  TextButton(onPressed: _pickPdfFile, child: const Text('Change')),
                ],
              ),
            ],
          ),
        ),

        // Interactive Placement Canvas
        Expanded(
          child: Container(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            padding: const EdgeInsets.all(12),
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final pageAspect = _docPageSize.height / (_docPageSize.width > 0 ? _docPageSize.width : 595.28);
                  final maxW = constraints.maxWidth;
                  final maxH = constraints.maxHeight;

                  double canvasW = maxW;
                  double canvasH = canvasW * pageAspect;
                  if (canvasH > maxH) {
                    canvasH = maxH;
                    canvasW = canvasH / pageAspect;
                  }

                  final sigW = canvasW * _signatureScale;
                  final sigH = sigW / _signatureAspectRatio;

                  final sigLeft = (_signatureNormalizedPos.dx * canvasW).clamp(0.0, canvasW - sigW);
                  final sigTop = (_signatureNormalizedPos.dy * canvasH).clamp(0.0, canvasH - sigH);

                  return Container(
                    width: canvasW,
                    height: canvasH,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // 1. True Page Rendering Canvas (Extracted Document Text Layout)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CustomPaint(
                              painter: _DigitalSignaturePagePainter(
                                docPageSize: _docPageSize,
                                existingSpans: _pageTextSpans[_currentPageIndex] ?? [],
                              ),
                            ),
                          ),
                        ),

                        // 2. Tap detector to reposition
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapDown: (details) {
                            final normX = (details.localPosition.dx - sigW / 2) / canvasW;
                            final normY = (details.localPosition.dy - sigH / 2) / canvasH;
                            setState(() {
                              _signatureNormalizedPos = Offset(
                                normX.clamp(0.0, 1.0 - _signatureScale),
                                normY.clamp(0.0, 1.0 - (sigH / canvasH)),
                              );
                            });
                          },
                        ),

                        // Loading Indicator
                        if (_isLoadingSpans)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                  SizedBox(width: 6),
                                  Text('Loading Layout...', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),

                        // 3. Draggable & Resizable Signature Overlay
                        Positioned(
                          left: sigLeft,
                          top: sigTop,
                          width: sigW,
                          height: sigH,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              final newNormX = (_signatureNormalizedPos.dx + details.delta.dx / canvasW).clamp(0.0, 1.0 - _signatureScale);
                              final newNormY = (_signatureNormalizedPos.dy + details.delta.dy / canvasH).clamp(0.0, 1.0 - (sigH / canvasH));
                              setState(() {
                                _signatureNormalizedPos = Offset(newNormX, newNormY);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                border: Border.all(color: AppColors.primary, width: 1.8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Stack(
                                children: [
                                  Center(child: _buildSignaturePreviewWidget()),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                      child: const Icon(LucideIcons.move, size: 10, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Bottom Controls (Signature Creator & Size Slider)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mode Selector & Resize Slider Row
              Row(
                children: [
                  SegmentedButton<SignatureCreationMode>(
                    segments: const [
                      ButtonSegment(value: SignatureCreationMode.draw, icon: Icon(LucideIcons.penTool, size: 14), label: Text('Draw')),
                      ButtonSegment(value: SignatureCreationMode.type, icon: Icon(LucideIcons.type, size: 14), label: Text('Type')),
                      ButtonSegment(value: SignatureCreationMode.upload, icon: Icon(LucideIcons.image, size: 14), label: Text('Image')),
                    ],
                    selected: {_signatureMode},
                    onSelectionChanged: (val) {
                      setState(() => _signatureMode = val.first);
                      if (val.first == SignatureCreationMode.upload && _uploadedSignatureBytes == null) {
                        _pickSignatureImage();
                      }
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.primary,
                      selectedForegroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  const Text('Size: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  SizedBox(
                    width: 100,
                    child: Slider(
                      value: _signatureScale,
                      min: 0.15,
                      max: 0.65,
                      onChanged: (val) => setState(() => _signatureScale = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Creation Mode Sheet
              if (_signatureMode == SignatureCreationMode.draw) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Draw your signature below:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.undo, size: 16),
                          tooltip: 'Undo',
                          visualDensity: VisualDensity.compact,
                          onPressed: _drawStrokes.isNotEmpty
                              ? () => setState(() => _drawStrokes.removeLast())
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                          tooltip: 'Clear',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() => _drawStrokes.clear()),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _currentStroke = [details.localPosition];
                        _drawStrokes.add(_currentStroke);
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _currentStroke.add(details.localPosition);
                      });
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CustomPaint(
                        painter: _SignatureDrawingPainter(
                          strokes: _drawStrokes,
                          color: _drawColor,
                          strokeWidth: _drawStrokeWidth,
                        ),
                        child: Container(),
                      ),
                    ),
                  ),
                ),
              ] else if (_signatureMode == SignatureCreationMode.type) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _typedNameController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Signer Name',
                          prefixIcon: Icon(LucideIcons.user, size: 16),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _typedReasonController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Reason',
                          prefixIcon: Icon(LucideIcons.checkCircle2, size: 16),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickSignatureImage,
                      icon: const Icon(LucideIcons.image, size: 16),
                      label: Text(_uploadedSignatureBytes != null ? 'Change Image' : 'Upload Image'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _uploadedSignatureBytes != null ? 'Signature image loaded' : 'No signature image selected',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              // Burn & Apply Button
              ActionButton(
                label: 'Stamp Signature on Page ${_currentPageIndex + 1}',
                icon: LucideIcons.fileCheck,
                isLoading: _isProcessing,
                onPressed: _applyDigitalSignature,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignaturePreviewWidget() {
    if (_signatureMode == SignatureCreationMode.draw && _drawStrokes.isNotEmpty) {
      return CustomPaint(
        painter: _SignatureDrawingPainter(
          strokes: _drawStrokes,
          color: _drawColor,
          strokeWidth: 2.0,
        ),
        child: Container(),
      );
    } else if (_signatureMode == SignatureCreationMode.upload && _uploadedSignatureBytes != null) {
      return Image.memory(_uploadedSignatureBytes!, fit: BoxFit.contain);
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _typedNameController.text.trim().isEmpty ? 'Sign Here' : _typedNameController.text.trim(),
            style: GoogleFonts.dancingScript(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          if (_includeDateBadge)
            Text(
              '${DateTime.now().toIso8601String().substring(0, 10)} • Verified',
              style: const TextStyle(fontSize: 7.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
        ],
      );
    }
  }
}

class _SignatureDrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color color;
  final double strokeWidth;

  _SignatureDrawingPainter({
    required this.strokes,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path();
      path.moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignatureDrawingPainter oldDelegate) => true;
}

class _DigitalSignaturePagePainter extends CustomPainter {
  final Size docPageSize;
  final List<PdfExistingTextSpan> existingSpans;

  _DigitalSignaturePagePainter({
    required this.docPageSize,
    required this.existingSpans,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Document Background
    final pageBgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), pageBgPaint);

    // Calculate viewport font scale relative to true document page width
    final docWidth = docPageSize.width > 0 ? docPageSize.width : 595.28;
    final fontScale = (size.width / docWidth).clamp(0.1, 4.0);

    // 2. Render Existing Extracted Text Spans (Words)
    for (final span in existingSpans) {
      final rect = Rect.fromLTWH(
        span.normalizedRect.left * size.width,
        span.normalizedRect.top * size.height,
        span.normalizedRect.width * size.width,
        span.normalizedRect.height * size.height,
      );

      final scaledFontSize = (span.fontSize * fontScale).clamp(4.0, 72.0);

      final tp = TextPainter(
        text: TextSpan(
          text: span.currentText,
          style: TextStyle(
            color: span.color,
            fontSize: scaledFontSize,
            fontWeight: span.isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: span.isItalic ? FontStyle.italic : FontStyle.normal,
            fontFamilyFallback: span.flutterFontFamilyFallback,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: (size.width - rect.left).clamp(10.0, size.width));

      tp.paint(canvas, rect.topLeft);
    }
  }

  @override
  bool shouldRepaint(covariant _DigitalSignaturePagePainter oldDelegate) =>
      oldDelegate.existingSpans != existingSpans || oldDelegate.docPageSize != docPageSize;
}
