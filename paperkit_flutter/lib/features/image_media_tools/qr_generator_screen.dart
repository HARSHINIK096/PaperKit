import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr/qr.dart';
import '../../core/services/share_service.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final TextEditingController _dataController = TextEditingController(text: 'https://paperkit.app');
  bool _isGenerating = false;
  File? _qrFile;

  Future<void> _generateQrCode() async {
    final text = _dataController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isGenerating = true);

    try {
      final qrCode = QrCode.fromData(
        data: text,
        errorCorrectLevel: QrErrorCorrectLevel.M,
      );
      final qrImage = QrImage(qrCode);

      final int moduleCount = qrImage.moduleCount;
      const double moduleSize = 12.0;
      final double imageSize = moduleCount * moduleSize + 40;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, imageSize, imageSize));

      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, imageSize, imageSize), bgPaint);

      final fgPaint = Paint()..color = Colors.black;

      for (int x = 0; x < moduleCount; x++) {
        for (int y = 0; y < moduleCount; y++) {
          if (qrImage.isDark(y, x)) {
            final rect = Rect.fromLTWH(
              20 + x * moduleSize,
              20 + y * moduleSize,
              moduleSize,
              moduleSize,
            );
            canvas.drawRect(rect, fgPaint);
          }
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(imageSize.toInt(), imageSize.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        final tempDir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${tempDir.path}/qrcode_$timestamp.png');
        await file.writeAsBytes(bytes);

        setState(() {
          _qrFile = file;
          _isGenerating = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR Code generated successfully!')),
          );
        }
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('QR Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'QR Code Studio',
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
                    controller: _dataController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'QR Content (URL, Text, Contact)',
                      hintText: 'e.g. https://paperkit.app',
                      prefixIcon: Icon(LucideIcons.qrCode, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    label: 'Generate QR Code PNG',
                    icon: LucideIcons.qrCode,
                    isLoading: _isGenerating,
                    onPressed: _generateQrCode,
                  ),
                ],
              ),
            ),
          ),
          if (_qrFile != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Image.file(_qrFile!, height: 220),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => ShareService.shareFile(filePath: _qrFile!.path),
                          icon: const Icon(LucideIcons.share2),
                          label: const Text('Share QR'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => OpenFilex.open(_qrFile!.path),
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
