import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/tool_item.dart';
import '../theme/app_colors.dart';

/// Canonical ToolRegistry — one ToolItem definition per tool.
///
/// All UI lists (featured, category, search, getTopToolsForCategory) MUST
/// reference entries from this registry — never define duplicate ToolItems.
class ToolRegistry {
  ToolRegistry._();

  // ──────────────────────────────────────────────────────────────────────────
  // CANONICAL TOOL DEFINITIONS
  // ──────────────────────────────────────────────────────────────────────────

  // ── PDF Tools ─────────────────────────────────────────────────────────────

  static const ToolItem pdfEditor = ToolItem(
    id: 'pdf-editor',
    label: 'PDF Editor',
    description: 'In-place text editing & object replacement',
    route: '/tools/pdf-editor',
    icon: LucideIcons.fileSignature,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.pdf,
    isPro: true,
    tags: ['edit', 'annotate', 'pdf', 'text', 'draw', 'highlight'],
  );

  static const ToolItem mergePdf = ToolItem(
    id: 'merge-pdf',
    label: 'Merge PDF',
    description: 'Combine multiple PDFs into one',
    route: '/tools/merge',
    icon: LucideIcons.files,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.pdf,
    tags: ['merge', 'combine', 'join', 'pdf'],
  );

  static const ToolItem splitPdf = ToolItem(
    id: 'split-pdf',
    label: 'Split PDF',
    description: 'Split by ranges, every N or single pages',
    route: '/tools/split',
    icon: LucideIcons.scissors,
    color: AppColors.toolRed,
    softColor: AppColors.toolRedSoft,
    category: ToolCategory.pdf,
    tags: ['split', 'divide', 'pages', 'pdf'],
  );

  static const ToolItem compressPdf = ToolItem(
    id: 'compress-pdf',
    label: 'Compress PDF',
    description: 'Reduce file size with multi-level optimization',
    route: '/tools/compress',
    icon: LucideIcons.minimize2,
    color: AppColors.toolOrange,
    softColor: AppColors.toolOrangeSoft,
    category: ToolCategory.pdf,
    tags: ['compress', 'reduce', 'size', 'optimize', 'pdf'],
  );

  static const ToolItem extractPages = ToolItem(
    id: 'extract-pages',
    label: 'Extract Pages',
    description: 'Extract specific pages into new PDF',
    route: '/tools/extract-pages',
    icon: LucideIcons.fileOutput,
    color: AppColors.toolTeal,
    softColor: AppColors.toolTealSoft,
    category: ToolCategory.pdf,
    tags: ['extract', 'pages', 'pdf'],
  );

  static const ToolItem rotatePdf = ToolItem(
    id: 'rotate-pdf',
    label: 'Rotate PDF',
    description: 'Rotate page orientation permanently',
    route: '/tools/rotate',
    icon: LucideIcons.rotateCw,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.pdf,
    tags: ['rotate', 'orientation', 'pdf'],
  );

  static const ToolItem watermark = ToolItem(
    id: 'watermark',
    label: 'Watermark',
    description: 'Add text or logo watermarks',
    route: '/tools/watermark',
    icon: LucideIcons.stamp,
    color: AppColors.toolTeal,
    softColor: AppColors.toolTealSoft,
    category: ToolCategory.pdf,
    tags: ['watermark', 'stamp', 'brand', 'pdf'],
  );

  static const ToolItem organizePages = ToolItem(
    id: 'organize-pages',
    label: 'Organize Pages',
    description: 'Reorder, delete, duplicate & rotate',
    route: '/tools/organize-pages',
    icon: LucideIcons.layers,
    color: AppColors.toolIndigo,
    softColor: AppColors.toolIndigoSoft,
    category: ToolCategory.pdf,
    tags: ['organize', 'reorder', 'delete', 'pages', 'pdf'],
  );

  static const ToolItem nupPdf = ToolItem(
    id: 'pdf-nup',
    label: 'N-Up Printing',
    description: 'Tile 2, 4, 8 or 16 pages per sheet',
    route: '/tools/nup',
    icon: LucideIcons.layoutGrid,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.pdf,
    tags: ['nup', 'print', 'tile', 'pages', 'pdf'],
  );

  static const ToolItem bookletPdf = ToolItem(
    id: 'pdf-booklet',
    label: 'Booklet Creator',
    description: 'Reorder pages for 2-up folding booklet',
    route: '/tools/booklet',
    icon: LucideIcons.bookOpen,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.pdf,
    tags: ['booklet', 'print', 'fold', 'pdf'],
  );

  static const ToolItem batesStamping = ToolItem(
    id: 'bates-stamping',
    label: 'Bates Stamping',
    description: 'Sequential legal document numbering',
    route: '/tools/bates',
    icon: LucideIcons.binary,
    color: AppColors.toolRed,
    softColor: AppColors.toolRedSoft,
    category: ToolCategory.pdf,
    tags: ['bates', 'numbering', 'legal', 'stamp', 'pdf'],
  );

