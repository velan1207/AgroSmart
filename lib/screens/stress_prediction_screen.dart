import 'package:flutter/material.dart';

import '../models/stress_prediction.dart';
import '../services/tts_service.dart';
import '../utils/localization.dart';

/// Full-screen view for AI stress prediction details.
class StressPredictionScreen extends StatefulWidget {
  final StressPrediction prediction;
  final String languageCode;

  const StressPredictionScreen({
    super.key,
    required this.prediction,
    this.languageCode = 'en',
  });

  @override
  State<StressPredictionScreen> createState() => _StressPredictionScreenState();
}

class _StressPredictionScreenState extends State<StressPredictionScreen> {
  bool _isVoicePlaying = false;

  StressPrediction get _prediction => widget.prediction;
  String get _languageCode => widget.languageCode;

  String _t(String key) => AppLocalizations.get(key, _languageCode);

  String _localizedRiskLabel(StressRiskLevel risk) {
    switch (risk) {
      case StressRiskLevel.low:
        return _t('low_risk');
      case StressRiskLevel.medium:
        return _t('medium_risk');
      case StressRiskLevel.high:
        return _t('high_risk');
      case StressRiskLevel.critical:
        return _t('critical_risk');
    }
  }

  @override
  void dispose() {
    // Stop any active speech when closing the details page.
    TTSService().stop();
    super.dispose();
  }

  Future<void> _toggleSpeakPrediction() async {
    final tts = TTSService();

    if (_isVoicePlaying || tts.isSpeaking) {
      await tts.stop();
      if (mounted) {
        setState(() => _isVoicePlaying = false);
      }
      return;
    }

    final summary = _languageCode == 'ta'
        ? '${_prediction.predictedStressType}. ${_prediction.recommendation}. ${_prediction.detailedAnalysis}'
        : (_languageCode == 'hi'
            ? '${_prediction.predictedStressType}. ${_prediction.recommendation}. ${_prediction.detailedAnalysis}'
            : _prediction.summaryText);

    await tts.speakStressPrediction(summary, _languageCode);

    if (!tts.isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _languageCode == 'ta'
                  ? 'இந்த சாதனத்தில் குரல் வெளியீடு ஆதரிக்கப்படவில்லை.'
                  : (_languageCode == 'hi'
                      ? 'इस डिवाइस पर वॉइस आउटपुट समर्थित नहीं है।'
                      : 'Voice output is not supported on this device.'),
            ),
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _isVoicePlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final risk = _prediction.overallRisk;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _t('stress_prediction'),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isVoicePlaying ? Icons.volume_off : Icons.volume_up,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                onPressed: _toggleSpeakPrediction,
                tooltip: _t('speak_prediction'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildRiskCard(isDark, risk),
                  const SizedBox(height: 16),
                  _buildRecommendationCard(isDark),
                  const SizedBox(height: 16),
                  if (_prediction.contributingFactors.isNotEmpty) ...[
                    _buildFactorsCard(isDark),
                    const SizedBox(height: 16),
                  ],
                  _buildAnalysisCard(isDark),
                  const SizedBox(height: 16),
                  _buildActionButtons(isDark),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskCard(bool isDark, StressRiskLevel risk) {
    final riskColor = _getRiskColor(risk);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getRiskIcon(risk), color: riskColor, size: 24),
              const SizedBox(width: 8),
              Text(
                _localizedRiskLabel(risk),
                style: TextStyle(
                  color: riskColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _prediction.predictedStressType,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildChip(
                isDark,
                Icons.speed,
                _t('confidence'),
                _prediction.confidencePercent,
              ),
              _buildChip(
                isDark,
                Icons.timer,
                _t('time_to_stress'),
                _prediction.timeToStress,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    bool isDark,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.white70 : Colors.black54),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label: $value',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                _t('recommendation'),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _prediction.recommendation,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorsCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.blue.shade400, size: 20),
              const SizedBox(width: 8),
              Text(
                _t('contributing_factors'),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._prediction.contributingFactors.map((factor) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    factor.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    factor.description,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: Colors.purple.shade300, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.get('detailed_analysis', _languageCode),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _prediction.detailedAnalysis,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${AppLocalizations.get('crop', _languageCode)}: ${_prediction.cropType}  •  ${AppLocalizations.get('field_name', _languageCode)}: ${_prediction.fieldName}',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _toggleSpeakPrediction,
            icon: Icon(_isVoicePlaying ? Icons.volume_off : Icons.volume_up, size: 18),
            label: Text(_t('speak_prediction')),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(AppLocalizations.get('back', _languageCode)),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getRiskColor(StressRiskLevel risk) {
    switch (risk) {
      case StressRiskLevel.low:
        return const Color(0xFF4CAF50);
      case StressRiskLevel.medium:
        return const Color(0xFFFFC107);
      case StressRiskLevel.high:
        return const Color(0xFFFF5722);
      case StressRiskLevel.critical:
        return const Color(0xFFF44336);
    }
  }

  IconData _getRiskIcon(StressRiskLevel risk) {
    switch (risk) {
      case StressRiskLevel.low:
        return Icons.check_circle;
      case StressRiskLevel.medium:
        return Icons.warning_amber;
      case StressRiskLevel.high:
        return Icons.error;
      case StressRiskLevel.critical:
        return Icons.dangerous;
    }
  }
}
