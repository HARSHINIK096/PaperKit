import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/particle_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoPlayTimer;
  Timer? _cloudBootPoller;

  final List<_TourSlide> _slides = [
    const _TourSlide(
      id: 1,
      badge: 'Welcome to PaperKit',
      title: 'Your Ultimate PDF & Document Studio',
      subtitle: 'All-in-one document intelligence, local WebAssembly tools, and deep AI capabilities built for modern workflows.',
      icon: LucideIcons.sparkles,
      iconColor: Color(0xFF2563EB),
      bgColor: Color(0x1F2563EB),
      highlightColor: Color(0xFF2563EB),
      features: [
        'Universal PDF processing suite with 20+ specialized tools',
        'Instant document conversion, compression, & editing',
        'Deep AI intelligence for summaries & Q&A analysis',
      ],
    ),
    const _TourSlide(
      id: 2,
      badge: '100% Private Processing',
      title: 'Offline Client-Side WASM Core',
      subtitle: 'Your documents never leave your device memory. Processing runs locally on your device with complete privacy.',
      icon: LucideIcons.shieldCheck,
      iconColor: Color(0xFF059669),
      bgColor: Color(0x1F059669),
      highlightColor: Color(0xFF059669),
      features: [
        'Zero server upload requirement for standard PDF tools',
        'Bank-grade privacy for confidential & proprietary documents',
        'Lightning-fast execution directly on your CPU/GPU',
      ],
    ),
    const _TourSlide(
      id: 3,
      badge: 'Document Merging',
      title: 'Combine & Stack Multi-Format Files',
      subtitle: 'Merge hundreds of PDFs, CAD drawings, lab manuals, and image files into one structured document in seconds.',
      icon: LucideIcons.layers,
      iconColor: Color(0xFF7C3AED),
      bgColor: Color(0x1F7C3AED),
      highlightColor: Color(0xFF7C3AED),
      features: [
        'Drag-and-drop page ordering & document stacking',
        'Preserve original bookmarks, vector fonts, and layout',
        'Instant preview before generating final compilation',
      ],
    ),
    const _TourSlide(
      id: 4,
      badge: 'Smart Compression',
      title: 'Reduce File Size up to 90%',
      subtitle: 'Intelligent vector and image compression shrinks heavy PDFs for quick email sharing and portal uploads.',
      icon: LucideIcons.zap,
      iconColor: Color(0xFFD97706),
      bgColor: Color(0x1FD97706),
      highlightColor: Color(0xFFD97706),
      features: [
        'Multiple compression levels: Extreme, Recommended, & Light',
        'Retains sharp text and vector diagrams at high DPI',
        'Real-time estimated file size reduction preview',
      ],
    ),
    const _TourSlide(
      id: 5,
      badge: 'Ask PDF AI',
      title: 'Interactive AI Document Q&A',
      subtitle: 'Chat directly with long textbooks, research papers, and technical manuals with instant accurate page citations.',
      icon: LucideIcons.messageSquare,
      iconColor: Color(0xFF2563EB),
      bgColor: Color(0x1F2563EB),
      highlightColor: Color(0xFF2563EB),
      features: [
        'Context-aware answers with exact page reference quotes',
        'Multi-document chat for comparing multiple sources',
        'Export Q&A transcripts into study notes or summaries',
      ],
    ),
    const _TourSlide(
      id: 6,
      badge: 'AI Table Extraction',
      title: 'Convert Document Data to CSV/Excel',
      subtitle: 'Automatically detect and extract complex tables, lab datasets, and financial statements with zero manual typing.',
      icon: LucideIcons.table,
      iconColor: Color(0xFF059669),
      bgColor: Color(0x1F059669),
      highlightColor: Color(0xFF059669),
      features: [
        'Detects structured & unbordered table boundaries',
        'One-click export to clean CSV, JSON, or Excel sheets',
        'Automatic mathematical & numerical format validation',
      ],
    ),
    const _TourSlide(
      id: 7,
      badge: 'OCR Recognition',
      title: 'Turn Scans into Searchable Text',
      subtitle: 'High-precision optical character recognition converts paper scans and images into copyable, searchable text.',
      icon: LucideIcons.scanText,
      iconColor: Color(0xFF7C3AED),
      bgColor: Color(0x1F7C3AED),
      highlightColor: Color(0xFF7C3AED),
      features: [
        'Multi-language OCR engine supporting 20+ languages',
        'Preserves original document layout and paragraphing',
        'Generates searchable PDF/A overlay layers',
      ],
    ),
    const _TourSlide(
      id: 8,
      badge: 'Smart Redaction',
      title: 'Permanent PII & Data Sanitization',
      subtitle: 'Blackout sensitive names, social security numbers, passwords, and addresses permanently before distribution.',
      icon: LucideIcons.shieldAlert,
      iconColor: Color(0xFFDC2626),
      bgColor: Color(0x1FDC2626),
      highlightColor: Color(0xFFDC2626),
      features: [
        'Automated regex pattern scanning (Emails, SSNs, Phones)',
        'Destroys underlying vector text data — zero recovery',
        'Sanitizes hidden metadata & revision histories',
      ],
    ),
    const _TourSlide(
      id: 9,
      badge: 'Signatures & Watermarks',
      title: 'Digital Signing & Document Protection',
      subtitle: 'Add cryptographic signatures, visual stamp signatures, watermarks, and password encryption in seconds.',
      icon: LucideIcons.penTool,
      iconColor: Color(0xFF2563EB),
      bgColor: Color(0x1F2563EB),
      highlightColor: Color(0xFF2563EB),
      features: [
        'Draw, type, or upload custom e-signatures',
        'Custom text or image watermarks with opacity control',
        'AES-256 password protection & permission restriction',
      ],
    ),
    const _TourSlide(
      id: 10,
      badge: 'ISO PDF/A Archiving',
      title: 'Long-Term Preserved Compliance',
      subtitle: 'Convert standard documents into ISO 19005 compliant PDF/A format required for legal and government records.',
      icon: LucideIcons.archive,
      iconColor: Color(0xFFD97706),
      bgColor: Color(0x1FD97706),
      highlightColor: Color(0xFFD97706),
      features: [
        'Embeds all fonts, color profiles, & metadata standards',
        'Ensures document renders identically 50 years from now',
        'Built-in compliance checking & validation report',
      ],
    ),
    const _TourSlide(
      id: 11,
      badge: 'Visual Page Organizer',
      title: 'Reorder, Rotate, Split & Duplicate',
      subtitle: 'Visual thumbnail grid lets you manage individual PDF pages with simple drag-and-drop actions.',
      icon: LucideIcons.grid,
      iconColor: Color(0xFF059669),
      bgColor: Color(0x1F059669),
      highlightColor: Color(0xFF059669),
      features: [
        'Rotate upside-down pages by 90°, 180°, or 270°',
        'Extract custom page ranges into standalone PDFs',
        'Delete blank pages or duplicate important slides',
      ],
    ),
    const _TourSlide(
      id: 12,
      badge: 'Multi-Language Compactability',
      title: 'Native Mobile & Offline App',
      subtitle: 'Full interface translation across 10+ languages with native desktop & mobile app experience.',
      icon: LucideIcons.globe,
      iconColor: Color(0xFF7C3AED),
      bgColor: Color(0x1F7C3AED),
      highlightColor: Color(0xFF7C3AED),
      features: [
        'Seamless multi-language switching (English, Spanish, Hindi, etc.)',
        'Installable on Android, iOS, Windows & macOS',
        'Offline-first architecture — works without active internet',
      ],
    ),
    const _TourSlide(
      id: 13,
      badge: 'Cloud AI Intelligence',
      title: 'Deep Document Analytics & Cloud Engine',
      subtitle: 'Real-time cloud sync powers semantic document comparison, vector similarity matrices, and automatic classification.',
      icon: LucideIcons.cpu,
      iconColor: Color(0xFF2563EB),
      bgColor: Color(0x1F2563EB),
      highlightColor: Color(0xFF2563EB),
      features: [
        'Semantic document comparison highlighting hidden structural changes',
        'AI Document classification and auto-tagging system',
        'High-throughput vector search across massive document archives',
      ],
    ),
    const _TourSlide(
      id: 14,
      isRateLimits: true,
      badge: 'Fair Use Policy',
      title: 'Usage Limits & Fair Access',
      subtitle: 'To keep performance fast and reliable for everyone, fair usage limits apply on shared cloud infrastructure.',
      icon: LucideIcons.gauge,
      iconColor: Color(0xFFEA580C),
      bgColor: Color(0x1FEA580C),
      highlightColor: Color(0xFFEA580C),
      pdfRule: '≤ 15 pages per document',
      pdfNote: 'Merge, Split, Compress, Rotate, Watermark, Edit & all PDF tools.',
      pdfTip: 'Split large PDFs into chunks under 15 pages before processing.',
      aiRule: '5 requests per 1–4 hours',
      aiNote: 'Summarize, Ask PDF, OCR, Translate, Tables & all AI tools.',
      aiTip: 'Limits reset automatically. Each AI tool category has an independent counter.',
      features: [
        'Limits reset automatically — no account required',
        'Client-side WASM PDF tools are always unlimited',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoPlay();
    _startCloudBootPoller();
  }

  void _startCloudBootPoller() {
    _cloudBootPoller = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      try {
        final ok = await ApiService().checkHealth(timeoutMs: 3000);
        if (ok) {
          timer.cancel();
        }
      } catch (_) {}
    });
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (_currentIndex < _slides.length - 1) {
      _autoPlayTimer = Timer(const Duration(seconds: 6), () {
        if (mounted && _currentIndex < _slides.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
  }

  void _handleNext() {
    _autoPlayTimer?.cancel();
    HapticFeedback.lightImpact();
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _handleFinish();
    }
  }

  void _handlePrev() {
    _autoPlayTimer?.cancel();
    HapticFeedback.lightImpact();
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _handleFinish() async {
    _autoPlayTimer?.cancel();
    _cloudBootPoller?.cancel();
    HapticFeedback.mediumImpact();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('paperkit_onboarding_done', true);
    } catch (_) {}
    if (mounted) {
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _cloudBootPoller?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentSlide = _slides[_currentIndex];
    final progressPercent = (_currentIndex + 1) / _slides.length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Dynamic Particle Background
          ParticleBackground(
            numberOfParticles: 26,
            particleColor: currentSlide.highlightColor.withValues(alpha: 0.35),
            maxSpeed: 0.6,
          ),

          // Ambient Glow
          Positioned(
            top: -120,
            left: -100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentSlide.highlightColor.withValues(alpha: isDark ? 0.18 : 0.10),
                boxShadow: [
                  BoxShadow(
                    color: currentSlide.highlightColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Progress Bar & Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // PaperKit badge
                          Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: currentSlide.highlightColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(LucideIcons.sparkles, size: 14, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'PaperKit Tour',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),

                          // Skip Button
                          TextButton(
                            onPressed: _handleFinish,
                            style: TextButton.styleFrom(
                              foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            child: const Text(
                              'Skip Tour',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Linear Progress Track
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          height: 4,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progressPercent,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              decoration: BoxDecoration(
                                color: currentSlide.highlightColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Slide Carousel PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (idx) {
                      setState(() => _currentIndex = idx);
                      _startAutoPlay();
                    },
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: _SlideCard(slide: slide, isDark: isDark),
                      );
                    },
                  ),
                ),

                // Bottom Navigation Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      // Slide Dots Indicator
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_slides.length, (idx) {
                            final active = idx == _currentIndex;
                            return GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  idx,
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeInOutCubic,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                                width: active ? 22 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: active
                                      ? currentSlide.highlightColor
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Navigation Action Buttons
                      Row(
                        children: [
                          if (_currentIndex > 0)
                            Expanded(
                              flex: 1,
                              child: OutlinedButton.icon(
                                onPressed: _handlePrev,
                                icon: const Icon(LucideIcons.chevronLeft, size: 18),
                                label: const Text('Previous'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                                  side: BorderSide(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          if (_currentIndex > 0) const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _handleNext,
                              icon: Icon(
                                _currentIndex == _slides.length - 1
                                    ? LucideIcons.arrowRight
                                    : LucideIcons.chevronRight,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: Text(
                                _currentIndex == _slides.length - 1
                                    ? 'Get Started / Enter Studio'
                                    : 'Next Feature',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: currentSlide.highlightColor,
                                elevation: 4,
                                shadowColor: currentSlide.highlightColor.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideCard extends StatelessWidget {
  final _TourSlide slide;
  final bool isDark;

  const _SlideCard({required this.slide, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon Orb + Badge
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: slide.bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: slide.highlightColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(slide.icon, size: 28, color: slide.iconColor),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: slide.bgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: slide.highlightColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      slide.badge,
                      style: TextStyle(
                        color: slide.highlightColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Slide Title
          Text(
            slide.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            slide.subtitle,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          // Standard Slide Bullets
          if (!slide.isRateLimits) ...[
            ...slide.features.map(
              (feat) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: slide.highlightColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.checkCircle2,
                        size: 16,
                        color: slide.highlightColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Special Rate Limits Breakdown Slide
          if (slide.isRateLimits) ...[
            // PDF Limits Card
            _RateLimitItem(
              category: 'PDF Manipulation Tools',
              rule: slide.pdfRule ?? '≤ 15 pages per document',
              note: slide.pdfNote ?? '',
              tip: slide.pdfTip ?? '',
              color: const Color(0xFFDC2626),
              icon: LucideIcons.fileText,
              badgeText: 'PDF',
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            // AI Limits Card
            _RateLimitItem(
              category: 'AI Intelligence Features',
              rule: slide.aiRule ?? '5 requests per 1–4 hours',
              note: slide.aiNote ?? '',
              tip: slide.aiTip ?? '',
              color: const Color(0xFF7C3AED),
              icon: LucideIcons.brain,
              badgeText: 'AI',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Footer note for unlimited WASM tools
            ...slide.features.map(
              (feat) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle2, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RateLimitItem extends StatelessWidget {
  final String category;
  final String rule;
  final String note;
  final String tip;
  final Color color;
  final IconData icon;
  final String badgeText;
  final bool isDark;

  const _RateLimitItem({
    required this.category,
    required this.rule,
    required this.note,
    required this.tip,
    required this.color,
    required this.icon,
    required this.badgeText,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      rule,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.info, size: 12, color: isDark ? Colors.white54 : Colors.black45),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  note,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.alertTriangle, size: 12, color: Color(0xFFD97706)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD97706),
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
}

class _TourSlide {
  final int id;
  final String badge;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color highlightColor;
  final List<String> features;
  final bool isRateLimits;
  final String? pdfRule;
  final String? pdfNote;
  final String? pdfTip;
  final String? aiRule;
  final String? aiNote;
  final String? aiTip;

  const _TourSlide({
    required this.id,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.highlightColor,
    required this.features,
    this.isRateLimits = false,
    this.pdfRule,
    this.pdfNote,
    this.pdfTip,
    this.aiRule,
    this.aiNote,
    this.aiTip,
  });
}
