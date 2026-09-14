import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/services/share_service.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class ImageResizerScreen extends StatefulWidget {
  const ImageResizerScreen({super.key});

  @override
  State<ImageResizerScreen> createState() => _ImageResizerScreenState();
}

class _ImageResizerScreenState extends State<ImageResizerScreen> {
  File? _selectedFile;
  int _origWidth = 0;
  int _origHeight = 0;

  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  bool _maintainAspectRatio = true;
  bool _isProcessing = false;
  File? _outputFile;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);

      setState(() {
        _selectedFile = file;
        _origWidth = decoded?.width ?? 800;
        _origHeight = decoded?.height ?? 600;
        _widthController.text = '${(_origWidth * 0.5).round()}';
        _heightController.text = '${(_origHeight * 0.5).round()}';
        _outputFile = null;
      });
    }
  }

  void _scaleByPercent(double percent) {
    if (_origWidth <= 0) return;
    final w = (_origWidth * percent).round();
    final h = (_origHeight * percent).round();
    setState(() {
      _widthController.text = '$w';
      _heightController.text = '$h';
    });
  }

  Future<void> _resizeImage() async {
    if (_selectedFile == null) return;
    final targetW = int.tryParse(_widthController.text.trim()) ?? _origWidth;
    final targetH = int.tryParse(_heightController.text.trim()) ?? _origHeight;

    if (targetW <= 0 || targetH <= 0) return;

    setState(() => _isProcessing = true);

    try {
      final bytes = await _selectedFile!.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('Unable to decode image.');

      img.Image resized;
      if (_maintainAspectRatio) {
        resized = img.copyResize(decoded, width: targetW);
      } else {
        resized = img.copyResize(decoded, width: targetW, height: targetH);
      }

      final encodedBytes = img.encodePng(resized);
      final tempDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFile = File('${tempDir.path}/resized_$timestamp.png');
      await outputFile.writeAsBytes(encodedBytes);

      setState(() {
        _outputFile = outputFile;
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resized image to ${resized.width}x${resized.height} px!')),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Resizing Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Image Dimensional Resizer',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_selectedFile == null)
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(LucideIcons.imagePlus),
                      label: const Text('Select Image to Resize'),
                    )
                  else ...[
                    Row(
                      children: [
                        const Icon(LucideIcons.image, color: Colors.purple),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedFile!.uri.pathSegments.last, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Original: ${_origWidth}x$_origHeight px', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        TextButton(onPressed: _pickImage, child: const Text('Change')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _widthController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Width (px)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Height (px)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ActionChip(label: const Text('25%'), onPressed: () => _scaleByPercent(0.25)),
                        ActionChip(label: const Text('50%'), onPressed: () => _scaleByPercent(0.50)),
                        ActionChip(label: const Text('75%'), onPressed: () => _scaleByPercent(0.75)),
                        ActionChip(label: const Text('200%'), onPressed: () => _scaleByPercent(2.00)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ActionButton(
                      label: 'Resize Image',
                      icon: LucideIcons.scaling,
                      isLoading: _isProcessing,
                      onPressed: _resizeImage,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_outputFile != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Image.file(_outputFile!, height: 180),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => ShareService.shareFile(filePath: _outputFile!.path),
                          icon: const Icon(LucideIcons.share2),
                          label: const Text('Share'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => OpenFilex.open(_outputFile!.path),
                          icon: const Icon(LucideIcons.externalLink),
                          label: const Text('Open'),
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
