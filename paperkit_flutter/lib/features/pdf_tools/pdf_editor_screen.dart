import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/pdf_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_shell.dart';

enum EditorActiveTool { select, draw, text, highlight }

class PDFEditorScreen extends StatefulWidget {
  const PDFEditorScreen({super.key});

  @override
  State<PDFEditorScreen> createState() => _PDFEditorScreenState();
}

class _PDFEditorScreenState extends State<PDFEditorScreen> {
  File? _selectedFile;
  int _totalPages = 1;
  int _currentPageIndex = 0; // 0-indexed

  EditorActiveTool _activeTool = EditorActiveTool.select;
  Color _selectedColor = const Color(0xFF2563EB);
  final double _strokeWidth = 3.5;
  final double _fontSize = 16.0;

  // Original PDF page dimensions per page index
  final Map<int, Size> _pageSizes = {};

  // Extracted text spans per page
  final Map<int, List<PdfExistingTextSpan>> _pageTextSpans = {};
  bool _isLoadingSpans = false;

  // Selected existing text span being edited
  PdfExistingTextSpan? _activeSelectedSpan;

  // Edits organized by page index
  final Map<int, List<PdfDrawPath>> _drawPathsByPage = {};
  final Map<int, List<PdfTextEdit>> _textEditsByPage = {};
  final Map<int, List<PdfHighlightBox>> _highlightsByPage = {};

  List<Offset> _currentDrawingPoints = [];
  Offset? _highlightStart;
  Offset? _highlightEnd;

  bool _isSaving = false;

  final List<Color> _paletteColors = [
    const Color(0xFF000000), // Black
    const Color(0xFF2563EB), // Blue
    const Color(0xFFDC2626), // Red
    const Color(0xFF059669), // Green
    const Color(0xFFD97706), // Amber
    const Color(0xFF7C3AED), // Purple
  ];

