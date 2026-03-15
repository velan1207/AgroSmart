import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_insights_card.dart';
import '../services/ai_service.dart';
import '../services/tts_service.dart';
import '../models/models.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  AIInsight? _aiInsight;
  bool _isLoadingInsight = false;
  bool _isRefreshingForLanguageChange = false;

  @override
  void dispose() {
    // Stop audio when leaving the screen
    TTSService().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer2<FieldProvider, SettingsProvider>(
      builder: (context, fieldProvider, settingsProvider, _) {
        final field = fieldProvider.selectedField;
        final sensorData = fieldProvider.currentSensorData;
        final lang = settingsProvider.languageCode;
        final hasStaleInsight = _aiInsight != null && _aiInsight!.languageCode != lang;

        if (hasStaleInsight && !_isLoadingInsight && !_isRefreshingForLanguageChange && field != null && sensorData != null) {
          _isRefreshingForLanguageChange = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            _requestAIInsight(sensorData, field, lang, fieldProvider).whenComplete(() {
              _isRefreshingForLanguageChange = false;
            });
          });
        }

        return Scaffold(
          backgroundColor: Colors.transparent, // Handled by HomeScreen background
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settingsProvider.tr('ai_insights'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                const SizedBox(height: 8),
                Text(
                  lang == 'ta' 
                    ? 'உங்கள் பயிர்களுக்கான AI விவசாய நிபுணர் ஆலோசனை'
                    : lang == 'hi'
                      ? 'आपकी फसलों के लिए AI कृषि विशेषज्ञ की सलाह'
                      : 'AI-powered expert advice for your crops',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: -0.1),
                const SizedBox(height: 24),
                
                if (field == null) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Text(
                        lang == 'ta'
                            ? 'AI ஆலோசனைகளை பெற ஒரு வயலைத் தேர்ந்தெடுக்கவும்'
                            : lang == 'hi'
                                ? 'AI सलाह पाने के लिए एक खेत चुनें'
                                : 'Select a field to get AI insights',
                        style: TextStyle(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  AIInsightsCard(
                    insight: hasStaleInsight ? null : _aiInsight,
                    isLoading: _isLoadingInsight || hasStaleInsight,
                    languageCode: lang,
                    isPlayingAudio: TTSService().isSpeaking,
                    onRequestInsight: () => _requestAIInsight(sensorData, field, lang, fieldProvider),
                    onPlayAudio: !hasStaleInsight && _aiInsight != null ? () => _toggleAudioPlayback(lang) : null,
                  ),
                  const SizedBox(height: 24),
                  
                  // Educational Note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (isDark ? AppTheme.info.withOpacity(0.05) : Colors.blue.shade50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.info.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.info, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            lang == 'ta'
                              ? 'ஒவ்வொரு முறையும் நீங்கள் இந்த பட்டனை அழுத்தும்போது புதிய AI ஆலோசனை கிடைக்கும்.'
                              : lang == 'hi'
                                ? 'हर बार जब आप इस बटन को दबाते हैं, तो नई AI सलाह प्राप्त होती है।'
                                : 'A new AI insight is generated every time you request one based on real-time sensor data.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _requestAIInsight(SensorData? sensorData, Field? field, String languageCode, FieldProvider provider) async {
    if (sensorData == null || field == null) return;

    if (TTSService().isSpeaking) {
      await TTSService().stop();
    }

    setState(() {
      _isLoadingInsight = true;
      _aiInsight = null;
    });

    try {
      final aiService = AIService();
      aiService.configure('AIzaSyDtr04mzTqzdCN0EMasaUo4L00pJue5jx4');
      
      final history = await provider.getHistoricalData(
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        endDate: DateTime.now(),
      );
      
      final insight = await aiService.getAgriculturalInsights(
        sensorData: sensorData,
        field: field,
        languageCode: languageCode,
        history: history,
      );

      setState(() {
        _aiInsight = insight;
        _isLoadingInsight = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingInsight = false;
      });
    }
  }

  Future<void> _toggleAudioPlayback(String lang) async {
    final tts = TTSService();
    
    if (tts.isSpeaking) {
      await tts.stop();
    } else if (_aiInsight != null) {
      final textToSpeak = _aiInsight!.riskIntroduction ?? _aiInsight!.summary;
      await tts.speakInsight(textToSpeak, lang);
    }
    
    setState(() {});
  }
}
