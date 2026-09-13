import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../../core/models/document_file.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/files_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/file_success_dialog.dart';
import 'models/temporary_share_models.dart';

class SecureShareRecipientScreen extends StatefulWidget {
  final String shareId;

  const SecureShareRecipientScreen({super.key, required this.shareId});

  @override
  State<SecureShareRecipientScreen> createState() => _SecureShareRecipientScreenState();
}

class _SecureShareRecipientScreenState extends State<SecureShareRecipientScreen> {
  TemporaryShareMetadata? _metadata;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isExpired = false;

  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isDownloading = false;
  File? _downloadedFile;

  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isExpired = false;
    });

    try {
      final meta = await ApiService().getTemporaryShareInfo(widget.shareId);
      if (!mounted) return;

      _remainingSeconds = meta.remainingSeconds;
      _startCountdown(meta.expiresAt);

      setState(() {
        _metadata = meta;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString();
      setState(() {
        _isLoading = false;
        if (errStr.contains('410') || errStr.contains('expired')) {
          _isExpired = true;
          _errorMessage = 'This share has expired. Temporary shares are valid for 10 minutes only.';
        } else {
          _errorMessage = 'Share not found or network error: $e';
        }
      });
    }
  }

  void _startCountdown(DateTime expiresAt) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final diff = expiresAt.difference(DateTime.now()).inSeconds;
      if (diff <= 0) {
        t.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isExpired = true;
        });
      } else {
        setState(() => _remainingSeconds = diff);
      }
    });
  }

  Future<void> _unlockAndDownload() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the decryption password.')),
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      final file = await ApiService().downloadTemporaryShareFile(widget.shareId, password);
      final fileSize = await file.length();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = _metadata?.filename ?? file.uri.pathSegments.last;

      final doc = DocumentFile(
        id: 'unlocked_$timestamp',
        name: filename,
        path: file.path,
        size: fileSize,
        modifiedAt: DateTime.now(),
        type: FileTypeCategory.other,
      );

      if (mounted) {
        await context.read<FilesProvider>().addFile(doc);
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'hist_dl_$timestamp',
                toolId: 'secure-share',
                toolName: '10-Minute Secure Share (Unlocked)',
                fileName: filename,
                outputPath: file.path,
                fileSize: fileSize,
                timestamp: DateTime.now(),
              ),
            );

        setState(() {
          _downloadedFile = file;
          _isDownloading = false;
        });

        HapticFeedback.mediumImpact();

        FileSuccessDialog.show(
          context,
          title: 'Decryption Successful!',
          message: 'File decrypted and downloaded securely to your device.',
          file: file,
          fileSize: _metadata?.fileSizeFormatted ?? '${(fileSize / 1024).toStringAsFixed(1)} KB',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        final err = e.toString();
        String message = 'Incorrect decryption password.';
        if (err.contains('410') || err.contains('expired')) {
          _isExpired = true;
          message = 'This temporary share has expired.';
        } else if (err.contains('429')) {
          message = 'Too many failed attempts. Access temporarily locked.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.toolRed),
        );
      }
    }
  }

  String _formatTimer(int seconds) {
    if (seconds <= 0) return '00:00';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'PaperKit Secure Share',
      showBottomNav: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _isLoading
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Verifying temporary share status...'),
                    ],
                  )
                : _isExpired || _errorMessage != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.toolRed.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.clock, color: AppColors.toolRed, size: 40),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _isExpired ? 'Share Expired' : 'Share Unavailable',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _errorMessage ??
                                'This share has expired. Temporary shares are strictly valid for 10 minutes only.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13.5, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(LucideIcons.arrowLeft, size: 16),
                            label: const Text('Back to Tools'),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Badge
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.toolIndigo.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '10-MINUTE ENCRYPTED SHARE',
                                style: TextStyle(
                                  color: AppColors.toolIndigo,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // File Information Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.black.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.toolBlue.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(LucideIcons.fileLock, color: AppColors.toolBlue, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _metadata?.filename ?? 'Shared File',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${_metadata?.fileSizeFormatted ?? ''} • AES-256 Encrypted',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Live Expiration Timer
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.toolOrange.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.toolOrange.withOpacity(0.25)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(LucideIcons.hourglass, size: 16, color: AppColors.toolOrange),
                                    SizedBox(width: 8),
                                    Text('Time Remaining:', style: TextStyle(fontSize: 13, color: AppColors.toolOrange)),
                                  ],
                                ),
                                Text(
                                  _formatTimer(_remainingSeconds),
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.toolOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password Entry
                          const Text(
                            'Enter Decryption Password',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Password provided by sender',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(LucideIcons.key, size: 18),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Unlock & Download Action
                          ActionButton(
                            label: 'Unlock & Download File',
                            icon: LucideIcons.unlock,
                            isLoading: _isDownloading,
                            onPressed: _unlockAndDownload,
                          ),

                          if (_downloadedFile != null) ...[
                            const SizedBox(height: 12),
                            ActionButton(
                              label: 'Open Downloaded File',
                              icon: LucideIcons.externalLink,
                              isSecondary: true,
                              onPressed: () => OpenFilex.open(_downloadedFile!.path),
                            ),
                          ],
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
