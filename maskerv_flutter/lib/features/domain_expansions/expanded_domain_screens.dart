import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/file_success_dialog.dart';

// ── DOMAIN 5: SPACED REPETITION STUDY TRACKER ────────────────────────────────
class SpacedRepetitionScreen extends StatefulWidget {
  const SpacedRepetitionScreen({super.key});

  @override
  State<SpacedRepetitionScreen> createState() => _SpacedRepetitionScreenState();
}

class _SpacedRepetitionScreenState extends State<SpacedRepetitionScreen> {
  int _leitnerBox = 1;
  int _cardIndex = 0;
  final List<Map<String, String>> _cards = [
    {'q': 'What is SM-2 Algorithm?', 'a': 'SuperMemo-2 spaced repetition interval calculator based on user recall quality rating.'},
    {'q': 'What is Active Recall?', 'a': 'Testing memory during learning rather than passive review.'},
  ];

  @override
  Widget build(BuildContext context) {
    final card = _cards[_cardIndex % _cards.length];
    return AppShell(
      title: 'Spaced Repetition SM-2 Tracker',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Leitner Box $_leitnerBox • Review Interval: ${_leitnerBox * 2} Days', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  const SizedBox(height: 20),
                  Text(card['q']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(card['a']!, style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() {
                          _leitnerBox = (_leitnerBox > 1) ? _leitnerBox - 1 : 1;
                          _cardIndex++;
                        }),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                        child: const Text('Hard (-1 Box)'),
                      ),
                      ElevatedButton(
                        onPressed: () => setState(() {
                          _leitnerBox = (_leitnerBox < 5) ? _leitnerBox + 1 : 5;
                          _cardIndex++;
                        }),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        child: const Text('Easy (+1 Box)'),
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

// ── DOMAIN 5: SPEED READER SPRINT ───────────────────────────────────────────
class SpeedReaderScreen extends StatefulWidget {
  const SpeedReaderScreen({super.key});

  @override
  State<SpeedReaderScreen> createState() => _SpeedReaderScreenState();
}

class _SpeedReaderScreenState extends State<SpeedReaderScreen> {
  final TextEditingController _textController = TextEditingController(
    text: 'Rapid Serial Visual Presentation RSVP trains cognitive reading speed and focus.',
  );
  int _wpm = 300;
  bool _isPlaying = false;
  String _currentWord = 'Ready';
  Timer? _timer;

  void _togglePlay() {
    if (_isPlaying) {
      _timer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      final words = _textController.text.trim().split(RegExp(r'\s+'));
      if (words.isEmpty) return;
      int idx = 0;
      setState(() => _isPlaying = true);
      final interval = Duration(milliseconds: (60000 / _wpm).round());
      _timer = Timer.periodic(interval, (t) {
        if (idx >= words.length) {
          t.cancel();
          setState(() => _isPlaying = false);
        } else {
          setState(() => _currentWord = words[idx++]);
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
    return AppShell(
      title: 'Speed Reading RSVP Trainer',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    height: 100,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16)),
                    child: Text(_currentWord, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  ),
                  const SizedBox(height: 20),
                  Text('Reading Speed: $_wpm WPM', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _wpm.toDouble(),
                    min: 100,
                    max: 800,
                    divisions: 14,
                    onChanged: (v) => setState(() => _wpm = v.round()),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _togglePlay,
                    icon: Icon(_isPlaying ? LucideIcons.pause : LucideIcons.play),
                    label: Text(_isPlaying ? 'Pause Sprint' : 'Start Reading Sprint'),
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

// ── DOMAIN 6: AUDIO TRIMMER & CUTTER ─────────────────────────────────────────
class AudioTrimmerScreen extends StatelessWidget {
  const AudioTrimmerScreen({super.key});

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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(LucideIcons.scissors, size: 48, color: Color(0xFF2563EB)),
                  const SizedBox(height: 12),
                  const Text('Audio Trimmer Engine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Trim start & end timestamps from MP3, WAV audio files.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.upload), label: const Text('Select Audio File')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── DOMAIN 6: VOICE NOTE TRANSCRIBER ────────────────────────────────────────
class VoiceTranscriberScreen extends StatelessWidget {
  const VoiceTranscriberScreen({super.key});

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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(LucideIcons.mic, size: 48, color: Color(0xFF7C3AED)),
                  const SizedBox(height: 12),
                  const Text('Voice-to-Text Transcriber', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Convert spoken voice notes and audio files into clean transcript text.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.fileAudio), label: const Text('Transcribe Voice File')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── DOMAIN 7: HIGH CONTRAST READER ──────────────────────────────────────────
class HighContrastReaderScreen extends StatelessWidget {
  const HighContrastReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'High Contrast Inclusive Reader',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.yellow,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: const [
                  Text('HIGH CONTRAST PALETTE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
                  SizedBox(height: 8),
                  Text('Optimized for low-vision and color-blind inclusive reading.', style: TextStyle(color: Colors.black, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── DOMAIN 7: TTS ACCESSIBILITY ─────────────────────────────────────────────
class TtsAccessibilityScreen extends StatelessWidget {
  const TtsAccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Text-to-Speech Accessibility',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(LucideIcons.volume2, size: 48, color: Color(0xFF0D9488)),
                  const SizedBox(height: 12),
                  const Text('Screen Reader & Speech Engine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.volumeX), label: const Text('Read Text Aloud')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── DOMAIN 8: LEGAL REDACTION CERTIFIER ─────────────────────────────────────
class RedactionCertifierScreen extends StatelessWidget {
  const RedactionCertifierScreen({super.key});

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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(LucideIcons.shieldCheck, size: 48, color: Color(0xFFDC2626)),
                  const SizedBox(height: 12),
                  const Text('SHA-256 Redaction Audit Certificate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.award), label: const Text('Generate Audit Certificate')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── DOMAIN 8: CONTRACT CLAUSE COMPARATOR ────────────────────────────────────
class ClauseComparatorScreen extends StatelessWidget {
  const ClauseComparatorScreen({super.key});

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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(LucideIcons.gitCompare, size: 48, color: Color(0xFFDC2626)),
                  const SizedBox(height: 12),
                  const Text('Legal Clause Diff & Risk Matrix', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.fileDiff), label: const Text('Compare Contract Clauses')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── DOMAIN 9: FORM DATA EXTRACTOR ───────────────────────────────────────────
class FormDataExtractorScreen extends StatelessWidget {
  const FormDataExtractorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Form Field Data Extractor',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(LucideIcons.formInput, size: 48, color: Color(0xFF2563EB)),
                  const SizedBox(height: 12),
                  const Text('Extract Filled Form Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.download), label: const Text('Export Form JSON / CSV')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── DOMAIN 11: FOCUS POMODORO TIMER ─────────────────────────────────────────
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
      title: 'Student Focus Pomodoro Timer',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('$mins:$secs', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _toggleTimer,
                    icon: Icon(_isRunning ? LucideIcons.pause : LucideIcons.play),
                    label: Text(_isRunning ? 'Pause Timer' : 'Start 25-Min Study Session'),
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

// ── DOMAIN 11: GPA CALCULATOR ───────────────────────────────────────────────
class GpaCalculatorScreen extends StatelessWidget {
  const GpaCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Student Grade & GPA Calculator',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(LucideIcons.calculator, size: 48, color: Color(0xFF4F46E5)),
                  const SizedBox(height: 12),
                  const Text('GPA & Course Predictor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.plus), label: const Text('Calculate GPA')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── DOMAIN 14: MULTILINGUAL GLOSSARY ────────────────────────────────────────
class MultilingualGlossaryScreen extends StatelessWidget {
  const MultilingualGlossaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Multilingual Dictionary & Glossary',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(LucideIcons.bookMarked, size: 48, color: Color(0xFFDB2777)),
                  const SizedBox(height: 12),
                  const Text('Domain Glossary Memory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.search), label: const Text('Lookup Term')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── DOMAIN 15: EBOOK COVER DESIGNER ─────────────────────────────────────────
class EbookCoverDesignerScreen extends StatelessWidget {
  const EbookCoverDesignerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'e-Book Cover Design Studio',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(LucideIcons.bookOpen, size: 48, color: Color(0xFF9333EA)),
                  const SizedBox(height: 12),
                  const Text('Reflowable Cover Layout Studio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.palette), label: const Text('Design Cover')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── DOMAIN 15: MARKDOWN TO EPUB ─────────────────────────────────────────────
class MarkdownToEpubScreen extends StatelessWidget {
  const MarkdownToEpubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Markdown to ePub Publisher',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(LucideIcons.fileCheck, size: 48, color: Color(0xFF9333EA)),
                  const SizedBox(height: 12),
                  const Text('Compile Markdown to .ePub eBook', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.bookOpenCheck), label: const Text('Publish .ePub Book')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
