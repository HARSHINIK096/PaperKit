import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/compact_upload_container.dart';

/// Upload to Vault — file selection page.
///
/// The user selects ONE file. No other inputs are asked for:
/// no name, description, category, folder, password, or metadata.
/// After confirmation the user is navigated to the encryption screen.
class UploadVaultPage extends StatefulWidget {
  const UploadVaultPage({super.key});

  @override
  State<UploadVaultPage> createState() => _UploadVaultPageState();
}

class _UploadVaultPageState extends State<UploadVaultPage> {
  List<File> _selectedFiles = [];

  static const Color _vaultColor = AppColors.toolTeal;

  File? get _selectedFile => _selectedFiles.isNotEmpty ? _selectedFiles.first : null;

  void _proceed() {
    final file = _selectedFile;
    if (file == null) return;
    HapticFeedback.mediumImpact();
    // Navigate to encryption progress, passing the selected file via extra
    context.push('/vault/encrypt', extra: file);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFile = _selectedFile != null;

    return AppShell(
      title: 'Upload to Vault',
      showBottomNav: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions banner
            _buildInstructionBanner(isDark),
            const SizedBox(height: 20),

            // File picker
            CompactUploadContainer(
              files: _selectedFiles,
              title: 'Select a File to Encrypt',
              subtitle: 'PDF, image, document, audio, video, or any file',
              primaryColor: _vaultColor,
              icon: LucideIcons.fileKey2,
              allowedExtensions: const [],
              allowMultiple: false,
              useShader: true,
              onFilesSelected: (files) {
                setState(() => _selectedFiles = files.take(1).toList());
              },
              onClear: () => setState(() => _selectedFiles = []),
            ),
            const SizedBox(height: 16),

            // Selected file info
            if (hasFile) ...[
              _buildSelectedFileInfo(isDark, _selectedFile!),
              const SizedBox(height: 16),
            ],

            // Continue button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: hasFile ? _proceed : null,
                icon: const Icon(LucideIcons.lockKeyhole, size: 18),
                label: const Text(
                  'Secure & Encrypt File',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _vaultColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  disabledForegroundColor: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Security note
            _buildSecurityNote(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _vaultColor.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _vaultColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, size: 16, color: _vaultColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Select any file from your device. It will be encrypted locally and stored securely — nothing is uploaded to a server.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFileInfo(bool isDark, File file) {
    final name = file.uri.pathSegments.last;
    final ext = name.contains('.') ? name.split('.').last.toUpperCase() : 'FILE';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _vaultColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: _vaultColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ext,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _vaultColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FutureBuilder<int>(
                  future: file.length(),
                  builder: (ctx, snap) {
                    if (!snap.hasData) return const SizedBox.shrink();
                    final bytes = snap.data!;
                    final sizeStr = bytes < 1024 * 1024
                        ? '${(bytes / 1024).toStringAsFixed(1)} KB'
                        : '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
                    return Text(
                      sizeStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 20),
        ],
      ),
    );
  }

  Widget _buildSecurityNote(bool isDark) {
    final color = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.shieldCheck, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Your file will be encrypted with AES-256-GCM using a key stored in your device\'s secure enclave (Android Keystore / iOS Keychain). The original file is never modified.',
            style: TextStyle(fontSize: 11.5, color: color, height: 1.5),
          ),
        ),
      ],
    );
  }
}
