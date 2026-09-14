import 'package:flutter/material.dart';
import '../models/document_file.dart';
import '../services/storage_service.dart';

class FilesProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<DocumentFile> _files = [];
  bool _isLoading = false;
  Map<String, int> _storageBreakdown = {'total': 0};

  List<DocumentFile> get files => _files;
  List<DocumentFile> get recentFiles => _files.take(5).toList();
  List<DocumentFile> get favoriteFiles => _files.where((f) => f.isFavorite).toList();
  bool get isLoading => _isLoading;
  Map<String, int> get storageBreakdown => _storageBreakdown;

  FilesProvider() {
    loadFiles();
  }

  Future<void> loadFiles() async {
    _isLoading = true;
    notifyListeners();
    _files = await _storageService.getFiles();
    _storageBreakdown = await _storageService.getStorageBreakdown();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addFile(DocumentFile file) async {
    await _storageService.saveFile(file);
    await loadFiles();
  }

  Future<void> toggleFavorite(String fileId) async {
    await _storageService.toggleFavorite(fileId);
    await loadFiles();
  }

  Future<void> deleteFile(String fileId) async {
    await _storageService.deleteFile(fileId);
    await loadFiles();
  }
}
