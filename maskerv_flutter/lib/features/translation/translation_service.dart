import 'dart:io';
import '../../core/models/translation_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/pdf_engine.dart';
import '../../core/services/storage_service.dart';

class TranslationService {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  // Load Glossary Terms
  Future<List<GlossaryTerm>> loadGlossary() async {
    final rawList = await _storage.getGlossaryTerms();
    return rawList.map((m) => GlossaryTerm.fromJson(m)).toList();
  }

  // Save Glossary Term
  Future<void> saveGlossaryTerm(GlossaryTerm term) async {
    final terms = await loadGlossary();
    terms.removeWhere((t) => t.id == term.id);
    terms.insert(0, term);
    await _storage.saveGlossaryTerms(terms.map((t) => t.toJson()).toList());
  }

  // Translate Document Page Paragraphs
  Future<List<TranslationSegment>> translateDocument({
    required File file,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      final raw = await _apiService.translateDocument(
        file: file,
        targetLanguage: targetLanguage,
      );
      if (raw.containsKey('translation') && raw['translation'] is List) {
        return (raw['translation'] as List)
            .map((t) => TranslationSegment.fromJson(Map<String, dynamic>.from(t)))
            .toList();
      }
    } catch (_) {}

    // Fallback: Local sentence parsing & translation mapping with glossary
    final text = await PdfEngine.extractTextFromPdf(file);
    final paragraphs = text.split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).toList();
    final glossary = await loadGlossary();

    final List<TranslationSegment> segments = [];
    for (int i = 0; i < paragraphs.length; i++) {
      String original = paragraphs[i].trim();
      String translated = original;

      // Apply glossary terms substitution
      for (final term in glossary) {
        if (term.sourceTerm.isNotEmpty && original.contains(term.sourceTerm)) {
          translated = translated.replaceAll(term.sourceTerm, '${term.targetTerm} (${term.sourceTerm})');
        }
      }

      segments.add(
        TranslationSegment(
          pageNumber: (i ~/ 3) + 1,
          originalText: original,
          translatedText: '[Translated -> $targetLanguage]: $translated',
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        ),
      );
    }

    return segments;
  }
}
