import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'particle_background.dart';
import 'tool_how_it_works_card.dart';

enum ToolStep {
  upload,
  edition,
  processing,
  download,
  success,
}

class ToolSessionData {
  final List<File> inputFiles;
  final Map<String, dynamic> parameters;
  final File? outputFile;
  final int originalSizeBytes;
  final int outputSizeBytes;
  final String? errorMessage;

  const ToolSessionData({
    this.inputFiles = const [],
    this.parameters = const {},
    this.outputFile,
    this.originalSizeBytes = 0,
    this.outputSizeBytes = 0,
    this.errorMessage,
  });
}

class ToolFlowScaffold extends StatefulWidget {
  final String title;
  final String toolId;
  final Color primaryColor;
  final IconData toolIcon;
  final Widget uploadWidget;
  final Widget editionWidget;
  final Widget? customDownloadPreview;
  final String processingMessage;
  final Future<File?> Function() onProcess;
  final bool canProceedToEdition;
  final VoidCallback? onReset;
  final int originalSizeBytes;

  const ToolFlowScaffold({
    super.key,
    required this.title,
    required this.toolId,
    required this.primaryColor,
    required this.toolIcon,
    required this.uploadWidget,
    required this.editionWidget,
    this.customDownloadPreview,
    this.processingMessage = 'Processing document...',
    required this.onProcess,
    this.canProceedToEdition = true,
    this.onReset,
    this.originalSizeBytes = 0,
  });

  @override
  State<ToolFlowScaffold> createState() => _ToolFlowScaffoldState();
}

