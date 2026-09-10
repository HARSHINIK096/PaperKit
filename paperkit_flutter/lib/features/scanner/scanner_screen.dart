import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _scannedPages = [];
  bool _isExporting = false;

  Future<void> _capturePage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 95,
      );

      if (image != null) {
        setState(() {
          _scannedPages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing page: $e')),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    if (_scannedPages.isEmpty) return;

    setState(() => _isExporting = true);

    try {
      final pdf = pw.Document();

      for (final pageFile in _scannedPages) {
        final imageBytes = await pageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: pw_pdf.PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      final outputDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Scan_$timestamp.pdf';
      final outputFile = File('${outputDir.path}/$fileName');
      await outputFile.writeAsBytes(await pdf.save());

      final doc = DocumentFile(
        id: 'scan_$timestamp',
        name: fileName,
        path: outputFile.path,
        size: await outputFile.length(),
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.pdf,
        pageCount: _scannedPages.length,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'scanner',
                toolName: 'Document Scanner',
                fileName: fileName,
                outputPath: outputFile.path,
                fileSize: await outputFile.length(),
                timestamp: DateTime.now(),
              ),
            );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved $fileName with ${_scannedPages.length} pages!')),
        );

        setState(() {
          _scannedPages.clear();
          _isExporting = false;
        });

        context.go('/files');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Document Scanner',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Page Counter & Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pages (${_scannedPages.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (_scannedPages.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => setState(() => _scannedPages.clear()),
                    icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                    label: const Text('Clear All', style: TextStyle(color: AppColors.error)),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Captured Pages Grid / Empty View
            Expanded(
              child: _scannedPages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.camera, size: 36, color: AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Pages Captured',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Take a picture with camera or pick from gallery',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      itemCount: _scannedPages.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                ),
                                image: DecorationImage(
                                  image: FileImage(_scannedPages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.65),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Page ${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: InkWell(
                                onTap: () => setState(() => _scannedPages.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            // Capture Controls
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    label: 'Camera',
                    icon: LucideIcons.camera,
                    onPressed: () => _capturePage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ActionButton(
                    label: 'Gallery',
                    icon: LucideIcons.image,
                    isSecondary: true,
                    onPressed: () => _capturePage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            if (_scannedPages.isNotEmpty) ...[
              const SizedBox(height: 10),
              ActionButton(
                label: 'Save & Export PDF (${_scannedPages.length} pages)',
                icon: LucideIcons.fileCheck,
                isLoading: _isExporting,
                onPressed: _exportPdf,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
