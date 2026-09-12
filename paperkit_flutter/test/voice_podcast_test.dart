import 'package:flutter_test/flutter_test.dart';
import 'package:maskerv_flutter/core/models/podcast_model.dart';
import 'package:maskerv_flutter/features/voice_podcast/voice_podcast_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Domain 6: Voice & Podcast Studio Tests', () {
    final service = VoicePodcastService();

    test('PodcastScript dialogue line alternating speakers and timestamps', () {
      final line1 = DialogueLine(speaker: 'Alex (Host)', text: 'Welcome!', timestamp: '00:00');
      final line2 = DialogueLine(speaker: 'Dr. Sam (Expert)', text: 'Thank you.', timestamp: '00:05');

      final script = PodcastScript(
        title: 'Test Podcast',
        summary: 'Podcast Summary',
        dialogue: [line1, line2],
        documentPath: '/tmp/test.pdf',
        totalWords: 3,
      );

      expect(script.dialogue.length, equals(2));
      expect(script.dialogue[0].speaker, equals('Alex (Host)'));
      expect(script.dialogue[1].speaker, equals('Dr. Sam (Expert)'));
      expect(script.totalWords, equals(3));
    });

    test('VoiceAnnotation serialization and JSON conversion', () {
      final annotation = VoiceAnnotation(
        id: 'note_123',
        documentPath: '/docs/research.pdf',
        pageIndex: 2,
        audioFilePath: '/storage/note_123.m4a',
        duration: const Duration(seconds: 45),
        noteText: 'Important research summary',
      );

      final json = annotation.toJson();
      final restored = VoiceAnnotation.fromJson(json);

      expect(restored.id, equals('note_123'));
      expect(restored.documentPath, equals('/docs/research.pdf'));
      expect(restored.pageIndex, equals(2));
      expect(restored.duration.inSeconds, equals(45));
      expect(restored.noteText, equals('Important research summary'));
    });

    test('TTS configuration parameters update safely', () async {
      await service.configureTts(speechRate: 0.8, pitch: 1.1, volume: 0.9);
      expect(service.tts, isNotNull);
    });
  });
}
