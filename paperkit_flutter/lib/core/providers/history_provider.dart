import 'package:flutter/material.dart';
import '../models/history_item.dart';
import '../services/storage_service.dart';

class HistoryProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<HistoryItem> _history = [];
  bool _isLoading = false;

  List<HistoryItem> get history => _history;
  bool get isLoading => _isLoading;

  HistoryProvider() {
    loadHistory();
  }

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();
    _history = await _storageService.getHistory();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRecord(HistoryItem item) async {
    await _storageService.addHistory(item);
    await loadHistory();
  }

  Future<void> clearAll() async {
    await _storageService.clearHistory();
    await loadHistory();
  }
}