  static const ToolItem headerFooter = ToolItem(
    id: 'header-footer',
    label: 'Header & Footer',
    description: 'Add text, page numbers & dates to headers/footers',
    route: '/tools/headers',
    icon: LucideIcons.alignJustify,
    color: AppColors.toolTeal,
    softColor: AppColors.toolTealSoft,
    category: ToolCategory.pdf,
    tags: ['header', 'footer', 'page number', 'date', 'pdf'],
  );

  static const ToolItem pdfToPdfa = ToolItem(
    id: 'pdf-to-pdfa',
    label: 'PDF/A Archive',
    description: 'Convert to ISO archiving standard',
    route: '/tools/pdf-to-pdfa',
    icon: LucideIcons.archive,
    color: AppColors.toolOrange,
    softColor: AppColors.toolOrangeSoft,
    category: ToolCategory.pdf,
    tags: ['pdfa', 'archive', 'iso', 'long-term', 'pdf'],
  );

  // ── AI Tools ──────────────────────────────────────────────────────────────

  static const ToolItem aiOcr = ToolItem(
    id: 'ai-ocr',
    label: 'OCR Text & Layout',
    description: 'Extract text & tables from scans/images',
    route: '/ai/ocr',
    icon: LucideIcons.scanLine,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.ai,
    isAi: true,
    tags: ['ocr', 'scan', 'text', 'extract', 'image', 'scanned'],
  );

  static const ToolItem aiSummary = ToolItem(
    id: 'ai-summary',
    label: 'AI Summary',
    description: 'Detailed, short, key points & action items',
    route: '/ai/summarize',
    icon: LucideIcons.sparkles,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.ai,
    isAi: true,
    tags: ['summary', 'summarize', 'overview', 'key points', 'ai'],
  );

  static const ToolItem semanticCompare = ToolItem(
    id: 'semantic-compare',
    label: 'Semantic Compare',
    description: 'Compare meaning & temporal/financial changes',
    route: '/ai/compare',
    icon: LucideIcons.gitCompare,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.ai,
    isAi: true,
    tags: ['compare', 'diff', 'difference', 'semantic', 'ai'],
  );

  static const ToolItem similarityMatrix = ToolItem(
    id: 'similarity-matrix',
    label: 'Similarity Score',
    description: 'Pairwise similarity & duplicate detection',
    route: '/ai/similarity',
    icon: LucideIcons.layoutGrid,
    color: AppColors.toolIndigo,
    softColor: AppColors.toolIndigoSoft,
    category: ToolCategory.ai,
    isAi: true,
    tags: ['similarity', 'duplicate', 'matrix', 'ai'],
  );

  static const ToolItem aiDocChat = ToolItem(
    id: 'ai-doc-chat',
    label: 'AI Document Chat',
    description: 'Interactive conversational Q&A and research',
    route: '/ai/ask',
    icon: LucideIcons.messageSquare,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.ai,
    isAi: true,
    tags: ['chat', 'ask', 'question', 'conversation', 'ai'],
  );

  static const ToolItem semanticSearch = ToolItem(
    id: 'semantic-search',
    label: 'Semantic Search',
    description: 'Search document by intent and meaning',
    route: '/ai/search',
    icon: LucideIcons.search,
    color: AppColors.toolTeal,
    softColor: AppColors.toolTealSoft,
    category: ToolCategory.ai,
    isAi: true,
    tags: ['search', 'semantic', 'find', 'intent', 'ai'],
  );

  static const ToolItem classifyDocument = ToolItem(
    id: 'classify-document',
    label: 'Document Classify',
    description: 'Auto-identify paper, resume, invoice, contract',
    route: '/ai/classify',
    icon: LucideIcons.tag,
    color: AppColors.toolOrange,
    softColor: AppColors.toolOrangeSoft,
    category: ToolCategory.ai,
    isAi: true,
    tags: ['classify', 'category', 'type', 'identify', 'ai'],
  );

  static const ToolItem extractInfo = ToolItem(
    id: 'extract-info',
    label: 'Information Extract',
    description: 'Structured fields from invoices, CVs & papers',
    route: '/ai/extract-info',
    icon: LucideIcons.fileSearch,
    color: AppColors.toolPink,
    softColor: AppColors.toolPinkSoft,
    category: ToolCategory.ai,
    isAi: true,
    tags: ['extract', 'information', 'fields', 'invoice', 'resume', 'ai'],
  );

  static const ToolItem translateDoc = ToolItem(
    id: 'translate-doc',
    label: 'AI Translation',
    description: 'Translate into 15+ languages',
    route: '/ai/translate',
    icon: LucideIcons.languages,
    color: AppColors.toolGreen,
    softColor: AppColors.toolGreenSoft,
    category: ToolCategory.ai,
    isAi: true,
    tags: ['translate', 'language', 'multilingual', 'ai'],
  );

