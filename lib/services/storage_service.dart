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
}
