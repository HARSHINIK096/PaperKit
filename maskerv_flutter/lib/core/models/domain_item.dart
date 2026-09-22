import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

/// The 15 Authoritative Functional Domains of MaskerV
enum DomainId {
  fileManipulation,      // 1. File Manipulation & Document Tools
  securityVault,         // 2. Security, Cryptography & Compliance Vault
  academicIntelligence, // 3. Academic & Research Intelligence Suite
  opticalVisionOcr,      // 4. Optical Scanning & Vision Engine (OCR)
  cognitiveRetention,    // 5. Gamified Cognitive Retention & Active Study Studio
  voicePodcastStudio,    // 6. Multi-Modal Voice & Podcast Audio Studio
  accessibilityReader,   // 7. Universal Accessibility & Inclusive Reading Studio
  legalAuditSuite,       // 8. Legal & Forensic Compliance Audit Suite
  formBuilderEngine,     // 9. Interactive Form Builder & Auto-Fill Engine
  mindMappingStudio,     // 10. Visual Mind Mapping & Diagram Studio
  studentWorkspace,      // 11. Student Productivity & Dual-Pane Workspace Hub
  mediaDevUtilities,     // 12. Media Utilities & Developer Tools Hub
  dataAnalyticsTabular,  // 13. Data Analytics & Tabular Data Extractor
  translationHub,        // 14. Translation & Multi-Lingual Localization Hub
  publishingStudio,      // 15. Automated Publishing & e-Book Studio
  utilities,             // Cross-domain general utilities layer
}

/// Metadata model for each authoritative domain.
class DomainItem {
  final int number;
  final DomainId id;
  final String slug;
  final String name;
  final String shortName;
  final String description;
  final IconData icon;
  final Color color;
  final Color softColor;
  final String route;
  final List<String> primaryToolIds;
  final List<String> crossDomainToolIds;

  const DomainItem({
    required this.number,
    required this.id,
    required this.slug,
    required this.name,
    required this.shortName,
    required this.description,
    required this.icon,
    required this.color,
    required this.softColor,
    required this.route,
    required this.primaryToolIds,
    this.crossDomainToolIds = const [],
  });
}

/// Canonical registry of the 15 Authoritative Functional Domains.
class DomainRegistry {
  DomainRegistry._();

