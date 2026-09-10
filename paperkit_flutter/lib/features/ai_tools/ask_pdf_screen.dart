import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_shell.dart';

class AskPDFScreen extends StatefulWidget {
  const AskPDFScreen({super.key});

  @override
  State<AskPDFScreen> createState() => _AskPDFScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  _ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class _AskPDFScreenState extends State<AskPDFScreen> {
  File? _selectedFile;
  final TextEditingController _queryController = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _messages.clear();
        _messages.add(
          _ChatMessage(
            text: 'Hello! I have loaded "${_selectedFile!.uri.pathSegments.last}". Ask me anything about this document!',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _queryController.text.trim();
    if (text.isEmpty || _selectedFile == null) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _queryController.clear();
      _isLoading = true;
    });

    try {
      final res = await ApiService().askPDF(
        file: _selectedFile!,
        question: text,
      );
      final answer = res['answer'] ?? res['response'] ?? 'No answer provided by PaperKit AI server.';

      setState(() {
        _messages.add(_ChatMessage(text: answer, isUser: false, timestamp: DateTime.now()));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          text: 'PaperKit AI Processing Error: Unable to complete request ($e). Please verify server connection.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Ask PDF (AI Chat)',
      showBottomNav: false,
      actions: [
        if (_selectedFile != null)
          TextButton.icon(
            onPressed: _pickFile,
            icon: const Icon(LucideIcons.fileText, size: 16),
            label: const Text('Change File'),
          ),
      ],
      child: Column(
        children: [
          if (_selectedFile == null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.toolBlue.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.messageSquare, color: AppColors.toolBlue, size: 36),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Chat with Any Document',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ask questions, extract facts, summarize sections, and synthesize findings with AI.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(LucideIcons.filePlus, size: 18),
                        label: const Text('Select Document to Chat'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            // Chat history
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.82,
                      ),
                      decoration: BoxDecoration(
                        color: msg.isUser
                            ? AppColors.primary
                            : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                        borderRadius: BorderRadius.circular(16),
                        border: msg.isUser
                            ? null
                            : Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      child: msg.isUser
                          ? Text(
                              msg.text,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                height: 1.45,
                              ),
                            )
                          : MarkdownBody(
                              data: msg.text,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                                ),
                                strong: const TextStyle(fontWeight: FontWeight.w700),
                                code: TextStyle(
                                  fontSize: 12.5,
                                  fontFamily: 'monospace',
                                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('AI is reading document...', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),

            // Input Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      decoration: InputDecoration(
                        hintText: 'Ask a question about document...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(LucideIcons.send, size: 18),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
