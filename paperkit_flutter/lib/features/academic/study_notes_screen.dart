import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/document_analysis_result.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import 'academic_tool_scaffold.dart';

class StudyNotesScreen extends StatefulWidget {
  const StudyNotesScreen({super.key});

  @override
  State<StudyNotesScreen> createState() => _StudyNotesScreenState();
}

class _StudyNotesScreenState extends State<StudyNotesScreen> {
  final _focusController = TextEditingController();

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AcademicToolScaffold<Map<String, dynamic>>(
      title: 'Study Notes',
      toolId: 'study-notes',
      toolName: 'Study Notes Generator',
      toolIcon: LucideIcons.bookOpenCheck,
      toolColor: AppColors.toolGreen,
      toolSoftColor: AppColors.toolGreenSoft,
      processingLabel: 'Generate Study Notes',
      filePickerLabel: 'Choose Document (PDF)',
      allowedExtensions: ['pdf', 'txt', 'docx', 'pptx'],
      onProcess: (files) {
        final focus = _focusController.text.trim();
        final focusAreas = focus.isNotEmpty
            ? focus.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty).toList()
            : null;
        return ApiService().generateStudyNotes(file: files.first, focusAreas: focusAreas);
      },
      exportToText: (result) {
        final buf = StringBuffer('# Study Notes: ${result['document_title'] ?? 'Document'}\n\n');
        final notes = result['notes'] as List? ?? [];
        for (final note in notes) {
          buf.writeln('\n## ${note['section'] ?? 'Section'}');
          final kp = note['key_points'] as List? ?? [];
          if (kp.isNotEmpty) {
            buf.writeln('\n**Key Points:**');
            for (final p in kp) {
              buf.writeln('- $p');
            }
          }
          final defs = note['definitions'] as Map? ?? {};
          if (defs.isNotEmpty) {
            buf.writeln('\n**Definitions:**');
            defs.forEach((k, v) => buf.writeln('- **$k**: $v'));
          }
          final formulas = note['formulas'] as List? ?? [];
          if (formulas.isNotEmpty) {
            buf.writeln('\n**Formulas:**');
            for (final f in formulas) {
              buf.writeln('- $f');
            }
          }
        }
        return buf.toString();
      },
      configWidget: (_) => _FocusInput(controller: _focusController),
      resultBuilder: (result, files) {
        final notes = (result['notes'] as List? ?? [])
            .map((n) => StudyNote.fromJson(Map<String, dynamic>.from(n)))
            .toList();

        return Builder(builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            if (result['document_title'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(result['document_title'].toString(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),

            Text('${notes.length} sections',
                style: TextStyle(fontSize: 12.5,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            const SizedBox(height: 12),

            ...notes.map((note) => AcademicResultSection(
              title: note.section,
              icon: LucideIcons.notebookPen,
              accentColor: AppColors.toolGreen,
              initiallyExpanded: notes.indexOf(note) == 0,
              child: _StudyNoteContent(note: note, isDark: isDark),
            )),
          ]);
        });
      },
    );
  }
}

class _FocusInput extends StatelessWidget {
  final TextEditingController controller;
  const _FocusInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Focus Areas (optional)', style: TextStyle(
        fontWeight: FontWeight.w600, fontSize: 13.5,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      )),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'e.g., neural networks, backpropagation, gradient descent',
          hintStyle: const TextStyle(fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        style: const TextStyle(fontSize: 13),
        maxLines: 2,
      ),
      const SizedBox(height: 6),
      Text('Comma-separated topics to focus on',
          style: TextStyle(fontSize: 11.5,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
    ]);
  }
}

class _StudyNoteContent extends StatelessWidget {
  final StudyNote note;
  final bool isDark;

  const _StudyNoteContent({required this.note, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (note.keyPoints.isNotEmpty) ...[
        _SubHeader('Key Points', LucideIcons.checkSquare, AppColors.toolGreen),
        const SizedBox(height: 6),
        BulletList(items: note.keyPoints, bulletColor: AppColors.toolGreen),
        const SizedBox(height: 12),
      ],

      if (note.definitions.isNotEmpty) ...[
        _SubHeader('Definitions', LucideIcons.bookText, AppColors.toolBlue),
        const SizedBox(height: 6),
        ...note.definitions.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: RichText(text: TextSpan(
            style: TextStyle(fontSize: 13, color: textColor, height: 1.5),
            children: [
              TextSpan(text: '${e.key}: ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.toolBlue)),
              TextSpan(text: e.value),
            ],
          )),
        )),
        const SizedBox(height: 12),
      ],

      if (note.importantFacts.isNotEmpty) ...[
        _SubHeader('Important Facts', LucideIcons.alertCircle, AppColors.toolOrange),
        const SizedBox(height: 6),
        BulletList(items: note.importantFacts, bulletColor: AppColors.toolOrange),
        const SizedBox(height: 12),
      ],

      if (note.formulas.isNotEmpty) ...[
        _SubHeader('Formulas & Equations', LucideIcons.squareSigma, AppColors.toolPurple),
        const SizedBox(height: 6),
        ...note.formulas.map((f) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.toolPurple.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.toolPurple.withOpacity(0.2)),
          ),
          child: Row(children: [
            const Icon(LucideIcons.squareSigma, size: 14, color: AppColors.toolPurple),
            const SizedBox(width: 8),
            Expanded(child: Text(f, style: const TextStyle(fontSize: 13, fontFamily: 'monospace'))),
            IconButton(
              onPressed: () => Clipboard.setData(ClipboardData(text: f)),
              icon: const Icon(LucideIcons.copy, size: 13),
              visualDensity: VisualDensity.compact,
              color: AppColors.toolPurple,
            ),
          ]),
        )),
        const SizedBox(height: 12),
      ],

      if (note.examples.isNotEmpty) ...[
        _SubHeader('Examples', LucideIcons.lightbulb, AppColors.toolTeal),
        const SizedBox(height: 6),
        BulletList(items: note.examples, bulletColor: AppColors.toolTeal),
        const SizedBox(height: 12),
      ],

      if (note.examFocusPoints.isNotEmpty) ...[
        _SubHeader('Exam Focus', LucideIcons.star, AppColors.toolRed),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.errorSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.error.withOpacity(0.2)),
          ),
          child: BulletList(items: note.examFocusPoints, bulletColor: AppColors.error),
        ),
      ],
    ]);
  }
}

class _SubHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SubHeader(this.title, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
    ]);
  }
}
