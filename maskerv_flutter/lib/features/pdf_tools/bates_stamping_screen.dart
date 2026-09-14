import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/models/audit_ledger_model.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class BatesStampingScreen extends StatefulWidget {
  const BatesStampingScreen({super.key});

  @override
  State<BatesStampingScreen> createState() => _BatesStampingScreenState();
}

class _BatesStampingScreenState extends State<BatesStampingScreen> {
  File? _selectedFile;
  final TextEditingController _prefixController = TextEditingController(text: 'EXHIBIT-');
  final TextEditingController _startNumController = TextEditingController(text: '1001');
  int _digits = 6;
  bool _isProcessing = false;
  File? _outputFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _outputFile = null;
      });
    }
  }

  Future<void> _applyBatesStamping() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      final bytes = await _selectedFile!.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final font = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
      final brush = PdfSolidBrush(PdfColor(180, 0, 0));

      final config = BatesConfig(
        prefix: _prefixController.text.trim(),
        startNumber: int.tryParse(_startNumController.text.trim()) ?? 1001,
        digitPadding: _digits,
      );

      for (int i = 0; i < document.pages.count; i++) {
        final page = document.pages[i];
        final pageSize = page.size;
        final batesNumber = config.formatNumber(i);

        page.graphics.drawString(
          batesNumber,
          font,
          brush: brush,
          bounds: Rect.fromLTWH(pageSize.width - 180, pageSize.height - 25, 160, 20),
          format: PdfStringFormat(alignment: PdfTextAlignment.right),
        );
      }

      final outputBytes = document.saveSync();
      document.dispose();

      final tempDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/bates_$timestamp.pdf');
      await file.writeAsBytes(outputBytes);

      setState(() {
        _outputFile = file;
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bates numbers stamped successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bates Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Legal Bates Stamping',
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
                      onPressed: _pickFile,
                      icon: const Icon(LucideIcons.filePlus),
                      label: const Text('Choose PDF Document'),
                    )
                  else ...[
                    Row(
                      children: [
                        const Icon(LucideIcons.stamp, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_selectedFile!.uri.pathSegments.last, style: const TextStyle(fontWeight: FontWeight.bold))),
                        TextButton(onPressed: _pickFile, child: const Text('Change')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _prefixController,
                      decoration: const InputDecoration(
                        labelText: 'Bates Prefix',
                        hintText: 'e.g. EXHIBIT-A-',
                        prefixIcon: Icon(LucideIcons.tag, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _startNumController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Start Sequence Number',
                        hintText: 'e.g. 1001',
                        prefixIcon: Icon(LucideIcons.binary, size: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ActionButton(
                      label: 'Apply Bates Stamp',
                      icon: LucideIcons.stamp,
                      isDanger: true,
                      isLoading: _isProcessing,
                      onPressed: _applyBatesStamping,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_outputFile != null) ...[
            const SizedBox(height: 16),
            ActionButton(
              label: 'Open Bates PDF',
              icon: LucideIcons.externalLink,
              isSecondary: true,
              onPressed: () => OpenFilex.open(_outputFile!.path),
            ),
          ],
        ],
      ),
    );
  }
}
