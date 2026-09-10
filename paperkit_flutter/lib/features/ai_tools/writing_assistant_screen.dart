import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class WritingAssistantScreen extends StatefulWidget {
  const WritingAssistantScreen({super.key});

  @override
  State<WritingAssistantScreen> createState() => _WritingAssistantScreenState();
}

class _WritingAssistantScreenState extends State<WritingAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _mode = 'academic'; // 'academic', 'formal', 'concise', 'paraphrase'
  bool _isProcessing = false;
  String _polishedText = '';

  Future<void> _polishText() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isProcessing = true);

    try {
      final res = await ApiService().writingAssistant(text: text, task: _mode);
      final improved = res['improved_text'] ?? res['result'] ?? '';
      if (improved.trim().isEmpty) {
        throw Exception('PaperKit writing engine did not return improved text.');
      }

      setState(() {
        _polishedText = improved;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PaperKit Writing Assistant Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'AI Writing Assistant',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _inputController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Paste or type text to polish',
              hintText: 'Enter paragraphs, draft notes, or manuscript sections...',
            ),
          ),
          const SizedBox(height: 16),

          Text('Target Polish Style', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            children: [
              _buildModeChip('Academic & Scholarly', 'academic'),
              _buildModeChip('Formal Professional', 'formal'),
              _buildModeChip('Concise & Direct', 'concise'),
              _buildModeChip('Paraphrase & Reword', 'paraphrase'),
            ],
          ),
          const SizedBox(height: 20),

          ActionButton(
            label: 'Polish with AI Writing Assistant',
            icon: LucideIcons.penTool,
            isLoading: _isProcessing,
            onPressed: _polishText,
          ),

          if (_polishedText.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Polished Output', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _polishedText));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied polished text!')));
                  },
                  icon: const Icon(LucideIcons.copy, size: 16),
                  label: const Text('Copy'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: SelectableText(
                _polishedText,
                style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, String val) {
    final isSelected = _mode == val;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (_) => setState(() => _mode = val),
    );
  }
}
