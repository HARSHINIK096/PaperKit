import 'dart:async';
import 'dart:math';
import '../../core/models/study_session_model.dart';
import '../../core/services/storage_service.dart';

class CognitiveRetentionService {
  final StorageService _storage = StorageService();

  // Spaced Repetition Scheduling Algorithm (SuperMemo 2 / Leitner hybrid)
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

  // Extract key terms & definitions for Blur-to-Recall
  List<RecallItem> extractRecallItemsFromText(String text, {required String documentPath}) {
    final List<RecallItem> items = [];
    final lines = text.split(RegExp(r'\r?\n'));

    int index = 0;
    for (final line in lines) {
      final trimmed = line.trim();
      // Detect definition formats like "Term: definition" or "Term - definition"
      if (trimmed.contains(':') || trimmed.contains(' - ')) {
        final parts = trimmed.contains(':') ? trimmed.split(':') : trimmed.split(' - ');
        if (parts.length >= 2 && parts[0].trim().length < 40 && parts[1].trim().length > 10) {
          items.add(
            RecallItem(
              id: 'recall_${DateTime.now().millisecondsSinceEpoch}_$index',
              term: parts[0].trim(),
              definition: parts.sublist(1).join(' ').trim(),
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

    // Fallback: If no structured lines, split by key sentences with keywords
    if (items.isEmpty) {
      final sentences = text.split(RegExp(r'\.|\n'));
      for (final sentence in sentences) {
        final words = sentence.trim().split(RegExp(r'\s+'));
        if (words.length >= 6) {
          final termWord = words.firstWhere((w) => w.length > 5, orElse: () => words[0]);
          items.add(
            RecallItem(
              id: 'recall_${DateTime.now().millisecondsSinceEpoch}_$index',
              term: termWord.replaceAll(RegExp(r'[^\w]'), ''),
              definition: sentence.trim(),
              sourceDocumentPath: documentPath,
              pageIndex: 0,
              isBlurred: true,
              leitnerBox: 1,
            ),
          );
          index++;
          if (items.length >= 10) break;
        }
      }
    }

    return items;
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
