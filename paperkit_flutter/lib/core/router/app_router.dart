import 'package:go_router/go_router.dart';

import '../../features/welcome/splash_screen.dart';
import '../../features/welcome/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/tools/all_tools_screen.dart';
import '../../features/tools/category_hub_screen.dart';
import '../../features/scanner/scanner_screen.dart';
import '../../features/files/files_screen.dart';
import '../../features/files/storage_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/help_screen.dart';
import '../../features/profile/about_screen.dart';

// PDF Tools
import '../../features/pdf_tools/merge_pdf_screen.dart';
import '../../features/pdf_tools/split_pdf_screen.dart';
import '../../features/pdf_tools/compress_pdf_screen.dart';
import '../../features/pdf_tools/convert_document_screen.dart';
import '../../features/pdf_tools/rotate_pdf_screen.dart';
import '../../features/pdf_tools/watermark_pdf_screen.dart';
import '../../features/pdf_tools/organize_pages_screen.dart';
import '../../features/pdf_tools/extract_pages_screen.dart';
import '../../features/pdf_tools/pdf_to_pdfa_screen.dart';
import '../../features/pdf_tools/pdf_editor_screen.dart';

// Security Tools
import '../../features/security_tools/protect_pdf_screen.dart';
import '../../features/security_tools/smart_redaction_screen.dart';
import '../../features/security_tools/digital_signature_screen.dart';
import '../../features/security_tools/metadata_screen.dart';

// Image & Media Tools
import '../../features/image_media_tools/image_converter_screen.dart';
import '../../features/image_media_tools/image_compressor_screen.dart';
import '../../features/image_media_tools/image_manipulator_screen.dart';
import '../../features/image_media_tools/media_downloader_screen.dart';
import '../../features/image_media_tools/audio_converter_screen.dart';
import '../../features/image_media_tools/video_converter_screen.dart';
import '../../features/image_media_tools/video_compressor_screen.dart';
import '../../features/image_media_tools/archive_studio_screen.dart';

