import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

class ToolFeatureStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const ToolFeatureStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.color = AppColors.primary,
  });
}

class ToolFeaturesRegistry {
  ToolFeaturesRegistry._();

  static const Map<String, List<ToolFeatureStep>> _featuresMap = {
    // ── PDF Tools ────────────────────────────────────────────────────────────
    'pdf-editor': [
      ToolFeatureStep(
        title: 'Pixel-Perfect Page Canvas',
        subtitle: 'Renders original page background with 100% of logos, tables & graphics.',
        icon: LucideIcons.eye,
        color: AppColors.toolBlue,
      ),
      ToolFeatureStep(
        title: 'In-Place Text Editing',
        subtitle: 'Tap any text line to change font family, size & style directly on screen.',
        icon: LucideIcons.fileEdit,
        color: AppColors.toolPurple,
      ),
      ToolFeatureStep(
        title: 'Typography Control',
        subtitle: 'Select Serif, Sans-Serif, Monospace, bold, italic & custom text colors.',
        icon: LucideIcons.type,
        color: AppColors.toolIndigo,
      ),
      ToolFeatureStep(
        title: 'Freehand Pen & Highlight',
        subtitle: 'Draw annotations or highlight important passages with custom strokes.',
        icon: LucideIcons.highlighter,
        color: AppColors.toolOrange,
      ),
      ToolFeatureStep(
        title: 'Clean Vector Export',
        subtitle: 'Redacts original bounding box & re-inserts formatted text seamlessly.',
        icon: LucideIcons.download,
        color: AppColors.toolGreen,
      ),
    ],

    'merge-pdf': [
      ToolFeatureStep(
        title: 'Combine Instantly',
        subtitle: 'Merge dozens of documents in seconds into one clean file.',
        icon: LucideIcons.layers,
        color: AppColors.toolGreen,
      ),
      ToolFeatureStep(
        title: 'Batch Selection',
        subtitle: 'Upload multiple PDF documents simultaneously from device storage.',
        icon: LucideIcons.filePlus,
        color: AppColors.toolBlue,
      ),
      ToolFeatureStep(
        title: 'Drag & Reorder',
        subtitle: 'Arrange files in your exact preferred reading sequence.',
        icon: LucideIcons.arrowUpDown,
        color: AppColors.toolPurple,
      ),
      ToolFeatureStep(
        title: 'Quality Preservation',
        subtitle: 'Retains 100% vector fonts, page resolution & document metadata.',
        icon: LucideIcons.shieldCheck,
        color: AppColors.toolTeal,
      ),
      ToolFeatureStep(
        title: 'One-Tap Share',
        subtitle: 'Export & share your merged PDF bundle effortlessly.',
        icon: LucideIcons.share2,
        color: AppColors.toolIndigo,
      ),
    ],

    'split-pdf': [
      ToolFeatureStep(
        title: 'Smart Range Extraction',
        subtitle: 'Extract specific page ranges (e.g. 1-5, 8, 12-15) with precision.',
        icon: LucideIcons.scissors,
        color: AppColors.toolOrange,
      ),
      ToolFeatureStep(
        title: 'Single-Page Burst',
        subtitle: 'Split every page into individual standalone PDF files.',
        icon: LucideIcons.files,
        color: AppColors.toolPurple,
      ),
      ToolFeatureStep(
        title: 'Thumbnail Grid',
        subtitle: 'Inspect PDF page thumbnails visually before splitting.',
        icon: LucideIcons.grid,
        color: AppColors.toolBlue,
      ),
      ToolFeatureStep(
        title: 'Custom Naming',
        subtitle: 'Automatically names split files with clean range suffixes.',
        icon: LucideIcons.fileCode,
        color: AppColors.toolTeal,
      ),
      ToolFeatureStep(
        title: 'ZIP Export',
        subtitle: 'Download all extracted pages bundled cleanly in a single ZIP.',
        icon: LucideIcons.archive,
        color: AppColors.toolGreen,
      ),
    ],

    'compress-pdf': [
      ToolFeatureStep(
        title: 'Smart File Reduction',
        subtitle: 'Shrink PDF file size by up to 80% while retaining crisp readability.',
        icon: LucideIcons.minimize2,
        color: AppColors.toolPink,
      ),
      ToolFeatureStep(
        title: 'Multi-Level Presets',
        subtitle: 'Choose Low, Medium, High, or Extreme compression ratios.',
        icon: LucideIcons.sliders,
        color: AppColors.toolIndigo,
      ),
      ToolFeatureStep(
        title: 'Vector Stream Clean',
        subtitle: 'Cleans unused embedded font subsets & redundant image streams.',
        icon: LucideIcons.zap,
        color: AppColors.toolOrange,
      ),
      ToolFeatureStep(
        title: 'Live Size Compare',
        subtitle: 'View original vs compressed file size before saving.',
        icon: LucideIcons.barChart2,
        color: AppColors.toolBlue,
      ),
      ToolFeatureStep(
        title: 'Portal Ready',
        subtitle: 'Perfect for university uploads, portal submissions & email attachments.',
        icon: LucideIcons.mail,
        color: AppColors.toolGreen,
      ),
    ],

    'pdf-to-word': [
      ToolFeatureStep(
        title: 'Editable DOCX Output',
        subtitle: 'Converts PDFs into fully editable Microsoft Word documents.',
        icon: LucideIcons.fileText,
        color: AppColors.toolBlue,
      ),
      ToolFeatureStep(
        title: 'Layout Preservation',
        subtitle: 'Maintains paragraph flow, headings, bullet lists & columns.',
        icon: LucideIcons.layout,
        color: AppColors.toolPurple,
      ),
      ToolFeatureStep(
        title: 'Table Extraction',
        subtitle: 'Extracts tables with exact cell borders & alignment preserved.',
        icon: LucideIcons.table,
        color: AppColors.toolTeal,
      ),
      ToolFeatureStep(
        title: 'Inline Images',
        subtitle: 'Extracts graphics, logos & inline figures into the DOCX file.',
        icon: LucideIcons.image,
        color: AppColors.toolPink,
      ),
      ToolFeatureStep(
        title: 'Instant Download',
        subtitle: 'Open directly in Microsoft Word, WPS Office or Google Docs.',
        icon: LucideIcons.externalLink,
        color: AppColors.toolGreen,
      ),
    ],

    'word-to-pdf': [
      ToolFeatureStep(
        title: 'DOC & DOCX Conversion',
        subtitle: 'Converts Word files into universal PDF documents instantly.',
        icon: LucideIcons.fileCheck,
        color: AppColors.toolIndigo,
      ),
      ToolFeatureStep(
        title: 'Embedded Fonts',
        subtitle: 'Embeds standard typography for identical display across all screens.',
        icon: LucideIcons.type,
        color: AppColors.toolPurple,
      ),
      ToolFeatureStep(
        title: 'High-Res Rendering',
        subtitle: 'Renders complex tables, shapes & headers seamlessly.',
        icon: LucideIcons.printer,
        color: AppColors.toolBlue,
      ),
      ToolFeatureStep(
        title: 'Rapid Cloud Engine',
        subtitle: 'Fast server-assisted conversion with zero formatting loss.',
        icon: LucideIcons.cpu,
        color: AppColors.toolOrange,
      ),
      ToolFeatureStep(
        title: 'PDF/A Compliance',
        subtitle: 'Generates archive-ready PDF files suitable for long-term storage.',
        icon: LucideIcons.award,
        color: AppColors.toolGreen,
      ),
    ],

    // ── Video & Audio Tools ──────────────────────────────────────────────────
    'video-converter': [
      ToolFeatureStep(
        title: 'Multi-Format Conversion',
        subtitle: 'Convert between MP4, WebM, MOV, AVI, MKV, FLV, WMV, 3GP & GIF.',
        icon: LucideIcons.video,
        color: AppColors.toolBlue,
      ),
      ToolFeatureStep(
        title: 'Extract Audio from Video',
        subtitle: 'Extract high-quality MP3, WAV, AAC, M4A or FLAC audio tracks.',
        icon: LucideIcons.music,
        color: AppColors.toolGreen,
      ),
      ToolFeatureStep(
        title: 'FFmpeg Core Engine',
        subtitle: 'Powered by server-side FFmpeg for fast, lossless transcoding.',
        icon: LucideIcons.cpu,
        color: AppColors.toolPurple,
      ),
      ToolFeatureStep(
        title: 'Frame Rate Control',
        subtitle: 'Maintains smooth playback & sharp video resolution.',
        icon: LucideIcons.sliders,
        color: AppColors.toolOrange,
      ),
      ToolFeatureStep(
        title: 'Instant Download',
        subtitle: 'Save converted videos directly to your PaperKit workspace.',
        icon: LucideIcons.download,
        color: AppColors.toolTeal,
      ),
    ],

    'video-compressor': [
      ToolFeatureStep(
        title: 'Shrink Video Size',
        subtitle: 'Compress large video recordings to save device storage.',
        icon: LucideIcons.minimize2,
        color: AppColors.toolOrange,
      ),
      ToolFeatureStep(
        title: 'Multi-Preset Control',
        subtitle: 'Select Low, Medium, High, or Extreme CRF compression levels.',
        icon: LucideIcons.gauge,
        color: AppColors.toolPink,
      ),
      ToolFeatureStep(
        title: 'Resolution Rescaling',
        subtitle: 'Downscale video resolution to 720p HD or 480p SD mobile size.',
        icon: LucideIcons.monitor,
        color: AppColors.toolBlue,
      ),
      ToolFeatureStep(
        title: 'Audio Bitrate Tuning',
        subtitle: 'Optimizes background audio track to maximize compression.',
        icon: LucideIcons.volume2,
        color: AppColors.toolPurple,
      ),
      ToolFeatureStep(
        title: 'Async Processing',
        subtitle: 'Runs in background with automatic completion notifications.',
        icon: LucideIcons.clock,
        color: AppColors.toolGreen,
      ),
    ],

    'audio-converter': [
      ToolFeatureStep(
        title: 'Comprehensive Formats',
        subtitle: 'Convert MP3, WAV, OGG, M4A, AAC, FLAC, WMA, OPUS, AMR & AIFF.',
        icon: LucideIcons.music,
        color: AppColors.toolGreen,
      ),
      ToolFeatureStep(
        title: 'Lossless Fidelity',
        subtitle: 'Export to WAV or FLAC for pristine studio-quality audio.',
        icon: LucideIcons.disc,
        color: AppColors.toolBlue,
      ),
      ToolFeatureStep(
        title: 'Compact Compression',
        subtitle: 'Convert to MP3 or AAC for minimal storage usage.',
        icon: LucideIcons.headphones,
        color: AppColors.toolPurple,
      ),
      ToolFeatureStep(
        title: 'Clean Bitrate Control',
        subtitle: 'Ensures clear sound without audio distortion or artifacts.',
        icon: LucideIcons.zap,
        color: AppColors.toolOrange,
      ),
      ToolFeatureStep(
        title: 'Universal Playback',
        subtitle: 'Compatible with all mobile, web, desktop & car audio systems.',
        icon: LucideIcons.playCircle,
        color: AppColors.toolTeal,
      ),
    ],

    // ── Archive Tools ────────────────────────────────────────────────────────
    'archive-studio': [
      ToolFeatureStep(
        title: 'Create Compressed Archives',
        subtitle: 'Package files into ZIP, TAR, TAR.GZ, TAR.BZ2, GZ, or BZ2 format.',
        icon: LucideIcons.package,
        color: AppColors.toolPurple,
      ),
      ToolFeatureStep(
        title: 'Extract Archives',
        subtitle: 'Unpack ZIP, TAR, GZ, RAR, 7Z, BZ2, TGZ & TBZ archive files.',
        icon: LucideIcons.folderInput,
        color: AppColors.toolOrange,
      ),
      ToolFeatureStep(
        title: 'Password Encryption',
        subtitle: 'Protect sensitive archives with secure AES password encryption.',
        icon: LucideIcons.lock,
        color: AppColors.toolPink,
      ),
      ToolFeatureStep(
        title: 'Multi-File Bundle',
        subtitle: 'Bundle mixed documents, photos & media into one zip file.',
        icon: LucideIcons.filePlus,
        color: AppColors.toolBlue,
      ),
      ToolFeatureStep(
        title: 'Workspace Access',
        subtitle: 'View & extract downloaded archives inside PaperKit storage.',
        icon: LucideIcons.share2,
        color: AppColors.toolGreen,
      ),
    ],

    // ── AI Tools ─────────────────────────────────────────────────────────────
    'ai-doc-chat': [
      ToolFeatureStep(
        title: 'Chat with Documents',
        subtitle: 'Ask questions & chat directly with any PDF, paper or report.',
        icon: LucideIcons.messageSquare,
        color: AppColors.toolIndigo,
      ),
      ToolFeatureStep(
        title: 'Page Citation References',
        subtitle: 'AI cites exact page numbers & paragraphs for every answer.',
        icon: LucideIcons.bookmark,
        color: AppColors.toolPurple,
      ),
      ToolFeatureStep(
        title: 'Multi-Document Context',
        subtitle: 'Analyze relationships across multiple uploaded research files.',
        icon: LucideIcons.files,
        color: AppColors.toolBlue,
      ),
      ToolFeatureStep(
        title: 'Instant Fact Verification',
        subtitle: 'Verifies figures, dates & conclusions with neural search.',
        icon: LucideIcons.checkCircle,
        color: AppColors.toolTeal,
      ),
      ToolFeatureStep(
        title: 'Export Q&A Report',
        subtitle: 'Export chat transcript to PDF or Markdown with one tap.',
        icon: LucideIcons.download,
        color: AppColors.toolGreen,
      ),
    ],

    'ai-summary': [
      ToolFeatureStep(
        title: 'Instant Document Digest',
        subtitle: 'Summarizes long 50+ page PDFs into concise key takeaways.',
        icon: LucideIcons.fileCheck2,
        color: AppColors.toolTeal,
      ),
      ToolFeatureStep(
        title: 'Executive Bullet Points',
        subtitle: 'Generates structured bullet points for rapid reading.',
        icon: LucideIcons.list,
        color: AppColors.toolBlue,
      ),
      ToolFeatureStep(
        title: 'Key Recommendations',
        subtitle: 'Highlights main findings, methodology & conclusion notes.',
        icon: LucideIcons.lightbulb,
        color: AppColors.toolOrange,
      ),
      ToolFeatureStep(
        title: 'Multilingual Summaries',
        subtitle: 'Translates & summarizes documents in 25+ languages.',
        icon: LucideIcons.languages,
        color: AppColors.toolPurple,
      ),
      ToolFeatureStep(
        title: 'Copy & Share',
        subtitle: 'Copy summary text or save formatted PDF report.',
        icon: LucideIcons.copy,
        color: AppColors.toolGreen,
      ),
    ],

    // ── Image Tools ──────────────────────────────────────────────────────────
    'image-converter': [
      ToolFeatureStep(
        title: 'Multi-Format Support',
        subtitle: 'Convert between PNG, JPG, WebP, GIF, BMP, HEIC & TIFF.',
        icon: LucideIcons.image,
        color: AppColors.toolPink,
      ),
      ToolFeatureStep(
        title: 'Batch Image Conversion',
        subtitle: 'Convert dozens of photos in a single batch operation.',
        icon: LucideIcons.images,
        color: AppColors.toolPurple,
      ),
      ToolFeatureStep(
        title: 'Transparency Retention',
        subtitle: 'Preserves PNG & WebP alpha transparency channels.',
        icon: LucideIcons.layers,
        color: AppColors.toolBlue,
      ),
      ToolFeatureStep(
        title: 'Quality Compression',
        subtitle: 'Adjust JPEG/WebP compression slider for optimal quality.',
        icon: LucideIcons.sliders,
        color: AppColors.toolOrange,
      ),
      ToolFeatureStep(
        title: 'Gallery Export',
        subtitle: 'Save converted images directly to system gallery or workspace.',
        icon: LucideIcons.download,
        color: AppColors.toolGreen,
      ),
    ],

    'image-compressor': [
      ToolFeatureStep(
        title: 'Shrink Photo Bytes',
        subtitle: 'Compress heavy camera photos from MBs down to KBs.',
        icon: LucideIcons.minimize,
        color: AppColors.toolPink,
      ),
      ToolFeatureStep(
        title: 'Visual Quality Check',
        subtitle: 'Compare original vs compressed image side-by-side.',
        icon: LucideIcons.eye,
        color: AppColors.toolBlue,
      ),
      ToolFeatureStep(
        title: 'Preset Compression',
        subtitle: 'Select Low, Medium, or High compression presets.',
        icon: LucideIcons.gauge,
        color: AppColors.toolOrange,
      ),
      ToolFeatureStep(
        title: 'Dimension Rescaling',
        subtitle: 'Optionally scale down pixel dimensions for web sharing.',
        icon: LucideIcons.moveHorizontal,
        color: AppColors.toolPurple,
      ),
      ToolFeatureStep(
        title: 'Batch Export',
        subtitle: 'Compress entire photo folders rapidly in background.',
        icon: LucideIcons.folderDown,
        color: AppColors.toolGreen,
      ),
    ],

    // ── Utilities & Security ─────────────────────────────────────────────────
    'qr-generator': [
      ToolFeatureStep(
        title: 'Generate Custom QR Codes',
        subtitle: 'Create QR codes for URLs, Wi-Fi keys, text, email & contacts.',
        icon: LucideIcons.qrCode,
        color: AppColors.toolIndigo,
      ),
      ToolFeatureStep(
        title: 'Custom Brand Colors',
        subtitle: 'Customize foreground & background colors with crisp contrast.',
        icon: LucideIcons.palette,
        color: AppColors.toolPink,
      ),
      ToolFeatureStep(
        title: 'Error Correction Level',
        subtitle: 'Set High error correction so QR codes scan even if damaged.',
        icon: LucideIcons.shield,
        color: AppColors.toolTeal,
      ),
      ToolFeatureStep(
        title: 'High-Res Vector Export',
        subtitle: 'Export QR code image in PNG or crisp SVG vector format.',
        icon: LucideIcons.download,
        color: AppColors.toolBlue,
      ),
      ToolFeatureStep(
        title: 'Instant Scan Preview',
        subtitle: 'Verify QR code scanning readability directly on screen.',
        icon: LucideIcons.scan,
        color: AppColors.toolGreen,
      ),
    ],

    'barcode-generator': [
      ToolFeatureStep(
        title: 'Universal Barcode Types',
        subtitle: 'Generate Code128, EAN13, EAN8, UPC, Code39 & ITF barcodes.',
        icon: LucideIcons.barChart,
        color: AppColors.toolPurple,
      ),
      ToolFeatureStep(
        title: 'Inventory & Product Ready',
        subtitle: 'Ideal for product tagging, retail labels & library ISBNs.',
        icon: LucideIcons.tag,
        color: AppColors.toolBlue,
      ),
      ToolFeatureStep(
        title: 'Custom Captions',
        subtitle: 'Display human-readable text digits beneath barcode bars.',
        icon: LucideIcons.type,
        color: AppColors.toolOrange,
      ),
      ToolFeatureStep(
        title: 'Print Quality DPI',
        subtitle: 'Outputs high-density barcode graphics suitable for printing.',
        icon: LucideIcons.printer,
        color: AppColors.toolTeal,
      ),
      ToolFeatureStep(
        title: 'Export & Share',
        subtitle: 'Save barcode image or insert directly into PDF documents.',
        icon: LucideIcons.share2,
        color: AppColors.toolGreen,
      ),
    ],

    'protect-pdf': [
      ToolFeatureStep(
        title: 'Bank-Grade Encryption',
        subtitle: 'Encrypt PDFs with 256-Bit AES security algorithm.',
        icon: LucideIcons.lock,
        color: AppColors.toolOrange,
      ),
      ToolFeatureStep(
        title: 'User & Owner Passwords',
        subtitle: 'Set separate open password and administrative owner password.',
        icon: LucideIcons.key,
        color: AppColors.toolPurple,
      ),
      ToolFeatureStep(
        title: 'Restrict Permissions',
        subtitle: 'Block unauthorized printing, text copying, or page editing.',
        icon: LucideIcons.shield,
        color: AppColors.toolPink,
      ),
      ToolFeatureStep(
        title: 'Sanitize Metadata',
        subtitle: 'Removes sensitive document author history & metadata.',
        icon: LucideIcons.eyeOff,
        color: AppColors.toolBlue,
      ),
      ToolFeatureStep(
        title: 'Secure Download',
        subtitle: 'Generates password-protected PDF output securely.',
        icon: LucideIcons.checkSquare,
        color: AppColors.toolGreen,
      ),
    ],

    'scan-to-pdf': [
      ToolFeatureStep(
        title: 'Camera Document Scanner',
        subtitle: 'Scan receipts, book pages, IDs & paper documents.',
        icon: LucideIcons.camera,
        color: AppColors.toolBlue,
      ),
      ToolFeatureStep(
        title: 'Perspective Crop',
        subtitle: 'Auto-detects document edges & flattens skewed scans.',
        icon: LucideIcons.crop,
        color: AppColors.toolOrange,
      ),
      ToolFeatureStep(
        title: 'Enhancement Filters',
        subtitle: 'Apply B&W, Grayscale, Magic Color & Document Contrast.',
        icon: LucideIcons.sliders,
        color: AppColors.toolPurple,
      ),
      ToolFeatureStep(
        title: 'Multi-Page Scan',
        subtitle: 'Scan continuous pages & compile into a single PDF.',
        icon: LucideIcons.files,
        color: AppColors.toolTeal,
      ),
      ToolFeatureStep(
        title: 'Searchable OCR PDF',
        subtitle: 'Generates searchable text layer over scanned images.',
        icon: LucideIcons.fileSearch,
        color: AppColors.toolGreen,
      ),
    ],
  };

