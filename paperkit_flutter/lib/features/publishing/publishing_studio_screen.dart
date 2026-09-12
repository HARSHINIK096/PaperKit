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

  String _title = 'My E-Book';
  String _author = 'Author';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    setState(() => _isLoading = true);
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
        _title = file.uri.pathSegments.last.replaceAll('.pdf', '');
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _convertAndExportEpub() async {
    if (_selectedFile == null) return;
    setState(() => _isLoading = true);

    final cover = CoverConfig(title: _title, author: _author);
    final epubFile = await _service.convertPdfToEpub(
      pdfFile: _selectedFile!,
      title: _title,
      author: _author,
      cover: cover,
    );

    setState(() => _isLoading = false);
    ShareService.shareFile(filePath: epubFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automated Publishing & E-Book Studio'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(LucideIcons.book), text: 'PDF ➔ EPUB Engine'),
            Tab(icon: Icon(LucideIcons.image), text: 'Cover Designer'),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickDocument,
            icon: const Icon(LucideIcons.fileUp),
            label: const Text('Select Source PDF Document'),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_selectedFile == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Select a PDF to extract heading structure, create chapters, and compile a genuine EPUB e-book package.'),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: TextEditingController(text: _title),
                  decoration: const InputDecoration(labelText: 'Book Title'),
                  onChanged: (val) => _title = val,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: _author),
                  decoration: const InputDecoration(labelText: 'Author Name'),
                  onChanged: (val) => _author = val,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _convertAndExportEpub,
                  icon: const Icon(LucideIcons.download),
                  label: const Text('Compile & Export Genuine EPUB Package'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCoverTab() {
    return const Center(child: Text('Interactive E-Book Cover Designer with custom typography & colors.'));
  }

  Widget _buildPreflightTab() {
    if (_preflightReport == null) {
      return const Center(child: Text('Load a PDF to run print preflight analysis.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Print Preflight Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Divider(),
              Text('Pages: ${_preflightReport!.pageCount}'),
              Text('Page Size: ${_preflightReport!.pageSize}'),
              Text('Estimated Resolution: ${_preflightReport!.estimatedDpi} DPI'),
              Text('Color Space: ${_preflightReport!.colorSpace}'),
              Text('Embedded Fonts: ${_preflightReport!.fontsEmbedded ? "YES" : "NO"}'),
            ],
          ),
        ),
      ),
    );
  }
}
