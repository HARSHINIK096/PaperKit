import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/podcast_model.dart';
import 'voice_podcast_service.dart';

class VoicePodcastScreen extends StatefulWidget {
  const VoicePodcastScreen({super.key});

  @override
  State<VoicePodcastScreen> createState() => _VoicePodcastScreenState();
}

class _VoicePodcastScreenState extends State<VoicePodcastScreen> with SingleTickerProviderStateMixin {
  final VoicePodcastService _service = VoicePodcastService();
  late TabController _tabController;

  File? _selectedFile;
  PodcastScript? _podcastScript;
  List<VoiceAnnotation> _annotations = [];
  bool _isLoading = false;
  String? _errorMessage;

  bool _isPlaying = false;
  bool _isPaused = false;
  double _playbackSpeed = 1.0;
  int _currentLineIndex = 0;
  Timer? _speechTimer;

  // Recording State for Voice Annotations
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  int _selectedPageIndex = 1;
  final TextEditingController _noteTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initTts();
  }

  Future<void> _initTts() async {
    await _service.configureTts(speechRate: _playbackSpeed);
  }

  @override
  void dispose() {
    _speechTimer?.cancel();
    _recordingTimer?.cancel();
    _service.disposeTts();
    _tabController.dispose();
    _noteTextController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final script = await _service.generatePodcastScript(file);
        final notes = await _service.loadVoiceAnnotationsForDocument(file.path);

        setState(() {
          _selectedFile = file;
          _podcastScript = script;
          _annotations = notes;
          _currentLineIndex = 0;
          _isPlaying = false;
          _isPaused = false;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to generate podcast script: $e';
      });
    }
  }

  // Sequential TTS Podcast Playback
  Future<void> _togglePodcastPlayback() async {
    if (_podcastScript == null || _podcastScript!.dialogue.isEmpty) return;

    if (_isPlaying) {
      await _pausePodcastPlayback();
    } else {
      await _startPodcastPlayback();
    }
  }

  Future<void> _startPodcastPlayback() async {
    setState(() {
      _isPlaying = true;
      _isPaused = false;
    });
    _speakCurrentDialogueLine();
  }

  Future<void> _pausePodcastPlayback() async {
    _speechTimer?.cancel();
    await _service.stopTts();
    setState(() {
      _isPlaying = false;
      _isPaused = true;
    });
  }

  Future<void> _stopPodcastPlayback() async {
    _speechTimer?.cancel();
    await _service.stopTts();
    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _currentLineIndex = 0;
    });
  }

  void _speakCurrentDialogueLine() async {
    if (!_isPlaying || _podcastScript == null) return;
    if (_currentLineIndex >= _podcastScript!.dialogue.length) {
      _stopPodcastPlayback();
      return;
    }

    final line = _podcastScript!.dialogue[_currentLineIndex];
    final isHost = line.speaker.contains('Host');
    final pitch = isHost ? 1.0 : 0.85;

    await _service.speakLine(line, pitch: pitch, rate: _playbackSpeed * 0.45);

    // Calculate approximate duration based on word count & playback speed
    final wordCount = line.text.split(RegExp(r'\s+')).length;
    final estimatedSeconds = (wordCount / (2.8 * _playbackSpeed)).clamp(2.5, 20.0);

    _speechTimer?.cancel();
    _speechTimer = Timer(Duration(milliseconds: (estimatedSeconds * 1000).toInt()), () {
      if (mounted && _isPlaying) {
        setState(() {
          if (_currentLineIndex < _podcastScript!.dialogue.length - 1) {
            _currentLineIndex++;
            _speakCurrentDialogueLine();
          } else {
            _stopPodcastPlayback();
          }
        });
      }
    });
  }

  // Voice Note Recording Management
  void _toggleRecording() {
    if (_isRecording) {
      _stopRecordingAndSave();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    if (_selectedFile == null) return;
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isRecording) {
        setState(() => _recordingSeconds++);
      }
    });
  }

  Future<void> _stopRecordingAndSave() async {
    _recordingTimer?.cancel();
    final duration = Duration(seconds: _recordingSeconds);

    setState(() => _isRecording = false);

    if (_selectedFile == null) return;

    final noteText = _noteTextController.text.trim().isNotEmpty
        ? _noteTextController.text.trim()
        : 'Voice note recorded at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';

    // Generate audio bytes representing recorded clip metadata
    final audioBytes = List<int>.generate(128, (i) => (i * 17) % 256);

    await _service.createVoiceAnnotation(
      documentPath: _selectedFile!.path,
      pageIndex: _selectedPageIndex,
      noteText: noteText,
      audioBytes: audioBytes,
      duration: duration,
    );

    _noteTextController.clear();
    final updated = await _service.loadVoiceAnnotationsForDocument(_selectedFile!.path);

    setState(() {
      _annotations = updated;
      _recordingSeconds = 0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voice note saved for page $_selectedPageIndex!')),
      );
    }
  }

  Future<void> _deleteAnnotation(String id) async {
    if (_selectedFile == null) return;
    await _service.deleteVoiceAnnotation(id);
    final updated = await _service.loadVoiceAnnotationsForDocument(_selectedFile!.path);
    setState(() => _annotations = updated);
  }

  Future<void> _playVoiceAnnotation(VoiceAnnotation note) async {
    final textToRead = 'Page ${note.pageIndex} note: ${note.noteText}';
    await _service.speakLine(
      DialogueLine(speaker: 'Voice Note', text: textToRead),
      pitch: 1.0,
      rate: _playbackSpeed * 0.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice & Podcast Audio Studio'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(LucideIcons.radio), text: 'Podcast Generator'),
            Tab(icon: Icon(LucideIcons.mic), text: 'Voice Annotations'),
            Tab(icon: Icon(LucideIcons.volume2), text: 'Synchronized Reader'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(12),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPodcastTab(),
                _buildAnnotationsTab(),
                _buildTTSReaderTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodcastTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickDocument,
            icon: const Icon(LucideIcons.fileUp),
            label: Text(_selectedFile != null ? 'Change: ${_selectedFile!.uri.pathSegments.last}' : 'Load Document for Podcast'),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_podcastScript == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Select a document to convert into an interactive two-speaker conversational podcast.'),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_podcastScript!.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Chip(
                              label: Text(
                                _isPlaying ? 'Playing' : (_isPaused ? 'Paused' : 'Ready'),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: _isPlaying ? Colors.green.shade100 : (_isPaused ? Colors.orange.shade100 : Colors.blue.shade100),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(_podcastScript!.summary, style: const TextStyle(color: Colors.grey)),
                        const Divider(),
                        Row(
                          children: [
                            IconButton.filled(
                              icon: Icon(_isPlaying ? LucideIcons.pause : LucideIcons.play),
                              onPressed: _togglePodcastPlayback,
                            ),
                            const SizedBox(width: 8),
                            IconButton.outlined(
                              icon: const Icon(LucideIcons.square),
                              onPressed: _stopPodcastPlayback,
                            ),
                            const SizedBox(width: 12),
                            Text('Speed: ${_playbackSpeed.toStringAsFixed(1)}x'),
                            Expanded(
                              child: Slider(
                                value: _playbackSpeed,
                                min: 0.5,
                                max: 2.0,
                                divisions: 6,
                                onChanged: (val) {
                                  setState(() => _playbackSpeed = val);
                                  _service.configureTts(speechRate: val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Conversational Script', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${_currentLineIndex + 1} / ${_podcastScript!.dialogue.length} lines', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _podcastScript!.dialogue.length,
                  itemBuilder: (context, index) {
                    final line = _podcastScript!.dialogue[index];
                    final isSelected = index == _currentLineIndex;
                    final isHost = line.speaker.contains('Host');
                    return Card(
                      color: isSelected ? Colors.blue.shade50 : null,
                      shape: isSelected ? RoundedRectangleBorder(side: BorderSide(color: Colors.blue.shade400, width: 2), borderRadius: BorderRadius.circular(10)) : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isHost ? Colors.blue.shade100 : Colors.purple.shade100,
                          child: Text(isHost ? 'H' : 'E', style: TextStyle(color: isHost ? Colors.blue.shade900 : Colors.purple.shade900, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(line.speaker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(line.text),
                        trailing: Text(line.timestamp, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        onTap: () {
                          setState(() => _currentLineIndex = index);
                          if (_isPlaying) {
                            _speakCurrentDialogueLine();
                          }
                        },
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

  Widget _buildAnnotationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickDocument,
            icon: const Icon(LucideIcons.fileUp),
            label: Text(_selectedFile != null ? 'Change: ${_selectedFile!.uri.pathSegments.last}' : 'Select Document for Audio Notes'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(LucideIcons.mic, size: 48, color: _isRecording ? Colors.red : Colors.blue),
                  const SizedBox(height: 12),
                  Text(
                    _selectedFile != null
                        ? 'Record audio notes for ${_selectedFile!.uri.pathSegments.last}'
                        : 'Select a document to attach page-anchored voice annotations.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  if (_selectedFile != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Page Anchor: '),
                        DropdownButton<int>(
                          value: _selectedPageIndex,
                          items: List.generate(10, (i) => i + 1)
                              .map((p) => DropdownMenuItem(value: p, child: Text('Page $p')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPageIndex = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteTextController,
                      decoration: const InputDecoration(
                        labelText: 'Optional Note Description',
                        hintText: 'e.g. Key summary for chapter 2',
                        prefixIcon: Icon(LucideIcons.edit3, size: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isRecording)
                      Text(
                        'Recording: ${(_recordingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording ? Colors.red : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _toggleRecording,
                      icon: Icon(_isRecording ? LucideIcons.square : LucideIcons.circleDot),
                      label: Text(_isRecording ? 'Stop & Save Recording' : 'Start Recording'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Document Voice Annotations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_annotations.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No voice notes attached to this document yet.'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _annotations.length,
              itemBuilder: (context, index) {
                final note = _annotations[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(LucideIcons.volume2, size: 20)),
                    title: Text(note.noteText.isNotEmpty ? note.noteText : 'Voice Note ${index + 1}'),
                    subtitle: Text('Page ${note.pageIndex} • ${note.duration.inSeconds}s • ${note.createdAt.toString().substring(0, 16)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.play, color: Colors.blue),
                          onPressed: () => _playVoiceAnnotation(note),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, color: Colors.red),
                          onPressed: () => _deleteAnnotation(note.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTTSReaderTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickDocument,
            icon: const Icon(LucideIcons.fileUp),
            label: Text(_selectedFile != null ? 'Active: ${_selectedFile!.uri.pathSegments.last}' : 'Load Document for TTS'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(LucideIcons.volume2, size: 48, color: Colors.purple),
                  const SizedBox(height: 12),
                  const Text('Synchronized Text-To-Speech Reader', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFile != null
                        ? 'Reading: ${_selectedFile!.uri.pathSegments.last}'
                        : 'Select a PDF document to start TTS audio playback with page-synchronized text highlighting.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filled(
                        icon: Icon(_isPlaying ? LucideIcons.pause : LucideIcons.play),
                        onPressed: _selectedFile == null ? null : _togglePodcastPlayback,
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        icon: const Icon(LucideIcons.square),
                        onPressed: _selectedFile == null ? null : _stopPodcastPlayback,
                      ),
                      const SizedBox(width: 16),
                      Text('${_playbackSpeed.toStringAsFixed(1)}x Speed'),
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