  /// Returns 5 customized feature/step cards for the specified [toolId].
  /// Provides intelligent fallbacks if a tool is not explicitly listed.
  static List<ToolFeatureStep> getForTool(String toolId, {String? toolName, Color? color}) {
    final key = toolId.toLowerCase().trim();
    if (_featuresMap.containsKey(key)) {
      return _featuresMap[key]!;
    }

    // Category / Keyword fallback rules for any custom or new tools
    final toolThemeColor = color ?? AppColors.primary;
    final name = toolName ?? toolId.replaceAll('-', ' ').toUpperCase();

    return [
      ToolFeatureStep(
        title: '1. Select & Load',
        subtitle: 'Upload your file or enter input details to launch $name.',
        icon: LucideIcons.filePlus,
        color: toolThemeColor,
      ),
      ToolFeatureStep(
        title: '2. Custom Configuration',
        subtitle: 'Configure tool parameters, formats, or preferences to your exact needs.',
        icon: LucideIcons.sliders,
        color: AppColors.toolPurple,
      ),
      ToolFeatureStep(
        title: '3. Fast AI/Engine Processing',
        subtitle: 'Powered by high-performance local & server-side processing engines.',
        icon: LucideIcons.cpu,
        color: AppColors.toolOrange,
      ),
      ToolFeatureStep(
        title: '4. Instant Live Preview',
        subtitle: 'Inspect results live on screen before finalizing your changes.',
        icon: LucideIcons.eye,
        color: AppColors.toolBlue,
      ),
      ToolFeatureStep(
        title: '5. Export & Share',
        subtitle: 'Save the output directly to PaperKit workspace or share via apps.',
        icon: LucideIcons.download,
        color: AppColors.toolGreen,
      ),
    ];
  }
}
