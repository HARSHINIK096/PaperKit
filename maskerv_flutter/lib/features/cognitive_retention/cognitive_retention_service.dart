import 'dart:async';
import 'dart:math';
import '../../core/models/study_session_model.dart';
import '../../core/services/storage_service.dart';

class CognitiveRetentionService {
  final StorageService _storage = StorageService();

  // Spaced Repetition Scheduling Algorithm (SuperMemo 2 / Leitner 5-Box hybrid)
  RecallItem rateCardRecall(RecallItem card, CardDifficulty difficulty) {
    card.reviewCount++;
    card.lastReviewedAt = DateTime.now();

    switch (difficulty) {
      case CardDifficulty.easy:
        card.successCount++;
        card.leitnerBox = min(5, card.leitnerBox + 1);
        final nextDays = pow(2, card.leitnerBox).toInt();
        card.nextReviewAt = DateTime.now().add(Duration(days: nextDays));
        break;

      case CardDifficulty.medium:
        card.successCount++;
        final nextDays = max(1, pow(1.5, card.leitnerBox).toInt());
        card.nextReviewAt = DateTime.now().add(Duration(days: nextDays));
        break;

      case CardDifficulty.hard:
        // Keep in current box, review in 1 day
        card.nextReviewAt = DateTime.now().add(const Duration(days: 1));
        break;

      case CardDifficulty.forgotten:
        card.leitnerBox = 1;
        card.nextReviewAt = DateTime.now().add(const Duration(hours: 4));
        break;
    }

    return card;
  }

  // Extract key terms & definitions for Blur-to-Recall from document text
  List<RecallItem> extractRecallItemsFromText(String text, {required String documentPath}) {
    final List<RecallItem> items = [];
    if (text.trim().isEmpty) return items;

    final lines = text.split(RegExp(r'\r?\n'));
    int index = 0;

    for (final line in lines) {
      String trimmed = line.trim();
      // Remove leading bullets or list numbering like "1.", "•", "-", "*"
      trimmed = trimmed.replaceAll(RegExp(r'^[\u2022\u25CF\u25CB\u25A0\*\-\d+\.\)]\s*'), '').trim();
      if (trimmed.isEmpty) continue;

      // Check for common definition separators: ":", " - ", " – ", " = ", " refers to ", " is defined as "
      String? term;
      String? definition;

      if (trimmed.contains(':')) {
        final parts = trimmed.split(':');
        if (parts.length >= 2 && parts[0].trim().length >= 2 && parts[0].trim().length <= 50 && parts[1].trim().length >= 8) {
          term = parts[0].trim();
          definition = parts.sublist(1).join(':').trim();
        }
      } else if (trimmed.contains(' - ') || trimmed.contains(' – ')) {
        final sep = trimmed.contains(' - ') ? ' - ' : ' – ';
        final parts = trimmed.split(sep);
        if (parts.length >= 2 && parts[0].trim().length >= 2 && parts[0].trim().length <= 50 && parts[1].trim().length >= 8) {
          term = parts[0].trim();
          definition = parts.sublist(1).join(sep).trim();
        }
      } else if (trimmed.contains(' is defined as ')) {
        final parts = trimmed.split(' is defined as ');
        term = parts[0].trim();
        definition = 'is defined as ${parts[1].trim()}';
      } else if (trimmed.contains(' refers to ')) {
        final parts = trimmed.split(' refers to ');
        term = parts[0].trim();
        definition = 'refers to ${parts[1].trim()}';
      }

      if (term != null && definition != null) {
        // Clean markdown bold/italics
        final cleanTerm = term.replaceAll(RegExp(r'[\*\_\`]'), '').trim();
        final cleanDef = definition.replaceAll(RegExp(r'[\*\_\`]'), '').trim();

        if (cleanTerm.isNotEmpty && cleanDef.isNotEmpty) {
          items.add(
            RecallItem(
              id: 'recall_${DateTime.now().millisecondsSinceEpoch}_$index',
              term: cleanTerm,
              definition: cleanDef,
              sourceDocumentPath: documentPath,
              pageIndex: 0,
              isBlurred: true,
              leitnerBox: 1,
            ),
          );
          index++;
        }
      }
    }

    // Fallback: If no structured key-value lines found, split by sentences & extract key concepts
    if (items.isEmpty) {
      final sentences = text.split(RegExp(r'\.|\n'));
      for (final sentence in sentences) {
        final cleanSentence = sentence.trim();
        if (cleanSentence.length < 15) continue;

        final words = cleanSentence.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();
        if (words.length >= 5) {
          // Find longest or key word (>5 chars)
          final termWord = words.firstWhere(
            (w) => w.length > 5 && !w.startsWith('http'),
            orElse: () => words.first,
          );
          final cleanTerm = termWord.replaceAll(RegExp(r'[^\w\-]'), '').trim();

          if (cleanTerm.isNotEmpty) {
            items.add(
              RecallItem(
                id: 'recall_${DateTime.now().millisecondsSinceEpoch}_$index',
                term: cleanTerm,
                definition: cleanSentence,
                sourceDocumentPath: documentPath,
                pageIndex: 0,
                isBlurred: true,
                leitnerBox: 1,
              ),
            );
            index++;
            if (items.length >= 15) break;
          }
        }
      }
    }

    return items;
  }

  // Generate Sample Starter Flashcard Deck for demonstration / immediate study
  List<RecallItem> getSampleStudyCards() {
    return [
      RecallItem(
        id: 'sample_1',
        term: 'Active Recall',
        definition: 'The learning practice of stimulating memory during the learning process by testing oneself on key concepts.',
        sourceDocumentPath: 'Sample Study Guide',
        leitnerBox: 1,
      ),
      RecallItem(
        id: 'sample_2',
        term: 'Spaced Repetition',
        definition: 'An evidence-based learning technique where reviews are spaced at increasing intervals to exploit the psychological spacing effect.',
        sourceDocumentPath: 'Sample Study Guide',
        leitnerBox: 1,
      ),
      RecallItem(
        id: 'sample_3',
        term: 'Leitner 5-Box System',
        definition: 'A method of using flashcards where cards are moved through 5 boxes based on correct or incorrect responses.',
        sourceDocumentPath: 'Sample Study Guide',
        leitnerBox: 2,
      ),
      RecallItem(
        id: 'sample_4',
        term: 'Forgetting Curve',
        definition: 'Hypothesis formulated by Hermann Ebbinghaus describing the decline of memory retention over time without reinforcement.',
        sourceDocumentPath: 'Sample Study Guide',
        leitnerBox: 1,
      ),
      RecallItem(
        id: 'sample_5',
        term: 'Pomodoro Technique',
        definition: 'Time management framework breaking study work into 25-minute focused intervals separated by short rest breaks.',
        sourceDocumentPath: 'Sample Study Guide',
        leitnerBox: 3,
      ),
    ];
  }

  // Persistent Deck Management
  Future<List<StudyDeck>> loadDecks() async {
    final rawList = await _storage.getStudyDecks();
    return rawList.map((m) => StudyDeck.fromJson(m)).toList();
  }

  Future<void> saveDeck(StudyDeck deck) async {
    final decks = await loadDecks();
    decks.removeWhere((d) => d.id == deck.id);
    decks.insert(0, deck);
    await _storage.saveStudyDecks(decks.map((d) => d.toJson()).toList());
  }

  Future<void> deleteDeck(String deckId) async {
    final decks = await loadDecks();
    decks.removeWhere((d) => d.id == deckId);
    await _storage.saveStudyDecks(decks.map((d) => d.toJson()).toList());
  }
}
