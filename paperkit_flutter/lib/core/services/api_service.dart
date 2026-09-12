import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_config.dart';
import 'pdf_engine.dart';
import 'storage_service.dart';

class ApiService {
  static const String defaultBaseUrl = ApiConfig.defaultBackendUrl;
  static const String productionBaseUrl = ApiConfig.defaultBackendUrl;
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
          final token =
              prefs.getString('paperkit_auth_token') ??
              prefs.getString('pk_token');
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

  String get baseUrl => dio.options.baseUrl;

  void setBaseUrl(String url) {
    dio.options.baseUrl = url;
  }

  Future<bool> checkHealth({int timeoutMs = 7000}) async {
    final candidateUrls = <String>{
      dio.options.baseUrl.replaceAll(RegExp(r'/+$'), ''),
      defaultBaseUrl.replaceAll(RegExp(r'/+$'), ''),
      ApiConfig.defaultBackendUrl.replaceAll(RegExp(r'/+$'), ''),
    }.where((url) => url.isNotEmpty).toList();

    for (final base in candidateUrls) {
      for (final endpoint in ['/health', '/']) {
        try {
          final probeDio = Dio(
            BaseOptions(
              baseUrl: base,
              connectTimeout: Duration(milliseconds: timeoutMs),
              receiveTimeout: Duration(milliseconds: timeoutMs),
              headers: {'Accept': 'application/json'},
              followRedirects: true,
              maxRedirects: 5,
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 400,
            ),
          );
          final response = await probeDio.get(endpoint);
          if (response.statusCode != null &&
              response.statusCode! >= 200 &&
              response.statusCode! < 400) {
            dio.options.baseUrl = base;
            return true;
          }
        } catch (_) {
          // Continue probing next candidate
        }
      }
    }
    return false;
  }

  // Generic File Upload to /files/upload
  Future<Map<String, dynamic>> uploadFile(
    File file, {
    ProgressCallback? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    final filename = file.uri.pathSegments.last;
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });

