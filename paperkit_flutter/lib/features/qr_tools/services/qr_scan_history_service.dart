import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/qr_parsed_payload.dart';
import '../models/qr_scan_history_item.dart';

class QrScanHistoryService {
  static const String _storageKey = 'paperkit_qr_scan_history_v1';
  static const int _maxItems = 100;

  const QrScanHistoryService._();

  static Future<List<QrScanHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];
    return jsonList
        .map((itemStr) {
          try {
            return QrScanHistoryItem.fromJson(jsonDecode(itemStr) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<QrScanHistoryItem>()
        .toList();
  }

  static Future<QrScanHistoryItem> recordScan(QrParsedPayload payload) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    final item = QrScanHistoryItem(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      type: payload.type,
      rawData: payload.rawData,
      title: payload.title,
      subtitle: payload.subtitle,
    );

    // Add at start (newest first), deduplicating exact same recent scan if < 5 seconds
    history.removeWhere((h) => h.rawData == payload.rawData && DateTime.now().difference(h.timestamp).inSeconds < 5);
    history.insert(0, item);

    if (history.length > _maxItems) {
      history.removeRange(_maxItems, history.length);
    }

    final jsonList = history.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
    return item;
  }

  static Future<void> deleteItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.removeWhere((h) => h.id == id);
    final jsonList = history.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
