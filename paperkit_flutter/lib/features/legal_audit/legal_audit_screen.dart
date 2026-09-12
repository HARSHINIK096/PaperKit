import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/audit_ledger_model.dart';
import '../../core/services/share_service.dart';
import 'legal_audit_service.dart';

class LegalAuditScreen extends StatefulWidget {
  const LegalAuditScreen({super.key});

  @override
  State<LegalAuditScreen> createState() => _LegalAuditScreenState();
}

class _LegalAuditScreenState extends State<LegalAuditScreen> with SingleTickerProviderStateMixin {
  final LegalAuditService _service = LegalAuditService();
  late TabController _tabController;

  File? _selectedFile;
  String? _documentHash;
  List<AuditEvent> _ledger = [];
  List<ContractClause> _clauses = [];
  bool _isLoading = false;

  // Bates Stamping Config
  String _batesPrefix = 'EXHIBIT-';
  int _batesStartNum = 1;
  String _batesPosition = 'bottom-right';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLedger();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLedger() async {
    final loaded = await _service.loadLedger();
    setState(() => _ledger = loaded);
  }

  Future<void> _pickDocument() async {
    setState(() => _isLoading = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final hash = await _service.computeSha256(file);
      final clauses = await _service.analyzeContract(file);

      // Record audit event
      await _service.logEvent(
        eventType: 'imported_audit',
        file: file,
        actorId: 'user_local',
      );

      setState(() {
        _selectedFile = file;
        _documentHash = hash;
        _clauses = clauses;
        _isLoading = false;
      });
      await _loadLedger();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyBatesStamping() async {
    if (_selectedFile == null) return;
    setState(() => _isLoading = true);

    final config = BatesConfig(
      prefix: _batesPrefix,
      startNumber: _batesStartNum,
      position: _batesPosition,
    );

    final stampedFile = await _service.applyBatesStamping(_selectedFile!, config);

    await _service.logEvent(
      eventType: 'bates_stamped',
      file: stampedFile,
      actorId: 'user_local',
    );

    setState(() => _isLoading = false);
    await _loadLedger();
    ShareService.shareFile(filePath: stampedFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal & Forensic Compliance Suite'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(LucideIcons.shieldCheck), text: 'Integrity & Hash'),
            Tab(icon: Icon(LucideIcons.fileText), text: 'Contract Analyzer'),
            Tab(icon: Icon(LucideIcons.stamp), text: 'Bates Stamping'),
            Tab(icon: Icon(LucideIcons.listOrdered), text: 'Audit Ledger'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIntegrityTab(),
          _buildContractTab(),
          _buildBatesTab(),
          _buildLedgerTab(),
        ],
      ),
    );
  }

  Widget _buildIntegrityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickDocument,
            icon: const Icon(LucideIcons.fileUp),
            label: const Text('Select PDF Document'),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_selectedFile == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Select a legal PDF to generate SHA-256 integrity checksums and record verifiable audit trail logs.'),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Document: ${_selectedFile!.uri.pathSegments.last}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(),
                    const Text('SHA-256 Checksum:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    SelectableText(_documentHash ?? '', style: const TextStyle(fontFamily: 'Monospace', fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContractTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _clauses.length,
      itemBuilder: (context, index) {
        final clause = _clauses[index];
        return Card(
          child: ListTile(
            title: Text(clause.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${clause.snippet}\n(Page ${clause.pageNumber})'),
            trailing: Chip(label: Text(clause.category)),
          ),
        );
      },
    );
  }

  Widget _buildBatesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Bates Prefix'),
            onChanged: (val) => _batesPrefix = val,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _selectedFile == null ? null : _applyBatesStamping,
            icon: const Icon(LucideIcons.stamp),
            label: const Text('Apply Bates Stamping & Export'),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ledger.length,
      itemBuilder: (context, index) {
        final event = _ledger[index];
        return Card(
          child: ListTile(
            leading: const Icon(LucideIcons.shieldAlert),
            title: Text(event.eventType.toUpperCase()),
            subtitle: Text('${event.documentName}\nHash: ${event.contentHash.substring(0, 16)}...'),
            trailing: Text(event.timestamp.toString().split(' ')[0]),
          ),
        );
      },
    );
  }
}
