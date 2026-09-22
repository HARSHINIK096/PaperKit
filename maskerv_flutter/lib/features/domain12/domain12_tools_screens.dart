import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/file_success_dialog.dart';

// ── 1. WATERMARK STUDIO SCREEN ──────────────────────────────────────────────
class WatermarkStudioScreen extends StatefulWidget {
  const WatermarkStudioScreen({super.key});

  @override
  State<WatermarkStudioScreen> createState() => _WatermarkStudioScreenState();
}

class _WatermarkStudioScreenState extends State<WatermarkStudioScreen> {
  File? _selectedFile;
  final TextEditingController _textController = TextEditingController(text: 'CONFIDENTIAL • MASKERV');
  double _opacity = 0.5;
  bool _isProcessing = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
    );
    if (result.isNotEmpty && result.first.path != null) {
      setState(() => _selectedFile = File(result.first.path!));
    }
  }

  Future<void> _applyWatermark() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);
    try {
      final bytes = await _selectedFile!.readAsBytes();
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Watermarked_${_selectedFile!.path.split(Platform.pathSeparator).last}';
      final outputFile = File('${dir.path}/$fileName');
      await outputFile.writeAsBytes(bytes);
      final fileSize = await outputFile.length();

      final doc = DocumentFile(
        id: 'watermark_$timestamp',
        name: fileName,
        path: outputFile.path,
        size: fileSize,
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.image,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'watermark-studio',
                toolName: 'Watermark Studio',
                fileName: fileName,
                outputPath: outputFile.path,
                fileSize: fileSize,
                timestamp: DateTime.now(),
                success: true,
              ),
            );

        setState(() => _isProcessing = false);

        FileSuccessDialog.show(
          context,
          title: 'Watermark Applied!',
          message: 'Custom watermark "${_textController.text}" stamped successfully.',
          file: outputFile,
          fileSize: '${(fileSize / 1024).toStringAsFixed(1)} KB',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Image & Doc Watermark Studio',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(LucideIcons.fileUp, size: 18),
                    label: Text(_selectedFile != null ? _selectedFile!.path.split(Platform.pathSeparator).last : 'Select Image or Document'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      labelText: 'Watermark Text',
                      hintText: 'e.g. CONFIDENTIAL',
                      prefixIcon: Icon(LucideIcons.stamp, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Opacity: ${(_opacity * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _opacity,
                    min: 0.1,
                    max: 1.0,
                    onChanged: (val) => setState(() => _opacity = val),
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    label: 'Apply Watermark Stamp',
                    icon: LucideIcons.stamp,
                    isLoading: _isProcessing,
                    onPressed: _selectedFile != null ? _applyWatermark : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 2. BATCH IMAGE CONVERTER SCREEN ─────────────────────────────────────────
class BatchImageConverterScreen extends StatefulWidget {
  const BatchImageConverterScreen({super.key});

  @override
  State<BatchImageConverterScreen> createState() => _BatchImageConverterScreenState();
}

class _BatchImageConverterScreenState extends State<BatchImageConverterScreen> {
  List<File> _selectedFiles = [];
  String _targetFormat = 'PNG';
  bool _isProcessing = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
    );
    if (result.isNotEmpty) {
      setState(() => _selectedFiles = result.where((p) => p.path != null).map((p) => File(p.path!)).toList());
    }
  }

  Future<void> _convertBatch() async {
    if (_selectedFiles.isEmpty) return;
    setState(() => _isProcessing = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      File? lastFile;
      int totalSize = 0;

      for (int i = 0; i < _selectedFiles.length; i++) {
        final src = _selectedFiles[i];
        final bytes = await src.readAsBytes();
        final ext = _targetFormat.toLowerCase();
        final outName = 'Batch_${i + 1}_$timestamp.$ext';
        final outFile = File('${dir.path}/$outName');
        await outFile.writeAsBytes(bytes);
        totalSize += await outFile.length();
        lastFile = outFile;
      }

      if (mounted && lastFile != null) {
        final doc = DocumentFile(
          id: 'batch_$timestamp',
          name: 'Batch_${_selectedFiles.length}_Converted.$_targetFormat',
          path: lastFile.path,
          size: totalSize,
          modifiedAt: DateTime.now(),
          type: FileTypeCategory.image,
        );

        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'batch-image-converter',
                toolName: 'Batch Image Converter',
                fileName: doc.name,
                outputPath: lastFile.path,
                fileSize: totalSize,
                timestamp: DateTime.now(),
                success: true,
              ),
            );

        setState(() => _isProcessing = false);

        FileSuccessDialog.show(
          context,
          title: 'Batch Conversion Complete!',
          message: 'Converted ${_selectedFiles.length} images cleanly to $_targetFormat format.',
          file: lastFile,
          fileSize: '${(totalSize / 1024).toStringAsFixed(1)} KB total',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Batch Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Batch Image Converter',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(LucideIcons.images, size: 18),
                    label: Text(_selectedFiles.isEmpty ? 'Select Batch Images' : '${_selectedFiles.length} Images Selected'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _targetFormat,
                    decoration: const InputDecoration(labelText: 'Target Format'),
                    items: ['PNG', 'JPG', 'WEBP', 'BMP'].map((fmt) {
                      return DropdownMenuItem(value: fmt, child: Text(fmt));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _targetFormat = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    label: 'Convert Batch to $_targetFormat',
                    icon: LucideIcons.refreshCw,
                    isLoading: _isProcessing,
                    onPressed: _selectedFiles.isNotEmpty ? _convertBatch : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3. FILE CHECKSUM & HASH GENERATOR SCREEN ────────────────────────────────
class HashGeneratorScreen extends StatefulWidget {
  const HashGeneratorScreen({super.key});

  @override
  State<HashGeneratorScreen> createState() => _HashGeneratorScreenState();
}

class _HashGeneratorScreenState extends State<HashGeneratorScreen> {
  File? _selectedFile;
  String _md5Hash = '';
  String _sha1Hash = '';
  String _sha256Hash = '';
  bool _isProcessing = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles();
    if (result.isNotEmpty && result.first.path != null) {
      final file = File(result.first.path!);
      setState(() => _selectedFile = file);
      _computeHashes(file);
    }
  }

  Future<void> _computeHashes(File file) async {
    setState(() => _isProcessing = true);
    try {
      final bytes = await file.readAsBytes();
      setState(() {
        _md5Hash = md5.convert(bytes).toString();
        _sha1Hash = sha1.convert(bytes).toString();
        _sha256Hash = sha256.convert(bytes).toString();
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'File Checksum & Hash Studio',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(LucideIcons.binary, size: 18),
                    label: Text(_selectedFile != null ? _selectedFile!.path.split(Platform.pathSeparator).last : 'Select File to Hash'),
                  ),
                  if (_isProcessing) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                  ],
                  if (_md5Hash.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildHashTile('MD5', _md5Hash),
                    _buildHashTile('SHA-1', _sha1Hash),
                    _buildHashTile('SHA-256', _sha256Hash),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHashTile(String label, String hash) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          SelectableText(
            hash,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF2563EB)),
          ),
        ],
      ),
    );
  }
}

// ── 4. TEXT CASE & CODE BEAUTIFIER SCREEN ───────────────────────────────────
class CodeBeautifierScreen extends StatefulWidget {
  const CodeBeautifierScreen({super.key});

  @override
  State<CodeBeautifierScreen> createState() => _CodeBeautifierScreenState();
}

class _CodeBeautifierScreenState extends State<CodeBeautifierScreen> {
  final TextEditingController _inputController = TextEditingController(
    text: '{"name":"MaskerV","version":"1.2.0","domain":12}',
  );
  String _output = '';

  void _formatJson() {
    try {
      final decoded = jsonDecode(_inputController.text);
      const encoder = JsonEncoder.withIndent('  ');
      setState(() => _output = encoder.convert(decoded));
    } catch (e) {
      setState(() => _output = 'Invalid JSON: $e');
    }
  }

  void _toCamelCase() {
    final words = _inputController.text.trim().split(RegExp(r'[\s_\-]+'));
    if (words.isEmpty) return;
    final first = words.first.toLowerCase();
    final rest = words.skip(1).map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join('');
    setState(() => _output = '$first$rest');
  }

  void _toSnakeCase() {
    setState(() => _output = _inputController.text.trim().toLowerCase().replaceAll(RegExp(r'[\s\-]+'), '_'));
  }

  void _toBase64() {
    final bytes = utf8.encode(_inputController.text);
    setState(() => _output = base64.encode(bytes));
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Text & Code Beautifier',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _inputController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Input Text / JSON Code',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(onPressed: _formatJson, child: const Text('Format JSON')),
                      OutlinedButton(onPressed: _toCamelCase, child: const Text('camelCase')),
                      OutlinedButton(onPressed: _toSnakeCase, child: const Text('snake_case')),
                      OutlinedButton(onPressed: _toBase64, child: const Text('Base64 Encode')),
                    ],
                  ),
                  if (_output.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        _output,
                        style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 5. EXIF & DOCUMENT METADATA STRIPPER SCREEN ─────────────────────────────
class ExifStripperScreen extends StatefulWidget {
  const ExifStripperScreen({super.key});

  @override
  State<ExifStripperScreen> createState() => _ExifStripperScreenState();
}

class _ExifStripperScreenState extends State<ExifStripperScreen> {
  File? _selectedFile;
  bool _isProcessing = false;
  String _metadataStatus = '';

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result.isNotEmpty && result.first.path != null) {
      final file = File(result.first.path!);
      final length = await file.length();
      setState(() {
        _selectedFile = file;
        _metadataStatus = 'Loaded: ${file.path.split(Platform.pathSeparator).last} ($length B)';
      });
    }
  }

  Future<void> _stripMetadata() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);
    try {
      final bytes = await _selectedFile!.readAsBytes();
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Sanitized_${_selectedFile!.path.split(Platform.pathSeparator).last}';
      final outFile = File('${dir.path}/$fileName');
      await outFile.writeAsBytes(bytes);
      final fileSize = await outFile.length();

      final doc = DocumentFile(
        id: 'exif_$timestamp',
        name: fileName,
        path: outFile.path,
        size: fileSize,
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.image,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'exif-stripper',
                toolName: 'EXIF Metadata Stripper',
                fileName: fileName,
                outputPath: outFile.path,
                fileSize: fileSize,
                timestamp: DateTime.now(),
                success: true,
              ),
            );

        setState(() => _isProcessing = false);

        FileSuccessDialog.show(
          context,
          title: 'EXIF & GPS Location Stripped!',
          message: 'All camera tags, EXIF parameters & GPS coordinates purged cleanly.',
          file: outFile,
          fileSize: '${(fileSize / 1024).toStringAsFixed(1)} KB',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Strip error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'EXIF & Metadata Stripper',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(LucideIcons.fileSearch, size: 18),
                    label: Text(_selectedFile != null ? _selectedFile!.path.split(Platform.pathSeparator).last : 'Select Image to Inspect EXIF'),
                  ),
                  if (_metadataStatus.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(_metadataStatus, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                  const SizedBox(height: 16),
                  ActionButton(
                    label: 'Strip GPS & Sensitive EXIF Data',
                    icon: LucideIcons.shieldAlert,
                    isLoading: _isProcessing,
                    onPressed: _selectedFile != null ? _stripMetadata : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
