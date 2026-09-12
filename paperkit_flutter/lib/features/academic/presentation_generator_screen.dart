import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/document_analysis_result.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import 'academic_tool_scaffold.dart';

class PresentationGeneratorScreen extends StatefulWidget {
  const PresentationGeneratorScreen({super.key});

  @override
  State<PresentationGeneratorScreen> createState() => _PresentationGeneratorScreenState();
}

class _PresentationGeneratorScreenState extends State<PresentationGeneratorScreen> {
  int _slideCount = 10;

  @override
  Widget build(BuildContext context) {
    return AcademicToolScaffold<List<PresentationSlide>>(
      title: 'Presentation Generator',
      toolId: 'presentation-generator',
      toolName: 'Presentation Generator',
      toolIcon: LucideIcons.presentation,
      toolColor: AppColors.toolTeal,
      toolSoftColor: AppColors.toolTealSoft,
      processingLabel: 'Generate Presentation',
      filePickerLabel: 'Choose Document (PDF)',
      allowedExtensions: ['pdf', 'txt', 'docx', 'pptx'],
      onProcess: (files) async {
        final raw = await ApiService().generatePresentation(file: files.first, slideCount: _slideCount);
        return (raw['slides'] as List? ?? [])
            .map((s) => PresentationSlide.fromJson(Map<String, dynamic>.from(s)))
            .toList();
      },
      exportToText: (slides) {
        final buf = StringBuffer('# Presentation Outline\n\n');
        for (final slide in slides) {
          buf.writeln('## Slide ${slide.slideNumber}: ${slide.title}');
          for (final bullet in slide.bulletPoints) {
            buf.writeln('- $bullet');
          }
          if (slide.notes != null) buf.writeln('\n*Notes: ${slide.notes}*');
          buf.writeln();
        }
        return buf.toString();
      },
      configWidget: (_) => Builder(builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Number of Slides', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const Spacer(),
              Text('$_slideCount', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.toolTeal)),
            ]),
            Slider(
              value: _slideCount.toDouble(), min: 5, max: 20, divisions: 3,
              label: '$_slideCount', activeColor: AppColors.toolTeal,
              onChanged: (v) => setState(() => _slideCount = v.round()),
            ),
          ]),
        );
      }),
      resultBuilder: (slides, files) => _PresentationResult(slides: slides),
    );
  }
}

class _PresentationResult extends StatefulWidget {
  final List<PresentationSlide> slides;
  const _PresentationResult({required this.slides});

  @override
  State<_PresentationResult> createState() => _PresentationResultState();
}

class _PresentationResultState extends State<_PresentationResult> {
  int _currentSlide = 0;
  bool _showNotes = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slide = widget.slides[_currentSlide];
    final slideColor = _slideColor(slide.slideType);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header with slide count
      Row(children: [
        const Icon(LucideIcons.presentation, size: 15, color: AppColors.toolTeal),
        const SizedBox(width: 8),
        Text('${widget.slides.length} slides generated',
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.toolTeal)),
        const Spacer(),
        Switch.adaptive(
          value: _showNotes,
          onChanged: (v) => setState(() => _showNotes = v),
          activeColor: AppColors.toolTeal,
        ),
        const Text('Notes', style: TextStyle(fontSize: 12.5)),
      ]),
      const SizedBox(height: 12),

      // Slide card
      Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 260),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              slideColor.withOpacity(0.15),
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: slideColor.withOpacity(0.3), width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Slide number + type
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: slideColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: Text('Slide ${slide.slideNumber}',
                  style: TextStyle(color: slideColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceElevatedDark : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              child: Text(slide.slideType, style: const TextStyle(fontSize: 11.5)),
            ),
          ]),
          const SizedBox(height: 16),

          // Title
          Text(slide.title, style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            height: 1.3,
          )),
          const SizedBox(height: 16),

          // Bullets
          if (slide.bulletPoints.isNotEmpty)
            Column(
              children: slide.bulletPoints.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(width: 6, height: 6, decoration: BoxDecoration(color: slideColor, shape: BoxShape.circle)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(b, style: TextStyle(fontSize: 13.5, height: 1.5,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
                ]),
              )).toList(),
            ),

          // Notes
          if (_showNotes && slide.notes != null && slide.notes!.isNotEmpty) ...[
            const Divider(height: 24),
            Row(children: [
              const Icon(LucideIcons.mic2, size: 13, color: AppColors.toolTeal),
              const SizedBox(width: 6),
              const Text('Speaker Notes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.toolTeal)),
            ]),
            const SizedBox(height: 6),
            Text(slide.notes!, style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          ],
        ]),
      ),
      const SizedBox(height: 16),

      // Navigation
      Row(children: [
        IconButton.outlined(
          onPressed: _currentSlide > 0 ? () => setState(() => _currentSlide--) : null,
          icon: const Icon(LucideIcons.chevronLeft),
          color: AppColors.toolTeal,
        ),
        const Spacer(),
        // Thumbnail row
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: widget.slides.length,
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () => setState(() => _currentSlide = i),
              child: Container(
                width: 30,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i == _currentSlide ? AppColors.toolTeal : (isDark ? AppColors.surfaceElevatedDark : AppColors.backgroundLight),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: i == _currentSlide ? AppColors.toolTeal : Colors.transparent),
                ),
                child: Center(child: Text('${i + 1}', style: TextStyle(
                    fontSize: 10, color: i == _currentSlide ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)))),
              ),
            ),
          ),
        ),
        const Spacer(),
        IconButton.outlined(
          onPressed: _currentSlide < widget.slides.length - 1 ? () => setState(() => _currentSlide++) : null,
          icon: const Icon(LucideIcons.chevronRight),
          color: AppColors.toolTeal,
        ),
      ]),

      const SizedBox(height: 16),

      // Slide list
      AcademicResultSection(
        title: 'All Slides',
        icon: LucideIcons.layoutTemplate,
        accentColor: AppColors.toolTeal,
        initiallyExpanded: false,
        child: Column(
          children: widget.slides.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              leading: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: _slideColor(s.slideType).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(child: Text('${s.slideNumber}',
                    style: TextStyle(color: _slideColor(s.slideType), fontWeight: FontWeight.bold, fontSize: 13))),
              ),
              title: Text(s.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text(s.slideType, style: const TextStyle(fontSize: 11.5)),
              selected: i == _currentSlide,
              selectedTileColor: AppColors.toolTeal.withOpacity(0.07),
              onTap: () => setState(() => _currentSlide = i),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            );
          }).toList(),
        ),
      ),
    ]);
  }

  Color _slideColor(String type) {
    switch (type.toLowerCase()) {
      case 'title': return AppColors.toolTeal;
      case 'agenda': return AppColors.toolBlue;
      case 'intro': return AppColors.toolIndigo;
      case 'methodology': return AppColors.toolPurple;
      case 'results': return AppColors.toolGreen;
      case 'discussion': return AppColors.toolOrange;
      case 'conclusion': return AppColors.toolRed;
      case 'references': return AppColors.textMutedLight;
      default: return AppColors.toolTeal;
    }
  }
}
