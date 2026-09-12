import '../models/tool_item.dart';
import 'tool_registry.dart';

export 'tool_registry.dart';

/// AppTools — maintained for backward compatibility.
///
/// All lists are now backed by [ToolRegistry] — no duplicate ToolItem
/// definitions exist here. Callers that imported AppTools continue to work;
/// new code should prefer ToolRegistry directly.
class AppTools {
  AppTools._();

  // ── Featured & Quick Tools ─────────────────────────────────────────────
  static List<ToolItem> get featuredTools => ToolRegistry.featuredTools;
  static List<ToolItem> get quickTools => ToolRegistry.quickTools;

  // ── Category Lists ─────────────────────────────────────────────────────
  static List<ToolItem> get aiTools => ToolRegistry.aiTools;
  static List<ToolItem> get pdfTools =>
      ToolRegistry.getByCategory(ToolCategory.pdf);
  static List<ToolItem> get securityTools =>
      ToolRegistry.getByCategory(ToolCategory.security);
  static List<ToolItem> get conversionTools =>
      ToolRegistry.getByCategory(ToolCategory.convert);
  static List<ToolItem> get imageFormatTools =>
      ToolRegistry.getByCategory(ToolCategory.image);
  static List<ToolItem> get imageCompressorTools =>
      ToolRegistry.getByCategory(ToolCategory.image);
  static List<ToolItem> get videoConverterTools =>
      [ToolRegistry.videoConverter];
  static List<ToolItem> get videoCompressorTools =>
      [ToolRegistry.videoCompressor];
  static List<ToolItem> get archiveTools =>
      ToolRegistry.getByCategory(ToolCategory.archive);
  static List<ToolItem> get audioConverterTools =>
      ToolRegistry.getByCategory(ToolCategory.audio);
  static List<ToolItem> get academicTools => ToolRegistry.academicTools;
  static List<ToolItem> get scannerTools => ToolRegistry.scannerTools;
  static List<ToolItem> get formTools => ToolRegistry.formTools;

  // ── All Tools (deduplicated) ───────────────────────────────────────────
  static List<ToolItem> get allTools => ToolRegistry.allTools;

  // ── Lookup ─────────────────────────────────────────────────────────────
  static ToolItem? getById(String id) => ToolRegistry.getById(id);
  static ToolItem? getByRoute(String route) => ToolRegistry.getByRoute(route);
  static List<ToolItem> search(String query) => ToolRegistry.search(query);

  /// Returns top tools for a category. Delegates to canonical registry.
  static List<ToolItem> getTopToolsForCategory(String categoryKey) =>
      ToolRegistry.getTopToolsForCategory(categoryKey);
}
