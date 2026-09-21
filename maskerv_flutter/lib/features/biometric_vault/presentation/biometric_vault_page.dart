import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/services/biometric_auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';

/// The Biometric Vault landing page.
/// Displays exactly two action cards:
///   1. Upload to Vault — encrypts a file and stores it locally.
///   2. View Vault — biometric-gated access to stored files.
class BiometricVaultPage extends StatefulWidget {
  const BiometricVaultPage({super.key});

  @override
  State<BiometricVaultPage> createState() => _BiometricVaultPageState();
}

class _BiometricVaultPageState extends State<BiometricVaultPage>
    with SingleTickerProviderStateMixin {
  final BiometricAuthService _biometricAuth = BiometricAuthService();
  late AnimationController _shimmerController;
  bool _isAuthenticating = false;

  static const Color _vaultColor = AppColors.toolTeal;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _handleViewVault() async {
    if (_isAuthenticating) return;
    HapticFeedback.mediumImpact();

    setState(() => _isAuthenticating = true);

    try {
      final authenticated = await _biometricAuth.authenticate(
        reason: 'Authenticate to access your Biometric Vault',
        context: context,
      );

      if (!mounted) return;

      if (authenticated) {
        HapticFeedback.lightImpact();
        context.push('/vault/file-list');
      } else {
        _showAuthFailedSnack();
      }
    } catch (e) {
      if (mounted) _showAuthFailedSnack();
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void _showAuthFailedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Biometric authentication failed. Vault remains locked.'),
        backgroundColor: AppColors.error,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Biometric Vault',
      showBottomNav: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header badge
            _buildHeaderBadge(isDark),
            const SizedBox(height: 28),

            // Card 1 — Upload to Vault
            _buildActionCard(
              isDark: isDark,
              icon: LucideIcons.fileKey2,
              title: 'Upload to Vault',
              description:
                  'Select a file from your device. It will be encrypted with AES-256-GCM and stored securely on your device — never uploaded to any server.',
              buttonLabel: 'Select & Encrypt File',
              buttonIcon: LucideIcons.lockKeyhole,
              onTap: () {
                HapticFeedback.selectionClick();
                context.push('/vault/upload');
              },
              isLoading: false,
            ),
            const SizedBox(height: 16),

            // Card 2 — View Vault
            _buildActionCard(
              isDark: isDark,
              icon: LucideIcons.vault,
              title: 'View Vault',
              description:
                  'Access your encrypted files. Biometric authentication is required before any vault contents are revealed.',
              buttonLabel: _isAuthenticating ? 'Authenticating…' : 'Authenticate & Open',
              buttonIcon: LucideIcons.fingerprint,
              onTap: _handleViewVault,
              isLoading: _isAuthenticating,
            ),
            const SizedBox(height: 32),

            // Security info
            _buildSecurityInfo(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBadge(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  _vaultColor.withValues(alpha: 0.18),
                  _vaultColor.withValues(alpha: 0.08),
                ]
              : [
                  _vaultColor.withValues(alpha: 0.10),
                  const Color(0xFFF0FDFA),
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _vaultColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _vaultColor.withValues(alpha: isDark ? 0.25 : 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(LucideIcons.shieldCheck, color: _vaultColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Biometric Vault',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: _vaultColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'AES-256-GCM · Fully local · Biometric-gated',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String description,
    required String buttonLabel,
    required IconData buttonIcon,
    required VoidCallback onTap,
    required bool isLoading,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon column — fixed width so text is always aligned
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _vaultColor.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _vaultColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(icon, color: _vaultColor, size: 24),
                ),
                const SizedBox(width: 16),

                // Text + button column — flexible
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : onTap,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(buttonIcon, size: 16),
                          label: Text(
                            buttonLabel,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _vaultColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _vaultColor.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityInfo(bool isDark) {
    final infoColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final items = [
      (LucideIcons.lock, 'Files encrypted with AES-256-GCM'),
      (LucideIcons.serverOff, 'No data ever leaves your device'),
      (LucideIcons.fingerprint, 'Biometric authentication required to view'),
      (LucideIcons.keyRound, 'Encryption key stored in device Keystore/Keychain'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security Guarantees',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: infoColor,
          ),
        ),
        const SizedBox(height: 10),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(item.$1, size: 14, color: infoColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 12,
                      color: infoColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
