import 'dart:io';
import 'dart:ui';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/models/audit_ledger_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/pdf_engine.dart';
import '../../core/services/storage_service.dart';

class LegalAuditService {
  final StorageService _storage = StorageService();
  final ApiService _apiService = ApiService();

  // Compute SHA-256 Checksum of File
  Future<String> computeSha256(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Record Verifiable Audit Event with Hash Chain
  Future<AuditEvent> logEvent({
    required String eventType,
    required File file,
    required String actorId,
    Map<String, dynamic>? metadata,
  }) async {
    final ledger = await loadLedger();
    final previousHash = ledger.isNotEmpty ? ledger.first.contentHash : '0' * 64;
    final contentHash = await computeSha256(file);

    final event = AuditEvent(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      eventType: eventType,
      documentId: file.path,
      documentName: file.uri.pathSegments.last,
      contentHash: contentHash,
      previousHash: previousHash,
      actorId: actorId,
      metadata: metadata,
    );

    ledger.insert(0, event);
    await _storage.saveAuditLedger(ledger.map((e) => e.toJson()).toList());
    return event;
  }

  Future<List<AuditEvent>> loadLedger() async {
    final rawList = await _storage.getAuditLedger();
    return rawList.map((m) => AuditEvent.fromJson(m)).toList();
  }

  // Analyze Contract Clauses with page anchors
  Future<List<ContractClause>> analyzeContract(File file) async {
    try {
      final raw = await _apiService.analyzeContract(file: file);
      if (raw.containsKey('clauses') && raw['clauses'] is List) {
        return (raw['clauses'] as List)
            .map((c) => ContractClause.fromJson(Map<String, dynamic>.from(c)))
            .toList();
      }
    } catch (_) {}

    // Fallback: Local rule-based contract clause extraction
    final text = await PdfEngine.extractTextFromPdf(file);
    final lines = text.split(RegExp(r'\r?\n'));
    final List<ContractClause> clauses = [];

    int currentPage = 1;
    for (final line in lines) {
      final l = line.toLowerCase();
      if (l.contains('party') || l.contains('between') || l.contains('agreement')) {
        clauses.add(
          ContractClause(
            category: 'Parties',
            title: 'Agreement Parties',
            snippet: line.trim(),
            pageNumber: currentPage,
          ),
        );
      } else if (l.contains('terminat') || l.contains('cancel')) {
        clauses.add(
          ContractClause(
            category: 'Termination',
            title: 'Termination Clause',
            snippet: line.trim(),
            pageNumber: currentPage,
          ),
        );
      } else if (l.contains('liabil') || l.contains('indemn') || l.contains('damage')) {
        clauses.add(
          ContractClause(
            category: 'Liability',
            title: 'Limitation of Liability',
            snippet: line.trim(),
            pageNumber: currentPage,
          ),
        );
      } else if (l.contains('payment') || l.contains('fee') || l.contains('usd') || l.contains('\$')) {
        clauses.add(
          ContractClause(
            category: 'Payment & Fee',
            title: 'Payment Terms',
            snippet: line.trim(),
            pageNumber: currentPage,
          ),
        );
      }
      if (clauses.length >= 15) break;
    }

    return clauses;
  }

  // Apply Bates Stamping to PDF Pages
  Future<File> applyBatesStamping(File inputFile, BatesConfig config) async {
    final bytes = await inputFile.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    final font = PdfStandardFont(PdfFontFamily.helvetica, config.fontSize);
    final brush = PdfSolidBrush(PdfColor(
      (config.textColorHex >> 16) & 0xFF,
      (config.textColorHex >> 8) & 0xFF,
      config.textColorHex & 0xFF,
    ));

    for (int i = 0; i < document.pages.count; i++) {
      final page = document.pages[i];
      final batesStr = config.formatNumber(i);
      final textSize = font.measureString(batesStr);

      Offset position;
      switch (config.position) {
        case 'top-left':
          position = const Offset(15, 15);
          break;
        case 'top-right':
          position = Offset(page.size.width - textSize.width - 15, 15);
          break;
        case 'bottom-left':
          position = Offset(15, page.size.height - textSize.height - 15);
          break;
        case 'bottom-right':
        default:
          position = Offset(page.size.width - textSize.width - 15, page.size.height - textSize.height - 15);
          break;
      }

      page.graphics.drawString(batesStr, font, brush: brush, bounds: Rect.fromLTWH(position.dx, position.dy, textSize.width + 10, textSize.height + 5));
    }

    final outputDir = await getApplicationDocumentsDirectory();
    final outputFile = File('${outputDir.path}/bates_${inputFile.uri.pathSegments.last}');
    await outputFile.writeAsBytes(document.saveSync());
    document.dispose();
    return outputFile;
  }

  // Generate Exhibit Index Document
  Future<File> generateExhibitIndex(List<ExhibitIndexItem> exhibits, String outputFileName) async {
    final document = PdfDocument();
    final page = document.pages.add();

    final fontTitle = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final fontHeader = PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold);
    final fontBody = PdfStandardFont(PdfFontFamily.helvetica, 10);

    page.graphics.drawString('LEGAL EXHIBIT INDEX', fontTitle, bounds: const Rect.fromLTWH(0, 0, 500, 30));

    double y = 45;
    // Draw Header Table
    page.graphics.drawString('Exhibit #', fontHeader, bounds: Rect.fromLTWH(0, y, 70, 20));
    page.graphics.drawString('Document Name', fontHeader, bounds: Rect.fromLTWH(75, y, 180, 20));
    page.graphics.drawString('Bates Range', fontHeader, bounds: Rect.fromLTWH(260, y, 110, 20));
    page.graphics.drawString('Pages', fontHeader, bounds: Rect.fromLTWH(375, y, 40, 20));
    page.graphics.drawString('Description', fontHeader, bounds: Rect.fromLTWH(420, y, 100, 20));
    y += 25;

    for (final item in exhibits) {
      page.graphics.drawString(item.exhibitId, fontBody, bounds: Rect.fromLTWH(0, y, 70, 20));
      page.graphics.drawString(item.documentName, fontBody, bounds: Rect.fromLTWH(75, y, 180, 20));
      page.graphics.drawString(item.batesRange, fontBody, bounds: Rect.fromLTWH(260, y, 110, 20));
      page.graphics.drawString(item.pageCount.toString(), fontBody, bounds: Rect.fromLTWH(375, y, 40, 20));
      page.graphics.drawString(item.description, fontBody, bounds: Rect.fromLTWH(420, y, 100, 20));
      y += 20;
    }

    final outputDir = await getApplicationDocumentsDirectory();
    final outputFile = File('${outputDir.path}/$outputFileName.pdf');
    await outputFile.writeAsBytes(document.saveSync());
    document.dispose();
    return outputFile;
  }
}
