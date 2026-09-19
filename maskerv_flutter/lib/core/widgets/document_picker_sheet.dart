import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/document_file.dart';
import '../providers/files_provider.dart';
import '../services/pdf_engine.dart';
import '../theme/app_colors.dart';

class SelectedDocumentResult {
  final File? file;
  final String name;
  final String textContent;
  final String source; // 'app_storage', 'device', 'sample', 'pasted'

  SelectedDocumentResult({
    this.file,
    required this.name,
    required this.textContent,
    required this.source,
  });
}

class DocumentPickerSheet extends StatefulWidget {
  final String title;
  final int initialTab;
  final List<String> allowedExtensions;
  final ValueChanged<SelectedDocumentResult>? onSelected;

  const DocumentPickerSheet({
    super.key,
    this.title = 'Import / Select Document',
    this.initialTab = 0,
    this.allowedExtensions = const ['pdf', 'txt', 'doc', 'docx'],
    this.onSelected,
  });

  static Future<SelectedDocumentResult?> show(
    BuildContext context, {
    String title = 'Import / Select Document',
    int initialTab = 0,
    List<String> allowedExtensions = const ['pdf', 'txt', 'doc', 'docx'],
  }) {
    return showModalBottomSheet<SelectedDocumentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DocumentPickerSheet(
        title: title,
        initialTab: initialTab,
        allowedExtensions: allowedExtensions,
        onSelected: (result) => Navigator.of(ctx).pop(result),
      ),
    );
  }

  @override
  State<DocumentPickerSheet> createState() => _DocumentPickerSheetState();
}

