import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class ExtractTablesScreen extends StatefulWidget {
  const ExtractTablesScreen({super.key});

  @override
  State<ExtractTablesScreen> createState() => _ExtractTablesScreenState();
}

class _ExtractTablesScreenState extends State<ExtractTablesScreen> {
  File? _selectedFile;
  bool _isExtracting = false;
  List<List<String>>? _tableData;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _tableData = null;
      });
    }
  }

  Future<void> _extractTable() async {
    if (_selectedFile == null) return;
    setState(() => _isExtracting = true);

    try {
      final res = await ApiService().extractTables(file: _selectedFile!);
      final rawTables = res['tables'] ?? res['result'] ?? '';
      List<List<String>> tables = [];

      if (rawTables.isNotEmpty && rawTables.contains('|')) {
        final lines = rawTables.split('\n');
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('|') && !trimmed.contains('---')) {
            final cells = trimmed.split('|').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
            if (cells.isNotEmpty) tables.add(cells);
          }
        }
      }

      setState(() {
        _tableData = tables;
        _isExtracting = false;
      });

      if (tables.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tabular data detected in this document.')),
        );
      }
    } catch (e) {
      setState(() => _isExtracting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PaperKit Table Extraction Error: $e')),
        );
      }
    }
  }

  void _copyCSV() {
    if (_tableData == null) return;
    final csv = _tableData!.map((row) => row.join(',')).join('\n');
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Table copied as CSV!')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Extract Tables',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_selectedFile == null)
            Center(
              child: OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(LucideIcons.table, size: 20),
                label: const Text('Choose Document to Extract Tables'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            )
          else ...[
            ListTile(
              leading: const Icon(LucideIcons.fileSpreadsheet, color: AppColors.toolOrange),
              title: Text(_selectedFile!.uri.pathSegments.last, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: TextButton(onPressed: _pickFile, child: const Text('Change')),
            ),
            const SizedBox(height: 16),

            ActionButton(
              label: 'Detect & Extract Tables with AI',
              icon: LucideIcons.table,
              isLoading: _isExtracting,
              onPressed: _extractTable,
            ),
          ],

          if (_tableData != null) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Detected Table Structure', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                TextButton.icon(
                  onPressed: _copyCSV,
                  icon: const Icon(LucideIcons.copy, size: 16),
                  label: const Text('Copy CSV'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: _tableData!.first.map((header) => DataColumn(label: Text(header, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                rows: _tableData!.sublist(1).map((row) {
                  return DataRow(cells: row.map((c) => DataCell(Text(c))).toList());
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
