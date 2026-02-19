import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Real Notification Service for Android/iOS
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Skip initialization on web platform
    if (kIsWeb) {
      debugPrint('[Notification] Web platform - notifications disabled');
      _isInitialized = true;
      return;
    }

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[Notification] Response: ${response.payload}');
        },
      );
      
      // Request permissions for Android 13+
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      _isInitialized = true;
      debugPrint('[Notification] Local notifications initialized');
    } catch (e) {
      debugPrint('[Notification] Failed to initialize: $e');
      _isInitialized = false;
    }
  }

  /// Show a detailed consolidated notification for a field
  Future<void> showFieldStatusNotification({
    required String fieldName,
    required double temperature,
    required double humidity,
    required double moisture,
    required String statusMessage,
    bool isCritical = false,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;

    final String title = isCritical ? '🔴 CRITICAL: $fieldName' : '🌱 Status: $fieldName';
    final String body = 'T: ${temperature.toStringAsFixed(1)}°C | H: ${humidity.toStringAsFixed(0)}% | M: ${moisture.toStringAsFixed(0)}%\n$statusMessage';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'field_alerts_channel',
      'Field Alerts',
      channelDescription: 'Notifications for field sensor alerts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      color: Color(0xFF4CAF50),
      enableLights: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      fieldName.hashCode, // Unique ID per field
      title,
      body,
      platformDetails,
    );
  }

  Future<void> showAlert({
    required String title,
    required String body,
    String? payload,
    bool critical = false,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'general_alerts_channel',
      'General Alerts',
      channelDescription: 'General app notifications',
      importance: critical ? Importance.max : Importance.defaultImportance,
      priority: critical ? Priority.high : Priority.defaultPriority,
    );

    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
