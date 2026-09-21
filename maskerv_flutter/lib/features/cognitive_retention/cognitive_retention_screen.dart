import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/study_session_model.dart';
import '../../core/services/pdf_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/compact_upload_container.dart';
import 'cognitive_retention_service.dart';

class CognitiveRetentionScreen extends StatefulWidget {
  const CognitiveRetentionScreen({super.key});

  @override
  State<CognitiveRetentionScreen> createState() => _CognitiveRetentionScreenState();
}

class _CognitiveRetentionScreenState extends State<CognitiveRetentionScreen> with SingleTickerProviderStateMixin {
  final CognitiveRetentionService _service = CognitiveRetentionService();
  late TabController _tabController;

  File? _selectedFile;
  List<RecallItem> _recallCards = [];
  List<StudyDeck> _decks = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Spaced Repetition Queue State
  int _currentCardIndex = 0;
  bool _isAnswerRevealed = false;
  int _sessionSuccessCount = 0;

  // Active Recall Blur Mode
  bool _activeRecallActive = true;

  // Pomodoro Timer
  Timer? _pomodoroTimer;
  int _pomodoroSecondsRemaining = 25 * 60;
  bool _isPomodoroRunning = false;
  int _completedPomodoros = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDecksAndSamples();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pomodoroTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDecksAndSamples() async {
    final loaded = await _service.loadDecks();
    setState(() {
      _decks = loaded;
      if (_recallCards.isEmpty) {
        if (_decks.isNotEmpty && _decks.first.cards.isNotEmpty) {
          _recallCards = List.from(_decks.first.cards);
        } else {
          _recallCards = _service.getSampleStudyCards();
        }
      }
    });
  }

  Future<void> _processDocument(File file) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final path = file.path;
      String text = '';
      if (path.endsWith('.pdf')) {
        text = await PdfEngine.extractTextFromPdf(file);
      } else {
        text = await file.readAsString();
      }

