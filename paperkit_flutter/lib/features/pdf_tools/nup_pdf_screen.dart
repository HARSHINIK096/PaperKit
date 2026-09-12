import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class NupPdfScreen extends StatefulWidget {
  const NupPdfScreen({super.key});

  @override
  State<NupPdfScreen> createState() => _NupPdfScreenState();
}

class _NupPdfScreenState extends State<NupPdfScreen> {
  File? _selectedFile;
  int _nupOption = 2; // 2, 4, 9
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

  Future<void> _processNup() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      final inputBytes = await _selectedFile!.readAsBytes();
      final inputDoc = PdfDocument(inputBytes: inputBytes);
      final outputDoc = PdfDocument();

      int cols = 1;
      int rows = 2;
      if (_nupOption == 4) {
        cols = 2;
        rows = 2;
      } else if (_nupOption == 9) {
        cols = 3;
        rows = 3;
      }

      int totalInputPages = inputDoc.pages.count;
      int pagesPerSheet = cols * rows;

      for (int i = 0; i < totalInputPages; i += pagesPerSheet) {
        final newPage = outputDoc.pages.add();
        final sheetWidth = newPage.size.width;
        final sheetHeight = newPage.size.height;
        final cellWidth = sheetWidth / cols;
        final cellHeight = sheetHeight / rows;

        for (int cellIdx = 0; cellIdx < pagesPerSheet; cellIdx++) {
          int pageIdx = i + cellIdx;
          if (pageIdx >= totalInputPages) break;

          final template = inputDoc.pages[pageIdx].createTemplate();
          int r = cellIdx ~/ cols;
          int c = cellIdx % cols;

          newPage.graphics.drawPdfTemplate(
            template,
            Offset(c * cellWidth, r * cellHeight),
            Size(cellWidth, cellHeight),
          );
        }
      }

      final outputBytes = outputDoc.saveSync();
      inputDoc.dispose();
      outputDoc.dispose();

      final tempDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/nup_${_nupOption}up_$timestamp.pdf');
      await file.writeAsBytes(outputBytes);

      setState(() {
        _outputFile = file;
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created $_nupOption-Up PDF successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('N-Up Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'N-Up Page Grid Imposition',
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
                        const Icon(LucideIcons.fileText, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_selectedFile!.uri.pathSegments.last, style: const TextStyle(fontWeight: FontWeight.bold))),
                        TextButton(onPressed: _pickFile, child: const Text('Change')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [2, 4, 9].map((opt) {
                        return ChoiceChip(
                          label: Text('$opt-Up Grid'),
                          selected: _nupOption == opt,
                          onSelected: (selected) {
                            if (selected) setState(() => _nupOption = opt);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    ActionButton(
                      label: 'Combine Pages into $_nupOption-Up PDF',
                      icon: LucideIcons.layoutGrid,
                      isLoading: _isProcessing,
                      onPressed: _processNup,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_outputFile != null) ...[
            const SizedBox(height: 16),
            ActionButton(
              label: 'Open N-Up PDF',
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
