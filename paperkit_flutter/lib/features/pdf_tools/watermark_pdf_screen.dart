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
import '../../core/services/pdf_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class WatermarkPDFScreen extends StatefulWidget {
  const WatermarkPDFScreen({super.key});

  @override
  State<WatermarkPDFScreen> createState() => _WatermarkPDFScreenState();
}

class _WatermarkPDFScreenState extends State<WatermarkPDFScreen> {
  File? _selectedFile;
  final TextEditingController _watermarkController = TextEditingController(text: 'CONFIDENTIAL');
  double _opacity = 0.3;
  double _fontSize = 40;
  double _angle = -45;
  bool _isProcessing = false;
  File? _watermarkedResult;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _watermarkedResult = null;
      });
    }
  }

  Future<void> _applyWatermark() async {
    if (_selectedFile == null || _watermarkController.text.trim().isEmpty) return;
    setState(() => _isProcessing = true);

    try {
      final outputFile = await PdfEngine.addWatermark(
        inputFile: _selectedFile!,
        watermarkText: _watermarkController.text.trim(),
        opacity: _opacity,
        fontSize: _fontSize,
        angle: _angle,
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = outputFile.uri.pathSegments.last;

      final doc = DocumentFile(
        id: 'wm_$timestamp',
        name: fileName,
        path: outputFile.path,
        size: await outputFile.length(),
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.pdf,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'watermark',
                toolName: 'Watermark PDF',
                fileName: fileName,
                outputPath: outputFile.path,
                fileSize: await outputFile.length(),
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _watermarkedResult = outputFile;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Watermark applied successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Watermarking failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Watermark PDF',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              children: [
                if (_selectedFile == null)
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(LucideIcons.filePlus, size: 20),
                      label: const Text('Choose PDF Document'),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.toolTeal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.stamp, color: AppColors.toolTeal, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _selectedFile!.uri.pathSegments.last,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
            TextField(
              controller: _watermarkController,
              decoration: const InputDecoration(
                labelText: 'Watermark Text',
                hintText: 'e.g. CONFIDENTIAL, DRAFT, SAMPLE',
                prefixIcon: Icon(LucideIcons.type, size: 18),
              ),
            ),
            const SizedBox(height: 16),

            Text('Opacity: ${(_opacity * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            Slider(
              value: _opacity,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              onChanged: (val) => setState(() => _opacity = val),
            ),
            const SizedBox(height: 10),

            Text('Font Size: ${_fontSize.toInt()} pt', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            Slider(
              value: _fontSize,
              min: 20,
              max: 80,
              divisions: 12,
              onChanged: (val) => setState(() => _fontSize = val),
            ),
            const SizedBox(height: 20),

            ActionButton(
              label: 'Apply Watermark',
              icon: LucideIcons.stamp,
              isLoading: _isProcessing,
              onPressed: _applyWatermark,
            ),
          ],

          if (_watermarkedResult != null) ...[
            const SizedBox(height: 20),
            ActionButton(
              label: 'Open Watermarked PDF',
              icon: LucideIcons.externalLink,
              isSecondary: true,
              onPressed: () => OpenFilex.open(_watermarkedResult!.path),
            ),
          ],
        ],
      ),
    );
  }
}
