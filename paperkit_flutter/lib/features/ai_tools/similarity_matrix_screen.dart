import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../../core/services/pdf_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class SimilarityMatrixScreen extends StatefulWidget {
  const SimilarityMatrixScreen({super.key});

  @override
  State<SimilarityMatrixScreen> createState() => _SimilarityMatrixScreenState();
}

class _SimilarityMatrixScreenState extends State<SimilarityMatrixScreen> {
  final List<File> _files = [];
  bool _isProcessing = false;
  List<List<double>>? _matrix;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        for (final p in result.paths) {
          if (p != null) _files.add(File(p));
        }
        _matrix = null;
      });
    }
  }

  Future<void> _calculateMatrix() async {
    if (_files.length < 2) return;
    setState(() => _isProcessing = true);

    try {
      final List<Map<String, String>> docsPayload = [];
      for (int i = 0; i < _files.length; i++) {
        final f = _files[i];
        String txt = '';
        if (f.path.toLowerCase().endsWith('.pdf')) {
          try {
            txt = await PdfEngine.extractText(f);
          } catch (_) {}
        } else {
          try {
            txt = await f.readAsString();
          } catch (_) {}
        }
        docsPayload.add({
          'id': 'doc_$i',
          'name': f.uri.pathSegments.last,
          'text': txt.isNotEmpty ? txt : 'Document content for ${f.uri.pathSegments.last}',
        });
      }

      final res = await ApiService().similarityMatrix(documents: docsPayload);
      final n = _files.length;
      final List<List<double>> mat = List.generate(n, (i) => List.generate(n, (j) => 0.0));

      for (int i = 0; i < n; i++) {
        mat[i][i] = 1.0;
      }

      if (res['matrix'] is List) {
        for (final item in res['matrix']) {
          final docA = item['doc_a_id']?.toString() ?? '';
          final docB = item['doc_b_id']?.toString() ?? '';
          final score = (item['similarity_score'] as num?)?.toDouble() ?? 50.0;
          final normalizedScore = score > 1.0 ? score / 100.0 : score;

          final idxA = int.tryParse(docA.replaceAll('doc_', ''));
          final idxB = int.tryParse(docB.replaceAll('doc_', ''));
          if (idxA != null && idxB != null && idxA < n && idxB < n) {
            mat[idxA][idxB] = normalizedScore;
            mat[idxB][idxA] = normalizedScore;
          }
        }
      }

      setState(() {
        _matrix = mat;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PaperKit Similarity Matrix Error: $e')),
        );
      }
    }
  }

  Color _getHeatmapColor(double score) {
    if (score >= 0.9) return AppColors.primary;
    if (score >= 0.75) return AppColors.toolTeal;
    if (score >= 0.6) return AppColors.toolOrange;
    return AppColors.toolRed.withOpacity(0.7);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Similarity Score Matrix',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Corpus Files (${_files.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              OutlinedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add Docs'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_files.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: const Center(child: Text('Add 2 or more files to calculate cross-document similarity')),
            )
          else
            ..._files.map((f) => ListTile(
                  dense: true,
                  leading: const Icon(LucideIcons.fileText, color: AppColors.toolIndigo, size: 20),
                  title: Text(f.uri.pathSegments.last, style: const TextStyle(fontSize: 13)),
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                    onPressed: () => setState(() => _files.remove(f)),
                  ),
                )),
          const SizedBox(height: 20),

          ActionButton(
            label: 'Compute Similarity Matrix',
            icon: LucideIcons.layoutGrid,
            isLoading: _isProcessing,
            onPressed: _files.length >= 2 ? _calculateMatrix : null,
          ),

          if (_matrix != null) ...[
            const SizedBox(height: 24),
            Text('Cosine Similarity Heatmap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Doc', style: TextStyle(fontWeight: FontWeight.bold))),
                  ..._files.map((f) => DataColumn(
                        label: Text(
                          f.uri.pathSegments.last.substring(0, (f.uri.pathSegments.last.length > 8 ? 8 : f.uri.pathSegments.last.length)),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      )),
                ],
                rows: List.generate(_files.length, (rowIdx) {
                  return DataRow(
                    cells: [
                      DataCell(Text('D${rowIdx + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      ...List.generate(_files.length, (colIdx) {
                        final val = _matrix![rowIdx][colIdx];
                        return DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getHeatmapColor(val).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${(val * 100).toInt()}%',
                              style: TextStyle(fontWeight: FontWeight.bold, color: _getHeatmapColor(val), fontSize: 12),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
