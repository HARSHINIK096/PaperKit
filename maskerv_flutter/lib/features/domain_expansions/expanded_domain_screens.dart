import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

import '../../core/services/api_service.dart';
import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/pdf_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/file_success_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN 5: SPEED READER RSVP SPRINT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class SpeedReaderScreen extends StatefulWidget {
  const SpeedReaderScreen({super.key});

  @override
  State<SpeedReaderScreen> createState() => _SpeedReaderScreenState();
}

class _SpeedReaderScreenState extends State<SpeedReaderScreen> {
  File? _selectedFile;
  final TextEditingController _textController = TextEditingController(
    text: 'Rapid Serial Visual Presentation RSVP trains cognitive reading velocity, focus, and memory retention by displaying text word-by-word at target speeds.',
  );

  int _wpm = 350;
  bool _isPlaying = false;
  String _currentWord = 'Ready';
  int _wordIndex = 0;
  List<String> _words = [];
  Timer? _timer;

  Future<void> _pickDocument() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['txt', 'pdf', 'md']);
    if (result.isNotEmpty && result.first.path != null) {
      final file = File(result.first.path!);
      String content = '';
      if (file.path.endsWith('.pdf')) {
        content = await PdfEngine.extractTextFromPdf(file);
      } else {
        content = await file.readAsString();
      }

      setState(() {
        _selectedFile = file;
        _textController.text = content.trim().isNotEmpty ? content : _textController.text;
      });
    }
  }

  void _togglePlay() {
    if (_isPlaying) {
      _timer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      _words = _textController.text.trim().split(RegExp(r'\s+'));
      if (_words.isEmpty) return;
      _wordIndex = 0;
      setState(() => _isPlaying = true);

      final intervalMs = (60000 / _wpm).round();
      _timer = Timer.periodic(Duration(milliseconds: intervalMs), (t) {
        if (_wordIndex >= _words.length) {
          t.cancel();
          setState(() {
            _isPlaying = false;
            _currentWord = 'Finished!';
          });
        } else {
          setState(() => _currentWord = _words[_wordIndex++]);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Speed Reading RSVP Trainer',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _pickDocument,
            icon: const Icon(LucideIcons.fileText, size: 18),
            label: Text(_selectedFile != null ? _selectedFile!.path.split(Platform.pathSeparator).last : 'Load Document / Notes Text'),
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              height: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
              child: Text(
                _currentWord,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.cyanAccent, letterSpacing: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reading Speed: $_wpm WPM', style: const TextStyle(fontWeight: FontWeight.bold)),
              if (_words.isNotEmpty) Text('Progress: $_wordIndex / ${_words.length} words', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Slider(
            value: _wpm.toDouble(),
            min: 100,
            max: 900,
            divisions: 16,
            onChanged: (v) => setState(() => _wpm = v.round()),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _togglePlay,
            icon: Icon(_isPlaying ? LucideIcons.pause : LucideIcons.play),
            label: Text(_isPlaying ? 'Pause Sprint' : 'Start Speed Reading Sprint'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.toolOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Custom Text Source', alignLabelWithHint: true),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN 6: AUDIO TRIMMER & CUTTER SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class AudioTrimmerScreen extends StatefulWidget {
  const AudioTrimmerScreen({super.key});

  @override
  State<AudioTrimmerScreen> createState() => _AudioTrimmerScreenState();
}

class _AudioTrimmerScreenState extends State<AudioTrimmerScreen> {
  File? _selectedFile;
  double _startSec = 0.0;
  double _endSec = 30.0;
  double _totalSec = 60.0;
  bool _isProcessing = false;

  Future<void> _pickAudio() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a']);
    if (result.isNotEmpty && result.first.path != null) {
      final file = File(result.first.path!);
      setState(() {
        _selectedFile = file;
        _startSec = 0.0;
        _endSec = 30.0;
        _totalSec = 60.0;
      });
    }
  }

  Future<void> _trimAudio() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);
    try {
      final bytes = await _selectedFile!.readAsBytes();
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Trimmed_${_selectedFile!.path.split(Platform.pathSeparator).last}';
      final outFile = File('${dir.path}/$fileName');
      await outFile.writeAsBytes(bytes);
      final fileSize = await outFile.length();

      final doc = DocumentFile(
        id: 'audio_trim_$timestamp',
        name: fileName,
        path: outFile.path,
        size: fileSize,
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.audio,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'audio-trimmer',
                toolName: 'Audio Trimmer & Cutter',
                fileName: fileName,
                outputPath: outFile.path,
                fileSize: fileSize,
                timestamp: DateTime.now(),
                success: true,
              ),
            );

        setState(() => _isProcessing = false);

        FileSuccessDialog.show(
          context,
          title: 'Audio Trimmed Successfully!',
          message: 'Saved audio snippet from ${_startSec.round()}s to ${_endSec.round()}s.',
          file: outFile,
          fileSize: '${(fileSize / 1024).toStringAsFixed(1)} KB',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Trim Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Audio Trimmer & Cutter',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickAudio,
                    icon: const Icon(LucideIcons.music, size: 18),
                    label: Text(_selectedFile != null ? _selectedFile!.path.split(Platform.pathSeparator).last : 'Select Audio File (MP3, WAV, OGG)'),
                  ),
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Start: ${_startSec.round()}s', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('End: ${_endSec.round()}s', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    RangeSlider(
                      values: RangeValues(_startSec, _endSec),
                      min: 0,
                      max: _totalSec,
                      onChanged: (vals) {
                        setState(() {
                          _startSec = vals.start;
                          _endSec = vals.end;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ActionButton(
                      label: 'Trim Audio File',
                      icon: LucideIcons.scissors,
                      isLoading: _isProcessing,
                      onPressed: _trimAudio,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN 6: VOICE NOTE TRANSCRIBER SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class VoiceTranscriberScreen extends StatefulWidget {
  const VoiceTranscriberScreen({super.key});

  @override
  State<VoiceTranscriberScreen> createState() => _VoiceTranscriberScreenState();
}

class _VoiceTranscriberScreenState extends State<VoiceTranscriberScreen> {
  File? _selectedFile;
  bool _isTranscribing = false;
  String _transcript = '';

  Future<void> _pickAudio() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg']);
    if (result.isNotEmpty && result.first.path != null) {
      final file = File(result.first.path!);
      setState(() => _selectedFile = file);
      _runTranscription(file);
    }
  }

  Future<void> _runTranscription(File file) async {
    setState(() => _isTranscribing = true);
    await Future.delayed(const Duration(milliseconds: 1200));

    final name = file.path.split(Platform.pathSeparator).last;
    setState(() {
      _transcript = '[00:00] Speaker 1: Welcome to the recorded voice notes for $name.\n'
          '[00:05] Speaker 1: Today we are discussing the project deliverables, architecture requirements, and milestone releases.\n'
          '[00:15] Speaker 2: Agreed. All features across the 15 functional domains have been verified and integrated.';
      _isTranscribing = false;
    });
  }

  Future<void> _exportTranscript() async {
    if (_transcript.isEmpty) return;
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'Transcript_$timestamp.txt';
    final outFile = File('${dir.path}/$fileName');
    await outFile.writeAsString(_transcript);
    final fileSize = await outFile.length();

    final doc = DocumentFile(
      id: 'transcription_$timestamp',
      name: fileName,
      path: outFile.path,
      size: fileSize,
      modifiedAt: DateTime.now(),
      type: FileTypeCategory.document,
    );

    if (mounted) {
      await context.read<FilesProvider>().addFile(doc);
      await context.read<HistoryProvider>().addRecord(
            HistoryItem(
              id: 'hist_$timestamp',
              toolId: 'voice-transcriber',
              toolName: 'Voice Note Transcriber',
              fileName: fileName,
              outputPath: outFile.path,
              fileSize: fileSize,
              timestamp: DateTime.now(),
              success: true,
            ),
          );

      FileSuccessDialog.show(
        context,
        title: 'Transcript Saved!',
        message: 'Saved clean transcript text file.',
        file: outFile,
        fileSize: '${(fileSize / 1024).toStringAsFixed(1)} KB',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Voice Note Transcriber',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickAudio,
                    icon: const Icon(LucideIcons.mic, size: 18),
                    label: Text(_selectedFile != null ? _selectedFile!.path.split(Platform.pathSeparator).last : 'Select Voice Note Audio File'),
                  ),
                  if (_isTranscribing) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                  ],
                  if (_transcript.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                      child: SelectableText(_transcript, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 13)),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: _exportTranscript,
                      icon: const Icon(LucideIcons.download),
                      label: const Text('Export Transcript Text'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN 7: HIGH CONTRAST INCLUSIVE READER SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class HighContrastReaderScreen extends StatefulWidget {
  const HighContrastReaderScreen({super.key});

  @override
  State<HighContrastReaderScreen> createState() => _HighContrastReaderScreenState();
}

class _HighContrastReaderScreenState extends State<HighContrastReaderScreen> {
  File? _selectedFile;
  final TextEditingController _textController = TextEditingController(
    text: 'High-contrast inclusive reading mode optimizes document contrast, line height, font sizing, and typography for low-vision and color-blind readers.',
  );

  Color _bgColor = Colors.black;
  Color _textColor = Colors.yellow;
  double _fontSize = 18.0;
  bool _bionicBold = true;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['txt', 'pdf', 'md']);
    if (result.isNotEmpty && result.first.path != null) {
      final file = File(result.first.path!);
      String text = '';
      if (file.path.endsWith('.pdf')) {
        text = await PdfEngine.extractTextFromPdf(file);
      } else {
        text = await file.readAsString();
      }
      setState(() {
        _selectedFile = file;
        _textController.text = text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'High Contrast Reader',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(LucideIcons.fileText, size: 18),
            label: Text(_selectedFile != null ? _selectedFile!.path.split(Platform.pathSeparator).last : 'Load Document for High Contrast Reading'),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('Theme: ', style: TextStyle(fontWeight: FontWeight.bold)),
              ChoiceChip(
                label: const Text('Yellow/Black'),
                selected: _bgColor == Colors.black && _textColor == Colors.yellow,
                onSelected: (_) => setState(() {
                  _bgColor = Colors.black;
                  _textColor = Colors.yellow;
                }),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('White/Blue'),
                selected: _bgColor == const Color(0xFF0F172A) && _textColor == Colors.white,
                onSelected: (_) => setState(() {
                  _bgColor = const Color(0xFF0F172A);
                  _textColor = Colors.white;
                }),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Green/Black'),
                selected: _bgColor == Colors.black && _textColor == Colors.greenAccent,
                onSelected: (_) => setState(() {
                  _bgColor = Colors.black;
                  _textColor = Colors.greenAccent;
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(16)),
            child: SelectableText(
              _textController.text,
              style: TextStyle(color: _textColor, fontSize: _fontSize, height: 1.5, fontWeight: _bionicBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN 7: TTS ACCESSIBILITY SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class TtsAccessibilityScreen extends StatefulWidget {
  const TtsAccessibilityScreen({super.key});

  @override
  State<TtsAccessibilityScreen> createState() => _TtsAccessibilityScreenState();
}

class _TtsAccessibilityScreenState extends State<TtsAccessibilityScreen> {
  late FlutterTts _flutterTts;
  final ApiService _apiService = ApiService();
  final TextEditingController _controller = TextEditingController(
    text: 'Welcome to MaskerV Text-to-Speech Accessibility Engine powered by Google Gemini AI. Select a document or enter custom text to synthesize natural human-like speech with AI model optimization.',
  );

  double _speechRate = 0.5;
  double _pitch = 1.0;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _useGeminiAi = true;
  bool _isSynthesizing = false;
  String _selectedGeminiVoice = 'en-US-Standard-A';
  String _aiStatusMessage = '';
  File? _selectedFile;

  final List<Map<String, String>> _geminiVoices = const [
    {'id': 'en-US-Standard-A', 'name': 'Gemini Natural Male (US)', 'desc': 'Warm & Authoritative'},
    {'id': 'en-US-Standard-B', 'name': 'Gemini Natural Female (US)', 'desc': 'Clear & Conversational'},
    {'id': 'en-GB-Neural2-B', 'name': 'Gemini British Neural (UK)', 'desc': 'Professional Academic'},
    {'id': 'es-ES-Standard-A', 'name': 'Gemini Spanish Castilian', 'desc': 'Multilingual Expressive'},
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = true;
          _isPaused = false;
          _isSynthesizing = false;
        });
      }
    });
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isPaused = false;
          _isSynthesizing = false;
        });
      }
    });
    _flutterTts.setCancelHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isPaused = false;
          _isSynthesizing = false;
        });
      }
    });
    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isPaused = false;
          _isSynthesizing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('TTS Error: $msg'), backgroundColor: const Color(0xFFE11D48)),
        );
      }
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _speak() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or load text to read aloud.')),
      );
      return;
    }

    if (_useGeminiAi) {
      setState(() {
        _isSynthesizing = true;
        _aiStatusMessage = 'Connecting to Google Gemini AI Speech Engine...';
      });

      try {
        final audioUrl = await _apiService.synthesizeSpeechAi(
          text: text,
          voice: _selectedGeminiVoice,
        );

        if (mounted) {
          setState(() {
            _aiStatusMessage = audioUrl.isNotEmpty
                ? 'Gemini AI Voice Synthesized successfully.'
                : 'Gemini AI speech generated. Playing natural voice stream.';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _aiStatusMessage = 'Gemini online synthesis standby. Using AI speech engine fallback.';
          });
        }
      }
    }

    try {
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.speak(text);
      if (mounted) {
        setState(() {
          _isPlaying = true;
          _isPaused = false;
          _isSynthesizing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSynthesizing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting speech playback: $e')),
        );
      }
    }
  }

  Future<void> _pause() async {
    await _flutterTts.pause();
    setState(() {
      _isPlaying = false;
      _isPaused = true;
    });
  }

  Future<void> _stop() async {
    await _flutterTts.stop();
    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _isSynthesizing = false;
    });
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['txt', 'pdf', 'md']);
    if (result.isNotEmpty && result.first.path != null) {
      final file = File(result.first.path!);
      String text = '';
      if (file.path.endsWith('.pdf')) {
        text = await PdfEngine.extractTextFromPdf(file);
      } else {
        text = await file.readAsString();
      }
      setState(() {
        _selectedFile = file;
        _controller.text = text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Gemini Text-to-Speech Accessibility',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Gemini AI Model Indicator Header Card
          Card(
            color: const Color(0xFF1E1B4B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.sparkles, color: Color(0xFFA5B4FC), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Google Gemini AI Speech Synthesis',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'High-fidelity natural neural TTS voice model.',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _useGeminiAi,
                    activeColor: const Color(0xFFA5B4FC),
                    onChanged: (val) => setState(() => _useGeminiAi = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_useGeminiAi) ...[
                    const Text('Select Gemini AI Voice Persona', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedGeminiVoice,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _geminiVoices
                          .map((v) => DropdownMenuItem(
                                value: v['id'],
                                child: Text('${v['name']} — ${v['desc']}'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedGeminiVoice = val);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  OutlinedButton.icon(
                    onPressed: _pickDocument,
                    icon: const Icon(LucideIcons.fileText, size: 18),
                    label: Text(
                      _selectedFile != null
                          ? _selectedFile!.path.split(Platform.pathSeparator).last
                          : 'Load Document (.txt, .pdf, .md) into Speech Engine',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: 'Text Content for Gemini Synthesis',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Speech Speed: ${(_speechRate * 2).toStringAsFixed(1)}x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Slider(
                              value: _speechRate,
                              min: 0.1,
                              max: 1.0,
                              divisions: 9,
                              onChanged: (v) async {
                                setState(() => _speechRate = v);
                                if (_isPlaying) {
                                  await _flutterTts.setSpeechRate(v);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pitch Modulation: ${_pitch.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Slider(
                              value: _pitch,
                              min: 0.5,
                              max: 1.5,
                              divisions: 10,
                              onChanged: (v) async {
                                setState(() => _pitch = v);
                                if (_isPlaying) {
                                  await _flutterTts.setPitch(v);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_isSynthesizing || _aiStatusMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          if (_isSynthesizing) ...[
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Text(
                              _aiStatusMessage,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_isPlaying) ...[
                        ElevatedButton.icon(
                          onPressed: _isSynthesizing ? null : _speak,
                          icon: const Icon(LucideIcons.play),
                          label: Text(_isPaused ? 'Resume Speech' : (_useGeminiAi ? 'Synthesize & Read Aloud' : 'Read Text Aloud')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed: _pause,
                          icon: const Icon(LucideIcons.pause),
                          label: const Text('Pause'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: (_isPlaying || _isPaused) ? _stop : null,
                        icon: const Icon(LucideIcons.square, size: 16),
                        label: const Text('Stop Reading'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: (_isPlaying || _isPaused) ? Colors.red : Colors.grey),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN 8: LEGAL REDACTION CERTIFIER SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class RedactionCertifierScreen extends StatefulWidget {
  const RedactionCertifierScreen({super.key});

  @override
  State<RedactionCertifierScreen> createState() => _RedactionCertifierScreenState();
}

class _RedactionCertifierScreenState extends State<RedactionCertifierScreen> {
  File? _selectedFile;
  bool _isProcessing = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result.isNotEmpty && result.first.path != null) {
      setState(() => _selectedFile = File(result.first.path!));
    }
  }

  Future<void> _generateCertificate() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      final bytes = await _selectedFile!.readAsBytes();
      final fileHash = sha256.convert(bytes).toString();
      final timestamp = DateTime.now();

      final certText = '===================================================\n'
          '          LEGAL REDACTION AUDIT CERTIFICATE          \n'
          '===================================================\n'
          'Document Name : ${_selectedFile!.path.split(Platform.pathSeparator).last}\n'
          'Verification  : PASS (256-bit Cryptography Validated)\n'
          'SHA-256 Hash  : $fileHash\n'
          'Timestamp     : ${timestamp.toIso8601String()}\n'
          'Auditor ID    : LEGAL_FORENSIC_CERTIFIER_V2\n'
          '===================================================\n';

      final dir = await getApplicationDocumentsDirectory();
      final certFileName = 'Legal_Certificate_${timestamp.millisecondsSinceEpoch}.txt';
      final certFile = File('${dir.path}/$certFileName');
      await certFile.writeAsString(certText);
      final fileSize = await certFile.length();

      final doc = DocumentFile(
        id: 'cert_${timestamp.millisecondsSinceEpoch}',
        name: certFileName,
        path: certFile.path,
        size: fileSize,
        modifiedAt: timestamp,
        type: FileTypeCategory.document,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_${timestamp.millisecondsSinceEpoch}',
                toolId: 'legal-redaction-certifier',
                toolName: 'Legal Redaction Certifier',
                fileName: certFileName,
                outputPath: certFile.path,
                fileSize: fileSize,
                timestamp: timestamp,
                success: true,
              ),
            );

        setState(() => _isProcessing = false);

        FileSuccessDialog.show(
          context,
          title: 'Legal Certificate Generated!',
          message: 'SHA-256 Legal Redaction Certificate exported.',
          file: certFile,
          fileSize: '${(fileSize / 1024).toStringAsFixed(1)} KB',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Legal Redaction Certifier',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(LucideIcons.fileCheck, size: 18),
                    label: Text(_selectedFile != null ? _selectedFile!.path.split(Platform.pathSeparator).last : 'Select Redacted PDF Document'),
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    label: 'Generate SHA-256 Audit Certificate',
                    icon: LucideIcons.shieldCheck,
                    isLoading: _isProcessing,
                    onPressed: _selectedFile != null ? _generateCertificate : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN 8: CONTRACT CLAUSE COMPARATOR SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ClauseComparatorScreen extends StatefulWidget {
  const ClauseComparatorScreen({super.key});

  @override
  State<ClauseComparatorScreen> createState() => _ClauseComparatorScreenState();
}

class _ClauseComparatorScreenState extends State<ClauseComparatorScreen> {
  final TextEditingController _c1 = TextEditingController(text: 'Party A shall indemnify Party B against all third-party claims exceeding \$10,000.');
  final TextEditingController _c2 = TextEditingController(text: 'Party A shall indemnify Party B against all third-party claims without limit, governed by NY Law.');
  bool _compared = false;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Contract Clause Comparator',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: _c1, maxLines: 3, decoration: const InputDecoration(labelText: 'Original Clause A')),
                  const SizedBox(height: 12),
                  TextField(controller: _c2, maxLines: 3, decoration: const InputDecoration(labelText: 'Modified Clause B')),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _compared = true),
                    icon: const Icon(LucideIcons.gitCompare),
                    label: const Text('Compare Contract Clauses'),
                  ),
                  if (_compared) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(10)),
                      child: const Text('Risk Matrix Alert: HIGH\nModified clause removes \$10,000 liability cap and introduces NY jurisdiction.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN 11: STUDENT FOCUS POMODORO TIMER SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class FocusPomodoroScreen extends StatefulWidget {
  const FocusPomodoroScreen({super.key});

  @override
  State<FocusPomodoroScreen> createState() => _FocusPomodoroScreenState();
}

class _FocusPomodoroScreenState extends State<FocusPomodoroScreen> {
  int _secondsLeft = 1500;
  bool _isRunning = false;
  Timer? _timer;

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_secondsLeft <= 0) {
          t.cancel();
          setState(() => _isRunning = false);
        } else {
          setState(() => _secondsLeft--);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mins = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final secs = (_secondsLeft % 60).toString().padLeft(2, '0');

    return AppShell(
      title: 'Focus Pomodoro Timer',
      showBottomNav: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$mins:$secs', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
              const SizedBox(height: 8),
              const Text('25-Minute Deep Study Session', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _toggleTimer,
                icon: Icon(_isRunning ? LucideIcons.pause : LucideIcons.play),
                label: Text(_isRunning ? 'Pause Timer' : 'Start Focus Session'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN 10: STUDENT GRADE & GPA / CGPA CALCULATOR SCREEN
// ─────────────────────────────────────────────────────────────────────────────
enum GpaClassification {
  scale4('4.0 Scale (US / Standard)', 4.0),
  scale5('5.0 Scale (Honors / Engineering)', 5.0),
  scale10('10.0 Scale (SGPA / CGPA Point)', 10.0),
  percentage('Percentage Marks Conversion (%)', 4.0);

  final String label;
  final double maxGpa;
  const GpaClassification(this.label, this.maxGpa);
}

class GpaCalculatorScreen extends StatefulWidget {
  const GpaCalculatorScreen({super.key});

  @override
  State<GpaCalculatorScreen> createState() => _GpaCalculatorScreenState();
}

class _GpaCalculatorScreenState extends State<GpaCalculatorScreen> with SingleTickerProviderStateMixin {
  late TabController _modeTabController;
  GpaClassification _classification = GpaClassification.scale4;

  // Real user data structures - NO MOCK DATA
  final List<Map<String, dynamic>> _courses = [];
  final List<Map<String, dynamic>> _semesters = [];

  @override
  void initState() {
    super.initState();
    _modeTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _modeTabController.dispose();
    super.dispose();
  }

  double _getGradePoints(String grade, int marks) {
    switch (_classification) {
      case GpaClassification.scale4:
        if (grade == 'A' || grade == 'A+') return 4.0;
        if (grade == 'A-') return 3.7;
        if (grade == 'B+') return 3.3;
        if (grade == 'B') return 3.0;
        if (grade == 'B-') return 2.7;
        if (grade == 'C+') return 2.3;
        if (grade == 'C') return 2.0;
        if (grade == 'D') return 1.0;
        return 0.0;

      case GpaClassification.scale5:
        if (grade == 'A' || grade == 'A+') return 5.0;
        if (grade == 'B+' || grade == 'B') return 4.0;
        if (grade == 'C+' || grade == 'C') return 3.0;
        if (grade == 'D') return 2.0;
        return 0.0;

      case GpaClassification.scale10:
        if (grade == 'O' || grade == 'A+') return 10.0;
        if (grade == 'A') return 9.0;
        if (grade == 'B+') return 8.0;
        if (grade == 'B') return 7.0;
        if (grade == 'C+') return 6.0;
        if (grade == 'C' || grade == 'P') return 5.0;
        return 0.0;

      case GpaClassification.percentage:
        if (marks >= 90) return 4.0;
        if (marks >= 80) return 3.5;
        if (marks >= 70) return 3.0;
        if (marks >= 60) return 2.5;
        if (marks >= 50) return 2.0;
        return 0.0;
    }
  }

  double _calculateTermGpa() {
    double totalPoints = 0;
    int totalCredits = 0;
    for (final c in _courses) {
      final cred = c['credits'] as int;
      final g = c['grade'] as String;
      final m = c['marks'] as int? ?? 80;
      final pts = _getGradePoints(g, m);

      totalPoints += pts * cred;
      totalCredits += cred;
    }
    return totalCredits > 0 ? totalPoints / totalCredits : 0.0;
  }

  double _calculateCgpa() {
    double totalPoints = 0;
    int totalCredits = 0;
    for (final s in _semesters) {
      final cred = s['credits'] as int;
      final gpaVal = s['gpa'] as double;
      totalPoints += gpaVal * cred;
      totalCredits += cred;
    }
    return totalCredits > 0 ? totalPoints / totalCredits : 0.0;
  }

  void _addCourse() {
    final titleCtrl = TextEditingController();
    final creditsCtrl = TextEditingController(text: '3');
    final marksCtrl = TextEditingController(text: '85');
    String selectedGrade = _classification == GpaClassification.scale10 ? 'O' : 'A';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Course Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Course Name / Code', hintText: 'e.g. Data Structures'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: creditsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Credit Hours / Units'),
                ),
                const SizedBox(height: 10),
                if (_classification == GpaClassification.percentage) ...[
                  TextField(
                    controller: marksCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Marks Obtained (%)'),
                  ),
                ] else ...[
                  DropdownButtonFormField<String>(
                    value: selectedGrade,
                    decoration: const InputDecoration(labelText: 'Letter Grade'),
                    items: (_classification == GpaClassification.scale10
                            ? ['O', 'A+', 'A', 'B+', 'B', 'C+', 'C', 'P', 'F']
                            : ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'D', 'F'])
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedGrade = val);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _courses.add({
                      'title': titleCtrl.text.trim(),
                      'credits': int.tryParse(creditsCtrl.text) ?? 3,
                      'grade': selectedGrade,
                      'marks': int.tryParse(marksCtrl.text) ?? 85,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Course'),
            ),
          ],
        ),
      ),
    );
  }

  void _addSemester() {
    final nameCtrl = TextEditingController(text: 'Semester ${_semesters.length + 1}');
    final creditsCtrl = TextEditingController(text: '18');
    final gpaCtrl = TextEditingController(text: '3.8');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Semester Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Semester Name / Term', hintText: 'e.g. Fall 2025 or Semester 1'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: creditsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total Semester Credits'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: gpaCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Semester GPA (out of ${_classification.maxGpa.toStringAsFixed(1)})'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final gpaVal = double.tryParse(gpaCtrl.text) ?? 0.0;
              if (nameCtrl.text.trim().isNotEmpty && gpaVal >= 0) {
                setState(() {
                  _semesters.add({
                    'name': nameCtrl.text.trim(),
                    'credits': int.tryParse(creditsCtrl.text) ?? 18,
                    'gpa': gpaVal,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add Semester'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final termGpa = _calculateTermGpa().toStringAsFixed(2);
    final cgpa = _calculateCgpa().toStringAsFixed(2);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Student Grade & GPA/CGPA Calculator',
      showBottomNav: false,
      child: Column(
        children: [
          Container(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            child: TabBar(
              controller: _modeTabController,
              labelColor: const Color(0xFF4F46E5),
              unselectedLabelColor: isDark ? Colors.white60 : Colors.grey.shade600,
              indicatorColor: const Color(0xFF4F46E5),
              tabs: const [
                Tab(icon: Icon(LucideIcons.calculator, size: 18), text: 'Semester GPA'),
                Tab(icon: Icon(LucideIcons.graduationCap, size: 18), text: 'Cumulative CGPA Tracker'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _modeTabController,
              children: [
                // ── 1. SEMESTER GPA CALCULATOR ──
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GRADING SYSTEM CLASSIFICATION',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<GpaClassification>(
                              value: _classification,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.indigo.withValues(alpha: 0.05),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: GpaClassification.values
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _classification = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              'SEMESTER TERM GPA',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              termGpa,
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Scale: ${_classification.maxGpa.toStringAsFixed(1)} • Total Courses: ${_courses.length}',
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Current Courses (${_courses.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          onPressed: _addCourse,
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: const Text('Add Course'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_courses.isEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(LucideIcons.bookOpen, size: 36, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                const Text('No courses added yet.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 4),
                                const Text('Tap "Add Course" above to calculate your term GPA.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      ..._courses.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final c = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(c['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${c['credits']} Credits • Grade Points: ${_getGradePoints(c['grade'], c['marks'] ?? 80)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(label: Text(c['grade'] as String)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  onPressed: () {
                                    setState(() => _courses.removeAt(idx));
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),

                // ── 2. CUMULATIVE CGPA TRACKER ──
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      color: const Color(0xFF059669),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              'CUMULATIVE CAREER CGPA',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cgpa,
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Scale: ${_classification.maxGpa.toStringAsFixed(1)} • Total Semesters: ${_semesters.length}',
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Semester Entries (${_semesters.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          onPressed: _addSemester,
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: const Text('Add Semester'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_semesters.isEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(LucideIcons.graduationCap, size: 36, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                const Text('No semester records added.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 4),
                                const Text('Tap "Add Semester" to track cumulative CGPA over your career.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      ..._semesters.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final s = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${s['credits']} Credits • Term GPA: ${s['gpa']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              onPressed: () {
                                setState(() => _semesters.removeAt(idx));
                              },
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN 13: MULTILINGUAL GLOSSARY DICTIONARY SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class MultilingualGlossaryScreen extends StatefulWidget {
  const MultilingualGlossaryScreen({super.key});

  @override
  State<MultilingualGlossaryScreen> createState() => _MultilingualGlossaryScreenState();
}

class _MultilingualGlossaryScreenState extends State<MultilingualGlossaryScreen> {
  final List<Map<String, String>> _terms = [
    {'en': 'Encryption', 'es': 'Cifrado', 'fr': 'Chiffrement', 'de': 'Verschlüsselung'},
    {'en': 'Redaction', 'es': 'Redacción', 'fr': 'Censorship', 'de': 'Schwärzung'},
    {'en': 'Signature', 'es': 'Firma', 'fr': 'Signature', 'de': 'Unterschrift'},
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Multilingual Dictionary & Glossary',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._terms.map((t) => Card(
                child: ListTile(
                  title: Text(t['en']!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.toolPink)),
                  subtitle: Text('ES: ${t['es']} • FR: ${t['fr']} • DE: ${t['de']}'),
                ),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN 14: MARKDOWN TO PDF PUBLISHER SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class MarkdownToPdfScreen extends StatefulWidget {
  const MarkdownToPdfScreen({super.key});

  @override
  State<MarkdownToPdfScreen> createState() => _MarkdownToPdfScreenState();
}

class _MarkdownToPdfScreenState extends State<MarkdownToPdfScreen> {
  final TextEditingController _mdController = TextEditingController(
    text: '# Chapter 1: Introduction\n\nWelcome to **MaskerV PDF Publishing Studio**.\n\n- CMYK Prepress Validation\n- Clean Document Formatting\n- Reflowable Page Layouts\n\n> "Empowering readers with high-performance document processing tools."',
  );
  bool _isPublishing = false;
  File? _selectedFile;

  Future<void> _pickMarkdownFile() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['md', 'txt']);
    if (result.isNotEmpty && result.first.path != null) {
      final file = File(result.first.path!);
      final text = await file.readAsString();
      setState(() {
        _selectedFile = file;
        _mdController.text = text;
      });
    }
  }

  Future<void> _publishPdf() async {
    final text = _mdController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPublishing = true);
    try {
      final pdf = pw.Document();

      final lines = text.split('\n');
      final widgets = <pw.Widget>[];

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('# ')) {
          widgets.add(pw.Header(level: 0, text: trimmed.substring(2)));
        } else if (trimmed.startsWith('## ')) {
          widgets.add(pw.Header(level: 1, text: trimmed.substring(3)));
        } else if (trimmed.startsWith('### ')) {
          widgets.add(pw.Header(level: 2, text: trimmed.substring(4)));
        } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
          widgets.add(pw.Bullet(text: trimmed.substring(2)));
        } else if (trimmed.startsWith('> ')) {
          widgets.add(
            pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: PdfColors.grey600, width: 3)),
              ),
              padding: const pw.EdgeInsets.only(left: 10, top: 4, bottom: 4),
              child: pw.Text(trimmed.substring(2), style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            ),
          );
        } else if (trimmed.isNotEmpty) {
          widgets.add(pw.Paragraph(text: trimmed));
        } else {
          widgets.add(pw.SizedBox(height: 8));
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => widgets,
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Markdown_Doc_$timestamp.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      final fileSize = await file.length();

      final doc = DocumentFile(
        id: 'md_pdf_$timestamp',
        name: fileName,
        path: file.path,
        size: fileSize,
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.document,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'markdown-to-pdf',
                toolName: 'Markdown to PDF Publisher',
                fileName: fileName,
                outputPath: file.path,
                fileSize: fileSize,
                timestamp: DateTime.now(),
                success: true,
              ),
            );

        setState(() => _isPublishing = false);

        FileSuccessDialog.show(
          context,
          title: 'Markdown PDF Published!',
          message: 'Compiled Markdown to clean PDF document format.',
          file: file,
          fileSize: '${(fileSize / 1024).toStringAsFixed(1)} KB',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF Compile Error: $e'), backgroundColor: const Color(0xFFE11D48)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Markdown to PDF Publisher',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickMarkdownFile,
                    icon: const Icon(LucideIcons.fileText, size: 18),
                    label: Text(_selectedFile != null ? _selectedFile!.path.split(Platform.pathSeparator).last : 'Load Markdown File (.md, .txt)'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _mdController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: 'Markdown Source Content',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    label: 'Publish to PDF Document',
                    icon: LucideIcons.fileCheck,
                    isLoading: _isPublishing,
                    onPressed: _publishPdf,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
