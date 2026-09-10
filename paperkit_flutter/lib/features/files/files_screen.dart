import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/document_file.dart';
import '../../core/providers/files_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/file_list_item.dart';
import '../../core/widgets/file_preview_modal.dart';

enum FileSortOption { dateDesc, dateAsc, nameAsc, nameDesc, sizeDesc, sizeAsc }

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _activeCategory = 'all'; // all, pdf, word, image, others
  FileSortOption _sortOption = FileSortOption.dateDesc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _importFiles() async {
    HapticFeedback.lightImpact();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${result.files.length} file(s) into workspace'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('Sort Documents', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              ),
              const Divider(),
              RadioListTile<FileSortOption>(
                value: FileSortOption.dateDesc,
                groupValue: _sortOption,
                title: const Text('Newest First (Date)'),
                onChanged: (val) {
                  setState(() => _sortOption = val!);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<FileSortOption>(
                value: FileSortOption.dateAsc,
                groupValue: _sortOption,
                title: const Text('Oldest First (Date)'),
                onChanged: (val) {
                  setState(() => _sortOption = val!);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<FileSortOption>(
                value: FileSortOption.nameAsc,
                groupValue: _sortOption,
                title: const Text('File Name (A - Z)'),
                onChanged: (val) {
                  setState(() => _sortOption = val!);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<FileSortOption>(
                value: FileSortOption.sizeDesc,
                groupValue: _sortOption,
                title: const Text('Largest Size First'),
                onChanged: (val) {
                  setState(() => _sortOption = val!);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFileActions(DocumentFile file) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(file.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(file.formattedSize, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(LucideIcons.eye, color: AppColors.primary),
              title: const Text('Preview Document'),
              onTap: () {
                Navigator.pop(ctx);
                FilePreviewModal.show(context, file);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.externalLink, color: AppColors.toolBlue),
              title: const Text('Open in Native Viewer'),
              onTap: () {
                Navigator.pop(ctx);
                OpenFilex.open(file.path);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.share2, color: AppColors.toolPurple),
              title: const Text('Share File'),
              onTap: () {
                Navigator.pop(ctx);
                Share.shareXFiles([XFile(file.path)]);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: AppColors.error),
              title: const Text('Delete File', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<FilesProvider>().deleteFile(file.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<DocumentFile> _filterAndSort(List<DocumentFile> rawList) {
    var list = rawList.where((f) {
      final matchesSearch = _searchQuery.isEmpty || f.name.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_activeCategory == 'pdf') return f.type == FileTypeCategory.pdf;
      if (_activeCategory == 'word') return f.type == FileTypeCategory.document;
      if (_activeCategory == 'image') return f.type == FileTypeCategory.image;
      if (_activeCategory == 'others') {
        return f.type != FileTypeCategory.pdf && f.type != FileTypeCategory.document && f.type != FileTypeCategory.image;
      }
      return true;
    }).toList();

    switch (_sortOption) {
      case FileSortOption.dateDesc:
        list.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
        break;
      case FileSortOption.dateAsc:
        list.sort((a, b) => a.modifiedAt.compareTo(b.modifiedAt));
        break;
      case FileSortOption.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case FileSortOption.nameDesc:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case FileSortOption.sizeDesc:
        list.sort((a, b) => b.size.compareTo(a.size));
        break;
      case FileSortOption.sizeAsc:
        list.sort((a, b) => a.size.compareTo(b.size));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filesProv = context.watch<FilesProvider>();

    return AppShell(
      title: 'Files & Workspace',
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.slidersHorizontal, size: 20),
          onPressed: _showSortDialog,
          tooltip: 'Sort Files',
        ),
        IconButton(
          icon: const Icon(LucideIcons.pieChart, size: 20),
          onPressed: () => context.push('/storage'),
          tooltip: 'Storage Breakdown',
        ),
        IconButton(
          icon: const Icon(LucideIcons.plus, size: 22),
          onPressed: _importFiles,
          tooltip: 'Import Files',
        ),
        const SizedBox(width: 4),
      ],
      child: Column(
        children: [
          // Top Tabs (All Files vs Favorites)
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
            tabs: const [
              Tab(text: 'All Documents'),
              Tab(text: 'Starred & Favorites'),
            ],
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search files by title or extension...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildFilterChip('All Files', 'all', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('PDF Docs', 'pdf', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Word & Office', 'word', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Images', 'image', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Other Files', 'others', isDark),
              ],
            ),
          ),

          // Recent Files Quick Carousel (if any exist)
          if (filesProv.recentFiles.isNotEmpty && _searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.clock, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Recent Workspace Files',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filesProv.recentFiles.length,
                      itemBuilder: (context, index) {
                        final file = filesProv.recentFiles[index];
                        return InkWell(
                          onTap: () => FilePreviewModal.show(context, file),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.fileText, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 130),
                                  child: Text(
                                    file.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // File List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFileList(_filterAndSort(filesProv.files), filesProv, isDark),
                _buildFileList(_filterAndSort(filesProv.favoriteFiles), filesProv, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String categoryId, bool isDark) {
    final isSelected = _activeCategory == categoryId;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _activeCategory = categoryId),
      selectedColor: AppColors.primary.withOpacity(0.18),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
    );
  }

  Widget _buildFileList(List<DocumentFile> list, FilesProvider provider, bool isDark) {
    if (list.isEmpty) {
      return EmptyStateView(
        icon: LucideIcons.folderOpen,
        title: 'No Documents Found',
        description: 'Import files from your device or process documents using PaperKit tools.',
        actionLabel: 'Import Files',
        onAction: _importFiles,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final file = list[index];
        return InkWell(
          onTap: () => FilePreviewModal.show(context, file),
          onLongPress: () => _showFileActions(file),
          child: FileListItem(
            file: file,
            onFavoriteToggle: () => provider.toggleFavorite(file.id),
            onDelete: () => provider.deleteFile(file.id),
          ),
        );
      },
    );
  }
}
