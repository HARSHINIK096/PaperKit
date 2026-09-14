import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import 'academic_tool_scaffold.dart';

class CitationFormatterScreen extends StatefulWidget {
  const CitationFormatterScreen({super.key});

  @override
  State<CitationFormatterScreen> createState() => _CitationFormatterScreenState();
}

class _CitationFormatterScreenState extends State<CitationFormatterScreen> {
  String _selectedStyle = 'apa';

  @override
  Widget build(BuildContext context) {
    return AcademicToolScaffold<Map<String, dynamic>>(
      title: 'Citation Formatter',
      toolId: 'citation-formatter',
      toolName: 'Citation Formatter',
      toolIcon: LucideIcons.penLine,
      toolColor: AppColors.toolBlue,
      toolSoftColor: AppColors.toolBlueSoft,
      processingLabel: 'Format Citations',
      filePickerLabel: 'Choose Document with References (PDF)',
      allowedExtensions: ['pdf', 'txt', 'docx'],
      onProcess: (files) => ApiService().formatCitations(file: files.first, style: _selectedStyle),
      exportToText: (result) {
        final buf = StringBuffer('# Citations — ${(result['style'] ?? '').toString().toUpperCase()} Format\n\n');
        final formatted = result['formatted'] as List? ?? [];
        for (int i = 0; i < formatted.length; i++) {
          buf.writeln('[${i + 1}] ${formatted[i]['formatted'] ?? ''}');
        }
        return buf.toString();
      },
      configWidget: (_) => _StyleSelector(
        selected: _selectedStyle,
        onChanged: (s) => setState(() => _selectedStyle = s),
      ),
      resultBuilder: (result, files) {
        final formatted = result['formatted'] as List? ?? [];
        return Builder(builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Style badge header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.toolBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.toolBlue.withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(LucideIcons.penLine, size: 16, color: AppColors.toolBlue),
                const SizedBox(width: 8),
                Text(
                  '${formatted.length} citations formatted as ${(result['style'] ?? '').toString().toUpperCase()}',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.toolBlue),
                ),
              ]),
            ),

            AcademicResultSection(
              title: 'Formatted Citations',
              icon: LucideIcons.bookMarked,
              accentColor: AppColors.toolBlue,
              child: Column(
                children: formatted.asMap().entries.map((e) {
                  final i = e.key;
                  final c = e.value;
                  final isComplete = c['is_complete'] as bool? ?? false;
                  final missing = (c['missing_fields'] as List? ?? []).map((m) => m.toString()).toList();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceElevatedDark : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isComplete
                            ? AppColors.success.withOpacity(0.2)
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text('[${i + 1}]', style: const TextStyle(color: AppColors.toolBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                        const Spacer(),
                        ConfidenceBadge(confidence: isComplete ? 'detected' : 'inferred'),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: c['formatted']?.toString() ?? ''));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
                            );
                          },
                          icon: const Icon(LucideIcons.copy, size: 15),
                          visualDensity: VisualDensity.compact,
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text(c['formatted']?.toString() ?? '', style: const TextStyle(fontSize: 13, height: 1.5)),
                      if (missing.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('Missing fields: ${missing.join(', ')}',
                              style: const TextStyle(fontSize: 11, color: AppColors.warning)),
                        ),
                    ]),
                  );
                }).toList(),
              ),
            ),

            // Copy all
            if (formatted.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: OutlinedButton.icon(
                  onPressed: () {
                    final all = formatted.asMap().entries
                        .map((e) => '[${e.key + 1}] ${e.value['formatted'] ?? ''}')
                        .join('\n\n');
                    Clipboard.setData(ClipboardData(text: all));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All citations copied'), duration: Duration(seconds: 2)),
                    );
                  },
                  icon: const Icon(LucideIcons.clipboardCopy, size: 16),
                  label: const Text('Copy All'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.toolBlue),
                ),
              ),
          ]);
        });
      },
    );
  }
}

class _StyleSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  static const _styles = ['apa', 'mla', 'ieee', 'chicago', 'harvard', 'vancouver'];

  const _StyleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text('Citation Style', style: TextStyle(
          fontWeight: FontWeight.w600, fontSize: 13.5,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        )),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _styles.map((style) {
          final isSelected = selected == style;
          return InkWell(
            onTap: () => onChanged(style),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.toolBlue : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.toolBlue : (isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
              ),
              child: Text(
                style.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }
}
