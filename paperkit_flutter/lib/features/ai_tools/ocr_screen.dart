import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/pdf_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/markdown_viewer.dart';

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  File? _selectedFile;
  bool _isProcessing = false;
  String _extractedText = '';

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _extractedText = '';
      });
    }
  }

  Future<void> _runOCR() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      String text = '';
      final isPdf = _selectedFile!.path.toLowerCase().endsWith('.pdf');

      if (isPdf) {
        // Try local text layer first
        text = await PdfEngine.extractText(_selectedFile!);
      }

      if (text.trim().isEmpty) {
        // Run AI OCR on backend (Groq/Gemini Vision)
        final res = await ApiService().ocrDocument(file: _selectedFile!);
        text = res['text'] ?? res['ocr'] ?? '';
        if (text.trim().isEmpty) {
          throw Exception('No text or layout data could be recognized in the selected document.');
        }
      }

      if (mounted) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'ai-ocr',
                toolName: 'OCR Text Recognition',
                fileName: _selectedFile!.uri.pathSegments.last,
                fileSize: await _selectedFile!.length(),
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _extractedText = text;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OCR extraction complete!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR processing failed: $e')),
        );
      }
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _extractedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'OCR Text & Layout',
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
                      icon: const Icon(LucideIcons.scanLine, size: 20),
                      label: const Text('Choose PDF or Image for OCR'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.toolBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.scanLine, color: AppColors.toolBlue, size: 24),
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

          if (_selectedFile != null)
            ActionButton(
              label: 'Extract Text & Layout with AI',
              icon: LucideIcons.sparkles,
              isLoading: _isProcessing,
              onPressed: _runOCR,
            ),

          if (_extractedText.isNotEmpty) ...[
            const SizedBox(height: 24),
            MarkdownViewer(
              markdown: _extractedText,
              title: 'OCR Extracted Content',
            ),
          ],
        ],
      ),
    );
  }
}
