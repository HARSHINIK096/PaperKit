import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/mind_map_model.dart';
import '../../core/services/share_service.dart';
import 'diagram_service.dart';

class MindMapDiagramScreen extends StatefulWidget {
  const MindMapDiagramScreen({super.key});

  @override
  State<MindMapDiagramScreen> createState() => _MindMapDiagramScreenState();
}

class _MindMapDiagramScreenState extends State<MindMapDiagramScreen> with SingleTickerProviderStateMixin {
  final DiagramService _service = DiagramService();
  late TabController _tabController;

  File? _selectedFile;
  List<MindMapNode> _nodes = [];
  PresentationDeck? _presentationDeck;
  bool _isLoading = false;

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
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result.isNotEmpty && result.single.path != null) {
      final file = File(result.single.path!);
      final mindMap = await _service.generateMindMapFromDocument(file);
      final deck = await _service.generatePresentationFromDocument(file);

      setState(() {
        _selectedFile = file;
        _nodes = mindMap;
        _presentationDeck = deck;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportPresentation() async {
    if (_presentationDeck == null) return;
    setState(() => _isLoading = true);

    final pdfFile = await _service.exportPresentationAsPdf(
      _presentationDeck!,
      'presentation_${DateTime.now().millisecondsSinceEpoch}',
    );

    setState(() => _isLoading = false);
    ShareService.shareFile(filePath: pdfFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Mind Mapping & Diagram Studio'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(LucideIcons.gitFork), text: 'Mind Map Graph'),
            Tab(icon: Icon(LucideIcons.penTool), text: 'Vector Annotations'),
            Tab(icon: Icon(LucideIcons.presentation), text: 'Presentation Studio'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMindMapTab(),
          _buildVectorTab(),
          _buildPresentationTab(),
        ],
      ),
    );
  }

  void _addCustomNode() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Mind Map Node'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Concept / Topic Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                final id = 'node_${DateTime.now().millisecondsSinceEpoch}';
                setState(() {
                  _nodes.add(
                    MindMapNode(
                      id: id,
                      title: titleController.text.trim(),
                      parentId: _nodes.isNotEmpty ? _nodes.first.id : null,
                      x: (_nodes.length % 2 == 0 ? 200.0 : -200.0),
                      y: _nodes.length * 50.0,
                      colorHex: 0xFF8B5CF6,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add Node'),
          ),
        ],
      ),
    );
  }

  Widget _buildMindMapTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickDocument,
                icon: const Icon(LucideIcons.sparkles),
                label: const Text('AI Analysis: Generate Mind Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _nodes.isEmpty ? null : _addCustomNode,
                icon: const Icon(LucideIcons.plus),
                label: const Text('Add Node'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Analyzing document concepts like NotebookLM...'),
                  ],
                ),
              ),
            )
          else if (_nodes.isEmpty)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  children: [
                    Icon(LucideIcons.gitFork, size: 48, color: Color(0xFF6366F1)),
                    SizedBox(height: 12),
                    Text(
                      'NotebookLM Interactive AI Mind Map Studio',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Select a PDF or document to automatically extract core topics, key takeaways, and structural node graphs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Visual Node Graph Preview Banner
            Card(
              color: const Color(0xFF1E1B4B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(LucideIcons.network, color: Color(0xFFA5B4FC), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nodes.first.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'NotebookLM Mind Map • ${_nodes.length} Connected AI Concepts',
                            style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Nodes Tree Graph List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _nodes.length,
              itemBuilder: (context, index) {
                final node = _nodes[index];
                final isRoot = node.parentId == null;
                final isChild = node.parentId != null && !node.id.contains('_sub');

                return Card(
                  margin: EdgeInsets.only(
                    left: isRoot ? 0 : (isChild ? 16 : 32),
                    bottom: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Color(node.colorHex).withValues(alpha: 0.5)),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(node.colorHex),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      node.title,
                      style: TextStyle(
                        fontWeight: isRoot
                            ? FontWeight.bold
                            : (isChild ? FontWeight.w600 : FontWeight.normal),
                        fontSize: isRoot ? 15 : (isChild ? 13.5 : 12.5),
                      ),
                    ),
                    subtitle: Text(
                      isRoot
                          ? 'Root Topic'
                          : (isChild ? 'Major Section' : 'Key Insight / Takeaway'),
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: isRoot
                        ? const Chip(label: Text('Central Node'))
                        : Icon(
                            node.isExpanded
                                ? LucideIcons.chevronDown
                                : LucideIcons.chevronRight,
                            size: 16,
                          ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVectorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(LucideIcons.penTool, size: 48, color: Colors.indigo),
                  const SizedBox(height: 12),
                  Text(
                    _selectedFile != null
                        ? 'Vector Canvas for ${_selectedFile!.uri.pathSegments.last}'
                        : 'Vector Annotations Canvas (Pen, Highlighter, Arrow, Sticky Note). Select a document to start drawing.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresentationTab() {
    if (_presentationDeck == null) {
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
                    child: Icon(LucideIcons.presentation, size: 36, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AI Presentation Deck Generator',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a document to automatically summarize headings and key concepts into clean, exportable presentation slides.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _pickDocument,
                    icon: const Icon(LucideIcons.fileUp),
                    label: const Text('Select Document for Slides'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportPresentation,
        icon: const Icon(LucideIcons.download),
        label: const Text('Export Slides PDF'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _presentationDeck!.slides.length,
        itemBuilder: (context, index) {
          final slide = _presentationDeck!.slides[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SLIDE ${index + 1}: ${slide.slideTitle}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                  const Divider(),
                  ...slide.bulletPoints.map((b) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('• $b'),
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
