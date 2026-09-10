import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';
import 'pdf_engine.dart';
import 'storage_service.dart';

class ApiService {
  static const String defaultBaseUrl = ApiConfig.defaultBackendUrl;
  static const String localBaseUrl = ApiConfig.localBackendUrl;
  late final Dio dio;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.defaultBackendUrl,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 120),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 1. Attach anonymous user identity header for user data segregation
          try {
            final anonUserId = await StorageService().getAnonymousUserId();
            if (anonUserId.isNotEmpty) {
              options.headers['X-User-ID'] = anonUserId;
            }
          } catch (_) {}

          // 2. Attach registered auth token if available
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('paperkit_auth_token') ?? prefs.getString('pk_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers['Authorization'] = 'Bearer guest_access_token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  void setBaseUrl(String url) {
    dio.options.baseUrl = url;
  }

  Future<bool> checkHealth() async {
    try {
      final response = await dio.get('/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Generic File Upload
  Future<Response> uploadAndProcess({
    required String endpoint,
    required List<File> files,
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
  }) async {
    final formDataMap = <String, dynamic>{};

    if (files.length == 1) {
      final f = files.first;
      final filename = f.uri.pathSegments.last;
      formDataMap['file'] = await MultipartFile.fromFile(
        f.path,
        filename: filename,
      );
    } else {
      final fileList = <MultipartFile>[];
      for (final f in files) {
        fileList.add(
          await MultipartFile.fromFile(
            f.path,
            filename: f.uri.pathSegments.last,
          ),
        );
      }
      formDataMap['files'] = fileList;
    }

    if (data != null) {
      formDataMap.addAll(data);
    }

    final formData = FormData.fromMap(formDataMap);

    return await dio.post(
      endpoint,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: onSendProgress,
    );
  }

  // Helper to extract text from a file if not provided
  Future<String> _resolveText({String? text, File? file}) async {
    if (text != null && text.trim().isNotEmpty) {
      return text;
    }
    if (file != null) {
      final ext = file.path.split('.').last.toLowerCase();
      if (ext == 'pdf') {
        try {
          final extracted = await PdfEngine.extractText(file);
          if (extracted.trim().isNotEmpty) return extracted;
        } catch (_) {}
      } else if (ext == 'txt' || ext == 'md' || ext == 'json' || ext == 'csv') {
        try {
          return await file.readAsString();
        } catch (_) {}
      }
    }
    return '';
  }

  // ==========================================
  // 17 AI METHODS BACKED BY REACT / FASTAPI
  // ==========================================

  // 1. AI OCR (Groq Vision / Gemini Vision)
  Future<Map<String, dynamic>> ocrDocument({File? file, String? fileId}) async {
    if (file != null) {
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : (ext == 'pdf' ? 'application/pdf' : 'image/jpeg'));
      
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: file.uri.pathSegments.last, contentType: MediaType.parse(mimeType)),
      });

      try {
        final res = await dio.post('/ai/ocr', data: {'file_id': fileId});
        return res.data;
      } catch (_) {
        final res = await dio.post('/ai/ocr', data: formData, options: Options(contentType: 'multipart/form-data'));
        return res.data is Map<String, dynamic> ? res.data : {'text': res.data.toString(), 'ocr': res.data.toString()};
      }
    }
    final res = await dio.post('/ai/ocr', data: {'file_id': fileId});
    return res.data;
  }

  // 2. AI Document Summarizer
  Future<Map<String, dynamic>> summarizePDF({
    String? text,
    File? file,
    String? fileId,
    String mode = 'detailed',
    String language = 'English',
  }) async {
    final resolvedText = await _resolveText(text: text, file: file);
    final res = await dio.post('/ai/summarize', data: {
      'text': resolvedText,
      'file_id': fileId,
      'mode': mode,
      'language': language,
    });
    return res.data;
  }

  // 3. AI Document Chat (Ask Document with RAG)
  Future<Map<String, dynamic>> askPDF({
    required String question,
    String? text,
    File? file,
    String? fileId,
  }) async {
    final resolvedText = await _resolveText(text: text, file: file);
    final res = await dio.post('/ai/ask', data: {
      'question': question,
      'text': resolvedText,
      'file_id': fileId,
    });
    return res.data;
  }

  // 4. Semantic Compare (Two Documents)
  Future<Map<String, dynamic>> compareDocuments({
    String? textA,
    String? textB,
    File? fileA,
    File? fileB,
    String? fileIdA,
    String? fileIdB,
  }) async {
    final resolvedA = await _resolveText(text: textA, file: fileA);
    final resolvedB = await _resolveText(text: textB, file: fileB);

    final res = await dio.post('/ai/compare', data: {
      'text_a': resolvedA,
      'text_b': resolvedB,
      'file_id_a': fileIdA,
      'file_id_b': fileIdB,
    });
    return res.data;
  }

  // 5. Similarity Matrix (Multi-Doc Comparison)
  Future<Map<String, dynamic>> similarityMatrix({
    List<Map<String, String>>? documents,
    List<String>? fileIds,
  }) async {
    final res = await dio.post('/ai/similarity-matrix', data: {
      'documents': documents ?? [],
      'file_ids': fileIds ?? [],
    });
    return res.data;
  }

  // 6. Semantic Search (Intent-based Document Search)
  Future<Map<String, dynamic>> semanticSearch({
    required String query,
    String? text,
    File? file,
    String? fileId,
  }) async {
    final resolvedText = await _resolveText(text: text, file: file);
    final res = await dio.post('/ai/search', data: {
      'query': query,
      'text': resolvedText,
      'file_id': fileId,
    });
    return res.data;
  }

  // 7. Document Classification & Tagger
  Future<Map<String, dynamic>> classifyDocument({
    String? text,
    File? file,
    String? fileId,
  }) async {
    final resolvedText = await _resolveText(text: text, file: file);
    final res = await dio.post('/ai/classify', data: {
      'text': resolvedText,
      'file_id': fileId,
    });
    return res.data;
  }

  // 8. Information & Key-Value Extraction
  Future<Map<String, dynamic>> extractInformation({
    String? text,
    File? file,
    String? fileId,
    String schemaType = 'auto',
  }) async {
    final resolvedText = await _resolveText(text: text, file: file);
    final res = await dio.post('/ai/extract-info', data: {
      'text': resolvedText,
      'file_id': fileId,
      'schema_type': schemaType,
    });
    return res.data;
  }

  // 9. AI Writing Assistant
  Future<Map<String, dynamic>> writingAssistant({
    required String text,
    String task = 'grammar_spelling',
    String? customInstruction,
    String? fileId,
  }) async {
    final res = await dio.post('/ai/writing-assist', data: {
      'text': text,
      'task': task,
      'custom_instruction': customInstruction,
      'file_id': fileId,
    });
    return res.data;
  }

  // 10. Smart PII Privacy & Redaction Detector
  Future<Map<String, dynamic>> detectPrivacy({
    String? text,
    File? file,
    String? fileId,
  }) async {
    final resolvedText = await _resolveText(text: text, file: file);
    final res = await dio.post('/ai/detect-privacy', data: {
      'text': resolvedText,
      'file_id': fileId,
    });
    return res.data;
  }

  // 11. Document Quality Auditor & Integrity Checker
  Future<Map<String, dynamic>> qualityCheckDocument({
    String? text,
    File? file,
    String? fileId,
  }) async {
    final resolvedText = await _resolveText(text: text, file: file);
    final res = await dio.post('/ai/quality-check', data: {
      'text': resolvedText,
      'file_id': fileId,
    });
    return res.data;
  }

  // 12. Multilingual Document Translation
  Future<Map<String, dynamic>> translatePDF({
    required String targetLanguage,
    String? text,
    File? file,
    String? fileId,
  }) async {
    final resolvedText = await _resolveText(text: text, file: file);
    final res = await dio.post('/ai/translate', data: {
      'target_language': targetLanguage,
      'text': resolvedText,
      'file_id': fileId,
    });
    return res.data;
  }

  // 13. AI Table Extractor
  Future<Map<String, dynamic>> extractTables({
    String? text,
    File? file,
    String? fileId,
  }) async {
    final resolvedText = await _resolveText(text: text, file: file);
    final res = await dio.post('/ai/extract-tables', data: {
      'text': resolvedText,
      'file_id': fileId,
    });
    return res.data;
  }

  // 14. AI PDF to Markdown Converter
  Future<Map<String, dynamic>> pdfToMarkdown({
    String? text,
    File? file,
    String? fileId,
  }) async {
    final resolvedText = await _resolveText(text: text, file: file);
    final res = await dio.post('/ai/pdf-to-markdown', data: {
      'text': resolvedText,
      'file_id': fileId,
    });
    return res.data;
  }

  // 15. AI Report PDF Generator
  Future<Map<String, dynamic>> generateReportPdf({
    required String title,
    required String content,
    String subtitle = 'AI Analysis & Insights',
  }) async {
    final res = await dio.post('/ai/generate-report-pdf', data: {
      'title': title,
      'content': content,
      'subtitle': subtitle,
    });
    return res.data;
  }

  // 16. AI Searchable PDF Generator
  Future<Map<String, dynamic>> createSearchablePdf({
    String? text,
    File? file,
    String? fileId,
  }) async {
    final resolvedText = await _resolveText(text: text, file: file);
    final res = await dio.post('/ai/searchable-pdf', data: {
      'text': resolvedText,
      'file_id': fileId,
    });
    return res.data;
  }

  // 17. AI Image Enhancer (HuggingFace Inference API)
  Future<List<int>> enhanceImageHuggingFace({
    required File imageFile,
    String? hfToken,
  }) async {
    const hfUrl = 'https://api-inference.huggingface.co/models/caidas/swin2SR-classical-sr-x2-64';
    final bytes = await imageFile.readAsBytes();
    final ext = imageFile.path.split('.').last.toLowerCase();
    final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
    final token = hfToken ?? await ApiConfig.getHfApiKey();

    final hfDio = Dio();
    final response = await hfDio.post(
      hfUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': contentType,
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        responseType: ResponseType.bytes,
      ),
    );
    return response.data;
  }

  // Legacy compatibility method
  Future<Map<String, dynamic>> processAiTask({
    required String endpoint,
    required File file,
    Map<String, dynamic>? extraParams,
    ProgressCallback? onProgress,
  }) async {
    final resolvedText = await _resolveText(file: file);
    final data = <String, dynamic>{'text': resolvedText};
    if (extraParams != null) data.addAll(extraParams);

    final cleanEndpoint = endpoint.startsWith('/api') ? endpoint.substring(4) : endpoint;
    final res = await dio.post(cleanEndpoint, data: data);
    if (res.data is Map<String, dynamic>) {
      return res.data;
    }
    return {'result': res.data};
  }

  // Media Downloader
  Future<Map<String, dynamic>> downloadMedia({
    required String url,
    required String type,
  }) async {
    final response = await dio.post(
      '/api/media/download',
      data: {
        'url': url,
        'type': type,
      },
    );
    return response.data;
  }
}

