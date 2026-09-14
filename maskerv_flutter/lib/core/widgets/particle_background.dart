import 'dart:math';
import 'package:flutter/material.dart';

class ParticleBackground extends StatefulWidget {
  final int numberOfParticles;
  final Color? particleColor;
  final bool enableLines;
  final double maxSpeed;

  const ParticleBackground({
    super.key,
    this.numberOfParticles = 30,
    this.particleColor,
    this.enableLines = true,
    this.maxSpeed = 0.6,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    for (int i = 0; i < widget.numberOfParticles; i++) {
      _particles.add(
        _Particle(
          x: _rnd.nextDouble(),
          y: _rnd.nextDouble(),
          vx: (_rnd.nextDouble() - 0.5) * widget.maxSpeed * 0.003,
          vy: (_rnd.nextDouble() - 0.5) * widget.maxSpeed * 0.003,
          radius: _rnd.nextDouble() * 2.5 + 1.2,
          opacity: _rnd.nextDouble() * 0.4 + 0.15,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = widget.particleColor ??
        (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        for (final p in _particles) {
          p.x += p.vx;
          p.y += p.vy;

          if (p.x < 0) p.x = 1.0;
          if (p.x > 1) p.x = 0.0;
          if (p.y < 0) p.y = 1.0;
          if (p.y > 1) p.y = 0.0;
        }

        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(
            particles: _particles,
            baseColor: defaultColor,
            enableLines: widget.enableLines,
          ),
        );
      },
    );
  }
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color baseColor;
  final bool enableLines;

  _ParticlePainter({
    required this.particles,
    required this.baseColor,
    required this.enableLines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    // Draw connecting lines if close
    if (enableLines) {
      for (int i = 0; i < particles.length; i++) {
        final p1 = particles[i];
        final x1 = p1.x * size.width;
        final y1 = p1.y * size.height;

        for (int j = i + 1; j < particles.length; j++) {
          final p2 = particles[j];
          final x2 = p2.x * size.width;
          final y2 = p2.y * size.height;

          final dx = x1 - x2;
          final dy = y1 - y2;
          final dist = sqrt(dx * dx + dy * dy);

          if (dist < 90) {
            final alpha = (1.0 - (dist / 90)) * 0.15;
            linePaint.color = baseColor.withValues(alpha: alpha);
            canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
          }
        }
      }
    }

    // Draw glowing particles
    for (final p in particles) {
      paint.color = baseColor.withValues(alpha: p.opacity);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
