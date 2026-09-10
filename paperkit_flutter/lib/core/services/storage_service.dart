import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/document_file.dart';
import '../models/history_item.dart';

class StorageService {
  static const String _filesKey = 'paperkit_saved_files_v1';
  static const String _historyKey = 'paperkit_history_records_v1';
  static const String _anonUserIdKey = 'paperkit_anon_user_id_v1';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  String? _cachedUserId;

  // Generate RFC4122 v4 UUID
  String _generateUuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant RFC4122
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  // Get or initialize persistent anonymous user ID
  Future<String> getAnonymousUserId() async {
    if (_cachedUserId != null && _cachedUserId!.isNotEmpty) {
      return _cachedUserId!;
    }
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_anonUserIdKey);
    if (id == null || id.isEmpty) {
      id = _generateUuidV4();
      await prefs.setString(_anonUserIdKey, id);
    }
    _cachedUserId = id;
    return id;
  }

  // Reset or rotate anonymous identity
  Future<String> resetAnonymousIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    final newId = _generateUuidV4();
    await prefs.setString(_anonUserIdKey, newId);
    _cachedUserId = newId;
    return newId;
  }

  // Load all tracked documents
  Future<List<DocumentFile>> getFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_filesKey);
    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      final List<DocumentFile> list = [];
      for (final item in decoded) {
        final doc = DocumentFile.fromJson(item);
        if (File(doc.path).existsSync()) {
          list.add(doc);
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  // Save document to history & files tracking
  Future<void> saveFile(DocumentFile file) async {
    final files = await getFiles();
    files.removeWhere((f) => f.path == file.path);
    files.insert(0, file);

    final prefs = await SharedPreferences.getInstance();
    final jsonList = files.map((f) => f.toJson()).toList();
    await prefs.setString(_filesKey, jsonEncode(jsonList));
  }

  // Toggle Favorite
  Future<void> toggleFavorite(String fileId) async {
    final files = await getFiles();
    final index = files.indexWhere((f) => f.id == fileId);
    if (index != -1) {
      final updated = DocumentFile(
        id: files[index].id,
        name: files[index].name,
        path: files[index].path,
        size: files[index].size,
        modifiedAt: files[index].modifiedAt,
        type: files[index].type,
        isFavorite: !files[index].isFavorite,
        thumbnailPath: files[index].thumbnailPath,
        pageCount: files[index].pageCount,
      );
      files[index] = updated;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_filesKey, jsonEncode(files.map((f) => f.toJson()).toList()));
    }
  }

  // Delete file from device and tracking
  Future<void> deleteFile(String fileId) async {
    final files = await getFiles();
    final target = files.where((f) => f.id == fileId).firstOrNull;
    if (target != null) {
      final file = File(target.path);
      if (await file.exists()) {
        await file.delete();
      }
      files.removeWhere((f) => f.id == fileId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_filesKey, jsonEncode(files.map((f) => f.toJson()).toList()));
    }
  }

  // Get Processing History
  Future<List<HistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_historyKey);
    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => HistoryItem.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  // Record operation into history
  Future<void> addHistory(HistoryItem item) async {
    final history = await getHistory();
    history.insert(0, item);
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(history.map((h) => h.toJson()).toList()));
  }

  // Clear history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // Calculate storage usage breakdown
  Future<Map<String, int>> getStorageBreakdown() async {
    final files = await getFiles();
    int pdfBytes = 0;
    int imageBytes = 0;
    int mediaBytes = 0;
    int otherBytes = 0;

    for (final f in files) {
      switch (f.type) {
        case FileTypeCategory.pdf:
          pdfBytes += f.size;
          break;
        case FileTypeCategory.image:
          imageBytes += f.size;
          break;
        case FileTypeCategory.video:
        case FileTypeCategory.audio:
          mediaBytes += f.size;
          break;
        default:
          otherBytes += f.size;
      }
    }

    return {
      'pdf': pdfBytes,
      'image': imageBytes,
      'media': mediaBytes,
      'other': otherBytes,
      'total': pdfBytes + imageBytes + mediaBytes + otherBytes,
    };
  }
}
