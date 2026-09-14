import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/document_analysis_result.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import 'academic_tool_scaffold.dart';

class ResearchAnalyzerScreen extends StatelessWidget {
  const ResearchAnalyzerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AcademicToolScaffold<ResearchAnalysisResult>(
      title: 'Research Analyzer',
      toolId: 'research-analyzer',
      toolName: 'Research Paper Analyzer',
      toolIcon: LucideIcons.microscope,
      toolColor: AppColors.toolPurple,
      toolSoftColor: AppColors.toolPurpleSoft,
      processingLabel: 'Analyze Research Paper',
      filePickerLabel: 'Choose Research Paper (PDF)',
      allowedExtensions: ['pdf', 'txt', 'docx'],
      onProcess: (files) async {
        final raw = await ApiService().analyzeResearchPaper(file: files.first);
        return ResearchAnalysisResult.fromJson(raw);
      },
      exportToText: (result) {
        final buf = StringBuffer();
        buf.writeln('# Research Analysis: ${result.title ?? 'Untitled'}');
        if (result.authors.isNotEmpty) buf.writeln('\nAuthors: ${result.authors.join(', ')}');
        if (result.year != null) buf.writeln('Year: ${result.year}');
        if (result.abstractText != null) buf.writeln('\n## Abstract\n${result.abstractText}');
        if (result.researchProblem != null) buf.writeln('\n## Research Problem\n${result.researchProblem}');
        if (result.methodology != null) buf.writeln('\n## Methodology\n${result.methodology}');
        if (result.results != null) buf.writeln('\n## Results\n${result.results}');
        if (result.conclusion != null) buf.writeln('\n## Conclusion\n${result.conclusion}');
        if (result.limitations.isNotEmpty) {
          buf.writeln('\n## Limitations');
          for (final l in result.limitations) {
            buf.writeln('- $l');
          }
        }
        if (result.futureWork.isNotEmpty) {
          buf.writeln('\n## Future Work');
          for (final f in result.futureWork) {
            buf.writeln('- $f');
          }
        }
        return buf.toString();
      },
      resultBuilder: (result, files) => _ResearchResult(result: result),
    );
  }
}

class _ResearchResult extends StatelessWidget {
  final ResearchAnalysisResult result;
  const _ResearchResult({required this.result});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header card
        _HeaderCard(result: result, isDark: isDark),
        const SizedBox(height: 12),

        // Confidence banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.toolPurple.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.info, size: 15, color: AppColors.toolPurple),
              const SizedBox(width: 8),
              const Text('Overall confidence: ', style: TextStyle(fontSize: 12.5)),
              ConfidenceBadge(confidence: result.overallConfidence.name),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (result.abstractText != null && result.abstractText!.isNotEmpty)
          AcademicResultSection(
            title: 'Abstract',
            icon: LucideIcons.fileText,
            accentColor: AppColors.toolPurple,
            child: _CopyableText(text: result.abstractText!, isDark: isDark),
          ),

        if (result.keywords.isNotEmpty)
          AcademicResultSection(
            title: 'Keywords',
            icon: LucideIcons.tag,
            accentColor: AppColors.toolIndigo,
            initiallyExpanded: false,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: result.keywords.map((k) => Chip(
                label: Text(k, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.toolIndigoSoft,
                side: BorderSide.none,
                padding: EdgeInsets.zero,
              )).toList(),
            ),
          ),

        if (result.researchProblem != null && result.researchProblem!.isNotEmpty)
          AcademicResultSection(
            title: 'Research Problem',
            icon: LucideIcons.alertCircle,
            accentColor: AppColors.toolRed,
            child: _CopyableText(text: result.researchProblem!, isDark: isDark),
          ),

        if (result.objectives.isNotEmpty)
          AcademicResultSection(
            title: 'Objectives',
            icon: LucideIcons.target,
            accentColor: AppColors.toolOrange,
            initiallyExpanded: false,
            child: BulletList(items: result.objectives, bulletColor: AppColors.toolOrange),
          ),

