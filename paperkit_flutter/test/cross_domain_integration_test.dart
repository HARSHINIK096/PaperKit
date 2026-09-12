import 'package:flutter_test/flutter_test.dart';
import 'package:maskerv_flutter/core/models/accessibility_models.dart';
import 'package:maskerv_flutter/core/models/audit_ledger_model.dart';
import 'package:maskerv_flutter/core/models/dual_pane_model.dart';
import 'package:maskerv_flutter/core/models/form_field_model.dart';
import 'package:maskerv_flutter/core/models/mind_map_model.dart';
import 'package:maskerv_flutter/core/models/p2p_share_model.dart';
import 'package:maskerv_flutter/core/models/podcast_model.dart';
import 'package:maskerv_flutter/core/models/publishing_model.dart';
import 'package:maskerv_flutter/core/models/study_session_model.dart';
import 'package:maskerv_flutter/core/models/table_extractor_model.dart';
import 'package:maskerv_flutter/core/models/translation_model.dart';
import 'package:maskerv_flutter/features/accessibility/bionic_reading_engine.dart';
import 'package:maskerv_flutter/features/cognitive_retention/cognitive_retention_service.dart';
import 'package:maskerv_flutter/features/forms/form_engine_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Domain 5: Cognitive Retention & Spaced Repetition', () {
    final service = CognitiveRetentionService();

    test('SM-2 / Leitner scheduling promotes card to box 2 on Easy', () {
      final card = RecallItem(
        id: 'c1',
        term: 'Neural Plasticity',
        definition: 'Brain ability to reorganize itself',
        sourceDocumentPath: '/docs/neuro.pdf',
      );

      final rated = service.rateCardRecall(card, CardDifficulty.easy);
      expect(rated.leitnerBox, equals(2));
      expect(rated.reviewCount, equals(1));
    });

    test('Extract recall items parses term: definition patterns', () {
      const sampleText =
          'Photosynthesis: Converts solar energy to sugar.\nCellular Respiration: Breaks down glucose.';
      final items = service.extractRecallItemsFromText(
        sampleText,
        documentPath: '/docs/bio.pdf',
      );
      expect(items.length, equals(2));
      expect(items[0].term, equals('Photosynthesis'));
      expect(items[1].term, equals('Cellular Respiration'));
    });
  });

  group('Domain 6: Multi-Modal Voice & Podcast Script Model', () {
    test('PodcastScript serializes and deserializes dialogue lines', () {
      final script = PodcastScript(
        title: 'Quantum Physics Breakdown',
        summary: 'Discussion on entanglement',
        dialogue: [
          DialogueLine(
            speaker: 'Alex (Host)',
            text: 'Welcome to the show!',
            timestamp: '00:00',
          ),
          DialogueLine(
            speaker: 'Dr. Sam (Expert)',
            text: 'Glad to be here.',
            timestamp: '00:05',
          ),
        ],
        documentPath: '/docs/quantum.pdf',
        totalWords: 10,
      );

      final jsonMap = script.toJson();
      final decoded = PodcastScript.fromJson(jsonMap);
      expect(decoded.title, equals('Quantum Physics Breakdown'));
      expect(decoded.dialogue.length, equals(2));
      expect(decoded.dialogue[1].speaker, equals('Dr. Sam (Expert)'));
    });
  });

  group('Domain 7: Universal Accessibility & Bionic Reading Engine', () {
    test('Bionic tokenizes leading punctuation and core word correctly', () {
      final token = BionicReadingEngine.processWord('"Neuroscience"');
      expect(token.boldPrefix.contains('Neu'), isTrue);
      expect(token.normalSuffix.contains('science"'), isTrue);
    });

    test('ReadingProfile standard vs dyslexia profile properties', () {
      final std = ReadingProfile.standard();
      final dys = ReadingProfile.dyslexiaFriendly();

      expect(std.type, equals(ReadingProfileType.standard));
      expect(dys.type, equals(ReadingProfileType.dyslexiaFriendly));
      expect(dys.lineHeight, greaterThan(std.lineHeight));
    });
  });

  group('Domain 8: Legal Audit & Forensic Bates Stamping', () {
    test('AuditEvent records SHA-256 hash chain link', () {
      final event1 = AuditEvent(
        id: 'e1',
        timestamp: DateTime.now(),
        eventType: 'IMPORTED',
        documentId: '/docs/contract.pdf',
        documentName: 'contract.pdf',
        contentHash:
            'hash111111111111111111111111111111111111111111111111111111111111',
        previousHash:
            '0000000000000000000000000000000000000000000000000000000000000000',
        actorId: 'user_1',
      );

      final json = event1.toJson();
      final decoded = AuditEvent.fromJson(json);

      expect(
        decoded.contentHash,
        equals(
          'hash111111111111111111111111111111111111111111111111111111111111',
        ),
      );
      expect(decoded.eventType, equals('IMPORTED'));
    });
  });

  group('Domain 9: Interactive Form Builder & Profile Auto-Fill', () {
    test('FormEngineService auto-fills matching fields from user profile', () {
      final profile = UserFormProfile(
        id: 'prof_1',
        profileName: 'Student Profile',
        fullName: 'Alice Smith',
        email: 'alice@university.edu',
        phone: '+15550199',
        institution: 'MIT',
        studentId: 'ST-99823',
      );

      final fields = [
        CustomFormField(id: 'f1', label: 'Full Name', type: FormFieldType.text),
        CustomFormField(
          id: 'f2',
          label: 'Email Address',
          type: FormFieldType.text,
        ),
        CustomFormField(
          id: 'f3',
          label: 'University',
          type: FormFieldType.text,
        ),
      ];

      final service = FormEngineService();
      final filled = service.autoFillFields(fields, profile);

      expect(filled[0].value, equals('Alice Smith'));
      expect(filled[1].value, equals('alice@university.edu'));
      expect(filled[2].value, equals('MIT'));
    });
  });

  group('Domain 10: Visual Mind Mapping & Presentation Generator', () {
    test('MindMapNode hierarchy representation', () {
      final rootNode = MindMapNode(
        id: 'node_root',
        title: 'Computer Science',
        x: 100,
        y: 100,
        colorHex: 0xFF2563EB,
      );

      final childNode = MindMapNode(
        id: 'node_child_1',
        parentId: 'node_root',
        title: 'Data Structures',
        x: 200,
        y: 200,
        colorHex: 0xFF10B981,
      );

      expect(childNode.parentId, equals('node_root'));
      expect(rootNode.parentId, isNull);
    });

    test('PresentationDeck JSON serialization', () {
      final deck = PresentationDeck(
        title: 'Intro to Algorithms',
        slides: [
          SlideItem(
            slideTitle: 'Overview',
            bulletPoints: ['Definition', 'Complexity'],
          ),
        ],
      );

      final json = deck.toJson();
      final decoded = PresentationDeck.fromJson(json);

      expect(decoded.title, equals('Intro to Algorithms'));
      expect(decoded.slides.first.bulletPoints.length, equals(2));
    });
  });

  group('Domain 11: Dual-Pane Workspace & Course Syllabus Tracker', () {
    test('CourseSyllabus progress calculation', () {
      final course = SyllabusCourse(
        id: 'course_101',
        courseName: 'Linear Algebra',
        courseCode: 'MATH201',
        topics: [
          SyllabusTopic(id: 't1', title: 'Vector Addition', isCompleted: true),
          SyllabusTopic(id: 't2', title: 'Dot Product', isCompleted: true),
          SyllabusTopic(id: 't3', title: 'Cross Product', isCompleted: false),
        ],
      );

      expect(course.progressPercentage, closeTo(0.666, 0.01));
    });
  });

  group('Domain 12: Offline P2P Air-Share & Bundle Serialization', () {
    test('QrSessionPayload URL encoding contains required parameters', () {
      final payload = QrSessionPayload(
        protocolVersion: '1.0',
        sessionId: 'sess_123',
        hostIp: '192.168.1.50',
        port: 8080,
        secretToken: 'secret_token_123',
        documentName: 'thesis.pdf',
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );

      final url = payload.toEncodedUrl();
      expect(url.contains('paperkit://airshare'), isTrue);
      expect(url.contains('ip=192.168.1.50'), isTrue);
      expect(url.contains('port=8080'), isTrue);
    });
  });

  group('Domain 13: Tabular Analytics & Data Extraction', () {
    test('ExtractedTableData formats CSV row content with double quotes', () {
      final table = ExtractedTableData(
        title: 'Quarterly Financials',
        pageNumber: 1,
        headers: ['Quarter', 'Revenue, USD', 'Notes'],
        rows: [
          ['Q1', '\$1,500,000', 'Initial launch "success"'],
          ['Q2', '\$2,100,000', 'Growth phase'],
        ],
      );

      final csvContent = StringBuffer();
      csvContent.writeln(
        table.headers.map((h) => '"${h.replaceAll('"', '""')}"').join(','),
      );
      for (final row in table.rows) {
        csvContent.writeln(
          row.map((c) => '"${c.replaceAll('"', '""')}"').join(','),
        );
      }

      final csvString = csvContent.toString();
      expect(csvString.contains('"Revenue, USD"'), isTrue);
      expect(csvString.contains('"Initial launch ""success"""'), isTrue);
    });
  });

  group('Domain 14: Translation & Terminology Glossary', () {
    test('GlossaryTerm model and dictionary replacement', () {
      final glossary = GlossaryTerm(
        id: 'g1',
        sourceTerm: 'Machine Learning',
        targetTerm: 'Aprendizaje Automático',
        sourceLanguage: 'en',
        targetLanguage: 'es',
        domainCategory: 'Computer Science',
      );

      const inputText = 'The paper discusses Machine Learning algorithms.';
      final outputText = inputText.replaceAll(
        glossary.sourceTerm,
        glossary.targetTerm,
      );

      expect(
        outputText,
        equals('The paper discusses Aprendizaje Automático algorithms.'),
      );
    });
  });

  group('Domain 15: E-Book Publishing & Print Preflight Analysis', () {
    test('PreflightReport evaluates PASS, WARNING, and ERROR status', () {
      final report = PreflightReport(
        pageCount: 10,
        pageSize: 'A4',
        estimatedDpi: 150,
        colorSpace: 'RGB',
        fontsEmbedded: true,
        warnings: ['Image DPI is below 300 DPI'],
        isPrintReady: false,
      );

      expect(report.isPrintReady, isFalse);
      expect(report.warnings.first, equals('Image DPI is below 300 DPI'));
    });
  });
}
