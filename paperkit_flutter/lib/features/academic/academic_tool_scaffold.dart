import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/history_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/empty_state_view.dart';

/// Shared scaffold for academic AI tools.
///
/// Handles the common flow:
///   File selection → Configuration → [Analyze] → Processing → Results → Export
///
/// Screen-specific content is injected via [configWidget] and [resultBuilder].
class AcademicToolScaffold<T> extends StatefulWidget {
  final String title;
  final String toolId;
  final String toolName;
  final IconData toolIcon;
  final Color toolColor;
  final Color toolSoftColor;
  final String processingLabel;
  final String filePickerLabel;
  final List<String> allowedExtensions;
  final bool allowMultiple;

  /// Widget shown between file selection and the action button for configuration.
  final Widget Function(bool hasMounted)? configWidget;

  /// The actual AI processing call. Returns the parsed result or throws.
  final Future<T> Function(List<File> files) onProcess;

  /// Renders the structured result.
  final Widget Function(T result, List<File> files) resultBuilder;

  /// If the result can be exported as a string, provide this to enable share.
  final String Function(T result)? exportToText;

  const AcademicToolScaffold({
    super.key,
    required this.title,
    required this.toolId,
    required this.toolName,
    required this.toolIcon,
    required this.toolColor,
    required this.toolSoftColor,
    required this.processingLabel,
    required this.filePickerLabel,
    required this.allowedExtensions,
    required this.onProcess,
    required this.resultBuilder,
    this.allowMultiple = false,
    this.configWidget,
    this.exportToText,
  });

  @override
  State<AcademicToolScaffold<T>> createState() => _AcademicToolScaffoldState<T>();
}