  static const ToolItem writingAssistant = ToolItem(
    id: 'writing-assistant',
    label: 'Writing Assistant',
    description: 'Grammar, paraphrase, formal & tone polish',
    route: '/ai/writing-assist',
    icon: LucideIcons.penTool,
    color: AppColors.toolGreen,
    softColor: AppColors.toolGreenSoft,
    category: ToolCategory.ai,
    isAi: true,
    tags: ['writing', 'grammar', 'paraphrase', 'tone', 'ai'],
  );

  static const ToolItem qualityChecker = ToolItem(
    id: 'quality-checker',
    label: 'Quality Checker',
    description: 'Audit structure, citations & readability',
    route: '/ai/quality-checker',
    icon: LucideIcons.checkCheck,
    color: AppColors.toolTeal,
    softColor: AppColors.toolTealSoft,
    category: ToolCategory.ai,
    isAi: true,
    tags: ['quality', 'audit', 'check', 'readability', 'ai'],
  );

  static const ToolItem extractTables = ToolItem(
    id: 'extract-tables',
    label: 'Extract Tables',
    description: 'Detect & export structured tables',
    route: '/ai/extract-tables',
    icon: LucideIcons.table,
    color: AppColors.toolGreen,
    softColor: AppColors.toolGreenSoft,
    category: ToolCategory.ai,
    isAi: true,
    tags: ['table', 'extract', 'csv', 'data', 'ai'],
  );

  static const ToolItem imageEnhancer = ToolItem(
    id: 'image-enhancer',
    label: 'Image Enhancer',
    description: 'AI upscaling & image quality improvement',
    route: '/ai/image-enhancer',
    icon: LucideIcons.imagePlus,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.ai,
    isAi: true,
    tags: ['enhance', 'upscale', 'image', 'quality', 'ai'],
  );

  static const ToolItem parseInvoice = ToolItem(
    id: 'parse-invoice',
    label: 'Invoice AI Parser',
    description: 'Extract vendor, date, totals & line items',
    route: '/ai/invoice',
    icon: LucideIcons.receipt,
    color: AppColors.toolGreen,
    softColor: AppColors.toolGreenSoft,
    category: ToolCategory.ai,
    isAi: true,
    tags: ['invoice', 'receipt', 'vendor', 'amount', 'parse', 'ai'],
  );

  static const ToolItem parseCv = ToolItem(
    id: 'parse-cv',
    label: 'Resume AI Scanner',
    description: 'Extract skills, experience & education',
    route: '/ai/resume',
    icon: LucideIcons.fileUser,
    color: AppColors.toolOrange,
    softColor: AppColors.toolOrangeSoft,
    category: ToolCategory.ai,
    isAi: true,
    tags: ['resume', 'cv', 'skills', 'experience', 'ai'],
  );

  // ── Security Tools ────────────────────────────────────────────────────────

  static const ToolItem protectPdf = ToolItem(
    id: 'protect-pdf',
    label: 'Protect PDF',
    description: '256-bit AES password encryption & permissions',
    route: '/security/protect',
    icon: LucideIcons.lock,
    color: AppColors.toolRed,
    softColor: AppColors.toolRedSoft,
    category: ToolCategory.security,
    tags: ['protect', 'password', 'encrypt', 'security', 'pdf'],
  );

  static const ToolItem smartRedaction = ToolItem(
    id: 'smart-redaction',
    label: 'Redact Data',
    description: 'AI privacy scan & permanent blackouts',
    route: '/security/redact',
    icon: LucideIcons.eyeOff,
    color: AppColors.toolOrange,
    softColor: AppColors.toolOrangeSoft,
    category: ToolCategory.security,
    isAi: true,
    tags: ['redact', 'privacy', 'blackout', 'pii', 'security'],
  );

  static const ToolItem digitalSign = ToolItem(
    id: 'digital-sign',
    label: 'Digital Sign',
    description: 'Draw, type, or stamp digital signatures',
    route: '/security/sign',
    icon: LucideIcons.fileSignature,
    color: AppColors.toolIndigo,
    softColor: AppColors.toolIndigoSoft,
    category: ToolCategory.security,
    tags: ['sign', 'signature', 'digital', 'pdf'],
  );

  static const ToolItem metadataManager = ToolItem(
    id: 'metadata-manager',
    label: 'Metadata Manager',
    description: 'Inspect, edit, or sanitize metadata for privacy',
    route: '/security/metadata',
    icon: LucideIcons.info,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.security,
    tags: ['metadata', 'privacy', 'sanitize', 'author', 'pdf'],
  );

  // ── Conversion Tools ──────────────────────────────────────────────────────

  static const ToolItem wordToPdf = ToolItem(
    id: 'word-to-pdf',
    label: 'Word to PDF',
    description: 'Convert DOC/DOCX documents to PDF format',
    route: '/tools/convert?from=word&to=pdf',
    icon: LucideIcons.fileText,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.convert,
    tags: ['word', 'docx', 'doc', 'convert', 'pdf'],
  );