      final cards = _service.extractRecallItemsFromText(text, documentPath: path);
      if (cards.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No structured key terms or definitions found in document. Try another study PDF or text notes file.';
        });
        return;
      }

      final deck = StudyDeck(
        id: 'deck_${DateTime.now().millisecondsSinceEpoch}',
        name: file.uri.pathSegments.last,
        documentPath: path,
        cards: cards,
      );

      await _service.saveDeck(deck);
      await _loadDecksAndSamples();

      setState(() {
        _selectedFile = file;
        _recallCards = cards;
        _currentCardIndex = 0;
        _isAnswerRevealed = false;
        _sessionSuccessCount = 0;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Extracted ${cards.length} active recall study flashcards!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to extract study cards: ${e.toString()}';
      });
    }
  }

  void _rateCurrentCard(CardDifficulty difficulty) {
    if (_recallCards.isEmpty || _currentCardIndex >= _recallCards.length) return;

    HapticFeedback.lightImpact();
    final card = _recallCards[_currentCardIndex];
    _service.rateCardRecall(card, difficulty);

    if (difficulty == CardDifficulty.easy || difficulty == CardDifficulty.medium) {
      _sessionSuccessCount++;
    }

    setState(() {
      _isAnswerRevealed = false;
      _currentCardIndex++;
    });

    // Save updated card metrics to active deck
    if (_decks.isNotEmpty) {
      final activeDeck = _decks.first;
      _service.saveDeck(activeDeck);
    }
  }

  void _restartReviewSession() {
    setState(() {
      _currentCardIndex = 0;
      _isAnswerRevealed = false;
      _sessionSuccessCount = 0;
    });
  }

  void _loadDeckForReview(StudyDeck deck) {
    setState(() {
      _recallCards = List.from(deck.cards);
      _currentCardIndex = 0;
      _isAnswerRevealed = false;
      _sessionSuccessCount = 0;
    });
    _tabController.animateTo(1); // Switch to Spaced Repetition Tab
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded "${deck.name}" (${deck.cards.length} cards) into Spaced Repetition'),
        backgroundColor: AppColors.toolPurple,
      ),
    );
  }

  // Pomodoro Actions
  void _startPomodoro() {
    setState(() => _isPomodoroRunning = true);
    _pomodoroTimer?.cancel();
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_pomodoroSecondsRemaining > 0) {
        setState(() => _pomodoroSecondsRemaining--);
      } else {
        timer.cancel();
        HapticFeedback.vibrate();
        setState(() {
          _isPomodoroRunning = false;
          _completedPomodoros++;
          _pomodoroSecondsRemaining = 25 * 60;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pomodoro 25-Min Deep Study Session Completed! Take a 5-min break.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
    });
  }

  void _pausePomodoro() {
    _pomodoroTimer?.cancel();
    setState(() => _isPomodoroRunning = false);
  }

  void _resetPomodoro() {
    _pomodoroTimer?.cancel();
    setState(() {
      _isPomodoroRunning = false;
      _pomodoroSecondsRemaining = 25 * 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamified Cognitive Retention Studio'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.toolPurple,
          indicatorColor: AppColors.toolPurple,
          tabs: const [
            Tab(icon: Icon(LucideIcons.eyeOff, size: 18), text: 'Blur Recall'),
            Tab(icon: Icon(LucideIcons.brainCircuit, size: 18), text: 'Spaced Review'),
            Tab(icon: Icon(LucideIcons.box, size: 18), text: 'Leitner Decks'),
            Tab(icon: Icon(LucideIcons.timer, size: 18), text: 'Pomodoro'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBlurRecallTab(isDark),
                _buildSpacedRepetitionTab(isDark),
                _buildLeitnerTab(isDark),
                _buildPomodoroTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. BLUR RECALL TAB ──
  Widget _buildBlurRecallTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CompactUploadContainer(
            files: _selectedFile != null ? [_selectedFile!] : [],
            title: 'Load Document for Active Recall',
            subtitle: 'Extract key terms & blurred concepts from PDF or notes',
            icon: LucideIcons.brain,
            primaryColor: AppColors.toolPurple,
            allowedExtensions: const ['pdf', 'txt', 'md'],
            useShader: true,
            enabled: !_isLoading,
            onFilesSelected: (files) {
              if (files.isNotEmpty) {
                _processDocument(files.first);
              }
            },
            onClear: () {
              setState(() {
                _selectedFile = null;
                _recallCards = _service.getSampleStudyCards();
                _currentCardIndex = 0;
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Active Recall Terms (${_recallCards.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                icon: Icon(_activeRecallActive ? LucideIcons.eye : LucideIcons.eyeOff, size: 16),
                label: Text(_activeRecallActive ? 'Unblur All' : 'Blur All'),
                onPressed: () {
                  setState(() {
                    _activeRecallActive = !_activeRecallActive;
                    for (final c in _recallCards) {
                      c.isBlurred = _activeRecallActive;
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_recallCards.isEmpty)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No terms extracted yet. Upload a study document above.'),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recallCards.length,
              itemBuilder: (context, index) {
                final card = _recallCards[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: card.isBlurred ? Colors.amber.shade300 : AppColors.toolPurple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.toolPurple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Box ${card.leitnerBox}',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.toolPurple),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            card.isBlurred ? '█' * (card.term.length + 2) : card.term,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: card.isBlurred ? 1.5 : 0,
                              color: card.isBlurred ? Colors.amber.shade900 : AppColors.toolPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        card.definition,
                        style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(card.isBlurred ? LucideIcons.eyeOff : LucideIcons.eye, color: AppColors.toolPurple),
                      onPressed: () {
                        setState(() {
                          card.isBlurred = !card.isBlurred;
                        });
                      },
                      tooltip: card.isBlurred ? 'Tap to Unblur Answer' : 'Blur Term',
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ── 2. SPACED REPETITION TAB ──
  Widget _buildSpacedRepetitionTab(bool isDark) {
    if (_recallCards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.repeat, size: 48, color: AppColors.toolPurple.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              const Text('Review Queue Empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Load a document in Blur Recall or select a saved deck from Leitner Decks.'),
            ],
          ),
        ),
      );
    }

    // Completion summary if review queue finished
    if (_currentCardIndex >= _recallCards.length) {
      final total = _recallCards.length;
      final accuracy = total > 0 ? ((_sessionSuccessCount / total) * 100).round() : 100;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.checkCheck, size: 48, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Review Session Complete!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'You reviewed $total flashcards with $accuracy% mastery accuracy.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _restartReviewSession,
                icon: const Icon(LucideIcons.rotateCcw, size: 18),
                label: const Text('Review Deck Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.toolPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final card = _recallCards[_currentCardIndex];
    final progress = (_currentCardIndex + 1) / _recallCards.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Queue Header & Progress Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${_currentCardIndex + 1} of ${_recallCards.length}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.toolPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Leitner Box ${card.leitnerBox}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.toolPurple),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.toolPurple),
            ),
          ),
          const SizedBox(height: 24),

          // Interactive Flashcard Card
          GestureDetector(
            onTap: () => setState(() => _isAnswerRevealed = !_isAnswerRevealed),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: const BoxConstraints(minHeight: 220),
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'QUESTION / TERM',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      card.term,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
                    ),
                    const Divider(height: 32),
                    if (_isAnswerRevealed) ...[
                      Text(
                        'ANSWER / DEFINITION',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.toolPurple.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        card.definition,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, height: 1.4),
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _isAnswerRevealed = true),
                        icon: const Icon(LucideIcons.eye, size: 16),
                        label: const Text('Tap to Reveal Answer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.toolPurple,
                          side: const BorderSide(color: AppColors.toolPurple),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Difficulty Rating Buttons (Visible when answer is revealed or for quick rating)
          if (_isAnswerRevealed) ...[
            const Text(
              'How well did you recall this concept?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rateCurrentCard(CardDifficulty.forgotten),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Forgotten', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rateCurrentCard(CardDifficulty.hard),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Hard', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rateCurrentCard(CardDifficulty.easy),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Easy', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── 3. LEITNER DECKS TAB ──
  Widget _buildLeitnerTab(bool isDark) {
    if (_decks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.box, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('No Saved Decks Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Load a PDF or study document in the Blur Recall tab to automatically save a Leitner study deck.'),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _decks.length,
      itemBuilder: (context, index) {
        final deck = _decks[index];
        final box1Count = deck.cards.where((c) => c.leitnerBox == 1).length;
        final masteredCount = deck.cards.where((c) => c.leitnerBox >= 4).length;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.toolPurple.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.box, color: AppColors.toolPurple, size: 24),
            ),
            title: Text(deck.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${deck.cards.length} Cards • Created ${deck.createdAt.toString().split(' ')[0]}'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Review Box 1: $box1Count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Mastered: $masteredCount', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () => _loadDeckForReview(deck),
            trailing: IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
              onPressed: () async {
                await _service.deleteDeck(deck.id);
                await _loadDecksAndSamples();
              },
              tooltip: 'Delete Deck',
            ),
          ),
        );
      },
    );
  }

  // ── 4. POMODORO TAB ──
  Widget _buildPomodoroTab(bool isDark) {
    final minutes = (_pomodoroSecondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_pomodoroSecondsRemaining % 60).toString().padLeft(2, '0');
    final progress = (25 * 60 - _pomodoroSecondsRemaining) / (25 * 60);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.toolPurple),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$minutes:$seconds', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Focus Period (25m)', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.toolPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Completed Sessions: $_completedPomodoros',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.toolPurple),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isPomodoroRunning ? _pausePomodoro : _startPomodoro,
                  icon: Icon(_isPomodoroRunning ? LucideIcons.pause : LucideIcons.play, size: 20),
                  label: Text(_isPomodoroRunning ? 'Pause' : 'Start Focus'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.toolPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 14),
                OutlinedButton.icon(
                  onPressed: _resetPomodoro,
                  icon: const Icon(LucideIcons.rotateCcw, size: 18),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.toolPurple,
                    side: const BorderSide(color: AppColors.toolPurple),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