// AI Tools
import '../../features/ai_tools/ai_tools_hub_screen.dart';
import '../../features/ai_tools/ocr_screen.dart';
import '../../features/ai_tools/summarize_pdf_screen.dart';
import '../../features/ai_tools/ask_pdf_screen.dart';
import '../../features/ai_tools/semantic_compare_screen.dart';
import '../../features/ai_tools/similarity_matrix_screen.dart';
import '../../features/ai_tools/semantic_search_screen.dart';
import '../../features/ai_tools/classify_pdf_screen.dart';
import '../../features/ai_tools/extract_info_screen.dart';
import '../../features/ai_tools/translate_pdf_screen.dart';
import '../../features/ai_tools/writing_assistant_screen.dart';
import '../../features/ai_tools/quality_checker_screen.dart';
import '../../features/ai_tools/extract_tables_screen.dart';
import '../../features/ai_tools/image_enhancer_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/tools',
        builder: (context, state) => const AllToolsScreen(),
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/files',
        builder: (context, state) => const FilesScreen(),
      ),
      GoRoute(
        path: '/storage',
        builder: (context, state) => const StorageScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/category/:categoryId',
        builder: (context, state) => CategoryHubScreen(
          categoryId: state.pathParameters['categoryId'] ?? 'pdf',
        ),
      ),
      GoRoute(
        path: '/tools/category/:categoryId',
        builder: (context, state) => CategoryHubScreen(
          categoryId: state.pathParameters['categoryId'] ?? 'pdf',
        ),
      ),

      // PDF Tools
      GoRoute(path: '/tools/merge', builder: (context, state) => const MergePDFScreen()),
      GoRoute(path: '/tools/split', builder: (context, state) => const SplitPDFScreen()),
      GoRoute(path: '/tools/compress', builder: (context, state) => const CompressPDFScreen()),
      GoRoute(
        path: '/tools/convert',
        builder: (context, state) => ConvertDocumentScreen(
          initialFrom: state.uri.queryParameters['from'],
          initialTo: state.uri.queryParameters['to'],
        ),
      ),
      GoRoute(path: '/tools/rotate', builder: (context, state) => const RotatePDFScreen()),
      GoRoute(path: '/tools/watermark', builder: (context, state) => const WatermarkPDFScreen()),
      GoRoute(path: '/tools/organize-pages', builder: (context, state) => const OrganizePagesScreen()),
      GoRoute(path: '/tools/remove-pages', builder: (context, state) => const OrganizePagesScreen()),
      GoRoute(path: '/tools/reorder-pages', builder: (context, state) => const OrganizePagesScreen()),
      GoRoute(path: '/tools/duplicate-pages', builder: (context, state) => const OrganizePagesScreen()),
      GoRoute(path: '/tools/extract-pages', builder: (context, state) => const ExtractPagesScreen()),
      GoRoute(path: '/tools/pdf-to-pdfa', builder: (context, state) => const PDFToPDFAScreen()),
      GoRoute(path: '/tools/pdf-editor', builder: (context, state) => const PDFEditorScreen()),

      // Security Tools
      GoRoute(path: '/security/protect', builder: (context, state) => const ProtectPDFScreen()),
      GoRoute(path: '/tools/protect', builder: (context, state) => const ProtectPDFScreen()),
      GoRoute(path: '/security/redact', builder: (context, state) => const SmartRedactionScreen()),
      GoRoute(path: '/tools/redact', builder: (context, state) => const SmartRedactionScreen()),
      GoRoute(path: '/security/sign', builder: (context, state) => const DigitalSignatureScreen()),
      GoRoute(path: '/tools/sign', builder: (context, state) => const DigitalSignatureScreen()),
      GoRoute(path: '/security/metadata', builder: (context, state) => const MetadataScreen()),
      GoRoute(path: '/tools/metadata', builder: (context, state) => const MetadataScreen()),

      // Image & Media Tools
      GoRoute(
        path: '/tools/image-converter',
        builder: (context, state) => ImageConverterScreen(
          initialTo: state.uri.queryParameters['to'],
        ),
      ),
      GoRoute(
        path: '/tools/image-compressor',
        builder: (context, state) => ImageCompressorScreen(
          initialPreset: state.uri.queryParameters['preset'],
        ),
      ),
      GoRoute(path: '/tools/image-manipulator', builder: (context, state) => const ImageManipulatorScreen()),
      GoRoute(
        path: '/tools/media-downloader',
        builder: (context, state) => MediaDownloaderScreen(
          initialType: state.uri.queryParameters['type'],
        ),
      ),
      GoRoute(
        path: '/tools/audio-converter',
        builder: (context, state) => AudioConverterScreen(
          initialTo: state.uri.queryParameters['to'],
        ),
      ),
      GoRoute(
        path: '/tools/video-converter',
        builder: (context, state) => VideoConverterScreen(
          initialTo: state.uri.queryParameters['to'],
        ),
      ),
      GoRoute(
        path: '/tools/video-compressor',
        builder: (context, state) => VideoCompressorScreen(
          initialPreset: state.uri.queryParameters['preset'],
        ),
      ),
      GoRoute(
        path: '/tools/archive',
        builder: (context, state) => ArchiveStudioScreen(
          initialMode: state.uri.queryParameters['mode'],
        ),
      ),

      // AI Tools
      GoRoute(path: '/ai', builder: (context, state) => const AIToolsHubScreen()),
      GoRoute(path: '/ai/ocr', builder: (context, state) => const OCRScreen()),
      GoRoute(path: '/tools/ocr', builder: (context, state) => const OCRScreen()),
      GoRoute(path: '/ai/summarize', builder: (context, state) => const SummarizePDFScreen()),
      GoRoute(path: '/ai/ask', builder: (context, state) => const AskPDFScreen()),
      GoRoute(path: '/ai/compare', builder: (context, state) => const SemanticCompareScreen()),
      GoRoute(path: '/ai/similarity', builder: (context, state) => const SimilarityMatrixScreen()),
      GoRoute(path: '/ai/search', builder: (context, state) => const SemanticSearchScreen()),
      GoRoute(path: '/ai/classify', builder: (context, state) => const ClassifyPDFScreen()),
      GoRoute(path: '/ai/extract-info', builder: (context, state) => const ExtractInfoScreen()),
      GoRoute(path: '/ai/translate', builder: (context, state) => const TranslatePDFScreen()),
      GoRoute(path: '/ai/writing-assist', builder: (context, state) => const WritingAssistantScreen()),
      GoRoute(path: '/ai/quality-checker', builder: (context, state) => const QualityCheckerScreen()),
      GoRoute(path: '/ai/extract-tables', builder: (context, state) => const ExtractTablesScreen()),
      GoRoute(path: '/ai/image-enhancer', builder: (context, state) => const ImageEnhancerScreen()),
    ],
  );
}
