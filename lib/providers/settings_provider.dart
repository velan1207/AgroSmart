import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/services.dart';
import '../utils/localization.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _criticalAlertsOnly = false;
  String _temperatureUnit = 'celsius';
  String _languageCode = 'en'; // en, ta, hi
  int _refreshInterval = 5;
  String? _userId;
  bool _isOnline = true;
  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get criticalAlertsOnly => _criticalAlertsOnly;
  String get temperatureUnit => _temperatureUnit;
  String get languageCode => _languageCode;
  String get language => _languageCodeToName(_languageCode);
  int get refreshInterval => _refreshInterval;
  String? get userId => _userId;
  bool get hasUserId => _userId != null && _userId!.isNotEmpty;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  bool get isOnline => _isOnline;

  // Initialize settings from storage
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _storageService.initialize();
    
    _isDarkMode = _storageService.getDarkMode();
    _notificationsEnabled = _storageService.getNotificationsEnabled();
    _criticalAlertsOnly = _storageService.getCriticalAlertsOnly();
    _temperatureUnit = _storageService.getTemperatureUnit();
    _languageCode = _languageNameToCode(_storageService.getLanguage());
    _refreshInterval = _storageService.getRefreshInterval();
    _userId = _storageService.getUserId();
    
    if (_userId != null) {
      FirebaseService().setUserId(_userId!);
    }
    
    _initConnectivity();
    
    _isInitialized = true;
    notifyListeners();
  }

  String _languageCodeToName(String code) {
    switch (code) {
      case 'ta':
        return 'tamil';
      case 'hi':
        return 'hindi';
      default:
        return 'english';
    }
  }

  String _languageNameToCode(String name) {
    switch (name.toLowerCase()) {
      case 'tamil':
        return 'ta';
      case 'hindi':
        return 'hi';
      default:
        return 'en';
    }
  }

  // Toggle dark mode
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _storageService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  // Set dark mode
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _storageService.setDarkMode(value);
    notifyListeners();
  }

  // Toggle notifications
  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    await _storageService.setNotificationsEnabled(_notificationsEnabled);
    notifyListeners();
  }

  // Set critical alerts only
  Future<void> setCriticalAlertsOnly(bool value) async {
    _criticalAlertsOnly = value;
    await _storageService.setCriticalAlertsOnly(value);
    notifyListeners();
  }

  // Set temperature unit
  Future<void> setTemperatureUnit(String unit) async {
    _temperatureUnit = unit;
    await _storageService.setTemperatureUnit(unit);
    notifyListeners();
  }

  // Set language by code (en, ta, hi)
  Future<void> setLanguageCode(String code) async {
    _languageCode = code;
    await _storageService.setLanguage(_languageCodeToName(code));
    notifyListeners();
  }

  // Set language by name (for backward compatibility)
  Future<void> setLanguage(String language) async {
    _languageCode = _languageNameToCode(language);
    await _storageService.setLanguage(language);
    notifyListeners();
  }

  // Set refresh interval
  Future<void> setRefreshInterval(int seconds) async {
    _refreshInterval = seconds;
    await _storageService.setRefreshInterval(seconds);
    notifyListeners();
  }

  // Set User ID
  Future<void> setUserId(String id) async {
    _userId = id;
    await _storageService.setUserId(id);
    
    // Also notify Firebase service about the change
    FirebaseService().setUserId(id);
    
    notifyListeners();
  }

  // Set online status
  void setOnlineStatus(bool isOnline) {
    _isOnline = isOnline;
    notifyListeners();
  }

  // Convert temperature based on unit preference
  double convertTemperature(double celsius) {
    if (_temperatureUnit == 'fahrenheit') {
      return (celsius * 9 / 5) + 32;
    }
    return celsius;
  }

  // Get temperature unit symbol
  String get temperatureSymbol {
    return _temperatureUnit == 'fahrenheit' ? '°F' : '°C';
  }

  // Get localized string
  String tr(String key) {
    return AppLocalizations.get(key, _languageCode);
  }

  // Get available languages
  List<Map<String, String>> get availableLanguages => SupportedLanguages.all;

  // Reset to defaults
  Future<void> resetToDefaults() async {
    _isDarkMode = false;
    _notificationsEnabled = true;
    _criticalAlertsOnly = false;
    _temperatureUnit = 'celsius';
    _languageCode = 'en';
    _refreshInterval = 5;
    _userId = null;
    
    // Clear in Firebase Service too
    FirebaseService().setUserId('');
    
    await _storageService.clearAll();
    notifyListeners();
  }

  // Monitor connectivity
  void _initConnectivity() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // If results contains mobile, wifi, or ethernet, we are online
      // If it only contains none (or is empty? unlikely), we are offline
      bool isConnected = results.any((result) => 
        result == ConnectivityResult.mobile || 
        result == ConnectivityResult.wifi || 
        result == ConnectivityResult.ethernet);
        
      if (_isOnline != isConnected) {
        _isOnline = isConnected;
        notifyListeners();
      }
    });
  }
}
