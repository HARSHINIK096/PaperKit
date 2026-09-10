import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class CompressPDFScreen extends StatefulWidget {
  const CompressPDFScreen({super.key});

  @override
  State<CompressPDFScreen> createState() => _CompressPDFScreenState();
}

class _CompressPDFScreenState extends State<CompressPDFScreen> {
  File? _selectedFile;
  int _originalSize = 0;
  String _compressionLevel = 'recommended'; // 'extreme', 'recommended', 'less'
  bool _isProcessing = false;
  File? _compressedFile;
  int _compressedSize = 0;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final len = await file.length();
      setState(() {
        _selectedFile = file;
        _originalSize = len;
        _compressedFile = null;
      });
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _compressPdf() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      final bytes = await _selectedFile!.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      // Apply Syncfusion compression options
      document.compressionLevel = _compressionLevel == 'extreme'
          ? PdfCompressionLevel.best
          : (_compressionLevel == 'recommended' ? PdfCompressionLevel.normal : PdfCompressionLevel.belowNormal);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outName = 'Compressed_${_selectedFile!.uri.pathSegments.last}';
      final outPath = '${_selectedFile!.parent.path}/$outName';
      final outFile = File(outPath);
      await outFile.writeAsBytes(document.saveSync());
      document.dispose();

      final newSize = await outFile.length();

      final doc = DocumentFile(
        id: 'comp_$timestamp',
        name: outName,
        path: outFile.path,
        size: newSize,
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.pdf,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'compress-pdf',
                toolName: 'Compress PDF',
                fileName: outName,
                outputPath: outFile.path,
                fileSize: newSize,
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _compressedFile = outFile;
          _compressedSize = newSize;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF compressed successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Compression failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Compress PDF',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Select File Tile
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              children: [
                if (_selectedFile == null)
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(LucideIcons.filePlus, size: 20),
                      label: const Text('Choose PDF Document'),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.toolOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.minimize2, color: AppColors.toolOrange, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile!.uri.pathSegments.last,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Original Size: ${_formatSize(_originalSize)}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(onPressed: _pickFile, child: const Text('Change')),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_selectedFile != null) ...[
            Text(
              'Compression Preset',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),

            _buildPresetOption(
              level: 'extreme',
              title: 'Extreme Compression',
              desc: 'Smallest file size, maximum optimization',
              icon: LucideIcons.zap,
              isDark: isDark,
            ),
            _buildPresetOption(
              level: 'recommended',
              title: 'Recommended Compression',
              desc: 'Great balance of quality and size reduction',
              icon: LucideIcons.checkCircle,
              isDark: isDark,
            ),
            _buildPresetOption(
              level: 'less',
              title: 'Less Compression',
              desc: 'Highest visual quality with minor reduction',
              icon: LucideIcons.shieldCheck,
              isDark: isDark,
            ),

            const SizedBox(height: 24),
            ActionButton(
              label: 'Compress PDF',
              icon: LucideIcons.minimize2,
              isLoading: _isProcessing,
              onPressed: _compressPdf,
            ),
          ],

          if (_compressedFile != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Original:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(_formatSize(_originalSize), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Compressed:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        _formatSize(_compressedSize),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ActionButton(
                    label: 'Open Compressed PDF',
                    icon: LucideIcons.externalLink,
                    onPressed: () => OpenFilex.open(_compressedFile!.path),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetOption({
    required String level,
    required String title,
    required String desc,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _compressionLevel == level;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: level,
        groupValue: _compressionLevel,
        onChanged: (val) => setState(() => _compressionLevel = val!),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
        secondary: Icon(icon, color: isSelected ? AppColors.primary : (isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight)),
      ),
    );
  }
}