  static const ToolItem pdfToWord = ToolItem(
    id: 'pdf-to-word',
    label: 'PDF to Word',
    description: 'Convert PDF documents to editable DOCX',
    route: '/tools/convert?from=pdf&to=word',
    icon: LucideIcons.fileOutput,
    color: AppColors.toolIndigo,
    softColor: AppColors.toolIndigoSoft,
    category: ToolCategory.convert,
    tags: ['pdf', 'word', 'docx', 'convert', 'edit'],
  );

  static const ToolItem excelToPdf = ToolItem(
    id: 'excel-to-pdf',
    label: 'Excel to PDF',
    description: 'Convert XLS/XLSX spreadsheets to PDF',
    route: '/tools/convert?from=excel&to=pdf',
    icon: LucideIcons.table,
    color: AppColors.toolGreen,
    softColor: AppColors.toolGreenSoft,
    category: ToolCategory.convert,
    tags: ['excel', 'spreadsheet', 'xlsx', 'convert', 'pdf'],
  );

  static const ToolItem pdfToExcel = ToolItem(
    id: 'pdf-to-excel',
    label: 'PDF to Excel',
    description: 'Extract tables and data to XLSX format',
    route: '/tools/convert?from=pdf&to=excel',
    icon: LucideIcons.fileSpreadsheet,
    color: AppColors.toolTeal,
    softColor: AppColors.toolTealSoft,
    category: ToolCategory.convert,
    tags: ['pdf', 'excel', 'xlsx', 'convert', 'table'],
  );

  static const ToolItem pptToPdf = ToolItem(
    id: 'ppt-to-pdf',
    label: 'PPT to PDF',
    description: 'Convert PowerPoint slides to PDF',
    route: '/tools/convert?from=ppt&to=pdf',
    icon: LucideIcons.presentation,
    color: AppColors.toolOrange,
    softColor: AppColors.toolOrangeSoft,
    category: ToolCategory.convert,
    tags: ['powerpoint', 'ppt', 'pptx', 'slides', 'convert', 'pdf'],
  );

  static const ToolItem pdfToPpt = ToolItem(
    id: 'pdf-to-ppt',
    label: 'PDF to PPT',
    description: 'Convert PDF pages into PowerPoint slides',
    route: '/tools/convert?from=pdf&to=ppt',
    icon: LucideIcons.fileSliders,
    color: AppColors.toolPink,
    softColor: AppColors.toolPinkSoft,
    category: ToolCategory.convert,
    tags: ['pdf', 'powerpoint', 'pptx', 'slides', 'convert'],
  );

  static const ToolItem imageToPdf = ToolItem(
    id: 'image-to-pdf',
    label: 'Image to PDF',
    description: 'Convert JPG, PNG, WEBP images to PDF',
    route: '/tools/convert?from=image&to=pdf',
    icon: LucideIcons.image,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.convert,
    tags: ['image', 'jpg', 'png', 'convert', 'pdf'],
  );

  static const ToolItem pdfToImage = ToolItem(
    id: 'pdf-to-image',
    label: 'PDF to Image',
    description: 'Render PDF pages as high-resolution images',
    route: '/tools/convert?from=pdf&to=image',
    icon: LucideIcons.images,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.convert,
    tags: ['pdf', 'image', 'jpg', 'png', 'convert'],
  );

  // ── Image Tools ───────────────────────────────────────────────────────────

  static const ToolItem imageConverter = ToolItem(
    id: 'image-converter',
    label: 'Image Converter',
    description: 'Convert between JPG, PNG, WebP, HEIC, BMP',
    route: '/tools/image-converter',
    icon: LucideIcons.image,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.image,
    tags: ['image', 'convert', 'jpg', 'png', 'webp', 'heic', 'bmp'],
  );

  static const ToolItem imageCompressor = ToolItem(
    id: 'image-compressor',
    label: 'Image Compressor',
    description: 'Reduce image file size with quality control',
    route: '/tools/image-compressor',
    icon: LucideIcons.minimize2,
    color: AppColors.toolOrange,
    softColor: AppColors.toolOrangeSoft,
    category: ToolCategory.image,
    tags: ['image', 'compress', 'reduce', 'size'],
  );

  static const ToolItem imageManipulator = ToolItem(
    id: 'image-manipulator',
    label: 'Image Adjust & Manipulator',
    description: 'Adjust brightness, contrast, saturation & filters',
    route: '/tools/image-manipulator',
    icon: LucideIcons.sliders,
    color: AppColors.toolPink,
    softColor: AppColors.toolPinkSoft,
    category: ToolCategory.image,
    tags: ['image', 'adjust', 'brightness', 'contrast', 'filter'],
  );

  static const ToolItem imageResizer = ToolItem(
    id: 'image-resizer',
    label: 'Image Resizer',
    description: 'Resize images by dimensions, percentage or presets',
    route: '/tools/image-resizer',
    icon: LucideIcons.moveHorizontal,
    color: AppColors.toolTeal,
    softColor: AppColors.toolTealSoft,
    category: ToolCategory.image,
    isNew: true,
    tags: ['image', 'resize', 'dimensions', 'scale', 'batch'],
  );

