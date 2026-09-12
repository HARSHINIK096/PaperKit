import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/tool_features_registry.dart';
import '../theme/app_colors.dart';

class HowItWorksCarousel extends StatefulWidget {
  final String toolId;
  final String? toolName;
  final Color? color;
  final EdgeInsetsGeometry padding;

  const HowItWorksCarousel({
    super.key,
    required this.toolId,
    this.toolName,
    this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  State<HowItWorksCarousel> createState() => _HowItWorksCarouselState();
}

class _HowItWorksCarouselState extends State<HowItWorksCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = ToolFeaturesRegistry.getForTool(
      widget.toolId,
      toolName: widget.toolName,
      color: widget.color,
    );

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ⓘ How it works (Swipe to explore)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: (widget.color ?? AppColors.primary).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.info,
                  size: 15,
                  color: widget.color ?? AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'How it works (Swipe to explore)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Swipeable Cards PageView
          SizedBox(
            height: 114,
            child: PageView.builder(
              controller: _pageController,
              itemCount: steps.length,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemBuilder: (context, index) {
                final step = steps[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildCard(step, isDark),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Pagination indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              steps.length,
              (idx) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == idx ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == idx
                      ? (widget.color ?? AppColors.primary)
                      : (isDark ? Colors.white24 : Colors.black12),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ToolFeatureStep step, bool isDark) {
    final cardColor = step.color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor.withOpacity(isDark ? 0.22 : 0.14),
            cardColor.withOpacity(isDark ? 0.08 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cardColor.withOpacity(isDark ? 0.5 : 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular Icon Badge
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              step.icon,
              size: 20,
              color: cardColor,
            ),
          ),
          const SizedBox(width: 12),

          // Title & Subtitle Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  step.subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
