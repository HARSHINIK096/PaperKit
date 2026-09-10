import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/particle_background.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  String _selectedCategory = 'All';
  String _selectedLanguage = 'us English (English)';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // Background particle layer
          const ParticleBackground(
            numberOfParticles: 20,
            particleColor: Color(0xFF3B82F6),
            maxSpeed: 0.4,
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // PaperKit Logo Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(
                                child: Icon(LucideIcons.fileText, size: 13, color: Color(0xFF60A5FA)),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'PaperKit',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Language Dropdown Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.globe, size: 14, color: AppColors.primary),
                            const SizedBox(width: 5),
                            Text(
                              _selectedLanguage.length > 16 ? '${_selectedLanguage.substring(0, 16)}...' : _selectedLanguage,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('US', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Scrollable Body
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    children: [
                      // ── TOP HERO CARD ────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Open Source PDF Studio ✦',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Hero Graphic with Play Button
                            Container(
                              width: double.infinity,
                              height: 130,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Stack(
                                children: [
                                  // Background visual icons
                                  Positioned.fill(
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Icon(LucideIcons.fileText, size: 42, color: Colors.white.withValues(alpha: 0.25)),
                                          Icon(LucideIcons.sparkles, size: 54, color: Colors.white.withValues(alpha: 0.35)),
                                          Icon(LucideIcons.shieldCheck, size: 42, color: Colors.white.withValues(alpha: 0.25)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Play Button Circle
                                  Positioned(
                                    right: 18,
                                    top: 36,
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.15),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.play_arrow_rounded, color: Color(0xFF0F172A), size: 30),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Headline
                            Text(
                              'Clear speed.\nPure calm.',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                                letterSpacing: -0.5,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Subtitle
                            Text(
                              'Curated for document clarity, offline privacy and speed.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── DISCOVER CARD ────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search bar with user avatar
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.search, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: 'Find your document tool',
                                        hintStyle: TextStyle(
                                          fontSize: 12.5,
                                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                  const Icon(LucideIcons.user, size: 16, color: Color(0xFF64748B)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Header + Filter Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Discover',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'what powers your workflow',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Icon(LucideIcons.slidersHorizontal, size: 15, color: Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Category Chips (All, PDF, AI Intelligence)
                            Row(
                              children: [
                                _buildCategoryPill('All', isDark),
                                const SizedBox(width: 8),
                                _buildCategoryPill('PDF', isDark),
                                const SizedBox(width: 8),
                                _buildCategoryPill('AI Intelligence', isDark),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // 2x2 Grid Cards
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.5,
                              children: [
                                _buildFeatureCard(
                                  title: 'Merge PDF',
                                  subtitle: 'Combine multiple files',
                                  icon: LucideIcons.fileText,
                                  iconColor: const Color(0xFF2563EB),
                                  isDark: isDark,
                                  onTap: () => context.push('/tools/merge'),
                                ),
                                _buildFeatureCard(
                                  title: 'Compress PDF',
                                  subtitle: 'Reduce file size',
                                  icon: LucideIcons.fileText,
                                  iconColor: const Color(0xFF2563EB),
                                  isDark: isDark,
                                  onTap: () => context.push('/tools/compress'),
                                ),
                                _buildFeatureCard(
                                  title: 'Ask PDF AI',
                                  subtitle: 'Instant QA on docs',
                                  icon: LucideIcons.sparkles,
                                  iconColor: const Color(0xFF8B5CF6),
                                  isDark: isDark,
                                  onTap: () => context.push('/ai/ask'),
                                ),
                                _buildFeatureCard(
                                  title: 'Split PDF',
                                  subtitle: 'Extract or split pages',
                                  icon: LucideIcons.fileText,
                                  iconColor: const Color(0xFF2563EB),
                                  isDark: isDark,
                                  onTap: () => context.push('/tools/split'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),

                // Bottom Sticky CTA Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.go('/');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Launch Studio',
                            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                          ),
                          SizedBox(width: 8),
                          Icon(LucideIcons.arrowRight, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String label, bool isDark) {
    final isSelected = _selectedCategory == label;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0F172A)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