  static const ToolItem qrGenerator = ToolItem(
    id: 'qr-generator',
    label: 'QR Code Generator',
    description: 'Generate QR codes for URLs, text, email & more',
    route: '/tools/qr-generator',
    icon: LucideIcons.qrCode,
    color: AppColors.toolIndigo,
    softColor: AppColors.toolIndigoSoft,
    category: ToolCategory.utilities,
    isNew: true,
    tags: ['qr', 'qr code', 'barcode', 'link', 'url'],
  );

  static const ToolItem barcodeGenerator = ToolItem(
    id: 'barcode-generator',
    label: 'Barcode Generator',
    description: 'Generate Code128, EAN13, QR & other barcodes',
    route: '/tools/barcode-generator',
    icon: LucideIcons.barChart,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.utilities,
    isNew: true,
    tags: ['barcode', 'code128', 'ean', 'product', 'inventory'],
  );

  // ── Video Tools ───────────────────────────────────────────────────────────

  static const ToolItem videoConverter = ToolItem(
    id: 'video-converter',
    label: 'Video Converter',
    description: 'Convert between MP4, WebM, MOV & GIF',
    route: '/tools/video-converter',
    icon: LucideIcons.video,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.video,
    tags: ['video', 'convert', 'mp4', 'webm', 'mov'],
  );

  static const ToolItem videoCompressor = ToolItem(
    id: 'video-compressor',
    label: 'Video Compressor',
    description: 'Compress video with quality control',
    route: '/tools/video-compressor',
    icon: LucideIcons.minimize2,
    color: AppColors.toolOrange,
    softColor: AppColors.toolOrangeSoft,
    category: ToolCategory.video,
    tags: ['video', 'compress', 'reduce', 'size'],
  );

  // ── Audio Tools ───────────────────────────────────────────────────────────

  static const ToolItem audioConverter = ToolItem(
    id: 'audio-converter',
    label: 'Audio Converter',
    description: 'Convert between MP3, WAV, OGG formats',
    route: '/tools/audio-converter',
    icon: LucideIcons.music,
    color: AppColors.toolGreen,
    softColor: AppColors.toolGreenSoft,
    category: ToolCategory.audio,
    tags: ['audio', 'convert', 'mp3', 'wav', 'ogg'],
  );

  // ── Archive Tools ─────────────────────────────────────────────────────────

  static const ToolItem archiveStudio = ToolItem(
    id: 'archive-studio',
    label: 'Archive Studio',
    description: 'Extract, create & convert ZIP, RAR, TAR, GZ archives',
    route: '/tools/archive',
    icon: LucideIcons.archiveRestore,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.archive,
    tags: ['archive', 'zip', 'rar', 'tar', 'extract', 'compress'],
  );

  // ── Scanner Tools ─────────────────────────────────────────────────────────

  static const ToolItem scanToPdf = ToolItem(
    id: 'scan-to-pdf',
    label: 'Scan to PDF',
    description: 'Camera scan with edge detection, crop & OCR to searchable PDF',
    route: '/scanner',
    icon: LucideIcons.scanLine,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.scanner,
    tags: ['scan', 'camera', 'pdf', 'ocr', 'document', 'searchable'],
  );

  // ── Academic / Research Tools ─────────────────────────────────────────────

  static const ToolItem researchAnalyzer = ToolItem(
    id: 'research-analyzer',
    label: 'Research Analyzer',
    description: 'Deep analysis: title, abstract, methods, results & gaps',
    route: '/academic/research-analyzer',
    icon: LucideIcons.microscope,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.academic,
    isAi: true,
    isNew: true,
    tags: ['research', 'paper', 'analyze', 'academic', 'abstract', 'methodology'],
  );

  static const ToolItem literatureReview = ToolItem(
    id: 'literature-review',
    label: 'Literature Review',
    description: 'Multi-paper analysis & structured review generation',
    route: '/academic/literature-review',
    icon: LucideIcons.bookOpen,
    color: AppColors.toolIndigo,
    softColor: AppColors.toolIndigoSoft,
    category: ToolCategory.academic,
    isAi: true,
    isNew: true,
    tags: ['literature', 'review', 'research', 'papers', 'academic', 'compare'],
  );

  static const ToolItem researchGap = ToolItem(
    id: 'research-gap',
    label: 'Research Gap Finder',
    description: 'Identify limitations, unresolved problems & future work',
    route: '/academic/research-gap',
    icon: LucideIcons.searchX,
    color: AppColors.toolTeal,
    softColor: AppColors.toolTealSoft,
    category: ToolCategory.academic,
    isAi: true,
    isNew: true,
    tags: ['gap', 'research', 'limitation', 'future work', 'academic'],
  );