    final res = await dio.post(
      '/files/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: onProgress,
    );
    if (res.data is Map<String, dynamic>) {
      return res.data;
    }
    return {'_id': res.data.toString(), 'filename': filename};
  }

  // Convert Document Bi-directional
  Future<File> convertDocument({
    required File file,
    required String fromFormat,
    required String toFormat,
    Map<String, dynamic>? options,
    ProgressCallback? onProgress,
  }) async {
    // 1. Upload file to get file_id
    String? fileId;
    try {
      final uploadRes = await uploadFile(
        file,
        onProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress((sent / total * 40).round(), 100);
          }
        },
      );
      fileId = uploadRes['_id']?.toString() ?? uploadRes['id']?.toString();
    } catch (_) {
      // Fallback: direct multipart convert
    }

    Response res;
    if (fileId != null && fileId.isNotEmpty) {
      final payload = <String, dynamic>{
        'file_id': fileId,
        'from_format': fromFormat,
        'to_format': toFormat,
        if (options != null) ...options,
      };
      res = await dio.post('/tools/convert', data: payload);
    } else {
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.uri.pathSegments.last,
        ),
        'from_format': fromFormat,
        'to_format': toFormat,
        if (options != null) ...options,
      });
      res = await dio.post(
        '/tools/convert',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    }

    final outputDir = await getApplicationDocumentsDirectory();
    const extMap = {
      'word': 'docx',
      'excel': 'xlsx',
      'ppt': 'pptx',
      'image': 'jpg',
      'pdf': 'pdf',
      'txt': 'txt',
      'html': 'html',
      'markdown': 'md',
    };
    final outExt = extMap[toFormat.toLowerCase()] ?? toFormat.toLowerCase();
    final stem = file.uri.pathSegments.last.contains('.')
        ? file.uri.pathSegments.last.substring(
            0,
            file.uri.pathSegments.last.lastIndexOf('.'),
          )
        : 'Document';
    final outFilename = '${stem}_converted.$outExt';
    final outputFile = File('${outputDir.path}/$outFilename');

    if (res.data is List<int>) {
      await outputFile.writeAsBytes(res.data);
      return outputFile;
    } else if (res.data is Map && res.data['download_url'] != null) {
      String downloadUrl = res.data['download_url'].toString();
      if (!downloadUrl.startsWith('http')) {
        final cleanBase = dio.options.baseUrl.replaceAll(RegExp(r'/+$'), '');
        downloadUrl = '$cleanBase$downloadUrl';
      }
      final downloadRes = await dio.get<List<int>>(
        downloadUrl,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress((40 + (received / total * 60)).round(), 100);
          }
        },
      );
      if (downloadRes.data != null && downloadRes.data!.isNotEmpty) {
        await outputFile.writeAsBytes(downloadRes.data!);
        return outputFile;
      }
    }

    throw Exception(
      'Failed to obtain converted $toFormat file from PaperKit backend.',
    );
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
    if (fileId != null && fileId.isNotEmpty) {
      final res = await dio.post('/ai/ocr', data: {'file_id': fileId});
      return res.data is Map<String, dynamic>
          ? res.data
          : {'text': res.data.toString(), 'ocr': res.data.toString()};
    }
    if (file != null) {
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png'
          ? 'image/png'
          : (ext == 'webp'
                ? 'image/webp'
                : (ext == 'pdf' ? 'application/pdf' : 'image/jpeg'));

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.uri.pathSegments.last,
          contentType: MediaType.parse(mimeType),
        ),
      });

      final res = await dio.post(
        '/ai/ocr',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data is Map<String, dynamic>
          ? res.data
          : {'text': res.data.toString(), 'ocr': res.data.toString()};
    }
    throw Exception('No document or file provided for OCR');
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
    if (resolvedText.isEmpty && file != null) {
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.uri.pathSegments.last,
        ),
        'mode': mode,
        'language': language,
      });
      final res = await dio.post(
        '/ai/summarize',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data is Map<String, dynamic>
          ? res.data
          : {'summary': res.data.toString()};
    }
    final res = await dio.post(
      '/ai/summarize',
      data: {
        'text': resolvedText,
        'file_id': fileId,
        'mode': mode,
        'language': language,
      },
    );
    return res.data is Map<String, dynamic>
        ? res.data
        : {'summary': res.data.toString()};
  }

  // 3. AI Document Chat (Ask Document with RAG)
  Future<Map<String, dynamic>> askPDF({
    required String question,
    String? text,
    File? file,
    String? fileId,
  }) async {
    final resolvedText = await _resolveText(text: text, file: file);
    if (resolvedText.isEmpty && file != null) {
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.uri.pathSegments.last,
        ),
        'question': question,
      });
      final res = await dio.post(
        '/ai/ask',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data is Map<String, dynamic>
          ? res.data
          : {'answer': res.data.toString()};
    }
    final res = await dio.post(
      '/ai/ask',
      data: {'question': question, 'text': resolvedText, 'file_id': fileId},
    );
    return res.data is Map<String, dynamic>
        ? res.data
        : {'answer': res.data.toString()};
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

    if ((resolvedA.isEmpty && fileA != null) ||
        (resolvedB.isEmpty && fileB != null)) {
      final formMap = <String, dynamic>{};
      if (fileA != null) {
        formMap['file_a'] = MultipartFile.fromBytes(
          await fileA.readAsBytes(),
          filename: fileA.uri.pathSegments.last,
        );
      }
      if (fileB != null) {
        formMap['file_b'] = MultipartFile.fromBytes(
          await fileB.readAsBytes(),
          filename: fileB.uri.pathSegments.last,
        );
      }
      if (resolvedA.isNotEmpty) formMap['text_a'] = resolvedA;
      if (resolvedB.isNotEmpty) formMap['text_b'] = resolvedB;
      final res = await dio.post(
        '/ai/compare',
        data: FormData.fromMap(formMap),
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data;
    }

    final res = await dio.post(
      '/ai/compare',
      data: {
        'text_a': resolvedA,
        'text_b': resolvedB,
        'file_id_a': fileIdA,
        'file_id_b': fileIdB,
      },
    );
    return res.data;
  }

  // 5. Similarity Matrix (Multi-Doc Comparison)
  Future<Map<String, dynamic>> similarityMatrix({
    List<Map<String, String>>? documents,
    List<String>? fileIds,
  }) async {
    final res = await dio.post(
      '/ai/similarity-matrix',
      data: {'documents': documents ?? [], 'file_ids': fileIds ?? []},
    );
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
    if (resolvedText.isEmpty && file != null) {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          await file.readAsBytes(),
          filename: file.uri.pathSegments.last,
        ),
        'query': query,
      });
      final res = await dio.post(
        '/ai/search',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data;
    }
    final res = await dio.post(
      '/ai/search',
      data: {'query': query, 'text': resolvedText, 'file_id': fileId},
    );
    return res.data;
  }

  // 7. Document Classification & Tagger
  Future<Map<String, dynamic>> classifyDocument({
    String? text,
    File? file,
    String? fileId,
  }) async {
    final resolvedText = await _resolveText(text: text, file: file);
    if (resolvedText.isEmpty && file != null) {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          await file.readAsBytes(),
          filename: file.uri.pathSegments.last,
        ),
      });
      final res = await dio.post(
        '/ai/classify',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data;
    }
    final res = await dio.post(
      '/ai/classify',
      data: {'text': resolvedText, 'file_id': fileId},
    );
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
    if (resolvedText.isEmpty && file != null) {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          await file.readAsBytes(),
          filename: file.uri.pathSegments.last,
        ),
        'schema_type': schemaType,
      });
      final res = await dio.post(
        '/ai/extract-info',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data;
    }
    final res = await dio.post(
      '/ai/extract-info',
      data: {
        'text': resolvedText,
        'file_id': fileId,
        'schema_type': schemaType,
      },
    );
    return res.data;
  }

  // 9. AI Writing Assistant
  Future<Map<String, dynamic>> writingAssistant({
    required String text,
    String task = 'grammar_spelling',
    String? customInstruction,
    String? fileId,
  }) async {
    final res = await dio.post(
      '/ai/writing-assist',
      data: {
        'text': text,
        'task': task,
        'custom_instruction': customInstruction,
        'file_id': fileId,
      },
    );
    return res.data;
  }

  // 10. Smart PII Privacy & Redaction Detector
  Future<Map<String, dynamic>> detectPrivacy({
    String? text,
    File? file,
    String? fileId,
  }) async {
    final resolvedText = await _resolveText(text: text, file: file);
    if (resolvedText.isEmpty && file != null) {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          await file.readAsBytes(),
          filename: file.uri.pathSegments.last,
        ),
      });
      final res = await dio.post(
        '/ai/detect-privacy',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data;
    }
    final res = await dio.post(
      '/ai/detect-privacy',
      data: {'text': resolvedText, 'file_id': fileId},
    );
    return res.data;
  }

  // 11. Document Quality Auditor & Integrity Checker
  Future<Map<String, dynamic>> qualityCheckDocument({
    String? text,
    File? file,
    String? fileId,
  }) async {
    final resolvedText = await _resolveText(text: text, file: file);
    if (resolvedText.isEmpty && file != null) {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          await file.readAsBytes(),
          filename: file.uri.pathSegments.last,
        ),
      });
      final res = await dio.post(
        '/ai/quality-check',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data;
    }
    final res = await dio.post(
      '/ai/quality-check',
      data: {'text': resolvedText, 'file_id': fileId},
    );
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
    if (resolvedText.isEmpty && file != null) {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          await file.readAsBytes(),
          filename: file.uri.pathSegments.last,
        ),
        'target_language': targetLanguage,
      });
      final res = await dio.post(
        '/ai/translate',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data is Map<String, dynamic>
          ? res.data
          : {'translation': res.data.toString()};
    }
    final res = await dio.post(
      '/ai/translate',
      data: {
        'target_language': targetLanguage,
        'text': resolvedText,
        'file_id': fileId,
      },
    );
    return res.data is Map<String, dynamic>
        ? res.data
        : {'translation': res.data.toString()};
  }

  // 13. AI Table Extractor
  Future<Map<String, dynamic>> extractTables({
    String? text,
    File? file,
    String? fileId,
  }) async {
    final resolvedText = await _resolveText(text: text, file: file);
    if (resolvedText.isEmpty && file != null) {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          await file.readAsBytes(),
          filename: file.uri.pathSegments.last,
        ),
      });
      final res = await dio.post(
        '/ai/extract-tables',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data;
    }
    final res = await dio.post(
      '/ai/extract-tables',
      data: {'text': resolvedText, 'file_id': fileId},
    );
    return res.data;
  }

  // 14. AI PDF to Markdown Converter
  Future<Map<String, dynamic>> pdfToMarkdown({
    String? text,
    File? file,
    String? fileId,
  }) async {
    final resolvedText = await _resolveText(text: text, file: file);
    if (resolvedText.isEmpty && file != null) {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          await file.readAsBytes(),
          filename: file.uri.pathSegments.last,
        ),
      });
      final res = await dio.post(
        '/ai/pdf-to-markdown',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data;
    }
    final res = await dio.post(
      '/ai/pdf-to-markdown',
      data: {'text': resolvedText, 'file_id': fileId},
    );
    return res.data;
  }

  // 15. AI Report PDF Generator
  Future<Map<String, dynamic>> generateReportPdf({
    required String title,
    required String content,
    String subtitle = 'AI Analysis & Insights',
  }) async {
    final res = await dio.post(
      '/ai/generate-report-pdf',
      data: {'title': title, 'content': content, 'subtitle': subtitle},
    );
    return res.data;
  }

  // 16. AI Searchable PDF Generator
  Future<Map<String, dynamic>> createSearchablePdf({
    String? text,
    File? file,
    String? fileId,
  }) async {
    final resolvedText = await _resolveText(text: text, file: file);
    if (resolvedText.isEmpty && file != null) {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          await file.readAsBytes(),
          filename: file.uri.pathSegments.last,
        ),
      });
      final res = await dio.post(
        '/ai/searchable-pdf',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data;
    }
    final res = await dio.post(
      '/ai/searchable-pdf',
      data: {'text': resolvedText, 'file_id': fileId},
    );
    return res.data;
  }

  // 17. AI Image Enhancer (HuggingFace Inference API)
  Future<List<int>> enhanceImageHuggingFace({
    required File imageFile,
    String? hfToken,
  }) async {
    const hfUrl =
        'https://api-inference.huggingface.co/models/caidas/swin2SR-classical-sr-x2-64';
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

    final cleanEndpoint = endpoint.startsWith('/api')
        ? endpoint.substring(4)
        : endpoint;
    final res = await dio.post(cleanEndpoint, data: data);
    if (res.data is Map<String, dynamic>) {
      return res.data;
    }
    return {'result': res.data};
  }

  // Convert Video via backend FFmpeg
  Future<File> convertVideo({
    required File file,
    required String targetFormat,
  }) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
      'target_format': targetFormat,
    });
    final response = await dio.post<List<int>>(
      '/api/media/convert-video',
      data: formData,
      options: Options(
        responseType: ResponseType.bytes,
        contentType: 'multipart/form-data',
      ),
    );
    if (response.data == null || response.data!.isEmpty) {
      throw Exception('Video conversion failed on server.');
    }
    final outputDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputFile = File(
      '${outputDir.path}/Video_${targetFormat}_$timestamp.$targetFormat',
    );
    await outputFile.writeAsBytes(response.data!);
    return outputFile;
  }

  // Compress Video via backend FFmpeg
  Future<File> compressVideo({
    required File file,
    required String preset,
  }) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
      'preset': preset,
    });
    final response = await dio.post<List<int>>(
      '/api/media/compress-video',
      data: formData,
      options: Options(
        responseType: ResponseType.bytes,
        contentType: 'multipart/form-data',
      ),
    );
    if (response.data == null || response.data!.isEmpty) {
      throw Exception('Video compression failed on server.');
    }
    final outputDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = file.path.contains('.') ? file.path.split('.').last : 'mp4';
    final outputFile = File(
      '${outputDir.path}/Compressed_${preset}_$timestamp.$ext',
    );
    await outputFile.writeAsBytes(response.data!);
    return outputFile;
  }

  // Convert Audio via backend FFmpeg
  Future<File> convertAudio({
    required File file,
    required String targetFormat,
  }) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
      'target_format': targetFormat,
    });
    final response = await dio.post<List<int>>(
      '/api/media/convert-audio',
      data: formData,
      options: Options(
        responseType: ResponseType.bytes,
        contentType: 'multipart/form-data',
      ),
    );
    if (response.data == null || response.data!.isEmpty) {
      throw Exception('Audio conversion failed on server.');
    }
    final outputDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputFile = File(
      '${outputDir.path}/Audio_${targetFormat}_$timestamp.$targetFormat',
    );
    await outputFile.writeAsBytes(response.data!);
    return outputFile;
  }

  // PDF Editor: Render Page Image Byte Stream via PyMuPDF
  Future<Uint8List?> renderPdfPage({
    File? file,
    Uint8List? bytes,
    String? filename,
    required int pageNumber,
    int dpi = 150,
  }) async {
    try {
      final fileBytes = bytes ?? await file?.readAsBytes();
      if (fileBytes == null) return null;
      final name =
          filename ??
          (file != null ? file.uri.pathSegments.last : 'document.pdf');
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: name),
        'page_number': pageNumber,
        'dpi': dpi,
      });
      final response = await dio.post<List<int>>(
        '/api/editor/render-page',
        data: formData,
        options: Options(
          responseType: ResponseType.bytes,
          contentType: 'multipart/form-data',
        ),
      );
      if (response.data != null && response.data!.isNotEmpty) {
        return Uint8List.fromList(response.data!);
      }
    } catch (e) {
      print('ApiService.renderPdfPage error: $e');
    }
    return null;
  }

  // PDF Editor: Extract Structured Spans with Font Attributes via PyMuPDF
  Future<Map<String, dynamic>?> extractPdfSpans({
    File? file,
    Uint8List? bytes,
    String? filename,
    required int pageNumber,
  }) async {
    try {
      final fileBytes = bytes ?? await file?.readAsBytes();
      if (fileBytes == null) return null;
      final name =
          filename ??
          (file != null ? file.uri.pathSegments.last : 'document.pdf');
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: name),
        'page_number': pageNumber,
      });
      final response = await dio.post(
        '/api/editor/extract-spans',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
    } catch (e) {
      print('ApiService.extractPdfSpans error: $e');
    }
    return null;
  }

  // PDF Editor: Apply In-Place Text & Image Edits via PyMuPDF
  Future<File> applyPdfInPlaceEdits({
    required File file,
    required List<Map<String, dynamic>> editsPayload,
  }) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
      'payload': jsonEncode(editsPayload),
    });
    final response = await dio.post<List<int>>(
      '/api/editor/edit',
      data: formData,
      options: Options(
        responseType: ResponseType.bytes,
        contentType: 'multipart/form-data',
      ),
    );
    if (response.data == null || response.data!.isEmpty) {
      throw Exception('PDF In-Place edit failed on server.');
    }
    final outputDir = await getApplicationDocumentsDirectory();
    final outputFile = File(
      '${outputDir.path}/edited_${file.uri.pathSegments.last}',
    );
    await outputFile.writeAsBytes(response.data!);
    return outputFile;
  }

  // Parse Invoice details via AI
  Future<String> parseInvoice(File file) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
    });
    final response = await dio.post('/api/ai/parse-invoice', data: formData);
    return response.data['result']?.toString() ?? 'Invoice analysis complete.';
  }

  // Parse Resume/CV details via AI
  Future<String> parseCv(File file) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
    });
    final response = await dio.post('/api/ai/parse-cv', data: formData);
    return response.data['result']?.toString() ?? 'Resume analysis complete.';
  }

  // Generate Quiz — legacy unstructured string response (kept for backward compat)
  // Use generateQuiz() instead for the new structured JSON response.
  Future<String> generateQuizLegacy(File file) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
    });
    final response = await dio.post('/ai/generate-quiz', data: formData);
    return response.data['result']?.toString() ?? '';
  }

  // N-Up PDF generation
  Future<File> nupPdf(File file, int pagesPerSheet) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
      'pages_per_sheet': pagesPerSheet,
    });
    final response = await dio.post<List<int>>(
      '/api/tools/pdf/nup',
      data: formData,
      options: Options(responseType: ResponseType.bytes),
    );
    final outputDir = await getApplicationDocumentsDirectory();
    final outputFile = File(
      '${outputDir.path}/NUp_${pagesPerSheet}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await outputFile.writeAsBytes(response.data!);
    return outputFile;
  }

  // Booklet PDF creation
  Future<File> bookletPdf(File file) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
    });
    final response = await dio.post<List<int>>(
      '/api/tools/pdf/booklet',
      data: formData,
      options: Options(responseType: ResponseType.bytes),
    );
    final outputDir = await getApplicationDocumentsDirectory();
    final outputFile = File(
      '${outputDir.path}/Booklet_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await outputFile.writeAsBytes(response.data!);
    return outputFile;
  }

  // Add Headers & Footers
  Future<File> headersPdf(
    File file,
    String headerText,
    String footerText,
  ) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
      'header_text': headerText,
      'footer_text': footerText,
    });
    final response = await dio.post<List<int>>(
      '/api/tools/pdf/headers',
      data: formData,
      options: Options(responseType: ResponseType.bytes),
    );
    final outputDir = await getApplicationDocumentsDirectory();
    final outputFile = File(
      '${outputDir.path}/Numbered_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await outputFile.writeAsBytes(response.data!);
    return outputFile;
  }

  // Bates Stamping
  Future<File> batesPdf(File file, String prefix) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
      'prefix': prefix,
    });
    final response = await dio.post<List<int>>(
      '/api/tools/pdf/bates',
      data: formData,
      options: Options(responseType: ResponseType.bytes),
    );
    final outputDir = await getApplicationDocumentsDirectory();
    final outputFile = File(
      '${outputDir.path}/Bates_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await outputFile.writeAsBytes(response.data!);
    return outputFile;
  }

  // Flatten PDF Forms
  Future<File> flattenPdf(File file) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
    });
    final response = await dio.post<List<int>>(
      '/api/tools/pdf/flatten',
      data: formData,
      options: Options(responseType: ResponseType.bytes),
    );
    final outputDir = await getApplicationDocumentsDirectory();
    final outputFile = File(
      '${outputDir.path}/Flattened_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await outputFile.writeAsBytes(response.data!);
    return outputFile;
  }

  // Sanitize Image EXIF
  Future<File> sanitizeExif(File file) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
    });
    final response = await dio.post<List<int>>(
      '/api/tools/image/exif-sanitize',
      data: formData,
      options: Options(responseType: ResponseType.bytes),
    );
    final outputDir = await getApplicationDocumentsDirectory();
    final outputFile = File(
      '${outputDir.path}/Sanitized_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await outputFile.writeAsBytes(response.data!);
    return outputFile;
  }

  // Verify Checksum
  Future<Map<String, dynamic>> verifyChecksum(File file) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
    });
    final response = await dio.post(
      '/api/tools/checksum/verify',
      data: formData,
    );
    return Map<String, dynamic>.from(response.data);
  }

  // ── Academic / Research API Methods ─────────────────────────────────────

  /// Analyze a research paper — returns structured JSON with confidence labels.
  Future<Map<String, dynamic>> analyzeResearchPaper({
    required File file,
  }) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
    });
    final response = await dio.post('/ai/analyze-research', data: formData);
    return Map<String, dynamic>.from(response.data);
  }

  /// Literature review from 2–8 files.
  Future<Map<String, dynamic>> literatureReview({
    required List<File> files,
  }) async {
    final fields = <String, dynamic>{};
    for (int i = 0; i < files.length; i++) {
      final bytes = await files[i].readAsBytes();
      fields['file_$i'] = MultipartFile.fromBytes(
        bytes,
        filename: files[i].uri.pathSegments.last,
        contentType: MediaType('application', 'pdf'),
      );
    }
    final formData = FormData.fromMap(fields);
    final response = await dio.post('/ai/literature-review', data: formData);
    return Map<String, dynamic>.from(response.data);
  }

  /// Research gap analysis — returns structured JSON with gap list.
  Future<Map<String, dynamic>> researchGaps({required File file}) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
    });
    final response = await dio.post('/ai/research-gaps', data: formData);
    return Map<String, dynamic>.from(response.data);
  }

  /// Extract citations and bibliography entries.
  Future<Map<String, dynamic>> extractCitations({required File file}) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
    });
    final response = await dio.post('/ai/extract-citations', data: formData);
    return Map<String, dynamic>.from(response.data);
  }

  /// Format citations by style (apa, mla, ieee, chicago, harvard, vancouver).
  /// Accepts a list of raw citation strings or extracts them from a file.
  Future<Map<String, dynamic>> formatCitations({
    File? file,
    List<String>? citations,
    String style = 'apa',
  }) async {
    if (citations != null && citations.isNotEmpty) {
      final response = await dio.post(
        '/ai/format-citation',
        data: {'citations': citations, 'style': style},
      );
      return Map<String, dynamic>.from(response.data);
    }

    if (file == null) {
      throw ArgumentError('Either citations or file must be provided.');
    }
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
      'style': style,
    });
    final response = await dio.post('/ai/format-citation', data: formData);
    return Map<String, dynamic>.from(response.data);
  }

  /// Reference consistency check — returns issues, missing refs, duplicates.
  Future<Map<String, dynamic>> checkReferences({required File file}) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
    });
    final response = await dio.post('/ai/reference-check', data: formData);
    return Map<String, dynamic>.from(response.data);
  }

  /// Generate structured study notes.
  Future<Map<String, dynamic>> generateStudyNotes({
    required File file,
    List<String>? focusAreas,
  }) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
      if (focusAreas != null && focusAreas.isNotEmpty)
        'focus_areas': focusAreas.join(','),
    });
    final response = await dio.post('/ai/study-notes', data: formData);
    return Map<String, dynamic>.from(response.data);
  }

  /// Generate structured quiz questions.
  Future<Map<String, dynamic>> generateQuiz({
    required File file,
    List<String>? questionTypes,
    String difficulty = 'medium',
    int count = 10,
  }) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
      if (questionTypes != null && questionTypes.isNotEmpty)
        'question_types': questionTypes.join(','),
      'difficulty': difficulty,
      'count': count.toString(),
    });
    final response = await dio.post('/ai/generate-quiz', data: formData);
    return Map<String, dynamic>.from(response.data);
  }

  /// Generate spaced-repetition flashcards.
  Future<Map<String, dynamic>> generateFlashcards({
    required File file,
    List<String>? cardTypes,
    int count = 20,
  }) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
      if (cardTypes != null && cardTypes.isNotEmpty)
        'card_types': cardTypes.join(','),
      'count': count.toString(),
    });
    final response = await dio.post('/ai/generate-flashcards', data: formData);
    return Map<String, dynamic>.from(response.data);
  }

  /// Generate a hierarchical mind map structure.
  Future<Map<String, dynamic>> generateMindMap({required File file}) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
    });
    final response = await dio.post('/ai/generate-mindmap', data: formData);
    return Map<String, dynamic>.from(response.data);
  }

  /// Generate a slide presentation outline.
  Future<Map<String, dynamic>> generatePresentation({
    required File file,
    int slideCount = 10,
  }) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
      'slide_count': slideCount.toString(),
    });
    final response = await dio.post(
      '/ai/generate-presentation',
      data: formData,
    );
    return Map<String, dynamic>.from(response.data);
  }
}