  Future<void> _pickPdfFile() async {
    HapticFeedback.lightImpact();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      try {
        final bytes = await file.readAsBytes();
        final doc = PdfDocument(inputBytes: bytes);
        final count = doc.pages.count;
        _pageSizes.clear();
        for (int i = 0; i < count; i++) {
          final pSize = doc.pages[i].size;
          _pageSizes[i] = Size(pSize.width, pSize.height);
        }
        doc.dispose();

        setState(() {
          _selectedFile = file;
          _totalPages = count > 0 ? count : 1;
          _currentPageIndex = 0;
          _pageTextSpans.clear();
          _activeSelectedSpan = null;
          _drawPathsByPage.clear();
          _textEditsByPage.clear();
          _highlightsByPage.clear();
        });

        await _loadPageSpans(_currentPageIndex);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to read PDF pages: $e')),
          );
        }
      }
    }
  }

  Future<void> _loadPageSpans(int pageIndex) async {
    if (_selectedFile == null) return;
    if (_pageTextSpans.containsKey(pageIndex)) return;

    setState(() => _isLoadingSpans = true);
    try {
      final spans = await PdfEngine.extractPageTextSpans(
        inputFile: _selectedFile!,
        pageIndex: pageIndex,
      );
      if (mounted) {
        setState(() {
          _pageTextSpans[pageIndex] = spans;
          _isLoadingSpans = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSpans = false);
      }
    }
  }

  void _onPageChanged(int newPageIndex) {
    if (newPageIndex >= 0 && newPageIndex < _totalPages) {
      setState(() {
        _currentPageIndex = newPageIndex;
        _activeSelectedSpan = null;
      });
      _loadPageSpans(newPageIndex);
    }
  }

  void _selectSpanForEditing(PdfExistingTextSpan span) {
    HapticFeedback.lightImpact();
    setState(() => _activeSelectedSpan = span);
    _showEditSpanModal(span);
  }

  void _showEditSpanModal(PdfExistingTextSpan span) {
    final textCtrl = TextEditingController(text: span.currentText);
    double curFontSize = span.fontSize;
    Color curColor = span.color;
    bool curBold = span.isBold;
    bool curItalic = span.isItalic;
    PdfFontFamily curFamily = span.fontFamily;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.fileEdit, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Edit PDF Text Object',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          Text(
                            'Detected Font: ${span.fontFamilyDisplayName}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                maxLines: 3,
                minLines: 1,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Text Content',
                  hintText: 'Type replacement text...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('Font Size: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Slider(
                      value: curFontSize.clamp(6.0, 48.0),
                      min: 6,
                      max: 48,
                      label: '${curFontSize.toStringAsFixed(1)} pt',
                      onChanged: (val) => setSheetState(() => curFontSize = val),
                    ),
                  ),
                  Text('${curFontSize.toStringAsFixed(1)} pt', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              Row(
                children: [
                  const Text('Style: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('Bold'),
                    selected: curBold,
                    onSelected: (val) => setSheetState(() => curBold = val),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: curBold ? AppColors.primary : Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('Italic'),
                    selected: curItalic,
                    onSelected: (val) => setSheetState(() => curItalic = val),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: curItalic ? AppColors.primary : Colors.black87,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  // Font family quick selector
                  DropdownButton<PdfFontFamily>(
                    value: curFamily,
                    underline: const SizedBox(),
                    isDense: true,
                    style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(
                        value: PdfFontFamily.timesRoman,
                        child: Text('Serif (Times)'),
                      ),
                      DropdownMenuItem(
                        value: PdfFontFamily.helvetica,
                        child: Text('Sans (Helvetica)'),
                      ),
                      DropdownMenuItem(
                        value: PdfFontFamily.courier,
                        child: Text('Mono (Courier)'),
                      ),
                    ],
                    onChanged: (f) {
                      if (f != null) setSheetState(() => curFamily = f);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Color: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  ..._paletteColors.map((c) => GestureDetector(
                        onTap: () => setSheetState(() => curColor = c),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: curColor == c ? AppColors.primary : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (span.isModified) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          span.currentText = span.originalText;
                          span.isModified = false;
                          span.color = const Color(0xFF000000);
                        });
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(LucideIcons.rotateCcw, size: 16),
                      label: const Text('Revert'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final newText = textCtrl.text.trim();
                        if (newText.isNotEmpty) {
                          setState(() {
                            span.currentText = newText;
                            span.fontSize = curFontSize;
                            span.color = curColor;
                            span.isBold = curBold;
                            span.isItalic = curItalic;
                            span.fontFamily = curFamily;
                            span.isModified = true;
                            _activeSelectedSpan = span;
                          });
                        }
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(LucideIcons.check, size: 16),
                      label: const Text('Apply Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTextDialog(Offset tapPosition) {
    final textController = TextEditingController();
    bool isBold = false;
    double currentFontSize = _fontSize;
    Color textColor = _selectedColor;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Insert Text to PDF', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Text Content',
                  hintText: 'Type text annotation...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('Size: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Slider(
                      value: currentFontSize,
                      min: 10,
                      max: 32,
                      divisions: 11,
                      label: '${currentFontSize.round()} pt',
                      onChanged: (val) => setDialogState(() => currentFontSize = val),
                    ),
                  ),
                  Text('${currentFontSize.round()} pt', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              Row(
                children: [
                  const Text('Color: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  ..._paletteColors.map((c) => GestureDetector(
                        onTap: () => setDialogState(() => textColor = c),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: textColor == c ? AppColors.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  setState(() {
                    _textEditsByPage.putIfAbsent(_currentPageIndex, () => []).add(
                          PdfTextEdit(
                            text: textController.text.trim(),
                            normalizedPosition: tapPosition,
                            fontSize: currentFontSize,
                            color: textColor,
                            isBold: isBold,
                          ),
                        );
                  });
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Insert Text'),
            ),
          ],
        ),
      ),
    );
  }

  void _undoLastAction() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_drawPathsByPage[_currentPageIndex]?.isNotEmpty ?? false) {
        _drawPathsByPage[_currentPageIndex]!.removeLast();
      } else if (_textEditsByPage[_currentPageIndex]?.isNotEmpty ?? false) {
        _textEditsByPage[_currentPageIndex]!.removeLast();
      } else if (_highlightsByPage[_currentPageIndex]?.isNotEmpty ?? false) {
        _highlightsByPage[_currentPageIndex]!.removeLast();
      }
    });
  }

  void _clearCurrentPage() {
    HapticFeedback.mediumImpact();
    setState(() {
      _drawPathsByPage[_currentPageIndex]?.clear();
      _textEditsByPage[_currentPageIndex]?.clear();
      _highlightsByPage[_currentPageIndex]?.clear();
      final spans = _pageTextSpans[_currentPageIndex] ?? [];
      for (final s in spans) {
        s.currentText = s.originalText;
        s.isModified = false;
      }
      _activeSelectedSpan = null;
    });
  }

  Future<void> _saveAndExport() async {
    if (_selectedFile == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final outputFile = await PdfEngine.applyPdfAnnotations(
        inputFile: _selectedFile!,
        drawPathsByPage: _drawPathsByPage,
        textEditsByPage: _textEditsByPage,
        highlightsByPage: _highlightsByPage,
        modifiedSpansByPage: _pageTextSpans,
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outName = outputFile.uri.pathSegments.last;

      final doc = DocumentFile(
        id: 'edit_$timestamp',
        name: outName,
        path: outputFile.path,
        size: await outputFile.length(),
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.pdf,
        pageCount: _totalPages,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'pdf-editor',
                toolName: 'PDF Editor',
                fileName: outName,
                outputPath: outputFile.path,
                fileSize: await outputFile.length(),
                timestamp: DateTime.now(),
                success: true,
              ),
            );

        setState(() {
          _isSaving = false;
        });

        _showSuccessSheet(outputFile);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving PDF: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showSuccessSheet(File outputFile) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'PDF Edits Applied & Saved!',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                'Saved directly to your PaperKit workspace.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        OpenFilex.open(outputFile.path);
                      },
                      icon: const Icon(LucideIcons.eye, size: 16),
                      label: const Text('View PDF'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Share.shareXFiles([XFile(outputFile.path)]);
                      },
                      icon: const Icon(LucideIcons.share2, size: 16),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'PDF Editor',
      actions: [
        if (_selectedFile != null)
          IconButton(
            icon: const Icon(LucideIcons.save, size: 20),
            onPressed: _isSaving ? null : _saveAndExport,
            tooltip: 'Save & Export',
          ),
        IconButton(
          icon: const Icon(LucideIcons.filePlus, size: 20),
          onPressed: _pickPdfFile,
          tooltip: 'Open PDF',
        ),
        const SizedBox(width: 4),
      ],
      child: _selectedFile == null
          ? _buildFilePickerPlaceholder(isDark)
          : Column(
              children: [
                // Top Page Navigation Bar
                _buildPageNavigator(isDark),

                // Tool Palette (Select Text, Draw, Add Text, Highlight, Colors, Undo, Clear)
                _buildToolPalette(isDark),

                // Interactive Document Canvas
                Expanded(
                  child: _buildInteractiveCanvas(isDark),
                ),
              ],
            ),
    );
  }

  Widget _buildFilePickerPlaceholder(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: InkWell(
          onTap: _pickPdfFile,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                style: BorderStyle.solid,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.fileEdit, size: 42, color: AppColors.primary),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Select a PDF Document to Edit',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select & edit existing text in-place, insert annotations, draw with pen, and highlight content.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _pickPdfFile,
                  icon: const Icon(LucideIcons.uploadCloud, size: 18),
                  label: const Text('Browse Files'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageNavigator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.fileText, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  _selectedFile!.uri.pathSegments.last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.chevronLeft, size: 18),
                onPressed: _currentPageIndex > 0 ? () => _onPageChanged(_currentPageIndex - 1) : null,
                tooltip: 'Previous Page',
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Page ${_currentPageIndex + 1} of $_totalPages',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.chevronRight, size: 18),
                onPressed: _currentPageIndex < _totalPages - 1 ? () => _onPageChanged(_currentPageIndex + 1) : null,
                tooltip: 'Next Page',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolPalette(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Tool selector chips
            _buildToolChip(
              icon: LucideIcons.mousePointer,
              label: 'Select Text',
              isSelected: _activeTool == EditorActiveTool.select,
              onTap: () => setState(() => _activeTool = EditorActiveTool.select),
            ),
            const SizedBox(width: 8),
            _buildToolChip(
              icon: LucideIcons.penTool,
              label: 'Pen',
              isSelected: _activeTool == EditorActiveTool.draw,
              onTap: () => setState(() => _activeTool = EditorActiveTool.draw),
            ),
            const SizedBox(width: 8),
            _buildToolChip(
              icon: LucideIcons.type,
              label: 'Add Text',
              isSelected: _activeTool == EditorActiveTool.text,
              onTap: () => setState(() => _activeTool = EditorActiveTool.text),
            ),
            const SizedBox(width: 8),
            _buildToolChip(
              icon: LucideIcons.highlighter,
              label: 'Highlight',
              isSelected: _activeTool == EditorActiveTool.highlight,
              onTap: () => setState(() => _activeTool = EditorActiveTool.highlight),
            ),

            const SizedBox(width: 14),
            Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(width: 14),

            // Color Palette
            ..._paletteColors.map((c) => GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == c ? AppColors.primary : Colors.transparent,
                        width: 2.2,
                      ),
                      boxShadow: [
                        if (_selectedColor == c)
                          BoxShadow(color: c.withOpacity(0.4), blurRadius: 4),
                      ],
                    ),
                  ),
                )),

            const SizedBox(width: 10),
            Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(width: 10),

            // Undo & Clear
            IconButton(
              icon: const Icon(LucideIcons.undo, size: 18),
              onPressed: _undoLastAction,
              tooltip: 'Undo',
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
              onPressed: _clearCurrentPage,
              tooltip: 'Clear Page Edits',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.primary),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.primary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildInteractiveCanvas(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final spans = _pageTextSpans[_currentPageIndex] ?? [];
              final docPageSize = _pageSizes[_currentPageIndex] ??
                  (spans.isNotEmpty ? spans.first.originalPageSize : const Size(595.28, 841.89));
              final pageAspect = docPageSize.height / (docPageSize.width > 0 ? docPageSize.width : 595.28);

              final maxW = constraints.maxWidth;
              final maxH = constraints.maxHeight;
              double canvasW = maxW;
              double canvasH = canvasW * pageAspect;

              if (canvasH > maxH) {
                canvasH = maxH;
                canvasW = canvasH / pageAspect;
              }

              return Container(
                width: canvasW,
                height: canvasH,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 14, offset: Offset(0, 4)),
                  ],
                ),
                child: Stack(
                  children: [
                    // Canvas Painting Layer (Watermarks, Highlights, Drawings, Text Overlays)
                    GestureDetector(
                      onTapUp: (details) {
                        if (_activeTool == EditorActiveTool.text) {
                          final normX = details.localPosition.dx / canvasW;
                          final normY = details.localPosition.dy / canvasH;
                          _showAddTextDialog(Offset(normX, normY));
                        } else if (_activeTool == EditorActiveTool.select) {
                          final normX = details.localPosition.dx / canvasW;
                          final normY = details.localPosition.dy / canvasH;
                          final tapPoint = Offset(normX, normY);
                          // Find closest span under tap with generous hit padding
                          for (final s in spans) {
                            final touchRect = Rect.fromLTWH(
                              s.normalizedRect.left - 0.012,
                              s.normalizedRect.top - 0.008,
                              s.normalizedRect.width + 0.024,
                              s.normalizedRect.height + 0.016,
                            );
                            if (touchRect.contains(tapPoint)) {
                              _selectSpanForEditing(s);
                              return;
                            }
                          }
                        }
                      },
                      onPanStart: (details) {
                        if (_activeTool == EditorActiveTool.draw) {
                          final normX = details.localPosition.dx / canvasW;
                          final normY = details.localPosition.dy / canvasH;
                          setState(() {
                            _currentDrawingPoints = [Offset(normX, normY)];
                          });
                        } else if (_activeTool == EditorActiveTool.highlight) {
                          final normX = details.localPosition.dx / canvasW;
                          final normY = details.localPosition.dy / canvasH;
                          setState(() {
                            _highlightStart = Offset(normX, normY);
                            _highlightEnd = Offset(normX, normY);
                          });
                        }
                      },
                      onPanUpdate: (details) {
                        if (_activeTool == EditorActiveTool.draw) {
                          final normX = (details.localPosition.dx / canvasW).clamp(0.0, 1.0);
                          final normY = (details.localPosition.dy / canvasH).clamp(0.0, 1.0);
                          setState(() {
                            _currentDrawingPoints.add(Offset(normX, normY));
                          });
                        } else if (_activeTool == EditorActiveTool.highlight && _highlightStart != null) {
                          final normX = (details.localPosition.dx / canvasW).clamp(0.0, 1.0);
                          final normY = (details.localPosition.dy / canvasH).clamp(0.0, 1.0);
                          setState(() {
                            _highlightEnd = Offset(normX, normY);
                          });
                        }
                      },
                      onPanEnd: (_) {
                        if (_activeTool == EditorActiveTool.draw && _currentDrawingPoints.length > 1) {
                          setState(() {
                            _drawPathsByPage.putIfAbsent(_currentPageIndex, () => []).add(
                                  PdfDrawPath(
                                    normalizedPoints: List.from(_currentDrawingPoints),
                                    color: _selectedColor,
                                    strokeWidth: _strokeWidth,
                                  ),
                                );
                            _currentDrawingPoints = [];
                          });
                        } else if (_activeTool == EditorActiveTool.highlight &&
                            _highlightStart != null &&
                            _highlightEnd != null) {
                          final left = _highlightStart!.dx < _highlightEnd!.dx ? _highlightStart!.dx : _highlightEnd!.dx;
                          final top = _highlightStart!.dy < _highlightEnd!.dy ? _highlightStart!.dy : _highlightEnd!.dy;
                          final right = _highlightStart!.dx > _highlightEnd!.dx ? _highlightStart!.dx : _highlightEnd!.dx;
                          final bottom = _highlightStart!.dy > _highlightEnd!.dy ? _highlightStart!.dy : _highlightEnd!.dy;

                          if ((right - left) > 0.02 && (bottom - top) > 0.01) {
                            setState(() {
                              _highlightsByPage.putIfAbsent(_currentPageIndex, () => []).add(
                                    PdfHighlightBox(
                                      normalizedRect: Rect.fromLTRB(left, top, right, bottom),
                                      color: _selectedColor,
                                      opacity: 0.35,
                                    ),
                                  );
                            });
                          }
                          setState(() {
                            _highlightStart = null;
                            _highlightEnd = null;
                          });
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CustomPaint(
                          painter: _PdfPageCanvasPainter(
                            pageNumber: _currentPageIndex + 1,
                            docPageSize: docPageSize,
                            existingSpans: spans,
                            drawPaths: _drawPathsByPage[_currentPageIndex] ?? [],
                            textEdits: _textEditsByPage[_currentPageIndex] ?? [],
                            highlights: _highlightsByPage[_currentPageIndex] ?? [],
                            activePoints: _currentDrawingPoints,
                            activeColor: _selectedColor,
                            activeStrokeWidth: _strokeWidth,
                            highlightStart: _highlightStart,
                            highlightEnd: _highlightEnd,
                            selectedSpan: _activeSelectedSpan,
                            isSelectTool: _activeTool == EditorActiveTool.select,
                          ),
                          child: Container(),
                        ),
                      ),
                    ),

                    // Loading indicator for text spans
                    if (_isLoadingSpans)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Detecting Text...',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PdfPageCanvasPainter extends CustomPainter {
  final int pageNumber;
  final Size docPageSize;
  final List<PdfExistingTextSpan> existingSpans;
  final List<PdfDrawPath> drawPaths;
  final List<PdfTextEdit> textEdits;
  final List<PdfHighlightBox> highlights;
  final List<Offset> activePoints;
  final Color activeColor;
  final double activeStrokeWidth;
  final Offset? highlightStart;
  final Offset? highlightEnd;
  final PdfExistingTextSpan? selectedSpan;
  final bool isSelectTool;

  _PdfPageCanvasPainter({
    required this.pageNumber,
    required this.docPageSize,
    required this.existingSpans,
    required this.drawPaths,
    required this.textEdits,
    required this.highlights,
    required this.activePoints,
    required this.activeColor,
    required this.activeStrokeWidth,
    this.highlightStart,
    this.highlightEnd,
    this.selectedSpan,
    required this.isSelectTool,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Document Background & Page Watermark
    final pageBgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), pageBgPaint);

    // Page indicator header
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'PDF Page $pageNumber — Tap any text to select & edit',
        style: TextStyle(color: Colors.grey.withOpacity(0.4), fontSize: 10.5, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, 10));

    // Calculate viewport font scale relative to true document page width
    final docWidth = docPageSize.width > 0 ? docPageSize.width : 595.28;
    final fontScale = (size.width / docWidth).clamp(0.1, 4.0);

    // 2. Render Existing Extracted Text Spans (Words)
    for (final span in existingSpans) {
      final rect = Rect.fromLTWH(
        span.normalizedRect.left * size.width,
        span.normalizedRect.top * size.height,
        span.normalizedRect.width * size.width,
        span.normalizedRect.height * size.height,
      );

      // Scaled font size accurately matching document page width
      final scaledFontSize = (span.fontSize * fontScale).clamp(3.0, 72.0);

      // If modified, cover only the exact word/letter bounding box with white
      if (span.isModified) {
        final coverPaint = Paint()..color = Colors.white;
        canvas.drawRect(Rect.fromLTWH(rect.left - 0.5, rect.top - 0.5, rect.width + 1.0, rect.height + 1.0), coverPaint);
      }

      // Draw word with exact typography matching original document
      final tp = TextPainter(
        text: TextSpan(
          text: span.currentText,
          style: TextStyle(
            color: span.color,
            fontSize: scaledFontSize,
            fontWeight: span.isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: span.isItalic ? FontStyle.italic : FontStyle.normal,
            fontFamilyFallback: span.flutterFontFamilyFallback,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, rect.topLeft);

      // If this span is the actively selected word, draw glowing selection frame
      if (selectedSpan != null && selectedSpan!.id == span.id) {
        final selPaint = Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;
        final selFill = Paint()
          ..color = AppColors.primary.withOpacity(0.12)
          ..style = PaintingStyle.fill;

        final effectiveW = tp.width > rect.width ? tp.width : rect.width;
        final effectiveH = tp.height > rect.height ? tp.height : rect.height;
        final selRect = Rect.fromLTWH(rect.left - 2, rect.top - 1, effectiveW + 4, effectiveH + 2);

        canvas.drawRRect(RRect.fromRectAndRadius(selRect, const Radius.circular(3)), selFill);
        canvas.drawRRect(RRect.fromRectAndRadius(selRect, const Radius.circular(3)), selPaint);

        // Corner handles
        final handlePaint = Paint()..color = AppColors.primary;
        canvas.drawCircle(selRect.topLeft, 3.0, handlePaint);
        canvas.drawCircle(selRect.topRight, 3.0, handlePaint);
        canvas.drawCircle(selRect.bottomLeft, 3.0, handlePaint);
        canvas.drawCircle(selRect.bottomRight, 3.0, handlePaint);
      }
    }

    // 3. Render Saved Highlights
    for (final h in highlights) {
      final highlightPaint = Paint()
        ..color = h.color.withOpacity(h.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(
          h.normalizedRect.left * size.width,
          h.normalizedRect.top * size.height,
          h.normalizedRect.width * size.width,
          h.normalizedRect.height * size.height,
        ),
        highlightPaint,
      );
    }

    // Active Highlight In-Progress
    if (highlightStart != null && highlightEnd != null) {
      final left = highlightStart!.dx < highlightEnd!.dx ? highlightStart!.dx : highlightEnd!.dx;
      final top = highlightStart!.dy < highlightEnd!.dy ? highlightStart!.dy : highlightEnd!.dy;
      final right = highlightStart!.dx > highlightEnd!.dx ? highlightStart!.dx : highlightEnd!.dx;
      final bottom = highlightStart!.dy > highlightEnd!.dy ? highlightStart!.dy : highlightEnd!.dy;

      final previewPaint = Paint()
        ..color = activeColor.withOpacity(0.35)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTRB(left * size.width, top * size.height, right * size.width, bottom * size.height),
        previewPaint,
      );
    }

    // 4. Render Saved Freehand Paths
    for (final path in drawPaths) {
      if (path.normalizedPoints.length < 2) continue;
      final paint = Paint()
        ..color = path.color
        ..strokeWidth = path.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final p = Path();
      p.moveTo(
        path.normalizedPoints.first.dx * size.width,
        path.normalizedPoints.first.dy * size.height,
      );
      for (int i = 1; i < path.normalizedPoints.length; i++) {
        p.lineTo(
          path.normalizedPoints[i].dx * size.width,
          path.normalizedPoints[i].dy * size.height,
        );
      }
      canvas.drawPath(p, paint);
    }

    // Active Drawing Path In-Progress
    if (activePoints.length > 1) {
      final activePaint = Paint()
        ..color = activeColor
        ..strokeWidth = activeStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final p = Path();
      p.moveTo(activePoints.first.dx * size.width, activePoints.first.dy * size.height);
      for (int i = 1; i < activePoints.length; i++) {
        p.lineTo(activePoints[i].dx * size.width, activePoints[i].dy * size.height);
      }
      canvas.drawPath(p, activePaint);
    }

    // 5. Render Text Annotations
    for (final textItem in textEdits) {
      final tp = TextPainter(
        text: TextSpan(
          text: textItem.text,
          style: TextStyle(
            color: textItem.color,
            fontSize: textItem.fontSize,
            fontWeight: textItem.isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width - (textItem.normalizedPosition.dx * size.width));

      tp.paint(
        canvas,
        Offset(
          textItem.normalizedPosition.dx * size.width,
          textItem.normalizedPosition.dy * size.height,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PdfPageCanvasPainter oldDelegate) => true;
}
