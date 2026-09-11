import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/document_analysis_result.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import 'academic_tool_scaffold.dart';

class QuizGeneratorScreen extends StatefulWidget {
  const QuizGeneratorScreen({super.key});

  @override
  State<QuizGeneratorScreen> createState() => _QuizGeneratorScreenState();
}

class _QuizGeneratorScreenState extends State<QuizGeneratorScreen> {
  final Set<String> _selectedTypes = {'mcq', 'true_false', 'short_answer'};
  String _difficulty = 'medium';
  int _count = 10;


  @override
  Widget build(BuildContext context) {
    return AcademicToolScaffold<List<QuizQuestion>>(
      title: 'Quiz Generator',
      toolId: 'quiz-generator',
      toolName: 'Quiz Generator',
      toolIcon: LucideIcons.clipboard,
      toolColor: AppColors.toolRed,
      toolSoftColor: AppColors.toolRedSoft,
      processingLabel: 'Generate Quiz',
      filePickerLabel: 'Choose Document (PDF)',
      allowedExtensions: ['pdf', 'txt', 'docx', 'pptx'],
      onProcess: (files) async {
        final raw = await ApiService().generateQuiz(
          file: files.first,
          questionTypes: _selectedTypes.toList(),
          difficulty: _difficulty,
          count: _count,
        );
        final questions = (raw['questions'] as List? ?? [])
            .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q)))
            .toList();
        return questions;
      },
      exportToText: (questions) {
        final buf = StringBuffer('# Generated Quiz\n\n');
        for (int i = 0; i < questions.length; i++) {
          final q = questions[i];
          buf.writeln('Q${i + 1}. [${q.type.label}] [${q.difficulty.name}] ${q.question}');
          for (final opt in q.options) buf.writeln('   $opt');
          buf.writeln('Answer: ${q.answer}');
          buf.writeln('Explanation: ${q.explanation}');
          buf.writeln();
        }
        return buf.toString();
      },
      configWidget: (_) => _QuizConfig(
        selectedTypes: _selectedTypes,
        difficulty: _difficulty,
        count: _count,
        onTypeToggle: (t) => setState(() => _selectedTypes.contains(t) ? _selectedTypes.remove(t) : _selectedTypes.add(t)),
        onDifficultyChanged: (d) => setState(() => _difficulty = d),
        onCountChanged: (c) => setState(() => _count = c),
      ),
      resultBuilder: (questions, files) => _QuizResult(questions: questions),
    );
  }
}

class _QuizConfig extends StatelessWidget {
  final Set<String> selectedTypes;
  final String difficulty;
  final int count;
  final void Function(String) onTypeToggle;
  final void Function(String) onDifficultyChanged;
  final void Function(int) onCountChanged;

  static const _allTypes = ['mcq', 'true_false', 'fill_in_blank', 'short_answer', 'long_answer'];
  static const _typeLabels = {
    'mcq': 'Multiple Choice',
    'true_false': 'True / False',
    'fill_in_blank': 'Fill Blank',
    'short_answer': 'Short Answer',
    'long_answer': 'Long Answer',
  };
  static const _difficulties = ['easy', 'medium', 'hard'];

  const _QuizConfig({
    required this.selectedTypes, required this.difficulty, required this.count,
    required this.onTypeToggle, required this.onDifficultyChanged, required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Question Types', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: textColor)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: _allTypes.map((t) {
          final selected = selectedTypes.contains(t);
          return FilterChip(
            label: Text(_typeLabels[t] ?? t, style: const TextStyle(fontSize: 12)),
            selected: selected,
            onSelected: (_) => onTypeToggle(t),
            selectedColor: AppColors.toolRed.withOpacity(0.15),
            checkmarkColor: AppColors.toolRed,
            side: BorderSide(color: selected ? AppColors.toolRed : (isDark ? AppColors.borderDark : AppColors.borderLight)),
            backgroundColor: isDark ? AppColors.surfaceElevatedDark : Colors.white,
          );
        }).toList()),

        const SizedBox(height: 14),
        Text('Difficulty', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: textColor)),
        const SizedBox(height: 8),
        Row(children: _difficulties.map((d) {
          final isSelected = difficulty == d;
          final color = d == 'easy' ? AppColors.success : d == 'medium' ? AppColors.warning : AppColors.error;
          return Expanded(child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => onDifficultyChanged(d),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.15) : (isDark ? AppColors.surfaceElevatedDark : Colors.white),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? color : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                ),
                child: Text(d[0].toUpperCase() + d.substring(1),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isSelected ? color : subColor, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
          ));
        }).toList()),

        const SizedBox(height: 14),
        Row(children: [
          Text('Number of Questions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: textColor)),
          const Spacer(),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.toolRed)),
        ]),
        Slider(
          value: count.toDouble(),
          min: 5,
          max: 30,
          divisions: 5,
          label: '$count',
          activeColor: AppColors.toolRed,
          onChanged: (v) => onCountChanged(v.round()),
        ),
      ]),
    );
  }
}

