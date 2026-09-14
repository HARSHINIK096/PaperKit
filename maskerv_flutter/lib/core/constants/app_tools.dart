import '../models/tool_item.dart';
import 'tool_registry.dart';

export 'tool_registry.dart';

/// AppTools — maintained for backward compatibility.
///
/// All lists are backed by [ToolRegistry] and [DomainRegistry].
class AppTools {
  AppTools._();

  // ── Featured & Quick Tools ─────────────────────────────────────────────
  static List<ToolItem> get featuredTools => ToolRegistry.featuredTools;
  static List<ToolItem> get quickTools => ToolRegistry.quickTools;

  // ── Domain Lists ───────────────────────────────────────────────────────
  static List<ToolItem> getByDomainNumber(int number) =>
      ToolRegistry.getByDomainNumber(number);
  static List<ToolItem> getByDomainId(DomainId domainId) =>
      ToolRegistry.getByDomainId(domainId);
  static List<ToolItem> get generalUtilities => ToolRegistry.generalUtilities;
  static List<ToolItem> getCrossDomainTools(int domainNumber) =>
      ToolRegistry.getCrossDomainTools(domainNumber);

  // ── Domain 1: File Manipulation & Document Tools ───────────────────────
  static List<ToolItem> get fileManipulationTools =>
      ToolRegistry.getByDomainNumber(1);
  static List<ToolItem> get pdfTools => ToolRegistry.getByDomainNumber(1);
  static List<ToolItem> get conversionTools => [
        ToolRegistry.wordToPdf,
        ToolRegistry.pdfToWord,
        ToolRegistry.excelToPdf,
        ToolRegistry.pdfToExcel,
        ToolRegistry.pptToPdf,
        ToolRegistry.pdfToPpt,
        ToolRegistry.imageToPdf,
        ToolRegistry.pdfToImage,
      ];

  // ── Domain 2: Security, Cryptography & Compliance Vault ────────────────
  static List<ToolItem> get securityTools => ToolRegistry.getByDomainNumber(2);

  // ── Domain 3: Academic & Research Intelligence Suite ───────────────────
  static List<ToolItem> get academicTools => ToolRegistry.getByDomainNumber(3);
  static List<ToolItem> get aiTools => ToolRegistry.getByDomainNumber(3);

  // ── Domain 4: Optical Scanning & Vision Engine (OCR) ───────────────────
  static List<ToolItem> get scannerTools => ToolRegistry.getByDomainNumber(4);
  static List<ToolItem> get imageFormatTools => [
        ToolRegistry.imageConverter,
        ToolRegistry.imageManipulator,
        ToolRegistry.imageResizer,
      ];
  static List<ToolItem> get imageCompressorTools => [
        ToolRegistry.imageCompressor,
      ];

  // ── Domain 6: Multi-Modal Voice & Podcast Audio Studio ─────────────────
  static List<ToolItem> get audioConverterTools => [
        ToolRegistry.audioConverter,
      ];

  // ── Domain 8: Legal & Forensic Compliance Audit Suite ──────────────────
  static List<ToolItem> get legalTools => ToolRegistry.getByDomainNumber(8);

  // ── Domain 9: Interactive Form Builder & Auto-Fill Engine ──────────────
  static List<ToolItem> get formTools => ToolRegistry.getByDomainNumber(9);

  // ── Domain 10: Visual Mind Mapping & Diagram Studio ────────────────────
  static List<ToolItem> get diagramTools => ToolRegistry.getByDomainNumber(10);

  // ── Domain 13: Data Analytics & Tabular Data Extractor ─────────────────
  static List<ToolItem> get analyticsTools => ToolRegistry.getByDomainNumber(13);

  // ── Domain 14: Translation & Multi-Lingual Localization Hub ────────────
  static List<ToolItem> get translationTools => ToolRegistry.getByDomainNumber(14);

  // ── Domain 15: Automated Publishing & e-Book Studio ────────────────────
  static List<ToolItem> get publishingTools => ToolRegistry.getByDomainNumber(15);

  // ── General Utilities ──────────────────────────────────────────────────
  static List<ToolItem> get qrTools => [ToolRegistry.qrGenerator, ToolRegistry.qrScanner];
  static List<ToolItem> get videoConverterTools => [ToolRegistry.videoConverter, ToolRegistry.videoToFrames];
  static List<ToolItem> get videoCompressorTools => [ToolRegistry.videoCompressor];
  static List<ToolItem> get videoTools => [
        ToolRegistry.videoConverter,
        ToolRegistry.videoCompressor,
        ToolRegistry.videoToFrames,
        ToolRegistry.videoEditor,
      ];
  static List<ToolItem> get secureShareTools => [ToolRegistry.secureShare];
  static List<ToolItem> get archiveTools => [ToolRegistry.archiveStudio];

  // ── All Tools (deduplicated) ───────────────────────────────────────────
  static List<ToolItem> get allTools => ToolRegistry.allTools;

  // ── Lookup ─────────────────────────────────────────────────────────────
  static ToolItem? getById(String id) => ToolRegistry.getById(id);
  static ToolItem? getByRoute(String route) => ToolRegistry.getByRoute(route);
  static List<ToolItem> search(String query) => ToolRegistry.search(query);

  static List<ToolItem> getTopToolsForCategory(String categoryKey) =>
      ToolRegistry.getTopToolsForCategory(categoryKey);
}