class _ToolFlowScaffoldState extends State<ToolFlowScaffold> with TickerProviderStateMixin {
  ToolStep _currentStep = ToolStep.upload;
  File? _resultFile;
  String? _errorMessage;
  int _autoDownloadSeconds = 2;
  Timer? _autoDownloadTimer;
  bool _hasAutoDownloaded = false;
  int _processingPercent = 0;
  Timer? _progressSimTimer;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _autoDownloadTimer?.cancel();
    _progressSimTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startProcessing() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _currentStep = ToolStep.processing;
      _errorMessage = null;
      _processingPercent = 15;
    });

    _progressSimTimer?.cancel();
    _progressSimTimer = Timer.periodic(const Duration(milliseconds: 250), (t) {
      if (_processingPercent < 90) {
        setState(() => _processingPercent += 12);
      }
    });

    try {
      final file = await widget.onProcess();
      _progressSimTimer?.cancel();
      if (!mounted) return;

      if (file != null) {
        setState(() {
          _processingPercent = 100;
          _resultFile = file;
          _currentStep = ToolStep.download;
        });
      } else {
        setState(() {
          _currentStep = ToolStep.edition;
          _errorMessage = 'Processing completed without output file.';
        });
      }
    } catch (e) {
      _progressSimTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _currentStep = ToolStep.edition;
        _errorMessage = 'Error: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Processing failed: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  void _proceedToAutoDownloadSuccess() {
    HapticFeedback.mediumImpact();
    setState(() {
      _currentStep = ToolStep.success;
      _autoDownloadSeconds = 2;
      _hasAutoDownloaded = false;
    });
    _startAutoDownloadCountdown();
  }

  void _startAutoDownloadCountdown() {
    _autoDownloadTimer?.cancel();
    _autoDownloadTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_autoDownloadSeconds > 1) {
        setState(() {
          _autoDownloadSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _autoDownloadSeconds = 0;
          _hasAutoDownloaded = true;
        });
        _triggerAutoSaveNotification();
      }
    });
  }

  void _triggerAutoSaveNotification() {
    HapticFeedback.heavyImpact();
    if (_resultFile != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Auto-downloaded & saved: ${_resultFile!.uri.pathSegments.last}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _resetFlow() {
    _autoDownloadTimer?.cancel();
    _progressSimTimer?.cancel();
    setState(() {
      _currentStep = ToolStep.upload;
      _resultFile = null;
      _errorMessage = null;
      _autoDownloadSeconds = 2;
      _hasAutoDownloaded = false;
      _processingPercent = 0;
    });
    if (widget.onReset != null) {
      widget.onReset!();
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0.00 MB';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18.5,
            letterSpacing: -0.3,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 22),
          onPressed: () {
            if (_currentStep == ToolStep.edition) {
              setState(() => _currentStep = ToolStep.upload);
            } else if (_currentStep == ToolStep.download) {
              setState(() => _currentStep = ToolStep.edition);
            } else if (_currentStep == ToolStep.success) {
              _resetFlow();
            } else {
              context.pop();
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 19),
            onPressed: _resetFlow,
            tooltip: 'Reset Pipeline',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _build5StepProgressBar(),
        ),
      ),
      body: Stack(
        children: [
          // Background Particle Canvas
          Positioned.fill(
            child: ParticleBackground(
              numberOfParticles: 25,
              particleColor: widget.primaryColor,
              enableLines: true,
              maxSpeed: 0.25,
            ),
          ),

          // Main 5-Stage Animated Switcher
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildCurrentStage(),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5-STEP PROGRESS HEADER BAR ────────────────────────────────────
  Widget _build5StepProgressBar() {
    final steps = ['Upload', 'Edit', 'Process', 'Download', 'Success'];
    final currentIndex = _currentStep.index;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(steps.length, (idx) {
            final isPassed = idx < currentIndex;
            final isActive = idx == currentIndex;
            final color = isActive
                ? widget.primaryColor
                : (isPassed ? const Color(0xFF10B981) : const Color(0xFF94A3B8));

            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? widget.primaryColor.withValues(alpha: 0.12)
                        : (isPassed
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? widget.primaryColor
                          : (isPassed
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE2E8F0)),
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPassed) ...[
                        const Icon(LucideIcons.check, size: 11, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        '${idx + 1}. ${steps[idx]}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive || isPassed ? FontWeight.w700 : FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (idx < steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 13,
                      color: isPassed ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCurrentStage() {
    switch (_currentStep) {
      case ToolStep.upload:
        return _buildPage1Upload();
      case ToolStep.edition:
        return _buildPage2Edition();
      case ToolStep.processing:
        return _buildPage3Processing();
      case ToolStep.download:
        return _buildPage4Download();
      case ToolStep.success:
        return _buildPage5Success();
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // ── PAGE 1: UPLOAD PAGE ───────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════
  Widget _buildPage1Upload() {
    return ListView(
      key: const ValueKey('page_1_upload'),
      padding: const EdgeInsets.all(16),
      children: [
        // Dropzone & File Pick Container
        widget.uploadWidget,
        const SizedBox(height: 18),

        // Tool Swipeable How It Works Card
        ToolHowItWorksCard(
          toolId: widget.toolId,
          primaryColor: widget.primaryColor,
        ),
        const SizedBox(height: 24),

        // Continue Action
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: widget.canProceedToEdition
                ? () {
                    HapticFeedback.selectionClick();
                    setState(() => _currentStep = ToolStep.edition);
                  }
                : null,
            icon: const Icon(LucideIcons.arrowRight, size: 18),
            label: const Text(
              'Continue to Editing',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              disabledForegroundColor: const Color(0xFF94A3B8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // ── PAGE 2: EDITING PAGE ──────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════
  Widget _buildPage2Edition() {
    return ListView(
      key: const ValueKey('page_2_edition'),
      padding: const EdgeInsets.all(16),
      children: [
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF87171)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Color(0xFFDC2626), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Custom Tool Parameters & Form
        widget.editionWidget,
        const SizedBox(height: 24),

        // Process Action Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _startProcessing,
            icon: const Icon(LucideIcons.play, size: 18),
            label: const Text(
              'Process & Apply Changes',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              foregroundColor: Colors.white,
              elevation: 3,
              shadowColor: widget.primaryColor.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _currentStep = ToolStep.upload),
            icon: const Icon(LucideIcons.arrowLeft, size: 16),
            label: const Text('Back to Upload'),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // ── PAGE 3: PROCESSING PAGE ───────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════
  Widget _buildPage3Processing() {
    return Center(
      key: const ValueKey('page_3_processing'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing Tool Icon Beacon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.12);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.primaryColor.withValues(alpha: 0.15),
                      border: Border.all(
                        color: widget.primaryColor.withValues(alpha: 0.5),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withValues(alpha: 0.25 * _pulseController.value),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.toolIcon,
                      size: 44,
                      color: widget.primaryColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            Text(
              widget.processingMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Running local transformation algorithms... $_processingPercent%',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),

            // Progress Bar
            SizedBox(
              width: 240,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _processingPercent / 100.0,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(height: 32),

            OutlinedButton(
              onPressed: () => setState(() => _currentStep = ToolStep.edition),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancel Processing'),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // ── PAGE 4: DOWNLOAD PAGE ─────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════
  Widget _buildPage4Download() {
    final fileName = _resultFile != null
        ? _resultFile!.uri.pathSegments.last
        : 'output_document.pdf';
    final outputSizeBytes = _resultFile != null && _resultFile!.existsSync()
        ? _resultFile!.lengthSync()
        : 0;

    return ListView(
      key: const ValueKey('page_4_download'),
      padding: const EdgeInsets.all(20),
      children: [
        // Download Overview Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.primaryColor.withValues(alpha: 0.12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.downloadCloud,
                  size: 32,
                  color: widget.primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Download Processed File',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Review generated file specifications before saving.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),

              // File Stats Summary Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(LucideIcons.fileCheck, size: 20, color: widget.primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Output Size',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                        Text(
                          _formatBytes(outputSizeBytes),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Primary Action: Download & Proceed to Success Auto-Download
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _proceedToAutoDownloadSuccess,
            icon: const Icon(LucideIcons.download, size: 18),
            label: const Text(
              'Download & Complete',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // ── PAGE 5: SUCCESS / AUTO-DOWNLOAD PAGE ──────────────────────────
  // ══════════════════════════════════════════════════════════════════
  Widget _buildPage5Success() {
    final fileName = _resultFile != null
        ? _resultFile!.uri.pathSegments.last
        : 'output_document.pdf';
    final outputSizeBytes = _resultFile != null && _resultFile!.existsSync()
        ? _resultFile!.lengthSync()
        : 0;

    return ListView(
      key: const ValueKey('page_5_success'),
      padding: const EdgeInsets.all(20),
      children: [
        // Success Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Checkmark Circle
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFECFDF5),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.checkCheck,
                  size: 36,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Success!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Document processed and saved to your device.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),

              // File Specs Capsule
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.fileCheck,
                        size: 22,
                        color: widget.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_formatBytes(outputSizeBytes)} • Saved locally',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2-Second Auto-Download Countdown Ticker Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _hasAutoDownloaded
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _hasAutoDownloaded
                        ? const Color(0xFF6EE7B7)
                        : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _hasAutoDownloaded
                          ? LucideIcons.download
                          : LucideIcons.timer,
                      size: 16,
                      color: _hasAutoDownloaded
                          ? const Color(0xFF059669)
                          : const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _hasAutoDownloaded
                          ? 'Auto-download complete ✓'
                          : 'Auto-downloading in $_autoDownloadSeconds seconds...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _hasAutoDownloaded
                            ? const Color(0xFF059669)
                            : const Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Action 1: Open Document
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_resultFile != null) {
                OpenFilex.open(_resultFile!.path);
              }
            },
            icon: const Icon(LucideIcons.externalLink, size: 18),
            label: const Text(
              'Open Document',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Action 2: Share with Apps
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              if (_resultFile != null) {
                Share.shareXFiles([XFile(_resultFile!.path)]);
              }
            },
            icon: const Icon(LucideIcons.share2, size: 17),
            label: const Text(
              'Share with Apps',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF334155),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Action 3: Process Another Document
        TextButton.icon(
          onPressed: _resetFlow,
          icon: const Icon(LucideIcons.plusCircle, size: 16),
          label: const Text('Process Another Document'),
        ),
      ],
    );
  }
}
