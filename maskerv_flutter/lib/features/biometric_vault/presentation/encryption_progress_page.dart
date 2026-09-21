import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../../../core/services/biometric_auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../models/vault_file.dart';
import '../services/vault_encryption_service.dart';
import '../services/vault_storage_service.dart';

// path is a transitive dep via path_provider — add explicit if needed
// import 'package:path/path.dart' as p;

enum _EncryptionState {
  reading,
  encrypting,
  authenticating,
  finalizing,
  success,
  error,
}

/// Auto-running encryption & biometric authentication screen.
///
/// The user cannot interact — the process runs automatically:
///   read file → encrypt → biometric prompt → finalize → success
///
/// No download button, save button, password input, or file naming.
class EncryptionProgressPage extends StatefulWidget {
  final File sourceFile;

  const EncryptionProgressPage({super.key, required this.sourceFile});

  @override
  State<EncryptionProgressPage> createState() => _EncryptionProgressPageState();
}

class _EncryptionProgressPageState extends State<EncryptionProgressPage>
    with SingleTickerProviderStateMixin {
  _EncryptionState _state = _EncryptionState.reading;
  String _errorMessage = '';
  late AnimationController _pulseController;
  double _progress = 0.0;
  Timer? _progressTimer;

  final VaultEncryptionService _encryptionService = VaultEncryptionService();
  final VaultStorageService _storageService = VaultStorageService();
  final BiometricAuthService _biometricAuth = BiometricAuthService();

  static const Color _vaultColor = AppColors.toolTeal;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    // Start the automated pipeline immediately
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPipeline());
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Pipeline ──────────────────────────────────────────────────

  Future<void> _runPipeline() async {
    try {
      // ── Phase 1: Read ──
      await _animateProgress(0.0, 0.15, label: _EncryptionState.reading);

      // ── Phase 2: Encrypt ──
      await _setStateAsync(_EncryptionState.encrypting);

      final id = _generateId();
      final encryptedFile = await _storageService.getEncryptedFilePath(id);
      await _encryptionService.encryptFile(widget.sourceFile, encryptedFile);
      await _animateProgress(0.15, 0.60);

      // ── Phase 3: Biometric Auth ──
      await _setStateAsync(_EncryptionState.authenticating);
      await _animateProgress(0.60, 0.65);

      final authenticated = await _biometricAuth.authenticate(
        reason: 'Authenticate to seal this file into your Biometric Vault',
        context: context,
      );

      if (!mounted) return;

      if (!authenticated) {
        // Auth failed — delete the encrypted file we just made
        await _storageService.deleteEncryptedFile(id);
        setState(() {
          _state = _EncryptionState.error;
          _errorMessage =
              'Biometric authentication failed.\nThe file was not stored in the vault.';
        });
        return;
      }

      // ── Phase 4: Finalize ──
      await _setStateAsync(_EncryptionState.finalizing);

      final originalName = p.basename(widget.sourceFile.path);
      final mimeType = _detectMimeType(originalName);
      final encryptedSize = await encryptedFile.length();

      final vaultEntry = VaultFile(
        id: id,
        originalName: originalName,
        encryptedFileName: 'enc_$id',
        mimeType: mimeType,
        sizeBytes: encryptedSize,
        createdAt: DateTime.now().toUtc(),
      );

      await _storageService.addVaultEntry(vaultEntry);
      await _animateProgress(0.65, 1.0, durationMs: 400);

      // ── Phase 5: Success ──
      if (mounted) {
        HapticFeedback.lightImpact();
        setState(() => _state = _EncryptionState.success);
      }
    } on VaultEncryptionException catch (e) {
      if (mounted) {
        setState(() {
          _state = _EncryptionState.error;
          _errorMessage = 'Encryption error. Please try again.';
          // Do not expose internal encryption exception details to UI
          debugPrint('Vault encryption exception: $e');
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _state = _EncryptionState.error;
          _errorMessage = 'An error occurred while processing the file. Please try again.';
        });
      }
    }
  }

  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = now.hashCode.abs().toString().padLeft(10, '0');
    return '${now}_$rand';
  }

  String _detectMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const map = {
      'pdf': 'application/pdf',
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'mp4': 'video/mp4',
      'mp3': 'audio/mpeg',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'zip': 'application/zip',
      'rar': 'application/x-rar-compressed',
    };
    return map[ext] ?? 'application/octet-stream';
  }

  Future<void> _setStateAsync(_EncryptionState state) async {
    if (!mounted) return;
    setState(() => _state = state);
    await Future.delayed(const Duration(milliseconds: 120));
  }

  Future<void> _animateProgress(
    double from,
    double to, {
    _EncryptionState? label,
    int durationMs = 700,
  }) async {
    if (!mounted) return;
    if (label != null) setState(() => _state = label);
    setState(() => _progress = from);

    const steps = 30;
    final stepDuration = Duration(milliseconds: durationMs ~/ steps);
    final increment = (to - from) / steps;
    for (int i = 0; i < steps; i++) {
      await Future.delayed(stepDuration);
      if (!mounted) return;
      setState(() => _progress = (from + increment * (i + 1)).clamp(0.0, 1.0));
    }
  }

  // ── UI ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Securing Your File',
      showBottomNav: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _state == _EncryptionState.success
              ? _buildSuccessView(isDark)
              : _state == _EncryptionState.error
                  ? _buildErrorView(isDark)
                  : _buildProgressView(isDark),
        ),
      ),
    );
  }

  Widget _buildProgressView(bool isDark) {
    final label = switch (_state) {
      _EncryptionState.reading => 'Reading file…',
      _EncryptionState.encrypting => 'Encrypting with AES-256-GCM…',
      _EncryptionState.authenticating => 'Requesting biometric authentication…',
      _EncryptionState.finalizing => 'Finalizing vault storage…',
      _ => 'Processing…',
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (ctx, _) => Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _vaultColor.withValues(
                alpha: 0.08 + _pulseController.value * 0.08,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _vaultColor.withValues(alpha: 0.15),
              ),
              child: const Icon(LucideIcons.shieldCheck, color: _vaultColor, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Securing Your File',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        LinearProgressIndicator(
          value: _progress,
          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          valueColor: const AlwaysStoppedAnimation<Color>(_vaultColor),
          borderRadius: BorderRadius.circular(8),
          minHeight: 10,
        ),
        const SizedBox(height: 10),
        Text(
          '${(_progress * 100).toInt()}%',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: _vaultColor,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Your file is being encrypted and stored\nsecurely in the biometric vault.\nPlease wait…',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.6,
            color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFECFDF5),
          ),
          child: const Icon(
            LucideIcons.checkCheck,
            color: AppColors.success,
            size: 44,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'File Secured!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your file has been encrypted and safely\nstored in the Biometric Vault.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              // Pop back to vault landing page
              context.go('/vault');
            },
            icon: const Icon(LucideIcons.vault, size: 18),
            label: const Text(
              'Go to Vault',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _vaultColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {
            HapticFeedback.selectionClick();
            context.go('/vault/upload');
          },
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('Encrypt Another File'),
          style: TextButton.styleFrom(foregroundColor: _vaultColor),
        ),
      ],
    );
  }

  Widget _buildErrorView(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error.withValues(alpha: 0.1),
          ),
          child: const Icon(LucideIcons.shieldX, color: AppColors.error, size: 42),
        ),
        const SizedBox(height: 24),
        const Text(
          'Vault Locked',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              context.go('/vault/upload');
            },
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text(
              'Try Again',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _vaultColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go('/vault'),
          style: TextButton.styleFrom(foregroundColor: _vaultColor),
          child: const Text('Back to Vault'),
        ),
      ],
    );
  }
}
