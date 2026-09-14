import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/dual_pane_model.dart';
import '../../core/services/pdf_engine.dart';
import 'workspace_service.dart';

class DualPaneWorkspaceScreen extends StatefulWidget {
  const DualPaneWorkspaceScreen({super.key});

  @override
  State<DualPaneWorkspaceScreen> createState() => _DualPaneWorkspaceScreenState();
}

class _DualPaneWorkspaceScreenState extends State<DualPaneWorkspaceScreen> with SingleTickerProviderStateMixin {
  final WorkspaceService _service = WorkspaceService();
  late TabController _tabController;

  final ScrollController _scrollControllerA = ScrollController();
  final ScrollController _scrollControllerB = ScrollController();

  File? _paneAFile;
  File? _paneBFile;
  String _paneAText = '';
  String _paneBText = '';

  List<PageAnchorNote> _notesPaneA = [];
  bool _syncScroll = false;
  bool _isSyncing = false;

  List<SyllabusCourse> _syllabusCourses = [];
  bool _isLoadingSyllabus = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollControllerA.addListener(_onScrollA);
    _scrollControllerB.addListener(_onScrollB);
    _loadSyllabusData();
  }

  @override
  void dispose() {
    _scrollControllerA.removeListener(_onScrollA);
    _scrollControllerB.removeListener(_onScrollB);
    _scrollControllerA.dispose();
    _scrollControllerB.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSyllabusData() async {
    setState(() => _isLoadingSyllabus = true);
    final courses = await _service.loadSyllabusCourses();
    setState(() {
      _syllabusCourses = courses;
      _isLoadingSyllabus = false;
    });
  }

  // Non-recursive Proportional Sync Scroll Listeners
  void _onScrollA() {
    if (!_syncScroll || _isSyncing) return;
    if (!_scrollControllerA.hasClients || !_scrollControllerB.hasClients) return;

    final maxA = _scrollControllerA.position.maxScrollExtent;
    final maxB = _scrollControllerB.position.maxScrollExtent;
    if (maxA <= 0 || maxB <= 0) return;

    final ratio = (_scrollControllerA.offset / maxA).clamp(0.0, 1.0);
    final targetB = (ratio * maxB).clamp(0.0, maxB);

    _isSyncing = true;
    _scrollControllerB.jumpTo(targetB);
    _isSyncing = false;
  }

  void _onScrollB() {
    if (!_syncScroll || _isSyncing) return;
    if (!_scrollControllerA.hasClients || !_scrollControllerB.hasClients) return;

    final maxA = _scrollControllerA.position.maxScrollExtent;
    final maxB = _scrollControllerB.position.maxScrollExtent;
    if (maxA <= 0 || maxB <= 0) return;

    final ratio = (_scrollControllerB.offset / maxB).clamp(0.0, 1.0);
    final targetA = (ratio * maxA).clamp(0.0, maxA);

    _isSyncing = true;
    _scrollControllerA.jumpTo(targetA);
    _isSyncing = false;
  }

  Future<void> _pickPaneA() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'txt']);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final text = file.path.endsWith('.pdf') ? await PdfEngine.extractTextFromPdf(file) : await file.readAsString();
      final notes = await _service.loadNotesForDocument(file.path);
      setState(() {
        _paneAFile = file;
        _paneAText = text;
        _notesPaneA = notes;
      });
    }
  }

  Future<void> _pickPaneB() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'txt']);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final text = file.path.endsWith('.pdf') ? await PdfEngine.extractTextFromPdf(file) : await file.readAsString();
      setState(() {
        _paneBFile = file;
        _paneBText = text;
      });
    }
  }

  // Syllabus CRUD Dialogs
  Future<void> _showAddCourseDialog() async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final topicsCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Syllabus Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Course Name', hintText: 'e.g. Data Structures'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Course Code', hintText: 'e.g. CS101'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: topicsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Topics/Units (Comma-separated)',
                  hintText: 'e.g. Arrays, Linked Lists, Trees, Graphs',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;

              final topicTitles = topicsCtrl.text
                  .split(',')
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList();

              final topics = topicTitles
                  .map((t) => SyllabusTopic(
                        id: 'topic_${DateTime.now().microsecondsSinceEpoch}_${t.hashCode}',
                        title: t,
                      ))
                  .toList();

              final course = SyllabusCourse(
                id: 'course_${DateTime.now().millisecondsSinceEpoch}',
                courseName: nameCtrl.text.trim(),
                courseCode: codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim() : 'COURSE',
                topics: topics,
              );

              await _service.saveSyllabusCourse(course);
              if (mounted) Navigator.pop(context);
              _loadSyllabusData();
            },
            child: const Text('Save Course'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCourse(String courseId) async {
    await _service.deleteSyllabusCourse(courseId);
    _loadSyllabusData();
  }

  Future<void> _toggleTopic(String courseId, String topicId) async {
    await _service.toggleTopicCompletion(courseId, topicId);
    _loadSyllabusData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dual-Pane Workspace & Productivity'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(LucideIcons.columns), text: 'Dual-Pane Reader'),
            Tab(icon: Icon(LucideIcons.checkSquare), text: 'Syllabus Tracker'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDualPaneTab(),
          _buildSyllabusTab(),
        ],
      ),
    );
  }

  Widget _buildDualPaneTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey.shade200,
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickPaneA,
                icon: const Icon(LucideIcons.fileText),
                label: const Text('Pane A'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _pickPaneB,
                icon: const Icon(LucideIcons.fileText),
                label: const Text('Pane B'),
              ),
              const Spacer(),
              FilterChip(
                label: const Text('Sync Scroll'),
                selected: _syncScroll,
                onSelected: (val) {
                  setState(() => _syncScroll = val);
                  if (val) {
                    _onScrollA();
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              // Pane A
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300))),
                  child: SingleChildScrollView(
                    controller: _scrollControllerA,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(_paneAFile?.uri.pathSegments.last ?? 'Pane A (Empty)', style: const TextStyle(fontWeight: FontWeight.bold))),
                            if (_notesPaneA.isNotEmpty)
                              Chip(label: Text('${_notesPaneA.length} Notes', style: const TextStyle(fontSize: 10))),
                          ],
                        ),
                        const Divider(),
                        Text(_paneAText.isNotEmpty ? _paneAText : 'Load document in Pane A.'),
                      ],
                    ),
                  ),
                ),
              ),
              // Pane B
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    controller: _scrollControllerB,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_paneBFile?.uri.pathSegments.last ?? 'Pane B (Empty)', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Divider(),
                        Text(_paneBText.isNotEmpty ? _paneBText : 'Load document in Pane B.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyllabusTab() {
    final totalCourses = _syllabusCourses.length;
    final totalTopics = _syllabusCourses.fold<int>(0, (sum, c) => sum + c.topics.length);
    final completedTopics = _syllabusCourses.fold<int>(0, (sum, c) => sum + c.topics.where((t) => t.isCompleted).length);
    final overallProgress = totalTopics > 0 ? (completedTopics / totalTopics) * 100 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Academic Syllabus Tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _showAddCourseDialog,
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Add Course'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Overall Progress: ${overallProgress.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('$completedTopics / $totalTopics topics completed', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: totalTopics > 0 ? completedTopics / totalTopics : 0.0,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatChip('Total Courses', '$totalCourses'),
                      _buildStatChip('Total Topics', '$totalTopics'),
                      _buildStatChip('Completed', '$completedTopics'),
                      _buildStatChip('Remaining', '${totalTopics - completedTopics}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingSyllabus)
            const Center(child: CircularProgressIndicator())
          else if (_syllabusCourses.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: const [
                      Icon(LucideIcons.bookOpen, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No courses added yet.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Click "Add Course" to track units, topics, and completion status.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _syllabusCourses.length,
              itemBuilder: (context, index) {
                final course = _syllabusCourses[index];
                final progressPct = (course.progressPercentage * 100).toStringAsFixed(1);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(course.courseCode.substring(0, course.courseCode.length.clamp(0, 3)), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue.shade900)),
                    ),
                    title: Text('${course.courseCode}: ${course.courseName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Progress: $progressPct% (${course.topics.where((t) => t.isCompleted).length}/${course.topics.length} topics)'),
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
                      onPressed: () => _deleteCourse(course.id),
                    ),
                    children: course.topics.isEmpty
                        ? [
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('No topics added to this course.'),
                            )
                          ]
                        : course.topics.map((topic) {
                            return CheckboxListTile(
                              title: Text(topic.title, style: TextStyle(decoration: topic.isCompleted ? TextDecoration.lineThrough : null)),
                              value: topic.isCompleted,
                              onChanged: (val) => _toggleTopic(course.id, topic.id),
                            );
                          }).toList(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
