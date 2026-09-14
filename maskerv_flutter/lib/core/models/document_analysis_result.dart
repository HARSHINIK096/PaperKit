// ignore_for_file: public_member_api_docs

/// Confidence level for an extracted piece of information.
enum ExtractionConfidence {
  /// Directly extracted from document text.
  detected,
  /// Derived or inferred from document content by AI.
  inferred,
  /// Not found or insufficient information in the document.
  unavailable,
}

extension ExtractionConfidenceExt on ExtractionConfidence {
  String get label {
    switch (this) {
      case ExtractionConfidence.detected:
        return 'Detected';
      case ExtractionConfidence.inferred:
        return 'Inferred';
      case ExtractionConfidence.unavailable:
        return 'Unavailable';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DOCUMENT SECTION
// ─────────────────────────────────────────────────────────────────────────────

class DocumentSection {
  final String title;
  final String content;
  final int? pageStart;
  final int? pageEnd;
  final ExtractionConfidence confidence;

  const DocumentSection({
    required this.title,
    required this.content,
    this.pageStart,
    this.pageEnd,
    this.confidence = ExtractionConfidence.detected,
  });

  factory DocumentSection.fromJson(Map<String, dynamic> json) {
    return DocumentSection(
      title: (json['title'] as String? ?? '').trim(),
      content: (json['content'] as String? ?? '').trim(),
      pageStart: json['page_start'] as int?,
      pageEnd: json['page_end'] as int?,
      confidence: _parseConfidence(json['confidence']),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'page_start': pageStart,
        'page_end': pageEnd,
        'confidence': confidence.name,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// DOCUMENT ENTITY
// ─────────────────────────────────────────────────────────────────────────────

class DocumentEntity {
  final String text;
  final String type; // person, org, location, date, technology, dataset, etc.
  final int? pageRef;
  final ExtractionConfidence confidence;

  const DocumentEntity({
    required this.text,
    required this.type,
    this.pageRef,
    this.confidence = ExtractionConfidence.detected,
  });

  factory DocumentEntity.fromJson(Map<String, dynamic> json) {
    return DocumentEntity(
      text: (json['text'] as String? ?? '').trim(),
      type: (json['type'] as String? ?? 'unknown').trim(),
      pageRef: json['page_ref'] as int?,
      confidence: _parseConfidence(json['confidence']),
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'type': type,
        'page_ref': pageRef,
        'confidence': confidence.name,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// DOCUMENT TABLE
// ─────────────────────────────────────────────────────────────────────────────

class DocumentTable {
  final String? title;
  final List<String> headers;
  final List<List<String>> rows;
  final int? sourcePageRef;

  const DocumentTable({
    this.title,
    required this.headers,
    required this.rows,
    this.sourcePageRef,
  });

  factory DocumentTable.fromJson(Map<String, dynamic> json) {
    final rawHeaders = json['headers'];
    final rawRows = json['rows'];

    final headers = rawHeaders is List
        ? rawHeaders.map((h) => h.toString()).toList()
        : <String>[];

    final rows = rawRows is List
        ? rawRows.map<List<String>>((row) {
            if (row is List) return row.map((c) => c.toString()).toList();
            return [row.toString()];
          }).toList()
        : <List<String>>[];

    return DocumentTable(
      title: json['title'] as String?,
      headers: headers,
      rows: rows,
      sourcePageRef: json['source_page_ref'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'headers': headers,
        'rows': rows,
        'source_page_ref': sourcePageRef,
      };

  /// Convert table to CSV string.
  String toCsv() {
    final buffer = StringBuffer();
    if (headers.isNotEmpty) {
      buffer.writeln(headers.map(_escapeCsv).join(','));
    }
    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsv).join(','));
    }
    return buffer.toString();
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CITATION
// ─────────────────────────────────────────────────────────────────────────────

class Citation {
  final String? inText;
  final String? bibliographyEntry;
  final String? doi;
  final String? url;
  final String? title;
  final List<String> authors;
  final String? year;
  final String? journal;
  final String? volume;
  final String? issue;
  final String? pages;
  final String? publisher;
  final String? style; // apa, mla, ieee, chicago, harvard, vancouver
  final bool isComplete;
  final List<String> missingFields;
  final int? sourcePageRef;

  const Citation({
    this.inText,
    this.bibliographyEntry,
    this.doi,
    this.url,
    this.title,
    this.authors = const [],
    this.year,
    this.journal,
    this.volume,
    this.issue,
    this.pages,
    this.publisher,
    this.style,
    this.isComplete = false,
    this.missingFields = const [],
    this.sourcePageRef,
  });

  factory Citation.fromJson(Map<String, dynamic> json) {
    final rawAuthors = json['authors'];
    final authors = rawAuthors is List
        ? rawAuthors.map((a) => a.toString()).toList()
        : <String>[];

    final rawMissing = json['missing_fields'];
    final missing = rawMissing is List
        ? rawMissing.map((m) => m.toString()).toList()
        : <String>[];

    return Citation(
      inText: json['in_text'] as String?,
      bibliographyEntry: json['bibliography_entry'] as String?,
      doi: json['doi'] as String?,
      url: json['url'] as String?,
      title: json['title'] as String?,
      authors: authors,
      year: json['year']?.toString(),
      journal: json['journal'] as String?,
      volume: json['volume']?.toString(),
      issue: json['issue']?.toString(),
      pages: json['pages'] as String?,
      publisher: json['publisher'] as String?,
      style: json['style'] as String?,
      isComplete: json['is_complete'] as bool? ?? false,
      missingFields: missing,
      sourcePageRef: json['source_page_ref'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'in_text': inText,
        'bibliography_entry': bibliographyEntry,
        'doi': doi,
        'url': url,
        'title': title,
        'authors': authors,
        'year': year,
        'journal': journal,
        'volume': volume,
        'issue': issue,
        'pages': pages,
        'publisher': publisher,
        'style': style,
        'is_complete': isComplete,
        'missing_fields': missingFields,
        'source_page_ref': sourcePageRef,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// RESEARCH ANALYSIS RESULT
// ─────────────────────────────────────────────────────────────────────────────

class ResearchAnalysisResult {
  final String? title;
  final List<String> authors;
  final String? year;
  final String? abstractText;
  final List<String> keywords;
  final String? researchProblem;
  final List<String> objectives;
  final List<String> researchQuestions;
  final String? hypothesis;
  final String? methodology;
  final String? dataset;
  final String? experiments;
  final String? results;
  final List<String> metrics;
  final List<String> limitations;
  final String? conclusion;
  final List<String> futureWork;
  final List<Citation> references;
  final List<String> importantFindings;
  final List<DocumentSection> sections;
  final ExtractionConfidence overallConfidence;

  const ResearchAnalysisResult({
    this.title,
    this.authors = const [],
    this.year,
    this.abstractText,
    this.keywords = const [],
    this.researchProblem,
    this.objectives = const [],
    this.researchQuestions = const [],
    this.hypothesis,
    this.methodology,
    this.dataset,
    this.experiments,
    this.results,
    this.metrics = const [],
    this.limitations = const [],
    this.conclusion,
    this.futureWork = const [],
    this.references = const [],
    this.importantFindings = const [],
    this.sections = const [],
    this.overallConfidence = ExtractionConfidence.detected,
  });

  factory ResearchAnalysisResult.fromJson(Map<String, dynamic> json) {
    List<String> toStringList(dynamic val) =>
        val is List ? val.map((e) => e.toString()).toList() : <String>[];

    List<Citation> toCitations(dynamic val) =>
        val is List
            ? val
                .whereType<Map<String, dynamic>>()
                .map(Citation.fromJson)
                .toList()
            : <Citation>[];

    List<DocumentSection> toSections(dynamic val) =>
        val is List
            ? val
                .whereType<Map<String, dynamic>>()
                .map(DocumentSection.fromJson)
                .toList()
            : <DocumentSection>[];

    return ResearchAnalysisResult(
      title: json['title'] as String?,
      authors: toStringList(json['authors']),
      year: json['year']?.toString(),
      abstractText: json['abstract'] as String?,
      keywords: toStringList(json['keywords']),
      researchProblem: json['research_problem'] as String?,
      objectives: toStringList(json['objectives']),
      researchQuestions: toStringList(json['research_questions']),
      hypothesis: json['hypothesis'] as String?,
      methodology: json['methodology'] as String?,
      dataset: json['dataset'] as String?,
      experiments: json['experiments'] as String?,
      results: json['results'] as String?,
      metrics: toStringList(json['metrics']),
      limitations: toStringList(json['limitations']),
      conclusion: json['conclusion'] as String?,
      futureWork: toStringList(json['future_work']),
      references: toCitations(json['references']),
      importantFindings: toStringList(json['important_findings']),
      sections: toSections(json['sections']),
      overallConfidence: _parseConfidence(json['overall_confidence']),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESEARCH GAP
// ─────────────────────────────────────────────────────────────────────────────

class ResearchGap {
  final String gap;
  final String evidence;
  final List<String> sourcePapers;
  final String? sourceSection;
  final List<String> potentialResearchQuestions;
  final String gapType; // methodology, dataset, evaluation, technology, etc.

  const ResearchGap({
    required this.gap,
    required this.evidence,
    this.sourcePapers = const [],
    this.sourceSection,
    this.potentialResearchQuestions = const [],
    this.gapType = 'general',
  });

  factory ResearchGap.fromJson(Map<String, dynamic> json) {
    List<String> toStringList(dynamic val) =>
        val is List ? val.map((e) => e.toString()).toList() : <String>[];

    return ResearchGap(
      gap: (json['gap'] as String? ?? '').trim(),
      evidence: (json['evidence'] as String? ?? '').trim(),
      sourcePapers: toStringList(json['source_papers']),
      sourceSection: json['source_section'] as String?,
      potentialResearchQuestions:
          toStringList(json['potential_research_questions']),
      gapType: (json['gap_type'] as String? ?? 'general').trim(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STUDY NOTE
// ─────────────────────────────────────────────────────────────────────────────

class StudyNote {
  final String section;
  final List<String> keyPoints;
  final Map<String, String> definitions; // term → definition
  final List<String> importantFacts;
  final List<String> formulas;
  final List<String> examples;
  final List<String> examFocusPoints;
  final int? sourcePageRef;

  const StudyNote({
    required this.section,
    this.keyPoints = const [],
    this.definitions = const {},
    this.importantFacts = const [],
    this.formulas = const [],
    this.examples = const [],
    this.examFocusPoints = const [],
    this.sourcePageRef,
  });

  factory StudyNote.fromJson(Map<String, dynamic> json) {
    List<String> toStringList(dynamic val) =>
        val is List ? val.map((e) => e.toString()).toList() : <String>[];

    Map<String, String> toStringMap(dynamic val) {
      if (val is Map) {
        return val.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      return {};
    }

    return StudyNote(
      section: (json['section'] as String? ?? '').trim(),
      keyPoints: toStringList(json['key_points']),
      definitions: toStringMap(json['definitions']),
      importantFacts: toStringList(json['important_facts']),
      formulas: toStringList(json['formulas']),
      examples: toStringList(json['examples']),
      examFocusPoints: toStringList(json['exam_focus_points']),
      sourcePageRef: json['source_page_ref'] as int?,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUIZ QUESTION
// ─────────────────────────────────────────────────────────────────────────────

enum QuizQuestionType { mcq, trueFalse, fillInBlank, shortAnswer, longAnswer }

extension QuizQuestionTypeExt on QuizQuestionType {
  String get label {
    switch (this) {
      case QuizQuestionType.mcq:
        return 'Multiple Choice';
      case QuizQuestionType.trueFalse:
        return 'True / False';
      case QuizQuestionType.fillInBlank:
        return 'Fill in the Blank';
      case QuizQuestionType.shortAnswer:
        return 'Short Answer';
      case QuizQuestionType.longAnswer:
        return 'Long Answer';
    }
  }
}

enum QuizDifficulty { easy, medium, hard }

class QuizQuestion {
  final String question;
  final QuizQuestionType type;
  final QuizDifficulty difficulty;
  final List<String> options; // for MCQ / T-F
  final String answer;
  final String explanation;
  final String? sourceSection;
  final int? sourcePageRef;

  const QuizQuestion({
    required this.question,
    required this.type,
    required this.difficulty,
    this.options = const [],
    required this.answer,
    required this.explanation,
    this.sourceSection,
    this.sourcePageRef,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    List<String> toStringList(dynamic val) =>
        val is List ? val.map((e) => e.toString()).toList() : <String>[];

    return QuizQuestion(
      question: (json['question'] as String? ?? '').trim(),
      type: _parseQuestionType(json['type']),
      difficulty: _parseDifficulty(json['difficulty']),
      options: toStringList(json['options']),
      answer: (json['answer'] as String? ?? '').trim(),
      explanation: (json['explanation'] as String? ?? '').trim(),
      sourceSection: json['source_section'] as String?,
      sourcePageRef: json['source_page_ref'] as int?,
    );
  }

  static QuizQuestionType _parseQuestionType(dynamic val) {
    switch ((val ?? '').toString().toLowerCase().replaceAll(' ', '_')) {
      case 'mcq':
      case 'multiple_choice':
        return QuizQuestionType.mcq;
      case 'true_false':
      case 'truefalse':
        return QuizQuestionType.trueFalse;
      case 'fill_in_blank':
      case 'fill_in_the_blank':
        return QuizQuestionType.fillInBlank;
      case 'long_answer':
        return QuizQuestionType.longAnswer;
      default:
        return QuizQuestionType.shortAnswer;
    }
  }

  static QuizDifficulty _parseDifficulty(dynamic val) {
    switch ((val ?? '').toString().toLowerCase()) {
      case 'easy':
        return QuizDifficulty.easy;
      case 'hard':
        return QuizDifficulty.hard;
      default:
        return QuizDifficulty.medium;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FLASHCARD
// ─────────────────────────────────────────────────────────────────────────────

enum FlashcardType { termDefinition, questionAnswer, conceptExample, formulaExplanation }

class Flashcard {
  final String front;
  final String back;
  final FlashcardType type;
  final String? sourceSection;
  final int? sourcePageRef;
  bool isKnown;

  Flashcard({
    required this.front,
    required this.back,
    this.type = FlashcardType.termDefinition,
    this.sourceSection,
    this.sourcePageRef,
    this.isKnown = false,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      front: (json['front'] as String? ?? '').trim(),
      back: (json['back'] as String? ?? '').trim(),
      type: _parseFlashcardType(json['type']),
      sourceSection: json['source_section'] as String?,
      sourcePageRef: json['source_page_ref'] as int?,
    );
  }

  static FlashcardType _parseFlashcardType(dynamic val) {
    switch ((val ?? '').toString().toLowerCase().replaceAll(' ', '_')) {
      case 'question_answer':
      case 'qa':
        return FlashcardType.questionAnswer;
      case 'concept_example':
        return FlashcardType.conceptExample;
      case 'formula_explanation':
        return FlashcardType.formulaExplanation;
      default:
        return FlashcardType.termDefinition;
    }
  }

  Flashcard copyWith({bool? isKnown}) =>
      Flashcard(
        front: front,
        back: back,
        type: type,
        sourceSection: sourceSection,
        sourcePageRef: sourcePageRef,
        isKnown: isKnown ?? this.isKnown,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// MIND MAP NODE
// ─────────────────────────────────────────────────────────────────────────────

class MindMapNode {
  final String id;
  final String label;
  final List<MindMapNode> children;
  final String? sourceRef;
  bool isExpanded;

  MindMapNode({
    required this.id,
    required this.label,
    this.children = const [],
    this.sourceRef,
    this.isExpanded = true,
  });

  factory MindMapNode.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    final children = rawChildren is List
        ? rawChildren
            .whereType<Map<String, dynamic>>()
            .map(MindMapNode.fromJson)
            .toList()
        : <MindMapNode>[];

    return MindMapNode(
      id: (json['id'] as String? ?? UniqueKey().toString()),
      label: (json['label'] as String? ?? '').trim(),
      children: children,
      sourceRef: json['source_ref'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRESENTATION SLIDE
// ─────────────────────────────────────────────────────────────────────────────

class PresentationSlide {
  final int slideNumber;
  final String title;
  final List<String> bulletPoints;
  final String? notes;
  final String? sourceRef;
  final String slideType; // title, agenda, intro, methodology, results, conclusion, references

  const PresentationSlide({
    required this.slideNumber,
    required this.title,
    this.bulletPoints = const [],
    this.notes,
    this.sourceRef,
    this.slideType = 'content',
  });

  factory PresentationSlide.fromJson(Map<String, dynamic> json) {
    List<String> toStringList(dynamic val) =>
        val is List ? val.map((e) => e.toString()).toList() : <String>[];

    return PresentationSlide(
      slideNumber: json['slide_number'] as int? ?? 0,
      title: (json['title'] as String? ?? '').trim(),
      bulletPoints: toStringList(json['bullet_points']),
      notes: json['notes'] as String?,
      sourceRef: json['source_ref'] as String?,
      slideType: (json['slide_type'] as String? ?? 'content').trim(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REFERENCE ISSUE (for Reference Checker)
// ─────────────────────────────────────────────────────────────────────────────

enum ReferenceIssueType {
  missingReference,
  uncitedReference,
  duplicateReference,
  inconsistentAuthor,
  inconsistentYear,
  inconsistentFormatting,
  missingDoi,
  malformedReference,
  orderingIssue,
  numberingInconsistency,
}

class ReferenceIssue {
  final ReferenceIssueType type;
  final String description;
  final String? sourceText;
  final int? sourcePageRef;

  const ReferenceIssue({
    required this.type,
    required this.description,
    this.sourceText,
    this.sourcePageRef,
  });

  factory ReferenceIssue.fromJson(Map<String, dynamic> json) {
    return ReferenceIssue(
      type: _parseIssueType(json['type']),
      description: (json['description'] as String? ?? '').trim(),
      sourceText: json['source_text'] as String?,
      sourcePageRef: json['source_page_ref'] as int?,
    );
  }

  static ReferenceIssueType _parseIssueType(dynamic val) {
    switch ((val ?? '').toString().toLowerCase()) {
      case 'missing_reference':
        return ReferenceIssueType.missingReference;
      case 'uncited_reference':
        return ReferenceIssueType.uncitedReference;
      case 'duplicate_reference':
        return ReferenceIssueType.duplicateReference;
      case 'inconsistent_author':
        return ReferenceIssueType.inconsistentAuthor;
      case 'inconsistent_year':
        return ReferenceIssueType.inconsistentYear;
      case 'inconsistent_formatting':
        return ReferenceIssueType.inconsistentFormatting;
      case 'missing_doi':
        return ReferenceIssueType.missingDoi;
      case 'malformed_reference':
        return ReferenceIssueType.malformedReference;
      case 'ordering_issue':
        return ReferenceIssueType.orderingIssue;
      case 'numbering_inconsistency':
        return ReferenceIssueType.numberingInconsistency;
      default:
        return ReferenceIssueType.malformedReference;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER
// ─────────────────────────────────────────────────────────────────────────────

ExtractionConfidence _parseConfidence(dynamic val) {
  switch ((val ?? '').toString().toLowerCase()) {
    case 'detected':
      return ExtractionConfidence.detected;
    case 'inferred':
      return ExtractionConfidence.inferred;
    default:
      return ExtractionConfidence.unavailable;
  }
}

// ignore: prefer_const_constructors
// Used for generating IDs when not provided
class UniqueKey {
  @override
  String toString() =>
      'node_${DateTime.now().microsecondsSinceEpoch}';
}
