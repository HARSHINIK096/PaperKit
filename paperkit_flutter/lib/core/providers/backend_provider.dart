import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BackendProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isConnected = false;
  bool _isChecking = false;
  String _statusMessage = 'Checking Server Sync...';
  Timer? _periodicTimer;

  bool get isConnected => _isConnected;
  bool get isChecking => _isChecking;
  String get statusMessage => _statusMessage;
  Color get statusColor => _isConnected
      ? const Color(0xFF10B981) // Green Online
      : (_isChecking ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)); // Red Offline

  BackendProvider() {
    checkHealth();
    // Periodic background sync ping every 25 seconds
    _periodicTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      checkHealth(isSilent: true);
    });
  }

  Future<bool> checkHealth({bool isSilent = false}) async {
    if (!isSilent) {
      _isChecking = true;
      _statusMessage = 'Connecting to PaperKit Server...';
      notifyListeners();
    }

    try {
      final healthy = await _apiService.checkHealth();
      _isConnected = healthy;
      _statusMessage = healthy
          ? 'Cloud Server Online • Operational'
          : 'Local Mode • Cloud Server Offline';
      _isChecking = false;
      notifyListeners();
      return healthy;
    } catch (_) {
      _isConnected = false;
      _statusMessage = 'Server Offline • Reconnecting...';
      _isChecking = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }
}
