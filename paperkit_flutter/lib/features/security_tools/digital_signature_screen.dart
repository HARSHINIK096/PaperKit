import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/pdf_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class DigitalSignatureScreen extends StatefulWidget {
  const DigitalSignatureScreen({super.key});

  @override
  State<DigitalSignatureScreen> createState() => _DigitalSignatureScreenState();
}

class _DigitalSignatureScreenState extends State<DigitalSignatureScreen> {
  File? _selectedFile;
  final TextEditingController _signerNameController = TextEditingController(text: 'John Doe');
  final TextEditingController _reasonController = TextEditingController(text: 'Approved & Signed');
  bool _isProcessing = false;
  File? _signedResult;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _signedResult = null;
      });
    }
  }

  Future<void> _signPdf() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      final signer = _signerNameController.text.trim();
      final reason = _reasonController.text.trim();
      final stampText = 'Digitally Signed by $signer\nDate: ${DateTime.now().toIso8601String().substring(0, 10)}\nReason: $reason';

      final outputFile = await PdfEngine.addWatermark(
        inputFile: _selectedFile!,
        watermarkText: stampText,
        opacity: 0.5,
        fontSize: 20,
        angle: 0,
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = outputFile.uri.pathSegments.last;

      final doc = DocumentFile(
        id: 'sign_$timestamp',
        name: fileName,
        path: outputFile.path,
        size: await outputFile.length(),
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.pdf,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'digital-sign',
                toolName: 'Digital Signature',
                fileName: fileName,
                outputPath: outputFile.path,
                fileSize: await outputFile.length(),
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _signedResult = outputFile;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Digital Signature stamped successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signing failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Digital Signature',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                          color: AppColors.toolIndigo.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.fileSignature, color: AppColors.toolIndigo, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _selectedFile!.uri.pathSegments.last,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
            TextField(
              controller: _signerNameController,
              decoration: const InputDecoration(
                labelText: 'Signer Full Name',
                prefixIcon: Icon(LucideIcons.user, size: 18),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Signing Reason / Purpose',
                prefixIcon: Icon(LucideIcons.fileText, size: 18),
              ),
            ),
            const SizedBox(height: 24),

            ActionButton(
              label: 'Apply Digital Signature',
              icon: LucideIcons.fileSignature,
              isLoading: _isProcessing,
              onPressed: _signPdf,
            ),
          ],

          if (_signedResult != null) ...[
            const SizedBox(height: 20),
            ActionButton(
              label: 'Open Signed PDF',
              icon: LucideIcons.externalLink,
              isSecondary: true,
              onPressed: () => OpenFilex.open(_signedResult!.path),
            ),
          ],
        ],
      ),
    );
  }
}
