import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import 'academic_tool_scaffold.dart';

class LiteratureReviewScreen extends StatelessWidget {
  const LiteratureReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AcademicToolScaffold<Map<String, dynamic>>(
      title: 'Literature Review',
      toolId: 'literature-review',
      toolName: 'Literature Review',
      toolIcon: LucideIcons.bookOpen,
      toolColor: AppColors.toolIndigo,
      toolSoftColor: AppColors.toolIndigoSoft,
      processingLabel: 'Generate Literature Review',
      filePickerLabel: 'Choose 2–8 Research Papers (PDF)',
      allowedExtensions: ['pdf', 'txt', 'docx'],
      allowMultiple: true,
      onProcess: (files) async {
        if (files.length < 2) {
          throw Exception('A literature review requires at least 2 papers. Please select 2 or more PDF files.');
        }
        return await ApiService().literatureReview(files: files);
      },
      exportToText: (result) {
        final buf = StringBuffer('# Literature Review\n\n');
        buf.writeln(result['overview'] ?? '');
        final themes = result['research_themes'] as List? ?? [];
        if (themes.isNotEmpty) {
          buf.writeln('\n## Research Themes');
          for (final t in themes) {
            buf.writeln('\n### ${t['theme']}');
            buf.writeln(t['description'] ?? '');
          }
        }
        buf.writeln('\n## Synthesis\n${result['synthesis'] ?? ''}');
        return buf.toString();
      },
      resultBuilder: (result, files) => _LiteratureReviewResult(result: result),
    );
  }
}

class _LiteratureReviewResult extends StatelessWidget {
  final Map<String, dynamic> result;
  const _LiteratureReviewResult({required this.result});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themes = result['research_themes'] as List? ?? [];
    final findings = result['key_findings'] as List? ?? [];
    final conflicts = result['conflicts'] as List? ?? [];
    final gaps = result['identified_gaps'] as List? ?? [];
    final future = result['recommended_future_directions'] as List? ?? [];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (result['overview'] != null)
        AcademicResultSection(
          title: 'Overview',
          icon: LucideIcons.bookOpen,
          accentColor: AppColors.toolIndigo,
          child: Text(result['overview'].toString(),
              style: TextStyle(fontSize: 13.5, height: 1.6,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        ),

      if (themes.isNotEmpty)
        AcademicResultSection(
          title: 'Research Themes (${themes.length})',
          icon: LucideIcons.layers,
          accentColor: AppColors.toolPurple,
          child: Column(
            children: themes.map<Widget>((t) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.toolPurple.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t['theme']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 4),
                Text(t['description']?.toString() ?? '', style: TextStyle(fontSize: 12.5,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                if ((t['supporting_papers'] as List?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, children: (t['supporting_papers'] as List).map((p) =>
                    Chip(label: Text(p.toString(), style: const TextStyle(fontSize: 11)),
                      backgroundColor: AppColors.toolIndigoSoft, padding: EdgeInsets.zero,
                      side: BorderSide.none, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)
                  ).toList()),
                ],
              ]),
            )).toList(),
          ),
        ),

      if (findings.isNotEmpty)
        AcademicResultSection(
          title: 'Key Findings (${findings.length})',
          icon: LucideIcons.lightbulb,
          accentColor: AppColors.toolGreen,
          child: Column(children: findings.map<Widget>((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(LucideIcons.checkCircle2, size: 16, color: AppColors.toolGreen),
              const SizedBox(width: 10),
              Expanded(child: Text(f['finding']?.toString() ?? '',
                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
            ]),
          )).toList()),
        ),

      if (conflicts.isNotEmpty)
        AcademicResultSection(
          title: 'Conflicting Views (${conflicts.length})',
          icon: LucideIcons.gitBranchPlus,
          accentColor: AppColors.toolRed,
          initiallyExpanded: false,
          child: Column(children: conflicts.map<Widget>((c) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.errorSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c['topic']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              ...((c['positions'] as Map?)?.entries ?? <MapEntry>[]).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.error)),
                  Expanded(child: Text(e.value.toString(), style: const TextStyle(fontSize: 12.5))),
                ]),
              )),
            ]),
          )).toList()),
        ),

      if (result['synthesis'] != null)
        AcademicResultSection(
          title: 'Synthesis',
          icon: LucideIcons.combine,
          accentColor: AppColors.toolTeal,
          child: Text(result['synthesis'].toString(),
              style: TextStyle(fontSize: 13.5, height: 1.6,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        ),

      if (gaps.isNotEmpty)
        AcademicResultSection(
          title: 'Identified Gaps',
          icon: LucideIcons.searchX,
          accentColor: AppColors.toolOrange,
          initiallyExpanded: false,
          child: BulletList(items: gaps.map((g) => g.toString()).toList(), bulletColor: AppColors.toolOrange),
        ),

      if (future.isNotEmpty)
        AcademicResultSection(
          title: 'Future Directions',
          icon: LucideIcons.arrowRight,
          accentColor: AppColors.toolBlue,
          initiallyExpanded: false,
          child: BulletList(items: future.map((f) => f.toString()).toList(), bulletColor: AppColors.toolBlue),
        ),
    ]);
  }
}
