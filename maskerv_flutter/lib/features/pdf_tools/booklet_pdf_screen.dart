import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class BookletPdfScreen extends StatefulWidget {
  const BookletPdfScreen({super.key});

  @override
  State<BookletPdfScreen> createState() => _BookletPdfScreenState();
}

class _BookletPdfScreenState extends State<BookletPdfScreen> {
  File? _selectedFile;
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

  Future<void> _generateBooklet() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      final inputBytes = await _selectedFile!.readAsBytes();
      final inputDoc = PdfDocument(inputBytes: inputBytes);
      final outputDoc = PdfDocument();

      int pageCount = inputDoc.pages.count;
      int totalBookletPages = ((pageCount + 3) ~/ 4) * 4;

      List<int> pageOrder = [];
      int left = totalBookletPages - 1;
      int right = 0;

      while (right < left) {
        pageOrder.add(left);
        pageOrder.add(right);
        right++;
        left--;
        pageOrder.add(right);
        pageOrder.add(left);
        right++;
        left--;
      }

      outputDoc.pageSettings.orientation = PdfPageOrientation.landscape;
      outputDoc.pageSettings.size = PdfPageSize.a4;

      for (int i = 0; i < pageOrder.length; i += 2) {
        final sheetPage = outputDoc.pages.add();

        final sheetWidth = sheetPage.size.width;
        final sheetHeight = sheetPage.size.height;
        final halfWidth = sheetWidth / 2;

        int leftIdx = pageOrder[i];
        int rightIdx = pageOrder[i + 1];

        if (leftIdx < pageCount) {
          final leftTemplate = inputDoc.pages[leftIdx].createTemplate();
          sheetPage.graphics.drawPdfTemplate(leftTemplate, const Offset(0, 0), Size(halfWidth, sheetHeight));
        }

        if (rightIdx < pageCount) {
          final rightTemplate = inputDoc.pages[rightIdx].createTemplate();
          sheetPage.graphics.drawPdfTemplate(rightTemplate, Offset(halfWidth, 0), Size(halfWidth, sheetHeight));
        }
      }

      final outputBytes = outputDoc.saveSync();
      inputDoc.dispose();
      outputDoc.dispose();

      final tempDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/booklet_$timestamp.pdf');
      await file.writeAsBytes(outputBytes);

      setState(() {
        _outputFile = file;
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booklet imposition generated successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booklet Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Booklet Printing Imposition',
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
                        const Icon(LucideIcons.bookOpen, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_selectedFile!.uri.pathSegments.last, style: const TextStyle(fontWeight: FontWeight.bold))),
                        TextButton(onPressed: _pickFile, child: const Text('Change')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Re-arranges pages into 2-up saddle-stitch booklet order for double-sided printing.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ActionButton(
                      label: 'Generate Print Booklet',
                      icon: LucideIcons.book,
                      isLoading: _isProcessing,
                      onPressed: _generateBooklet,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_outputFile != null) ...[
            const SizedBox(height: 16),
            ActionButton(
              label: 'Open Booklet PDF',
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
