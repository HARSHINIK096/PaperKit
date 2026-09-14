import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/document_analysis_result.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import 'academic_tool_scaffold.dart';

class ResearchGapScreen extends StatelessWidget {
  const ResearchGapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AcademicToolScaffold<Map<String, dynamic>>(
      title: 'Research Gap Finder',
      toolId: 'research-gap',
      toolName: 'Research Gap Finder',
      toolIcon: LucideIcons.searchX,
      toolColor: AppColors.toolTeal,
      toolSoftColor: AppColors.toolTealSoft,
      processingLabel: 'Find Research Gaps',
      filePickerLabel: 'Choose Research Paper (PDF)',
      allowedExtensions: ['pdf', 'txt', 'docx'],
      onProcess: (files) => ApiService().researchGaps(file: files.first),
      exportToText: (result) {
        final buf = StringBuffer('# Research Gap Analysis\n\n');
        buf.writeln(result['summary'] ?? '');
        final gaps = result['gaps'] as List? ?? [];
        for (int i = 0; i < gaps.length; i++) {
          final g = gaps[i];
          buf.writeln('\n## Gap ${i + 1}: ${g['gap_type'] ?? 'General'}');
          buf.writeln(g['gap'] ?? '');
          buf.writeln('\n**Evidence:** ${g['evidence'] ?? ''}');
          final qs = (g['potential_research_questions'] as List? ?? []);
          if (qs.isNotEmpty) {
            buf.writeln('\n**Research Questions:**');
            for (final q in qs) {
              buf.writeln('- $q');
            }
          }
        }
        return buf.toString();
      },
      resultBuilder: (result, files) {
        final gaps = (result['gaps'] as List? ?? [])
            .map((g) => ResearchGap.fromJson(Map<String, dynamic>.from(g)))
            .toList();
        final limitations = result['limitations_stated_by_authors'] as List? ?? [];
        final methodGaps = result['methodological_concerns'] as List? ?? [];
        final datasetGaps = result['dataset_gaps'] as List? ?? [];
        final evalGaps = result['evaluation_gaps'] as List? ?? [];

        return Builder(builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (result['summary'] != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.toolTeal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.toolTeal.withOpacity(0.2)),
                ),
                child: Text(result['summary'].toString(),
                    style: TextStyle(fontSize: 13.5, height: 1.6,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ),

            if (gaps.isNotEmpty)
              AcademicResultSection(
                title: 'Identified Gaps (${gaps.length})',
                icon: LucideIcons.searchX,
                accentColor: AppColors.toolTeal,
                child: Column(
                  children: gaps.asMap().entries.map((e) {
                    final i = e.key;
                    final gap = e.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceElevatedDark : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.toolTealSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Gap ${i + 1} · ${gap.gapType}',
                                style: const TextStyle(color: AppColors.toolTeal, fontSize: 11.5, fontWeight: FontWeight.w600)),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        Text(gap.gap, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text('Evidence: ${gap.evidence}',
                            style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                        if (gap.potentialResearchQuestions.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text('Potential Research Questions:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                          const SizedBox(height: 6),
                          BulletList(items: gap.potentialResearchQuestions, bulletColor: AppColors.toolTeal, fontSize: 12.5),
                        ],
                      ]),
                    );
                  }).toList(),
                ),
              ),

            if (limitations.isNotEmpty)
              AcademicResultSection(
                title: 'Author-Stated Limitations',
                icon: LucideIcons.alertTriangle,
                accentColor: AppColors.toolOrange,
                initiallyExpanded: false,
                child: BulletList(items: limitations.map((l) => l.toString()).toList(), bulletColor: AppColors.toolOrange),
              ),

            if (methodGaps.isNotEmpty)
              AcademicResultSection(
                title: 'Methodological Concerns',
                icon: LucideIcons.flaskConical,
                accentColor: AppColors.toolRed,
                initiallyExpanded: false,
                child: BulletList(items: methodGaps.map((m) => m.toString()).toList(), bulletColor: AppColors.toolRed),
              ),

            if (datasetGaps.isNotEmpty)
              AcademicResultSection(
                title: 'Dataset Gaps',
                icon: LucideIcons.database,
                accentColor: AppColors.toolBlue,
                initiallyExpanded: false,
                child: BulletList(items: datasetGaps.map((d) => d.toString()).toList(), bulletColor: AppColors.toolBlue),
              ),

            if (evalGaps.isNotEmpty)
              AcademicResultSection(
                title: 'Evaluation Gaps',
                icon: LucideIcons.gauge,
                accentColor: AppColors.toolPurple,
                initiallyExpanded: false,
                child: BulletList(items: evalGaps.map((e) => e.toString()).toList(), bulletColor: AppColors.toolPurple),
              ),
          ]);
        });
      },
    );
  }
}
