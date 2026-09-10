import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/pdf_engine.dart';
import '../../core/widgets/tool_flow_scaffold.dart';

class ProtectPDFScreen extends StatefulWidget {
  const ProtectPDFScreen({super.key});

  @override
  State<ProtectPDFScreen> createState() => _ProtectPDFScreenState();
}

class _ProtectPDFScreenState extends State<ProtectPDFScreen> {
  File? _selectedFile;
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    HapticFeedback.lightImpact();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<File?> _executeProtect() async {
    final pass = _passController.text;
    if (_selectedFile == null || pass.isEmpty) {
      throw Exception('Please enter a valid password.');
    }
    if (pass != _confirmController.text) {
      throw Exception('Passwords do not match. Please re-enter matching passwords.');
    }

    final outputFile = await PdfEngine.protectPdf(
      inputFile: _selectedFile!,
      userPassword: pass,
    );

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = outputFile.uri.pathSegments.last;
    final fileSize = await outputFile.length();

    final doc = DocumentFile(
      id: 'prot_$timestamp',
      name: fileName,
      path: outputFile.path,
      size: fileSize,
      modifiedAt: DateTime.now(),
      type: FileTypeCategory.pdf,
    );

    if (mounted) {
      await context.read<FilesProvider>().addFile(doc);
      await context.read<HistoryProvider>().addRecord(
            HistoryItem(
              id: 'hist_$timestamp',
              toolId: 'protect-pdf',
              toolName: 'Protect PDF',
              fileName: fileName,
              outputPath: outputFile.path,
              fileSize: fileSize,
              timestamp: DateTime.now(),
            ),
          );
    }

    return outputFile;
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFDC2626); // Crimson Red

    return ToolFlowScaffold(
      title: 'Protect PDF',
      toolId: 'protect-pdf',
      primaryColor: primaryColor,
      toolIcon: LucideIcons.lock,
      processingMessage: 'Encrypting PDF with 256-bit AES vault cipher...',
      canProceedToEdition: _selectedFile != null,
      onProcess: _executeProtect,
      onReset: () {
        setState(() {
          _selectedFile = null;
          _passController.clear();
          _confirmController.clear();
        });
      },

      // ── Step 1: Upload Widget ──
      uploadWidget: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.lock, size: 36, color: primaryColor),
            ),
            const SizedBox(height: 14),
            const Text(
              'Select PDF to Encrypt',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enforce 256-bit AES password encryption on your document.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(LucideIcons.filePlus, size: 18),
              label: Text(
                _selectedFile == null ? 'Choose PDF File' : 'Change Selected PDF',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            if (_selectedFile != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.fileCheck, color: primaryColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedFile!.uri.pathSegments.last,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),

      // ── Step 2: Edition Widget ──
      editionWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configure Security Password',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose a strong password to lock and encrypt this document.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _passController,
            obscureText: _obscureText,
            decoration: InputDecoration(
              labelText: 'User Password',
              hintText: 'Enter encryption password',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(LucideIcons.keyRound, size: 18),
              suffixIcon: IconButton(
                icon: Icon(_obscureText ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _confirmController,
            obscureText: _obscureText,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Re-enter encryption password',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(LucideIcons.check, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