  static const List<DomainItem> domains = [
    // ── Domain 1 ──
    DomainItem(
      number: 1,
      id: DomainId.fileManipulation,
      slug: 'file-manipulation',
      name: 'File Manipulation & Document Tools',
      shortName: 'File Tools',
      description: 'Document structure, multi-format conversion, organization, page management, and ISO archival preparation.',
      icon: LucideIcons.files,
      color: AppColors.toolBlue,
      softColor: AppColors.toolBlueSoft,
      route: '/domain/1',
      primaryToolIds: [
        'pdf-editor',
        'merge-pdf',
        'split-pdf',
        'compress-pdf',
        'extract-pages',
        'rotate-pdf',
        'watermark',
        'organize-pages',
        'pdf-nup',
        'pdf-booklet',
        'header-footer',
        'word-to-pdf',
        'pdf-to-word',
        'excel-to-pdf',
        'pdf-to-excel',
        'ppt-to-pdf',
        'pdf-to-ppt',
        'image-to-pdf',
        'pdf-to-image',
        'pdf-to-pdfa',
      ],
    ),

    // ── Domain 2 ──
    DomainItem(
      number: 2,
      id: DomainId.securityVault,
      slug: 'security-vault',
      name: 'Security, Cryptography & Compliance Vault',
      shortName: 'Security Vault',
      description: 'Document security, 256-bit AES encryption, smart PII redaction, cryptographic signatures, and metadata sanitization.',
      icon: LucideIcons.shieldCheck,
      color: AppColors.toolRed,
      softColor: AppColors.toolRedSoft,
      route: '/domain/2',
      primaryToolIds: [
        'protect-pdf',
        'smart-redaction',
        'digital-sign',
        'metadata-manager',
      ],
    ),

    // ── Domain 3 ──
    DomainItem(
      number: 3,
      id: DomainId.academicIntelligence,
      slug: 'academic-intelligence',
      name: 'Academic & Research Intelligence Suite',
      shortName: 'Academic Suite',
      description: 'Academic reasoning, literature reviews, research gap detection, citation extraction/formatting, and document intelligence.',
      icon: LucideIcons.graduationCap,
      color: AppColors.toolPurple,
      softColor: AppColors.toolPurpleSoft,
      route: '/domain/3',
      primaryToolIds: [
        'research-analyzer',
        'literature-review',
        'research-gap',
        'citation-extractor',
        'citation-formatter',
        'reference-checker',
        'study-notes',
        'quiz-generator',
        'flashcards',
        'ai-summary',
        'ai-doc-chat',
        'semantic-compare',
        'similarity-matrix',
        'semantic-search',
        'classify-document',
        'extract-info',
        'writing-assistant',
        'quality-checker',
        'parse-cv',
      ],
      crossDomainToolIds: [
        'mind-map',
        'presentation-generator',
        'cognitive-retention',
        'workspace-dualpane',
      ],
    ),

    // ── Domain 4 ──
    DomainItem(
      number: 4,
      id: DomainId.opticalVisionOcr,
      slug: 'optical-vision-ocr',
      name: 'Optical Scanning & Vision Engine (OCR)',
      shortName: 'Scanning & Vision',
      description: 'Physical document acquisition, edge detection, perspective correction, OCR text recognition, and image enhancement.',
      icon: LucideIcons.scanLine,
      color: AppColors.toolTeal,
      softColor: AppColors.toolTealSoft,
      route: '/domain/4',
      primaryToolIds: [
        'ai-ocr',
        'scan-to-pdf',
        'image-enhancer',
        'image-converter',
        'image-compressor',
        'image-manipulator',
        'image-resizer',
      ],
    ),

    // ── Domain 5 ──
    DomainItem(
      number: 5,
      id: DomainId.cognitiveRetention,
      slug: 'cognitive-retention',
      name: 'Gamified Cognitive Retention & Active Study Studio',
      shortName: 'Cognitive Studio',
      description: 'Active recall blur-to-reveal reading, SM-2 / Leitner spaced repetition scheduling, and reading velocity tracking.',
      icon: LucideIcons.brain,
      color: AppColors.toolOrange,
      softColor: AppColors.toolOrangeSoft,
      route: '/domain/5',
      primaryToolIds: [
        'cognitive-retention',
        'spaced-repetition',
        'speed-reader',
      ],
      crossDomainToolIds: [
        'flashcards',
        'study-notes',
      ],
    ),

    // ── Domain 6 ──
    DomainItem(
      number: 6,
      id: DomainId.voicePodcastStudio,
      slug: 'voice-podcast',
      name: 'Multi-Modal Voice & Podcast Audio Studio',
      shortName: 'Voice & Podcast',
      description: 'Conversational dialogue podcast script generation, dual-speaker TTS audio playback, and audio format processing.',
      icon: LucideIcons.mic,
      color: AppColors.toolIndigo,
      softColor: AppColors.toolIndigoSoft,
      route: '/domain/6',
      primaryToolIds: [
        'voice-podcast',
        'audio-converter',
        'audio-trimmer',
        'voice-transcriber',
      ],
    ),

    // ── Domain 7 ──
    DomainItem(
      number: 7,
      id: DomainId.accessibilityReader,
      slug: 'accessibility-reader',
      name: 'Universal Accessibility & Inclusive Reading Studio',
      shortName: 'Accessibility',
      description: 'Bionic Reading typography, OpenDyslexic typeface, high-contrast visual themes, and line focus assistance.',
      icon: LucideIcons.eye,
      color: AppColors.toolTeal,
      softColor: AppColors.toolTealSoft,
      route: '/domain/7',
      primaryToolIds: [
        'accessibility-reader',
        'high-contrast-reader',
        'tts-accessibility',
      ],
    ),

    // ── Domain 8 ──
    DomainItem(
      number: 8,
      id: DomainId.legalAuditSuite,
      slug: 'legal-audit',
      name: 'Legal & Forensic Compliance Audit Suite',
      shortName: 'Legal & Forensic',
      description: 'Sequential Bates document stamping, SHA-256 chain-of-custody ledgers, clause risk matrix, and forensic audit logs.',
      icon: LucideIcons.scale,
      color: AppColors.toolRed,
      softColor: AppColors.toolRedSoft,
      route: '/domain/8',
      primaryToolIds: [
        'bates-stamping',
        'legal-audit',
        'legal-redaction-certifier',
        'clause-comparator',
      ],
      crossDomainToolIds: [
        'smart-redaction',
        'digital-sign',
      ],
    ),

    // ── Domain 9 ──
    DomainItem(
      number: 9,
      id: DomainId.formBuilderEngine,
      slug: 'form-builder',
      name: 'Interactive Form Builder & Auto-Fill Engine',
      shortName: 'Form Studio',
      description: 'Interactive PDF form field detection, profile-based auto-fill, and visual form field authoring/flattening.',
      icon: LucideIcons.formInput,
      color: AppColors.toolBlue,
      softColor: AppColors.toolBlueSoft,
      route: '/domain/9',
      primaryToolIds: [
        'form-filler',
        'form-creator',
        'form-data-extractor',
      ],
    ),

    // ── Domain 10 ──
    DomainItem(
      number: 10,
      id: DomainId.mindMappingStudio,
      slug: 'mind-mapping',
      name: 'Visual Mind Mapping & Diagram Studio',
      shortName: 'Diagram Studio',
      description: 'Interactive node-graph visual canvas, document structure-to-mindmap conversion, and presentation slide deck generation.',
      icon: LucideIcons.gitFork,
      color: AppColors.toolPurple,
      softColor: AppColors.toolPurpleSoft,
      route: '/domain/10',
      primaryToolIds: [
        'diagram-mindmap',
        'mind-map',
        'presentation-generator',
      ],
      crossDomainToolIds: [
        'research-analyzer',
      ],
    ),

    // ── Domain 11 ──
    DomainItem(
      number: 11,
      id: DomainId.studentWorkspace,
      slug: 'student-workspace',
      name: 'Student Productivity & Dual-Pane Workspace Hub',
      shortName: 'Workspace Hub',
      description: 'Side-by-side dual-pane document reader, synchronized note-taking, markdown scratchpad, and course syllabus tracker.',
      icon: LucideIcons.layoutGrid,
      color: AppColors.toolIndigo,
      softColor: AppColors.toolIndigoSoft,
      route: '/domain/11',
      primaryToolIds: [
        'workspace-dualpane',
        'focus-pomodoro',
        'gpa-calculator',
      ],
      crossDomainToolIds: [
        'study-notes',
        'ai-doc-chat',
      ],
    ),

    // ── Domain 12 ──
    DomainItem(
      number: 12,
      id: DomainId.mediaDevUtilities,
      slug: 'media-dev-utilities',
      name: 'Media Utilities & Developer Tools Hub',
      shortName: 'Media & Dev Tools',
      description: 'Watermarking studio, batch image conversion, cryptographic checksum generation, code formatting, and EXIF metadata stripping.',
      icon: LucideIcons.wrench,
      color: AppColors.toolTeal,
      softColor: AppColors.toolTealSoft,
      route: '/domain/12',
      primaryToolIds: [
        'watermark-studio',
        'batch-image-converter',
        'hash-generator',
        'text-beautifier',
        'exif-stripper',
      ],
    ),

    // ── Domain 13 ──
    DomainItem(
      number: 13,
      id: DomainId.dataAnalyticsTabular,
      slug: 'data-analytics',
      name: 'Data Analytics & Tabular Data Extractor',
      shortName: 'Data Analytics',
      description: 'Automated table boundary detection, tabular data extraction to CSV/Excel, and structured financial invoice analysis.',
      icon: LucideIcons.table,
      color: AppColors.toolBlue,
      softColor: AppColors.toolBlueSoft,
      route: '/domain/13',
      primaryToolIds: [
        'analytics-tables',
        'extract-tables',
        'parse-invoice',
      ],
      crossDomainToolIds: [
        'pdf-to-excel',
      ],
    ),

    // ── Domain 14 ──
    DomainItem(
      number: 14,
      id: DomainId.translationHub,
      slug: 'translation-hub',
      name: 'Translation & Multi-Lingual Localization Hub',
      shortName: 'Translation Hub',
      description: 'Layout-preserving document translation and side-by-side paragraph multilingual localization in 15+ languages.',
      icon: LucideIcons.languages,
      color: AppColors.toolPink,
      softColor: AppColors.toolPinkSoft,
      route: '/domain/14',
      primaryToolIds: [
        'translate-doc',
        'translation-hub',
        'multilingual-glossary',
      ],
    ),

    // ── Domain 15 ──
    DomainItem(
      number: 15,
      id: DomainId.publishingStudio,
      slug: 'publishing-studio',
      name: 'Automated Publishing & e-Book Studio',
      shortName: 'Publishing Studio',
      description: 'CMYK prepress validation, print preflight audit checklist, and automated reflowable ePub eBook generation.',
      icon: LucideIcons.bookOpenCheck,
      color: AppColors.toolPurple,
      softColor: AppColors.toolPurpleSoft,
      route: '/domain/15',
      primaryToolIds: [
        'publishing-studio',
        'ebook-cover-designer',
        'markdown-to-epub',
      ],
      crossDomainToolIds: [
        'pdf-to-pdfa',
      ],
    ),
  ];

