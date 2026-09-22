import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/tool_item.dart';
import '../theme/app_colors.dart';

/// Canonical ToolRegistry — one ToolItem definition per tool.
///
/// Organized into the 15 Authoritative Functional Domains of MaskerV
/// with shared cross-domain general utilities.
class ToolRegistry {
  ToolRegistry._();

  // ──────────────────────────────────────────────────────────────────────────
  // DOMAIN 1: File Manipulation & Document Tools
  // ──────────────────────────────────────────────────────────────────────────

  static const ToolItem pdfEditor = ToolItem(
    id: 'pdf-editor',
    label: 'PDF Editor',
    description: 'In-place text editing & object replacement',
    route: '/tools/pdf-editor',
    icon: LucideIcons.fileSignature,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.pdf,
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
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
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
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
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
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
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
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
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
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
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
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
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
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
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
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
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
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
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
    tags: ['booklet', 'print', 'fold', 'pdf'],
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
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
    tags: ['header', 'footer', 'page number', 'date', 'pdf'],
  );

  static const ToolItem wordToPdf = ToolItem(
    id: 'word-to-pdf',
    label: 'Word to PDF',
    description: 'Convert DOC/DOCX documents to PDF format',
    route: '/tools/convert?from=word&to=pdf',
    icon: LucideIcons.fileText,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.convert,
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
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
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
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
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
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
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
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
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
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
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
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
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
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
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
    tags: ['pdf', 'image', 'jpg', 'png', 'convert'],
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
    domainNumber: 1,
    domainName: 'File Manipulation & Document Tools',
    domainId: DomainId.fileManipulation,
    tags: ['pdfa', 'archive', 'iso', 'long-term', 'pdf'],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // DOMAIN 2: Security, Cryptography & Compliance Vault
  // ──────────────────────────────────────────────────────────────────────────

  static const ToolItem protectPdf = ToolItem(
    id: 'protect-pdf',
    label: 'Protect PDF',
    description: '256-bit AES password encryption & permissions',
    route: '/security/protect',
    icon: LucideIcons.lock,
    color: AppColors.toolRed,
    softColor: AppColors.toolRedSoft,
    category: ToolCategory.security,
    domainNumber: 2,
    domainName: 'Security, Cryptography & Compliance Vault',
    domainId: DomainId.securityVault,
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
    domainNumber: 2,
    domainName: 'Security, Cryptography & Compliance Vault',
    domainId: DomainId.securityVault,
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
    domainNumber: 2,
    domainName: 'Security, Cryptography & Compliance Vault',
    domainId: DomainId.securityVault,
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
    domainNumber: 2,
    domainName: 'Security, Cryptography & Compliance Vault',
    domainId: DomainId.securityVault,
    tags: ['metadata', 'privacy', 'sanitize', 'author', 'pdf'],
  );


  // ──────────────────────────────────────────────────────────────────────────
  // DOMAIN 3: Academic & Research Intelligence Suite
  // ──────────────────────────────────────────────────────────────────────────

  static const ToolItem researchAnalyzer = ToolItem(
    id: 'research-analyzer',
    label: 'Research Analyzer',
    description: 'Deep analysis: title, abstract, methods, results & gaps',
    route: '/academic/research-analyzer',
    icon: LucideIcons.microscope,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.academic,
    domainNumber: 3,
    domainName: 'Academic & Research Intelligence Suite',
    domainId: DomainId.academicIntelligence,
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
    domainNumber: 3,
    domainName: 'Academic & Research Intelligence Suite',
    domainId: DomainId.academicIntelligence,
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
    domainNumber: 3,
    domainName: 'Academic & Research Intelligence Suite',
    domainId: DomainId.academicIntelligence,
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
    domainNumber: 3,
    domainName: 'Academic & Research Intelligence Suite',
    domainId: DomainId.academicIntelligence,
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
    domainNumber: 3,
    domainName: 'Academic & Research Intelligence Suite',
    domainId: DomainId.academicIntelligence,
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
    domainNumber: 3,
    domainName: 'Academic & Research Intelligence Suite',
    domainId: DomainId.academicIntelligence,
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
    domainNumber: 3,
    domainName: 'Academic & Research Intelligence Suite',
    domainId: DomainId.academicIntelligence,
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
    domainNumber: 3,
    domainName: 'Academic & Research Intelligence Suite',
    domainId: DomainId.academicIntelligence,
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
    domainNumber: 3,
    domainName: 'Academic & Research Intelligence Suite',
    domainId: DomainId.academicIntelligence,
    isAi: true,
    isNew: true,
    tags: ['flashcard', 'study', 'memorize', 'term', 'definition', 'review'],
  );

  static const ToolItem aiSummary = ToolItem(
    id: 'ai-summary',
    label: 'AI Summary',
    description: 'Detailed, short, key points & action items',
    route: '/ai/summarize',
    icon: LucideIcons.sparkles,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.academic,
    domainNumber: 3,
    domainName: 'Academic & Research Intelligence Suite',
    domainId: DomainId.academicIntelligence,
    isAi: true,
    tags: ['summary', 'summarize', 'overview', 'key points', 'ai'],
  );

  static const ToolItem aiDocChat = ToolItem(
    id: 'ai-doc-chat',
    label: 'AI Document Chat',
    description: 'Interactive conversational Q&A and research',
    route: '/ai/ask',
    icon: LucideIcons.messageSquare,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.academic,
    domainNumber: 3,
    domainName: 'Academic & Research Intelligence Suite',
    domainId: DomainId.academicIntelligence,
    isAi: true,
    tags: ['chat', 'ask', 'question', 'conversation', 'ai'],
  );

  static const ToolItem semanticCompare = ToolItem(
    id: 'semantic-compare',
    label: 'Semantic Compare',
    description: 'Compare meaning & temporal/financial changes',
    route: '/ai/compare',
    icon: LucideIcons.gitCompare,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.academic,
    domainNumber: 3,
    domainName: 'Academic & Research Intelligence Suite',
    domainId: DomainId.academicIntelligence,
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
    category: ToolCategory.academic,
    domainNumber: 3,
    domainName: 'Academic & Research Intelligence Suite',
    domainId: DomainId.academicIntelligence,
    isAi: true,
    tags: ['similarity', 'duplicate', 'matrix', 'ai'],
  );

  static const ToolItem semanticSearch = ToolItem(
    id: 'semantic-search',
    label: 'Semantic Search',
    description: 'Search document by intent and meaning',
    route: '/ai/search',
    icon: LucideIcons.search,
    color: AppColors.toolTeal,
    softColor: AppColors.toolTealSoft,
    category: ToolCategory.academic,
    domainNumber: 3,
    domainName: 'Academic & Research Intelligence Suite',
    domainId: DomainId.academicIntelligence,
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
    category: ToolCategory.academic,
    domainNumber: 3,
    domainName: 'Academic & Research Intelligence Suite',
    domainId: DomainId.academicIntelligence,
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
    category: ToolCategory.academic,
    domainNumber: 3,
    domainName: 'Academic & Research Intelligence Suite',
    domainId: DomainId.academicIntelligence,
    isAi: true,
    tags: ['extract', 'information', 'fields', 'invoice', 'resume', 'ai'],
  );

  static const ToolItem writingAssistant = ToolItem(
    id: 'writing-assistant',
    label: 'Writing Assistant',
    description: 'Grammar, paraphrase, formal & tone polish',
    route: '/ai/writing-assist',
    icon: LucideIcons.penTool,
    color: AppColors.toolGreen,
    softColor: AppColors.toolGreenSoft,
    category: ToolCategory.academic,
    domainNumber: 3,
    domainName: 'Academic & Research Intelligence Suite',
    domainId: DomainId.academicIntelligence,
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
    category: ToolCategory.academic,
    domainNumber: 3,
    domainName: 'Academic & Research Intelligence Suite',
    domainId: DomainId.academicIntelligence,
    isAi: true,
    tags: ['quality', 'audit', 'check', 'readability', 'ai'],
  );

  static const ToolItem parseCv = ToolItem(
    id: 'parse-cv',
    label: 'Resume AI Scanner',
    description: 'Extract skills, experience & education',
    route: '/ai/resume',
    icon: LucideIcons.fileUser,
    color: AppColors.toolOrange,
    softColor: AppColors.toolOrangeSoft,
    category: ToolCategory.academic,
    domainNumber: 3,
    domainName: 'Academic & Research Intelligence Suite',
    domainId: DomainId.academicIntelligence,
    isAi: true,
    tags: ['resume', 'cv', 'skills', 'experience', 'ai'],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // DOMAIN 4: Optical Scanning & Vision Engine (OCR)
  // ──────────────────────────────────────────────────────────────────────────

  static const ToolItem aiOcr = ToolItem(
    id: 'ai-ocr',
    label: 'OCR Text & Layout',
    description: 'Extract text & tables from scans/images',
    route: '/ai/ocr',
    icon: LucideIcons.scanLine,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.scanner,
    domainNumber: 4,
    domainName: 'Optical Scanning & Vision Engine (OCR)',
    domainId: DomainId.opticalVisionOcr,
    isAi: true,
    tags: ['ocr', 'scan', 'text', 'extract', 'image', 'scanned'],
  );

  static const ToolItem scanToPdf = ToolItem(
    id: 'scan-to-pdf',
    label: 'Scan to PDF',
    description: 'Camera scan with edge detection, crop & OCR to searchable PDF',
    route: '/scanner',
    icon: LucideIcons.camera,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.scanner,
    domainNumber: 4,
    domainName: 'Optical Scanning & Vision Engine (OCR)',
    domainId: DomainId.opticalVisionOcr,
    tags: ['scan', 'camera', 'pdf', 'ocr', 'document', 'searchable'],
  );

  static const ToolItem imageEnhancer = ToolItem(
    id: 'image-enhancer',
    label: 'Image Enhancer',
    description: 'AI upscaling & image quality improvement',
    route: '/ai/image-enhancer',
    icon: LucideIcons.imagePlus,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.scanner,
    domainNumber: 4,
    domainName: 'Optical Scanning & Vision Engine (OCR)',
    domainId: DomainId.opticalVisionOcr,
    isAi: true,
    tags: ['enhance', 'upscale', 'image', 'quality', 'ai'],
  );

  static const ToolItem imageConverter = ToolItem(
    id: 'image-converter',
    label: 'Image Converter',
    description: 'Convert between JPG, PNG, WebP, HEIC, BMP',
    route: '/tools/image-converter',
    icon: LucideIcons.image,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.image,
    domainNumber: 4,
    domainName: 'Optical Scanning & Vision Engine (OCR)',
    domainId: DomainId.opticalVisionOcr,
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
    domainNumber: 4,
    domainName: 'Optical Scanning & Vision Engine (OCR)',
    domainId: DomainId.opticalVisionOcr,
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
    domainNumber: 4,
    domainName: 'Optical Scanning & Vision Engine (OCR)',
    domainId: DomainId.opticalVisionOcr,
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
    domainNumber: 4,
    domainName: 'Optical Scanning & Vision Engine (OCR)',
    domainId: DomainId.opticalVisionOcr,
    isNew: true,
    tags: ['image', 'resize', 'dimensions', 'scale', 'batch'],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // DOMAIN 5: Gamified Cognitive Retention & Active Study Studio
  // ──────────────────────────────────────────────────────────────────────────

  static const ToolItem cognitiveRetention = ToolItem(
    id: 'cognitive-retention',
    label: 'Cognitive Retention Studio',
    description: 'Active recall blur-to-reveal reading & Leitner study',
    route: '/cognitive/retention',
    icon: LucideIcons.brain,
    color: AppColors.toolOrange,
    softColor: AppColors.toolOrangeSoft,
    category: ToolCategory.cognitive,
    domainNumber: 5,
    domainName: 'Gamified Cognitive Retention & Active Study Studio',
    domainId: DomainId.cognitiveRetention,
    tags: ['active recall', 'flashcard', 'study', 'retention', 'blur', 'wpm'],
  );

  static const ToolItem spacedRepetition = ToolItem(
    id: 'spaced-repetition',
    label: 'Spaced Repetition SM-2 Tracker',
    description: 'SM-2 / Leitner box flashcard interval calculator',
    route: '/cognitive/spaced-repetition',
    icon: LucideIcons.calendarCheck,
    color: AppColors.toolOrange,
    softColor: AppColors.toolOrangeSoft,
    category: ToolCategory.cognitive,
    domainNumber: 5,
    domainName: 'Gamified Cognitive Retention & Active Study Studio',
    domainId: DomainId.cognitiveRetention,
    isNew: true,
    tags: ['spaced repetition', 'leitner', 'sm-2', 'study', 'flashcard'],
  );

  static const ToolItem speedReader = ToolItem(
    id: 'speed-reader',
    label: 'Speed Reading RSVP Trainer',
    description: 'RSVP rapid serial visual presentation reading velocity trainer',
    route: '/cognitive/speed-reader',
    icon: LucideIcons.zap,
    color: AppColors.toolOrange,
    softColor: AppColors.toolOrangeSoft,
    category: ToolCategory.cognitive,
    domainNumber: 5,
    domainName: 'Gamified Cognitive Retention & Active Study Studio',
    domainId: DomainId.cognitiveRetention,
    isNew: true,
    tags: ['speed reading', 'rsvp', 'wpm', 'reading', 'focus'],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // DOMAIN 6: Multi-Modal Voice & Podcast Audio Studio
  // ──────────────────────────────────────────────────────────────────────────

  static const ToolItem voicePodcast = ToolItem(
    id: 'voice-podcast',
    label: 'Voice & Podcast Studio',
    description: 'Conversational dialogue podcast script & TTS audio player',
    route: '/voice/podcast',
    icon: LucideIcons.mic,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.voice,
    domainNumber: 6,
    domainName: 'Multi-Modal Voice & Podcast Audio Studio',
    domainId: DomainId.voicePodcastStudio,
    tags: ['podcast', 'voice', 'audio', 'tts', 'dialogue', 'speech'],
  );

  static const ToolItem audioConverter = ToolItem(
    id: 'audio-converter',
    label: 'Audio Converter',
    description: 'Convert between MP3, WAV, OGG formats',
    route: '/tools/audio-converter',
    icon: LucideIcons.music,
    color: AppColors.toolGreen,
    softColor: AppColors.toolGreenSoft,
    category: ToolCategory.audio,
    domainNumber: 6,
    domainName: 'Multi-Modal Voice & Podcast Audio Studio',
    domainId: DomainId.voicePodcastStudio,
    tags: ['audio', 'convert', 'mp3', 'wav', 'ogg'],
  );

  static const ToolItem audioTrimmer = ToolItem(
    id: 'audio-trimmer',
    label: 'Audio Trimmer & Cutter',
    description: 'Trim start & end timestamps from audio files',
    route: '/voice/audio-trimmer',
    icon: LucideIcons.scissors,
    color: AppColors.toolIndigo,
    softColor: AppColors.toolIndigoSoft,
    category: ToolCategory.audio,
    domainNumber: 6,
    domainName: 'Multi-Modal Voice & Podcast Audio Studio',
    domainId: DomainId.voicePodcastStudio,
    isNew: true,
    tags: ['audio', 'trim', 'cut', 'mp3', 'wav'],
  );

  static const ToolItem voiceTranscriber = ToolItem(
    id: 'voice-transcriber',
    label: 'Voice Note Transcriber',
    description: 'Convert voice recordings into clean transcript text',
    route: '/voice/transcriber',
    icon: LucideIcons.mic,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.audio,
    domainNumber: 6,
    domainName: 'Multi-Modal Voice & Podcast Audio Studio',
    domainId: DomainId.voicePodcastStudio,
    isNew: true,
    tags: ['voice', 'transcribe', 'speech to text', 'audio'],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // DOMAIN 7: Universal Accessibility & Inclusive Reading Studio
  // ──────────────────────────────────────────────────────────────────────────

  static const ToolItem accessibilityReader = ToolItem(
    id: 'accessibility-reader',
    label: 'Accessibility Reader Studio',
    description: 'Bionic Reading, OpenDyslexic font & high-contrast themes',
    route: '/accessibility/reader',
    icon: LucideIcons.eye,
    color: AppColors.toolTeal,
    softColor: AppColors.toolTealSoft,
    category: ToolCategory.accessibility,
    domainNumber: 7,
    domainName: 'Universal Accessibility & Inclusive Reading Studio',
    domainId: DomainId.accessibilityReader,
    tags: ['bionic', 'dyslexia', 'accessibility', 'contrast', 'reading'],
  );

  static const ToolItem highContrastReader = ToolItem(
    id: 'high-contrast-reader',
    label: 'High Contrast Reader',
    description: 'Low-vision & color-blind inclusive reading themes',
    route: '/accessibility/high-contrast',
    icon: LucideIcons.sun,
    color: AppColors.toolTeal,
    softColor: AppColors.toolTealSoft,
    category: ToolCategory.accessibility,
    domainNumber: 7,
    domainName: 'Universal Accessibility & Inclusive Reading Studio',
    domainId: DomainId.accessibilityReader,
    isNew: true,
    tags: ['accessibility', 'contrast', 'low vision', 'color blind'],
  );

  static const ToolItem ttsAccessibility = ToolItem(
    id: 'tts-accessibility',
    label: 'Text-to-Speech Accessibility',
    description: 'Read text aloud with speed & pitch controls',
    route: '/accessibility/tts',
    icon: LucideIcons.volume2,
    color: AppColors.toolTeal,
    softColor: AppColors.toolTealSoft,
    category: ToolCategory.accessibility,
    domainNumber: 7,
    domainName: 'Universal Accessibility & Inclusive Reading Studio',
    domainId: DomainId.accessibilityReader,
    isNew: true,
    tags: ['tts', 'speech', 'read aloud', 'voice'],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // DOMAIN 8: Legal & Forensic Compliance Audit Suite
  // ──────────────────────────────────────────────────────────────────────────

  static const ToolItem batesStamping = ToolItem(
    id: 'bates-stamping',
    label: 'Bates Stamping',
    description: 'Sequential legal document numbering & discovery codes',
    route: '/tools/bates',
    icon: LucideIcons.binary,
    color: AppColors.toolRed,
    softColor: AppColors.toolRedSoft,
    category: ToolCategory.legal,
    domainNumber: 8,
    domainName: 'Legal & Forensic Compliance Audit Suite',
    domainId: DomainId.legalAuditSuite,
    tags: ['bates', 'numbering', 'legal', 'stamp', 'pdf', 'exhibit'],
  );

  static const ToolItem legalAudit = ToolItem(
    id: 'legal-audit',
    label: 'Legal & Forensic Audit Suite',
    description: 'SHA-256 chain-of-custody log, clause matrix & Bates codes',
    route: '/legal/audit',
    icon: LucideIcons.scale,
    color: AppColors.toolRed,
    softColor: AppColors.toolRedSoft,
    category: ToolCategory.legal,
    domainNumber: 8,
    domainName: 'Legal & Forensic Compliance Audit Suite',
    domainId: DomainId.legalAuditSuite,
    tags: ['legal', 'forensic', 'sha256', 'hash', 'bates', 'clause', 'contract'],
  );

  static const ToolItem legalRedactionCertifier = ToolItem(
    id: 'legal-redaction-certifier',
    label: 'Legal Redaction Certifier',
    description: 'Generate SHA-256 audit certificate for redacted documents',
    route: '/legal/redaction-certifier',
    icon: LucideIcons.shieldCheck,
    color: AppColors.toolRed,
    softColor: AppColors.toolRedSoft,
    category: ToolCategory.legal,
    domainNumber: 8,
    domainName: 'Legal & Forensic Compliance Audit Suite',
    domainId: DomainId.legalAuditSuite,
    isNew: true,
    tags: ['legal', 'redaction', 'certificate', 'sha256', 'audit'],
  );

  static const ToolItem clauseComparator = ToolItem(
    id: 'clause-comparator',
    label: 'Contract Clause Comparator',
    description: 'Side-by-side legal clause diff and risk analyzer',
    route: '/legal/clause-comparator',
    icon: LucideIcons.gitCompare,
    color: AppColors.toolRed,
    softColor: AppColors.toolRedSoft,
    category: ToolCategory.legal,
    domainNumber: 8,
    domainName: 'Legal & Forensic Compliance Audit Suite',
    domainId: DomainId.legalAuditSuite,
    isNew: true,
    tags: ['contract', 'clause', 'compare', 'diff', 'legal'],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // DOMAIN 9: Interactive Form Builder & Auto-Fill Engine
  // ──────────────────────────────────────────────────────────────────────────

  static const ToolItem formFiller = ToolItem(
    id: 'form-filler',
    label: 'Form Filler',
    description: 'Fill PDF form fields: text, checkbox, radio, dropdown',
    route: '/forms/filler',
    icon: LucideIcons.formInput,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.forms,
    domainNumber: 9,
    domainName: 'Interactive Form Builder & Auto-Fill Engine',
    domainId: DomainId.formBuilderEngine,
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
    domainNumber: 9,
    domainName: 'Interactive Form Builder & Auto-Fill Engine',
    domainId: DomainId.formBuilderEngine,
    isNew: true,
    tags: ['form', 'create', 'build', 'pdf', 'field', 'design'],
  );

  static const ToolItem formDataExtractor = ToolItem(
    id: 'form-data-extractor',
    label: 'Form Field Data Extractor',
    description: 'Export filled form field data to JSON & CSV',
    route: '/forms/data-extractor',
    icon: LucideIcons.fileSpreadsheet,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.forms,
    domainNumber: 9,
    domainName: 'Interactive Form Builder & Auto-Fill Engine',
    domainId: DomainId.formBuilderEngine,
    isNew: true,
    tags: ['form', 'extract', 'data', 'json', 'csv'],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // DOMAIN 10: Visual Mind Mapping & Diagram Studio
  // ──────────────────────────────────────────────────────────────────────────

  static const ToolItem mindMapDiagram = ToolItem(
    id: 'diagram-mindmap',
    label: 'Visual Mind Map Studio',
    description: 'Outline-to-mindmap node graph & visual canvas',
    route: '/diagram/mindmap',
    icon: LucideIcons.gitFork,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.diagram,
    domainNumber: 10,
    domainName: 'Visual Mind Mapping & Diagram Studio',
    domainId: DomainId.mindMappingStudio,
    tags: ['mindmap', 'diagram', 'visual', 'nodes', 'canvas', 'graph'],
  );

  static const ToolItem mindMap = ToolItem(
    id: 'mind-map',
    label: 'Mind Map Generator',
    description: 'Convert document structure to interactive knowledge graph',
    route: '/academic/mind-map',
    icon: LucideIcons.network,
    color: AppColors.toolIndigo,
    softColor: AppColors.toolIndigoSoft,
    category: ToolCategory.diagram,
    domainNumber: 10,
    domainName: 'Visual Mind Mapping & Diagram Studio',
    domainId: DomainId.mindMappingStudio,
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
    category: ToolCategory.diagram,
    domainNumber: 10,
    domainName: 'Visual Mind Mapping & Diagram Studio',
    domainId: DomainId.mindMappingStudio,
    isAi: true,
    isNew: true,
    tags: ['presentation', 'slides', 'ppt', 'academic', 'generate'],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // DOMAIN 11: Student Productivity & Dual-Pane Workspace Hub
  // ──────────────────────────────────────────────────────────────────────────

  static const ToolItem dualPaneWorkspace = ToolItem(
    id: 'workspace-dualpane',
    label: 'Dual-Pane Workspace Hub',
    description: 'Split-screen side-by-side document viewer & markdown notes',
    route: '/workspace/dualpane',
    icon: LucideIcons.layoutGrid,
    color: AppColors.toolIndigo,
    softColor: AppColors.toolIndigoSoft,
    category: ToolCategory.workspace,
    domainNumber: 11,
    domainName: 'Student Productivity & Dual-Pane Workspace Hub',
    domainId: DomainId.studentWorkspace,
    tags: ['dualpane', 'workspace', 'split', 'notes', 'markdown', 'study'],
  );

  static const ToolItem focusPomodoro = ToolItem(
    id: 'focus-pomodoro',
    label: 'Focus Pomodoro Timer',
    description: 'Study focus timer with 25-minute break cycles',
    route: '/workspace/pomodoro',
    icon: LucideIcons.timer,
    color: AppColors.toolIndigo,
    softColor: AppColors.toolIndigoSoft,
    category: ToolCategory.workspace,
    domainNumber: 11,
    domainName: 'Student Productivity & Dual-Pane Workspace Hub',
    domainId: DomainId.studentWorkspace,
    isNew: true,
    tags: ['pomodoro', 'timer', 'study', 'focus'],
  );

  static const ToolItem gpaCalculator = ToolItem(
    id: 'gpa-calculator',
    label: 'Student Grade & GPA Calculator',
    description: 'Calculate course grades & GPA target predictions',
    route: '/workspace/gpa-calculator',
    icon: LucideIcons.calculator,
    color: AppColors.toolIndigo,
    softColor: AppColors.toolIndigoSoft,
    category: ToolCategory.workspace,
    domainNumber: 11,
    domainName: 'Student Productivity & Dual-Pane Workspace Hub',
    domainId: DomainId.studentWorkspace,
    isNew: true,
    tags: ['gpa', 'grade', 'calculator', 'student', 'course'],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // DOMAIN 12: Media Utilities & Developer Tools Hub
  // ──────────────────────────────────────────────────────────────────────────

  static const ToolItem watermarkStudio = ToolItem(
    id: 'watermark-studio',
    label: 'Image & Doc Watermark Studio',
    description: 'Add custom text or image watermarks, position & opacity',
    route: '/domain12/watermark-studio',
    icon: LucideIcons.stamp,
    color: AppColors.toolTeal,
    softColor: AppColors.toolTealSoft,
    category: ToolCategory.image,
    domainNumber: 12,
    domainName: 'Media Utilities & Developer Tools Hub',
    domainId: DomainId.mediaDevUtilities,
    isNew: true,
    tags: ['watermark', 'stamp', 'image', 'brand', 'pdf'],
  );

  static const ToolItem batchImageConverter = ToolItem(
    id: 'batch-image-converter',
    label: 'Batch Image Converter',
    description: 'Convert multiple images simultaneously to PNG, JPG, WEBP',
    route: '/domain12/batch-image-converter',
    icon: LucideIcons.images,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.image,
    domainNumber: 12,
    domainName: 'Media Utilities & Developer Tools Hub',
    domainId: DomainId.mediaDevUtilities,
    isNew: true,
    tags: ['batch', 'image', 'convert', 'png', 'jpg', 'webp'],
  );

  static const ToolItem hashGenerator = ToolItem(
    id: 'hash-generator',
    label: 'File Checksum & Hash Studio',
    description: 'Compute MD5, SHA-1 & SHA-256 cryptographic checksums',
    route: '/domain12/hash-generator',
    icon: LucideIcons.binary,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.utilities,
    domainNumber: 12,
    domainName: 'Media Utilities & Developer Tools Hub',
    domainId: DomainId.mediaDevUtilities,
    isNew: true,
    tags: ['hash', 'md5', 'sha256', 'checksum', 'integrity'],
  );

  static const ToolItem textBeautifier = ToolItem(
    id: 'text-beautifier',
    label: 'Text & Code Beautifier',
    description: 'Format JSON/XML, convert text cases (camelCase), Base64',
    route: '/domain12/text-beautifier',
    icon: LucideIcons.code,
    color: AppColors.toolIndigo,
    softColor: AppColors.toolIndigoSoft,
    category: ToolCategory.utilities,
    domainNumber: 12,
    domainName: 'Media Utilities & Developer Tools Hub',
    domainId: DomainId.mediaDevUtilities,
    isNew: true,
    tags: ['code', 'json', 'beautify', 'camelcase', 'base64'],
  );

  static const ToolItem exifStripper = ToolItem(
    id: 'exif-stripper',
    label: 'EXIF & Metadata Stripper',
    description: 'Inspect & sanitize image EXIF tags & GPS locations',
    route: '/domain12/exif-stripper',
    icon: LucideIcons.shieldAlert,
    color: AppColors.toolRed,
    softColor: AppColors.toolRedSoft,
    category: ToolCategory.image,
    domainNumber: 12,
    domainName: 'Media Utilities & Developer Tools Hub',
    domainId: DomainId.mediaDevUtilities,
    isNew: true,
    tags: ['exif', 'metadata', 'gps', 'privacy', 'sanitize'],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // DOMAIN 13: Data Analytics & Tabular Data Extractor
  // ──────────────────────────────────────────────────────────────────────────

  static const ToolItem tabularExtractor = ToolItem(
    id: 'analytics-tables',
    label: 'Tabular Data Extractor',
    description: 'Detect table boundaries & export PDF tables to CSV/Excel',
    route: '/analytics/tables',
    icon: LucideIcons.table,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.analytics,
    domainNumber: 13,
    domainName: 'Data Analytics & Tabular Data Extractor',
    domainId: DomainId.dataAnalyticsTabular,
    tags: ['table', 'csv', 'excel', 'extract', 'data', 'tabular'],
  );

  static const ToolItem extractTables = ToolItem(
    id: 'extract-tables',
    label: 'Extract Tables',
    description: 'Detect & export structured tables with AI engine',
    route: '/ai/extract-tables',
    icon: LucideIcons.tableProperties,
    color: AppColors.toolGreen,
    softColor: AppColors.toolGreenSoft,
    category: ToolCategory.analytics,
    domainNumber: 13,
    domainName: 'Data Analytics & Tabular Data Extractor',
    domainId: DomainId.dataAnalyticsTabular,
    isAi: true,
    tags: ['table', 'extract', 'csv', 'data', 'ai'],
  );

  static const ToolItem parseInvoice = ToolItem(
    id: 'parse-invoice',
    label: 'Invoice AI Parser',
    description: 'Extract vendor, date, totals & line items',
    route: '/ai/invoice',
    icon: LucideIcons.receipt,
    color: AppColors.toolGreen,
    softColor: AppColors.toolGreenSoft,
    category: ToolCategory.analytics,
    domainNumber: 13,
    domainName: 'Data Analytics & Tabular Data Extractor',
    domainId: DomainId.dataAnalyticsTabular,
    isAi: true,
    tags: ['invoice', 'receipt', 'vendor', 'amount', 'parse', 'ai'],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // DOMAIN 14: Translation & Multi-Lingual Localization Hub
  // ──────────────────────────────────────────────────────────────────────────

  static const ToolItem translateDoc = ToolItem(
    id: 'translate-doc',
    label: 'AI Translation',
    description: 'Translate into 15+ languages',
    route: '/ai/translate',
    icon: LucideIcons.languages,
    color: AppColors.toolGreen,
    softColor: AppColors.toolGreenSoft,
    category: ToolCategory.translation,
    domainNumber: 14,
    domainName: 'Translation & Multi-Lingual Localization Hub',
    domainId: DomainId.translationHub,
    isAi: true,
    tags: ['translate', 'language', 'multilingual', 'ai'],
  );

  static const ToolItem translationHub = ToolItem(
    id: 'translation-hub',
    label: 'Translation & Localization Hub',
    description: 'Side-by-side paragraph translation in Spanish, French, German',
    route: '/translation/hub',
    icon: LucideIcons.globe2,
    color: AppColors.toolPink,
    softColor: AppColors.toolPinkSoft,
    category: ToolCategory.translation,
    domainNumber: 14,
    domainName: 'Translation & Multi-Lingual Localization Hub',
    domainId: DomainId.translationHub,
    tags: ['translate', 'languages', 'spanish', 'french', 'german', 'localization'],
  );

  static const ToolItem multilingualGlossary = ToolItem(
    id: 'multilingual-glossary',
    label: 'Multilingual Dictionary & Glossary',
    description: 'Build domain term dictionaries & translation lookups',
    route: '/translation/glossary',
    icon: LucideIcons.bookMarked,
    color: AppColors.toolPink,
    softColor: AppColors.toolPinkSoft,
    category: ToolCategory.translation,
    domainNumber: 14,
    domainName: 'Translation & Multi-Lingual Localization Hub',
    domainId: DomainId.translationHub,
    isNew: true,
    tags: ['glossary', 'dictionary', 'translation', 'multilingual'],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // DOMAIN 15: Automated Publishing & e-Book Studio
  // ──────────────────────────────────────────────────────────────────────────

  static const ToolItem publishingStudio = ToolItem(
    id: 'publishing-studio',
    label: 'Automated Publishing Studio',
    description: 'CMYK pre-flight audit checklist & ePub book generator',
    route: '/publishing/studio',
    icon: LucideIcons.bookOpenCheck,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.publishing,
    domainNumber: 15,
    domainName: 'Automated Publishing & e-Book Studio',
    domainId: DomainId.publishingStudio,
    tags: ['publishing', 'epub', 'cmyk', 'preflight', 'book', 'cover'],
  );

  static const ToolItem ebookCoverDesigner = ToolItem(
    id: 'ebook-cover-designer',
    label: 'e-Book Cover Design Studio',
    description: 'Design e-book cover front & back layouts with themes',
    route: '/publishing/cover-designer',
    icon: LucideIcons.bookOpen,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.publishing,
    domainNumber: 15,
    domainName: 'Automated Publishing & e-Book Studio',
    domainId: DomainId.publishingStudio,
    isNew: true,
    tags: ['cover', 'ebook', 'design', 'epub', 'publishing'],
  );

  static const ToolItem markdownToEpub = ToolItem(
    id: 'markdown-to-epub',
    label: 'Markdown to ePub Publisher',
    description: 'Compile markdown files into standard .epub e-books',
    route: '/publishing/markdown-epub',
    icon: LucideIcons.fileCheck,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.publishing,
    domainNumber: 15,
    domainName: 'Automated Publishing & e-Book Studio',
    domainId: DomainId.publishingStudio,
    isNew: true,
    tags: ['markdown', 'epub', 'ebook', 'publish'],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // GENERAL UTILITIES LAYER (Cross-Domain, Not a 16th Domain)
  // ──────────────────────────────────────────────────────────────────────────

  static const ToolItem qrGenerator = ToolItem(
    id: 'qr-generator',
    label: 'QR Code Generator',
    description: 'Custom QR codes with logos, frames, styles & vector SVG',
    route: '/tools/qr-generator',
    icon: LucideIcons.qrCode,
    color: AppColors.toolIndigo,
    softColor: AppColors.toolIndigoSoft,
    category: ToolCategory.utilities,
    domainNumber: null,
    domainName: 'General Utilities & Media',
    domainId: DomainId.utilities,
    isNew: true,
    tags: ['qr', 'qr code', 'barcode', 'link', 'generator', 'wifi', 'vcard', 'svg'],
  );

  static const ToolItem qrScanner = ToolItem(
    id: 'qr-scanner',
    label: 'QR Code Scanner',
    description: 'Live camera & image QR scanner with smart payload actions',
    route: '/tools/qr-scanner',
    icon: LucideIcons.scanLine,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.utilities,
    domainNumber: null,
    domainName: 'General Utilities & Media',
    domainId: DomainId.utilities,
    isNew: true,
    tags: ['qr', 'scanner', 'scan', 'camera', 'barcode', 'reader', 'decode'],
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
    domainNumber: null,
    domainName: 'General Utilities & Media',
    domainId: DomainId.utilities,
    isNew: true,
    tags: ['barcode', 'code128', 'ean', 'product', 'inventory'],
  );

  static const ToolItem videoConverter = ToolItem(
    id: 'video-converter',
    label: 'Video Converter',
    description: 'Convert between MP4, WebM, MOV & GIF',
    route: '/tools/video-converter',
    icon: LucideIcons.video,
    color: AppColors.toolBlue,
    softColor: AppColors.toolBlueSoft,
    category: ToolCategory.video,
    domainNumber: null,
    domainName: 'General Utilities & Media',
    domainId: DomainId.utilities,
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
    domainNumber: null,
    domainName: 'General Utilities & Media',
    domainId: DomainId.utilities,
    tags: ['video', 'compress', 'reduce', 'size'],
  );

  static const ToolItem archiveStudio = ToolItem(
    id: 'archive-studio',
    label: 'Archive Studio',
    description: 'Extract, create & convert ZIP, RAR, TAR, GZ archives',
    route: '/tools/archive',
    icon: LucideIcons.archiveRestore,
    color: AppColors.toolPurple,
    softColor: AppColors.toolPurpleSoft,
    category: ToolCategory.archive,
    domainNumber: null,
    domainName: 'General Utilities & Media',
    domainId: DomainId.utilities,
    tags: ['archive', 'zip', 'rar', 'tar', 'extract', 'compress'],
  );

  static const ToolItem videoToFrames = ToolItem(
    id: 'video-to-frames',
    label: 'Video to Frames',
    description: 'Extract every frame, at FPS or interval into JPG/PNG & ZIP',
    route: '/tools/video-to-frames',
    icon: LucideIcons.film,
    color: AppColors.toolIndigo,
    softColor: AppColors.toolIndigoSoft,
    category: ToolCategory.video,
    domainNumber: null,
    domainName: 'General Utilities & Media',
    domainId: DomainId.utilities,
    isNew: true,
    tags: ['video', 'frames', 'extract frames', 'fps', 'interval', 'zip', 'jpg', 'png'],
  );

  static const ToolItem videoEditor = ToolItem(
    id: 'video-editor',
    label: 'Video Editor',
    description: 'Trim, crop, rotate, flip, speed, volume, filters & overlay',
    route: '/tools/video-editor',
    icon: LucideIcons.clapperboard,
    color: AppColors.toolOrange,
    softColor: AppColors.toolOrangeSoft,
    category: ToolCategory.video,
    domainNumber: null,
    domainName: 'General Utilities & Media',
    domainId: DomainId.utilities,
    isNew: true,
    tags: ['video', 'editor', 'video editor', 'trim', 'trim video', 'crop', 'crop video', 'rotate', 'speed', 'filter', 'text'],
  );

  static const ToolItem secureShare = ToolItem(
    id: 'secure-share',
    label: '10-Minute Secure Share',
    description: 'Temporary encrypted server file sharing via QR code',
    route: '/tools/secure-share',
    icon: LucideIcons.qrCode,
    color: AppColors.toolTeal,
    softColor: AppColors.toolTealSoft,
    category: ToolCategory.utilities,
    domainNumber: null,
    domainName: 'General Utilities & Media',
    domainId: DomainId.utilities,
    isNew: true,
    tags: ['temporary share', 'secure share', 'qr share', '10 minute share', 'encrypted', 'password', 'share'],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // LEGACY ID ALIASES
  // ──────────────────────────────────────────────────────────────────────────

  static const Map<String, String> _legacyIdMap = {
    'summarize-pdf': 'ai-summary',
    'ask-pdf': 'ai-doc-chat',
    'ocr-document': 'ai-ocr',
    'classify-pdf': 'classify-document',
    'translate-pdf': 'translate-doc',
    'digital-signature': 'digital-sign',
    'metadata-cleaner': 'metadata-manager',
    'convert-pdf': 'word-to-pdf',
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
    'pdf-to-pdfa-convert': 'pdf-to-pdfa',
  };

  // ──────────────────────────────────────────────────────────────────────────
  // CANONICAL INDEX
  // ──────────────────────────────────────────────────────────────────────────

  static final Map<String, ToolItem> _registry = {
    // Domain 1
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
    headerFooter.id: headerFooter,
    wordToPdf.id: wordToPdf,
    pdfToWord.id: pdfToWord,
    excelToPdf.id: excelToPdf,
    pdfToExcel.id: pdfToExcel,
    pptToPdf.id: pptToPdf,
    pdfToPpt.id: pdfToPpt,
    imageToPdf.id: imageToPdf,
    pdfToImage.id: pdfToImage,
    pdfToPdfa.id: pdfToPdfa,

    // Domain 2
    protectPdf.id: protectPdf,
    smartRedaction.id: smartRedaction,
    digitalSign.id: digitalSign,
    metadataManager.id: metadataManager,

    // Domain 3
    researchAnalyzer.id: researchAnalyzer,
    literatureReview.id: literatureReview,
    researchGap.id: researchGap,
    citationExtractor.id: citationExtractor,
    citationFormatter.id: citationFormatter,
    referenceChecker.id: referenceChecker,
    studyNotes.id: studyNotes,
    quizGenerator.id: quizGenerator,
    flashcards.id: flashcards,
    aiSummary.id: aiSummary,
    aiDocChat.id: aiDocChat,
    semanticCompare.id: semanticCompare,
    similarityMatrix.id: similarityMatrix,
    semanticSearch.id: semanticSearch,
    classifyDocument.id: classifyDocument,
    extractInfo.id: extractInfo,
    writingAssistant.id: writingAssistant,
    qualityChecker.id: qualityChecker,
    parseCv.id: parseCv,

    // Domain 4
    aiOcr.id: aiOcr,
    scanToPdf.id: scanToPdf,
    imageEnhancer.id: imageEnhancer,
    imageConverter.id: imageConverter,
    imageCompressor.id: imageCompressor,
    imageManipulator.id: imageManipulator,
    imageResizer.id: imageResizer,

    // Domain 5
    cognitiveRetention.id: cognitiveRetention,
    spacedRepetition.id: spacedRepetition,
    speedReader.id: speedReader,

    // Domain 6
    voicePodcast.id: voicePodcast,
    audioConverter.id: audioConverter,
    audioTrimmer.id: audioTrimmer,
    voiceTranscriber.id: voiceTranscriber,

    // Domain 7
    accessibilityReader.id: accessibilityReader,
    highContrastReader.id: highContrastReader,
    ttsAccessibility.id: ttsAccessibility,

    // Domain 8
    batesStamping.id: batesStamping,
    legalAudit.id: legalAudit,
    legalRedactionCertifier.id: legalRedactionCertifier,
    clauseComparator.id: clauseComparator,

    // Domain 9
    formFiller.id: formFiller,
    formCreator.id: formCreator,
    formDataExtractor.id: formDataExtractor,

    // Domain 10
    mindMapDiagram.id: mindMapDiagram,
    mindMap.id: mindMap,
    presentationGenerator.id: presentationGenerator,

    // Domain 11
    dualPaneWorkspace.id: dualPaneWorkspace,
    focusPomodoro.id: focusPomodoro,
    gpaCalculator.id: gpaCalculator,

    // Domain 12
    watermarkStudio.id: watermarkStudio,
    batchImageConverter.id: batchImageConverter,
    hashGenerator.id: hashGenerator,
    textBeautifier.id: textBeautifier,
    exifStripper.id: exifStripper,

    // Domain 13
    tabularExtractor.id: tabularExtractor,
    extractTables.id: extractTables,
    parseInvoice.id: parseInvoice,

    // Domain 14
    translateDoc.id: translateDoc,
    translationHub.id: translationHub,
    multilingualGlossary.id: multilingualGlossary,

    // Domain 15
    publishingStudio.id: publishingStudio,
    ebookCoverDesigner.id: ebookCoverDesigner,
    markdownToEpub.id: markdownToEpub,

    // General Utilities
    qrGenerator.id: qrGenerator,
    qrScanner.id: qrScanner,
    barcodeGenerator.id: barcodeGenerator,
    videoConverter.id: videoConverter,
    videoCompressor.id: videoCompressor,
    videoToFrames.id: videoToFrames,
    videoEditor.id: videoEditor,
    secureShare.id: secureShare,
    archiveStudio.id: archiveStudio,
  };

  // ──────────────────────────────────────────────────────────────────────────
  // LOOKUP & DOMAIN QUERY API
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
    final routeBase = route.split('?').first;
    for (final tool in _registry.values) {
      if (tool.route == route || tool.route.split('?').first == routeBase) {
        return tool;
      }
    }
    return null;
  }

  /// Returns all tools primarily owned by the given domain number (1..15).
  static List<ToolItem> getByDomainNumber(int domainNumber) {
    return _registry.values.where((t) => t.domainNumber == domainNumber).toList();
  }

  /// Returns all tools primarily owned by the given [DomainId].
  static List<ToolItem> getByDomainId(DomainId domainId) {
    return _registry.values.where((t) => t.domainId == domainId).toList();
  }

  /// Returns tools belonging to the general utility layer.
  static List<ToolItem> get generalUtilities {
    return _registry.values.where((t) => t.domainNumber == null || t.domainId == DomainId.utilities).toList();
  }

  /// Returns all cross-domain tools accessible from a given domain's workflow.
  static List<ToolItem> getCrossDomainTools(int domainNumber) {
    final domain = DomainRegistry.getByNumber(domainNumber);
    if (domain == null) return [];
    return domain.crossDomainToolIds
        .map((id) => getById(id))
        .whereType<ToolItem>()
        .toList();
  }

  /// Backward-compatible category lookup.
  static List<ToolItem> getByCategory(ToolCategory category) =>
      _registry.values.where((t) => t.category == category).toList();

  /// Searches tools by [query] against name, domain, description, and tags.
  static List<ToolItem> search(String query) {
    if (query.trim().isEmpty) return allTools;
    final q = query.toLowerCase().trim();
    return _registry.values.where((tool) {
      return tool.id.toLowerCase().contains(q) ||
          tool.label.toLowerCase().contains(q) ||
          tool.description.toLowerCase().contains(q) ||
          (tool.domainName != null && tool.domainName!.toLowerCase().contains(q)) ||
          (tool.domainNumber != null && 'domain ${tool.domainNumber}'.contains(q)) ||
          tool.tags.any((tag) => tag.toLowerCase().contains(q));
    }).toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CURATED LISTS
  // ──────────────────────────────────────────────────────────────────────────

  /// All canonical tools (deduplicated).
  static List<ToolItem> get allTools => _registry.values.toList();

  /// Featured tools shown on the home screen.
  static List<ToolItem> get featuredTools => [
        pdfEditor,
        mergePdf,
        splitPdf,
        compressPdf,
        cognitiveRetention,
        legalAudit,
        publishingStudio,
      ];

  static List<ToolItem> get quickTools => featuredTools;

  /// All AI-powered tools.
  static List<ToolItem> get aiTools =>
      _registry.values.where((t) => t.isAi).toList();

  /// Academic & research tools.
  static List<ToolItem> get academicTools => getByDomainNumber(3);

  /// Scanner tools.
  static List<ToolItem> get scannerTools => getByDomainNumber(4);

  /// Forms tools.
  static List<ToolItem> get formTools => getByDomainNumber(9);

  /// Top tools for a given category/domain key (for contextual navigation).
  static List<ToolItem> getTopToolsForCategory(String categoryKey) {
    final resolvedDomain = DomainRegistry.resolve(categoryKey);
    if (resolvedDomain != null) {
      final tools = getByDomainNumber(resolvedDomain.number);
      if (tools.isNotEmpty) return tools.take(4).toList();
    }
    return [pdfEditor, mergePdf, splitPdf, compressPdf];
  }
}
