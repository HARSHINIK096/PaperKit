import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/services/storage_service.dart';

class AirShareFileItem {
  final String name;
  final String path;
  final int size;
  final DateTime modifiedAt;
  final bool isInApp;
  final String extension;

  AirShareFileItem({
    required this.name,
    required this.path,
    required this.size,
    required this.modifiedAt,
    required this.isInApp,
    required this.extension,
  });

  File get file => File(path);
}

class AirShareFileSelectorSheet extends StatefulWidget {
  final int initialTab; // 0 = In-App Files, 1 = Phone Files
  final ValueChanged<File>? onFileSelected;
  final List<AirShareFileItem>? customInAppFiles;
  final List<AirShareFileItem>? customPhoneFiles;

  const AirShareFileSelectorSheet({
    super.key,
    this.initialTab = 0,
    this.onFileSelected,
    this.customInAppFiles,
    this.customPhoneFiles,
  });

  static Future<File?> show(
    BuildContext context, {
    int initialTab = 0,
  }) {
    return showModalBottomSheet<File?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AirShareFileSelectorSheet(
        initialTab: initialTab,
        onFileSelected: (f) => Navigator.of(ctx).pop(f),
      ),
    );
  }

  @override
  State<AirShareFileSelectorSheet> createState() => _AirShareFileSelectorSheetState();
}

