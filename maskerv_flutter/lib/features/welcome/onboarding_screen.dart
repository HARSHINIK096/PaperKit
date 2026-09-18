import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../core/providers/i18n_provider.dart';
import '../../core/widgets/language_selector_sheet.dart';
import '../../core/widgets/particle_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0;
  double _stepProgress = 0.0;
  bool _serverReady = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initServerReady();
    _startAutoTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initServerReady() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _serverReady = true;
        });
      }
    });
  }

  void _startAutoTimer() {
    _timer?.cancel();
    const intervalMs = 50;
    const totalCardTimeMs = 5000; // 5 seconds per card
    const increment = intervalMs / totalCardTimeMs;

    _timer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) return;
      setState(() {
        _stepProgress += increment;
        if (_stepProgress >= 1.0) {
          _stepProgress = 0.0;
          if (_currentIndex < 15) {
            _currentIndex += 1;
          } else {
            _timer?.cancel();
            _finishTour();
          }
        }
      });
    });
  }

  void _nextSlide(int totalSlides) {
    if (_currentIndex < totalSlides - 1) {
      setState(() {
        _currentIndex += 1;
        _stepProgress = 0.0;
      });
    } else {
      _finishTour();
    }
  }

  void _previousSlide(int totalSlides) {
    setState(() {
      _currentIndex = (_currentIndex - 1 + totalSlides) % totalSlides;
      _stepProgress = 0.0;
    });
  }

  Future<void> _finishTour() async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (mounted) {
      context.go('/welcome');
    }
  }

  List<_CloudTourSlide> _getSlides(BuildContext context) {
    return [
      _CloudTourSlide(
        id: 1,
        badge: context.t('ob_s1_badge'),
        title: context.t('ob_s1_title'),
        subtitle: context.t('ob_s1_sub'),
        icon: LucideIcons.sparkles,
        cloudColor1: const Color(0xFF0F172A),
        cloudColor2: const Color(0xFF1E3A8A),
        accentColor: const Color(0xFF3B82F6),
        features: [
          context.t('ob_s1_f1'),
          context.t('ob_s1_f2'),
          context.t('ob_s1_f3'),
        ],
        tags: const ['20+ Tools', 'Instant Convert', 'AI Intelligence'],
      ),
      _CloudTourSlide(
        id: 2,
        badge: context.t('ob_s2_badge'),
        title: context.t('ob_s2_title'),
        subtitle: context.t('ob_s2_sub'),
        icon: LucideIcons.shieldCheck,
        cloudColor1: const Color(0xFF022C22),
        cloudColor2: const Color(0xFF065F46),
        accentColor: const Color(0xFF10B981),
        features: [
          context.t('ob_s2_f1'),
          context.t('ob_s2_f2'),
          context.t('ob_s2_f3'),
        ],
        tags: const ['Offline WASM', 'Zero Uploads', 'Hardware Speed'],
      ),
      _CloudTourSlide(
        id: 3,
        badge: context.t('ob_s3_badge'),
        title: context.t('ob_s3_title'),
        subtitle: context.t('ob_s3_sub'),
        icon: LucideIcons.layers,
        cloudColor1: const Color(0xFF2E1065),
        cloudColor2: const Color(0xFF581C87),
        accentColor: const Color(0xFF8B5CF6),
        features: [
          context.t('ob_s3_f1'),
          context.t('ob_s3_f2'),
          context.t('ob_s3_f3'),
        ],
        tags: const ['Stack Files', 'Keep Bookmarks', 'Lossless Merge'],
      ),
      _CloudTourSlide(
        id: 4,
        badge: context.t('ob_s4_badge'),
        title: context.t('ob_s4_title'),
        subtitle: context.t('ob_s4_sub'),
        icon: LucideIcons.zap,
        cloudColor1: const Color(0xFF451A03),
        cloudColor2: const Color(0xFF78350F),
        accentColor: const Color(0xFFD97706),
        features: [
          context.t('ob_s4_f1'),
          context.t('ob_s4_f2'),
          context.t('ob_s4_f3'),
        ],
        tags: const ['90% Smaller', 'Vector Sharpness', 'Instant Shrink'],
      ),
      _CloudTourSlide(
        id: 5,
        badge: context.t('ob_s5_badge'),
        title: context.t('ob_s5_title'),
        subtitle: context.t('ob_s5_sub'),
        icon: LucideIcons.messageSquare,
        cloudColor1: const Color(0xFF172554),
        cloudColor2: const Color(0xFF1D4ED8),
        accentColor: const Color(0xFF60A5FA),
        features: [
          context.t('ob_s5_f1'),
          context.t('ob_s5_f2'),
          context.t('ob_s5_f3'),
        ],
        tags: const ['Document RAG', 'Citation Quotes', 'Study Notes'],
      ),
      _CloudTourSlide(
        id: 6,
        badge: context.t('ob_s6_badge'),
        title: context.t('ob_s6_title'),
        subtitle: context.t('ob_s6_sub'),
        icon: LucideIcons.table,
        cloudColor1: const Color(0xFF064E3B),
        cloudColor2: const Color(0xFF047857),
        accentColor: const Color(0xFF34D399),
        features: [
          context.t('ob_s6_f1'),
          context.t('ob_s6_f2'),
          context.t('ob_s6_f3'),
        ],
        tags: const ['CSV / Excel Export', 'Auto Detection', 'Clean Data'],
      ),
      _CloudTourSlide(
        id: 7,
        badge: context.t('ob_s7_badge'),
        title: context.t('ob_s7_title'),
        subtitle: context.t('ob_s7_sub'),
        icon: LucideIcons.scanText,
        cloudColor1: const Color(0xFF3B0764),
        cloudColor2: const Color(0xFF6D28D9),
        accentColor: const Color(0xFFA78BFA),
        features: [
          context.t('ob_s7_f1'),
          context.t('ob_s7_f2'),
          context.t('ob_s7_f3'),
        ],
        tags: const ['20+ Languages', 'Searchable PDF', 'Scan to Text'],
      ),
      _CloudTourSlide(
        id: 8,
        badge: context.t('ob_s8_badge'),
        title: context.t('ob_s8_title'),
        subtitle: context.t('ob_s8_sub'),
        icon: LucideIcons.shieldAlert,
        cloudColor1: const Color(0xFF450A0A),
        cloudColor2: const Color(0xFF991B1B),
        accentColor: const Color(0xFFEF4444),
        features: [
          context.t('ob_s8_f1'),
          context.t('ob_s8_f2'),
          context.t('ob_s8_f3'),
        ],
        tags: const ['Zero Recovery', 'Regex Redact', 'PII Purge'],
      ),
      _CloudTourSlide(
        id: 9,
        badge: context.t('ob_s9_badge'),
        title: context.t('ob_s9_title'),
        subtitle: context.t('ob_s9_sub'),
        icon: LucideIcons.penTool,
        cloudColor1: const Color(0xFF1E1B4B),
        cloudColor2: const Color(0xFF3730A3),
        accentColor: const Color(0xFF6366F1),
        features: [
          context.t('ob_s9_f1'),
          context.t('ob_s9_f2'),
          context.t('ob_s9_f3'),
        ],
        tags: const ['e-Signatures', 'Watermark Stamp', 'AES-256 Lock'],
      ),
      _CloudTourSlide(
        id: 10,
        badge: context.t('ob_s10_badge'),
        title: context.t('ob_s10_title'),
        subtitle: context.t('ob_s10_sub'),
        icon: LucideIcons.archive,
        cloudColor1: const Color(0xFF3F2C03),
        cloudColor2: const Color(0xFF854D0E),
        accentColor: const Color(0xFFFBBF24),
        features: [
          context.t('ob_s10_f1'),
          context.t('ob_s10_f2'),
          context.t('ob_s10_f3'),
        ],
        tags: const ['ISO 19005', 'Font Embedding', '50-Year Safe'],
      ),
      _CloudTourSlide(
        id: 11,
        badge: context.t('ob_s11_badge'),
        title: context.t('ob_s11_title'),
        subtitle: context.t('ob_s11_sub'),
        icon: LucideIcons.grid,
        cloudColor1: const Color(0xFF064E3B),
        cloudColor2: const Color(0xFF0F766E),
        accentColor: const Color(0xFF14B8A6),
        features: [
          context.t('ob_s11_f1'),
          context.t('ob_s11_f2'),
          context.t('ob_s11_f3'),
        ],
        tags: const ['Thumbnail Grid', 'Rotate 90°/180°', 'Page Split'],
      ),
      _CloudTourSlide(
        id: 12,
        badge: context.t('ob_s12_badge'),
        title: context.t('ob_s12_title'),
        subtitle: context.t('ob_s12_sub'),
        icon: LucideIcons.globe,
        cloudColor1: const Color(0xFF2E1065),
        cloudColor2: const Color(0xFF5B21B6),
        accentColor: const Color(0xFF8B5CF6),
        features: [
          context.t('ob_s12_f1'),
          context.t('ob_s12_f2'),
          context.t('ob_s12_f3'),
        ],
        tags: const ['10+ Languages', 'Offline-First', 'Universal App'],
      ),
      _CloudTourSlide(
        id: 13,
        badge: context.t('ob_s13_badge'),
        title: context.t('ob_s13_title'),
        subtitle: context.t('ob_s13_sub'),
        icon: LucideIcons.cpu,
        cloudColor1: const Color(0xFF1E3A8A),
        cloudColor2: const Color(0xFF2563EB),
        accentColor: const Color(0xFF60A5FA),
        features: [
          context.t('ob_s13_f1'),
          context.t('ob_s13_f2'),
          context.t('ob_s13_f3'),
        ],
        tags: const ['Semantic Diff', 'Auto-Tagging', 'Vector Search'],
      ),
      _CloudTourSlide(
        id: 14,
        badge: context.t('ob_s14_badge'),
        title: context.t('ob_s14_title'),
        subtitle: context.t('ob_s14_sub'),
        icon: LucideIcons.clapperboard,
        cloudColor1: const Color(0xFF0C4A6E),
        cloudColor2: const Color(0xFF0284C7),
        accentColor: const Color(0xFF38BDF8),
        features: [
          context.t('ob_s14_f1'),
          context.t('ob_s14_f2'),
          context.t('ob_s14_f3'),
        ],
        tags: const ['Frame Extract', 'ZIP Export', '≤ 180s Duration', 'Render Safe'],
      ),
      _CloudTourSlide(
        id: 15,
        badge: context.t('ob_s15_badge'),
        title: context.t('ob_s15_title'),
        subtitle: context.t('ob_s15_sub'),
        icon: LucideIcons.qrCode,
        cloudColor1: const Color(0xFF064E3B),
        cloudColor2: const Color(0xFF059669),
        accentColor: const Color(0xFF34D399),
        features: [
          context.t('ob_s15_f1'),
          context.t('ob_s15_f2'),
          context.t('ob_s15_f3'),
        ],
        tags: const ['AES-256-GCM', '10-Min Expiry', 'Zero Plaintext', '≤ 50 MB'],
      ),
      _CloudTourSlide(
        id: 16,
        isRateLimits: true,
        badge: context.t('ob_s16_badge'),
        title: context.t('ob_s16_title'),
        subtitle: context.t('ob_s16_sub'),
        icon: LucideIcons.gauge,
        cloudColor1: const Color(0xFF431407),
        cloudColor2: const Color(0xFF9A3412),
        accentColor: const Color(0xFFF97316),
        features: [
          context.t('ob_s16_f1'),
          context.t('ob_s16_f2'),
          context.t('ob_s16_f3'),
        ],
        tags: const ['Fair Use', 'Auto-Reset', '100% Free', 'Render Guard'],
        rateLimits: [
          _RateLimitItem(
            title: 'PDF Manipulation Tools',
            rule: '≤ 15 pages per document',
            note: 'Merge, Split, Compress, Rotate, Watermark, Edit & PDF converters.',
            tip: 'Split large PDFs into chunks under 15 pages. Offline WASM mode is unlimited.',
            accentColor: const Color(0xFFF87171),
            icon: LucideIcons.fileText,
          ),
          _RateLimitItem(
            title: 'Video & Frame Extraction',
            rule: '≤ 180s • ≤ 100 MB',
            note: 'Frame extraction (FPS, interval, timestamps), trim, crop & editor.',
            tip: 'Capped to 180s duration and 300 preview frames for Render stability.',
            accentColor: const Color(0xFF38BDF8),
            icon: LucideIcons.film,
          ),
          _RateLimitItem(
            title: '10-Min Encrypted Share',
            rule: '10m expiry • ≤ 50 MB',
            note: 'AES-256-GCM encrypted temporary storage with zero-knowledge QR URL.',
            tip: 'Server-authoritative 10m hard expiry (410 Gone). Max 5 password attempts.',
            accentColor: const Color(0xFF34D399),
            icon: LucideIcons.shieldCheck,
          ),
          _RateLimitItem(
            title: 'AI Intelligence Features',
            rule: '5 reqs per 1–4 hours',
            note: 'Summarize, Ask PDF, OCR, Translate, Tables & all AI tools.',
            tip: 'Limits reset automatically. Independent counter per tool category.',
            accentColor: const Color(0xFFA78BFA),
            icon: LucideIcons.brain,
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final slides = _getSlides(context);
    final slide = slides[_currentIndex.clamp(0, slides.length - 1)];

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -200) {
            _nextSlide(slides.length);
          } else if (details.primaryVelocity! > 200) {
            _previousSlide(slides.length);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.3),
              radius: 1.35,
              colors: [
                slide.cloudColor2,
                slide.cloudColor1,
                const Color(0xFF030712),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Dynamic Cloud Particle Layer
              ParticleBackground(
                numberOfParticles: 35,
                particleColor: slide.accentColor.withValues(alpha: 0.55),
                maxSpeed: 0.7,
              ),

              // 1. Right Bottom Cloud Glow Orb
              Positioned(
                bottom: -60,
                right: -50,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 1400),
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: slide.accentColor.withValues(alpha: 0.22),
                    boxShadow: [
                      BoxShadow(
                        color: slide.accentColor.withValues(alpha: 0.35),
                        blurRadius: 110,
                        spreadRadius: 25,
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Left Center Cloud Glow Orb
              Positioned(
                top: MediaQuery.of(context).size.height * 0.35,
                left: -70,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 1400),
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: slide.cloudColor2.withValues(alpha: 0.30),
                    boxShadow: [
                      BoxShadow(
                        color: slide.cloudColor2.withValues(alpha: 0.40),
                        blurRadius: 100,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Row: Progress Bars + optional Skip button
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Progress bar segments
                                  Expanded(
                                    child: Row(
                                      children: List.generate(slides.length, (idx) {
                                        double val = 0.0;
                                        if (idx < _currentIndex) {
                                          val = 1.0;
                                        } else if (idx == _currentIndex) {
                                          val = _stepProgress;
                                        }
                                        return Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _currentIndex = idx;
                                                _stepProgress = 0.0;
                                              });
                                            },
                                            child: Container(
                                              height: 4,
                                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                              child: FractionallySizedBox(
                                                alignment: Alignment.centerLeft,
                                                widthFactor: val,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(2),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: slide.accentColor.withValues(alpha: 0.8),
                                                        blurRadius: 4,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),

                                // Quick Language Switcher Pill
                                GestureDetector(
                                  onTap: () => LanguageSelectorSheet.show(context),
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.35),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          context.watch<I18nProvider>().currentAppLanguage.flag,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          context.watch<I18nProvider>().currentAppLanguage.countryCode,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Skip button — appears with fade+slide when server pings back
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  transitionBuilder: (child, anim) => FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.4, 0),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: anim,
                                        curve: Curves.easeOutCubic,
                                      )),
                                      child: child,
                                    ),
                                  ),
                                  child: _serverReady
                                      ? GestureDetector(
                                          key: const ValueKey('skip_btn'),
                                          onTap: _finishTour,
                                          child: Container(
                                            margin: const EdgeInsets.only(left: 6),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.35),
                                                width: 1.2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: slide.accentColor.withValues(alpha: 0.35),
                                                  blurRadius: 10,
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    context.t('ob_skip'),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: Colors.white.withValues(alpha: 0.9),
                                                      fontSize: 11.5,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  LucideIcons.skipForward,
                                                  size: 13,
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(key: ValueKey('skip_hidden')),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Animated Cloud Slide Card
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 700),
                              transitionBuilder: (child, anim) => FadeTransition(
                                opacity: anim,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                                  ),
                                  child: child,
                                ),
                              ),
                              child: Container(
                                key: ValueKey<int>(_currentIndex),
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1.4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: slide.cloudColor2.withValues(alpha: 0.45),
                                      blurRadius: 40,
                                      offset: const Offset(0, 16),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header Orb & Badge
                                    Row(
                                      children: [
                                        Container(
                                          width: 58,
                                          height: 58,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.16),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: slide.accentColor.withValues(alpha: 0.5),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: slide.accentColor.withValues(alpha: 0.4),
                                                blurRadius: 16,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Icon(
                                              slide.icon,
                                              size: 30,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: slide.accentColor.withValues(alpha: 0.4),
                                                ),
                                              ),
                                              child: Text(
                                                slide.badge,
                                                style: TextStyle(
                                                  color: slide.accentColor,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Title
                                    Text(
                                      slide.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Subtitle
                                    Text(
                                      slide.subtitle,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 13,
                                        height: 1.45,
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    // Features List
                                    if (!slide.isRateLimits) ...[
                                      ...slide.features.map(
                                        (feat) => Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                margin: const EdgeInsets.only(top: 2),
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: slide.accentColor.withValues(alpha: 0.25),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  LucideIcons.checkCircle2,
                                                  size: 15,
                                                  color: slide.accentColor,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  feat,
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                    height: 1.35,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],

                                    // Rate Limits Breakdown (Slide 16)
                                    if (slide.isRateLimits) ...[
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight: MediaQuery.of(context).size.height > 780 ? 270 : 210,
                                        ),
                                        child: RawScrollbar(
                                          thumbColor: slide.accentColor.withValues(alpha: 0.5),
                                          radius: const Radius.circular(4),
                                          thickness: 3,
                                          child: SingleChildScrollView(
                                            physics: const BouncingScrollPhysics(),
                                            child: Column(
                                              children: [
                                                if (slide.rateLimits != null && slide.rateLimits!.isNotEmpty) ...[
                                                  for (int i = 0; i < slide.rateLimits!.length; i++) ...[
                                                    if (i > 0) const SizedBox(height: 8),
                                                    _RateLimitCloudCard(
                                                      title: slide.rateLimits![i].title,
                                                      rule: slide.rateLimits![i].rule,
                                                      note: slide.rateLimits![i].note,
                                                      tip: slide.rateLimits![i].tip,
                                                      accentColor: slide.rateLimits![i].accentColor,
                                                      icon: slide.rateLimits![i].icon,
                                                    ),
                                                  ],
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      ...slide.features.map(
                                        (feat) => Padding(
                                          padding: const EdgeInsets.only(bottom: 5),
                                          child: Row(
                                            children: [
                                              const Icon(LucideIcons.checkCircle2, size: 14, color: Color(0xFF34D399)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  feat,
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white.withValues(alpha: 0.85),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 14),

                                    // Capability Tags
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: slide.tags.map((tag) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.25),
                                            ),
                                          ),
                                          child: Text(
                                            tag,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Continuous Auto-Presentation Cloud Beacon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Previous Button
                                IconButton(
                                  onPressed: _currentIndex > 0 ? () => _previousSlide(slides.length) : null,
                                  icon: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 22),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.04),
                                  ),
                                ),

                                // Status Beacon & Indicators
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: slide.accentColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: slide.accentColor.withValues(alpha: 0.8),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Card ${_currentIndex + 1} of ${slides.length}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),

                                // Next / Continue to Welcome Page Button
                                _currentIndex == slides.length - 1
                                    ? ElevatedButton.icon(
                                        onPressed: _finishTour,
                                        icon: const Icon(LucideIcons.sparkles, size: 16),
                                        label: const Text(
                                          'Welcome Page',
                                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: slide.accentColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        ),
                                      )
                                    : IconButton(
                                        onPressed: () => _nextSlide(slides.length),
                                        icon: const Icon(LucideIcons.chevronRight, color: Colors.white, size: 22),
                                        style: IconButton.styleFrom(
                                          backgroundColor: slide.accentColor.withValues(alpha: 0.8),
                                        ),
                                      ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _RateLimitItem {
  final String title;
  final String rule;
  final String note;
  final String tip;
  final Color accentColor;
  final IconData icon;

  const _RateLimitItem({
    required this.title,
    required this.rule,
    required this.note,
    required this.tip,
    required this.accentColor,
    required this.icon,
  });
}

class _RateLimitCloudCard extends StatelessWidget {
  final String title;
  final String rule;
  final String note;
  final String tip;
  final Color accentColor;
  final IconData icon;

  const _RateLimitCloudCard({
    required this.title,
    required this.rule,
    required this.note,
    required this.tip,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rule,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            note,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1.5),
                child: Icon(LucideIcons.alertTriangle, size: 10, color: Color(0xFFFBBF24)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  tip,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFBBF24),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CloudTourSlide {
  final int id;
  final String badge;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color cloudColor1;
  final Color cloudColor2;
  final Color accentColor;
  final List<String> features;
  final List<String> tags;
  final bool isRateLimits;
  final List<_RateLimitItem>? rateLimits;

  const _CloudTourSlide({
    required this.id,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.cloudColor1,
    required this.cloudColor2,
    required this.accentColor,
    required this.features,
    required this.tags,
    this.isRateLimits = false,
    this.rateLimits,
  });
}
