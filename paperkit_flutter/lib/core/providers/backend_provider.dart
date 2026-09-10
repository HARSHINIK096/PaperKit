import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BackendProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isConnected = false;
  bool _isChecking = false;
  String _statusMessage = 'Connecting to PaperKit Cloud...';
  int _elapsedSeconds = 0;
  Timer? _timer;

  bool get isConnected => _isConnected;
  bool get isChecking => _isChecking;
  String get statusMessage => _statusMessage;
  int get elapsedSeconds => _elapsedSeconds;

  BackendProvider() {
    checkHealth();
  }

  Future<bool> checkHealth() async {
    _isChecking = true;
    _elapsedSeconds = 0;
    _statusMessage = 'Connecting to PaperKit Cloud...';
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      if (_elapsedSeconds > 5 && !_isConnected) {
        _statusMessage = 'Waking up cold services... ($_elapsedSeconds s)';
      }
      notifyListeners();
    });

    try {
      final healthy = await _apiService.checkHealth();
      _isConnected = healthy;
      _statusMessage = healthy ? 'Connected to PaperKit Cloud' : 'Cloud services offline';
      _isChecking = false;
      _timer?.cancel();
      notifyListeners();
      return healthy;
    } catch (_) {
      _isConnected = false;
      _statusMessage = 'Could not reach server';
      _isChecking = false;
      _timer?.cancel();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
