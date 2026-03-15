import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/alert.dart';

/// Text-to-Speech Service for voice output and voice alerts
class TTSService {
  static final TTSService _instance = TTSService._internal();
  static const MethodChannel _nativeLinuxChannel =
      MethodChannel('crop_monitor/native_tts');
  factory TTSService() => _instance;
  TTSService._internal();

  FlutterTts? _flutterTts;
  Timer? _linuxSpeechTimer;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isAvailable = true;
  String _currentLanguage = 'en-US';

  bool get isSpeaking => _isSpeaking;
  bool get isAvailable => _isAvailable;
  bool get _useNativeLinuxTts =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  void _markUnavailable(String reason) {
    _isAvailable = false;
    _isSpeaking = false;
    debugPrint('[TTS] Disabled: $reason');
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (!_isAvailable) return;

    if (_useNativeLinuxTts) {
      try {
        final available =
            await _nativeLinuxChannel.invokeMethod<bool>('isAvailable') ?? false;
        if (!available) {
          _markUnavailable('No Linux speech backend found');
          return;
        }

        _isInitialized = true;
        debugPrint('[TTS] Linux native speech backend initialized');
      } on PlatformException catch (e) {
        _markUnavailable('Linux native TTS unavailable: ${e.message ?? e.code}');
      } catch (e) {
        _markUnavailable('Linux native TTS failed: $e');
      }
      return;
    }
    
    if (kIsWeb) {
      debugPrint('[TTS] Web platform - using browser TTS');
    }

    try {
      _flutterTts = FlutterTts();

      // iOS-only API. Calling this on Linux causes MissingPluginException.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _flutterTts!.setSharedInstance(true);
      }
      await _flutterTts!.setSpeechRate(0.5);
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.0);

      _flutterTts!.setStartHandler(() {
        _isSpeaking = true;
      });

      _flutterTts!.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts!.setErrorHandler((message) {
        _isSpeaking = false;
        debugPrint('[TTS] Error: $message');
      });

