import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:qr/qr.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/history_item.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/how_it_works_carousel.dart';
import '../qr_tools/models/qr_design_config.dart';
import '../qr_tools/services/qr_export_service.dart';
import '../qr_tools/widgets/qr_custom_painter.dart';
import 'models/temporary_share_models.dart';

class SecureShareScreen extends StatefulWidget {
  const SecureShareScreen({super.key});

  @override
  State<SecureShareScreen> createState() => _SecureShareScreenState();
}

class _SecureShareScreenState extends State<SecureShareScreen> {
  File? _selectedFile;
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isUploading = false;
  bool _isRevoking = false;

  TemporaryShareCreationResult? _shareResult;
  Timer? _countdownTimer;
  int _remainingSeconds = 600;
  bool _isRevoked = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _shareResult = null;
        _isRevoked = false;
      });
    }
  }

  Future<void> _createShare() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to share.')),
      );
      return;
    }

    final password = _passwordController.text.trim();
    if (password.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 4 characters.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final res = await ApiService().createTemporaryShare(
        file: _selectedFile!,
        password: password,
      );

      _countdownTimer?.cancel();
      _remainingSeconds = res.expiresInSeconds;

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        final now = DateTime.now();
        final diff = res.expiresAt.difference(now).inSeconds;
        if (diff <= 0) {
          timer.cancel();
          setState(() => _remainingSeconds = 0);
        } else {
          setState(() => _remainingSeconds = diff);
        }
      });

      // Log to history
      if (mounted) {
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'share_${res.shareId}',
                toolId: 'secure-share',
                toolName: '10-Minute Secure Share',
                fileName: res.filename,
                outputPath: res.shareUrl,
                fileSize: res.fileSize,
                timestamp: DateTime.now(),
                details: 'Expires in 10m • AES-256 Encrypted',
              ),
            );

        setState(() {
          _shareResult = res;
          _isUploading = false;
          _isRevoked = false;
        });

        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share creation failed: $e')),
        );
      }
    }
  }

  Future<void> _revokeShare() async {
    if (_shareResult == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Share?'),
        content: const Text(
          'Revoking will immediately destroy the encrypted file on the server. The QR code and link will permanently stop working.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.toolRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Revoke Now'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRevoking = true);
    try {
      await ApiService().revokeTemporaryShare(_shareResult!.shareId);
      _countdownTimer?.cancel();
      if (mounted) {
        setState(() {
          _isRevoked = true;
          _isRevoking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Temporary share revoked and file destroyed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRevoking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to revoke: $e')),
        );
      }
    }
  }

  Future<void> _exportOrShareQr({required bool isShare}) async {
    if (_shareResult == null) return;
    try {
      final file = await QrExportService.export(
        data: _shareResult!.shareUrl,
        config: const QrDesignConfig(
          frameLabel: '10-Min Secure Share',
        ),
        format: QrExportFormat.png,
      );

      if (isShare) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'PaperKit Secure Share (Expires in 10 mins): ${_shareResult!.shareUrl}',
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('QR Code image exported!'),
              action: SnackBarAction(label: 'Open', onPressed: () => OpenFilex.open(file.path)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR export failed: $e')),
        );
      }
    }
  }

  String _formatTimer(int totalSeconds) {
    if (totalSeconds <= 0) return 'EXPIRED';
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: '10-Minute Secure Share',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HowItWorksCarousel(
            toolId: 'secure-share',
            color: AppColors.toolIndigo,
            padding: EdgeInsets.only(bottom: 16),
          ),

          if (_shareResult == null) ...[
            // Creation Form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedFile == null)
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(LucideIcons.fileUp, size: 20),
                        label: const Text('Choose File to Share'),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.toolIndigo.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.fileKey, color: AppColors.toolIndigo, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFile!.uri.pathSegments.last,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              FutureBuilder<int>(
                                future: _selectedFile!.length(),
                                builder: (ctx, snap) {
                                  if (!snap.hasData) return const SizedBox();
                                  final bytes = snap.data!;
                                  final sizeStr = bytes > 1024 * 1024
                                      ? '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB'
                                      : '${(bytes / 1024).toStringAsFixed(1)} KB';
                                  return Text(sizeStr, style: const TextStyle(fontSize: 12, color: Colors.grey));
                                },
                              ),
                            ],
                          ),
                        ),
                        TextButton(onPressed: _pickFile, child: const Text('Change')),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_selectedFile != null) ...[
              Text(
                'Decryption Password',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Set password for recipient',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(LucideIcons.lock, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(LucideIcons.shieldCheck, size: 14, color: AppColors.toolGreen),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Zero-knowledge encryption: Password is never stored plaintext and never embedded in the QR code.',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ActionButton(
                label: 'Encrypt & Generate 10-Min Share QR',
                icon: LucideIcons.qrCode,
                isLoading: _isUploading,
                onPressed: _createShare,
              ),
            ],
          ] else ...[
            // Share Active / QR Dashboard
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isRevoked
                      ? AppColors.toolRed.withOpacity(0.4)
                      : (_remainingSeconds <= 0 ? Colors.grey : AppColors.toolIndigo.withOpacity(0.4)),
                ),
              ),
              child: Column(
                children: [
                  // Expiration Countdown Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isRevoked || _remainingSeconds <= 0
                          ? AppColors.toolRed.withOpacity(0.12)
                          : AppColors.toolOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isRevoked || _remainingSeconds <= 0 ? LucideIcons.alertCircle : LucideIcons.clock,
                          size: 16,
                          color: _isRevoked || _remainingSeconds <= 0 ? AppColors.toolRed : AppColors.toolOrange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isRevoked
                              ? 'SHARE REVOKED'
                              : (_remainingSeconds <= 0 ? 'SHARE EXPIRED' : 'Expires in: ${_formatTimer(_remainingSeconds)}'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _isRevoked || _remainingSeconds <= 0 ? AppColors.toolRed : AppColors.toolOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Real QR Code
                  if (!_isRevoked && _remainingSeconds > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Builder(
                        builder: (ctx) {
                          final qrCode = QrCode.fromData(
                            data: _shareResult!.shareUrl,
                            errorCorrectLevel: QrErrorCorrectLevel.M,
                          );
                          final qrImage = QrImage(qrCode);
                          return CustomPaint(
                            size: const Size(200, 200),
                            painter: QrCustomPainter(
                              qrImage: qrImage,
                              config: const QrDesignConfig(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      _shareResult!.filename,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Recipient must enter password to unlock',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    // Copy Link Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _shareResult!.shareUrl,
                              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _shareResult!.shareUrl));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Share URL copied to clipboard!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _exportOrShareQr(isShare: true),
                            icon: const Icon(LucideIcons.share2, size: 16),
                            label: const Text('Share QR'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _exportOrShareQr(isShare: false),
                            icon: const Icon(LucideIcons.download, size: 16),
                            label: const Text('Download QR'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Revoke Share Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: AppColors.toolRed),
                        onPressed: _isRevoking ? null : _revokeShare,
                        icon: const Icon(LucideIcons.trash2, size: 16),
                        label: Text(_isRevoking ? 'Revoking...' : 'Revoke Share Now'),
                      ),
                    ),
                  ] else ...[
                    // Expired or Revoked State
                    Icon(
                      _isRevoked ? LucideIcons.ban : LucideIcons.clock,
                      size: 48,
                      color: AppColors.toolRed,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isRevoked ? 'This share has been revoked' : 'This share has expired',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Temporary files are purged immediately from the server after expiration or revocation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _shareResult = null;
                        _selectedFile = null;
                        _isRevoked = false;
                      }),
                      child: const Text('Create Another Temporary Share'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
