import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class SemanticSearchScreen extends StatefulWidget {
  const SemanticSearchScreen({super.key});

  @override
  State<SemanticSearchScreen> createState() => _SemanticSearchScreenState();
}

class _SemanticSearchScreenState extends State<SemanticSearchScreen> {
  File? _selectedFile;
  final TextEditingController _queryController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _searchResults.clear();
      });
    }
  }

  Future<void> _search() async {
    final q = _queryController.text.trim();
    if (_selectedFile == null || q.isEmpty) return;
    setState(() => _isSearching = true);

    try {
      final res = await ApiService().semanticSearch(file: _selectedFile!, query: q);
      List<Map<String, dynamic>> results = [];
      if (res['results'] is List) {
        results = List<Map<String, dynamic>>.from(res['results']);
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });

      if (results.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No semantic matches found for "$q".')),
        );
      }
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MASKERV Search Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Semantic Search',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_selectedFile == null)
            Center(
              child: OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(LucideIcons.fileText, size: 20),
                label: const Text('Choose Document for AI Search'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            )
          else ...[
            ListTile(
              leading: const Icon(LucideIcons.fileText, color: AppColors.toolTeal),
              title: Text(_selectedFile!.uri.pathSegments.last, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: TextButton(onPressed: _pickFile, child: const Text('Change')),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _queryController,
              decoration: const InputDecoration(
                labelText: 'Search by concept or question',
                hintText: 'e.g. security policies, payment deadlines',
                prefixIcon: Icon(LucideIcons.search, size: 18),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),

            ActionButton(
              label: 'Search Document Concept',
              icon: LucideIcons.search,
              isLoading: _isSearching,
              onPressed: _search,
            ),
          ],

          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Semantic Matches (${_searchResults.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            const SizedBox(height: 12),
            ..._searchResults.map(
              (res) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.toolTeal.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text('Page ${res['page']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.toolTeal)),
                        ),
                        Text('${res['score']}% Relevance', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(res['snippet'], style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
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
