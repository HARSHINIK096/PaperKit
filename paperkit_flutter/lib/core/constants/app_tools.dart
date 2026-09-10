import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/tool_item.dart';
import '../theme/app_colors.dart';

class AppTools {
  // PDF Tools
  static const List<ToolItem> pdfTools = [
    ToolItem(
      id: 'merge-pdf',
      label: 'Merge PDF',
      description: 'Combine multiple PDFs into one unified document',
      route: '/tools/merge',
      icon: LucideIcons.files,
      color: AppColors.toolBlue,
      softColor: AppColors.toolBlueSoft,
      category: ToolCategory.pdf,
    ),
    ToolItem(
      id: 'split-pdf',
      label: 'Split PDF',
      description: 'Split by page ranges or extract single pages',
      route: '/tools/split',
      icon: LucideIcons.scissors,
      color: AppColors.toolRed,
      softColor: AppColors.toolRedSoft,
      category: ToolCategory.pdf,
    ),
    ToolItem(
      id: 'compress-pdf',
      label: 'Compress PDF',
      description: 'Reduce PDF size with extreme/balanced compression',
      route: '/tools/compress',
      icon: LucideIcons.minimize2,
      color: AppColors.toolOrange,
      softColor: AppColors.toolOrangeSoft,
      category: ToolCategory.pdf,
    ),
    ToolItem(
      id: 'convert-pdf',
      label: 'Convert Document',
      description: 'Convert between Word, Excel, PPT, Image and PDF',
      route: '/tools/convert',
      icon: LucideIcons.fileSpreadsheet,
      color: AppColors.toolGreen,
      softColor: AppColors.toolGreenSoft,
      category: ToolCategory.pdf,
    ),
    ToolItem(
      id: 'organize-pages',
      label: 'Organize Pages',
      description: 'Reorder, delete, duplicate & rotate PDF pages',
      route: '/tools/organize-pages',
      icon: LucideIcons.layers,
      color: AppColors.toolIndigo,
      softColor: AppColors.toolIndigoSoft,
      category: ToolCategory.pdf,
    ),
    ToolItem(
      id: 'extract-pages',
      label: 'Extract Pages',
      description: 'Extract specific pages into a brand new PDF',
      route: '/tools/extract-pages',
      icon: LucideIcons.fileOutput,
      color: AppColors.toolTeal,
      softColor: AppColors.toolTealSoft,
      category: ToolCategory.pdf,
    ),
    ToolItem(
      id: 'rotate-pdf',
      label: 'Rotate PDF',
      description: 'Rotate PDF orientation permanently by 90/180/270°',
      route: '/tools/rotate',
      icon: LucideIcons.rotateCw,
      color: AppColors.toolBlue,
      softColor: AppColors.toolBlueSoft,
      category: ToolCategory.pdf,
    ),
    ToolItem(
      id: 'watermark',
      label: 'Watermark',
      description: 'Add custom text stamp or image watermark',
      route: '/tools/watermark',
      icon: LucideIcons.stamp,
      color: AppColors.toolTeal,
      softColor: AppColors.toolTealSoft,
      category: ToolCategory.pdf,
    ),
    ToolItem(
      id: 'pdf-to-pdfa',
      label: 'PDF to PDF/A',
      description: 'Convert to ISO-compliant archival standard',
      route: '/tools/pdf-to-pdfa',
      icon: LucideIcons.archive,
      color: AppColors.toolPurple,
      softColor: AppColors.toolPurpleSoft,
      category: ToolCategory.pdf,
    ),
    ToolItem(
      id: 'pdf-editor',
      label: 'PDF Editor',
      description: 'In-place text editing, annotations & drawings',
      route: '/tools/pdf-editor',
      icon: LucideIcons.fileSignature,
      color: AppColors.toolPurple,
      softColor: AppColors.toolPurpleSoft,
      category: ToolCategory.pdf,
      isPro: true,
    ),
  ];

