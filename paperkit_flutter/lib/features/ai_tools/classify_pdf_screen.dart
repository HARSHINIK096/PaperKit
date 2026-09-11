import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class ClassifyPDFScreen extends StatefulWidget {
  const ClassifyPDFScreen({super.key});

  @override
  State<ClassifyPDFScreen> createState() => _ClassifyPDFScreenState();
}

class _ClassifyPDFScreenState extends State<ClassifyPDFScreen> {
  File? _selectedFile;
  bool _isClassifying = false;
  Map<String, dynamic>? _classification;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _classification = null;
      });
    }
  }

  Future<void> _classify() async {
    if (_selectedFile == null) return;
    setState(() => _isClassifying = true);

    try {
      final data = await ApiService().classifyDocument(file: _selectedFile!);

      setState(() {
        _classification = data;
        _isClassifying = false;
      });
    } catch (e) {
      setState(() => _isClassifying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MASKERV Classification Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Document Classification',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_selectedFile == null)
            Center(
              child: OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(LucideIcons.tag, size: 20),
                label: const Text('Choose Document to Classify'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            )
          else ...[
            ListTile(
              leading: const Icon(LucideIcons.fileText, color: AppColors.toolOrange),
              title: Text(_selectedFile!.uri.pathSegments.last, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: TextButton(onPressed: _pickFile, child: const Text('Change')),
            ),
            const SizedBox(height: 16),

            ActionButton(
              label: 'Run AI Classification',
              icon: LucideIcons.sparkles,
              isLoading: _isClassifying,
              onPressed: _classify,
            ),
          ],

          if (_classification != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _classification!['category'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          '${_classification!['confidence']}% Match',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Language: ${_classification!['language']}', style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Reading Level: ${_classification!['reading_level']}', style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 14),
                  const Text('Detected Tags:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (_classification!['tags'] as List).map((tag) {
                      return Chip(
                        label: Text(tag.toString(), style: const TextStyle(fontSize: 12)),
                        backgroundColor: AppColors.primarySoft,
                      );
                    }).toList(),
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
