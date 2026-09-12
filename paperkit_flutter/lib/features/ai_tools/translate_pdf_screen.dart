import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/how_it_works_carousel.dart';
import '../../core/widgets/markdown_viewer.dart';

class TranslatePDFScreen extends StatefulWidget {
  const TranslatePDFScreen({super.key});

  @override
  State<TranslatePDFScreen> createState() => _TranslatePDFScreenState();
}

class _TranslatePDFScreenState extends State<TranslatePDFScreen> {
  File? _selectedFile;
  String _targetLanguage = 'Spanish';
  bool _isTranslating = false;
  String _translatedText = '';

  final List<String> _languages = [
    'Spanish',
    'French',
    'German',
    'Japanese',
    'Chinese',
    'Hindi',
    'Arabic',
    'Portuguese',
    'Italian',
    'Russian',
  ];

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _translatedText = '';
      });
    }
  }

  Future<void> _translate() async {
    if (_selectedFile == null) return;
    setState(() => _isTranslating = true);

    try {
      final res = await ApiService().translatePDF(
        file: _selectedFile!,
        targetLanguage: _targetLanguage,
      );
      final translated = res['translation'] ?? res['result'] ?? '';
      if (translated.trim().isEmpty) {
        throw Exception('MASKERV server did not return a translation.');
      }

      setState(() {
        _translatedText = translated;
        _isTranslating = false;
      });
    } catch (e) {
      setState(() => _isTranslating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MASKERV Translation Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'AI Translation',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HowItWorksCarousel(
            toolId: 'translate-pdf',
            padding: EdgeInsets.only(bottom: 14),
          ),
          if (_selectedFile == null)
            Center(
              child: OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(LucideIcons.languages, size: 20),
                label: const Text('Choose Document to Translate'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            )
          else ...[
            ListTile(
              leading: const Icon(LucideIcons.fileText, color: AppColors.toolGreen),
              title: Text(_selectedFile!.uri.pathSegments.last, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: TextButton(onPressed: _pickFile, child: const Text('Change')),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _targetLanguage,
              decoration: const InputDecoration(
                labelText: 'Target Language',
                prefixIcon: Icon(LucideIcons.globe, size: 18),
              ),
              items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (val) => setState(() => _targetLanguage = val!),
            ),
            const SizedBox(height: 20),

            ActionButton(
              label: 'Translate to $_targetLanguage',
              icon: LucideIcons.languages,
              isLoading: _isTranslating,
              onPressed: _translate,
            ),
          ],

          if (_translatedText.isNotEmpty) ...[
            const SizedBox(height: 24),
            MarkdownViewer(
              markdown: _translatedText,
              title: 'AI Translation ($_targetLanguage)',
            ),
          ],
        ],
      ),
    );
  }
}