      _isInitialized = true;
      debugPrint('[TTS] Service initialized');
    } on MissingPluginException catch (e) {
      _markUnavailable('Missing plugin: $e');
    } catch (e) {
      debugPrint('[TTS] Failed to initialize: $e');
    }
  }

  /// Set language for TTS
  Future<void> setLanguage(String languageCode) async {
    if (!_isAvailable) return;
    if (!_isInitialized) await initialize();
    if (!_isAvailable) return;
    
    String locale;
    switch (languageCode) {
      case 'ta':
        locale = 'ta-IN';
        break;
      case 'hi':
        locale = 'hi-IN';
        break;
      default:
        locale = 'en-US';
    }
    
    _currentLanguage = locale;

    if (_useNativeLinuxTts) {
      debugPrint('[TTS] Linux native language set to $locale');
      return;
    }
    
    try {
      await _flutterTts?.setLanguage(locale);
      debugPrint('[TTS] Language set to $locale');
    } on MissingPluginException catch (e) {
      _markUnavailable('setLanguage unavailable: $e');
    } catch (e) {
      debugPrint('[TTS] Failed to set language: $e');
    }
  }

  /// Speak text
  Future<void> speak(String text) async {
    if (!_isAvailable) return;
    if (!_isInitialized) await initialize();
    if (!_isAvailable) return;

    final normalizedText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalizedText.isEmpty) return;

    if (_useNativeLinuxTts) {
      try {
        await stop();
        _isSpeaking = true;
        await _nativeLinuxChannel.invokeMethod('speak', {
          'text': normalizedText,
          'locale': _currentLanguage,
          'rate': _linuxRateForLocale(_currentLanguage),
          'pitch': _linuxPitchForLocale(_currentLanguage),
        });
        _scheduleLinuxSpeechReset(normalizedText, _currentLanguage);
      } on PlatformException catch (e) {
        _isSpeaking = false;
        _markUnavailable('Linux speak failed: ${e.message ?? e.code}');
      } catch (e) {
        _isSpeaking = false;
        debugPrint('[TTS] Failed to speak on Linux: $e');
      }
      return;
    }
    
    if (_flutterTts == null) {
      debugPrint('[TTS] Not available');
      return;
    }

    try {
      await stop();
      await _flutterTts!.speak(normalizedText);
    } on MissingPluginException catch (e) {
      _markUnavailable('speak unavailable: $e');
    } catch (e) {
      debugPrint('[TTS] Failed to speak: $e');
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    if (!_isAvailable) return;

    _linuxSpeechTimer?.cancel();
    _linuxSpeechTimer = null;

    if (_useNativeLinuxTts) {
      try {
        await _nativeLinuxChannel.invokeMethod('stop');
      } on PlatformException catch (e) {
        debugPrint('[TTS] Linux stop failed: ${e.message ?? e.code}');
      } catch (e) {
        debugPrint('[TTS] Failed to stop Linux TTS: $e');
      }
      _isSpeaking = false;
      return;
    }

    if (_flutterTts == null) return;
    
    try {
      await _flutterTts!.stop();
      _isSpeaking = false;
    } on MissingPluginException catch (e) {
      _markUnavailable('stop unavailable: $e');
    } catch (e) {
      debugPrint('[TTS] Failed to stop: $e');
    }
  }

  /// Speak AI insight summary
  Future<void> speakInsight(String summary, String languageCode) async {
    await setLanguage(languageCode);
    await speak(summary);
  }

  /// Speak an alert in the specified language
  Future<void> speakAlert(Alert alert, String languageCode) async {
    final text = _getAlertTextForLanguage(alert, languageCode);
    await setLanguage(languageCode);
    await speak(text);
    debugPrint('[TTS] Speaking alert in $languageCode: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
  }

  /// Speak a stress prediction summary
  Future<void> speakStressPrediction(String summary, String languageCode) async {
    await setLanguage(languageCode);
    await speak(summary);
  }

  /// Build localized natural language alert text
  String _getAlertTextForLanguage(Alert alert, String languageCode) {
    switch (languageCode) {
      case 'ta':
        return _getTamilAlertText(alert);
      case 'hi':
        return _getHindiAlertText(alert);
      default:
        return _getEnglishAlertText(alert);
    }
  }

  String _getEnglishAlertText(Alert alert) {
    final fieldName = alert.fieldName;
    switch (alert.type) {
      case AlertType.lowMoisture:
        return 'Alert! Soil moisture in $fieldName is low at ${alert.value?.toStringAsFixed(0) ?? 'unknown'} percent. Irrigation is needed immediately.';
      case AlertType.highMoisture:
        return 'Warning. Soil moisture in $fieldName is too high at ${alert.value?.toStringAsFixed(0) ?? 'unknown'} percent. Check for waterlogging.';
      case AlertType.highTemperature:
        return 'Alert! Temperature in $fieldName has reached ${alert.value?.toStringAsFixed(1) ?? 'unknown'} degrees celsius. This may cause heat stress to your crops.';
      case AlertType.lowTemperature:
        return 'Warning. Temperature in $fieldName has dropped to ${alert.value?.toStringAsFixed(1) ?? 'unknown'} degrees celsius. Cold stress may affect crops.';
      case AlertType.highHumidity:
        return 'Warning. Humidity in $fieldName is high. This may promote fungal diseases.';
      case AlertType.lowHumidity:
        return 'Warning. Humidity in $fieldName is very low. Crops may experience dry stress.';
      case AlertType.deviceOffline:
        return 'Warning. The sensor device for $fieldName is offline. Please check the hardware connection.';
      case AlertType.pumpActivated:
        return 'Information. The irrigation pump for $fieldName has been activated.';
      case AlertType.pumpDeactivated:
        return 'Information. The irrigation pump for $fieldName has been deactivated.';
      case AlertType.criticalStress:
        return 'Critical alert! Your crops in $fieldName are under severe stress. Immediate action is required to prevent crop damage.';
    }
  }

  String _getTamilAlertText(Alert alert) {
    final fieldName = alert.fieldName;
    switch (alert.type) {
      case AlertType.lowMoisture:
        return 'எச்சரிக்கை! $fieldName இல் மண் ஈரப்பதம் ${alert.value?.toStringAsFixed(0) ?? ''} சதவீதமாக குறைந்துள்ளது. உடனடியாக நீர்ப்பாசனம் செய்யவும்.';
      case AlertType.highMoisture:
        return 'எச்சரிக்கை. $fieldName இல் மண் ஈரப்பதம் மிக அதிகமாக உள்ளது. நீர் தேங்குதலைச் சரிபார்க்கவும்.';
      case AlertType.highTemperature:
        return 'எச்சரிக்கை! $fieldName இல் வெப்பநிலை ${alert.value?.toStringAsFixed(1) ?? ''} டிகிரி செல்சியஸ் ஆக உயர்ந்துள்ளது. பயிர்களுக்கு வெப்ப அழுத்தம் ஏற்படலாம்.';
      case AlertType.lowTemperature:
        return 'எச்சரிக்கை. $fieldName இல் வெப்பநிலை ${alert.value?.toStringAsFixed(1) ?? ''} டிகிரி செல்சியஸ் ஆக குறைந்துள்ளது. குளிர் அழுத்தம் ஏற்படலாம்.';
      case AlertType.highHumidity:
        return 'எச்சரிக்கை. $fieldName இல் ஈரப்பதம் அதிகமாக உள்ளது. பூஞ்சை நோய்கள் ஏற்படலாம்.';
      case AlertType.lowHumidity:
        return 'எச்சரிக்கை. $fieldName இல் ஈரப்பதம் மிகக் குறைவாக உள்ளது.';
      case AlertType.deviceOffline:
        return 'எச்சரிக்கை. $fieldName இன் சென்சார் ஆஃப்லைன் ஆகிவிட்டது. இணைப்பைச் சரிபார்க்கவும்.';
      case AlertType.pumpActivated:
        return '$fieldName இன் நீர்ப்பாசன மோட்டார் இயக்கப்பட்டது.';
      case AlertType.pumpDeactivated:
        return '$fieldName இன் நீர்ப்பாசன மோட்டார் நிறுத்தப்பட்டது.';
      case AlertType.criticalStress:
        return 'அவசர எச்சரிக்கை! $fieldName இல் உள்ள பயிர்கள் கடுமையான அழுத்தத்தில் உள்ளன. பயிர் சேதத்தைத் தடுக்க உடனடி நடவடிக்கை தேவை.';
    }
  }

  String _getHindiAlertText(Alert alert) {
    final fieldName = alert.fieldName;
    switch (alert.type) {
      case AlertType.lowMoisture:
        return 'चेतावनी! $fieldName में मिट्टी की नमी ${alert.value?.toStringAsFixed(0) ?? ''} प्रतिशत तक गिर गई है। तुरंत सिंचाई करें।';
      case AlertType.highMoisture:
        return 'चेतावनी। $fieldName में मिट्टी की नमी बहुत अधिक है। जलभराव की जाँच करें।';
      case AlertType.highTemperature:
        return 'चेतावनी! $fieldName में तापमान ${alert.value?.toStringAsFixed(1) ?? ''} डिग्री सेल्सियस तक पहुँच गया है। फसलों को गर्मी का तनाव हो सकता है।';
      case AlertType.lowTemperature:
        return 'चेतावनी। $fieldName में तापमान ${alert.value?.toStringAsFixed(1) ?? ''} डिग्री सेल्सियस तक गिर गया है। ठंड का तनाव हो सकता है।';
      case AlertType.highHumidity:
        return 'चेतावनी। $fieldName में नमी अधिक है। फंगल रोग हो सकते हैं।';
      case AlertType.lowHumidity:
        return 'चेतावनी। $fieldName में नमी बहुत कम है।';
      case AlertType.deviceOffline:
        return 'चेतावनी। $fieldName का सेंसर ऑफलाइन है। कनेक्शन जाँचें।';
      case AlertType.pumpActivated:
        return '$fieldName का सिंचाई पंप चालू किया गया।';
      case AlertType.pumpDeactivated:
        return '$fieldName का सिंचाई पंप बंद किया गया।';
      case AlertType.criticalStress:
        return 'गंभीर चेतावनी! $fieldName में फसलें गंभीर तनाव में हैं। फसल नुकसान रोकने के लिए तुरंत कार्रवाई करें।';
    }
  }

  /// Get available languages
  Future<List<String>> getAvailableLanguages() async {
    if (!_isInitialized) await initialize();

    if (_useNativeLinuxTts) {
      return const ['en-US', 'ta-IN', 'hi-IN'];
    }
    
    try {
      final languages = await _flutterTts?.getLanguages;
      return List<String>.from(languages ?? []);
    } catch (e) {
      debugPrint('[TTS] Failed to get languages: $e');
      return [];
    }
  }

  void dispose() {
    _linuxSpeechTimer?.cancel();
    _flutterTts?.stop();
  }

  int _linuxRateForLocale(String locale) {
    if (locale.startsWith('ta')) return -24;
    if (locale.startsWith('hi')) return -16;
    return -8;
  }

  int _linuxPitchForLocale(String locale) {
    if (locale.startsWith('ta')) return -8;
    if (locale.startsWith('hi')) return -4;
    return 0;
  }

  int _wordsPerMinuteForLocale(String locale) {
    if (locale.startsWith('ta')) return 118;
    if (locale.startsWith('hi')) return 128;
    return 150;
  }

  void _scheduleLinuxSpeechReset(String text, String locale) {
    _linuxSpeechTimer?.cancel();

    final tokens = text.split(RegExp(r'\s+')).where((token) => token.isNotEmpty);
    final wordCount = tokens.length;
    final wordsPerMinute = _wordsPerMinuteForLocale(locale);
    final seconds = ((wordCount / wordsPerMinute) * 60).ceil().clamp(2, 30);

    _linuxSpeechTimer = Timer(Duration(seconds: seconds + 1), () {
      _isSpeaking = false;
    });
  }
}
