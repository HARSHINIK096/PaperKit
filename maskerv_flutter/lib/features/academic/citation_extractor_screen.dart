import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/document_analysis_result.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import 'academic_tool_scaffold.dart';

class CitationExtractorScreen extends StatelessWidget {
  const CitationExtractorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AcademicToolScaffold<Map<String, dynamic>>(
      title: 'Citation Extractor',
      toolId: 'citation-extractor',
      toolName: 'Citation Extractor',
      toolIcon: LucideIcons.quote,
      toolColor: AppColors.toolOrange,
      toolSoftColor: AppColors.toolOrangeSoft,
      processingLabel: 'Extract Citations',
      filePickerLabel: 'Choose Document (PDF)',
      allowedExtensions: ['pdf', 'txt', 'docx'],
      onProcess: (files) => ApiService().extractCitations(file: files.first),
      exportToText: (result) {
        final buf = StringBuffer('# Extracted Citations\n\n');
        final bibliography = result['bibliography'] as List? ?? [];
        for (int i = 0; i < bibliography.length; i++) {
          final c = bibliography[i];
          buf.writeln('[${i + 1}] ${c['bibliography_entry'] ?? c['title'] ?? ''}');
          if (c['doi'] != null) buf.writeln('    DOI: ${c['doi']}');
          if (c['url'] != null) buf.writeln('    URL: ${c['url']}');
        }
        return buf.toString();
      },
      resultBuilder: (result, files) {
        final bibliography = (result['bibliography'] as List? ?? [])
            .map((c) => Citation.fromJson(Map<String, dynamic>.from(c)))
            .toList();
        final inText = result['in_text_citations'] as List? ?? [];

        return Builder(builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Summary row
            Row(children: [
              _StatChip(label: '${result['total_bibliography'] ?? bibliography.length}', sublabel: 'bibliography', color: AppColors.toolOrange),
              const SizedBox(width: 10),
              _StatChip(label: '${result['total_in_text'] ?? inText.length}', sublabel: 'in-text', color: AppColors.toolBlue),
              const SizedBox(width: 10),
              _StatChip(
                label: '${bibliography.where((c) => c.isComplete).length}',
                sublabel: 'complete',
                color: AppColors.success,
              ),
            ]),
            const SizedBox(height: 14),

            AcademicResultSection(
              title: 'Bibliography (${bibliography.length})',
              icon: LucideIcons.bookMarked,
              accentColor: AppColors.toolOrange,
              child: Column(
                children: bibliography.asMap().entries.map((e) {
                  final i = e.key;
                  final c = e.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceElevatedDark : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text('[${i + 1}]', style: const TextStyle(color: AppColors.toolOrange, fontWeight: FontWeight.bold, fontSize: 13)),
                        const Spacer(),
                        ConfidenceBadge(confidence: c.isComplete ? 'detected' : 'inferred'),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: c.bibliographyEntry ?? ''));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
                            );
                          },
                          icon: const Icon(LucideIcons.copy, size: 15),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Copy citation',
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(c.bibliographyEntry ?? c.title ?? 'Untitled', style: const TextStyle(fontSize: 13)),
                      if (c.authors.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Authors: ${c.authors.join(', ')}',
                            style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                      ],
                      if (c.year != null) Text('Year: ${c.year}',
                          style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                      if (c.doi != null) Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('DOI: ${c.doi}', style: const TextStyle(fontSize: 11.5, color: AppColors.primary)),
                      ),
                      if (!c.isComplete && c.missingFields.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('Missing: ${c.missingFields.join(', ')}',
                              style: const TextStyle(fontSize: 11, color: AppColors.warning)),
                        ),
                    ]),
                  );
                }).toList(),
              ),
            ),

            if (inText.isNotEmpty)
              AcademicResultSection(
                title: 'In-Text Citations (${inText.length})',
                icon: LucideIcons.textQuote,
                accentColor: AppColors.toolBlue,
                initiallyExpanded: false,
                child: Column(
                  children: inText.map<Widget>((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      const Icon(LucideIcons.quote, size: 14, color: AppColors.toolBlue),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c['in_text']?.toString() ?? '', style: const TextStyle(fontSize: 13))),
                      if (c['source_page_ref'] != null)
                        PageRefBadge(pageRef: c['source_page_ref'] as int?),
                    ]),
                  )).toList(),
                ),
              ),
          ]);
        });
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;

  const _StatChip({required this.label, required this.sublabel, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text(label, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          Text(sublabel, style: TextStyle(color: color.withOpacity(0.75), fontSize: 11.5)),
        ]),
      ),
    );
  }
}
