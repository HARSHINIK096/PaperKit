import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/app_shell.dart';

class InvoiceParserScreen extends StatefulWidget {
  const InvoiceParserScreen({super.key});

  @override
  State<InvoiceParserScreen> createState() => _InvoiceParserScreenState();
}

class _InvoiceParserScreenState extends State<InvoiceParserScreen> {
  File? _selectedFile;
  bool _isProcessing = false;
  Map<String, dynamic>? _invoiceData;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _invoiceData = null;
      });
    }
  }

  Future<void> _parseInvoice() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      final data = await ApiService().parseInvoiceDetails(_selectedFile!);
      setState(() {
        _invoiceData = data;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice Parsing Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      title: 'Invoice AI Parser',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              children: [
                if (_selectedFile == null)
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(LucideIcons.receipt, size: 20),
                      label: const Text('Select Invoice / Receipt PDF'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.receipt, color: Colors.green, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedFile!.uri.pathSegments.last, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${(_selectedFile!.lengthSync() / 1024).toStringAsFixed(1)} KB', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      TextButton(onPressed: _pickFile, child: const Text('Change')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    label: 'Parse Invoice Details',
                    icon: LucideIcons.sparkles,
                    isLoading: _isProcessing,
                    onPressed: _parseInvoice,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_invoiceData != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_invoiceData!['vendor']?.toString() ?? 'Invoice Details', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Chip(label: Text(_invoiceData!['totalAmount']?.toString() ?? '\$0.00', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                      ],
                    ),
                    const Divider(),
                    _buildInfoRow('Invoice #:', _invoiceData!['invoiceNumber']?.toString() ?? 'N/A'),
                    _buildInfoRow('Invoice Date:', _invoiceData!['invoiceDate']?.toString() ?? 'N/A'),
                    _buildInfoRow('Subtotal:', _invoiceData!['subtotal']?.toString() ?? '\$0.00'),
                    _buildInfoRow('Tax:', _invoiceData!['tax']?.toString() ?? '\$0.00'),
                    _buildInfoRow('Total Amount:', _invoiceData!['totalAmount']?.toString() ?? '\$0.00'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Line Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {
                    final summary = 'Vendor: ${_invoiceData!['vendor']}\nInvoice #: ${_invoiceData!['invoiceNumber']}\nTotal: ${_invoiceData!['totalAmount']}';
                    Clipboard.setData(ClipboardData(text: summary));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice details copied!')));
                  },
                  icon: const Icon(LucideIcons.copy, size: 16),
                  label: const Text('Copy Summary'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_invoiceData!['lineItems'] is List)
              ...(_invoiceData!['lineItems'] as List).map(
                (item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(LucideIcons.shoppingBag, size: 18)),
                    title: Text(item['description']?.toString() ?? 'Line Item'),
                    trailing: Text(item['amount']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
