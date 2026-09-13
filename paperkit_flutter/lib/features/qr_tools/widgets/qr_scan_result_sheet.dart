import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/share_service.dart';
import '../models/qr_parsed_payload.dart';

class QrScanResultSheet extends StatefulWidget {
  final QrParsedPayload payload;
  final VoidCallback onDismiss;

  const QrScanResultSheet({
    super.key,
    required this.payload,
    required this.onDismiss,
  });

  @override
  State<QrScanResultSheet> createState() => _QrScanResultSheetState();
}

class _QrScanResultSheetState extends State<QrScanResultSheet> {
  bool _revealWifiPassword = false;

  Future<void> _launchExternalUrl(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri != null) {
      if (widget.payload.isSuspiciousUrl) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(LucideIcons.triangleAlert, color: Color(0xFFF59E0B)),
                SizedBox(width: 8),
                Text('Security Notice'),
              ],
            ),
            content: Text(
              'This URL is not using HTTPS or is an IP/untrusted domain:\n\n$urlString\n\nDo you still wish to open it externally?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Proceed Anyway'),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payload;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Type Badge and Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.scanLine, size: 14, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Text(
                          p.type.displayName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: widget.onDismiss,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title & Subtitle
              Text(
                p.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (p.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  p.subtitle!,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],

              // Suspicious URL Warning
              if (p.isSuspiciousUrl) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.triangleAlert, color: Color(0xFFF59E0B), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Caution: This URL does not use encrypted HTTPS or is an unusual domain.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Payload Details Panel
              const SizedBox(height: 16),
              _buildTypeSpecificDetails(p),

              // Raw Data Box
              const SizedBox(height: 16),
              const Text('Raw Decoded Payload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                child: SelectableText(
                  p.rawData,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  maxLines: 4,
                ),
              ),

              // Action Buttons
              const SizedBox(height: 20),
              _buildActionButtons(p),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSpecificDetails(QrParsedPayload p) {
    if (p.type == QrPayloadType.wifi) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(LucideIcons.wifi, size: 18, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text('Network: ${p.ssid}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.key, size: 18, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _revealWifiPassword ? (p.password ?? 'None') : '••••••••••••',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _revealWifiPassword = !_revealWifiPassword),
                  child: Text(_revealWifiPassword ? 'Hide' : 'Reveal'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (p.type == QrPayloadType.vcard) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.contactName != null && p.contactName!.isNotEmpty)
              Text('Name: ${p.contactName!}', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (p.phone != null && p.phone!.isNotEmpty)
              Text('Phone: ${p.phone!}', style: const TextStyle(fontSize: 13)),
            if (p.email != null && p.email!.isNotEmpty)
              Text('Email: ${p.email!}', style: const TextStyle(fontSize: 13)),
            if (p.organization != null && p.organization!.isNotEmpty)
              Text('Organization: ${p.organization!}', style: const TextStyle(fontSize: 13)),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButtons(QrParsedPayload p) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (p.type == QrPayloadType.url && p.url != null && p.url!.contains('/share/'))
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              final shareId = p.url!.split('/share/').last.split('?').first.trim();
              if (shareId.isNotEmpty) {
                context.push('/share/$shareId');
              }
            },
            icon: const Icon(LucideIcons.fileKey, size: 16),
            label: const Text('Open Secure Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
            ),
          ),
        if (p.type == QrPayloadType.url && p.url != null)
          ElevatedButton.icon(
            onPressed: () => _launchExternalUrl(p.url!),
            icon: const Icon(LucideIcons.externalLink, size: 16),
            label: const Text('Open in Browser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
          ),
        if (p.type == QrPayloadType.email && p.email != null)
          ElevatedButton.icon(
            onPressed: () => _launchExternalUrl('mailto:${p.email}?subject=${Uri.encodeComponent(p.subject ?? '')}&body=${Uri.encodeComponent(p.body ?? '')}'),
            icon: const Icon(LucideIcons.mail, size: 16),
            label: const Text('Send Email'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
          ),
        if (p.type == QrPayloadType.phone && p.phone != null)
          ElevatedButton.icon(
            onPressed: () => _launchExternalUrl('tel:${p.phone}'),
            icon: const Icon(LucideIcons.phoneCall, size: 16),
            label: const Text('Call Number'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
          ),
        if (p.type == QrPayloadType.sms && p.phone != null)
          ElevatedButton.icon(
            onPressed: () => _launchExternalUrl('sms:${p.phone}?body=${Uri.encodeComponent(p.smsBody ?? '')}'),
            icon: const Icon(LucideIcons.messageSquare, size: 16),
            label: const Text('Send SMS'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
          ),
        if (p.type == QrPayloadType.geo && p.latitude != null && p.longitude != null)
          ElevatedButton.icon(
            onPressed: () => _launchExternalUrl('https://maps.google.com/?q=${p.latitude},${p.longitude}'),
            icon: const Icon(LucideIcons.mapPin, size: 16),
            label: const Text('Open in Maps'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white),
          ),
        if (p.type == QrPayloadType.wifi && p.password != null)
          ElevatedButton.icon(
            onPressed: () => _copyToClipboard(p.password!, 'Wi-Fi Password'),
            icon: const Icon(LucideIcons.copy, size: 16),
            label: const Text('Copy Wi-Fi Password'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
          ),

        // Universal Copy & Share Actions
        OutlinedButton.icon(
          onPressed: () => _copyToClipboard(p.rawData, 'QR Content'),
          icon: const Icon(LucideIcons.copy, size: 16),
          label: const Text('Copy Raw Text'),
        ),
        OutlinedButton.icon(
          onPressed: () => ShareService.shareText(content: p.rawData, subject: 'Scanned QR Code Content'),
          icon: const Icon(LucideIcons.share2, size: 16),
          label: const Text('Share Text'),
        ),
      ],
    );
  }
}
