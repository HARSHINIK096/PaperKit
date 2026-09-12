import 'package:flutter_test/flutter_test.dart';
import 'package:maskerv_flutter/core/models/audit_ledger_model.dart';
import 'package:maskerv_flutter/core/models/form_field_model.dart';
import 'package:maskerv_flutter/core/models/p2p_share_model.dart';
import 'package:maskerv_flutter/core/models/study_session_model.dart';
import 'package:maskerv_flutter/features/accessibility/bionic_reading_engine.dart';
import 'package:maskerv_flutter/features/cognitive_retention/cognitive_retention_service.dart';
import 'package:maskerv_flutter/features/forms/form_engine_service.dart';

void main() {
  group('Domain 5: Cognitive Retention Services', () {
    final service = CognitiveRetentionService();

    test('Spaced Repetition SM-2 rating calculation increases Leitner box on Easy', () {
      final card = RecallItem(
        id: '1',
        term: 'Memory',
        definition: 'Retention of info',
        sourceDocumentPath: 'test.pdf',
      );

      final rated = service.rateCardRecall(card, CardDifficulty.easy);
      expect(rated.leitnerBox, equals(2));
      expect(rated.reviewCount, equals(1));
    });

    test('Extract recall items from definition formatted text', () {
      const text = 'Cognitive Decay: The rate at which memory fades over time.\nActive Recall: Testing memory directly.';
      final items = service.extractRecallItemsFromText(text, documentPath: 'test.pdf');
      expect(items.length, equals(2));
      expect(items.first.term, equals('Cognitive Decay'));
    });
  });

  group('Domain 7: Accessibility & Bionic Reading Engine', () {
    test('Process word bionic bold prefix splitting', () {
      final token = BionicReadingEngine.processWord('Reading');
      expect(token.boldPrefix, equals('Rea'));
      expect(token.normalSuffix, equals('ding'));
    });
  });

  group('Domain 8: Legal Audit Models & Bates Stamping Config', () {
    test('BatesConfig formats number correctly with padding', () {
      const config = BatesConfig(prefix: 'EXHIBIT-', startNumber: 1, digitPadding: 6);
      expect(config.formatNumber(0), equals('EXHIBIT-000001'));
      expect(config.formatNumber(99), equals('EXHIBIT-000100'));
    });
  });

  group('Domain 9: Form Filler Profile Auto-Fill', () {
    test('Auto-fill populates matching fields from profile', () {
      final profile = UserFormProfile(
        id: 'p1',
        profileName: 'Default',
        fullName: 'Jane Doe',
        email: 'jane@example.com',
      );

      final fields = [
        CustomFormField(id: '1', label: 'Full Name', type: FormFieldType.text),
        CustomFormField(id: '2', label: 'Email Address', type: FormFieldType.text),
      ];

      final service = FormEngineService();
      final filled = service.autoFillFields(fields, profile);
      expect(filled[0].value, equals('Jane Doe'));
      expect(filled[1].value, equals('jane@example.com'));
    });
  });

  group('Domain 12: P2P Project Bundle Serialization', () {
    test('PaperKit Project Bundle manifest serialization', () {
      final manifest = PaperKitProjectBundleManifest(
        projectName: 'Test Project',
        createdBy: 'Test User',
        pdfFiles: ['doc1.pdf'],
        noteFiles: ['note1.txt'],
        flashcardsFiles: [],
        mindMapFiles: [],
        checksumSha256: 'abc123hash',
      );

      final json = manifest.toJson();
      final decoded = PaperKitProjectBundleManifest.fromJson(json);

      expect(decoded.projectName, equals('Test Project'));
      expect(decoded.pdfFiles.length, equals(1));
    });
  });
}