class _DocumentPickerSheetState extends State<DocumentPickerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _pasteCtrl = TextEditingController();
  final TextEditingController _pasteTitleCtrl = TextEditingController();

  String _searchQuery = '';
  bool _isExtracting = false;

  final List<Map<String, String>> _sampleDocs = [
    {
      'title': 'Academic Research Paper (Sample)',
      'subtitle': 'Deep Learning Architectures in Document Processing',
      'ext': 'txt',
      'content': '''# Deep Learning Architectures in Document Processing

## Abstract
Recent advancements in multi-modal transformers have revolutionized document understanding. This study evaluates dual-pane document comparison and semantic extraction pipelines.

## 1. Introduction
Document processing pipelines require high-throughput text parsing, structural alignment, and real-time layout analysis. In academic workflows, comparing source literature against synthesized notes is vital.

## 2. Methodology
We analyze two key metrics:
- Structural Similarity Index (SSIM) across structural blocks.
- Semantic Alignment via embeddings for contextual diff detection.

## 3. Findings
Proportional sync-scrolling reduces cognitive fatigue by 42% when reviewing multi-page manuscripts alongside summarized syllabus modules.

## 4. Conclusion
Integrating side-by-side verification with automated cross-referencing drastically improves reading comprehension and study retention.''',
    },
    {
      'title': 'Computer Science Syllabus (Sample)',
      'subtitle': 'CS301: Data Structures & Algorithms Overview',
      'ext': 'txt',
      'content': '''# CS301: Data Structures & Algorithms

## Unit 1: Linear Data Structures
- Arrays, Dynamic Arrays, and Memory Allocation
- Singly & Doubly Linked Lists
- Stacks & Queues: Implementation and Complexity

## Unit 2: Trees & Graphs
- Binary Search Trees (BST) & AVL Tree Rotations
- Graph Representations: Adjacency Matrix vs List
- Traversal Algorithms: Depth-First Search (DFS) & Breadth-First Search (BFS)

## Unit 3: Sorting & Searching
- Quicksort, Mergesort, Heapsort performance analysis
- Binary Search and Hash Map collision resolution

## Unit 4: Advanced Topics
- Dynamic Programming & Greedy Algorithms
- Min-Cut / Max-Flow and Graph Shortest Paths (Dijkstra)''',
    },
    {
      'title': 'Legal Agreement Template (Sample)',
      'subtitle': 'Non-Disclosure & Data Usage Policy',
      'ext': 'txt',
      'content': '''# Non-Disclosure Agreement (NDA)

This Agreement is entered into on this day for the purpose of preventing unauthorized disclosure of Confidential Information.

1. Definition of Confidential Information:
All data, source code, document structures, and user analytics stored within MaskerV workspace.

2. Obligations:
The Receiving Party shall maintain secrecy and limit access strictly to authorized personnel.

3. Duration:
This agreement shall remain effective for a period of two (2) years from the effective date.''',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _pasteCtrl.dispose();
    _pasteTitleCtrl.dispose();
    super.dispose();
  }

  void _finishSelect(SelectedDocumentResult res) {
    if (widget.onSelected != null) {
      widget.onSelected!(res);
    } else {
      Navigator.of(context).pop(res);
    }
  }

  Future<void> _pickFromDevice() async {
    HapticFeedback.lightImpact();
    setState(() => _isExtracting = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.allowedExtensions,
      );

      if (result.isNotEmpty && result.single.path != null) {
        final file = File(result.single.path!);
        final name = result.single.name;
        String content = '';
        if (name.toLowerCase().endsWith('.pdf')) {
          content = await PdfEngine.extractTextFromPdf(file);
        } else {
          content = await file.readAsString();
        }

        _finishSelect(SelectedDocumentResult(
          file: file,
          name: name,
          textContent: content,
          source: 'device',
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading device file: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  Future<void> _selectAppStorageFile(DocumentFile docFile) async {
    HapticFeedback.lightImpact();
    setState(() => _isExtracting = true);
    try {
      final file = File(docFile.path);
      String content = '';
      if (file.existsSync()) {
        if (docFile.name.toLowerCase().endsWith('.pdf')) {
          content = await PdfEngine.extractTextFromPdf(file);
        } else {
          content = await file.readAsString();
        }
      } else {
        content = 'Content for ${docFile.name} (File path: ${docFile.path})';
      }

      _finishSelect(SelectedDocumentResult(
        file: file.existsSync() ? file : null,
        name: docFile.name,
        textContent: content,
        source: 'app_storage',
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stored document: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  void _selectSampleDoc(Map<String, String> sample) {
    HapticFeedback.lightImpact();
    _finishSelect(SelectedDocumentResult(
      file: null,
      name: '${sample['title']}.${sample['ext']}',
      textContent: sample['content'] ?? '',
      source: 'sample',
    ));
  }

  void _submitPastedText() {
    final text = _pasteCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or paste some document text.')),
      );
      return;
    }
    final title = _pasteTitleCtrl.text.trim().isNotEmpty
        ? _pasteTitleCtrl.text.trim()
        : 'Pasted Document (${DateTime.now().minute}:${DateTime.now().second})';

    _finishSelect(SelectedDocumentResult(
      file: null,
      name: title,
      textContent: text,
      source: 'pasted',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E2028) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(LucideIcons.fileInput, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(icon: Icon(LucideIcons.folder, size: 16), text: 'App Storage'),
                  Tab(icon: Icon(LucideIcons.uploadCloud, size: 16), text: 'Device Storage'),
                  Tab(icon: Icon(LucideIcons.bookOpen, size: 16), text: 'Sample Docs'),
                  Tab(icon: Icon(LucideIcons.clipboard, size: 16), text: 'Paste Text'),
                ],
              ),

              const Divider(height: 1),

              if (_isExtracting)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Extracting & loading document...'),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAppStorageTab(isDark, scrollController),
                      _buildDeviceStorageTab(isDark),
                      _buildSampleDocsTab(isDark),
                      _buildPasteTextTab(isDark),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppStorageTab(bool isDark, ScrollController scrollController) {
    return Consumer<FilesProvider>(
      builder: (context, filesProv, _) {
        final allFiles = filesProv.files;
        final filteredFiles = allFiles.where((f) {
          if (_searchQuery.isEmpty) return true;
          return f.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search stored documents...',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF282A36) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: filteredFiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.folderOpen, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            allFiles.isEmpty ? 'No stored documents in MaskerV library' : 'No matching documents',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            allFiles.isEmpty ? 'Import files from Device Storage or use Sample Docs.' : 'Try a different search query.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filteredFiles.length,
                      itemBuilder: (ctx, idx) {
                        final doc = filteredFiles[idx];
                        final isPdf = doc.name.toLowerCase().endsWith('.pdf');
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPdf ? Colors.red.shade100 : Colors.blue.shade100,
                            child: Icon(
                              isPdf ? LucideIcons.fileText : LucideIcons.fileCode,
                              color: isPdf ? Colors.red.shade800 : Colors.blue.shade800,
                              size: 20,
                            ),
                          ),
                          title: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(
                            '${(doc.size / 1024).toStringAsFixed(1)} KB • Stored Document',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(LucideIcons.chevronRight, size: 18),
                          onTap: () => _selectAppStorageFile(doc),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceStorageTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.folderUp, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pick Document from Device',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Supports PDF documents, text files, markdown, and docx format.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pickFromDevice,
            icon: const Icon(LucideIcons.fileSearch),
            label: const Text('Open System File Selector'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleDocsTab(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sampleDocs.length,
      itemBuilder: (ctx, idx) {
        final sample = _sampleDocs[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: AppColors.primarySoft,
              child: const Icon(LucideIcons.bookMarked, color: AppColors.primary, size: 20),
            ),
            title: Text(sample['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(sample['subtitle']!, style: const TextStyle(fontSize: 12)),
            ),
            trailing: ElevatedButton(
              onPressed: () => _selectSampleDoc(sample),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Use Sample'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasteTextTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _pasteTitleCtrl,
            decoration: InputDecoration(
              labelText: 'Document Title (Optional)',
              hintText: 'e.g. Lecture 5 Notes',
              filled: true,
              fillColor: isDark ? const Color(0xFF282A36) : Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _pasteCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Paste or write document text here...',
                filled: true,
                fillColor: isDark ? const Color(0xFF282A36) : Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _submitPastedText,
            icon: const Icon(LucideIcons.check),
            label: const Text('Load Pasted Text into Feature'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