  /// Cross-domain general utilities layer (NOT a 16th functional domain).
  static const List<String> generalUtilityToolIds = [
    'qr-generator',
    'barcode-generator',
    'video-converter',
    'video-compressor',
    'archive-studio',
  ];

  /// Resolves a domain by its 1-indexed number (1..15).
  static DomainItem? getByNumber(int number) {
    if (number < 1 || number > domains.length) return null;
    return domains[number - 1];
  }

  /// Resolves a domain by its unique slug, number string, or category key alias.
  static DomainItem? resolve(String key) {
    final clean = key.toLowerCase().trim();

    // Direct number check (e.g. "1", "8", "15")
    final numVal = int.tryParse(clean);
    if (numVal != null && numVal >= 1 && numVal <= domains.length) {
      return domains[numVal - 1];
    }

    // Direct slug match (e.g. "domain-1", "file-manipulation", "legal-audit")
    for (final d in domains) {
      if (d.slug == clean || 'domain-${d.number}' == clean) {
        return d;
      }
    }

    // Alias mapping for backward-compatible category routes
    switch (clean) {
      case 'pdf':
      case 'convert':
      case 'conversions':
      case 'conversion':
        return getByNumber(1);
      case 'security':
      case 'privacy':
      case 'vault':
        return getByNumber(2);
      case 'academic':
      case 'research':
      case 'ai':
      case 'intelligence':
        return getByNumber(3);
      case 'scanner':
      case 'scan':
      case 'vision':
      case 'ocr':
      case 'image':
      case 'images':
      case 'image-compressor':
        return getByNumber(4);
      case 'cognitive':
      case 'retention':
      case 'study':
        return getByNumber(5);
      case 'voice':
      case 'podcast':
      case 'audio':
        return getByNumber(6);
      case 'accessibility':
      case 'reader':
      case 'bionic':
        return getByNumber(7);
      case 'legal':
      case 'forensic':
      case 'audit':
      case 'bates':
        return getByNumber(8);
      case 'forms':
      case 'form':
      case 'filler':
        return getByNumber(9);
      case 'diagram':
      case 'mindmap':
        return getByNumber(10);
      case 'workspace':
      case 'dualpane':
        return getByNumber(11);
      case 'p2p':
      case 'airshare':
      case 'mesh':
        return getByNumber(12);
      case 'analytics':
      case 'tables':
      case 'tabular':
        return getByNumber(13);
      case 'translation':
      case 'translate':
        return getByNumber(14);
      case 'publishing':
      case 'epub':
        return getByNumber(15);
      default:
        return null;
    }
  }
}
