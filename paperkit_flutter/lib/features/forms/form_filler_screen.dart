import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/form_field_model.dart';
import '../../core/services/share_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/compact_upload_container.dart';
import 'form_engine_service.dart';

class FormFillerScreen extends StatefulWidget {
  const FormFillerScreen({super.key});

  @override
  State<FormFillerScreen> createState() => _FormFillerScreenState();
}

class _FormFillerScreenState extends State<FormFillerScreen> {
  final FormEngineService _service = FormEngineService();

  File? _selectedFile;
  List<CustomFormField> _fields = [];
  List<UserFormProfile> _profiles = [];
  UserFormProfile? _selectedProfile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final loaded = await _service.loadProfiles();
    setState(() {
      _profiles = loaded;
      if (loaded.isNotEmpty) _selectedProfile = loaded.first;
    });
  }

  Future<void> _processDocument(File file) async {
    setState(() => _isLoading = true);
    final detected = await _service.detectFormFields(file);
    setState(() {
      _selectedFile = file;
      _fields = detected;
      _isLoading = false;
    });
  }

  void _applyAutoFill() {
    if (_selectedProfile != null && _fields.isNotEmpty) {
      setState(() {
        _fields = _service.autoFillFields(_fields, _selectedProfile!);
      });
    }
  }

  Future<void> _flattenAndExport() async {
    if (_selectedFile == null) return;
    setState(() => _isLoading = true);

    final flattenedFile = await _service.flattenPdfForm(_selectedFile!, _fields);
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Form auto-downloaded & saved: ${flattenedFile.uri.pathSegments.last}'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }

    ShareService.shareFile(filePath: flattenedFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Forms & Auto-Fill'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.save),
            onPressed: _selectedFile == null ? null : _flattenAndExport,
            tooltip: 'Export & Auto-Download Form',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompactUploadContainer(
              files: _selectedFile != null ? [_selectedFile!] : [],
              title: 'Upload Fillable PDF Form',
              subtitle: 'Auto-detects text fields, checkboxes and signature areas',
              icon: LucideIcons.fileSignature,
              primaryColor: AppColors.toolPurple,
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
                  _fields = [];
                });
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _fields.isEmpty ? null : _applyAutoFill,
                  icon: const Icon(LucideIcons.sparkles),
                  label: const Text('Auto-Fill'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.toolPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            if (_profiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Active Profile: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  DropdownButton<UserFormProfile>(
                    value: _selectedProfile,
                    items: _profiles.map((p) => DropdownMenuItem(value: p, child: Text(p.profileName))).toList(),
                    onChanged: (val) => setState(() => _selectedProfile = val),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_selectedFile == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Load a PDF document to detect existing form fields, apply profile auto-fill, and flatten into an un-editable PDF.'),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Detected Form Fields (${_fields.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _fields.length,
                    itemBuilder: (context, index) {
                      final field = _fields[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: TextFormField(
                            initialValue: field.value,
                            decoration: InputDecoration(
                              labelText: field.label,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (val) => field.value = val,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
