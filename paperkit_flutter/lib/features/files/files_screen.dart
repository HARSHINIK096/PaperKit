import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/models/document_file.dart';
import '../../core/providers/files_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/file_list_item.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  FileTypeCategory? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _importFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && result.files.isNotEmpty) {
      final filesProv = context.read<FilesProvider>();
      for (final platformFile in result.files) {
        if (platformFile.path != null) {
          final file = File(platformFile.path!);
          final name = platformFile.name;
          final ext = name.contains('.') ? name.split('.').last : '';
          final doc = DocumentFile(
            id: 'imp_${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}',
            name: name,
            path: file.path,
            size: platformFile.size,
            modifiedAt: DateTime.now(),
            type: DocumentFile.getTypeFromExtension(ext),
          );
          await filesProv.addFile(doc);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filesProv = context.watch<FilesProvider>();

    return AppShell(
      title: 'Files & Storage',
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.pieChart, size: 20),
          onPressed: () => context.push('/storage'),
          tooltip: 'Storage Breakdown',
        ),
        IconButton(
          icon: const Icon(LucideIcons.plus, size: 22),
          onPressed: _importFile,
          tooltip: 'Import File',
        ),
      ],
      child: Column(
        children: [
          // Tab bar: All Files vs Favorites
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
            tabs: const [
              Tab(text: 'All Files'),
              Tab(text: 'Favorites'),
            ],
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search files by name...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFileList(filesProv.files, filesProv, isDark),
                _buildFileList(filesProv.favoriteFiles, filesProv, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(List<DocumentFile> list, FilesProvider provider, bool isDark) {
    final filtered = list.where((f) {
      final matchesSearch = _searchQuery.isEmpty || f.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _selectedType == null || f.type == _selectedType;
      return matchesSearch && matchesType;
    }).toList();

    if (filtered.isEmpty) {
      return EmptyStateView(
        icon: LucideIcons.folderOpen,
        title: 'No Documents Found',
        description: 'Import files from your device or process them using our tools.',
        actionLabel: 'Import Files',
        onAction: _importFile,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final file = filtered[index];
        return FileListItem(
          file: file,
          onFavoriteToggle: () => provider.toggleFavorite(file.id),
          onDelete: () => provider.deleteFile(file.id),
        );
      },
    );
  }
}
