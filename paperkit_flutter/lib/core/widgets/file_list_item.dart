import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/document_file.dart';
import '../theme/app_colors.dart';

class FileListItem extends StatelessWidget {
  final DocumentFile file;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDelete;

  const FileListItem({
    super.key,
    required this.file,
    this.onFavoriteToggle,
    this.onDelete,
  });

  IconData _getFileIcon() {
    switch (file.type) {
      case FileTypeCategory.pdf:
        return LucideIcons.fileText;
      case FileTypeCategory.image:
        return LucideIcons.image;
      case FileTypeCategory.audio:
        return LucideIcons.music;
      case FileTypeCategory.video:
        return LucideIcons.video;
      case FileTypeCategory.archive:
        return LucideIcons.archive;
      default:
        return LucideIcons.file;
    }
  }

  Color _getFileColor() {
    switch (file.type) {
      case FileTypeCategory.pdf:
        return AppColors.toolRed;
      case FileTypeCategory.image:
        return AppColors.toolBlue;
      case FileTypeCategory.audio:
        return AppColors.toolGreen;
      case FileTypeCategory.video:
        return AppColors.toolPurple;
      case FileTypeCategory.archive:
        return AppColors.toolOrange;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fileColor = _getFileColor();
    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(file.modifiedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: fileColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_getFileIcon(), color: fileColor, size: 22),
        ),
        title: Text(
          file.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              file.formattedSize,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '•',
              style: TextStyle(
                color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onFavoriteToggle != null)
              IconButton(
                icon: Icon(
                  file.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: file.isFavorite ? AppColors.warning : (isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight),
                  size: 22,
                ),
                onPressed: onFavoriteToggle,
              ),
            PopupMenuButton<String>(
              icon: Icon(
                LucideIcons.moreVertical,
                size: 18,
                color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
              ),
              onSelected: (value) async {
                if (value == 'open') {
                  await OpenFilex.open(file.path);
                } else if (value == 'share') {
                  await Share.shareXFiles([XFile(file.path)]);
                } else if (value == 'delete' && onDelete != null) {
                  onDelete!();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'open',
                  child: Row(
                    children: [
                      Icon(LucideIcons.externalLink, size: 16),
                      SizedBox(width: 10),
                      Text('Open'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(LucideIcons.share2, size: 16),
                      SizedBox(width: 10),
                      Text('Share'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                      SizedBox(width: 10),
                      Text('Delete', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => OpenFilex.open(file.path),
      ),
    );
  }
}
