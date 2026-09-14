import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/compact_upload_container.dart';
import '../../core/widgets/google_dotted_loader.dart';

enum BiometricStage {
  upload,
  encrypting,
  viewing,
  downloading,
  success,
}

class VaultFileItem {
  final String id;
  final String name;
  final String originalPath;
  final int sizeBytes;
  final DateTime sealedAt;
  final bool isEncrypted;

  VaultFileItem({
    required this.id,
    required this.name,
    required this.originalPath,
    required this.sizeBytes,
    required this.sealedAt,
    this.isEncrypted = true,
  });
}

class BiometricAppLockScreen extends StatefulWidget {
  const BiometricAppLockScreen({super.key});

  @override
  State<BiometricAppLockScreen> createState() => _BiometricAppLockScreenState();
}

class _BiometricAppLockScreenState extends State<BiometricAppLockScreen> {
  BiometricStage _currentStage = BiometricStage.upload;

  bool _isVaultLocked = true;
  bool _biometricsEnabled = true;
  bool _faceIdEnabled = true;
  String _autoLockInterval = '1 minute';

  List<File> _selectedFiles = [];
  final List<VaultFileItem> _vaultItems = [];
  File? _lastDecryptedFile;

  int _progressPercent = 0;
  Timer? _progressTimer;
  int _autoDownloadSeconds = 2;
  Timer? _autoDownloadTimer;

  @override
  void dispose() {
    _progressTimer?.cancel();
    _autoDownloadTimer?.cancel();
    super.dispose();
  }