class _AcademicToolScaffoldState<T> extends State<AcademicToolScaffold<T>> {
  List<File> _files = [];
  bool _isProcessing = false;
  T? _result;
  String? _errorMessage;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: widget.allowedExtensions,
      allowMultiple: widget.allowMultiple,
    );
    if (result != null) {
      setState(() {
        _files = result.files.map((f) => File(f.path!)).toList();
        _result = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _runProcess() async {
    if (_files.isEmpty) return;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.onProcess(_files);
      if (mounted) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_$timestamp',
                toolId: widget.toolId,
                toolName: widget.toolName,
                fileName: _files.first.uri.pathSegments.last,
                fileSize: await _files.first.length(),
                timestamp: DateTime.now(),
              ),
            );
        setState(() {
          _result = result;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _reset() {
    setState(() {
      _files = [];
      _result = null;
      _errorMessage = null;
    });
  }

  Future<void> _share() async {
    if (_result == null || widget.exportToText == null) return;
    final text = widget.exportToText!(_result as T);
    await Share.share(text, subject: widget.title);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: widget.title,
      showBottomNav: false,
      actions: _result != null
          ? [
              if (widget.exportToText != null)
                IconButton(
                  onPressed: _share,
                  icon: const Icon(LucideIcons.share2, size: 20),
                  tooltip: 'Share results',
                ),
              IconButton(
                onPressed: _reset,
                icon: const Icon(LucideIcons.rotateCcw, size: 20),
                tooltip: 'Analyze another document',
              ),
            ]
          : null,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── File Selection Card ───────────────────────────────────────
          _FilePickerCard(
            files: _files,
            toolColor: widget.toolColor,
            toolSoftColor: widget.toolSoftColor,
            toolIcon: widget.toolIcon,
            allowMultiple: widget.allowMultiple,
            filePickerLabel: widget.filePickerLabel,
            allowedExtensions: widget.allowedExtensions,
            onPick: _pickFiles,
            isDark: isDark,
            enabled: !_isProcessing && _result == null,
          ),

          // ── Configuration ─────────────────────────────────────────────
          if (_files.isNotEmpty && _result == null && widget.configWidget != null) ...[
            const SizedBox(height: 20),
            widget.configWidget!(mounted),
          ],

          // ── Action Button ─────────────────────────────────────────────
          if (_files.isNotEmpty && _result == null) ...[
            const SizedBox(height: 20),
            ActionButton(
              label: widget.processingLabel,
              icon: LucideIcons.sparkles,
              isLoading: _isProcessing,
              onPressed: _isProcessing ? () {} : _runProcess,
            ),
          ],

          // ── Error State ───────────────────────────────────────────────
          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            _ErrorCard(message: _errorMessage!, onRetry: _runProcess, isDark: isDark),
          ],

          // ── Result ────────────────────────────────────────────────────
          if (_result != null) ...[
            const SizedBox(height: 24),
            widget.resultBuilder(_result as T, _files),
          ],

          // ── Empty State (no file selected) ────────────────────────────
          if (_files.isEmpty && _result == null && !_isProcessing) ...[
            const SizedBox(height: 40),
            EmptyStateView(
              icon: widget.toolIcon,
              title: 'No document selected',
              description: 'Choose a PDF or document file to get started.',
              actionLabel: widget.filePickerLabel,
              onAction: _pickFiles,
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _FilePickerCard extends StatelessWidget {
  final List<File> files;
  final Color toolColor;
  final Color toolSoftColor;
  final IconData toolIcon;
  final bool allowMultiple;
  final String filePickerLabel;
  final List<String> allowedExtensions;
  final VoidCallback onPick;
  final bool isDark;
  final bool enabled;

  const _FilePickerCard({
    required this.files,
    required this.toolColor,
    required this.toolSoftColor,
    required this.toolIcon,
    required this.allowMultiple,
    required this.filePickerLabel,
    required this.allowedExtensions,
    required this.onPick,
    required this.isDark,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: files.isEmpty
          ? Center(
              child: OutlinedButton.icon(
                onPressed: enabled ? onPick : null,
                icon: Icon(toolIcon, size: 20),
                label: Text(filePickerLabel),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  side: BorderSide(color: toolColor.withOpacity(0.5)),
                  foregroundColor: toolColor,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final file in files)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: toolSoftColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(toolIcon, color: toolColor, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.uri.pathSegments.last,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              FutureBuilder<int>(
                                future: file.length(),
                                builder: (context, snap) {
                                  if (!snap.hasData) return const SizedBox.shrink();
                                  final kb = (snap.data! / 1024).toStringAsFixed(1);
                                  return Text(
                                    '$kb KB',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        if (enabled)
                          TextButton(
                            onPressed: onPick,
                            child: Text(
                              files.length == 1 ? 'Change' : 'Replace',
                              style: TextStyle(color: toolColor, fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (allowMultiple && enabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextButton.icon(
                      onPressed: onPick,
                      icon: const Icon(LucideIcons.plusCircle, size: 16),
                      label: const Text('Select different files', style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(foregroundColor: toolColor),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isDark;

  const _ErrorCard({required this.message, required this.onRetry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 18),
              const SizedBox(width: 10),
              const Text(
                'Processing failed',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.error.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// A section card used in academic result screens for expandable sections.
class AcademicResultSection extends StatefulWidget {
  final String title;
  final Widget child;
  final IconData? icon;
  final Color? accentColor;
  final bool initiallyExpanded;

  const AcademicResultSection({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.accentColor,
    this.initiallyExpanded = true,
  });

  @override
  State<AcademicResultSection> createState() => _AcademicResultSectionState();
}

class _AcademicResultSectionState extends State<AcademicResultSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accentColor ?? AppColors.toolPurple;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(widget.icon, size: 16, color: accent),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 18,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

/// A chip that shows extraction confidence level.
class ConfidenceBadge extends StatelessWidget {
  final String confidence; // 'detected', 'inferred', 'unavailable'

  const ConfidenceBadge({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;
    switch (confidence.toLowerCase()) {
      case 'detected':
        color = AppColors.success;
        label = 'Detected';
        icon = LucideIcons.checkCircle2;
        break;
      case 'inferred':
        color = AppColors.warning;
        label = 'Inferred';
        icon = LucideIcons.brain;
        break;
      default:
        color = AppColors.textMutedLight;
        label = 'Not found';
        icon = LucideIcons.minusCircle;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Page reference badge.
class PageRefBadge extends StatelessWidget {
  final int? pageRef;

  const PageRefBadge({super.key, required this.pageRef});

  @override
  Widget build(BuildContext context) {
    if (pageRef == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'p.${pageRef! + 1}',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Shared bullet list renderer.
class BulletList extends StatelessWidget {
  final List<String> items;
  final Color? bulletColor;
  final double fontSize;

  const BulletList({
    super.key,
    required this.items,
    this.bulletColor,
    this.fontSize = 13.5,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = bulletColor ?? AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
