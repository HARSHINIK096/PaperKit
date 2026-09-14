import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/table_extractor_model.dart';
import '../../core/services/share_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/compact_upload_container.dart';
import 'table_extractor_service.dart';

class TabularExtractorScreen extends StatefulWidget {
  const TabularExtractorScreen({super.key});

  @override
  State<TabularExtractorScreen> createState() => _TabularExtractorScreenState();
}

class _TabularExtractorScreenState extends State<TabularExtractorScreen> {
  final TableExtractorService _service = TableExtractorService();

  File? _selectedFile;
  List<ExtractedTableData> _extractedTables = [];
  bool _isLoading = false;

  Future<void> _processDocument(File file) async {
    setState(() => _isLoading = true);
    final tables = await _service.extractTablesFromPdf(file);
    setState(() {
      _selectedFile = file;
      _extractedTables = tables;
      _isLoading = false;
    });
  }

  Future<void> _exportCsv(ExtractedTableData table) async {
    final csvFile = await _service.exportToCsv(table);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Auto-downloaded & saved: ${csvFile.uri.pathSegments.last}')),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
    ShareService.shareFile(filePath: csvFile.path);
  }

  Future<void> _exportXlsx(ExtractedTableData table) async {
    final xlsxFile = await _service.exportToXlsx(table);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Auto-downloaded & saved: ${xlsxFile.uri.pathSegments.last}')),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
    ShareService.shareFile(filePath: xlsxFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Data Analytics & Table Extractor', style: TextStyle(fontSize: 18)),
            if (_selectedFile != null)
              Text(_selectedFile!.uri.pathSegments.last, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompactUploadContainer(
              files: _selectedFile != null ? [_selectedFile!] : [],
              title: 'Upload Tabular PDF Document',
              subtitle: 'Extract rows, columns and data into CSV or Excel spreadsheet',
              icon: LucideIcons.tableProperties,
              primaryColor: AppColors.toolBlue,
              allowedExtensions: const ['pdf'],
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
                  _extractedTables = [];
                });
              },
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_extractedTables.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _selectedFile != null
                        ? 'No structured tables detected in ${_selectedFile!.uri.pathSegments.last}. Ensure the PDF contains tabular data formatted in columns.'
                        : 'Select a PDF document containing tables or structured data to extract into CSV or Excel XLSX spreadsheets.',
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _extractedTables.length,
                itemBuilder: (context, index) {
                  final table = _extractedTables[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(table.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Spacer(),
                              OutlinedButton.icon(
                                onPressed: () => _exportCsv(table),
                                icon: const Icon(LucideIcons.fileText),
                                label: const Text('CSV'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _exportXlsx(table),
                                icon: const Icon(LucideIcons.fileSpreadsheet),
                                label: const Text('XLSX'),
                              ),
                            ],
                          ),
                          const Divider(),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: table.headers.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                              rows: table.rows
                                  .map((r) => DataRow(cells: r.map((c) => DataCell(Text(c))).toList()))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
