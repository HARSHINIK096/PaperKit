import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr/qr.dart';
import '../models/qr_design_config.dart';

class QrDesignControls extends StatelessWidget {
  final QrDesignConfig config;
  final ValueChanged<QrDesignConfig> onChanged;

  const QrDesignControls({
    super.key,
    required this.config,
    required this.onChanged,
  });

  static const List<Color> _swatches = [
    Color(0xFF0F172A), // Dark Slate
    Color(0xFF1E3A8A), // Navy Blue
    Color(0xFF2563EB), // Royal Blue
    Color(0xFF059669), // Emerald
    Color(0xFF7C3AED), // Violet
    Color(0xFFD97706), // Amber
    Color(0xFFE11D48), // Rose
    Color(0xFF000000), // Pure Black
  ];

  static const List<IconData> _builtInIcons = [
    LucideIcons.globe,
    LucideIcons.link2,
    LucideIcons.mail,
    LucideIcons.phone,
    LucideIcons.wifi,
    LucideIcons.user,
    LucideIcons.sparkles,
    LucideIcons.heart,
    LucideIcons.star,
    LucideIcons.camera,
    LucideIcons.music,
    LucideIcons.code,
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            tabs: const [
              Tab(icon: Icon(LucideIcons.shapes, size: 16), text: 'Shapes & Eyes'),
              Tab(icon: Icon(LucideIcons.palette, size: 16), text: 'Colors'),
              Tab(icon: Icon(LucideIcons.square, size: 16), text: 'Frame & Label'),
              Tab(icon: Icon(LucideIcons.image, size: 16), text: 'Logo & Watermark'),
              Tab(icon: Icon(LucideIcons.shieldAlert, size: 16), text: 'Settings'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: TabBarView(
              children: [
                _buildShapesTab(),
                _buildColorsTab(),
                _buildFrameTab(),
                _buildLogoTab(),
                _buildSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Shapes & Eyes Tab
  Widget _buildShapesTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Module Style', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: QrModuleShape.values.map((shape) {
              final isSelected = config.moduleShape == shape;
              return ChoiceChip(
                label: Text(shape.label),
                selected: isSelected,
                onSelected: (_) => onChanged(config.copyWith(moduleShape: shape)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Corner Eye Outer Shape', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: QrEyeShape.values.map((shape) {
              final isSelected = config.eyeOuterShape == shape;
              return ChoiceChip(
                label: Text(shape.label),
                selected: isSelected,
                onSelected: (_) => onChanged(config.copyWith(eyeOuterShape: shape)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Corner Eye Inner Shape', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: QrEyeShape.values.map((shape) {
              final isSelected = config.eyeInnerShape == shape;
              return ChoiceChip(
                label: Text(shape.label),
                selected: isSelected,
                onSelected: (_) => onChanged(config.copyWith(eyeInnerShape: shape)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 2. Colors & Gradients Tab
  Widget _buildColorsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Color Style', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: QrColorMode.values.map((mode) {
              final isSelected = config.colorMode == mode;
              return ChoiceChip(
                label: Text(mode.label),
                selected: isSelected,
                onSelected: (_) => onChanged(config.copyWith(colorMode: mode)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Foreground Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: _swatches.map((c) {
              final isSelected = config.foregroundColor == c;
              return GestureDetector(
                onTap: () => onChanged(config.copyWith(foregroundColor: c)),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blueAccent : Colors.grey.withValues(alpha: 0.3),
                      width: isSelected ? 3 : 1.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (config.colorMode != QrColorMode.solid) ...[
            const SizedBox(height: 16),
            const Text('Gradient Accent Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _swatches.reversed.map((c) {
                final isSelected = config.foregroundGradientEnd == c;
                return GestureDetector(
                  onTap: () => onChanged(config.copyWith(foregroundGradientEnd: c)),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.blueAccent : Colors.grey.withValues(alpha: 0.3),
                        width: isSelected ? 3 : 1.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: config.transparentBackground,
                onChanged: (val) => onChanged(config.copyWith(transparentBackground: val ?? false)),
              ),
              const Text('Transparent Background (PNG)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Frame & Label Tab
  Widget _buildFrameTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Frame Style', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: QrFrameStyle.values.map((frame) {
              final isSelected = config.frameStyle == frame;
              return ChoiceChip(
                label: Text(frame.label),
                selected: isSelected,
                onSelected: (_) => onChanged(config.copyWith(frameStyle: frame)),
              );
            }).toList(),
          ),
          if (config.frameStyle != QrFrameStyle.none) ...[
            const SizedBox(height: 16),
            TextFormField(
              initialValue: config.frameLabel,
              decoration: InputDecoration(
                labelText: 'Frame Text Label',
                hintText: 'e.g. SCAN ME, CONNECT, VISIT',
                prefixIcon: const Icon(LucideIcons.type, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => onChanged(config.copyWith(frameLabel: val)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Position: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Bottom'),
                  selected: config.framePosition == QrFramePosition.bottom,
                  onSelected: (_) => onChanged(config.copyWith(framePosition: QrFramePosition.bottom)),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Top'),
                  selected: config.framePosition == QrFramePosition.top,
                  onSelected: (_) => onChanged(config.copyWith(framePosition: QrFramePosition.top)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 4. Logo & Watermark Tab
  Widget _buildLogoTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Center Icon / Logo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              if (config.hasCenterLogo)
                TextButton.icon(
                  onPressed: () => onChanged(config.copyWith(clearCenterLogo: true)),
                  icon: const Icon(LucideIcons.trash2, size: 14),
                  label: const Text('Remove Logo', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _builtInIcons.map((iconData) {
              final isSelected = config.centerIcon == iconData;
              return GestureDetector(
                onTap: () => onChanged(config.copyWith(centerIcon: iconData)),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(iconData, size: 20, color: isSelected ? Colors.blue : null),
                ),
              );
            }).toList(),
          ),
          if (config.hasCenterLogo) ...[
            const SizedBox(height: 16),
            const Text('Logo Shape', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: QrLogoBackgroundShape.values.map((shape) {
                final isSelected = config.logoBackgroundShape == shape;
                return ChoiceChip(
                  label: Text(shape.label),
                  selected: isSelected,
                  onSelected: (_) => onChanged(config.copyWith(logoBackgroundShape: shape)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Background Watermark', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              if (config.hasBackgroundWatermark)
                TextButton.icon(
                  onPressed: () => onChanged(config.copyWith(clearBackgroundWatermark: true)),
                  icon: const Icon(LucideIcons.trash2, size: 14),
                  label: const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _builtInIcons.map((iconData) {
              final isSelected = config.backgroundIcon == iconData;
              return GestureDetector(
                onTap: () => onChanged(config.copyWith(backgroundIcon: iconData)),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.purple.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Colors.purple : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(iconData, size: 20, color: isSelected ? Colors.purple : null),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 5. Settings Tab
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Error Correction Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          const Text(
            'Higher correction allows QR codes to be read even if partially obscured by logos or damaged.',
            style: TextStyle(fontSize: 11.5, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('L (~7%)'),
                selected: config.errorCorrectionLevel == QrErrorCorrectLevel.L,
                onSelected: (_) => onChanged(config.copyWith(errorCorrectionLevel: QrErrorCorrectLevel.L)),
              ),
              ChoiceChip(
                label: const Text('M (~15%)'),
                selected: config.errorCorrectionLevel == QrErrorCorrectLevel.M,
                onSelected: (_) => onChanged(config.copyWith(errorCorrectionLevel: QrErrorCorrectLevel.M)),
              ),
              ChoiceChip(
                label: const Text('Q (~25%)'),
                selected: config.errorCorrectionLevel == QrErrorCorrectLevel.Q,
                onSelected: (_) => onChanged(config.copyWith(errorCorrectionLevel: QrErrorCorrectLevel.Q)),
              ),
              ChoiceChip(
                label: const Text('H (~30% Recommended)'),
                selected: config.errorCorrectionLevel == QrErrorCorrectLevel.H,
                onSelected: (_) => onChanged(config.copyWith(errorCorrectionLevel: QrErrorCorrectLevel.H)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Export Resolution (Pixels)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [512, 1024, 2048].map((res) {
              final isSelected = config.exportResolution == res;
              return ChoiceChip(
                label: Text('${res}x$res px'),
                selected: isSelected,
                onSelected: (_) => onChanged(config.copyWith(exportResolution: res)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