        if (result.methodology != null && result.methodology!.isNotEmpty)
          AcademicResultSection(
            title: 'Methodology',
            icon: LucideIcons.flaskConical,
            accentColor: AppColors.toolTeal,
            child: _CopyableText(text: result.methodology!, isDark: isDark),
          ),

        if (result.dataset != null && result.dataset!.isNotEmpty)
          AcademicResultSection(
            title: 'Dataset / Data Sources',
            icon: LucideIcons.database,
            accentColor: AppColors.toolBlue,
            initiallyExpanded: false,
            child: _CopyableText(text: result.dataset!, isDark: isDark),
          ),

        if (result.results != null && result.results!.isNotEmpty)
          AcademicResultSection(
            title: 'Results & Findings',
            icon: LucideIcons.chartLine,
            accentColor: AppColors.toolGreen,
            child: _CopyableText(text: result.results!, isDark: isDark),
          ),

        if (result.metrics.isNotEmpty)
          AcademicResultSection(
            title: 'Evaluation Metrics',
            icon: LucideIcons.gauge,
            accentColor: AppColors.toolGreen,
            initiallyExpanded: false,
            child: BulletList(items: result.metrics, bulletColor: AppColors.toolGreen),
          ),

        if (result.importantFindings.isNotEmpty)
          AcademicResultSection(
            title: 'Important Findings',
            icon: LucideIcons.lightbulb,
            accentColor: AppColors.toolOrange,
            child: BulletList(items: result.importantFindings, bulletColor: AppColors.toolOrange),
          ),

        if (result.limitations.isNotEmpty)
          AcademicResultSection(
            title: 'Limitations',
            icon: LucideIcons.alertTriangle,
            accentColor: AppColors.toolRed,
            initiallyExpanded: false,
            child: BulletList(items: result.limitations, bulletColor: AppColors.toolRed),
          ),

        if (result.conclusion != null && result.conclusion!.isNotEmpty)
          AcademicResultSection(
            title: 'Conclusion',
            icon: LucideIcons.checkCircle,
            accentColor: AppColors.toolPurple,
            child: _CopyableText(text: result.conclusion!, isDark: isDark),
          ),

        if (result.futureWork.isNotEmpty)
          AcademicResultSection(
            title: 'Future Work',
            icon: LucideIcons.arrowRight,
            accentColor: AppColors.toolIndigo,
            initiallyExpanded: false,
            child: BulletList(items: result.futureWork, bulletColor: AppColors.toolIndigo),
          ),

        if (result.references.isNotEmpty)
          AcademicResultSection(
            title: 'References (${result.references.length})',
            icon: LucideIcons.quote,
            accentColor: AppColors.toolOrange,
            initiallyExpanded: false,
            child: Column(
              children: result.references.asMap().entries.map((e) {
                final i = e.key;
                final ref = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '[${i + 1}]',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.toolOrange,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ref.bibliographyEntry ?? ref.title ?? 'Untitled Reference',
                              style: const TextStyle(fontSize: 12.5),
                            ),
                            if (!ref.isComplete && ref.missingFields.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Missing: ${ref.missingFields.join(', ')}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final ResearchAnalysisResult result;
  final bool isDark;

  const _HeaderCard({required this.result, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.toolPurple.withOpacity(0.15),
            AppColors.toolIndigo.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.toolPurple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.title ?? 'Untitled Paper',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (result.authors.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              result.authors.join(', '),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
          if (result.year != null) ...[
            const SizedBox(height: 4),
            Text(
              result.year!,
              style: const TextStyle(fontSize: 12.5, color: AppColors.toolPurple),
            ),
          ],
        ],
      ),
    );
  }
}

class _CopyableText extends StatelessWidget {
  final String text;
  final bool isDark;

  const _CopyableText({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.6,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 2)),
            );
          },
          icon: const Icon(LucideIcons.copy, size: 14),
          label: const Text('Copy', style: TextStyle(fontSize: 12.5)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            foregroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