class _AirShareFileSelectorSheetState extends State<AirShareFileSelectorSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final StorageService _storageService = StorageService();

  List<AirShareFileItem> _inAppFiles = [];
  List<AirShareFileItem> _phoneFiles = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _activeCategory = 'all'; // all, pdf, doc, image, spreadsheet
  AirShareFileItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    if (widget.customInAppFiles != null || widget.customPhoneFiles != null) {
      _inAppFiles = widget.customInAppFiles ?? [];
      _phoneFiles = widget.customPhoneFiles ?? [];
      _isLoading = false;
    } else {
      _loadAllFiles();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllFiles() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch In-App Files from StorageService & App Directories
      final inAppList = <AirShareFileItem>[];
      final seenPaths = <String>{};

      // From tracked DocumentFiles
      final trackedFiles = await _storageService.getFiles();
      for (final doc in trackedFiles) {
        final f = File(doc.path);
        if (f.existsSync()) {
          seenPaths.add(f.path);
          final ext = f.path.contains('.') ? f.path.split('.').last.toLowerCase() : '';
          inAppList.add(AirShareFileItem(
            name: doc.name,
            path: f.path,
            size: doc.size,
            modifiedAt: doc.modifiedAt,
            isInApp: true,
            extension: ext,
          ));
        }
      }

      // Scan app documents directory for generated outputs
      final appDocDir = await getApplicationDocumentsDirectory();
      if (await appDocDir.exists()) {
        final entities = appDocDir.listSync(recursive: false);
        for (final entity in entities) {
          if (entity is File && !seenPaths.contains(entity.path)) {
            final ext = entity.path.contains('.') ? entity.path.split('.').last.toLowerCase() : '';
            if (['pdf', 'docx', 'doc', 'xlsx', 'xls', 'csv', 'png', 'jpg', 'jpeg', 'txt', 'zip'].contains(ext)) {
              seenPaths.add(entity.path);
              final stat = entity.statSync();
              inAppList.add(AirShareFileItem(
                name: entity.uri.pathSegments.last,
                path: entity.path,
                size: stat.size,
                modifiedAt: stat.modified,
                isInApp: true,
                extension: ext,
              ));
            }
          }
        }
      }

      // Scan temporary directory for recent conversions
      try {
        final tempDir = await getTemporaryDirectory();
        if (await tempDir.exists()) {
          final entities = tempDir.listSync(recursive: false);
          for (final entity in entities) {
            if (entity is File && !seenPaths.contains(entity.path)) {
              final ext = entity.path.contains('.') ? entity.path.split('.').last.toLowerCase() : '';
              if (['pdf', 'docx', 'xlsx', 'png', 'jpg', 'txt'].contains(ext)) {
                seenPaths.add(entity.path);
                final stat = entity.statSync();
                inAppList.add(AirShareFileItem(
                  name: entity.uri.pathSegments.last,
                  path: entity.path,
                  size: stat.size,
                  modifiedAt: stat.modified,
                  isInApp: true,
                  extension: ext,
                ));
              }
            }
          }
        }
      } catch (_) {}

      // Sort newest first
      inAppList.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

      // 2. Fetch In-Phone Files (Downloads, external documents)
      final phoneList = <AirShareFileItem>[];
      final seenPhonePaths = <String>{};

      // Try downloads directory
      try {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null && await downloadsDir.exists()) {
          final entities = downloadsDir.listSync(recursive: false);
          for (final entity in entities) {
            if (entity is File && !seenPhonePaths.contains(entity.path)) {
              final ext = entity.path.contains('.') ? entity.path.split('.').last.toLowerCase() : '';
              if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'csv', 'png', 'jpg', 'jpeg', 'txt', 'zip'].contains(ext)) {
                seenPhonePaths.add(entity.path);
                final stat = entity.statSync();
                phoneList.add(AirShareFileItem(
                  name: entity.uri.pathSegments.last,
                  path: entity.path,
                  size: stat.size,
                  modifiedAt: stat.modified,
                  isInApp: false,
                  extension: ext,
                ));
              }
            }
          }
        }
      } catch (_) {}

      // Try Android external storage directory
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null && await extDir.exists()) {
          final entities = extDir.listSync(recursive: false);
          for (final entity in entities) {
            if (entity is File && !seenPhonePaths.contains(entity.path)) {
              final ext = entity.path.contains('.') ? entity.path.split('.').last.toLowerCase() : '';
              if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'csv', 'png', 'jpg', 'jpeg'].contains(ext)) {
                seenPhonePaths.add(entity.path);
                final stat = entity.statSync();
                phoneList.add(AirShareFileItem(
                  name: entity.uri.pathSegments.last,
                  path: entity.path,
                  size: stat.size,
                  modifiedAt: stat.modified,
                  isInApp: false,
                  extension: ext,
                ));
              }
            }
          }
        }
      } catch (_) {}

      phoneList.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

      if (mounted) {
        setState(() {
          _inAppFiles = inAppList;
          _phoneFiles = phoneList;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDirectlyFromPhoneStorage() async {
    HapticFeedback.lightImpact();
    try {
      final result = await FilePicker.pickFiles();
      if (result.isNotEmpty && result.single.path != null) {
        final file = File(result.single.path!);
        if (widget.onFileSelected != null) {
          widget.onFileSelected!(file);
        } else if (mounted) {
          Navigator.of(context).pop(file);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  List<AirShareFileItem> _filterFiles(List<AirShareFileItem> source) {
    return source.where((item) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!item.name.toLowerCase().contains(q) && !item.extension.contains(q)) {
          return false;
        }
      }

      // Category filter
      if (_activeCategory == 'pdf' && item.extension != 'pdf') return false;
      if (_activeCategory == 'doc' && !['doc', 'docx', 'txt', 'rtf'].contains(item.extension)) return false;
      if (_activeCategory == 'image' && !['png', 'jpg', 'jpeg', 'webp'].contains(item.extension)) return false;
      if (_activeCategory == 'spreadsheet' && !['xls', 'xlsx', 'csv'].contains(item.extension)) return false;

      return true;
    }).toList();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fileDate = DateTime(dt.year, dt.month, dt.day);

    if (fileDate == today) {
      return 'Today, ${DateFormat('h:mm a').format(dt)}';
    } else if (today.difference(fileDate).inDays == 1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(dt)}';
    } else {
      return DateFormat('dd MMM yyyy').format(dt);
    }
  }

  IconData _getFileIcon(String ext) {
    switch (ext) {
      case 'pdf':
        return LucideIcons.fileText;
      case 'doc':
      case 'docx':
      case 'txt':
        return LucideIcons.fileType2;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return LucideIcons.fileSpreadsheet;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
        return LucideIcons.image;
      case 'zip':
      case 'rar':
      case '7z':
        return LucideIcons.fileArchive;
      default:
        return LucideIcons.file;
    }
  }

  Color _getFileColor(String ext) {
    switch (ext) {
      case 'pdf':
        return const Color(0xFFEF4444);
      case 'doc':
      case 'docx':
        return const Color(0xFF2563EB);
      case 'xls':
      case 'xlsx':
      case 'csv':
        return const Color(0xFF10B981);
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
        return const Color(0xFF8B5CF6);
      case 'zip':
      case 'rar':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredInApp = _filterFiles(_inAppFiles);
    final filteredPhone = _filterFiles(_phoneFiles);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.send, color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Document to AirShare',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Select from MaskerV Workspace or Phone Storage',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar (WhatsApp style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search documents by name or extension...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                    prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF64748B)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // Dual Tab Switcher: In-App Files vs In-Phone Files
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.sparkles, size: 15),
                        const SizedBox(width: 6),
                        Text('In-App Files (${_inAppFiles.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.smartphone, size: 15),
                        const SizedBox(width: 6),
                        Text('Phone Files (${_phoneFiles.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Category Filter Pills (All, PDF, Docs, Images, Spreadsheets)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  _buildCategoryChip('all', 'All Files', LucideIcons.files),
                  _buildCategoryChip('pdf', 'PDFs', LucideIcons.fileText),
                  _buildCategoryChip('doc', 'Documents', LucideIcons.fileType2),
                  _buildCategoryChip('image', 'Images', LucideIcons.image),
                  _buildCategoryChip('spreadsheet', 'Sheets', LucideIcons.fileSpreadsheet),
                ],
              ),
            ),

            // Tab Views for File Lists
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: In-App Files
                        _buildFileList(filteredInApp, isInApp: true),
                        // Tab 2: In-Phone Files
                        _buildFileList(filteredPhone, isInApp: false),
                      ],
                    ),
            ),

            // Bottom Confirmation Action Bar
            if (_selectedItem != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getFileColor(_selectedItem!.extension).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getFileIcon(_selectedItem!.extension),
                        size: 20,
                        color: _getFileColor(_selectedItem!.extension),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedItem!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_formatBytes(_selectedItem!.size)} • ${_selectedItem!.isInApp ? "MaskerV Workspace" : "Phone Storage"}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        if (widget.onFileSelected != null) {
                          widget.onFileSelected!(_selectedItem!.file);
                        } else {
                          Navigator.of(context).pop(_selectedItem!.file);
                        }
                      },
                      icon: const Icon(LucideIcons.send, size: 16),
                      label: const Text('AirShare Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String key, String label, IconData icon) {
    final isSelected = _activeCategory == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: Icon(
          icon,
          size: 13,
          color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : const Color(0xFF64748B)),
        ),
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : const Color(0xFF334155)),
        ),
        selectedColor: const Color(0xFF2563EB),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        onSelected: (val) => setState(() => _activeCategory = key),
      ),
    );
  }

  Widget _buildFileList(List<AirShareFileItem> items, {required bool isInApp}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length + (!isInApp ? 1 : 0),
      itemBuilder: (context, index) {
        // If phone tab, first item is "Browse More Files on Phone"
        if (!isInApp && index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.hardDrive, color: Color(0xFF2563EB), size: 22),
                ),
                title: const Text(
                  'Browse More Files on Phone',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                subtitle: const Text(
                  'Open device storage to select any document or file',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFF2563EB)),
                onTap: _pickDirectlyFromPhoneStorage,
              ),
            ),
          );
        }

        final item = isInApp ? items[index] : items[index - 1];
        final isSelected = _selectedItem?.path == item.path;
        final color = _getFileColor(item.extension);
        final icon = _getFileIcon(item.extension);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFEFF6FF))
                : (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : (isDark ? const Color(0xFF334155).withValues(alpha: 0.6) : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedItem = item);
              },
              onDoubleTap: () {
                HapticFeedback.mediumImpact();
                if (widget.onFileSelected != null) {
                  widget.onFileSelected!(item.file);
                } else {
                  Navigator.of(context).pop(item.file);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Squircle File Icon Badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Center(
                        child: Icon(icon, color: color, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // File Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.extension.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_formatBytes(item.size)} • ${_formatDate(item.modifiedAt)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Radio Selection Indicator
                    Icon(
                      isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                      color: isSelected ? const Color(0xFF2563EB) : (isDark ? Colors.grey[600] : Colors.grey[400]),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
