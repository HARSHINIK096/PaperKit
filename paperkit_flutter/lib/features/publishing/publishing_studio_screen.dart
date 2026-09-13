import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/publishing_model.dart';
import '../../core/services/share_service.dart';
import 'publishing_service.dart';

class PublishingStudioScreen extends StatefulWidget {
  const PublishingStudioScreen({super.key});

  @override
  State<PublishingStudioScreen> createState() => _PublishingStudioScreenState();
}

class _PublishingStudioScreenState extends State<PublishingStudioScreen> with SingleTickerProviderStateMixin {
  final PublishingService _service = PublishingService();
  late TabController _tabController;

  File? _selectedFile;
  PreflightReport? _preflightReport;
  bool _isLoading = false;

  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _subtitleController;

  // Cover customizer state
  Color _coverBgColor = const Color(0xFF1E3A8A); // Deep Indigo
  Color _coverTextColor = Colors.white;
  int _selectedStyleIndex = 0;

  final List<Color> _palette = const [
    Color(0xFF1E3A8A), // Deep Indigo
    Color(0xFF065F46), // Emerald Slate
    Color(0xFF881337), // Crimson Rose
    Color(0xFF18181B), // Charcoal
    Color(0xFF4C1D95), // Royal Violet
    Color(0xFF78350F), // Amber Earth
  ];

  final List<String> _typographyStyles = const [
    'Modern Serif',
    'Clean Sans',
    'Bold Impact',
    'Editorial Elegant',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _titleController = TextEditingController(text: 'My E-Book');
    _authorController = TextEditingController(text: 'Author Name');
    _subtitleController = TextEditingController(text: 'A Complete Digital Edition');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final report = await _service.runPrintPreflight(file);

        setState(() {
          _selectedFile = file;
          _preflightReport = report;
          _titleController.text = file.uri.pathSegments.last.replaceAll('.pdf', '');
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load PDF: $e')),
        );
      }
    }
  }

  CoverConfig _getCoverConfig() {
    return CoverConfig(
      title: _titleController.text.trim().isEmpty ? 'Untitled E-Book' : _titleController.text.trim(),
      subtitle: _subtitleController.text.trim(),
      author: _authorController.text.trim().isEmpty ? 'MaskerV Publisher' : _authorController.text.trim(),
      backgroundColorHex: _coverBgColor.toARGB32(),
      textColorHex: _coverTextColor.toARGB32(),
    );
  }

  Future<void> _convertAndExportEpub() async {
    if (_selectedFile == null) return;
    setState(() => _isLoading = true);

    try {
      final cover = _getCoverConfig();
      final epubFile = await _service.convertPdfToEpub(
        pdfFile: _selectedFile!,
        title: cover.title,
        author: cover.author,
        cover: cover,
      );

      setState(() => _isLoading = false);
      ShareService.shareFile(filePath: epubFile.path);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('EPUB export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publishing & E-Book Studio'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(LucideIcons.book), text: 'PDF ➔ EPUB'),
            Tab(icon: Icon(LucideIcons.palette), text: 'Cover Designer'),
            Tab(icon: Icon(LucideIcons.printer), text: 'Print Preflight'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEpubTab(),
          _buildCoverTab(),
          _buildPreflightTab(),
        ],
      ),
    );
  }

  Widget _buildEpubTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickDocument,
            icon: const Icon(LucideIcons.fileUp),
            label: Text(_selectedFile == null ? 'Select Source PDF Document' : 'Change Source PDF (${_selectedFile!.uri.pathSegments.last})'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_selectedFile == null)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.bookOpen, size: 36, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Automated E-Book Compilation',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select a PDF to extract heading structure, segment content into chapters, embed style metadata, and compile a genuine EPUB 3.0 package.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Metadata Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Book Title',
                        prefixIcon: Icon(LucideIcons.bookmark),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _authorController,
                      decoration: const InputDecoration(
                        labelText: 'Author Name',
                        prefixIcon: Icon(LucideIcons.user),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _convertAndExportEpub,
                        icon: const Icon(LucideIcons.download),
                        label: const Text('Compile & Export Genuine EPUB Package'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoverTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Cover Card Preview
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _coverBgColor,
                    Color.lerp(_coverBgColor, Colors.black, 0.45) ?? Colors.black,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Book spine accent
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 14,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        border: Border(
                          right: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
                        ),
                      ),
                    ),
                  ),
                  // Cover content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(36, 28, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'MASKERV DIGITAL EDITION',
                            style: TextStyle(
                              color: _coverTextColor.withValues(alpha: 0.9),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _titleController.text.trim().isEmpty ? 'Untitled E-Book' : _titleController.text.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _coverTextColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: _selectedStyleIndex == 0 ? 'serif' : null,
                          ),
                        ),
                        if (_subtitleController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            _subtitleController.text.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _coverTextColor.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(LucideIcons.feather, size: 14, color: _coverTextColor.withValues(alpha: 0.7)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _authorController.text.trim().isEmpty ? 'MaskerV Author' : _authorController.text.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _coverTextColor.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Customizer Controls Container Card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cover Customizer & Typography', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _subtitleController,
                    decoration: const InputDecoration(
                      labelText: 'Cover Subtitle / Tagline',
                      prefixIcon: Icon(LucideIcons.type),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  const Text('Color Palette Preset', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: _palette.map((c) {
                      final isSelected = _coverBgColor.value == c.value;
                      return InkWell(
                        onTap: () => setState(() => _coverBgColor = c),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Typography Style', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_typographyStyles.length, (idx) {
                      final isSelected = _selectedStyleIndex == idx;
                      return ChoiceChip(
                        label: Text(_typographyStyles[idx]),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedStyleIndex = idx);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _tabController.animateTo(0);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cover configuration applied to publication!')),
                        );
                      },
                      icon: const Icon(LucideIcons.check),
                      label: const Text('Apply Cover to E-Book Publication'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreflightTab() {
    if (_preflightReport == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.printer, size: 36, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Print Preflight & Compliance Inspector',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inspect PDF color profiles (CMYK/RGB), page boundaries, raster DPI resolution, and font embedding to verify print-ready standards before physical publication.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _pickDocument,
                    icon: const Icon(LucideIcons.fileUp),
                    label: const Text('Select PDF for Preflight'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    _preflightReport!.isPrintReady ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                    color: _preflightReport!.isPrintReady ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  const Text('Print Preflight Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const Divider(height: 24),
              _buildReportRow('Pages', '${_preflightReport!.pageCount}'),
              _buildReportRow('Page Size', _preflightReport!.pageSize),
              _buildReportRow('Estimated Resolution', '${_preflightReport!.estimatedDpi} DPI'),
              _buildReportRow('Color Space', _preflightReport!.colorSpace),
              _buildReportRow('Embedded Fonts', _preflightReport!.fontsEmbedded ? 'YES (Compliant)' : 'NO (May fail printing)'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickDocument,
                  icon: const Icon(LucideIcons.refreshCw),
                  label: const Text('Analyze Another Document'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