  static const ToolItem citationExtractor = ToolItem(
    id: 'citation-extractor',
    label: 'Citation Extractor',
    description: 'Extract in-text citations & bibliography with DOI/URL',
    route: '/academic/citation-extractor',
    icon: LucideIcons.quote,
    color: AppColors.toolOrange,
    softColor: AppColors.toolOrangeSoft,
    category: ToolCategory.academic,
    isAi: true,
    isNew: true,
    tags: ['citation', 'reference', 'bibliography', 'doi', 'extract', 'research'],
  );

  static const ToolItem citationFormatter = ToolItem(
    id: 'citation-formatter',
    label: 'Citation Formatter',
    description: 'Format citations in APA, MLA, IEEE, Chicago & more',
    route: '/academic/citation-formatter',
    icon: LucideIcons.listOrdered,
    color: AppColors.toolGreen,
    softColor: AppColors.toolGreenSoft,
    category: ToolCategory.academic,
    isAi: true,
    isNew: true,
    tags: ['citation', 'format', 'apa', 'mla', 'ieee', 'chicago', 'harvard', 'vancouver'],
  );

  static const ToolItem referenceChecker = ToolItem(
    id: 'reference-checker',
    label: 'Reference Checker',
    description: 'Detect missing, duplicate & inconsistent references',
    route: '/academic/reference-checker',
    icon: LucideIcons.checkCircle,
    color: AppColors.toolRed,
    softColor: AppColors.toolRedSoft,
    category: ToolCategory.academic,
    isAi: true,
    isNew: true,
    tags: ['reference', 'citation', 'check', 'missing', 'duplicate', 'research'],
  );

  static const ToolItem studyNotes = ToolItem(
    id: 'study-notes',
    label: 'Study Notes',
    description: 'Generate structured notes with key concepts & definitions',
    route: '/academic/study-notes',
    icon: LucideIcons.notebookPen,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.academic,
    isAi: true,
    isNew: true,
    tags: ['study', 'notes', 'key concepts', 'revision', 'academic', 'learn'],
  );

  static const ToolItem quizGenerator = ToolItem(
    id: 'quiz-generator',
    label: 'Quiz Generator',
    description: 'Generate MCQ, T/F & short-answer quizzes from documents',
    route: '/academic/quiz-generator',
    icon: LucideIcons.graduationCap,
    color: AppColors.toolTeal,
    softColor: AppColors.toolTealSoft,
    category: ToolCategory.academic,
    isAi: true,
    isNew: true,
    tags: ['quiz', 'test', 'question', 'mcq', 'study', 'academic', 'exam'],
  );

  static const ToolItem flashcards = ToolItem(
    id: 'flashcards',
    label: 'Flashcard Generator',
    description: 'Generate term/definition & Q&A flashcards',
    route: '/academic/flashcards',
    icon: LucideIcons.layers,
    color: AppColors.toolPink,
    softColor: AppColors.toolPinkSoft,
    category: ToolCategory.academic,
    isAi: true,
    isNew: true,
    tags: ['flashcard', 'study', 'memorize', 'term', 'definition', 'review'],
  );

  static const ToolItem mindMap = ToolItem(
    id: 'mind-map',
    label: 'Mind Map Generator',
    description: 'Convert document structure to interactive knowledge graph',
    route: '/academic/mind-map',
    icon: LucideIcons.network,
    color: AppColors.toolIndigo,
    softColor: AppColors.toolIndigoSoft,
    category: ToolCategory.academic,
    isAi: true,
    isNew: true,
    tags: ['mind map', 'concept', 'graph', 'knowledge', 'visual', 'study'],
  );

  static const ToolItem presentationGenerator = ToolItem(
    id: 'presentation-generator',
    label: 'Presentation Generator',
    description: 'Generate slide structure & content from documents',
    route: '/academic/presentation-generator',
    icon: LucideIcons.presentation,
    color: AppColors.toolOrange,
    softColor: AppColors.toolOrangeSoft,
    category: ToolCategory.academic,
    isAi: true,
    isNew: true,
    tags: ['presentation', 'slides', 'ppt', 'academic', 'generate'],
  );

  // ── Forms Tools ───────────────────────────────────────────────────────────

  static const ToolItem formFiller = ToolItem(
    id: 'form-filler',
    label: 'Form Filler',
    description: 'Fill PDF form fields: text, checkbox, radio, dropdown',
    route: '/forms/filler',
    icon: LucideIcons.formInput,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.forms,
    isNew: true,
    tags: ['form', 'fill', 'pdf', 'field', 'checkbox', 'input'],
  );

