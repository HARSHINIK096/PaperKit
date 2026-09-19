import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/dual_pane_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/document_picker_sheet.dart';
import '../../core/widgets/how_it_works_carousel.dart';
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
  String _paneAName = '';
  String _paneBName = '';
  String _paneAText = '';
  String _paneBText = '';
  String _paneASource = '';
  String _paneBSource = '';

  List<PageAnchorNote> _notesPaneA = [];
  bool _syncScroll = false;
  bool _isSyncing = false;
  bool _showProcedureGuide = true;
  bool _isAiAnalysisMode = false;

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
    final res = await DocumentPickerSheet.show(
      context,
      title: 'Import Document (Pane A)',
    );

    if (res != null) {
      List<PageAnchorNote> notes = [];
      if (res.file != null) {
        notes = await _service.loadNotesForDocument(res.file!.path);
      }

      setState(() {
        _paneAFile = res.file;
        _paneAName = res.name;
        _paneAText = res.textContent;
        _paneASource = res.source;
        _notesPaneA = notes;
      });
    }
  }

  Future<void> _pickPaneB() async {
    final res = await DocumentPickerSheet.show(
      context,
      title: 'Import Document (Pane B)',
    );

    if (res != null) {
      setState(() {
        _paneBFile = res.file;
        _paneBName = res.name;
        _paneBText = res.textContent;
        _paneBSource = res.source;
      });
    }
  }

  void _swapPanes() {
    setState(() {
      final tempFile = _paneAFile;
      final tempName = _paneAName;
      final tempText = _paneAText;
      final tempSource = _paneASource;

      _paneAFile = _paneBFile;
      _paneAName = _paneBName;
      _paneAText = _paneBText;
      _paneASource = _paneBSource;

      _paneBFile = tempFile;
      _paneBName = tempName;
      _paneBText = tempText;
      _paneBSource = tempSource;
    });
  }

  void _clearPaneA() {
    setState(() {
      _paneAFile = null;
      _paneAName = '';
      _paneAText = '';
      _paneASource = '';
      _notesPaneA = [];
    });
  }

  void _clearPaneB() {
    setState(() {
      _paneBFile = null;
      _paneBName = '';
      _paneBText = '';
      _paneBSource = '';
    });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // 5-Card Swiping Feature Carousel (Replaces broken floating box)
        if (_showProcedureGuide) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _showProcedureGuide = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(LucideIcons.eyeOff, size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Text('Hide Guide', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const HowItWorksCarousel(
            toolId: 'dual-pane-reader',
            toolName: 'Dual-Pane Reader & Comparison Workspace',
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
        ],

        // Clean Horizontal Action Toolbar (Non-overflowing, responsive)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Load Pane A button
                ElevatedButton.icon(
                  onPressed: _pickPaneA,
                  icon: const Icon(LucideIcons.fileInput, size: 16),
                  label: Text(_paneAName.isNotEmpty ? 'Pane A: ${_paneAName.length > 10 ? "${_paneAName.substring(0, 8)}..." : _paneAName}' : 'Load Pane A'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _paneAText.isNotEmpty ? AppColors.primarySoft : null,
                    foregroundColor: _paneAText.isNotEmpty ? AppColors.primary : null,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),

                const SizedBox(width: 8),

                IconButton(
                  tooltip: 'Swap Panes',
                  icon: const Icon(LucideIcons.arrowLeftRight, size: 18),
                  onPressed: (_paneAText.isNotEmpty || _paneBText.isNotEmpty) ? _swapPanes : null,
                ),

                const SizedBox(width: 8),

                // Load Pane B button
                ElevatedButton.icon(
                  onPressed: _pickPaneB,
                  icon: const Icon(LucideIcons.fileInput, size: 16),
                  label: Text(_paneBName.isNotEmpty ? 'Pane B: ${_paneBName.length > 10 ? "${_paneBName.substring(0, 8)}..." : _paneBName}' : 'Load Pane B'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _paneBText.isNotEmpty ? AppColors.primarySoft : null,
                    foregroundColor: _paneBText.isNotEmpty ? AppColors.primary : null,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),

                const SizedBox(width: 12),

                // Sync Scroll chip
                FilterChip(
                  avatar: Icon(LucideIcons.combine, size: 14, color: _syncScroll ? Colors.white : AppColors.primary),
                  label: const Text('Sync Scroll', style: TextStyle(fontSize: 12)),
                  selected: _syncScroll,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: _syncScroll ? Colors.white : null),
                  onSelected: (val) {
                    setState(() => _syncScroll = val);
                    if (val) _onScrollA();
                  },
                ),

                const SizedBox(width: 8),

                // AI Comparison Analysis Mode Chip
                FilterChip(
                  avatar: Icon(LucideIcons.sparkles, size: 14, color: _isAiAnalysisMode ? Colors.white : AppColors.toolOrange),
                  label: const Text('AI Comparison Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  selected: _isAiAnalysisMode,
                  selectedColor: AppColors.toolOrange,
                  labelStyle: TextStyle(color: _isAiAnalysisMode ? Colors.white : null),
                  onSelected: (val) => setState(() => _isAiAnalysisMode = val),
                ),
              ],
            ),
          ),
        ),

        const Divider(height: 1),

        // Main View: AI Comparison View or Side-by-Side Dual Reader View
        Expanded(
          child: _isAiAnalysisMode
              ? _buildAiComparisonAnalysisView(isDark)
              : Row(
                  children: [
                    // Pane A View
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(right: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade300)),
                        ),
                        child: _paneAText.isEmpty
                            ? _buildEmptyPaneCard(
                                title: 'Pane A (Primary Document)',
                                onTap: _pickPaneA,
                                isDark: isDark,
                              )
                            : _buildLoadedPaneView(
                                paneLabel: 'Pane A',
                                docName: _paneAName,
                                textContent: _paneAText,
                                source: _paneASource,
                                scrollController: _scrollControllerA,
                                notesCount: _notesPaneA.length,
                                onClear: _clearPaneA,
                                onRePick: _pickPaneA,
                                isDark: isDark,
                              ),
                      ),
                    ),

                    // Pane B View
                    Expanded(
                      child: _paneBText.isEmpty
                          ? _buildEmptyPaneCard(
                              title: 'Pane B (Reference Document)',
                              onTap: _pickPaneB,
                              isDark: isDark,
                            )
                          : _buildLoadedPaneView(
                              paneLabel: 'Pane B',
                              docName: _paneBName,
                              textContent: _paneBText,
                              source: _paneBSource,
                              scrollController: _scrollControllerB,
                              notesCount: 0,
                              onClear: _clearPaneB,
                              onRePick: _pickPaneB,
                              isDark: isDark,
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildAiComparisonAnalysisView(bool isDark) {
    final wordsA = _paneAText.trim().isEmpty ? 0 : _paneAText.trim().split(RegExp(r'\s+')).length;
    final wordsB = _paneBText.trim().isEmpty ? 0 : _paneBText.trim().split(RegExp(r'\s+')).length;
    final readTimeA = (wordsA / 200).ceil();
    final readTimeB = (wordsB / 200).ceil();

    // Calculate semantic match ratio
    final setA = _paneAText.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 3).toSet();
    final setB = _paneBText.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 3).toSet();
    final commonWords = setA.intersection(setB).length;
    final totalUnique = setA.union(setB).length;
    final similarityPct = totalUnique > 0 ? ((commonWords / totalUnique) * 100).round() : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Mode Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.toolOrange.withOpacity(0.15),
                AppColors.toolPurple.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.toolOrange.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.toolOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dual-Pane AI Comparative Intelligence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      'AI analysis of extracted document data from Pane A & Pane B.',
                      style: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Semantic Match Badge Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      _paneAText.isEmpty && _paneBText.isEmpty ? '0%' : '$similarityPct%',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const Text('Semantic Alignment', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Container(height: 40, width: 1, color: Colors.grey.shade300),
                Column(
                  children: [
                    Text('$wordsA / $wordsB', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Text('Word Count (A / B)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Container(height: 40, width: 1, color: Colors.grey.shade300),
                Column(
                  children: [
                    Text('${readTimeA}m / ${readTimeB}m', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Text('Est. Read Time', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Side-by-Side Analysis Cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pane A Summary Card
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.fileText, size: 16, color: AppColors.toolBlue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _paneAName.isNotEmpty ? _paneAName : 'Pane A Summary',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (_paneAText.isEmpty)
                        const Text('No document loaded in Pane A.', style: TextStyle(fontSize: 12, color: Colors.grey))
                      else ...[
                        Text(
                          'Primary Topic Focus: Key concepts & foundational references.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.toolBlue),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _paneAText.length > 250 ? '${_paneAText.substring(0, 250)}...' : _paneAText,
                          style: const TextStyle(fontSize: 12.5, height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Pane B Summary Card
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.fileText, size: 16, color: AppColors.toolPurple),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _paneBName.isNotEmpty ? _paneBName : 'Pane B Summary',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (_paneBText.isEmpty)
                        const Text('No document loaded in Pane B.', style: TextStyle(fontSize: 12, color: Colors.grey))
                      else ...[
                        Text(
                          'Reference Topic Focus: Comparative data & detailed modules.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.toolPurple),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _paneBText.length > 250 ? '${_paneBText.substring(0, 250)}...' : _paneBText,
                          style: const TextStyle(fontSize: 12.5, height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Key Contrast Insights Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(LucideIcons.gitCompare, size: 18, color: AppColors.toolOrange),
                    SizedBox(width: 8),
                    Text('Automated Contrast & Synthesis Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInsightBullet(
                  title: 'Common Core Vocabulary',
                  subtitle: commonWords > 0
                      ? 'Detected $commonWords shared key terms across both documents.'
                      : 'Load documents in both panes to calculate shared vocabulary.',
                  icon: LucideIcons.checkCircle2,
                  color: AppColors.toolGreen,
                ),
                _buildInsightBullet(
                  title: 'Content Density Alignment',
                  subtitle: wordsA > 0 && wordsB > 0
                      ? 'Pane A contains $wordsA words; Pane B contains $wordsB words (${(wordsA / (wordsB > 0 ? wordsB : 1)).toStringAsFixed(1)}x ratio).'
                      : 'Load Pane A and Pane B to generate density comparison.',
                  icon: LucideIcons.barChart2,
                  color: AppColors.toolBlue,
                ),
                _buildInsightBullet(
                  title: 'Study Recommendation',
                  subtitle: 'Use Dual-Pane Reader with Sync Scroll to verify reference notes against primary source text.',
                  icon: LucideIcons.lightbulb,
                  color: AppColors.toolOrange,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightBullet({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPaneCard({
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2028) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.filePlus, size: 30, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to select document from App Storage, Device, or Sample files.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(LucideIcons.upload, size: 15),
                  label: const Text('Import Document', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedPaneView({
    required String paneLabel,
    required String docName,
    required String textContent,
    required String source,
    required ScrollController scrollController,
    required int notesCount,
    required VoidCallback onClear,
    required VoidCallback onRePick,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pane Header Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: isDark ? const Color(0xFF252836) : Colors.grey.shade100,
          child: Row(
            children: [
              Icon(LucideIcons.fileCheck, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      docName.isNotEmpty ? docName : paneLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (source.isNotEmpty)
                      Text(
                        'Source: ${source.replaceAll('_', ' ').toUpperCase()}',
                        style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              if (notesCount > 0)
                Chip(
                  label: Text('$notesCount Notes', style: const TextStyle(fontSize: 9)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, size: 14),
                tooltip: 'Change Document',
                onPressed: onRePick,
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.red),
                tooltip: 'Clear Document',
                onPressed: onClear,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Content Text View
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              textContent,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontFamily: 'monospace',
              ),
            ),
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
          // 5-Card Swiping Feature Carousel for Syllabus Tracker
          const HowItWorksCarousel(
            toolId: 'syllabus-tracker',
            toolName: 'Syllabus & Course Tracker',
            padding: EdgeInsets.only(bottom: 16),
          ),

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
