import 'package:flutter/material.dart';
import '../models/stress_prediction.dart';
import '../utils/localization.dart';

/// Compact card showing AI stress prediction summary for the dashboard
class StressPredictionCard extends StatelessWidget {
  final StressPrediction? prediction;
  final bool isLoading;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;
  final VoidCallback? onVoiceToggle;
  final bool isVoicePlaying;
  final String languageCode;

  const StressPredictionCard({
    super.key,
    this.prediction,
    this.isLoading = false,
    this.onTap,
    this.onRefresh,
    this.onVoiceToggle,
    this.isVoicePlaying = false,
    this.languageCode = 'en',
  });

  String _t(String key) => AppLocalizations.get(key, languageCode);

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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(isDark),
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _getRiskColor().withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: isLoading ? _buildLoadingState() : _buildContent(isDark),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Row(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white70,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          _t('analyzing_stress_levels'),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark) {
    if (prediction == null) {
      return Row(
        children: [
          Icon(Icons.psychology, color: Colors.white.withValues(alpha: 0.7), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _t('tap_run_stress_prediction'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.5), size: 16),
        ],
      );
    }

    final pred = prediction!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getRiskIcon(),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        _t('ai_stress_prediction'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _localizedRiskLabel(pred.overallRisk),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pred.predictedStressType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: true,
                  ),
                ],
              ),
            ),
            if (onRefresh != null)
              IconButton(
                onPressed: onRefresh,
                icon: Icon(Icons.refresh, color: Colors.white.withValues(alpha: 0.7)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (onVoiceToggle != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onVoiceToggle,
                icon: Icon(
                  isVoicePlaying ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                tooltip: _t('speak_prediction'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Confidence & time-to-stress row
        Row(
          children: [
            _buildInfoChip(Icons.speed, pred.confidencePercent),
            const SizedBox(width: 12),
            if (pred.overallRisk != StressRiskLevel.low)
              _buildInfoChip(Icons.timer, pred.timeToStress),
          ],
        ),
        const SizedBox(height: 8),

        // Recommendation
        Text(
          pred.recommendation,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        // Tap hint
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              _t('tap_for_details'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.5), size: 12),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getRiskColor() {
    if (prediction == null) return Colors.blueGrey;
    switch (prediction!.overallRisk) {
      case StressRiskLevel.low:
        return const Color(0xFF2E7D32);
      case StressRiskLevel.medium:
        return const Color(0xFFF57F17);
      case StressRiskLevel.high:
        return const Color(0xFFE65100);
      case StressRiskLevel.critical:
        return const Color(0xFFB71C1C);
    }
  }

  IconData _getRiskIcon() {
    if (prediction == null) return Icons.psychology;
    switch (prediction!.overallRisk) {
      case StressRiskLevel.low:
        return Icons.check_circle_outline;
      case StressRiskLevel.medium:
        return Icons.warning_amber;
      case StressRiskLevel.high:
        return Icons.error_outline;
      case StressRiskLevel.critical:
        return Icons.dangerous;
    }
  }

  List<Color> _getGradientColors(bool isDark) {
    if (prediction == null) {
      return isDark
          ? [const Color(0xFF37474F), const Color(0xFF263238)]
          : [const Color(0xFF546E7A), const Color(0xFF37474F)];
    }
    switch (prediction!.overallRisk) {
      case StressRiskLevel.low:
        return [const Color(0xFF388E3C), const Color(0xFF1B5E20)];
      case StressRiskLevel.medium:
        return [const Color(0xFFF9A825), const Color(0xFFF57F17)];
      case StressRiskLevel.high:
        return [const Color(0xFFE65100), const Color(0xFFBF360C)];
      case StressRiskLevel.critical:
        return [const Color(0xFFC62828), const Color(0xFFB71C1C)];
    }
  }
}