  static const ToolItem formCreator = ToolItem(
    id: 'form-creator',
    label: 'Form Creator',
    description: 'Build PDF forms with text, checkbox & signature fields',
    route: '/forms/creator',
    icon: LucideIcons.fileEdit,
    color: AppColors.toolTeal,
    softColor: AppColors.toolTealSoft,
    category: ToolCategory.forms,
    isNew: true,
    tags: ['form', 'create', 'build', 'pdf', 'field', 'design'],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // LEGACY ID ALIASES
  // Maps old IDs (found in callers) → canonical ToolItem
  // ──────────────────────────────────────────────────────────────────────────

  static const Map<String, String> _legacyIdMap = {
    // Old IDs used in history records, getTopToolsForCategory inline items
    'summarize-pdf': 'ai-summary',
    'ask-pdf': 'ai-doc-chat',
    'ai-ocr': 'ai-ocr', // already canonical
    'extract-tables': 'extract-tables', // already canonical
    'ocr-document': 'ai-ocr',
    'classify-pdf': 'classify-document',
    'translate-pdf': 'translate-doc',
    'image-converter': 'image-converter',
    'video-converter': 'video-converter',
    'media-downloader': 'archive-studio', // fallback — no dedicated downloader screen
    'audio-converter': 'audio-converter',
    'digital-signature': 'digital-sign',
    'metadata-cleaner': 'metadata-manager',
    'convert-pdf': 'word-to-pdf', // generic fallback
    'generate-quiz': 'quiz-generator',
    'archive-extract': 'archive-studio',
    'archive-create-zip': 'archive-studio',
    'archive-create-tar': 'archive-studio',
    'archive-convert': 'archive-studio',
    'image-comp-low': 'image-compressor',
    'image-comp-med': 'image-compressor',
    'image-comp-high': 'image-compressor',
    'image-comp-custom': 'image-compressor',
    'video-to-mp4': 'video-converter',
    'video-to-webm': 'video-converter',
    'video-to-mov': 'video-converter',
    'video-to-gif': 'video-converter',
    'video-comp-low': 'video-compressor',
    'video-comp-med': 'video-compressor',
    'video-comp-high': 'video-compressor',
    'audio-to-mp3': 'audio-converter',
    'audio-to-wav': 'audio-converter',
    'audio-to-ogg': 'audio-converter',
    'jpg-to-png': 'image-converter',
    'png-to-jpg': 'image-converter',
    'webp-to-jpg': 'image-converter',
    'heic-to-jpg': 'image-converter',
    'bmp-to-jpg': 'image-converter',
    'pdf-nup': 'pdf-nup',
    'pdf-booklet': 'pdf-booklet',
    'bates-stamping': 'bates-stamping',
    'pdf-to-pdfa': 'pdf-to-pdfa',
    'pdf-to-pdfa-convert': 'pdf-to-pdfa',
    'digital-sign': 'digital-sign',
    'metadata-manager': 'metadata-manager',
    'word-to-pdf': 'word-to-pdf',
    'pdf-to-word': 'pdf-to-word',
    'excel-to-pdf': 'excel-to-pdf',
    'pdf-to-excel': 'pdf-to-excel',
    'ppt-to-pdf': 'ppt-to-pdf',
    'pdf-to-ppt': 'pdf-to-ppt',
    'image-to-pdf': 'image-to-pdf',
    'pdf-to-image': 'pdf-to-image',
  };

  // ──────────────────────────────────────────────────────────────────────────
  // CANONICAL INDEX
  // ──────────────────────────────────────────────────────────────────────────

  static final Map<String, ToolItem> _registry = {
    pdfEditor.id: pdfEditor,
    mergePdf.id: mergePdf,
    splitPdf.id: splitPdf,
    compressPdf.id: compressPdf,
    extractPages.id: extractPages,
    rotatePdf.id: rotatePdf,
    watermark.id: watermark,
    organizePages.id: organizePages,
    nupPdf.id: nupPdf,
    bookletPdf.id: bookletPdf,
    batesStamping.id: batesStamping,
    headerFooter.id: headerFooter,
    pdfToPdfa.id: pdfToPdfa,
    aiOcr.id: aiOcr,
    aiSummary.id: aiSummary,
    semanticCompare.id: semanticCompare,
    similarityMatrix.id: similarityMatrix,
    aiDocChat.id: aiDocChat,
    semanticSearch.id: semanticSearch,
    classifyDocument.id: classifyDocument,
    extractInfo.id: extractInfo,
    translateDoc.id: translateDoc,
    writingAssistant.id: writingAssistant,
    qualityChecker.id: qualityChecker,
    extractTables.id: extractTables,
    imageEnhancer.id: imageEnhancer,
    parseInvoice.id: parseInvoice,
    parseCv.id: parseCv,
    protectPdf.id: protectPdf,
    smartRedaction.id: smartRedaction,
    digitalSign.id: digitalSign,
    metadataManager.id: metadataManager,
    wordToPdf.id: wordToPdf,
    pdfToWord.id: pdfToWord,
    excelToPdf.id: excelToPdf,
    pdfToExcel.id: pdfToExcel,
    pptToPdf.id: pptToPdf,
    pdfToPpt.id: pdfToPpt,
    imageToPdf.id: imageToPdf,
    pdfToImage.id: pdfToImage,
    imageConverter.id: imageConverter,
    imageCompressor.id: imageCompressor,
    imageManipulator.id: imageManipulator,
    imageResizer.id: imageResizer,
    qrGenerator.id: qrGenerator,
    barcodeGenerator.id: barcodeGenerator,
    videoConverter.id: videoConverter,
    videoCompressor.id: videoCompressor,
    audioConverter.id: audioConverter,
    archiveStudio.id: archiveStudio,
    scanToPdf.id: scanToPdf,
    researchAnalyzer.id: researchAnalyzer,
    literatureReview.id: literatureReview,
    researchGap.id: researchGap,
    citationExtractor.id: citationExtractor,
    citationFormatter.id: citationFormatter,
    referenceChecker.id: referenceChecker,
    studyNotes.id: studyNotes,
    quizGenerator.id: quizGenerator,
    flashcards.id: flashcards,
    mindMap.id: mindMap,
    presentationGenerator.id: presentationGenerator,
    formFiller.id: formFiller,
    formCreator.id: formCreator,
  };

  // ──────────────────────────────────────────────────────────────────────────
  // LOOKUP API
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns the canonical ToolItem for [id], resolving legacy aliases.
  static ToolItem? getById(String id) {
    if (_registry.containsKey(id)) return _registry[id];
    final canonicalId = _legacyIdMap[id];
    if (canonicalId != null) return _registry[canonicalId];
    return null;
  }

  /// Returns the canonical ToolItem whose route matches [route].
  static ToolItem? getByRoute(String route) {
    // Strip query params for comparison
    final routeBase = route.split('?').first;
    for (final tool in _registry.values) {
      if (tool.route == route || tool.route.split('?').first == routeBase) {
        return tool;
      }
    }
    return null;
  }

  /// Returns all tools in a given [category].
  static List<ToolItem> getByCategory(ToolCategory category) =>
      _registry.values.where((t) => t.category == category).toList();

  /// Searches tools by [query] against id, label, description, and tags.
  static List<ToolItem> search(String query) {
    if (query.trim().isEmpty) return allTools;
    final q = query.toLowerCase().trim();
    return _registry.values.where((tool) {
      return tool.id.toLowerCase().contains(q) ||
          tool.label.toLowerCase().contains(q) ||
          tool.description.toLowerCase().contains(q) ||
          tool.tags.any((tag) => tag.toLowerCase().contains(q));
    }).toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CURATED LISTS (references only, no duplication)
  // ──────────────────────────────────────────────────────────────────────────

  /// All canonical tools (no duplicates).
  static List<ToolItem> get allTools => _registry.values.toList();

  /// Featured tools shown on the home screen.
  static List<ToolItem> get featuredTools => [
        pdfEditor,
        mergePdf,
        splitPdf,
        compressPdf,
        aiSummary,
        aiDocChat,
        protectPdf,
        smartRedaction,
      ];

  /// Quick-access tools (same as featured by default).
  static List<ToolItem> get quickTools => featuredTools;

  /// All AI-powered tools.
  static List<ToolItem> get aiTools =>
      _registry.values.where((t) => t.isAi).toList();

  /// Academic & research tools.
  static List<ToolItem> get academicTools => [
        researchAnalyzer,
        literatureReview,
        researchGap,
        citationExtractor,
        citationFormatter,
        referenceChecker,
        studyNotes,
        quizGenerator,
        flashcards,
        mindMap,
        presentationGenerator,
      ];

  /// Scanner tools.
  static List<ToolItem> get scannerTools => [
        scanToPdf,
        aiOcr,
      ];

  /// Forms tools.
  static List<ToolItem> get formTools => [formFiller, formCreator];

  /// Returns the top tools for a given category key (for contextual nav bar).
  /// All entries are canonical registry references — no inline ToolItems.
  static List<ToolItem> getTopToolsForCategory(String categoryKey) {
    final key = categoryKey.toLowerCase().trim();

    switch (key) {
      case 'ai':
      case 'intelligence':
        return [aiDocChat, aiSummary, aiOcr, extractTables];

      case 'pdf':
        return [pdfEditor, mergePdf, splitPdf, compressPdf];

      case 'academic':
      case 'research':
        return [researchAnalyzer, literatureReview, researchGap, citationFormatter];

      case 'scanner':
      case 'scan':
        return [scanToPdf, aiOcr];

      case 'forms':
      case 'form':
        return [formFiller, formCreator];

      case 'security':
      case 'privacy':
        return [protectPdf, smartRedaction, digitalSign, metadataManager];

      case 'media':
      case 'image':
      case 'images':
        return [imageConverter, imageCompressor, imageManipulator, imageResizer];

      case 'video':
        return [videoConverter, videoCompressor];

      case 'audio':
        return [audioConverter];

      case 'archive':
        return [archiveStudio];

      case 'convert':
      case 'conversion':
        return [wordToPdf, pdfToWord, excelToPdf, imageToPdf];

      case 'utilities':
        return [qrGenerator, barcodeGenerator, imageResizer];

      default:
        return [mergePdf, compressPdf, organizePages, extractPages];
    }
  }
}
