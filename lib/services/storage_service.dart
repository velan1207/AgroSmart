import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Theme preferences
  Future<void> setDarkMode(bool value) async {
    await _prefs?.setBool('dark_mode', value);
  }

  bool getDarkMode() {
    return _prefs?.getBool('dark_mode') ?? false;
  }

  // Last selected field
  Future<void> setLastFieldId(String fieldId) async {
    await _prefs?.setString('last_field_id', fieldId);
  }

  String? getLastFieldId() {
    return _prefs?.getString('last_field_id');
  }

  // User ID
  Future<void> setUserId(String userId) async {
    await _prefs?.setString('user_id', userId);
  }

  String? getUserId() {
    return _prefs?.getString('user_id');
  }

  // Notification preferences
  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs?.setBool('notifications_enabled', value);
  }

  bool getNotificationsEnabled() {
    return _prefs?.getBool('notifications_enabled') ?? true;
  }

  Future<void> setCriticalAlertsOnly(bool value) async {
    await _prefs?.setBool('critical_alerts_only', value);
  }

  bool getCriticalAlertsOnly() {
    return _prefs?.getBool('critical_alerts_only') ?? false;
  }

  // Unit preferences
  Future<void> setTemperatureUnit(String unit) async {
    await _prefs?.setString('temperature_unit', unit);
  }

  String getTemperatureUnit() {
    return _prefs?.getString('temperature_unit') ?? 'celsius';
  }

  // Language preference
  Future<void> setLanguage(String language) async {
    await _prefs?.setString('language', language);
  }

  String getLanguage() {
    return _prefs?.getString('language') ?? 'english';
  }

  // Refresh interval
  Future<void> setRefreshInterval(int seconds) async {
    await _prefs?.setInt('refresh_interval', seconds);
  }

  int getRefreshInterval() {
    return _prefs?.getInt('refresh_interval') ?? 5;
  }

  // ==========================================
  // SMS Alert Preferences
  // ==========================================

  Future<void> setSmsAlertsEnabled(bool value) async {
    await _prefs?.setBool('sms_alerts_enabled', value);
  }

  bool getSmsAlertsEnabled() {
    return _prefs?.getBool('sms_alerts_enabled') ?? false;
  }

  Future<void> setSmsPhoneNumbers(List<String> numbers) async {
    await _prefs?.setString('sms_phone_numbers', jsonEncode(numbers));
  }

  List<String> getSmsPhoneNumbers() {
    final stored = _prefs?.getString('sms_phone_numbers');
    if (stored == null || stored.isEmpty) return [];
    try {
      return List<String>.from(jsonDecode(stored));
    } catch (e) {
      return [];
    }
  }

  // ==========================================
  // Voice Alert Preferences
  // ==========================================

  Future<void> setVoiceAlertsEnabled(bool value) async {
    await _prefs?.setBool('voice_alerts_enabled', value);
  }

  bool getVoiceAlertsEnabled() {
    return _prefs?.getBool('voice_alerts_enabled') ?? false;
  }

  // Offline data cache
  Future<void> cacheOfflineData(String key, String jsonData) async {
    await _prefs?.setString('cache_$key', jsonData);
    await _prefs?.setInt('cache_${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  String? getCachedData(String key) {
    return _prefs?.getString('cache_$key');
  }

  int? getCacheTimestamp(String key) {
    return _prefs?.getInt('cache_${key}_timestamp');
  }

  bool isCacheValid(String key, {int maxAgeMinutes = 30}) {
    final timestamp = getCacheTimestamp(key);
    if (timestamp == null) return false;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return now.difference(cacheTime).inMinutes < maxAgeMinutes;
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs?.clear();
  }

  // ==========================================
  // Local Sensor History Storage
  // ==========================================

  static const String _historyKey = 'sensor_history';
  static const int _maxHistoryRecords = 2000; // ~7 days at 5-min intervals

  /// Store a sensor reading in local history
  Future<void> storeSensorReading(Map<String, dynamic> reading) async {
    await initialize();
    
    final history = getSensorHistory();
    
    // Add new reading with timestamp
    history.add({
      'temperature': reading['temperature'],
      'humidity': reading['humidity'],
      'soilMoisture': reading['soilMoisture'],
      'timestamp': reading['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
    });
    
    // Keep only the most recent records
    while (history.length > _maxHistoryRecords) {
      history.removeAt(0);
    }
    
    await _prefs?.setString(_historyKey, jsonEncode(history));
  }

  /// Get all stored sensor readings
  List<Map<String, dynamic>> getSensorHistory() {
    final stored = _prefs?.getString(_historyKey);
    if (stored == null || stored.isEmpty) return [];
    try {
      final decoded = jsonDecode(stored) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get sensor history filtered by date range
  List<Map<String, dynamic>> getSensorHistoryInRange(DateTime startDate, DateTime endDate) {
    final history = getSensorHistory();
    final startMs = startDate.millisecondsSinceEpoch;
    final endMs = endDate.millisecondsSinceEpoch;
    
    return history.where((reading) {
      final ts = reading['timestamp'] as int? ?? 0;
      return ts >= startMs && ts <= endMs;
    }).toList();
  }

  /// Calculate daily averages from local history
  List<Map<String, dynamic>> calculateDailyAverages({int days = 7}) {
    final history = getSensorHistory();
    if (history.isEmpty) return [];
    
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    
    // Group readings by date
    final Map<String, List<Map<String, dynamic>>> byDate = {};
    for (final reading in history) {
      final ts = reading['timestamp'] as int? ?? 0;
      final date = DateTime.fromMillisecondsSinceEpoch(ts);
      if (date.isBefore(cutoff)) continue;
      
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      byDate.putIfAbsent(dateKey, () => []).add(reading);
    }
    
    // Calculate averages for each date
    final List<Map<String, dynamic>> averages = [];
    byDate.forEach((dateKey, readings) {
      if (readings.isEmpty) return;
      
      double tempSum = 0, humSum = 0, moistureSum = 0;
      for (final r in readings) {
        tempSum += (r['temperature'] as num?)?.toDouble() ?? 0;
        humSum += (r['humidity'] as num?)?.toDouble() ?? 0;
        moistureSum += (r['soilMoisture'] as num?)?.toDouble() ?? 0;
      }
      
      final parts = dateKey.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      
      averages.add({
        'date': date,
        'temperature': tempSum / readings.length,
        'humidity': humSum / readings.length,
        'soilMoisture': moistureSum / readings.length,
      });
    });
    
    // Sort by date
    averages.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return averages;
  }

  /// Clear old history (keep only last N days)
  Future<void> cleanupOldHistory({int keepDays = 7}) async {
    final cutoff = DateTime.now().subtract(Duration(days: keepDays));
    final cutoffMs = cutoff.millisecondsSinceEpoch;
    
    final history = getSensorHistory();
    final filtered = history.where((reading) {
      final ts = reading['timestamp'] as int? ?? 0;
      return ts >= cutoffMs;
    }).toList();
    
    await _prefs?.setString(_historyKey, jsonEncode(filtered));
  }
}
