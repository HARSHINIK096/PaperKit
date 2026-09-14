import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/models/podcast_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/pdf_engine.dart';
import '../../core/services/storage_service.dart';

class VoicePodcastService {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();
  FlutterTts? _flutterTts;

  FlutterTts get tts {
    _flutterTts ??= FlutterTts();
    return _flutterTts!;
  }

  // Generate Conversational Podcast Script from Document
  Future<PodcastScript> generatePodcastScript(File file) async {
    try {
      // 1. Try backend API podcast generator
      final response = await _apiService.dio.post(
        '/ai/podcast-script',
        data: {'filePath': file.path},
      );
      if (response.statusCode == 200 && response.data != null) {
        return PodcastScript.fromJson(Map<String, dynamic>.from(response.data));
      }
    } catch (_) {
      // Fallback: Generate structured script directly from PDF text extraction
    }

    // Direct local text extraction & script formatting
    final text = await PdfEngine.extractTextFromPdf(file);
    final paragraphs = text
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().length > 20)
        .toList();

    final List<DialogueLine> dialogue = [];
    int timeSec = 0;

    for (int i = 0; i < paragraphs.length; i++) {
      final speaker = (i % 2 == 0) ? 'Alex (Host)' : 'Dr. Sam (Expert)';
      final minStr = (timeSec ~/ 60).toString().padLeft(2, '0');
      final secStr = (timeSec % 60).toString().padLeft(2, '0');
      final timestamp = '$minStr:$secStr';

      dialogue.add(
        DialogueLine(
          speaker: speaker,
          text: paragraphs[i].trim(),
          timestamp: timestamp,
        ),
      );
      timeSec += (25 + (paragraphs[i].length ~/ 15)).toInt();
      if (dialogue.length >= 12) break;
    }

    final totalWords = dialogue.fold<int>(0, (sum, line) => sum + line.text.split(RegExp(r'\s+')).length);

    return PodcastScript(
      title: 'Podcast: ${file.uri.pathSegments.last}',
      summary: 'Conversational breakdown of ${file.uri.pathSegments.last}',
      dialogue: dialogue,
      documentPath: file.path,
      totalWords: totalWords,
    );
  }

  // Text-To-Speech Engine API Controls
  Future<void> configureTts({
    double speechRate = 0.5,
    double pitch = 1.0,
    double volume = 1.0,
    String language = 'en-US',
  }) async {
    try {
      await tts.setLanguage(language);
      await tts.setSpeechRate(speechRate);
      await tts.setPitch(pitch);
      await tts.setVolume(volume);
    } catch (_) {}
  }

  Future<void> speakLine(DialogueLine line, {double pitch = 1.0, double rate = 0.5}) async {
    try {
      await tts.stop();
      await tts.setPitch(pitch);
      await tts.setSpeechRate(rate);
      await tts.speak(line.text);
    } catch (_) {}
  }

  Future<void> stopTts() async {
    try {
      await tts.stop();
    } catch (_) {}
  }

  Future<void> pauseTts() async {
    try {
      await tts.pause();
    } catch (_) {}
  }

  void disposeTts() {
    try {
      _flutterTts?.stop();
    } catch (_) {}
  }

  // Persistent Document-Anchored Voice Annotations Management
  Future<List<VoiceAnnotation>> loadVoiceAnnotationsForDocument(String documentPath) async {
    final rawList = await _storage.getVoiceAnnotations();
    return rawList
        .map((m) => VoiceAnnotation.fromJson(m))
        .where((a) => a.documentPath == documentPath)
        .toList();
  }

  Future<void> saveVoiceAnnotation(VoiceAnnotation annotation) async {
    final rawList = await _storage.getVoiceAnnotations();
    final annotations = rawList.map((m) => VoiceAnnotation.fromJson(m)).toList();
    annotations.removeWhere((a) => a.id == annotation.id);
    annotations.insert(0, annotation);
    await _storage.saveVoiceAnnotations(annotations.map((a) => a.toJson()).toList());
  }

  Future<void> deleteVoiceAnnotation(String annotationId) async {
    final rawList = await _storage.getVoiceAnnotations();
    final annotations = rawList.map((m) => VoiceAnnotation.fromJson(m)).toList();
    final target = annotations.where((a) => a.id == annotationId).firstOrNull;
    if (target != null) {
      final file = File(target.audioFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    annotations.removeWhere((a) => a.id == annotationId);
    await _storage.saveVoiceAnnotations(annotations.map((a) => a.toJson()).toList());
  }

  // Save Audio Annotation File
  Future<VoiceAnnotation> createVoiceAnnotation({
    required String documentPath,
    required int pageIndex,
    required String noteText,
    required List<int> audioBytes,
    required Duration duration,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${appDir.path}/voice_note_$timestamp.m4a';
    final audioFile = File(filePath);
    await audioFile.writeAsBytes(audioBytes);

    final annotation = VoiceAnnotation(
      id: 'voice_note_$timestamp',
      documentPath: documentPath,
      pageIndex: pageIndex,
      audioFilePath: filePath,
      duration: duration,
      createdAt: DateTime.now(),
      noteText: noteText,
    );

    await saveVoiceAnnotation(annotation);
    return annotation;
  }
}