class _QuizResult extends StatefulWidget {
  final List<QuizQuestion> questions;
  const _QuizResult({required this.questions});

  @override
  State<_QuizResult> createState() => _QuizResultState();
}

class _QuizResultState extends State<_QuizResult> {
  final Map<int, bool> _revealed = {};
  final Map<int, String?> _selected = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Summary
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.toolRed.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.toolRed.withOpacity(0.2)),
        ),
        child: Row(children: [
          const Icon(LucideIcons.clipboard, size: 16, color: AppColors.toolRed),
          const SizedBox(width: 8),
          Text('${widget.questions.length} questions generated',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.toolRed)),
        ]),
      ),

      ...widget.questions.asMap().entries.map((e) {
        final i = e.key;
        final q = e.value;
        final revealed = _revealed[i] ?? false;
        final selected = _selected[i];
        final diffColor = q.difficulty == QuizDifficulty.easy ? AppColors.success
            : q.difficulty == QuizDifficulty.hard ? AppColors.error : AppColors.warning;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Question header
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.toolRedSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Q${i + 1}', style: const TextStyle(color: AppColors.toolRed, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(q.type.label, style: const TextStyle(fontSize: 11)),
                backgroundColor: AppColors.toolBlue.withOpacity(0.1),
                padding: EdgeInsets.zero,
                side: BorderSide.none,
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: diffColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(q.difficulty.name, style: TextStyle(color: diffColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              if (q.sourceSection != null) ...[
                const Spacer(),
                Text(q.sourceSection!, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ],
            ]),
            const SizedBox(height: 10),

            // Question text
            Text(q.question, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.4)),
            const SizedBox(height: 12),

            // Options for MCQ / T-F
            if (q.options.isNotEmpty)
              ...q.options.map((opt) {
                final isCorrect = revealed && opt.startsWith(q.answer);
                final isSelected = selected == opt;
                Color? bgColor;
                if (revealed && isCorrect) bgColor = AppColors.successSoft;
                else if (revealed && isSelected) bgColor = AppColors.errorSoft;

                return GestureDetector(
                  onTap: revealed ? null : () => setState(() => _selected[i] = opt),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: bgColor ?? (isSelected
                          ? AppColors.primary.withOpacity(0.08)
                          : (isDark ? AppColors.surfaceElevatedDark : AppColors.backgroundLight)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: revealed && isCorrect ? AppColors.success
                            : revealed && isSelected ? AppColors.error
                            : isSelected ? AppColors.primary
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                    ),
                    child: Text(opt, style: TextStyle(
                      fontSize: 13.5,
                      color: revealed && isCorrect ? AppColors.success
                          : revealed && isSelected ? AppColors.error
                          : null,
                    )),
                  ),
                );
              }),

            const SizedBox(height: 10),

            // Reveal / Answer
            if (!revealed)
              OutlinedButton(
                onPressed: () => setState(() => _revealed[i] = true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.toolRed,
                  side: const BorderSide(color: AppColors.toolRed),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text('Reveal Answer', style: TextStyle(fontSize: 13)),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(LucideIcons.checkCircle2, size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text('Answer: ${q.answer}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                  ]),
                  if (q.explanation.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(q.explanation, style: const TextStyle(fontSize: 12.5, height: 1.4)),
                  ],
                ]),
              ),
          ]),
        );
      }),
    ]);
  }
}
