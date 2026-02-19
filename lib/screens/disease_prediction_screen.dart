import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/ai_service.dart';
import '../utils/localization.dart';

/// Disease Prediction Screen - AI-powered crop disease forecasting
class DiseasePredictionScreen extends StatefulWidget {
  final Field field;

  const DiseasePredictionScreen({
    super.key,
    required this.field,
  });

  @override
  State<DiseasePredictionScreen> createState() => _DiseasePredictionScreenState();
}

class _DiseasePredictionScreenState extends State<DiseasePredictionScreen> {
  final AIService _aiService = AIService();
  DiseasePredictionResult? _result;
  bool _isLoading = false;
  String? _errorMessage;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadPrediction();
  }

  Future<void> _loadPrediction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fieldProvider = context.read<FieldProvider>();
      final settings = context.read<SettingsProvider>();
      final sensorData = fieldProvider.currentSensorData;

      if (sensorData == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getErrorMessage('no_sensor_data', settings.languageCode);
        });
        return;
      }

      // Get historical data if available
      List<SensorData>? history;
      try {
        history = await fieldProvider.getHistoricalData(
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
        );
      } catch (e) {
        // Continue without history
      }

      final result = await _aiService.predictDiseases(
        sensorData: sensorData,
        field: widget.field,
        languageCode: settings.languageCode,
        history: history,
      );

      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final settings = context.read<SettingsProvider>();
        setState(() {
          _isLoading = false;
          _errorMessage = _getErrorMessage('prediction_failed', settings.languageCode);
        });
      }
    }
  }

  String _getErrorMessage(String key, String langCode) {
    final messages = {
      'no_sensor_data': {
        'en': 'No sensor data available. Please check your device connection.',
        'ta': 'சென்சார் தரவு இல்லை. உங்கள் சாதன இணைப்பை சரிபார்க்கவும்.',
        'hi': 'सेंसर डेटा उपलब्ध नहीं है। अपने डिवाइस कनेक्शन की जांच करें।',
      },
      'prediction_failed': {
        'en': 'Unable to predict diseases. Please try again later.',
        'ta': 'நோய்களை கணிக்க இயலவில்லை. பின்னர் மீண்டும் முயற்சிக்கவும்.',
        'hi': 'बीमारियों का अनुमान लगाने में असमर्थ। बाद में पुन: प्रयास करें।',
      },
      'video_unavailable': {
        'en': 'Video not available. Search YouTube for more videos.',
        'ta': 'வீடியோ கிடைக்கவில்லை. மேலும் வீடியோக்களுக்கு YouTube-ல் தேடவும்.',
        'hi': 'वीडियो उपलब्ध नहीं है। अधिक वीडियो के लिए YouTube पर खोजें।',
      },
    };
    return messages[key]?[langCode] ?? messages[key]?['en'] ?? 'An error occurred';
  }

  Future<void> _openYouTubeSearch(String query) async {
    final url = 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage('video_unavailable', 
                context.read<SettingsProvider>().languageCode)),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppTheme.backgroundDark, const Color(0xFF142018), AppTheme.backgroundDark]
                : [AppTheme.backgroundLight, const Color(0xFFE8F3ED), AppTheme.backgroundLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark, settings),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState(isDark, settings)
                    : _errorMessage != null
                        ? _buildErrorState(isDark, settings)
                        : _result != null
                            ? _buildPredictionContent(isDark, settings)
                            : _buildEmptyState(isDark, settings),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.get('disease_prediction', settings.languageCode),
                  style: TextStyle(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.field.name,
                  style: TextStyle(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadPrediction,
            icon: Icon(
              Icons.refresh,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildLoadingState(bool isDark, SettingsProvider settings) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.get('analyzing_field', settings.languageCode),
            style: TextStyle(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.get('ai_analyzing', settings.languageCode),
            style: TextStyle(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildErrorState(bool isDark, SettingsProvider settings) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppTheme.error,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.get('error_occurred', settings.languageCode),
              style: TextStyle(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              style: TextStyle(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPrediction,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.get('try_again', settings.languageCode)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildEmptyState(bool isDark, SettingsProvider settings) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.health_and_safety,
            size: 64,
            color: AppTheme.primaryGreen.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.get('no_predictions', settings.languageCode),
            style: TextStyle(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionContent(bool isDark, SettingsProvider settings) {
    return RefreshIndicator(
      onRefresh: _loadPrediction,
      color: AppTheme.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Assessment Card
            _buildOverallAssessmentCard(isDark, settings),
            const SizedBox(height: 16),

            // Risk Summary
            _buildRiskSummary(isDark, settings),
            const SizedBox(height: 20),

            // Disease Cards
            Text(
              AppLocalizations.get('predicted_diseases', settings.languageCode),
              style: TextStyle(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ..._result!.predictions.asMap().entries.map((entry) {
              return _buildDiseaseCard(entry.key, entry.value, isDark, settings);
            }),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallAssessmentCard(bool isDark, SettingsProvider settings) {
    final highestRisk = _result!.highestRiskLevel;
    final riskColor = Color(_result!.predictions.isNotEmpty 
        ? _result!.predictions.first.riskColorHex 
        : 0xFF4CAF50);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [riskColor, riskColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: riskColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getRiskIcon(highestRisk),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      highestRisk.localizedLabel(settings.languageCode),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.field.cropType} - ${widget.field.name}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _result!.overallAssessment,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildRiskSummary(bool isDark, SettingsProvider settings) {
    final highCount = _result!.predictions.where((p) => p.riskLevel == DiseaseRiskLevel.high).length;
    final mediumCount = _result!.predictions.where((p) => p.riskLevel == DiseaseRiskLevel.medium).length;
    final lowCount = _result!.predictions.where((p) => p.riskLevel == DiseaseRiskLevel.low).length;

    return Row(
      children: [
        _buildRiskBadge(highCount, DiseaseRiskLevel.high, isDark, settings),
        const SizedBox(width: 12),
        _buildRiskBadge(mediumCount, DiseaseRiskLevel.medium, isDark, settings),
        const SizedBox(width: 12),
        _buildRiskBadge(lowCount, DiseaseRiskLevel.low, isDark, settings),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _buildRiskBadge(int count, DiseaseRiskLevel level, bool isDark, SettingsProvider settings) {
    final color = Color(DiseasePrediction(
      diseaseName: '',
      diseaseNameLocal: '',
      riskLevel: level,
      reason: '',
      symptoms: '',
      causes: '',
      prevention: '',
      treatment: '',
      youtubeVideoId: '',
      youtubeSearchQuery: '',
      timestamp: DateTime.now(),
      languageCode: settings.languageCode,
    ).riskColorHex);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              level.localizedLabel(settings.languageCode),
              style: TextStyle(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseCard(int index, DiseasePrediction disease, bool isDark, SettingsProvider settings) {
    final isExpanded = _expandedIndex == index;
    final riskColor = Color(disease.riskColorHex);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? riskColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header (always visible)
            InkWell(
              onTap: () {
                setState(() {
                  _expandedIndex = isExpanded ? -1 : index;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getDiseaseIcon(disease.diseaseName),
                        color: riskColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            disease.diseaseNameLocal,
                            style: TextStyle(
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: riskColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              disease.riskLevel.localizedLabel(settings.languageCode),
                              style: TextStyle(
                                color: riskColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Reason (always visible)
            if (!isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  disease.reason,
                  style: TextStyle(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Expanded content
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildExpandedContent(disease, isDark, settings),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 400.ms);
  }

  Widget _buildExpandedContent(DiseasePrediction disease, bool isDark, SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reason
          _buildInfoSection(
            title: AppLocalizations.get('reason', settings.languageCode),
            content: disease.reason,
            icon: Icons.info_outline,
            color: Colors.blue,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // Symptoms
          _buildInfoSection(
            title: AppLocalizations.get('symptoms', settings.languageCode),
            content: disease.symptoms,
            icon: Icons.visibility,
            color: Colors.orange,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // Causes
          _buildInfoSection(
            title: AppLocalizations.get('causes', settings.languageCode),
            content: disease.causes,
            icon: Icons.bug_report,
            color: Colors.red,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // Prevention
          _buildInfoSection(
            title: AppLocalizations.get('prevention', settings.languageCode),
            content: disease.prevention,
            icon: Icons.shield,
            color: Colors.green,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // Treatment
          _buildInfoSection(
            title: AppLocalizations.get('treatment', settings.languageCode),
            content: disease.treatment,
            icon: Icons.healing,
            color: Colors.purple,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // YouTube Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openYouTubeSearch(disease.youtubeSearchQuery),
              icon: const Icon(Icons.play_circle_fill, color: Colors.white),
              label: Text(
                AppLocalizations.get('watch_disease_video', settings.languageCode),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000), // YouTube red
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    if (content.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRiskIcon(DiseaseRiskLevel level) {
    switch (level) {
      case DiseaseRiskLevel.high:
        return Icons.warning_amber;
      case DiseaseRiskLevel.medium:
        return Icons.info;
      case DiseaseRiskLevel.low:
        return Icons.check_circle;
    }
  }

  IconData _getDiseaseIcon(String diseaseName) {
    final name = diseaseName.toLowerCase();
    if (name.contains('blight') || name.contains('fungal')) {
      return Icons.coronavirus;
    } else if (name.contains('wilt') || name.contains('stress')) {
      return Icons.water_drop;
    } else if (name.contains('pest') || name.contains('insect')) {
      return Icons.bug_report;
    } else if (name.contains('drought')) {
      return Icons.wb_sunny;
    }
    return Icons.local_florist;
  }
}
