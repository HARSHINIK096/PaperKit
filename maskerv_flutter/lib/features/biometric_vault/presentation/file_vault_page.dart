import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../models/vault_file.dart';
import '../services/vault_encryption_service.dart';
import '../services/vault_storage_service.dart';

/// The authenticated file vault — displays the list of encrypted vault entries.
///
/// Authentication has already been verified before this page opens.
///
/// On this page the user can:
///   - View/open a file (decrypted temporarily → opened → temp deleted)
///   - Export/share a file (decrypted temporarily → shared → temp deleted)
///   - Delete a vault file
///
/// The user CANNOT:
///   - Edit vault files
///   - Upload files from here
///   - Create folders or categories
///   - Rename encrypted files
class FileVaultPage extends StatefulWidget {
  const FileVaultPage({super.key});

  @override
  State<FileVaultPage> createState() => _FileVaultPageState();
}

class _FileVaultPageState extends State<FileVaultPage>
    with WidgetsBindingObserver {
  final VaultStorageService _storageService = VaultStorageService();
  final VaultEncryptionService _encryptionService = VaultEncryptionService();

  List<VaultFile> _vaultFiles = [];
  bool _isLoading = true;
  String? _openingFileId; // tracks which file is currently being decrypted

  // Temp files created this session — cleaned on dispose/background
  final List<File> _tempFiles = [];

  static const Color _vaultColor = AppColors.toolTeal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadVaultFiles();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupTempFiles();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Clean temp files when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _cleanupTempFiles();
    }
  }

  // ── Data ──────────────────────────────────────────────────────

  Future<void> _loadVaultFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await _storageService.loadMetadata();
      // Sort by newest first
      files.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) setState(() => _vaultFiles = files);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load vault contents.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openFile(VaultFile vaultFile) async {
    if (_openingFileId != null) return;
    HapticFeedback.selectionClick();
    setState(() => _openingFileId = vaultFile.id);

    try {
      final encryptedFile = await _storageService.getEncryptedFilePath(vaultFile.id);
      if (!encryptedFile.existsSync()) {
        _showError('Encrypted file not found. It may have been deleted.');
        return;
      }

      final plaintext = await _encryptionService.decryptFile(encryptedFile);
      final tempFile = await _storageService.getTempDecryptedFilePath(vaultFile.originalName);
      await tempFile.writeAsBytes(plaintext, flush: true);
      _tempFiles.add(tempFile);

      if (!mounted) return;
      final result = await OpenFilex.open(tempFile.path);
      if (result.type != ResultType.done && mounted) {
        _showError('Could not open file. No app available to view this file type.');
      }
    } on VaultEncryptionException catch (_) {
      if (mounted) _showError('Decryption failed. The file may be corrupted.');
    } catch (_) {
      if (mounted) _showError('Failed to open file. Please try again.');
    } finally {
      if (mounted) setState(() => _openingFileId = null);
    }
  }

  Future<void> _exportFile(VaultFile vaultFile) async {
    if (_openingFileId != null) return;
    HapticFeedback.selectionClick();
    setState(() => _openingFileId = vaultFile.id);

    try {
      final encryptedFile = await _storageService.getEncryptedFilePath(vaultFile.id);
      if (!encryptedFile.existsSync()) {
        _showError('Encrypted file not found.');
        return;
      }

      final plaintext = await _encryptionService.decryptFile(encryptedFile);
      final tempFile = await _storageService.getTempDecryptedFilePath(vaultFile.originalName);
      await tempFile.writeAsBytes(plaintext, flush: true);
      _tempFiles.add(tempFile);

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: vaultFile.originalName,
      );
    } on VaultEncryptionException catch (_) {
      if (mounted) _showError('Decryption failed. The file may be corrupted.');
    } catch (_) {
      if (mounted) _showError('Failed to export file. Please try again.');
    } finally {
      if (mounted) setState(() => _openingFileId = null);
    }
  }

  Future<void> _deleteFile(VaultFile vaultFile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Delete from Vault',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Permanently delete "${vaultFile.originalName}" from the vault?\nThis cannot be undone.',
          style: const TextStyle(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _storageService.deleteVaultEntry(vaultFile.id);
      setState(() => _vaultFiles.removeWhere((f) => f.id == vaultFile.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${vaultFile.originalName}" deleted from vault.'),
            backgroundColor: const Color(0xFF64748B),
          ),
        );
      }
    } catch (_) {
      if (mounted) _showError('Failed to delete file. Please try again.');
    }
  }

  void _cleanupTempFiles() {
    for (final file in _tempFiles) {
      try {
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
    }
    _tempFiles.clear();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'File Vault',
      showBottomNav: false,
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.refreshCw, size: 18),
          onPressed: _loadVaultFiles,
          tooltip: 'Refresh',
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _vaultColor))
          : _buildContent(isDark),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_vaultFiles.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _vaultFiles.length + 1, // +1 for header
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (ctx, index) {
        if (index == 0) return _buildHeader(isDark);
        return _buildFileItem(isDark, _vaultFiles[index - 1]);
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(LucideIcons.shieldCheck, size: 16, color: _vaultColor),
          const SizedBox(width: 8),
          Text(
            '${_vaultFiles.length} encrypted file${_vaultFiles.length == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(bool isDark, VaultFile vaultFile) {
    final isOpening = _openingFileId == vaultFile.id;
    final iconData = _getFileIcon(vaultFile.extension);
    final iconColor = _getFileIconColor(vaultFile.extension);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // File type icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),

          // File info — flexible
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vaultFile.originalName,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${vaultFile.extension} · ${vaultFile.formattedSize}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Actions — fixed column on the right
          if (isOpening)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _vaultColor,
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionButton(
                  icon: LucideIcons.externalLink,
                  color: _vaultColor,
                  tooltip: 'Open',
                  onTap: () => _openFile(vaultFile),
                ),
                _actionButton(
                  icon: LucideIcons.share2,
                  color: _vaultColor,
                  tooltip: 'Export',
                  onTap: () => _exportFile(vaultFile),
                ),
                _actionButton(
                  icon: LucideIcons.trash2,
                  color: AppColors.error,
                  tooltip: 'Delete',
                  onTap: () => _deleteFile(vaultFile),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color),
      onPressed: onTap,
      tooltip: tooltip,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _vaultColor.withValues(alpha: 0.1),
              ),
              child: const Icon(LucideIcons.vault, color: _vaultColor, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'Vault is Empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No files have been encrypted yet.\nUse "Upload to Vault" to add files.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/vault/upload'),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text(
                'Add First File',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _vaultColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  IconData _getFileIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return LucideIcons.fileText;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
        return LucideIcons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
        return LucideIcons.video;
      case 'mp3':
      case 'wav':
      case 'aac':
        return LucideIcons.music;
      case 'zip':
      case 'rar':
      case 'tar':
        return LucideIcons.archive;
      case 'docx':
      case 'doc':
        return LucideIcons.fileType;
      case 'xlsx':
      case 'xls':
        return LucideIcons.fileSpreadsheet;
      default:
        return LucideIcons.file;
    }
  }

  Color _getFileIconColor(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return AppColors.toolRed;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
        return AppColors.toolIndigo;
      case 'mp4':
      case 'mov':
      case 'avi':
        return AppColors.toolPurple;
      case 'mp3':
      case 'wav':
      case 'aac':
        return AppColors.toolOrange;
      case 'zip':
      case 'rar':
        return AppColors.toolGreen;
      case 'docx':
      case 'doc':
        return AppColors.toolBlue;
      case 'xlsx':
      case 'xls':
        return AppColors.toolGreen;
      default:
        return AppColors.toolTeal;
    }
  }
}
