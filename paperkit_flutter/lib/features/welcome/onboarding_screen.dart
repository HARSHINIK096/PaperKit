import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/widgets/particle_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0;
  Timer? _autoAdvanceTimer;
  Timer? _progressTicker;
  double _stepProgress = 0.0;

  // 14 Superpower Slides with COC-style vibrant gradient cloud backgrounds
  final List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      title: 'Intelligent PDF Studio',
      subtitle: 'Merge, Split, Rotate & Reorder with Zero Cloud Uploads',
      description: 'Lightning-fast client-side document processing with total privacy preservation.',
      icon: LucideIcons.files,
      color1: const Color(0xFF1E3A8A), // Navy
      color2: const Color(0xFF3B82F6), // Blue
      accentColor: const Color(0xFF60A5FA),
      tags: ['Merge PDF', 'Split PDF', 'Extract Pages', 'Organize'],
    ),
    _OnboardingSlide(
      title: 'AI Document Chat & RAG',
      subtitle: 'Interactive Q&A and Fact Extraction with Multipage Docs',
      description: 'Conversational artificial intelligence that indexes your files and answers exact queries.',
      icon: LucideIcons.messageSquare,
      color1: const Color(0xFF4C1D95), // Deep Purple
      color2: const Color(0xFF8B5CF6), // Violet
      accentColor: const Color(0xFFA78BFA),
      tags: ['Ask PDF', 'Context Q&A', 'Citation Tracing'],
    ),
    _OnboardingSlide(
      title: 'Multimodal Vision OCR',
      subtitle: 'Digitize Scans, Photos & Invoices Instantly',
      description: 'State-of-the-art vision models extract text, tables, and document hierarchies from camera scans.',
      icon: LucideIcons.scanLine,
      color1: const Color(0xFF0F766E), // Deep Teal
      color2: const Color(0xFF14B8A6), // Cyan
      accentColor: const Color(0xFF5EEAD4),
      tags: ['OCR Scanner', 'Table Detection', 'Photo to Text'],
    ),
    _OnboardingSlide(
      title: 'Universal Document Conversions',
      subtitle: 'Bidirectional Word, Excel, PPT & Image Conversions',
      description: 'Convert DOCX, XLSX, PPTX and photos into pixel-perfect PDF documents and vice-versa.',
      icon: LucideIcons.fileSpreadsheet,
      color1: const Color(0xFF065F46), // Dark Emerald
      color2: const Color(0xFF10B981), // Emerald
      accentColor: const Color(0xFF6EE7B7),
      tags: ['Word to PDF', 'PDF to Excel', 'PPT to PDF', 'Images'],
    ),
    _OnboardingSlide(
      title: 'AES-256 PDF Security',
      subtitle: 'Military-Grade Encryption & Permission Controls',
      description: 'Lock your confidential documents with 256-bit encryption, printing blocks & view restrictions.',
      icon: LucideIcons.lock,
      color1: const Color(0xFF881337), // Crimson
      color2: const Color(0xFFE11D48), // Rose
      accentColor: const Color(0xFFFDA4AF),
      tags: ['Password Protect', 'Permission Locks', 'Audit Trail'],
    ),
    _OnboardingSlide(
      title: 'Smart PII Data Redaction',
      subtitle: 'Permanent Blackouts & Sensitive Data Sanitization',
      description: 'AI-assisted privacy scanner detects social security, credit cards, emails and permanently purges them.',
      icon: LucideIcons.eyeOff,
      color1: const Color(0xFF7C2D12), // Deep Amber/Orange
      color2: const Color(0xFFEA580C), // Orange
      accentColor: const Color(0xFFFDBA74),
      tags: ['Smart Redact', 'PII Detection', 'Metadata Wipe'],
    ),
    _OnboardingSlide(
      title: 'In-Place PDF Editor',
      subtitle: 'Edit Text, Markup Annotations & Draw Shapes',
      description: 'Professional visual document workspace with freehand drawings, stamps, and object placement.',
      icon: LucideIcons.fileSignature,
      color1: const Color(0xFF581C87), // Deep Violet
      color2: const Color(0xFF9333EA), // Purple
      accentColor: const Color(0xFFD8B4FE),
      tags: ['Text Editing', 'Draw & Stamp', 'Form Filler'],
    ),
    _OnboardingSlide(
      title: 'Lossless PDF Compression',
      subtitle: 'Shrink Huge Documents Up to 90% in Size',
      description: 'Multi-level compression optimization with Extreme, Recommended, and Custom presets.',
      icon: LucideIcons.minimize2,
      color1: const Color(0xFF78350F), // Amber
      color2: const Color(0xFFD97706), // Gold
      accentColor: const Color(0xFFFDE68A),
      tags: ['Extreme Compression', 'Vector Optimizer', 'Fast Shrink'],
    ),
    _OnboardingSlide(
      title: 'Image Converter & Adjuster',
      subtitle: 'Convert PNG, JPG, WebP, HEIC & Adjust Filters',
      description: 'High-speed image format transformation with brightness, contrast, invert & rotation controls.',
      icon: LucideIcons.sliders,
      color1: const Color(0xFF831843), // Pink
      color2: const Color(0xFFDB2777), // Hot Pink
      accentColor: const Color(0xFFF472B6),
      tags: ['Format Convert', 'Compressor', 'Color Adjuster'],
    ),
    _OnboardingSlide(
      title: 'High-Speed Media Downloader',
      subtitle: 'Download YouTube Videos & Spotify Audio Tracks',
      description: 'Directly extract high-definition MP4 videos and crystal-clear MP3 songs without ads or watermarks.',
      icon: LucideIcons.downloadCloud,
      color1: const Color(0xFF991B1B), // Red
      color2: const Color(0xFFEF4444), // Scarlet
      accentColor: const Color(0xFFFCA5A5),
      tags: ['YouTube HD', 'Spotify MP3', 'High Bitrate'],
    ),
    _OnboardingSlide(
      title: 'Video & Audio Studio',
      subtitle: 'FFmpeg-Powered MP4, WebM, MOV, GIF, MP3 & WAV',
      description: 'Professional multimedia encoding, compression and format conversion directly inside PaperKit.',
      icon: LucideIcons.video,
      color1: const Color(0xFF1E1B4B), // Indigo
      color2: const Color(0xFF6366F1), // Royal Indigo
      accentColor: const Color(0xFFA5B4FC),
      tags: ['Convert Video', 'Video Compressor', 'Audio Studio'],
    ),
    _OnboardingSlide(
      title: 'Archive & Compression Studio',
      subtitle: 'ZIP, RAR, TAR, GZ, 7Z & BZ2 Multi-Format Suite',
      description: 'Pack, extract, inspect, and convert multi-level compressed archive bundles effortlessly.',
      icon: LucideIcons.archive,
      color1: const Color(0xFF134E4A), // Teal
      color2: const Color(0xFF0D9488), // Teal
      accentColor: const Color(0xFF99F6E4),
      tags: ['Create ZIP', 'Extract 7Z/RAR', 'Pack TAR.GZ'],
    ),
    _OnboardingSlide(
      title: 'Semantic Document Compare',
      subtitle: 'Detect Critical Meaning & Revision Changes',
      description: 'Side-by-side AI comparative analysis highlighting financial, structural, and legal modifications.',
      icon: LucideIcons.gitCompare,
      color1: const Color(0xFF312E81), // Blue Indigo
      color2: const Color(0xFF4F46E5), // Indigo
      accentColor: const Color(0xFFC7D2FE),
      tags: ['Contract Compare', 'Diff Viewer', 'Change Audit'],
    ),
    _OnboardingSlide(
      title: 'Document Quality & Translation',
      subtitle: 'Translate 15+ Languages & Audit Citations',
      description: 'AI writing polish, readability audit, academic style grammar verification, and multilingual translation.',
      icon: LucideIcons.languages,
      color1: const Color(0xFF3B0764), // Dark Violet
      color2: const Color(0xFF7E22CE), // Violet
      accentColor: const Color(0xFFE9D5FF),
      tags: ['15+ Languages', 'Quality Checker', 'Writing Assistant'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoProgression();
  }

  void _startAutoProgression() {
    const slideDurationMs = 4000;
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
          // All 14 slides finished (56 seconds total duration)
          timer.cancel();
          context.go('/welcome');
        }
      }
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _progressTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 1.3,
            colors: [
              slide.color2,
              slide.color1,
              const Color(0xFF030712),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Particle Overlay
            ParticleBackground(
              numberOfParticles: 35,
              particleColor: slide.accentColor.withValues(alpha: 0.6),
              maxSpeed: 0.8,
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // 14-Step Progress Bar
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
                            margin: const EdgeInsets.symmetric(horizontal: 2),
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
                                      color: Colors.white.withValues(alpha: 0.6),
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

                    // Animated Card Container
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.92, end: 1.0).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Container(
                        key: ValueKey<int>(_currentIndex),
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: slide.color2.withValues(alpha: 0.4),
                              blurRadius: 36,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Feature Icon Glow
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: slide.accentColor.withValues(alpha: 0.5),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  slide.icon,
                                  size: 38,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Feature Title
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Subtitle
                            Text(
                              slide.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: slide.accentColor,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Description
                            Text(
                              slide.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12.5,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Capability Pills
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: slide.tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
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

                    // Auto presentation indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: slide.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Step ${_currentIndex + 1} of ${_slides.length} • Initializing Suite...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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

class _OnboardingSlide {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color1;
  final Color color2;
  final Color accentColor;
  final List<String> tags;

  const _OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color1,
    required this.color2,
    required this.accentColor,
    required this.tags,
  });
}
