import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-Speech Service for voice output
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  // ignore: unused_field
  String _currentLanguage = 'en-US';

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    if (kIsWeb) {
      debugPrint('[TTS] Web platform - using browser TTS');
    }

    try {
      _flutterTts = FlutterTts();
      
      await _flutterTts!.setSharedInstance(true);
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
    } catch (e) {
      debugPrint('[TTS] Failed to initialize: $e');
    }
  }

  /// Set language for TTS
  Future<void> setLanguage(String languageCode) async {
    if (!_isInitialized) await initialize();
    
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
    
    try {
      await _flutterTts?.setLanguage(locale);
      debugPrint('[TTS] Language set to $locale');
    } catch (e) {
      debugPrint('[TTS] Failed to set language: $e');
    }
  }

  /// Speak text
  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    
    if (_flutterTts == null) {
      debugPrint('[TTS] Not available');
      return;
    }

    try {
      await stop();
      await _flutterTts!.speak(text);
    } catch (e) {
      debugPrint('[TTS] Failed to speak: $e');
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    if (_flutterTts == null) return;
    
    try {
      await _flutterTts!.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('[TTS] Failed to stop: $e');
    }
  }

  /// Speak AI insight summary
  Future<void> speakInsight(String summary, String languageCode) async {
    await setLanguage(languageCode);
    await speak(summary);
  }

  /// Get available languages
  Future<List<String>> getAvailableLanguages() async {
    if (!_isInitialized) await initialize();
    
    try {
      final languages = await _flutterTts?.getLanguages;
      return List<String>.from(languages ?? []);
    } catch (e) {
      debugPrint('[TTS] Failed to get languages: $e');
      return [];
    }
  }

  void dispose() {
    _flutterTts?.stop();
  }
}
