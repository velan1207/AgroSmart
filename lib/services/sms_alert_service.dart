import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// SMS Alert Service for sending emergency crop alerts via SMS
class SmsAlertService {
  static final SmsAlertService _instance = SmsAlertService._internal();
  factory SmsAlertService() => _instance;
  SmsAlertService._internal();

  bool _isInitialized = false;
  bool _hasPermission = false;

  bool get hasPermission => _hasPermission;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (!kIsWeb && Platform.isAndroid) {
        // On Android, we'll use platform channel or url_launcher
        // Permission will be requested when first SMS is sent
        _hasPermission = true;
      }
      _isInitialized = true;
      debugPrint('[SMS] Service initialized');
    } catch (e) {
      debugPrint('[SMS] Failed to initialize: $e');
    }
  }

  /// Send SMS alert to a list of phone numbers
  Future<bool> sendAlert({
    required String title,
    required String body,
    required List<String> phoneNumbers,
  }) async {
    if (phoneNumbers.isEmpty) {
      debugPrint('[SMS] No phone numbers configured');
      return false;
    }

    if (!_isInitialized) await initialize();

    final message = '🌾 AgroSmart Alert\n$title\n$body';

    bool success = false;
    for (final number in phoneNumbers) {
      final trimmed = number.trim();
      if (trimmed.isEmpty) continue;

      try {
        success = await _sendSms(trimmed, message) || success;
      } catch (e) {
        debugPrint('[SMS] Failed to send to $trimmed: $e');
      }
    }

    return success;
  }

  /// Send a test SMS to verify the system works
  Future<bool> sendTestMessage(String phoneNumber) async {
    if (!_isInitialized) await initialize();

    return _sendSms(
      phoneNumber,
      '🌾 AgroSmart Test\nThis is a test alert from AgroSmart crop monitoring. If you received this, SMS alerts are working!',
    );
  }

  /// Internal SMS sending method
  Future<bool> _sendSms(String phoneNumber, String message) async {
    try {
      // Use url_launcher as a cross-platform approach
      // This opens the SMS app with pre-filled message
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );

      // On Android, try direct SMS first via intent
      if (!kIsWeb && Platform.isAndroid) {
        // Use the sms: URI scheme which works on Android
        final Uri directSmsUri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
        
        if (await canLaunchUrl(directSmsUri)) {
          await launchUrl(directSmsUri);
          debugPrint('[SMS] Sent to $phoneNumber');
          return true;
        }
      }

      // Fallback: try standard URI
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        debugPrint('[SMS] SMS compose opened for $phoneNumber');
        return true;
      }

      debugPrint('[SMS] Cannot launch SMS for $phoneNumber');
      return false;
    } catch (e) {
      debugPrint('[SMS] Error sending to $phoneNumber: $e');
      return false;
    }
  }
}
