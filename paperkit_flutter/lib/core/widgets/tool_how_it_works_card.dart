import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ToolHowItWorksItem {
  final IconData icon;
  final String title;
  final String description;
  final Color? accentColor;

  const ToolHowItWorksItem({
    required this.icon,
    required this.title,
    required this.description,
    this.accentColor,
  });
}

class ToolHowItWorksCard extends StatefulWidget {
  final String toolId;
  final Color primaryColor;
  final List<ToolHowItWorksItem>? customItems;

  const ToolHowItWorksCard({
    super.key,
    required this.toolId,
    required this.primaryColor,
    this.customItems,
  });

  @override
  State<ToolHowItWorksCard> createState() => _ToolHowItWorksCardState();
}

class _ToolHowItWorksCardState extends State<ToolHowItWorksCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<ToolHowItWorksItem> _getItemsForTool(String toolId) {
    if (widget.customItems != null && widget.customItems!.isNotEmpty) {
      return widget.customItems!;
    }

    switch (toolId) {
      case 'merge-pdf':
      case 'merge':
        return const [
          ToolHowItWorksItem(
            icon: LucideIcons.layers,
            title: 'Combine Instantly',
            description: 'Merge dozens of documents into a single master PDF in seconds.',
          ),
          ToolHowItWorksItem(
            icon: LucideIcons.arrowDownUp,
            title: 'Reorder Page Sequences',
            description: 'Drag & arrange PDF files in any exact order before final synthesis.',
          ),
          ToolHowItWorksItem(
            icon: LucideIcons.shieldCheck,
            title: '100% Private & Local',
            description: 'Your confidential papers never leave your device memory.',
          ),
        ];

      case 'split-pdf':
      case 'split':
        return const [
          ToolHowItWorksItem(
            icon: LucideIcons.scissors,
            title: 'Precision Range Extraction',
            description: 'Split by custom ranges (e.g. 1-3, 5-8) or extract individual pages.',
          ),
          ToolHowItWorksItem(
            icon: LucideIcons.layoutGrid,
            title: 'Burst Every N Pages',
            description: 'Automatically segment large book chapters or invoices every N pages.',
          ),
        ];

      case 'compress-pdf':
      case 'compress':
        return const [
          ToolHowItWorksItem(
            icon: LucideIcons.minimize2,
            title: 'Extreme File Reduction',
            description: 'Shrink massive PDFs up to 90% without compromising vector font clarity.',
          ),
          ToolHowItWorksItem(
            icon: LucideIcons.sliders,
            title: 'Multi-Level Presets',
            description: 'Choose Recommended, Extreme, or High Quality custom presets.',
          ),
        ];

      case 'summarize-pdf':
      case 'ai-summary':
        return const [
          ToolHowItWorksItem(
            icon: LucideIcons.sparkles,
            title: 'Neural Document Synthesis',
            description: 'Extract executive summaries, key takeaways, and action items instantly.',
          ),
          ToolHowItWorksItem(
            icon: LucideIcons.listCheck,
            title: 'Multi-Format Reports',
            description: 'Switch between bullet points, table briefs, or deep research essays.',
          ),
        ];

      case 'ask-pdf':
      case 'ai-chat':
        return const [
          ToolHowItWorksItem(
            icon: LucideIcons.messageSquare,
            title: 'Conversational Research',
            description: 'Chat directly with contracts, research papers, and books with citations.',
          ),
          ToolHowItWorksItem(
            icon: LucideIcons.searchCode,
            title: 'Exact Grounded Citations',
            description: 'AI retrieves precise quotes and page anchors for every factual claim.',
          ),
        ];

      case 'protect-pdf':
      case 'protect':
        return const [
          ToolHowItWorksItem(
            icon: LucideIcons.lock,
            title: 'Military-Grade AES-256',
            description: 'Enforce user & owner passwords with permission restrictions.',
          ),
          ToolHowItWorksItem(
            icon: LucideIcons.shieldAlert,
            title: 'Prevent Unauthorized Print',
            description: 'Block copying, printing, and modification rights with one tap.',
          ),
        ];

      case 'smart-redaction':
      case 'redact':
        return const [
          ToolHowItWorksItem(
            icon: LucideIcons.eyeOff,
            title: 'Permanent PII Sanitization',
            description: 'Deeply eradicate SSNs, emails, names, and card numbers from PDF bytes.',
          ),
          ToolHowItWorksItem(
            icon: LucideIcons.eraser,
            title: 'No Residual Metadata',
            description: 'Redacted objects are permanently expunged, not just visually hidden.',
          ),
        ];

      case 'video-converter':
      case 'video-to-mp4':
        return const [
          ToolHowItWorksItem(
            icon: LucideIcons.video,
            title: 'Hardware-Accelerated Encoding',
            description: 'Convert any format (MKV, AVI, MOV) to web-optimized MP4 or GIF.',
          ),
          ToolHowItWorksItem(
            icon: LucideIcons.sparkles,
            title: 'Lossless Visual Quality',
            description: 'Maintains full 60fps frame rate and color depth during transcoding.',
          ),
        ];

      case 'video-compressor':
        return const [
          ToolHowItWorksItem(
            icon: LucideIcons.film,
            title: 'Adaptive CRF Optimization',
            description: 'Compress video sizes dramatically for instant Discord & email sharing.',
          ),
        ];

      case 'audio-converter':
        return const [
          ToolHowItWorksItem(
            icon: LucideIcons.music2,
            title: 'Multi-Format Audio Studio',
            description: 'Transcode between MP3, lossless studio WAV, and open-source OGG.',
          ),
        ];

      case 'archive-studio':
      case 'archive-extract':
      case 'archive-create-zip':
        return const [
          ToolHowItWorksItem(
            icon: LucideIcons.archive,
            title: 'Universal Archive Suite',
            description: 'Extract & pack ZIP, RAR, TAR, GZ, 7Z, and BZ2 archives effortlessly.',
          ),
        ];

      default:
        return [
          ToolHowItWorksItem(
            icon: LucideIcons.sparkles,
            title: 'Fast & Local-First Processing',
            description: 'Engineered for maximum document privacy, clarity, and instant speed.',
          ),
          const ToolHowItWorksItem(
            icon: LucideIcons.shieldCheck,
            title: 'Zero Cloud Storage Logs',
            description: 'Processed entirely on-device and in volatile server memory.',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _getItemsForTool(widget.toolId);
    final themeColor = widget.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(LucideIcons.info, size: 15, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Text(
                'How it works (Swipe to explore)',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),

        // Carousel Box
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _pageController,
            itemCount: items.length,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeColor.withValues(alpha: 0.12),
                      themeColor.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: themeColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Badge (Circular white container)
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        item.icon,
                        color: const Color(0xFF0F172A),
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Subtitle / Description
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Dots Indicator
        if (items.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              items.length,
              (idx) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == idx ? 16 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: _currentPage == idx
                      ? themeColor
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
