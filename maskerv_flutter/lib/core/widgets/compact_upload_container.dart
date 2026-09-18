import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../utils/platform_file_ext.dart';

class CompactUploadContainer extends StatelessWidget {
  final List<File> files;
  final ValueChanged<List<File>> onFilesSelected;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final List<String> allowedExtensions;
  final bool allowMultiple;
  final bool useShader;
  final VoidCallback? onClear;
  final VoidCallback? onTap;
  final bool enabled;

  const CompactUploadContainer({
    super.key,
    required this.files,
    required this.onFilesSelected,
    this.title = 'Upload Document',
    this.subtitle = 'Tap to browse or select files from device',
    this.icon = LucideIcons.uploadCloud,
    this.primaryColor = AppColors.primary,
    this.allowedExtensions = const ['pdf'],
    this.allowMultiple = false,
    this.useShader = true,
    this.onClear,
    this.onTap,
    this.enabled = true,
  });

  Future<void> _pickFiles(BuildContext context) async {
    if (!enabled) return;
    HapticFeedback.selectionClick();
    try {
      final result = await FilePicker.pickFiles(
        type: allowedExtensions.isEmpty ? FileType.any : FileType.custom,
        allowedExtensions: allowedExtensions.isEmpty ? null : allowedExtensions,
      );

      if (result.isNotEmpty) {
        final selected = result
            .where((f) => f.hasValidFile)
            .map((f) => f.asFile ?? File(f.name))
            .toList();
        if (selected.isNotEmpty) {
          onFilesSelected(selected);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File selection failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFiles = files.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        gradient: useShader
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        primaryColor.withValues(alpha: 0.12),
                        AppColors.surfaceDark,
                      ]
                    : [
                        primaryColor.withValues(alpha: 0.07),
                        const Color(0xFFFAFAFC),
                      ],
              )
            : null,
        border: Border.all(
          color: hasFiles
              ? primaryColor.withValues(alpha: 0.5)
              : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
          width: hasFiles ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? (onTap ?? () => _pickFiles(context)) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: hasFiles
                ? _buildSelectedFilesView(context, isDark)
                : _buildEmptyDropzone(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDropzone(bool isDark) {
    return Row(
      children: [
        // Squircle Icon Badge with Shader Accent
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: isDark ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 24, color: primaryColor),
        ),
        const SizedBox(width: 14),

        // Textual Instructions & Tags
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textMutedDark
                      : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (allowedExtensions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 5,
                  children: allowedExtensions.take(4).map((ext) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '.${ext.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Browse Action Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.folderOpen, size: 14, color: Colors.white),
              SizedBox(width: 5),
              Text(
                'Browse',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFilesView(BuildContext context, bool isDark) {
    final firstFile = files.first;
    final fileName = firstFile.uri.pathSegments.last;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                LucideIcons.fileCheck2,
                size: 20,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  FutureBuilder<int>(
                    future: firstFile.length(),
                    builder: (context, snapshot) {
                      final sizeStr = _formatBytes(snapshot.data ?? 0);
                      final countStr = files.length > 1
                          ? ' • +${files.length - 1} more file(s)'
                          : '';
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'READY',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF10B981),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$sizeStr$countStr',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Change Button
            TextButton.icon(
              onPressed: enabled ? (onTap ?? () => _pickFiles(context)) : null,
              icon: const Icon(LucideIcons.refreshCw, size: 12),
              label: const Text(
                'Change',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  LucideIcons.x,
                  size: 16,
                  color: Color(0xFFEF4444),
                ),
                onPressed: onClear,
                tooltip: 'Clear selection',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
