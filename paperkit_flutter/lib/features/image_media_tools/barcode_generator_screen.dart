import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/services/share_service.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class BarcodeGeneratorScreen extends StatefulWidget {
  const BarcodeGeneratorScreen({super.key});

  @override
  State<BarcodeGeneratorScreen> createState() => _BarcodeGeneratorScreenState();
}

class _BarcodeGeneratorScreenState extends State<BarcodeGeneratorScreen> {
  final TextEditingController _codeController = TextEditingController(text: 'PAPERKIT-89412');
  bool _isGenerating = false;
  File? _barcodeFile;

  Future<void> _generateBarcode() async {
    final text = _codeController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isGenerating = true);

    try {
      const double imageWidth = 400;
      const double imageHeight = 160;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, imageWidth, imageHeight));

      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, imageWidth, imageHeight), bgPaint);

      final barPaint = Paint()..color = Colors.black;

      // Deterministic Barcode Encoding algorithm based on character hash values
      final charCodes = text.codeUnits;
      double xOffset = 30.0;

      for (int i = 0; i < charCodes.length; i++) {
        final val = charCodes[i];
        final pattern = [
          (val & 1) != 0,
          (val & 2) != 0,
          (val & 4) != 0,
          (val & 8) != 0,
          (val & 16) != 0,
          true,
          false,
        ];

        for (final isBar in pattern) {
          final barWidth = isBar ? 3.0 : 1.5;
          if (isBar) {
            canvas.drawRect(Rect.fromLTWH(xOffset, 20, barWidth, 90), barPaint);
          }
          xOffset += barWidth + 1.5;
          if (xOffset > imageWidth - 40) break;
        }
      }

      // Draw label text beneath barcode
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset((imageWidth - textPainter.width) / 2, 120));

      final picture = recorder.endRecording();
      final img = await picture.toImage(imageWidth.toInt(), imageHeight.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        final tempDir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${tempDir.path}/barcode_$timestamp.png');
        await file.writeAsBytes(bytes);

        setState(() {
          _barcodeFile = file;
          _isGenerating = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barcode generated successfully!')),
          );
        }
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Barcode Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Barcode Studio',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Barcode Code / SKU',
                      hintText: 'e.g. PAPERKIT-89412',
                      prefixIcon: Icon(LucideIcons.barcode, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    label: 'Generate Barcode PNG',
                    icon: LucideIcons.barcode,
                    isLoading: _isGenerating,
                    onPressed: _generateBarcode,
                  ),
                ],
              ),
            ),
          ),
          if (_barcodeFile != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Image.file(_barcodeFile!, height: 120),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => ShareService.shareFile(filePath: _barcodeFile!.path),
                          icon: const Icon(LucideIcons.share2),
                          label: const Text('Share Barcode'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => OpenFilex.open(_barcodeFile!.path),
                          icon: const Icon(LucideIcons.externalLink),
                          label: const Text('Open Image'),
                        ),
                      ],
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
}
