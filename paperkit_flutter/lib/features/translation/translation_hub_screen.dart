import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/translation_model.dart';
import 'translation_service.dart';

class TranslationHubScreen extends StatefulWidget {
  const TranslationHubScreen({super.key});

  @override
  State<TranslationHubScreen> createState() => _TranslationHubScreenState();
}

class _TranslationHubScreenState extends State<TranslationHubScreen> with SingleTickerProviderStateMixin {
  final TranslationService _service = TranslationService();
  late TabController _tabController;

  File? _selectedFile;
  List<TranslationSegment> _segments = [];
  List<GlossaryTerm> _glossary = [];
  bool _isLoading = false;

  String _targetLang = 'es';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGlossary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGlossary() async {
    final loaded = await _service.loadGlossary();
    setState(() => _glossary = loaded);
  }

  Future<void> _pickDocument() async {
    setState(() => _isLoading = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final segments = await _service.translateDocument(
        file: file,
        sourceLanguage: 'en',
        targetLanguage: _targetLang,
      );

      setState(() {
        _selectedFile = file;
        _segments = segments;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translation & Localization Hub'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(LucideIcons.languages), text: 'Side-by-Side View'),
            Tab(icon: Icon(LucideIcons.bookOpen), text: 'Custom Glossary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSideBySideTab(),
          _buildGlossaryTab(),
        ],
      ),
    );
  }

  Widget _buildSideBySideTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey.shade200,
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickDocument,
                icon: const Icon(LucideIcons.fileUp),
                label: Text(_selectedFile != null ? 'Active: ${_selectedFile!.uri.pathSegments.last}' : 'Load Document'),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _targetLang,
                items: const [
                  DropdownMenuItem(value: 'es', child: Text('Spanish (ES)')),
                  DropdownMenuItem(value: 'fr', child: Text('French (FR)')),
                  DropdownMenuItem(value: 'de', child: Text('German (DE)')),
                  DropdownMenuItem(value: 'ja', child: Text('Japanese (JA)')),
                ],
                onChanged: (val) => setState(() => _targetLang = val ?? 'es'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _segments.isEmpty
                  ? Center(
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
                                  child: Icon(LucideIcons.languages, size: 36, color: Theme.of(context).colorScheme.primary),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Dual-Language Translation',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Select a PDF or text document to translate paragraphs side-by-side while preserving structural alignment and formatting.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _pickDocument,
                                  icon: const Icon(LucideIcons.fileUp),
                                  label: const Text('Select Document to Translate'),
                                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _segments.length,
                      itemBuilder: (context, index) {
                        final seg = _segments[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('ORIGINAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                                      Text(seg.originalText),
                                    ],
                                  ),
                                ),
                                const VerticalDivider(),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('TRANSLATED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                      Text(seg.translatedText),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildGlossaryTab() {
    if (_glossary.isEmpty) {
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
                    child: Icon(LucideIcons.bookOpen, size: 36, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Translation Glossary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No custom domain glossary terms configured yet. Custom terms ensure precise technical and localized translations.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _glossary.length,
      itemBuilder: (context, index) {
        final g = _glossary[index];
        return Card(
          child: ListTile(
            title: Text('${g.sourceTerm} ➔ ${g.targetTerm}'),
            subtitle: Text('Domain: ${g.domainCategory} (${g.sourceLanguage} to ${g.targetLanguage})'),
          ),
        );
      },
    );
  }
}
