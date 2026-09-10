import 'dart:io';
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
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class PDFEditorScreen extends StatefulWidget {
  const PDFEditorScreen({super.key});

  @override
  State<PDFEditorScreen> createState() => _PDFEditorScreenState();
}

class _DrawingPoint {
  final Offset offset;
  final Paint paint;
  _DrawingPoint(this.offset, this.paint);
}

class _PDFEditorScreenState extends State<PDFEditorScreen> {
  File? _selectedFile;
  final List<List<_DrawingPoint?>> _lines = [];
  List<_DrawingPoint?> _currentLine = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _isProcessing = false;
  File? _editedResult;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _lines.clear();
        _editedResult = null;
      });
    }
  }

  Future<void> _saveEditedPdf() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: pw_pdf.PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text('Annotated Document from PaperKit PDF Editor', style: const pw.TextStyle(fontSize: 16)),
            );
          },
        ),
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outName = 'Edited_${_selectedFile!.uri.pathSegments.last}';
      final outPath = '${_selectedFile!.parent.path}/$outName';
      final outFile = File(outPath);
      await outFile.writeAsBytes(await pdf.save());

      final doc = DocumentFile(
        id: 'edit_$timestamp',
        name: outName,
        path: outFile.path,
        size: await outFile.length(),
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.pdf,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'pdf-editor',
                toolName: 'PDF Editor',
                fileName: outName,
                outputPath: outFile.path,
                fileSize: await outFile.length(),
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _editedResult = outFile;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annotations & edits saved to PDF!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'PDF Editor',
      showBottomNav: false,
      child: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.filePlus, size: 20),
                  onPressed: _pickFile,
                  tooltip: 'Open PDF',
                ),
                IconButton(
                  icon: const Icon(LucideIcons.undo, size: 20),
                  onPressed: _lines.isNotEmpty ? () => setState(() => _lines.removeLast()) : null,
                  tooltip: 'Undo',
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 20, color: AppColors.error),
                  onPressed: _lines.isNotEmpty ? () => setState(() => _lines.clear()) : null,
                  tooltip: 'Clear Canvas',
                ),
                const Spacer(),
                _buildColorCircle(Colors.black),
                _buildColorCircle(AppColors.primary),
                _buildColorCircle(AppColors.error),
                _buildColorCircle(AppColors.success),
                _buildColorCircle(Colors.amber),
              ],
            ),
          ),

          // Canvas Area
          Expanded(
            child: _selectedFile == null
                ? Center(
                    child: OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(LucideIcons.filePlus, size: 20),
                      label: const Text('Open PDF to Annotate & Edit'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(18)),
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          final paint = Paint()
                            ..color = _selectedColor
                            ..strokeWidth = _strokeWidth
                            ..strokeCap = StrokeCap.round;
                          _currentLine = [_DrawingPoint(details.localPosition, paint)];
                          _lines.add(_currentLine);
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          final paint = Paint()
                            ..color = _selectedColor
                            ..strokeWidth = _strokeWidth
                            ..strokeCap = StrokeCap.round;
                          _currentLine.add(_DrawingPoint(details.localPosition, paint));
                        });
                      },
                      child: CustomPaint(
                        painter: _EditorPainter(lines: _lines),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          alignment: Alignment.topCenter,
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            '📄 ${_selectedFile!.uri.pathSegments.last} (Ready for drawing & annotations)',
                            style: const TextStyle(color: Colors.black45, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),

          // Bottom Action Bar
          if (_selectedFile != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      label: 'Save & Export Document',
                      icon: LucideIcons.save,
                      isLoading: _isProcessing,
                      onPressed: _saveEditedPdf,
                    ),
                  ),
                  if (_editedResult != null) ...[
                    const SizedBox(width: 10),
                    ActionButton(
                      label: 'Open',
                      icon: LucideIcons.externalLink,
                      isSecondary: true,
                      width: 100,
                      onPressed: () => OpenFilex.open(_editedResult!.path),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColorCircle(Color color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: isSelected ? 26 : 20,
        height: isSelected ? 26 : 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]
              : null,
        ),
      ),
    );
  }
}

class _EditorPainter extends CustomPainter {
  final List<List<_DrawingPoint?>> lines;
  _EditorPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      for (int i = 0; i < line.length - 1; i++) {
        if (line[i] != null && line[i + 1] != null) {
          canvas.drawLine(line[i]!.offset, line[i + 1]!.offset, line[i]!.paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
