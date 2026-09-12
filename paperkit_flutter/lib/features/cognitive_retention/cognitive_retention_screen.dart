import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/study_session_model.dart';
import '../../core/services/pdf_engine.dart';
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

  // Active Recall Mode
  bool _activeRecallActive = true;

  // Pomodoro
  Timer? _pomodoroTimer;
  int _pomodoroSecondsRemaining = 25 * 60;
  bool _isPomodoroRunning = false;
  int _completedPomodoros = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDecks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pomodoroTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDecks() async {
    final loaded = await _service.loadDecks();
    setState(() {
      _decks = loaded;
    });
  }

  Future<void> _pickDocument() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);
        String text = '';
        if (path.endsWith('.pdf')) {
          text = await PdfEngine.extractTextFromPdf(file);
        } else {
          text = await file.readAsString();
        }

        final cards = _service.extractRecallItemsFromText(text, documentPath: path);

        setState(() {
          _selectedFile = file;
          _recallCards = cards;
          _isLoading = false;
        });

        // Save auto-created deck
        if (cards.isNotEmpty) {
          final deck = StudyDeck(
            id: 'deck_${DateTime.now().millisecondsSinceEpoch}',
            name: file.uri.pathSegments.last,
            documentPath: path,
            cards: cards,
          );
          await _service.saveDeck(deck);
          await _loadDecks();
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load document: ${e.toString()}';
      });
    }
  }

  void _startPomodoro() {
    setState(() => _isPomodoroRunning = true);
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_pomodoroSecondsRemaining > 0) {
        setState(() => _pomodoroSecondsRemaining--);
      } else {
        timer.cancel();
        setState(() {
          _isPomodoroRunning = false;
          _completedPomodoros++;
          _pomodoroSecondsRemaining = 25 * 60;
        });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cognitive Retention Studio'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(LucideIcons.eyeOff), text: 'Blur Recall'),
            Tab(icon: Icon(LucideIcons.brainCircuit), text: 'Spaced Repetition'),
            Tab(icon: Icon(LucideIcons.box), text: 'Leitner Decks'),
            Tab(icon: Icon(LucideIcons.timer), text: 'Pomodoro'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBlurRecallTab(),
                _buildSpacedRepetitionTab(),
                _buildLeitnerTab(),
                _buildPomodoroTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurRecallTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickDocument,
                icon: const Icon(LucideIcons.fileUp),
                label: const Text('Load Document'),
              ),
              const Spacer(),
              FilterChip(
                label: const Text('Blur Active'),
                selected: _activeRecallActive,
                onSelected: (val) => setState(() => _activeRecallActive = val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_selectedFile == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(LucideIcons.fileText, size: 48, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 12),
                    const Text('No Document Loaded', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Select a PDF or text document to generate interactive active recall challenges.'),
                  ],
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Recall: ${_recallCards.length} Terms', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recallCards.length,
                  itemBuilder: (context, index) {
                    final card = _recallCards[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          _activeRecallActive && card.isBlurred ? '█' * card.term.length : card.term,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: card.isBlurred ? Colors.amber.shade900 : Colors.green.shade800,
                          ),
                        ),
                        subtitle: Text(card.definition),
                        trailing: IconButton(
                          icon: Icon(card.isBlurred ? LucideIcons.eyeOff : LucideIcons.eye),
                          onPressed: () {
                            setState(() {
                              card.isBlurred = !card.isBlurred;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSpacedRepetitionTab() {
    if (_recallCards.isEmpty) {
      return const Center(child: Text('Load a document in Blur Recall to populate Spaced Repetition queue.'));
    }

    final card = _recallCards.first;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              child: Column(
                children: [
                  Text('BOX ${card.leitnerBox}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(card.term, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Divider(height: 32),
                  Text(card.definition, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() => _service.rateCardRecall(card, CardDifficulty.forgotten));
                },
                child: const Text('Forgotten'),
              ),
              OutlinedButton(
                onPressed: () {
                  setState(() => _service.rateCardRecall(card, CardDifficulty.hard));
                },
                child: const Text('Hard'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _service.rateCardRecall(card, CardDifficulty.easy));
                },
                child: const Text('Easy'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeitnerTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _decks.length,
      itemBuilder: (context, index) {
        final deck = _decks[index];
        return Card(
          child: ListTile(
            leading: const Icon(LucideIcons.box),
            title: Text(deck.name),
            subtitle: Text('${deck.cards.length} Cards • Created ${deck.createdAt.toString().split(' ')[0]}'),
            trailing: IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.red),
              onPressed: () async {
                await _service.deleteDeck(deck.id);
                await _loadDecks();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPomodoroTab() {
    final minutes = (_pomodoroSecondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_pomodoroSecondsRemaining % 60).toString().padLeft(2, '0');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$minutes:$seconds', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Completed Sessions: $_completedPomodoros', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                iconSize: 32,
                icon: Icon(_isPomodoroRunning ? LucideIcons.pause : LucideIcons.play),
                onPressed: _isPomodoroRunning ? _pausePomodoro : _startPomodoro,
              ),
              const SizedBox(width: 16),
              IconButton.outlined(
                iconSize: 32,
                icon: const Icon(LucideIcons.rotateCcw),
                onPressed: _resetPomodoro,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
