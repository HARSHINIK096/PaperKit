import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_config.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/particle_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _wakeUpServers();
    _startSplashSequence();
  }

  // Asynchronously ping both onrender URLs in background to wake up cold servers
  void _wakeUpServers() {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 55),
          receiveTimeout: const Duration(seconds: 55),
        ),
      );

      // Ping Backend
      dio.get('${ApiConfig.defaultBackendUrl}/health').catchError((_) => Response(requestOptions: RequestOptions(path: '')));
      
      // Ping Web URL
      dio.get(ApiConfig.frontendUrl).catchError((_) => Response(requestOptions: RequestOptions(path: '')));
      
      // Warm up local anonymous user storage
      StorageService().getAnonymousUserId().catchError((_) => '');
    } catch (_) {}
  }

  void _startSplashSequence() {
    // 5-second smooth progress timer
    const totalDurationMs = 5000;
    const intervalMs = 50;
    const step = intervalMs / totalDurationMs;

    _progressTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress = (_progress + step).clamp(0.0, 1.0);
      });

      if (_progress >= 1.0) {
        timer.cancel();
        context.go('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Ambient Particle Layer
          const ParticleBackground(
            numberOfParticles: 28,
            particleColor: Color(0xFF3B82F6),
            maxSpeed: 0.5,
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glowing App Icon
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                          blurRadius: 36,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        width: 108,
                        height: 108,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(
                        duration: 2000.ms,
                        begin: const Offset(1, 1),
                        end: const Offset(1.06, 1.06),
                        curve: Curves.easeInOut,
                      ),

                  const SizedBox(height: 28),

                  Text(
                    'PaperKit',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 6),

                  Text(
                    'Document Intelligence Suite',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 48),

                  // Progress Bar (5 seconds)
                  Container(
                    width: 200,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'Waking up cloud engines & local sandbox...',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
