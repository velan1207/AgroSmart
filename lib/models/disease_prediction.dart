/// Disease prediction model for crop disease forecasting
class DiseasePrediction {
  final String diseaseName;
  final String diseaseNameLocal; // Localized name
  final DiseaseRiskLevel riskLevel;
  final String reason;
  final String symptoms;
  final String causes;
  final String prevention;
  final String treatment;
  final String youtubeVideoId;
  final String youtubeSearchQuery;
  final DateTime timestamp;
  final String languageCode;

  const DiseasePrediction({
    required this.diseaseName,
    required this.diseaseNameLocal,
    required this.riskLevel,
    required this.reason,
    required this.symptoms,
    required this.causes,
    required this.prevention,
    required this.treatment,
    required this.youtubeVideoId,
    required this.youtubeSearchQuery,
    required this.timestamp,
    required this.languageCode,
  });

  /// Get the YouTube video URL
  String get youtubeVideoUrl => youtubeVideoId.isNotEmpty
      ? 'https://www.youtube.com/watch?v=$youtubeVideoId'
      : '';

  /// Get the YouTube embed URL for WebView
  String get youtubeEmbedUrl => youtubeVideoId.isNotEmpty
      ? 'https://www.youtube.com/embed/$youtubeVideoId'
      : '';

  /// Get the YouTube search URL
  String get youtubeSearchUrl =>
      'https://www.youtube.com/results?search_query=${Uri.encodeComponent(youtubeSearchQuery)}';

  /// Get risk level color hex
  int get riskColorHex {
    switch (riskLevel) {
      case DiseaseRiskLevel.low:
        return 0xFF4CAF50; // Green
      case DiseaseRiskLevel.medium:
        return 0xFFFF9800; // Orange
      case DiseaseRiskLevel.high:
        return 0xFFF44336; // Red
    }
  }

  /// Create from JSON
  factory DiseasePrediction.fromJson(
    Map<String, dynamic> json,
    String languageCode,
  ) {
    return DiseasePrediction(
      diseaseName: json['diseaseName'] ?? 'Unknown Disease',
      diseaseNameLocal: json['diseaseNameLocal'] ?? json['diseaseName'] ?? 'Unknown',
      riskLevel: _parseRiskLevel(json['riskLevel']),
      reason: json['reason'] ?? '',
      symptoms: json['symptoms'] ?? '',
      causes: json['causes'] ?? '',
      prevention: json['prevention'] ?? '',
      treatment: json['treatment'] ?? '',
      youtubeVideoId: json['youtubeVideoId'] ?? '',
      youtubeSearchQuery: json['youtubeSearchQuery'] ?? '',
      timestamp: DateTime.now(),
      languageCode: languageCode,
    );
  }

  static DiseaseRiskLevel _parseRiskLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'high':
        return DiseaseRiskLevel.high;
      case 'medium':
        return DiseaseRiskLevel.medium;
      case 'low':
      default:
        return DiseaseRiskLevel.low;
    }
  }
}

/// Disease risk level enum
enum DiseaseRiskLevel {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case DiseaseRiskLevel.low:
        return 'Low Risk';
      case DiseaseRiskLevel.medium:
        return 'Medium Risk';
      case DiseaseRiskLevel.high:
        return 'High Risk';
    }
  }

  String localizedLabel(String langCode) {
    switch (this) {
      case DiseaseRiskLevel.low:
        if (langCode == 'ta') return 'குறைந்த ஆபத்து';
        if (langCode == 'hi') return 'कम जोखिम';
        return 'Low Risk';
      case DiseaseRiskLevel.medium:
        if (langCode == 'ta') return 'நடுத்தர ஆபத்து';
        if (langCode == 'hi') return 'मध्यम जोखिम';
        return 'Medium Risk';
      case DiseaseRiskLevel.high:
        if (langCode == 'ta') return 'அதிக ஆபத்து';
        if (langCode == 'hi') return 'उच्च जोखिम';
        return 'High Risk';
    }
  }
}

/// Disease prediction result containing multiple predictions
class DiseasePredictionResult {
  final List<DiseasePrediction> predictions;
  final String overallAssessment;
  final String fieldName;
  final String cropType;
  final DateTime timestamp;
  final String languageCode;
  final bool isError;
  final String? errorMessage;

  const DiseasePredictionResult({
    required this.predictions,
    required this.overallAssessment,
    required this.fieldName,
    required this.cropType,
    required this.timestamp,
    required this.languageCode,
    this.isError = false,
    this.errorMessage,
  });

  /// Create error result
  factory DiseasePredictionResult.error(String message, String langCode) {
    return DiseasePredictionResult(
      predictions: [],
      overallAssessment: message,
      fieldName: '',
      cropType: '',
      timestamp: DateTime.now(),
      languageCode: langCode,
      isError: true,
      errorMessage: message,
    );
  }

  bool get hasPredictions => predictions.isNotEmpty;
  
  bool get hasHighRisk =>
      predictions.any((p) => p.riskLevel == DiseaseRiskLevel.high);
  
  bool get hasMediumRisk =>
      predictions.any((p) => p.riskLevel == DiseaseRiskLevel.medium);

  DiseaseRiskLevel get highestRiskLevel {
    if (hasHighRisk) return DiseaseRiskLevel.high;
    if (hasMediumRisk) return DiseaseRiskLevel.medium;
    return DiseaseRiskLevel.low;
  }
}
