enum AlertType {
  lowMoisture,
  highMoisture,
  highTemperature,
  lowTemperature,
  highHumidity,
  lowHumidity,
  deviceOffline,
  pumpActivated,
  pumpDeactivated,
  criticalStress,
}

enum AlertSeverity {
  info,
  warning,
  critical,
}

class Alert {
  final String id;
  final String fieldId;
  final String fieldName;
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final double? value;
  final double? threshold;
  final DateTime timestamp;
  final bool isRead;
  final bool isResolved;
  
  // Extra sensor data for consolidated notifications
  final double? currentTemp;
  final double? currentHumidity;
  final double? currentMoisture;

  Alert({
    required this.id,
    required this.fieldId,
    required this.fieldName,
    required this.type,
    required this.severity,
    required this.message,
    this.value,
    this.threshold,
    required this.timestamp,
    this.isRead = false,
    this.isResolved = false,
    this.currentTemp,
    this.currentHumidity,
    this.currentMoisture,
  });

  factory Alert.fromMap(String id, Map<dynamic, dynamic> map) {
    return Alert(
      id: id,
      fieldId: map['fieldId'] ?? '',
      fieldName: map['fieldName'] ?? 'Unknown',
      type: AlertType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AlertType.criticalStress,
      ),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => AlertSeverity.warning,
      ),
      message: map['message'] ?? '',
      value: map['value']?.toDouble(),
      threshold: map['threshold']?.toDouble(),
      timestamp: map['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      isResolved: map['isResolved'] ?? false,
      currentTemp: map['currentTemp']?.toDouble(),
      currentHumidity: map['currentHumidity']?.toDouble(),
      currentMoisture: map['currentMoisture']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fieldId': fieldId,
      'fieldName': fieldName,
      'type': type.name,
      'severity': severity.name,
      'message': message,
      if (value != null) 'value': value,
      if (threshold != null) 'threshold': threshold,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'isResolved': isResolved,
      if (currentTemp != null) 'currentTemp': currentTemp,
      if (currentHumidity != null) 'currentHumidity': currentHumidity,
      if (currentMoisture != null) 'currentMoisture': currentMoisture,
    };
  }

  String get icon {
    switch (type) {
      case AlertType.lowMoisture:
        return '💧';
      case AlertType.highMoisture:
        return '🌊';
      case AlertType.highTemperature:
        return '🔥';
      case AlertType.lowTemperature:
        return '❄️';
      case AlertType.highHumidity:
        return '💨';
      case AlertType.lowHumidity:
        return '🏜️';
      case AlertType.deviceOffline:
        return '📡';
      case AlertType.pumpActivated:
        return '💦';
      case AlertType.pumpDeactivated:
        return '⏹️';
      case AlertType.criticalStress:
        return '⚠️';
    }
  }

  String get title {
    switch (type) {
      case AlertType.lowMoisture:
        return 'Low Soil Moisture';
      case AlertType.highMoisture:
        return 'High Soil Moisture';
      case AlertType.highTemperature:
        return 'High Temperature';
      case AlertType.lowTemperature:
        return 'Low Temperature';
      case AlertType.highHumidity:
        return 'High Humidity';
      case AlertType.lowHumidity:
        return 'Low Humidity';
      case AlertType.deviceOffline:
        return 'Device Offline';
      case AlertType.pumpActivated:
        return 'Pump Activated';
      case AlertType.pumpDeactivated:
        return 'Pump Deactivated';
      case AlertType.criticalStress:
        return 'Critical Crop Stress';
    }
  }

  Alert copyWith({
    bool? isRead,
    bool? isResolved,
  }) {
    return Alert(
      id: id,
      fieldId: fieldId,
      fieldName: fieldName,
      type: type,
      severity: severity,
      message: message,
      value: value,
      threshold: threshold,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      isResolved: isResolved ?? this.isResolved,
      currentTemp: currentTemp,
      currentHumidity: currentHumidity,
      currentMoisture: currentMoisture,
    );
  }
}
