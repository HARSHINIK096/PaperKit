import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class ConvertDocumentScreen extends StatefulWidget {
  final String? initialFrom;
  final String? initialTo;

  const ConvertDocumentScreen({super.key, this.initialFrom, this.initialTo});

  @override
  State<ConvertDocumentScreen> createState() => _ConvertDocumentScreenState();
}

class _ConvertDocumentScreenState extends State<ConvertDocumentScreen> {
  File? _selectedFile;
  late String _fromFormat;
  late String _toFormat;
  bool _isProcessing = false;
  File? _convertedResult;

  final List<String> _formats = ['pdf', 'word', 'excel', 'ppt', 'image'];

  @override
  void initState() {
    super.initState();
    _fromFormat = widget.initialFrom ?? 'word';
    _toFormat = widget.initialTo ?? 'pdf';
  }

  Future<void> _pickFile() async {
    List<String> allowed = [];
    if (_fromFormat == 'pdf') allowed = ['pdf'];
    if (_fromFormat == 'word') allowed = ['doc', 'docx'];
    if (_fromFormat == 'excel') allowed = ['xls', 'xlsx'];
    if (_fromFormat == 'ppt') allowed = ['ppt', 'pptx'];
    if (_fromFormat == 'image') allowed = ['jpg', 'jpeg', 'png', 'webp', 'bmp'];

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowed,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _convertedResult = null;
      });
    }
  }

  Future<void> _convertDocument() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outName = 'Converted_$timestamp';
      File outputFile;

      if (_fromFormat == 'image' && _toFormat == 'pdf') {
        // Local conversion
        final pdf = pw.Document();
        final imgBytes = await _selectedFile!.readAsBytes();
        final image = pw.MemoryImage(imgBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: pw_pdf.PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
            },
          ),
        );

        outputFile = File('${_selectedFile!.parent.path}/$outName.pdf');
        await outputFile.writeAsBytes(await pdf.save());
      } else {
        // Backend conversion service
        final res = await ApiService().uploadAndProcess(
          endpoint: '/tools/convert',
          files: [_selectedFile!],
          data: {'from_format': _fromFormat, 'to_format': _toFormat},
        );
        outputFile = File('${_selectedFile!.parent.path}/$outName.$_toFormat');
        if (res.data is List<int>) {
          await outputFile.writeAsBytes(res.data);
        } else if (res.data is Map && res.data['download_url'] != null) {
          final downloadUrl = res.data['download_url'].toString();
          final downloadRes = await ApiService().dio.get<List<int>>(
            downloadUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          if (downloadRes.data != null) {
            await outputFile.writeAsBytes(downloadRes.data!);
          } else {
            throw Exception('PaperKit server did not return file payload for $_toFormat.');
          }
        } else {
          throw Exception('Conversion to $_toFormat failed on PaperKit server.');
        }
      }

      final doc = DocumentFile(
        id: 'conv_$timestamp',
        name: outputFile.uri.pathSegments.last,
        path: outputFile.path,
        size: await outputFile.length(),
        modifiedAt: DateTime.now(),
        type: DocumentFile.getTypeFromExtension(_toFormat),
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'convert-document',
                toolName: 'Convert Document ($_fromFormat to $_toFormat)',
                fileName: doc.name,
                outputPath: outputFile.path,
                fileSize: await outputFile.length(),
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _convertedResult = outputFile;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Converted to $_toFormat successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conversion failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Convert Document',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Format Selectors
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DropdownButton<String>(
                  value: _fromFormat,
                  underline: const SizedBox(),
                  items: _formats
                      .map((f) => DropdownMenuItem(value: f, child: Text(f.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _fromFormat = val!;
                      _selectedFile = null;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(LucideIcons.arrowRight, color: AppColors.primary),
                  onPressed: () {
                    setState(() {
                      final temp = _fromFormat;
                      _fromFormat = _toFormat;
                      _toFormat = temp;
                      _selectedFile = null;
                    });
                  },
                ),
                DropdownButton<String>(
                  value: _toFormat,
                  underline: const SizedBox(),
                  items: _formats
                      .map((f) => DropdownMenuItem(value: f, child: Text(f.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))))
                      .toList(),
                  onChanged: (val) => setState(() => _toFormat = val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // File Picker Tile
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
                      label: Text('Select ${_fromFormat.toUpperCase()} Document'),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.toolGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.fileSpreadsheet, color: AppColors.toolGreen, size: 24),
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
          const SizedBox(height: 24),

          if (_selectedFile != null)
            ActionButton(
              label: 'Convert ${_fromFormat.toUpperCase()} to ${_toFormat.toUpperCase()}',
              icon: LucideIcons.refreshCw,
              isLoading: _isProcessing,
              onPressed: _convertDocument,
            ),

          if (_convertedResult != null) ...[
            const SizedBox(height: 20),
            ActionButton(
              label: 'Open Converted File',
              icon: LucideIcons.externalLink,
              isSecondary: true,
              onPressed: () => OpenFilex.open(_convertedResult!.path),
            ),
          ],
        ],
      ),
    );
  }
}
