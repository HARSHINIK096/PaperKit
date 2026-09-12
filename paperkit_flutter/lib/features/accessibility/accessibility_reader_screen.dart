import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/accessibility_models.dart';
import '../../core/services/pdf_engine.dart';
import 'bionic_reading_engine.dart';

class AccessibilityReaderScreen extends StatefulWidget {
  const AccessibilityReaderScreen({super.key});

  @override
  State<AccessibilityReaderScreen> createState() => _AccessibilityReaderScreenState();
}

class _AccessibilityReaderScreenState extends State<AccessibilityReaderScreen> {
  ReadingProfile _activeProfile = ReadingProfile.standard();
  bool _bionicEnabled = true;
  bool _lineFocusEnabled = false;

  String _documentText =
      "PaperKit Accessibility Studio empowers readers with Bionic Reading word prefix emphasis, customizable typography, low-visual fatigue color profiles, and focused reading overlays.";

  File? _selectedFile;

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      String text = '';
      if (file.path.endsWith('.pdf')) {
        text = await PdfEngine.extractTextFromPdf(file);
      } else {
        text = await file.readAsString();
      }

      setState(() {
        _selectedFile = file;
        _documentText = text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Color(_activeProfile.backgroundColorValue);
    final textColor = Color(_activeProfile.textColorValue);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Accessibility Studio', style: TextStyle(color: textColor, fontSize: 18)),
            if (_selectedFile != null)
              Text(_selectedFile!.uri.pathSegments.last, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12)),
          ],
        ),
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.fileUp),
            onPressed: _pickDocument,
          ),
        ],
      ),
      body: Column(
        children: [
          // Control Panel
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade200,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Standard'),
                    selected: _activeProfile.type == ReadingProfileType.standard,
                    onSelected: (_) => setState(() => _activeProfile = ReadingProfile.standard()),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Dyslexia'),
                    selected: _activeProfile.type == ReadingProfileType.dyslexiaFriendly,
                    onSelected: (_) => setState(() => _activeProfile = ReadingProfile.dyslexiaFriendly()),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('High Contrast'),
                    selected: _activeProfile.type == ReadingProfileType.highContrast,
                    onSelected: (_) => setState(() => _activeProfile = ReadingProfile.highContrast()),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Sepia'),
                    selected: _activeProfile.type == ReadingProfileType.sepia,
                    onSelected: (_) => setState(() => _activeProfile = ReadingProfile.sepia()),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Bionic Bold'),
                    selected: _bionicEnabled,
                    onSelected: (val) => setState(() => _bionicEnabled = val),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Line Focus'),
                    selected: _lineFocusEnabled,
                    onSelected: (val) => setState(() => _lineFocusEnabled = val),
                  ),
                ],
              ),
            ),
          ),
          // Reader Display
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _bionicEnabled
                      ? RichText(
                          text: BionicReadingEngine.buildBionicTextSpan(
                            text: _documentText,
                            baseStyle: TextStyle(
                              fontSize: _activeProfile.fontSize,
                              height: _activeProfile.lineHeight,
                              letterSpacing: _activeProfile.letterSpacing,
                              color: textColor,
                            ),
                            boldStyle: TextStyle(
                              fontSize: _activeProfile.fontSize,
                              height: _activeProfile.lineHeight,
                              letterSpacing: _activeProfile.letterSpacing,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        )
                      : Text(
                          _documentText,
                          style: TextStyle(
                            fontSize: _activeProfile.fontSize,
                            height: _activeProfile.lineHeight,
                            letterSpacing: _activeProfile.letterSpacing,
                            color: textColor,
                          ),
                        ),
                ),
                if (_lineFocusEnabled)
                  Positioned(
                    top: 150,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        border: const Border.symmetric(horizontal: BorderSide(color: Colors.amber, width: 2)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
