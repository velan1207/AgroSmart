/// AI-based Stress Prediction model
/// Represents a structured prediction of future crop stress

enum StressRiskLevel {
  low,
  medium,
  high,
  critical,
}

extension StressRiskLevelExtension on StressRiskLevel {
  String get label {
    switch (this) {
      case StressRiskLevel.low:
        return 'Low Risk';
      case StressRiskLevel.medium:
        return 'Medium Risk';
      case StressRiskLevel.high:
        return 'High Risk';
      case StressRiskLevel.critical:
        return 'Critical Risk';
    }
  }

  String get emoji {
    switch (this) {
      case StressRiskLevel.low:
        return '🟢';
      case StressRiskLevel.medium:
        return '🟡';
      case StressRiskLevel.high:
        return '🟠';
      case StressRiskLevel.critical:
        return '🔴';
    }
  }

  double get numericValue {
    switch (this) {
      case StressRiskLevel.low:
        return 0.25;
      case StressRiskLevel.medium:
        return 0.5;
      case StressRiskLevel.high:
        return 0.75;
      case StressRiskLevel.critical:
        return 1.0;
    }
  }
}

class ContributingFactor {
  final String name;
  final String description;
  final double severity; // 0.0 to 1.0
  final String currentValue;
  final String optimalRange;

  ContributingFactor({
    required this.name,
    required this.description,
    required this.severity,
    required this.currentValue,
    required this.optimalRange,
  });
}

class StressPrediction {
  final StressRiskLevel overallRisk;
  final String predictedStressType;
  final double confidence; // 0.0 to 1.0 (e.g., 0.85 = 85%)
  final String timeToStress; // e.g., "6 hours", "2 days"
  final String recommendation;
  final String detailedAnalysis;
  final List<ContributingFactor> contributingFactors;
  final DateTime timestamp;
  final String cropType;
  final String fieldName;

  StressPrediction({
    required this.overallRisk,
    required this.predictedStressType,
    required this.confidence,
    required this.timeToStress,
    required this.recommendation,
    required this.detailedAnalysis,
    required this.contributingFactors,
    required this.timestamp,
    required this.cropType,
    required this.fieldName,
  });

  String get confidencePercent => '${(confidence * 100).toInt()}%';

  String get summaryText {
    if (overallRisk == StressRiskLevel.low) {
      return 'Your $cropType crops are in good condition. No immediate stress predicted.';
    }
    return '$predictedStressType predicted within $timeToStress with $confidencePercent confidence. $recommendation';
  }
}
