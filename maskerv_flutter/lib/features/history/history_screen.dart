import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/empty_state_view.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final historyProv = context.watch<HistoryProvider>();

    return AppShell(
      title: 'Processing History',
      showBottomNav: false,
      actions: [
        if (historyProv.history.isNotEmpty)
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 20, color: AppColors.error),
            onPressed: () => historyProv.clearAll(),
            tooltip: 'Clear History',
          ),
      ],
      child: historyProv.history.isEmpty
          ? const EmptyStateView(
              icon: LucideIcons.history,
              title: 'No Processing History',
              description: 'Operations performed with PDF, AI, and Media tools will appear here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: historyProv.history.length,
              itemBuilder: (context, index) {
                final item = historyProv.history[index];
                final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(item.timestamp);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.toolName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.fileName,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$formattedDate • ${item.formattedSize}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.outputPath != null)
                        IconButton(
                          icon: const Icon(LucideIcons.externalLink, size: 18),
                          onPressed: () => OpenFilex.open(item.outputPath!),
                          tooltip: 'Open Result',
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