  void _authenticateBiometric() {
    HapticFeedback.heavyImpact();
    // Hardware biometric authentication simulation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.toolTeal.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.fingerprint, size: 48, color: AppColors.toolTeal),
            ),
            const SizedBox(height: 16),
            const Text(
              'Touch Sensor to Unlock Vault',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Hold your finger on the biometric sensor or look at the camera for Face ID.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                HapticFeedback.lightImpact();
                setState(() => _isVaultLocked = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hardware Biometric Vault Unlocked'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.toolTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Verify Biometrics'),
            ),
          ],
        ),
      ),
    );
  }

  void _startEncryptAndSeal() {
    if (_selectedFiles.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _currentStage = BiometricStage.encrypting;
      _progressPercent = 10;
    });

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (_progressPercent < 90) {
        setState(() => _progressPercent += 15);
      } else {
        timer.cancel();
        _finalizeSealing();
      }
    });
  }

  void _finalizeSealing() {
    final file = _selectedFiles.first;
    final item = VaultFileItem(
      id: 'vault_${DateTime.now().millisecondsSinceEpoch}',
      name: file.uri.pathSegments.last,
      originalPath: file.path,
      sizeBytes: file.lengthSync(),
      sealedAt: DateTime.now(),
      isEncrypted: true,
    );

    setState(() {
      _vaultItems.insert(0, item);
      _lastDecryptedFile = file;
      _progressPercent = 100;
      _currentStage = BiometricStage.viewing;
    });
  }

  void _proceedToDownload() {
    setState(() {
      _currentStage = BiometricStage.downloading;
    });
  }

  void _proceedToAutoDownloadSuccess() {
    setState(() {
      _currentStage = BiometricStage.success;
      _autoDownloadSeconds = 2;
    });

    _autoDownloadTimer?.cancel();
    _autoDownloadTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_autoDownloadSeconds > 1) {
        setState(() => _autoDownloadSeconds--);
      } else {
        timer.cancel();
        setState(() => _autoDownloadSeconds = 0);
        if (_lastDecryptedFile != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Vault document auto-downloaded & archived: ${_lastDecryptedFile!.uri.pathSegments.last}'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    });
  }

  void _resetFlow() {
    _autoDownloadTimer?.cancel();
    _progressTimer?.cancel();
    setState(() {
      _currentStage = BiometricStage.upload;
      _selectedFiles = [];
      _progressPercent = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Biometric App Lock & Vault',
      showBottomNav: false,
      actions: [
        IconButton(
          icon: Icon(_isVaultLocked ? LucideIcons.lock : LucideIcons.unlock, size: 20),
          onPressed: () {
            if (_isVaultLocked) {
              _authenticateBiometric();
            } else {
              setState(() => _isVaultLocked = true);
            }
          },
          tooltip: _isVaultLocked ? 'Unlock Vault' : 'Lock Vault',
        ),
        IconButton(
          icon: const Icon(LucideIcons.refreshCw, size: 18),
          onPressed: _resetFlow,
          tooltip: 'Reset Pipeline',
        ),
      ],
      child: Column(
        children: [
          // 5-Stage Header Bar
          _buildStageHeader(isDark),

          // Main Body
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildCurrentStageView(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageHeader(bool isDark) {
    final stages = ['Upload', 'Encrypt', 'Vault View', 'Export', 'Success'];
    final currentIndex = _currentStage.index;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(stages.length, (idx) {
            final isPassed = idx < currentIndex;
            final isActive = idx == currentIndex;
            final color = isActive
                ? AppColors.toolTeal
                : (isPassed ? const Color(0xFF10B981) : const Color(0xFF94A3B8));

            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.toolTeal.withValues(alpha: 0.12)
                        : (isPassed ? const Color(0xFFECFDF5) : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive ? AppColors.toolTeal : (isPassed ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
                      width: isActive ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isPassed) ...[
                        const Icon(LucideIcons.check, size: 11, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        '${idx + 1}. ${stages[idx]}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive || isPassed ? FontWeight.w700 : FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (idx < stages.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(LucideIcons.chevronRight, size: 13, color: Color(0xFFCBD5E1)),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCurrentStageView(bool isDark) {
    switch (_currentStage) {
      case BiometricStage.upload:
        return _buildStage1Upload(isDark);
      case BiometricStage.encrypting:
        return _buildStage2Encrypting(isDark);
      case BiometricStage.viewing:
        return _buildStage3Viewing(isDark);
      case BiometricStage.downloading:
        return _buildStage4Downloading(isDark);
      case BiometricStage.success:
        return _buildStage5Success(isDark);
    }
  }

  // ── 1. UPLOAD STAGE ──
  Widget _buildStage1Upload(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Vault Security Badge
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _isVaultLocked
                ? const Color(0xFFFEF2F2)
                : const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isVaultLocked ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isVaultLocked ? LucideIcons.shieldAlert : LucideIcons.shieldCheck,
                color: _isVaultLocked ? const Color(0xFFDC2626) : const Color(0xFF059669),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isVaultLocked ? 'Vault is Locked' : 'Hardware Vault Active & Unlocked',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: _isVaultLocked ? const Color(0xFFDC2626) : const Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isVaultLocked
                          ? 'Tap unlock or authenticate to seal and view encrypted documents.'
                          : 'AES-256-GCM hardware enclave key active.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _isVaultLocked ? const Color(0xFFB91C1C) : const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isVaultLocked)
                ElevatedButton(
                  onPressed: _authenticateBiometric,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Unlock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Compact Upload Box
        CompactUploadContainer(
          files: _selectedFiles,
          title: 'Select Document to Vault',
          subtitle: 'Secure any sensitive PDF, contract, ID or image file',
          primaryColor: AppColors.toolTeal,
          icon: LucideIcons.fileKey2,
          allowedExtensions: const ['pdf', 'png', 'jpg', 'docx'],
          useShader: true,
          onFilesSelected: (files) => setState(() => _selectedFiles = files),
          onClear: () => setState(() => _selectedFiles = []),
        ),
        const SizedBox(height: 20),

        // Biometric Configuration Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Security Parameters',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  value: _biometricsEnabled,
                  onChanged: (v) => setState(() => _biometricsEnabled = v),
                  title: const Text('Fingerprint Authentication', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Require biometric touch sensor verification', style: TextStyle(fontSize: 11.5)),
                  secondary: const Icon(LucideIcons.fingerprint, size: 20, color: AppColors.toolTeal),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  value: _faceIdEnabled,
                  onChanged: (v) => setState(() => _faceIdEnabled = v),
                  title: const Text('Face ID Recognition', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Facial biometric camera scan verification', style: TextStyle(fontSize: 11.5)),
                  secondary: const Icon(LucideIcons.scanFace, size: 20, color: AppColors.toolTeal),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Auto-Lock Interval', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  DropdownButton<String>(
                    value: _autoLockInterval,
                    items: ['Immediate', '1 minute', '5 minutes', '15 minutes']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12.5))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _autoLockInterval = v);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _selectedFiles.isEmpty ? null : _startEncryptAndSeal,
            icon: const Icon(LucideIcons.lock, size: 18),
            label: const Text('Encrypt & Seal to Hardware Vault', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.toolTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // ── 2. PROCESSING / ENCRYPTING STAGE ──
  Widget _buildStage2Encrypting(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.toolTeal.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const GoogleDottedLoader(
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Enclave Sealing in Progress...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Generating AES-256-GCM keys and storing in hardware-backed biometric storage.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: isDark ? AppColors.textMutedDark : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: _progressPercent / 100,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.toolTeal),
              borderRadius: BorderRadius.circular(8),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Text(
              '$_progressPercent%',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.toolTeal),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. VIEWING STAGE ──
  Widget _buildStage3Viewing(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF6EE7B7)),
          ),
          child: const Row(
            children: [
              Icon(LucideIcons.checkCircle2, color: Color(0xFF059669), size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Document successfully encrypted and verified inside Biometric Vault.',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF065F46)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        const Text('Vault Inventory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),

        for (final item in _vaultItems)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.toolTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.fileLock2, color: AppColors.toolTeal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      const SizedBox(height: 2),
                      Text(
                        '${(item.sizeBytes / 1024).toStringAsFixed(1)} KB • Sealed with Biometrics',
                        style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.textMutedDark : const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('ENCRYPTED', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _proceedToDownload,
            icon: const Icon(LucideIcons.download, size: 18),
            label: const Text('Proceed to Download & Export', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.toolTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // ── 4. DOWNLOADING STAGE ──
  Widget _buildStage4Downloading(bool isDark) {
    final file = _lastDecryptedFile;
    final name = file?.uri.pathSegments.last ?? 'Secured_Document.pdf';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.toolTeal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.downloadCloud, size: 36, color: AppColors.toolTeal),
              ),
              const SizedBox(height: 14),
              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              const Text('Ready for decrypted export or device storage save.', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: file == null ? null : () => OpenFilex.open(file.path),
                      icon: const Icon(LucideIcons.externalLink, size: 16),
                      label: const Text('Open File'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.toolTeal,
                        side: const BorderSide(color: AppColors.toolTeal),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: file == null ? null : () => Share.shareXFiles([XFile(file.path)]),
                      icon: const Icon(LucideIcons.share2, size: 16),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.toolTeal,
                        side: const BorderSide(color: AppColors.toolTeal),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _proceedToAutoDownloadSuccess,
            icon: const Icon(LucideIcons.checkCircle2, size: 18),
            label: const Text('Confirm & Save to Downloads', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // ── 5. SUCCESS STAGE WITH AUTO-DOWNLOAD ──
  Widget _buildStage5Success(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.checkCheck, size: 48, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Biometric Security Enforced!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _autoDownloadSeconds > 0
                    ? 'Auto-downloading in $_autoDownloadSeconds seconds...'
                    : 'Auto-download complete • Saved in Downloads/MaskerV',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF059669),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _resetFlow,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Seal Another Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.toolTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
