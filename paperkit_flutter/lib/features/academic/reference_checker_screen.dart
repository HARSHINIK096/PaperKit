import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/document_analysis_result.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import 'academic_tool_scaffold.dart';

class ReferenceCheckerScreen extends StatelessWidget {
  const ReferenceCheckerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AcademicToolScaffold<Map<String, dynamic>>(
      title: 'Reference Checker',
      toolId: 'reference-checker',
      toolName: 'Reference Checker',
      toolIcon: LucideIcons.shieldCheck,
      toolColor: AppColors.toolGreen,
      toolSoftColor: AppColors.toolGreenSoft,
      processingLabel: 'Check References',
      filePickerLabel: 'Choose Document (PDF)',
      allowedExtensions: ['pdf', 'txt', 'docx'],
      onProcess: (files) => ApiService().checkReferences(file: files.first),
      exportToText: (result) {
        final buf = StringBuffer('# Reference Check Report\n\n');
        buf.writeln('Score: ${result['overall_score']}/100');
        buf.writeln(result['summary'] ?? '');
        final issues = result['issues'] as List? ?? [];
        if (issues.isNotEmpty) {
          buf.writeln('\n## Issues Found');
          for (final issue in issues) {
            buf.writeln('\n### ${issue['type']}');
            buf.writeln(issue['description'] ?? '');
            if (issue['source_text'] != null) buf.writeln('Text: ${issue['source_text']}');
          }
        }
        return buf.toString();
      },
      resultBuilder: (result, files) {
        final issues = (result['issues'] as List? ?? [])
            .map((i) => ReferenceIssue.fromJson(Map<String, dynamic>.from(i)))
            .toList();
        final score = result['overall_score'] as int? ?? 100;

        return Builder(builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          // Group issues by type
          final grouped = <ReferenceIssueType, List<ReferenceIssue>>{};
          for (final issue in issues) {
            grouped.putIfAbsent(issue.type, () => []).add(issue);
          }

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Score card
            _ScoreCard(score: score, totalIssues: issues.length, isDark: isDark),
            const SizedBox(height: 14),

            if (result['summary'] != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Text(result['summary'].toString(),
                    style: TextStyle(fontSize: 13.5, height: 1.6,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ),

            // Stats row
            Row(children: [
              _MiniStat(label: '${result['total_in_text_citations'] ?? '—'}', sub: 'in-text', color: AppColors.toolBlue),
              const SizedBox(width: 8),
              _MiniStat(label: '${result['total_bibliography_entries'] ?? '—'}', sub: 'bibliography', color: AppColors.toolOrange),
              const SizedBox(width: 8),
              _MiniStat(label: '${result['matched_citations'] ?? '—'}', sub: 'matched', color: AppColors.success),
              const SizedBox(width: 8),
              _MiniStat(label: '${result['unmatched_citations'] ?? '—'}', sub: 'unmatched', color: AppColors.error),
            ]),
            const SizedBox(height: 14),

            if (issues.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: const Row(children: [
                  Icon(LucideIcons.checkCircle2, color: AppColors.success),
                  SizedBox(width: 12),
                  Expanded(child: Text('No reference issues found!',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.success))),
                ]),
              )
            else
              ...grouped.entries.map((group) {
                final issueColor = _issueColor(group.key);
                final issueLabel = _issueLabel(group.key);
                return AcademicResultSection(
                  title: '$issueLabel (${group.value.length})',
                  icon: _issueIcon(group.key),
                  accentColor: issueColor,
                  initiallyExpanded: group.value.length <= 3,
                  child: Column(
                    children: group.value.map((issue) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: issueColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: issueColor.withOpacity(0.15)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(issue.description, style: const TextStyle(fontSize: 13, height: 1.5)),
                        if (issue.sourceText != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceElevatedDark : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('"${issue.sourceText}"',
                                style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                          ),
                        ],
                        if (issue.sourcePageRef != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: PageRefBadge(pageRef: issue.sourcePageRef),
                          ),
                      ]),
                    )).toList(),
                  ),
                );
              }),
          ]);
        });
      },
    );
  }

  Color _issueColor(ReferenceIssueType type) {
    switch (type) {
      case ReferenceIssueType.missingReference:
      case ReferenceIssueType.malformedReference:
        return AppColors.error;
      case ReferenceIssueType.uncitedReference:
      case ReferenceIssueType.duplicateReference:
        return AppColors.warning;
      case ReferenceIssueType.missingDoi:
      case ReferenceIssueType.inconsistentFormatting:
        return AppColors.toolOrange;
      default:
        return AppColors.toolBlue;
    }
  }

  IconData _issueIcon(ReferenceIssueType type) {
    switch (type) {
      case ReferenceIssueType.missingReference: return LucideIcons.fileX;
      case ReferenceIssueType.uncitedReference: return LucideIcons.fileMinus;
      case ReferenceIssueType.duplicateReference: return LucideIcons.copy;
      case ReferenceIssueType.inconsistentAuthor: return LucideIcons.user;
      case ReferenceIssueType.inconsistentYear: return LucideIcons.calendar;
      case ReferenceIssueType.inconsistentFormatting: return LucideIcons.alignLeft;
      case ReferenceIssueType.missingDoi: return LucideIcons.link;
      case ReferenceIssueType.malformedReference: return LucideIcons.alertTriangle;
      default: return LucideIcons.alertCircle;
    }
  }

  String _issueLabel(ReferenceIssueType type) {
    switch (type) {
      case ReferenceIssueType.missingReference: return 'Missing References';
      case ReferenceIssueType.uncitedReference: return 'Uncited References';
      case ReferenceIssueType.duplicateReference: return 'Duplicate References';
      case ReferenceIssueType.inconsistentAuthor: return 'Inconsistent Authors';
      case ReferenceIssueType.inconsistentYear: return 'Inconsistent Years';
      case ReferenceIssueType.inconsistentFormatting: return 'Formatting Issues';
      case ReferenceIssueType.missingDoi: return 'Missing DOIs';
      case ReferenceIssueType.malformedReference: return 'Malformed References';
      case ReferenceIssueType.orderingIssue: return 'Ordering Issues';
      case ReferenceIssueType.numberingInconsistency: return 'Numbering Issues';
    }
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;
  final int totalIssues;
  final bool isDark;

  const _ScoreCard({required this.score, required this.totalIssues, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = score >= 85 ? AppColors.success : score >= 60 ? AppColors.warning : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 7,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            Text('$score', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
          ]),
        ),
        const SizedBox(width: 18),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            score >= 85 ? 'Good' : score >= 60 ? 'Needs Improvement' : 'Poor',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            totalIssues == 0 ? 'No issues found' : '$totalIssues issue${totalIssues == 1 ? '' : 's'} detected',
            style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ])),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;

  const _MiniStat({required this.label, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(children: [
          Text(label, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
          Text(sub, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10.5)),
        ]),
      ),
    );
  }
}
