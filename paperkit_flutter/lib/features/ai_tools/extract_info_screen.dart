import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class ExtractInfoScreen extends StatefulWidget {
  const ExtractInfoScreen({super.key});

  @override
  State<ExtractInfoScreen> createState() => _ExtractInfoScreenState();
}

class _ExtractInfoScreenState extends State<ExtractInfoScreen> {
  File? _selectedFile;
  bool _isExtracting = false;
  Map<String, dynamic>? _extractedFields;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _extractedFields = null;
      });
    }
  }

  Future<void> _extractFields() async {
    if (_selectedFile == null) return;
    setState(() => _isExtracting = true);

    try {
      final res = await ApiService().extractInformation(file: _selectedFile!);
      Map<String, dynamic> data = {};
      if (res['fields'] is Map) {
        data = Map<String, dynamic>.from(res['fields']);
      } else {
        data = Map<String, dynamic>.from(res);
      }

      setState(() {
        _extractedFields = data;
        _isExtracting = false;
      });

      if (data.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No structured key-value entities found in this document.')),
        );
      }
    } catch (e) {
      setState(() => _isExtracting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MASKERV Extraction Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Information Extract',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_selectedFile == null)
            Center(
              child: OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(LucideIcons.fileSearch, size: 20),
                label: const Text('Choose Document / Invoice / CV'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            )
          else ...[
            ListTile(
              leading: const Icon(LucideIcons.fileText, color: AppColors.toolPink),
              title: Text(_selectedFile!.uri.pathSegments.last, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: TextButton(onPressed: _pickFile, child: const Text('Change')),
            ),
            const SizedBox(height: 16),

            ActionButton(
              label: 'Extract Structured Fields',
              icon: LucideIcons.fileSearch,
              isLoading: _isExtracting,
              onPressed: _extractFields,
            ),
          ],

          if (_extractedFields != null) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Extracted Key-Values', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                TextButton.icon(
                  onPressed: () {
                    final text = _extractedFields!.entries.map((e) => '${e.key}: ${e.value}').join('\n');
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied fields to clipboard!')));
                  },
                  icon: const Icon(LucideIcons.copy, size: 16),
                  label: const Text('Copy JSON/Text'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ..._extractedFields!.entries.map(
              (entry) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    Text(entry.value, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
