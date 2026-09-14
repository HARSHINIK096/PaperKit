import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/image_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class ImageEnhancerScreen extends StatefulWidget {
  const ImageEnhancerScreen({super.key});

  @override
  State<ImageEnhancerScreen> createState() => _ImageEnhancerScreenState();
}

class _ImageEnhancerScreenState extends State<ImageEnhancerScreen> {
  File? _selectedFile;
  bool _isEnhancing = false;
  File? _enhancedResult;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _enhancedResult = null;
      });
    }
  }

  Future<void> _enhanceImage() async {
    if (_selectedFile == null) return;
    setState(() => _isEnhancing = true);

    try {
      // Apply contrast, brightness, and sharpness filters
      final outputFile = await ImageEngine.manipulateImage(
        inputFile: _selectedFile!,
        brightness: 1.1,
        contrast: 1.25,
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Enhanced_${_selectedFile!.uri.pathSegments.last}';

      final doc = DocumentFile(
        id: 'enhance_$timestamp',
        name: fileName,
        path: outputFile.path,
        size: await outputFile.length(),
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.image,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'image-enhancer',
                toolName: 'AI Image Enhancer',
                fileName: fileName,
                outputPath: outputFile.path,
                fileSize: await outputFile.length(),
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _enhancedResult = outputFile;
          _isEnhancing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image enhanced with AI clarity filter!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEnhancing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enhancement failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'AI Image Enhancer',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              children: [
                if (_selectedFile == null)
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(LucideIcons.imagePlus, size: 20),
                      label: const Text('Choose Image to Enhance'),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(image: FileImage(_selectedFile!), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(_selectedFile!.uri.pathSegments.last, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      TextButton(onPressed: _pickFile, child: const Text('Change')),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_selectedFile != null) ...[
            ActionButton(
              label: 'Enhance Clarity & Upscale',
              icon: LucideIcons.sparkles,
              isLoading: _isEnhancing,
              onPressed: _enhanceImage,
            ),
          ],

          if (_enhancedResult != null) ...[
            const SizedBox(height: 20),
            ActionButton(
              label: 'Open Enhanced Image',
              icon: LucideIcons.externalLink,
              isSecondary: true,
              onPressed: () => OpenFilex.open(_enhancedResult!.path),
            ),
          ],
        ],
      ),
    );
  }
}
