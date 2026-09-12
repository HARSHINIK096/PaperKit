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
import '../../core/services/archive_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/how_it_works_carousel.dart';

class ArchiveStudioScreen extends StatefulWidget {
  final String? initialMode; // 'create' or 'extract'

  const ArchiveStudioScreen({super.key, this.initialMode});

  @override
  State<ArchiveStudioScreen> createState() => _ArchiveStudioScreenState();
}

class _ArchiveStudioScreenState extends State<ArchiveStudioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Create Archive state
  final List<File> _filesToZip = [];
  final TextEditingController _zipNameController = TextEditingController(text: 'Archive');
  final TextEditingController _createPasswordController = TextEditingController();
  String _selectedFormat = 'zip';
  bool _isZipping = false;
  File? _createdZip;

  // Extract Archive state
  File? _archiveToExtract;
  final TextEditingController _extractPasswordController = TextEditingController();
  bool _isExtracting = false;
  List<File> _extractedFiles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialMode == 'extract' ? 1 : 0,
    );
  }

  Future<void> _pickFilesToZip() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        for (final p in result.paths) {
          if (p != null) _filesToZip.add(File(p));
        }
      });
    }
  }

  Future<void> _createZip() async {
    if (_filesToZip.isEmpty) return;
    setState(() => _isZipping = true);

    try {
      final name = _zipNameController.text.trim().isEmpty ? 'Archive' : _zipNameController.text.trim();
      final password = _createPasswordController.text.trim().isEmpty ? null : _createPasswordController.text.trim();
      
      final outputFile = await ArchiveEngine.createArchive(
        files: _filesToZip,
        archiveName: '${name}_${DateTime.now().millisecondsSinceEpoch}',
        format: _selectedFormat,
        password: password,
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = outputFile.uri.pathSegments.last;

      final doc = DocumentFile(
        id: 'archive_$timestamp',
        name: fileName,
        path: outputFile.path,
        size: await outputFile.length(),
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.archive,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: 'archive-studio',
                toolName: 'Create Archive (${_selectedFormat.toUpperCase()})',
                fileName: fileName,
                outputPath: outputFile.path,
                fileSize: await outputFile.length(),
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _createdZip = outputFile;
          _isZipping = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created ${_selectedFormat.toUpperCase()} archive with ${_filesToZip.length} files!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isZipping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archive creation failed: $e')),
        );
      }
    }
  }

  Future<void> _pickArchiveToExtract() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'tar', 'gz', 'rar', '7z', 'bz2', 'tgz', 'tbz', 'xz', 'zst'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _archiveToExtract = File(result.files.single.path!);
        _extractedFiles.clear();
      });
    }
  }

  Future<void> _extractArchive() async {
    if (_archiveToExtract == null) return;
    setState(() => _isExtracting = true);

    try {
      final password = _extractPasswordController.text.trim().isEmpty ? null : _extractPasswordController.text.trim();
      final files = await ArchiveEngine.extractArchive(_archiveToExtract!, password: password);
      final filesProv = context.read<FilesProvider>();

      for (final f in files) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final name = f.uri.pathSegments.last;
        final ext = name.contains('.') ? name.split('.').last : '';
        await filesProv.addFile(
          DocumentFile(
            id: 'unzip_$timestamp',
            name: name,
            path: f.path,
            size: await f.length(),
            modifiedAt: DateTime.now(),
            type: DocumentFile.getTypeFromExtension(ext),
          ),
        );
      }

      setState(() {
        _extractedFiles = files;
        _isExtracting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extracted ${files.length} files successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExtracting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extraction failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Archive Studio',
      showBottomNav: false,
      child: Column(
        children: [
          const HowItWorksCarousel(
            toolId: 'archive-studio',
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
            tabs: const [
              Tab(text: 'Create ZIP'),
              Tab(text: 'Extract Archive'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCreateZipTab(isDark),
                _buildExtractArchiveTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateZipTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _zipNameController,
          decoration: const InputDecoration(
            labelText: 'Archive Name',
            hintText: 'e.g. Project_Backup',
            prefixIcon: Icon(LucideIcons.archive, size: 18),
          ),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: _selectedFormat,
          decoration: const InputDecoration(
            labelText: 'Archive Format',
            prefixIcon: Icon(LucideIcons.package, size: 18),
          ),
          items: const [
            DropdownMenuItem(value: 'zip', child: Text('ZIP Archive (.zip)')),
            DropdownMenuItem(value: 'tar', child: Text('TAR Tape Archive (.tar)')),
            DropdownMenuItem(value: 'tar.gz', child: Text('TAR GZip Archive (.tar.gz)')),
            DropdownMenuItem(value: 'tar.bz2', child: Text('TAR BZip2 Archive (.tar.bz2)')),
            DropdownMenuItem(value: 'gz', child: Text('GZip Compressed Archive (.gz)')),
            DropdownMenuItem(value: 'bz2', child: Text('BZip2 Compressed Archive (.bz2)')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedFormat = val);
          },
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _createPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Encryption Password (Optional)',
            hintText: 'Leave empty for no password',
            prefixIcon: Icon(LucideIcons.lock, size: 18),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Files to include (${_filesToZip.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            OutlinedButton.icon(
              onPressed: _pickFilesToZip,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add Files'),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_filesToZip.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: const Center(child: Text('No files added yet')),
          )
        else
          ..._filesToZip.map((f) => ListTile(
                leading: const Icon(LucideIcons.file, size: 20),
                title: Text(f.uri.pathSegments.last, style: const TextStyle(fontSize: 13.5)),
                trailing: IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                  onPressed: () => setState(() => _filesToZip.remove(f)),
                ),
              )),
        const SizedBox(height: 24),

        ActionButton(
          label: 'Create ${_selectedFormat.toUpperCase()} Archive',
          icon: LucideIcons.archive,
          isLoading: _isZipping,
          onPressed: _filesToZip.isNotEmpty ? _createZip : null,
        ),

        if (_createdZip != null) ...[
          const SizedBox(height: 16),
          ActionButton(
            label: 'Open Created Archive',
            icon: LucideIcons.externalLink,
            isSecondary: true,
            onPressed: () => OpenFilex.open(_createdZip!.path),
          ),
        ],
      ],
    );
  }

  Widget _buildExtractArchiveTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_archiveToExtract == null)
          Center(
            child: OutlinedButton.icon(
              onPressed: _pickArchiveToExtract,
              icon: const Icon(LucideIcons.archive, size: 20),
              label: const Text('Choose .ZIP / .TAR / .GZ / .7Z / .RAR File'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(18)),
            ),
          )
        else ...[
          ListTile(
            leading: const Icon(LucideIcons.archive, color: AppColors.toolOrange),
            title: Text(_archiveToExtract!.uri.pathSegments.last, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: TextButton(onPressed: _pickArchiveToExtract, child: const Text('Change')),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _extractPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Decryption Password (If Encrypted)',
              hintText: 'Enter password if archive is protected',
              prefixIcon: Icon(LucideIcons.key, size: 18),
            ),
          ),
          const SizedBox(height: 20),

          ActionButton(
            label: 'Extract All Files',
            icon: LucideIcons.folderInput,
            isLoading: _isExtracting,
            onPressed: _extractArchive,
          ),
        ],

        if (_extractedFiles.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Extracted Files (${_extractedFiles.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          ..._extractedFiles.map(
            (f) => ListTile(
              leading: const Icon(LucideIcons.fileCheck, color: AppColors.success),
              title: Text(f.uri.pathSegments.last, style: const TextStyle(fontSize: 13.5)),
              trailing: const Icon(LucideIcons.externalLink, size: 16),
              onTap: () => OpenFilex.open(f.path),
            ),
          ),
        ],
      ],
    );
  }
}
