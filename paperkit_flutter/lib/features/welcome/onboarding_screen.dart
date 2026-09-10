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
  int _currentIndex = 0;
  Timer? _progressTicker;
  Timer? _cloudBootPoller;
  double _stepProgress = 0.0;

  // 14 Superpower Slides with COC-style vibrant gradient cloud backgrounds
  final List<_CloudTourSlide> _slides = [
    const _CloudTourSlide(
      id: 1,
      badge: 'Universal PDF Studio',
      title: 'Your Ultimate PDF & Document Studio',
      subtitle: 'All-in-one document intelligence, local WebAssembly tools, and deep AI capabilities.',
      icon: LucideIcons.sparkles,
      cloudColor1: Color(0xFF0F172A),
      cloudColor2: Color(0xFF1E3A8A),
      accentColor: Color(0xFF3B82F6),
      features: [
        'Universal PDF processing suite with 20+ specialized tools',
        'Instant document conversion, compression, & editing',
        'Deep AI intelligence for summaries & Q&A analysis',
      ],
      tags: ['20+ Tools', 'Instant Convert', 'AI Intelligence'],
    ),
    const _CloudTourSlide(
      id: 2,
      badge: '100% Private Processing',
      title: 'Offline Client-Side WASM Core',
      subtitle: 'Your documents never leave your device memory with zero server uploads.',
      icon: LucideIcons.shieldCheck,
      cloudColor1: Color(0xFF022C22),
      cloudColor2: Color(0xFF065F46),
      accentColor: Color(0xFF10B981),
      features: [
        'Zero server upload requirement for standard PDF tools',
        'Bank-grade privacy for confidential & proprietary documents',
        'Lightning-fast execution directly on your CPU/GPU',
      ],
      tags: ['Offline WASM', 'Zero Uploads', 'Hardware Speed'],
    ),
    const _CloudTourSlide(
      id: 3,
      badge: 'Document Merging',
      title: 'Combine & Stack Multi-Format Files',
      subtitle: 'Merge hundreds of PDFs, CAD drawings, lab manuals, and image files into one structured document.',
      icon: LucideIcons.layers,
      cloudColor1: Color(0xFF2E1065),
      cloudColor2: Color(0xFF581C87),
      accentColor: Color(0xFF8B5CF6),
      features: [
        'Drag-and-drop page ordering & document stacking',
        'Preserve original bookmarks, vector fonts, and layout',
        'Instant preview before generating final compilation',
      ],
      tags: ['Stack Files', 'Keep Bookmarks', 'Lossless Merge'],
    ),
    const _CloudTourSlide(
      id: 4,
      badge: 'Smart Compression',
      title: 'Reduce File Size up to 90%',
      subtitle: 'Intelligent vector and image compression shrinks heavy PDFs for quick portal uploads.',
      icon: LucideIcons.zap,
      cloudColor1: Color(0xFF451A03),
      cloudColor2: Color(0xFF78350F),
      accentColor: Color(0xFFD97706),
      features: [
        'Multiple compression levels: Extreme, Recommended, & Light',
        'Retains sharp text and vector diagrams at high DPI',
        'Real-time estimated file size reduction preview',
      ],
      tags: ['90% Smaller', 'Vector Sharpness', 'Instant Shrink'],
    ),
    const _CloudTourSlide(
      id: 5,
      badge: 'Ask PDF AI',
      title: 'Interactive AI Document Q&A',
      subtitle: 'Chat directly with long textbooks, research papers, and technical manuals with page citations.',
      icon: LucideIcons.messageSquare,
      cloudColor1: Color(0xFF172554),
      cloudColor2: Color(0xFF1D4ED8),
      accentColor: Color(0xFF60A5FA),
      features: [
        'Context-aware answers with exact page reference quotes',
        'Multi-document chat for comparing multiple sources',
        'Export Q&A transcripts into study notes or summaries',
      ],
      tags: ['Document RAG', 'Citation Quotes', 'Study Notes'],
    ),
    const _CloudTourSlide(
      id: 6,
      badge: 'AI Table Extraction',
      title: 'Convert Document Data to CSV/Excel',
      subtitle: 'Automatically detect and extract complex tables, lab datasets, and financial statements.',
      icon: LucideIcons.table,
      cloudColor1: Color(0xFF064E3B),
      cloudColor2: Color(0xFF047857),
      accentColor: Color(0xFF34D399),
      features: [
        'Detects structured & unbordered table boundaries',
        'One-click export to clean CSV, JSON, or Excel sheets',
        'Automatic mathematical & numerical format validation',
      ],
      tags: ['CSV / Excel Export', 'Auto Detection', 'Clean Data'],
    ),
    const _CloudTourSlide(
      id: 7,
      badge: 'OCR Recognition',
      title: 'Turn Scans into Searchable Text',
      subtitle: 'High-precision optical character recognition converts paper scans into searchable text.',
      icon: LucideIcons.scanText,
      cloudColor1: Color(0xFF3B0764),
      cloudColor2: Color(0xFF6D28D9),
      accentColor: Color(0xFFA78BFA),
      features: [
        'Multi-language OCR engine supporting 20+ languages',
        'Preserves original document layout and paragraphing',
        'Generates searchable PDF/A overlay layers',
      ],
      tags: ['20+ Languages', 'Searchable PDF', 'Scan to Text'],
    ),
    const _CloudTourSlide(
      id: 8,
      badge: 'Smart Redaction',
      title: 'Permanent PII & Data Sanitization',
      subtitle: 'Blackout sensitive names, social security numbers, passwords, and addresses permanently.',
      icon: LucideIcons.shieldAlert,
      cloudColor1: Color(0xFF450A0A),
      cloudColor2: Color(0xFF991B1B),
      accentColor: Color(0xFFEF4444),
      features: [
        'Automated regex pattern scanning (Emails, SSNs, Phones)',
        'Destroys underlying vector text data — zero recovery',
        'Sanitizes hidden metadata & revision histories',
      ],
      tags: ['Zero Recovery', 'Regex Redact', 'PII Purge'],
    ),
    const _CloudTourSlide(
      id: 9,
      badge: 'Signatures & Watermarks',
      title: 'Digital Signing & Document Protection',
      subtitle: 'Add cryptographic signatures, visual stamp signatures, watermarks, and password encryption.',
      icon: LucideIcons.penTool,
      cloudColor1: Color(0xFF1E1B4B),
      cloudColor2: Color(0xFF3730A3),
      accentColor: Color(0xFF6366F1),
      features: [
        'Draw, type, or upload custom e-signatures',
        'Custom text or image watermarks with opacity control',
        'AES-256 password protection & permission restriction',
      ],
      tags: ['e-Signatures', 'Watermark Stamp', 'AES-256 Lock'],
    ),
    const _CloudTourSlide(
      id: 10,
      badge: 'ISO PDF/A Archiving',
      title: 'Long-Term Preserved Compliance',
      subtitle: 'Convert standard documents into ISO 19005 compliant PDF/A format for records.',
      icon: LucideIcons.archive,
      cloudColor1: Color(0xFF3F2C03),
      cloudColor2: Color(0xFF854D0E),
      accentColor: Color(0xFFFBBF24),
      features: [
        'Embeds all fonts, color profiles, & metadata standards',
        'Ensures document renders identically 50 years from now',
        'Built-in compliance checking & validation report',
      ],
      tags: ['ISO 19005', 'Font Embedding', '50-Year Safe'],
    ),
    const _CloudTourSlide(
      id: 11,
      badge: 'Visual Page Organizer',
      title: 'Reorder, Rotate, Split & Duplicate',
      subtitle: 'Visual thumbnail grid lets you manage individual PDF pages with simple drag actions.',
      icon: LucideIcons.grid,
      cloudColor1: Color(0xFF064E3B),
      cloudColor2: Color(0xFF0F766E),
      accentColor: Color(0xFF14B8A6),
      features: [
        'Rotate upside-down pages by 90°, 180°, or 270°',
        'Extract custom page ranges into standalone PDFs',
        'Delete blank pages or duplicate important slides',
      ],
      tags: ['Thumbnail Grid', 'Rotate 90°/180°', 'Page Split'],
    ),
    const _CloudTourSlide(
      id: 12,
      badge: 'Multi-Language Compactability',
      title: 'Native Mobile & Offline App',
      subtitle: 'Full interface translation across 10+ languages with native mobile app experience.',
      icon: LucideIcons.globe,
      cloudColor1: Color(0xFF2E1065),
      cloudColor2: Color(0xFF5B21B6),
      accentColor: Color(0xFF8B5CF6),
      features: [
        'Seamless multi-language switching (English, Spanish, Hindi, etc.)',
        'Native hardware performance on Android & iOS',
        'Offline-first architecture — works without active internet',
      ],
      tags: ['10+ Languages', 'Offline-First', 'Universal App'],
    ),
    const _CloudTourSlide(
      id: 13,
      badge: 'Cloud AI Intelligence',
      title: 'Deep Document Analytics & Cloud Engine',
      subtitle: 'Real-time cloud sync powers semantic document comparison and vector similarity matrices.',
      icon: LucideIcons.cpu,
      cloudColor1: Color(0xFF1E3A8A),
      cloudColor2: Color(0xFF2563EB),
      accentColor: Color(0xFF60A5FA),
      features: [
        'Semantic document comparison highlighting hidden changes',
        'AI Document classification and auto-tagging system',
        'High-throughput vector search across massive archives',
      ],
      tags: ['Semantic Diff', 'Auto-Tagging', 'Vector Search'],
    ),
    const _CloudTourSlide(
      id: 14,
      isRateLimits: true,
      badge: 'Fair Use Policy',
      title: 'Usage Limits & Fair Access',
      subtitle: 'To keep performance fast and reliable for everyone, fair usage limits apply on shared cloud infrastructure.',
      icon: LucideIcons.gauge,
      cloudColor1: Color(0xFF431407),
      cloudColor2: Color(0xFF9A3412),
      accentColor: Color(0xFFF97316),
      features: [
        'Limits reset automatically — no account required',
        'Client-side WASM PDF tools are always unlimited',
      ],
      tags: ['Fair Use', 'Auto-Reset', '100% Free'],
      pdfRule: '≤ 15 pages per document',
      pdfNote: 'Merge, Split, Compress, Rotate, Watermark, Edit & all PDF tools.',
      pdfTip: 'Split large PDFs into chunks under 15 pages before processing.',
      aiRule: '5 requests per 1–4 hours',
      aiNote: 'Summarize, Ask PDF, OCR, Translate, Tables & all AI tools.',
      aiTip: 'Limits reset automatically. Each AI tool category has an independent counter.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoTransition();
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

  void _startAutoTransition() {
    // 5000ms duration per slide (5 seconds permanent auto transition)
    const slideDurationMs = 5000;
    const tickIntervalMs = 50;
    const step = tickIntervalMs / slideDurationMs;

    _progressTicker = Timer.periodic(const Duration(milliseconds: tickIntervalMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _stepProgress = (_stepProgress + step).clamp(0.0, 1.0);
      });

      if (_stepProgress >= 1.0) {
        _stepProgress = 0.0;
        if (_currentIndex < _slides.length - 1) {
          HapticFeedback.lightImpact();
          setState(() {
            _currentIndex++;
          });
        } else {
          // Completed all 14 slides (70 seconds total tour showcase)
          timer.cancel();
          _finishTour();
        }
      }
    });
  }

  Future<void> _finishTour() async {
    _progressTicker?.cancel();
    _cloudBootPoller?.cancel();
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
    _progressTicker?.cancel();
    _cloudBootPoller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];

    return Scaffold(
      body: AnimatedContainer(
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // Top Progress Bar Track (14-Step Progress)
                    Row(
                      children: List.generate(_slides.length, (idx) {
                        double val = 0.0;
                        if (idx < _currentIndex) {
                          val = 1.0;
                        } else if (idx == _currentIndex) {
                          val = _stepProgress;
                        }
                        return Expanded(
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
                        );
                      }),
                    ),

                    const Spacer(flex: 2),

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
                        padding: const EdgeInsets.all(26),
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

                            // Rate Limits Breakdown (Slide 14)
                            if (slide.isRateLimits) ...[
                              _RateLimitCloudCard(
                                title: 'PDF Manipulation Tools',
                                rule: slide.pdfRule ?? '≤ 15 pages per document',
                                note: slide.pdfNote ?? '',
                                tip: slide.pdfTip ?? '',
                                accentColor: const Color(0xFFF87171),
                                icon: LucideIcons.fileText,
                              ),
                              const SizedBox(height: 10),
                              _RateLimitCloudCard(
                                title: 'AI Intelligence Features',
                                rule: slide.aiRule ?? '5 requests per 1–4 hours',
                                note: slide.aiNote ?? '',
                                tip: slide.aiTip ?? '',
                                accentColor: const Color(0xFFA78BFA),
                                icon: LucideIcons.brain,
                              ),
                              const SizedBox(height: 12),
                              ...slide.features.map(
                                (feat) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
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

                    const Spacer(flex: 3),

                    // Continuous Auto-Presentation Cloud Beacon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                          'Step ${_currentIndex + 1} of ${_slides.length} • Initializing Cloud Studio...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                rule,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(LucideIcons.alertTriangle, size: 11, color: Color(0xFFFBBF24)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  tip,
                  style: const TextStyle(
                    fontSize: 10.5,
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
  final String? pdfRule;
  final String? pdfNote;
  final String? pdfTip;
  final String? aiRule;
  final String? aiNote;
  final String? aiTip;

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
    this.pdfRule,
    this.pdfNote,
    this.pdfTip,
    this.aiRule,
    this.aiNote,
    this.aiTip,
  });
}
