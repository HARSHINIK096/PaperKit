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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
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

  Widget _buildMindMapTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickDocument,
            icon: const Icon(LucideIcons.fileUp),
            label: const Text('Generate Mind Map from PDF'),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_nodes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Select a PDF to automatically extract heading structures and build an interactive hierarchical mind map graph.'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _nodes.length,
              itemBuilder: (context, index) {
                final node = _nodes[index];
                return Card(
                  color: Color(node.colorHex).withOpacity(0.15),
                  child: ListTile(
                    leading: Icon(node.parentId == null ? LucideIcons.circleDot : LucideIcons.cornerDownRight),
                    title: Text(node.title, style: TextStyle(fontWeight: node.parentId == null ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text('ID: ${node.id}'),
                  ),
                );
              },
            ),
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
      return const Center(child: Text('Load a document to generate presentation slides.'));
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
