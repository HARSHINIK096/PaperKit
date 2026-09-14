import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/document_analysis_result.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import 'academic_tool_scaffold.dart';

class MindMapScreen extends StatelessWidget {
  const MindMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AcademicToolScaffold<MindMapNode>(
      title: 'Mind Map',
      toolId: 'mind-map',
      toolName: 'Mind Map Generator',
      toolIcon: LucideIcons.network,
      toolColor: AppColors.toolPurple,
      toolSoftColor: AppColors.toolPurpleSoft,
      processingLabel: 'Generate Mind Map',
      filePickerLabel: 'Choose Document (PDF)',
      allowedExtensions: ['pdf', 'txt', 'docx', 'pptx'],
      onProcess: (files) async {
        final raw = await ApiService().generateMindMap(file: files.first);
        return MindMapNode.fromJson(Map<String, dynamic>.from(raw['root'] ?? raw));
      },
      exportToText: (root) {
        final buf = StringBuffer();
        _exportNode(buf, root, 0);
        return buf.toString();
      },
      resultBuilder: (root, files) => _MindMapResult(root: root),
    );
  }

  void _exportNode(StringBuffer buf, MindMapNode node, int depth) {
    final indent = '  ' * depth;
    buf.writeln('$indent- ${node.label}');
    for (final child in node.children) {
      _exportNode(buf, child, depth + 1);
    }
  }
}

class _MindMapResult extends StatefulWidget {
  final MindMapNode root;
  const _MindMapResult({required this.root});

  @override
  State<_MindMapResult> createState() => _MindMapResultState();
}

class _MindMapResultState extends State<_MindMapResult> {
  late MindMapNode _root;

  @override
  void initState() {
    super.initState();
    _root = widget.root;
  }

  void _toggleNode(MindMapNode node) {
    setState(() => node.isExpanded = !node.isExpanded);
  }

  void _setAll(bool expand) {
    setState(() {
      _setAllExpanded(_root, expand);
    });
  }

  void _setAllExpanded(MindMapNode node, bool expand) {
    node.isExpanded = expand;
    for (final child in node.children) {
      _setAllExpanded(child, expand);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Controls
      Row(children: [
        const Icon(LucideIcons.network, size: 15, color: AppColors.toolPurple),
        const SizedBox(width: 8),
        Text(_root.label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.toolPurple)),
        const Spacer(),
        TextButton(onPressed: () => _setAll(true), child: const Text('Expand All', style: TextStyle(fontSize: 12))),
        TextButton(onPressed: () => _setAll(false), child: const Text('Collapse All', style: TextStyle(fontSize: 12))),
      ]),
      const SizedBox(height: 12),

      // Tree view
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: _MindMapTree(node: _root, depth: 0, isDark: isDark, onToggle: _toggleNode),
      ),
    ]);
  }
}

class _MindMapTree extends StatelessWidget {
  final MindMapNode node;
  final int depth;
  final bool isDark;
  final void Function(MindMapNode) onToggle;

  const _MindMapTree({required this.node, required this.depth, required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.toolPurple,
      AppColors.toolIndigo,
      AppColors.toolBlue,
      AppColors.toolTeal,
      AppColors.toolGreen,
    ];
    final color = colors[depth % colors.length];
    final hasChildren = node.children.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(left: depth == 0 ? 0 : 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: hasChildren ? () => onToggle(node) : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
            child: Row(children: [
              // Node dot / connector
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: depth == 0 ? color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: depth == 0 ? 0 : 2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  node.label,
                  style: TextStyle(
                    fontSize: depth == 0 ? 15 : depth == 1 ? 13.5 : 12.5,
                    fontWeight: depth == 0 ? FontWeight.w700 : depth == 1 ? FontWeight.w600 : FontWeight.normal,
                    color: depth == 0 ? color : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    height: 1.4,
                  ),
                ),
              ),
              if (hasChildren)
                Icon(
                  node.isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                  size: 16,
                  color: color,
                ),
            ]),
          ),
        ),
        if (hasChildren && node.isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(
                  width: 1.5,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: node.children.map((child) => _MindMapTree(
                      node: child, depth: depth + 1, isDark: isDark, onToggle: onToggle,
                    )).toList(),
                  ),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}
