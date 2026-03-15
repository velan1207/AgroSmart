import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../providers/settings_provider.dart';

class AlertProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  final SmsAlertService _smsAlertService = SmsAlertService();
  final TTSService _ttsService = TTSService();
  SettingsProvider? _settingsProvider;
  
  List<Alert> _alerts = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Alert>? _alertSubscription;
  int _unreadCount = 0;

  // Getters
  List<Alert> get alerts => _alerts;
  List<Alert> get unreadAlerts => _alerts.where((a) => !a.isRead).toList();
  List<Alert> get criticalAlerts => 
      _alerts.where((a) => a.severity == AlertSeverity.critical && !a.isResolved).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;
  bool get hasCritical => criticalAlerts.isNotEmpty;

  // Initialize and start listening
  Future<void> initialize({SettingsProvider? settingsProvider}) async {
    _settingsProvider = settingsProvider;
    try {
      await _notificationService.initialize();
      await _smsAlertService.initialize();
      await _ttsService.initialize();
    } catch (e) {
      debugPrint('[AlertProvider] Failed to initialize services: $e');
    }
    await loadAlerts();
    _startAlertListener();
  }

  /// Update the settings reference (call when settings change)
  void updateSettings(SettingsProvider settings) {
    _settingsProvider = settings;
  }

  void _startAlertListener() {
    _alertSubscription = _firebaseService.alertStream.listen((alert) {
      // Add new alert at the beginning
      _alerts.insert(0, alert);
      _unreadCount++;
      
      // Show notification for critical alerts
      if (alert.severity == AlertSeverity.critical) {
        _showNotification(alert);
      }
      
      notifyListeners();
    });
  }

  void _showNotification(Alert alert) {
    // Push notification
    if (alert.currentTemp != null && alert.currentHumidity != null && alert.currentMoisture != null) {
      _notificationService.showFieldStatusNotification(
        fieldName: alert.fieldName,
        temperature: alert.currentTemp!,
        humidity: alert.currentHumidity!,
        moisture: alert.currentMoisture!,
        statusMessage: alert.message,
        isCritical: alert.severity == AlertSeverity.critical,
      );
    } else {
      _notificationService.showAlert(
        title: alert.title,
        body: alert.message,
        critical: alert.severity == AlertSeverity.critical,
      );
    }

    // SMS alert for critical/warning alerts
    if (_settingsProvider != null && _settingsProvider!.smsAlertsEnabled) {
      final phoneNumbers = _settingsProvider!.smsPhoneNumbers;
      if (phoneNumbers.isNotEmpty && 
          (alert.severity == AlertSeverity.critical || alert.severity == AlertSeverity.warning)) {
        _smsAlertService.sendAlert(
          title: alert.title,
          body: '${alert.message}\nField: ${alert.fieldName}',
          phoneNumbers: phoneNumbers,
        );
        debugPrint('[AlertProvider] SMS alert sent to ${phoneNumbers.length} numbers');
      }
    }

    // Voice alert for critical alerts
    if (_settingsProvider != null && _settingsProvider!.voiceAlertsEnabled) {
      if (alert.severity == AlertSeverity.critical || alert.severity == AlertSeverity.warning) {
        final langCode = _settingsProvider!.languageCode;
        _ttsService.speakAlert(alert, langCode);
        debugPrint('[AlertProvider] Voice alert spoken in $langCode');
      }
    }
  }

  // Load alerts from Firebase
  Future<void> loadAlerts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _alerts = await _firebaseService.getRecentAlerts();
      _updateUnreadCount();
    } catch (e) {
      _error = 'Failed to load alerts: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark alert as read
  void markAsRead(String alertId) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isRead: true);
      _updateUnreadCount();
      notifyListeners();
    }
  }

  // Mark all as read
  void markAllAsRead() {
    _alerts = _alerts.map((a) => a.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();
  }

  // Mark alert as resolved
  void markAsResolved(String alertId) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isResolved: true);
      notifyListeners();
    }
  }

  // Delete alert
  Future<void> deleteAlert(String alertId) async {
    // Optimistic UI update
    _alerts.removeWhere((a) => a.id == alertId);
    _updateUnreadCount();
    notifyListeners();

    // Sync with Firebase
    await _firebaseService.deleteAlert(alertId);
  }

  // Clear all alerts
  Future<void> clearAll() async {
    // Optimistic UI update
    _alerts.clear();
    _unreadCount = 0;
    notifyListeners();

    // Sync with Firebase
    await _firebaseService.clearAllAlerts();
  }

  // Filter alerts by field
  List<Alert> getAlertsForField(String fieldId) {
    return _alerts.where((a) => a.fieldId == fieldId).toList();
  }

  // Filter alerts by type
  List<Alert> getAlertsByType(AlertType type) {
    return _alerts.where((a) => a.type == type).toList();
  }

  // Filter alerts by severity
  List<Alert> getAlertsBySeverity(AlertSeverity severity) {
    return _alerts.where((a) => a.severity == severity).toList();
  }

  void _updateUnreadCount() {
    _unreadCount = _alerts.where((a) => !a.isRead).length;
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    super.dispose();
  }
}
