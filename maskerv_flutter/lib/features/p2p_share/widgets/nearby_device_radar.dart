import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/p2p_share_model.dart';

class NearbyDeviceRadar extends StatefulWidget {
  final List<PeerDevice> devices;
  final double currentMaxRadius;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<PeerDevice> onDeviceSelected;
  final PeerDevice? selectedDevice;
  final bool isScanning;

  const NearbyDeviceRadar({
    super.key,
    required this.devices,
    required this.currentMaxRadius,
    required this.onRadiusChanged,
    required this.onDeviceSelected,
    this.selectedDevice,
    this.isScanning = false,
  });

  @override
  State<NearbyDeviceRadar> createState() => _NearbyDeviceRadarState();
}

class _NearbyDeviceRadarState extends State<NearbyDeviceRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  IconData _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'laptop':
        return LucideIcons.laptop;
      case 'tablet':
        return LucideIcons.tablet;
      case 'desktop':
        return LucideIcons.monitor;
      case 'phone':
      default:
        return LucideIcons.smartphone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Radius Range Filter Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              const Icon(LucideIcons.radar, size: 18, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              const Text(
                'Radius:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              _buildRadiusChip(label: '2m', value: 2.0),
              const SizedBox(width: 6),
              _buildRadiusChip(label: '5m', value: 5.0),
              const SizedBox(width: 6),
              _buildRadiusChip(label: '10m', value: 10.0),
              const SizedBox(width: 6),
              _buildRadiusChip(label: '20m', value: 20.0),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Animated Radar Sonar Canvas
        Center(
          child: Container(
            width: 270,
            height: 270,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: AnimatedBuilder(
                animation: _sweepController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _RadarSweepPainter(
                      sweepAngle: _sweepController.value * 2 * math.pi,
                      maxRadius: widget.currentMaxRadius,
                      devices: widget.devices,
                      selectedDeviceId: widget.selectedDevice?.id,
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                    child: Stack(
                      children: [
                        // Center Self Device Node
                        Center(
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.radio,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Interactive Discovered Device Nodes plotted on Radar
                        ...widget.devices.map((device) {
                          // Normalize distance against current max radius
                          final normalizedDist =
                              (device.distanceMeters / widget.currentMaxRadius)
                                  .clamp(0.18, 0.88);
                          final radarRadius = 135.0 * normalizedDist;

                          // Compute cartesian coordinates relative to center (135, 135)
                          final x =
                              135.0 +
                              radarRadius * math.cos(device.angleRadians);
                          final y =
                              135.0 +
                              radarRadius * math.sin(device.angleRadians);

                          final isSelected =
                              widget.selectedDevice?.id == device.id;

                          return Positioned(
                            left: x - 18,
                            top: y - 18,
                            child: Tooltip(
                              message:
                                  '${device.deviceName} (${device.distanceMeters.toStringAsFixed(1)}m)',
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  widget.onDeviceSelected(device);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? const Color(0xFF10B981)
                                        : (isDark
                                              ? const Color(0xFF1E293B)
                                              : Colors.white),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF2563EB),
                                      width: isSelected ? 2.5 : 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (isSelected
                                                    ? const Color(0xFF10B981)
                                                    : const Color(0xFF2563EB))
                                                .withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _getDeviceIcon(device.deviceType),
                                    size: 18,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Radar Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendDot(const Color(0xFF10B981), 'Selected'),
            const SizedBox(width: 14),
            _buildLegendDot(const Color(0xFF2563EB), 'Nearby Peer'),
            const SizedBox(width: 14),
            Text(
              '${widget.devices.length} in range (<${widget.currentMaxRadius.toInt()}m)',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Discovered Devices List
        const Text(
          'Select Available Device Nearby:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),

        if (widget.devices.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.radar, size: 36, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'No devices detected within ${widget.currentMaxRadius.toInt()}m.',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Expand the radius filter or ensure nearby devices have AirShare active.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.devices.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final device = widget.devices[index];
              final isSelected = widget.selectedDevice?.id == device.id;

              return Card(
                elevation: isSelected ? 3 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF10B981)
                        : (isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0)),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : const Color(0xFF2563EB).withValues(alpha: 0.15),
                    child: Icon(
                      _getDeviceIcon(device.deviceType),
                      color: isSelected
                          ? const Color(0xFF10B981)
                          : const Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          device.deviceName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          device.distanceLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        device.deviceModel,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 8),
                      Icon(
                        LucideIcons.wifi,
                        size: 12,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(device.signalStrength * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onDeviceSelected(device);
                    },
                    icon: Icon(
                      isSelected ? LucideIcons.check : LucideIcons.send,
                      size: 14,
                    ),
                    label: Text(isSelected ? 'Selected' : 'Beam File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? const Color(0xFF10B981)
                          : const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRadiusChip({required String label, required double value}) {
    final isSelected = widget.currentMaxRadius == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onRadiusChanged(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : null,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _RadarSweepPainter extends CustomPainter {
  final double sweepAngle;
  final double maxRadius;
  final List<PeerDevice> devices;
  final String? selectedDeviceId;
  final Color primaryColor;
  final bool isDark;

  _RadarSweepPainter({
    required this.sweepAngle,
    required this.maxRadius,
    required this.devices,
    required this.selectedDeviceId,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;

    final gridPaint = Paint()
      ..color = (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
          .withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 4 Concentric Proximity Distance Circles (2m, 5m, 10m, 20m normalized)
    final radiiSteps = [0.25, 0.50, 0.75, 1.0];
    for (final step in radiiSteps) {
      canvas.drawCircle(center, outerRadius * step, gridPaint);
    }

    // Crosshairs
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      gridPaint,
    );

    // Rotating Radar Sweep Gradient Beam
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: math.pi / 2,
        colors: [
          primaryColor.withValues(alpha: 0.0),
          primaryColor.withValues(alpha: 0.35),
        ],
        transform: GradientRotation(sweepAngle - math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));

    canvas.drawCircle(center, outerRadius, sweepPaint);

    // Dynamic Beam Leading Edge Line
    final edgePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.8)
      ..strokeWidth = 2.0;

    final beamEndX = center.dx + outerRadius * math.cos(sweepAngle);
    final beamEndY = center.dy + outerRadius * math.sin(sweepAngle);
    canvas.drawLine(center, Offset(beamEndX, beamEndY), edgePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarSweepPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.devices != devices ||
        oldDelegate.maxRadius != maxRadius ||
        oldDelegate.selectedDeviceId != selectedDeviceId;
  }
}