  // AI Intelligence Tools
  static const List<ToolItem> aiTools = [
    ToolItem(
      id: 'ai-ocr',
      label: 'OCR Text & Layout',
      description: 'Extract text & layout data from scans and photos',
      route: '/ai/ocr',
      icon: LucideIcons.scanLine,
      color: AppColors.toolBlue,
      softColor: AppColors.toolBlueSoft,
      category: ToolCategory.ai,
      isAi: true,
    ),
    ToolItem(
      id: 'summarize-pdf',
      label: 'AI Summary',
      description: 'Executive summary, key insights & bullet action points',
      route: '/ai/summarize',
      icon: LucideIcons.sparkles,
      color: AppColors.toolPurple,
      softColor: AppColors.toolPurpleSoft,
      category: ToolCategory.ai,
      isAi: true,
    ),
    ToolItem(
      id: 'ask-pdf',
      label: 'AI Document Chat',
      description: 'Ask questions & chat with your documents interactively',
      route: '/ai/ask',
      icon: LucideIcons.messageSquare,
      color: AppColors.toolBlue,
      softColor: AppColors.toolBlueSoft,
      category: ToolCategory.ai,
      isAi: true,
    ),
    ToolItem(
      id: 'semantic-compare',
      label: 'Semantic Compare',
      description: 'Compare meaning, changes & contracts side by side',
      route: '/ai/compare',
      icon: LucideIcons.gitCompare,
      color: AppColors.toolPurple,
      softColor: AppColors.toolPurpleSoft,
      category: ToolCategory.ai,
      isAi: true,
    ),
    ToolItem(
      id: 'similarity-matrix',
      label: 'Similarity Score',
      description: 'Cross-document similarity analysis & plagiarism check',
      route: '/ai/similarity',
      icon: LucideIcons.layoutGrid,
      color: AppColors.toolIndigo,
      softColor: AppColors.toolIndigoSoft,
      category: ToolCategory.ai,
      isAi: true,
    ),
    ToolItem(
      id: 'semantic-search',
      label: 'Semantic Search',
      description: 'Search documents by concept and intent, not just keywords',
      route: '/ai/search',
      icon: LucideIcons.search,
      color: AppColors.toolTeal,
      softColor: AppColors.toolTealSoft,
      category: ToolCategory.ai,
      isAi: true,
    ),
    ToolItem(
      id: 'classify-pdf',
      label: 'Document Classify',
      description: 'Auto-categorize invoices, resumes, contracts & reports',
      route: '/ai/classify',
      icon: LucideIcons.tag,
      color: AppColors.toolOrange,
      softColor: AppColors.toolOrangeSoft,
      category: ToolCategory.ai,
      isAi: true,
    ),
    ToolItem(
      id: 'extract-info',
      label: 'Information Extract',
      description: 'Extract key entities, dates, totals & key-values',
      route: '/ai/extract-info',
      icon: LucideIcons.fileSearch,
      color: AppColors.toolPink,
      softColor: AppColors.toolPinkSoft,
      category: ToolCategory.ai,
      isAi: true,
    ),
    ToolItem(
      id: 'translate-pdf',
      label: 'AI Translation',
      description: 'Translate documents into 15+ global languages',
      route: '/ai/translate',
      icon: LucideIcons.languages,
      color: AppColors.toolGreen,
      softColor: AppColors.toolGreenSoft,
      category: ToolCategory.ai,
      isAi: true,
    ),
    ToolItem(
      id: 'writing-assistant',
      label: 'Writing Assistant',
      description: 'Polish style, tone, academic grammar & clarity',
      route: '/ai/writing-assist',
      icon: LucideIcons.penTool,
      color: AppColors.toolGreen,
      softColor: AppColors.toolGreenSoft,
      category: ToolCategory.ai,
      isAi: true,
    ),
    ToolItem(
      id: 'quality-checker',
      label: 'Quality Checker',
      description: 'Audit citation integrity, readability & formatting',
      route: '/ai/quality-checker',
      icon: LucideIcons.checkCheck,
      color: AppColors.toolTeal,
      softColor: AppColors.toolTealSoft,
      category: ToolCategory.ai,
      isAi: true,
    ),
    ToolItem(
      id: 'extract-tables',
      label: 'Extract Tables',
      description: 'Detect & convert PDF tables into Excel / CSV / JSON',
      route: '/ai/extract-tables',
      icon: LucideIcons.table,
      color: AppColors.toolOrange,
      softColor: AppColors.toolOrangeSoft,
      category: ToolCategory.ai,
      isAi: true,
    ),
    ToolItem(
      id: 'image-enhancer',
      label: 'AI Image Enhancer',
      description: 'Upscale resolution, remove grain & enhance text clarity',
      route: '/ai/image-enhancer',
      icon: LucideIcons.imagePlus,
      color: AppColors.toolPink,
      softColor: AppColors.toolPinkSoft,
      category: ToolCategory.ai,
      isAi: true,
    ),
  ];

