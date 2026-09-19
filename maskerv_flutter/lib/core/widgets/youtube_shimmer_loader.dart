import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

/// Personalized MaskerV AI Document Processing Shimmer Loader.
/// Custom-crafted for MaskerV system (replaces generic YouTube style).
class MaskerVShimmerLoader extends StatefulWidget {
  final String statusTitle;
  final String statusSubtitle;
  final double? progress;
  final Color? color;
  final EdgeInsetsGeometry padding;

  const MaskerVShimmerLoader({
    super.key,
    this.statusTitle = 'Processing MaskerV Intelligence...',
    this.statusSubtitle = 'Extracting document semantics, structural nodes & academic insights',
    this.progress,
    this.color,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  State<MaskerVShimmerLoader> createState() => _MaskerVShimmerLoaderState();
}

class _MaskerVShimmerLoaderState extends State<MaskerVShimmerLoader>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;

  final List<String> _telemetrySteps = const [
    'Parsing document structure & typography...',
    'Extracting semantic concepts & formulas...',
    'Running deep academic AI engine...',
    'Formatting structured study output...',
  ];
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _cycleTelemetry();
  }

  void _cycleTelemetry() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 2200));
      if (mounted) {
        setState(() {
          _currentStepIndex = (_currentStepIndex + 1) % _telemetrySteps.length;
        });
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.color ?? AppColors.primary;
    final baseColor = isDark ? const Color(0xFF232533) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF3B3E54) : const Color(0xFFF8FAFC);

    return Padding(
      padding: widget.padding,
      child: AnimatedBuilder(
        animation: Listenable.merge([_shimmerAnimation, _pulseAnimation]),
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Personalized PaperKit Header Banner ──────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF1E1E2E),
                            primaryColor.withOpacity(0.18),
                          ]
                        : [
                            Colors.white,
                            primaryColor.withOpacity(0.06),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor,
                                  primaryColor.withOpacity(0.7),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.fileText,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.statusTitle,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 10,
                                          height: 10,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            value: widget.progress,
                                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          widget.progress != null
                                              ? '${(widget.progress! * 100).toInt()}%'
                                              : 'MaskerV AI',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.statusSubtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Animated Telemetry Step Indicator Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.3)
                            : primaryColor.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.sparkles,
                            size: 14,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _telemetrySteps[_currentStepIndex],
                                key: ValueKey<int>(_currentStepIndex),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Personalized PaperKit Skeleton Shimmer Cards ───────────────
              Row(
                children: [
                  _buildShimmerItem(baseColor, highlightColor, height: 28, widthFactor: 0.35, borderRadius: 14),
                  const SizedBox(width: 10),
                  _buildShimmerItem(baseColor, highlightColor, height: 28, widthFactor: 0.25, borderRadius: 14),
                ],
              ),
              const SizedBox(height: 12),
              _buildShimmerCard(baseColor, highlightColor, primaryColor, height: 110, isDark: isDark),
              const SizedBox(height: 14),
              _buildShimmerItem(baseColor, highlightColor, height: 16, widthFactor: 0.45, borderRadius: 8),
              const SizedBox(height: 10),
              _buildShimmerCard(baseColor, highlightColor, primaryColor, height: 72, isDark: isDark),
              const SizedBox(height: 10),
              _buildShimmerCard(baseColor, highlightColor, primaryColor, height: 72, isDark: isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShimmerItem(
    Color baseColor,
    Color highlightColor, {
    required double height,
    required double widthFactor,
    double borderRadius = 8,
  }) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment(_shimmerAnimation.value - 1.0, 0),
            end: Alignment(_shimmerAnimation.value, 0),
            colors: [
              baseColor,
              highlightColor,
              baseColor,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard(
    Color baseColor,
    Color highlightColor,
    Color primaryColor, {
    required double height,
    required bool isDark,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildShimmerItem(baseColor, highlightColor, height: 12, widthFactor: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildShimmerItem(baseColor, highlightColor, height: 10, widthFactor: 0.9),
          if (height > 80) ...[
            const SizedBox(height: 8),
            _buildShimmerItem(baseColor, highlightColor, height: 10, widthFactor: 0.7),
          ],
        ],
      ),
    );
  }
}

/// Backwards compatibility aliases
typedef PaperKitShimmerLoader = MaskerVShimmerLoader;
typedef YouTubeShimmerLoader = MaskerVShimmerLoader;
