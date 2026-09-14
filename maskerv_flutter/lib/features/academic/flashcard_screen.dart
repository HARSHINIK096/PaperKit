import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/document_analysis_result.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import 'academic_tool_scaffold.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  int _count = 20;
  final Set<String> _selectedTypes = {'term_definition', 'question_answer'};


  @override
  Widget build(BuildContext context) {
    return AcademicToolScaffold<List<Flashcard>>(
      title: 'Flashcards',
      toolId: 'flashcards',
      toolName: 'Flashcard Generator',
      toolIcon: LucideIcons.layers,
      toolColor: AppColors.toolIndigo,
      toolSoftColor: AppColors.toolIndigoSoft,
      processingLabel: 'Generate Flashcards',
      filePickerLabel: 'Choose Document (PDF)',
      allowedExtensions: ['pdf', 'txt', 'docx', 'pptx'],
      onProcess: (files) async {
        final raw = await ApiService().generateFlashcards(
          file: files.first,
          cardTypes: _selectedTypes.toList(),
          count: _count,
        );
        return (raw['flashcards'] as List? ?? [])
            .map((f) => Flashcard.fromJson(Map<String, dynamic>.from(f)))
            .toList();
      },
      exportToText: (cards) {
        final buf = StringBuffer('# Flashcards (${cards.length})\n\n');
        for (int i = 0; i < cards.length; i++) {
          buf.writeln('Card ${i + 1} [${cards[i].type.name}]');
          buf.writeln('FRONT: ${cards[i].front}');
          buf.writeln('BACK:  ${cards[i].back}');
          buf.writeln();
        }
        return buf.toString();
      },
      configWidget: (_) => _FlashcardConfig(
        selectedTypes: _selectedTypes,
        count: _count,
        onTypeToggle: (t) => setState(() => _selectedTypes.contains(t) ? _selectedTypes.remove(t) : _selectedTypes.add(t)),
        onCountChanged: (c) => setState(() => _count = c),
      ),
      resultBuilder: (cards, files) => _FlashcardDeck(cards: cards),
    );
  }
}

class _FlashcardConfig extends StatelessWidget {
  final Set<String> selectedTypes;
  final int count;
  final void Function(String) onTypeToggle;
  final void Function(int) onCountChanged;

  static const _allTypes = ['term_definition', 'question_answer', 'concept_example', 'formula_explanation'];
  static const _typeLabels = {
    'term_definition': 'Term → Definition',
    'question_answer': 'Question → Answer',
    'concept_example': 'Concept → Example',
    'formula_explanation': 'Formula → Explanation',
  };

  const _FlashcardConfig({
    required this.selectedTypes, required this.count,
    required this.onTypeToggle, required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Card Types', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: _allTypes.map((t) {
          final selected = selectedTypes.contains(t);
          return FilterChip(
            label: Text(_typeLabels[t] ?? t, style: const TextStyle(fontSize: 12)),
            selected: selected,
            onSelected: (_) => onTypeToggle(t),
            selectedColor: AppColors.toolIndigo.withOpacity(0.15),
            checkmarkColor: AppColors.toolIndigo,
            side: BorderSide(color: selected ? AppColors.toolIndigo : (isDark ? AppColors.borderDark : AppColors.borderLight)),
            backgroundColor: isDark ? AppColors.surfaceElevatedDark : Colors.white,
          );
        }).toList()),
        const SizedBox(height: 14),
        Row(children: [
          Text('Number of Cards', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          const Spacer(),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.toolIndigo)),
        ]),
        Slider(
          value: count.toDouble(), min: 5, max: 50, divisions: 9,
          label: '$count', activeColor: AppColors.toolIndigo,
          onChanged: (v) => onCountChanged(v.round()),
        ),
      ]),
    );
  }
}

class _FlashcardDeck extends StatefulWidget {
  final List<Flashcard> cards;
  const _FlashcardDeck({required this.cards});

  @override
  State<_FlashcardDeck> createState() => _FlashcardDeckState();
}

class _FlashcardDeckState extends State<_FlashcardDeck> {
  int _currentIndex = 0;
  bool _flipped = false;
  int _knownCount = 0;

  List<Flashcard> get _cards => widget.cards;

  void _flip() => setState(() => _flipped = !_flipped);

  void _markKnown() {
    setState(() {
      _cards[_currentIndex].isKnown = true;
      _knownCount = _cards.where((c) => c.isKnown).length;
    });
    _next();
  }

  void _next() {
    if (_currentIndex < _cards.length - 1) {
      setState(() { _currentIndex++; _flipped = false; });
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() { _currentIndex--; _flipped = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = _cards[_currentIndex];

    return Column(children: [
      // Progress
      Row(children: [
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _cards.length,
            backgroundColor: AppColors.toolIndigo.withOpacity(0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.toolIndigo),
            minHeight: 6,
          ),
        )),
        const SizedBox(width: 10),
        Text('${_currentIndex + 1} / ${_cards.length}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.toolIndigo)),
      ]),
      const SizedBox(height: 8),
      Text('$_knownCount known · ${_cards.length - _knownCount} to review',
          style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
      const SizedBox(height: 18),

      // Card
      GestureDetector(
        onTap: _flip,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: Container(
            key: ValueKey('${_currentIndex}_$_flipped'),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 200),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _flipped
                    ? [AppColors.toolIndigo.withOpacity(0.15), AppColors.toolPurple.withOpacity(0.08)]
                    : [AppColors.surfaceDark.withOpacity(isDark ? 1 : 0), AppColors.surfaceLight.withOpacity(isDark ? 0 : 1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _flipped ? AppColors.toolIndigo.withOpacity(0.4) : (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: _flipped ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(color: AppColors.toolIndigo.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(_flipped ? 'BACK' : 'FRONT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: _flipped ? AppColors.toolIndigo : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  )),
              const SizedBox(height: 16),
              Text(_flipped ? card.back : card.front,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    height: 1.5,
                  )),
              const SizedBox(height: 16),
              Text('Tap to flip',
                  style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            ]),
          ),
        ),
      ),

      const SizedBox(height: 20),

      // Controls
      Row(children: [
        IconButton.outlined(
          onPressed: _currentIndex > 0 ? _prev : null,
          icon: const Icon(LucideIcons.chevronLeft),
          color: AppColors.toolIndigo,
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _markKnown,
          icon: const Icon(LucideIcons.checkCircle2, size: 16),
          label: const Text('Know it'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.success, side: const BorderSide(color: AppColors.success)),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: _next,
          icon: const Icon(LucideIcons.arrowRight, size: 16),
          label: const Text('Next'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.toolIndigo),
        ),
        const Spacer(),
        IconButton.outlined(
          onPressed: () => setState(() { _currentIndex = 0; _flipped = false; }),
          icon: const Icon(LucideIcons.rotateCcw),
          color: AppColors.toolIndigo,
          tooltip: 'Restart',
        ),
      ]),
    ]);
  }
}
