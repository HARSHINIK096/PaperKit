import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/providers/backend_provider.dart';
import '../../core/providers/files_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/particle_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedLanguage = 'English';
  Map<String, int>? _storageBreakdown;

  final List<String> _languages = [
    'English',
    'Spanish (Español)',
    'French (Français)',
    'German (Deutsch)',
    'Hindi (हिन्दी)',
    'Japanese (日本語)',
    'Chinese (中文)',
    'Arabic (العربية)',
  ];

  @override
  void initState() {
    super.initState();
    _loadStorageStats();
  }

  Future<void> _loadStorageStats() async {
    try {
      final breakdown = await StorageService().getStorageBreakdown();
      if (mounted) {
        setState(() => _storageBreakdown = breakdown);
      }
    } catch (_) {}
  }

  void _showServerConfigDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiService().baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backend API Server', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure the FastAPI endpoint for MASKERV Cloud and AI services:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'https://paperkit-backend.onrender.com',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ApiService().setBaseUrl(controller.text.trim());
              context.read<BackendProvider>().checkHealth();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Save & Reconnect'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Language', style: TextStyle(fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _languages.length,
            itemBuilder: (context, index) {
              final lang = _languages[index];
              return RadioListTile<String>(
                value: lang,
                groupValue: _selectedLanguage,
                title: Text(lang),
                onChanged: (val) {
                  setState(() => _selectedLanguage = val!);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Storage & Cache?', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.error)),
        content: const Text(
          'This will purge local temporary cached files and reset application preferences. Your original documents in device storage will not be affected.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await StorageService().clearTempDirectory();
              if (mounted) {
                _loadStorageStats();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache purged successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backend = context.watch<BackendProvider>();
    final filesProv = context.watch<FilesProvider>();

    final totalMB = _storageBreakdown != null
        ? (_storageBreakdown!['total']! / (1024 * 1024)).toStringAsFixed(1)
        : '0.0';

    return AppShell(
      title: 'Settings',
      child: Stack(
        children: [
          // Subtle particle background on settings page
          const Positioned.fill(
            child: ParticleBackground(
              numberOfParticles: 25,
              particleColor: Color(0xFF3B82F6),
              enableLines: false,
              maxSpeed: 0.2,
            ),
          ),

          // Settings Page Scrollable Content
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Top Profile Card (Matching Image 4) ──
              _buildProfileCard(context),
              const SizedBox(height: 18),

              // ── Live Quick Stats Row ──
              Row(
                children: [
                  _buildStatCard(
                    icon: LucideIcons.hardDrive,
                    value: '$totalMB MB',
                    label: 'Storage Used',
                    color: AppColors.toolBlue,
                    isDark: isDark,
                    onTap: () => context.push('/storage'),
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    icon: LucideIcons.files,
                    value: '${filesProv.files.length}',
                    label: 'Saved Files',
                    color: AppColors.toolPurple,
                    isDark: isDark,
                    onTap: () => context.push('/files'),
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    icon: LucideIcons.zap,
                    value: '< 1.8s',
                    label: 'Avg Speed',
                    color: AppColors.toolGreen,
                    isDark: isDark,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ── Workspace Section ──
              _buildSectionHeader('WORKSPACE SHORTCUTS'),
              _buildSettingsCard(
                isDark: isDark,
                children: [
                  _buildSettingsTile(
                    icon: LucideIcons.folder,
                    iconColor: AppColors.primary,
                    title: 'All Documents',
                    subtitle: '${filesProv.files.length} documents saved',
                    onTap: () => context.push('/files'),
                  ),
                  _buildSettingsTile(
                    icon: LucideIcons.pieChart,
                    iconColor: AppColors.toolOrange,
                    title: 'Storage Breakdown & Cache',
                    subtitle: 'Manage disk usage and exports',
                    onTap: () => context.push('/storage'),
                  ),
                  _buildSettingsTile(
                    icon: LucideIcons.history,
                    iconColor: AppColors.toolGreen,
                    title: 'Processing History',
                    subtitle: 'View operation audit logs',
                    onTap: () => context.push('/history'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── App Preferences Section ──
              _buildSectionHeader('APPLICATION PREFERENCES'),
              _buildSettingsCard(
                isDark: isDark,
                children: [
                  _buildSettingsTile(
                    icon: LucideIcons.sun,
                    iconColor: AppColors.toolOrange,
                    title: 'Interface Theme',
                    subtitle: 'Pure Light Studio (Offline First)',
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    icon: LucideIcons.globe,
                    iconColor: AppColors.toolBlue,
                    title: 'Interface Language',
                    subtitle: _selectedLanguage,
                    onTap: _showLanguageDialog,
                  ),
                  _buildSettingsTile(
                    icon: LucideIcons.server,
                    iconColor: backend.isConnected ? AppColors.success : AppColors.error,
                    title: 'Cloud Microservice Endpoint',
                    subtitle: backend.isConnected ? 'Connected & Operational' : 'Offline / Local-first mode',
                    onTap: () => _showServerConfigDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Security & Storage Purge ──
              _buildSectionHeader('DATA & PRIVACY'),
              _buildSettingsCard(
                isDark: isDark,
                children: [
                  _buildSettingsTile(
                    icon: LucideIcons.shieldCheck,
                    iconColor: AppColors.toolGreen,
                    title: 'Security Architecture',
                    subtitle: '256-bit AES & Local WASM Processing',
                    onTap: () => context.push('/tools/protect'),
                  ),
                  _buildSettingsTile(
                    icon: LucideIcons.trash2,
                    iconColor: AppColors.error,
                    title: 'Purge Temporary Cache',
                    subtitle: 'Clean up generated temp files',
                    onTap: _showClearDataDialog,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── About & Support Section ──
              _buildSectionHeader('HELP & SUPPORT'),
              _buildSettingsCard(
                isDark: isDark,
                children: [
                  _buildSettingsTile(
                    icon: LucideIcons.helpCircle,
                    iconColor: AppColors.toolBlue,
                    title: 'Help Center & FAQs',
                    subtitle: 'Tips and tool documentation',
                    onTap: () => context.push('/help'),
                  ),
                  _buildSettingsTile(
                    icon: LucideIcons.sparkles,
                    iconColor: AppColors.toolPurple,
                    title: 'Welcome & Feature Tour',
                    subtitle: 'Explore 14 interactive studio capabilities',
                    onTap: () => context.push('/welcome'),
                  ),
                  _buildSettingsTile(
                    icon: LucideIcons.info,
                    iconColor: AppColors.toolPurple,
                    title: 'About MASKERV',
                    subtitle: 'Version 1.0.0 • Architecture & Credits',
                    onTap: () => context.push('/about'),
                  ),
                  _buildSettingsTile(
                    icon: LucideIcons.share2,
                    iconColor: AppColors.primary,
                    title: 'Share MASKERV',
                    subtitle: 'Invite peers and classmates',
                    onTap: () {
                      Share.share(
                        'Check out MASKERV - The all-in-one local-first document suite with AI intelligence & PDF editing!',
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ],
      ),
    );
  }

  // Exact profile card matching Image 4
  Widget _buildProfileCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2563EB),
            Color(0xFF3B82F6),
            Color(0xFF4F46E5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with verified badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2.5),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'OS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.shieldCheck,
                        size: 15,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Name & Verified Pill
              Row(
                children: [
                  const Text(
                    'Open Source User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.shieldCheck, size: 12, color: Color(0xFF34D399)),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Email
              Text(
                'user@paperkit.local',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Status Pills
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Pill 1: Unrestricted Access
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.shieldCheck, size: 13, color: Color(0xFF38BDF8)),
                        SizedBox(width: 5),
                        Text(
                          'UNRESTRICTED ACCESS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Pill 2: Expiry / Verified Date
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.clock, size: 13, color: Colors.white70),
                        SizedBox(width: 5),
                        Text(
                          'Sep 8, 2026',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Top right settings gear icon button
          Positioned(
            top: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showServerConfigDialog(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    LucideIcons.settings,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