  // Security & Privacy Tools
  static const List<ToolItem> securityTools = [
    ToolItem(
      id: 'protect-pdf',
      label: 'Protect PDF',
      description: '256-bit AES password encryption & permission locks',
      route: '/security/protect',
      icon: LucideIcons.lock,
      color: AppColors.toolRed,
      softColor: AppColors.toolRedSoft,
      category: ToolCategory.security,
    ),
    ToolItem(
      id: 'smart-redaction',
      label: 'Redact Data',
      description: 'Auto-scan PII & permanently blackout sensitive data',
      route: '/security/redact',
      icon: LucideIcons.eyeOff,
      color: AppColors.toolOrange,
      softColor: AppColors.toolOrangeSoft,
      category: ToolCategory.security,
    ),
    ToolItem(
      id: 'digital-sign',
      label: 'Digital Sign',
      description: 'Draw, import, or stamp legally valid digital signatures',
      route: '/security/sign',
      icon: LucideIcons.fileSignature,
      color: AppColors.toolIndigo,
      softColor: AppColors.toolIndigoSoft,
      category: ToolCategory.security,
    ),
    ToolItem(
      id: 'metadata-manager',
      label: 'Metadata Manager',
      description: 'View, edit, or wipe author and creation metadata',
      route: '/security/metadata',
      icon: LucideIcons.info,
      color: AppColors.toolBlue,
      softColor: AppColors.toolBlueSoft,
      category: ToolCategory.security,
    ),
  ];

  // Image & Media Tools
  static const List<ToolItem> mediaTools = [
    ToolItem(
      id: 'image-converter',
      label: 'Image Converter',
      description: 'Convert JPG, PNG, WEBP, HEIC & BMP formats',
      route: '/tools/image-converter',
      icon: LucideIcons.image,
      color: AppColors.toolBlue,
      softColor: AppColors.toolBlueSoft,
      category: ToolCategory.image,
    ),
    ToolItem(
      id: 'image-compressor',
      label: 'Image Compressor',
      description: 'Compress image dimensions and quality with presets',
      route: '/tools/image-compressor',
      icon: LucideIcons.fileArchive,
      color: AppColors.toolGreen,
      softColor: AppColors.toolGreenSoft,
      category: ToolCategory.image,
    ),
    ToolItem(
      id: 'image-manipulator',
      label: 'Image Adjust & Filter',
      description: 'Adjust brightness, contrast, crop, rotate & filters',
      route: '/tools/image-manipulator',
      icon: LucideIcons.sliders,
      color: AppColors.toolPurple,
      softColor: AppColors.toolPurpleSoft,
      category: ToolCategory.image,
    ),
    ToolItem(
      id: 'media-downloader',
      label: 'Media Downloader',
      description: 'Download media from YouTube, Spotify & URL links',
      route: '/tools/media-downloader',
      icon: LucideIcons.downloadCloud,
      color: AppColors.toolRed,
      softColor: AppColors.toolRedSoft,
      category: ToolCategory.media,
    ),
    ToolItem(
      id: 'audio-converter',
      label: 'Audio Converter',
      description: 'Convert audio to MP3, WAV, AAC & OGG formats',
      route: '/tools/audio-converter',
      icon: LucideIcons.music,
      color: AppColors.toolGreen,
      softColor: AppColors.toolGreenSoft,
      category: ToolCategory.audio,
    ),
    ToolItem(
      id: 'video-converter',
      label: 'Video Converter',
      description: 'Convert video formats to MP4, WebM, MOV & GIF',
      route: '/tools/video-converter',
      icon: LucideIcons.video,
      color: AppColors.toolBlue,
      softColor: AppColors.toolBlueSoft,
      category: ToolCategory.video,
    ),
    ToolItem(
      id: 'video-compressor',
      label: 'Video Compressor',
      description: 'Optimize video file size without sacrificing clarity',
      route: '/tools/video-compressor',
      icon: LucideIcons.minimize,
      color: AppColors.toolOrange,
      softColor: AppColors.toolOrangeSoft,
      category: ToolCategory.video,
    ),
    ToolItem(
      id: 'archive-studio',
      label: 'Archive Studio',
      description: 'Create & extract ZIP, TAR, GZ & RAR archives',
      route: '/tools/archive',
      icon: LucideIcons.archive,
      color: AppColors.toolOrange,
      softColor: AppColors.toolOrangeSoft,
      category: ToolCategory.archive,
    ),
  ];

  // Quick Tools for Home Screen
  static List<ToolItem> get quickTools => [
    pdfTools[9], // PDF Editor
    pdfTools[0], // Merge PDF
    pdfTools[1], // Split PDF
    pdfTools[2], // Compress PDF
    aiTools[1],  // AI Summary
    aiTools[2],  // AI Chat
    securityTools[0], // Protect PDF
    securityTools[1], // Redact Data
  ];

  static List<ToolItem> get allTools => [
    ...pdfTools,
    ...aiTools,
    ...securityTools,
    ...mediaTools,
  ];

  static ToolItem? getById(String id) {
    try {
      return allTools.firstWhere((tool) => tool.id == id);
    } catch (_) {
      return null;
    }
  }

  static ToolItem? getByRoute(String route) {
    try {
      return allTools.firstWhere((tool) => tool.route == route);
    } catch (_) {
      return null;
    }
  }
}
