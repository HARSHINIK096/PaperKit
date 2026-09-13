import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:qr/qr.dart';
import '../../core/models/history_item.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/share_service.dart';
import '../../core/widgets/app_shell.dart';
import 'models/qr_content_type.dart';
import 'models/qr_design_config.dart';
import 'services/qr_export_service.dart';
import 'services/qr_payload_formatter.dart';
import 'widgets/qr_content_form.dart';
import 'widgets/qr_custom_painter.dart';
import 'widgets/qr_design_controls.dart';
import 'widgets/qr_readability_badge.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  QrContentType _selectedType = QrContentType.url;
  String _formattedPayload = '';

  QrDesignConfig _config = const QrDesignConfig();
  bool _isExporting = false;
  File? _lastExportedFile;
  QrExportFormat _selectedExportFormat = QrExportFormat.png;

  void _onFormChanged(Map<String, String> values) {
    setState(() {
      _formattedPayload = QrPayloadFormatter.format(
        type: _selectedType,
        values: values,
      );
    });
  }

  Future<void> _exportQrCode() async {
    if (_formattedPayload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid content to generate QR code.')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final file = await QrExportService.export(
        data: _formattedPayload,
        config: _config,
        format: _selectedExportFormat,
      );

      final fileSize = await file.length();

      // Log to global MaskerV History
      if (mounted) {
        await context.read<HistoryProvider>().addRecord(
              HistoryItem(
                id: 'qr_gen_${DateTime.now().millisecondsSinceEpoch}',
                toolId: 'qr-generator',
                toolName: 'QR Code Generator',
                fileName: file.uri.pathSegments.last,
                outputPath: file.path,
                fileSize: fileSize,
                timestamp: DateTime.now(),
                success: true,
                details: '${_selectedType.label} • ${_selectedExportFormat.name.toUpperCase()}',
              ),
            );
      }

      setState(() {
        _lastExportedFile = file;
        _isExporting = false;
      });

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR Code saved to Phone Storage: ${file.path.split('/').last} (Downloads/MaskerV)'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFilex.open(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: const Color(0xFFE11D48)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build QR Image for Preview
    QrImage? qrImage;
    if (_formattedPayload.isNotEmpty) {
      try {
        final qrCode = QrCode.fromData(
          data: _formattedPayload,
          errorCorrectLevel: _config.recommendedErrorCorrectionLevel,
        );
        qrImage = QrImage(qrCode);
      } catch (_) {
        qrImage = null;
      }
    }

    return AppShell(
      title: 'QR Code Generator',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── LIVE PREVIEW & READABILITY CARD ──────────────────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.sparkles, size: 18, color: Color(0xFF2563EB)),
                          SizedBox(width: 8),
                          Text('Live Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      QrReadabilityBadge(config: _config),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // The Interactive Canvas Preview
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: _config.transparentBackground
                          ? Colors.grey.withValues(alpha: 0.1)
                          : _config.backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: qrImage != null
                        ? CustomPaint(
                            painter: QrCustomPainter(
                              qrImage: qrImage,
                              config: _config,
                            ),
                          )
                        : const Center(
                            child: Text(
                              'Enter content below\nto render QR Code',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                  ),
                  const SizedBox(height: 18),

                  // Quick Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isExporting ? null : _exportQrCode,
                        icon: _isExporting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(LucideIcons.download, size: 16),
                        label: Text(_isExporting ? 'Exporting...' : 'Export File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_lastExportedFile != null) ...[
                        OutlinedButton.icon(
                          onPressed: () => ShareService.shareFile(filePath: _lastExportedFile!.path),
                          icon: const Icon(LucideIcons.share2, size: 16),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.outlined(
                          onPressed: () => OpenFilex.open(_lastExportedFile!.path),
                          icon: const Icon(LucideIcons.externalLink, size: 16),
                          tooltip: 'Open in Viewer',
                        ),
                      ],
                    ],
                  ),

                  // Format Selector Pills
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: QrExportFormat.values.map((format) {
                      final isSelected = _selectedExportFormat == format;
                      return ChoiceChip(
                        label: Text(format.name.toUpperCase()),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedExportFormat = format),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── CONTENT TYPE SELECTOR ─────────────────────────────────────────
          const Text('1. Select Content Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),

          // Basic Content Types
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: QrContentType.values.where((t) => t.category == QrCategory.basic).map((t) {
                final isSelected = _selectedType == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(t.icon, size: 15, color: isSelected ? Colors.white : null),
                    label: Text(t.label),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2563EB),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _selectedType = t),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Social Presets
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: QrContentType.values.where((t) => t.category == QrCategory.social).map((t) {
                final isSelected = _selectedType == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(t.icon, size: 15, color: isSelected ? Colors.white : null),
                    label: Text(t.label),
                    selected: isSelected,
                    selectedColor: const Color(0xFF7C3AED),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _selectedType = t),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // ── CONTENT INPUT FORM ────────────────────────────────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_selectedType.icon, size: 18, color: const Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Text('Configure ${_selectedType.label}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  QrContentForm(
                    selectedType: _selectedType,
                    onChanged: _onFormChanged,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── VISUAL CUSTOMIZATION & DESIGN CONTROLS ────────────────────────
          const Text('2. Customize Visual Design', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: QrDesignControls(
                config: _config,
                onChanged: (newConfig) => setState(() => _config = newConfig),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
