class SensorData {
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final bool pumpStatus;
  final int? heartbeat;
  final DateTime timestamp;
  final String? deviceId;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    this.pumpStatus = false,
    this.heartbeat,
    required this.timestamp,
    this.deviceId,
  });

  /// Parse from new Firebase structure:
  /// live: { timestamp, dht22: {temperature, humidity}, soilMoisture, pumpStatus }
  factory SensorData.fromLiveMap(Map<dynamic, dynamic> map, {String? deviceId}) {
    final dhtData = map['dht22'] as Map<dynamic, dynamic>?;
    
    // PRIORITY: Root keys first, then dht22 nested keys
    final temp = map['temperature'] ?? map['Temperature'] ?? map['temp'] ?? map['Temp'] ?? dhtData?['temperature'] ?? dhtData?['temp'] ?? 0;
    final hum = map['humidity'] ?? map['Humidity'] ?? map['hum'] ?? map['Hum'] ?? dhtData?['humidity'] ?? dhtData?['hum'] ?? 0;
    final moisture = map['soilMoisture'] ?? map['SoilMoisture'] ?? map['moisture'] ?? map['Moisture'] ?? 0;
    final pump = map['pumpStatus'] ?? map['PumpStatus'] ?? map['pump'] ?? false;
    final heartbeat = map['heartbeat'] ?? map['heartBeat'] ?? map['hb'] ?? map['status'] ?? 0;
    final ts = map['timestamp'] ?? map['ts'] ?? map['time'];

    return SensorData(
      temperature: _toDouble(temp),
      humidity: _toDouble(hum),
      soilMoisture: _toDouble(moisture),
      pumpStatus: pump is bool ? pump : pump.toString().toLowerCase() == 'true' || pump == 1,
      heartbeat: heartbeat is int ? heartbeat : int.tryParse(heartbeat.toString()) ?? 0,
      timestamp: ts != null ? DateTime.fromMillisecondsSinceEpoch(ts is int ? ts : int.tryParse(ts.toString()) ?? DateTime.now().millisecondsSinceEpoch) : DateTime.now(),
      deviceId: deviceId,
    );
  }

  /// Parse from history record structure:
  /// /{hh:mm}: { dht22: {temperature, humidity}, soilMoisture }
  factory SensorData.fromHistoryRecord(String timeKey, String dateKey, Map<dynamic, dynamic> map, {String? deviceId}) {
    final dhtData = map['dht22'] as Map<dynamic, dynamic>?;
    
    final temp = dhtData?['temperature'] ?? map['temperature'] ?? 0;
    final hum = dhtData?['humidity'] ?? map['humidity'] ?? 0;
    final moisture = map['soilMoisture'] ?? map['SoilMoisture'] ?? 0;

    // Parse date from dd-mm-yyyy and time from hh:mm
    DateTime parsedTimestamp = DateTime.now();
    try {
      final dateParts = dateKey.split('-');
      final timeParts = timeKey.split(':');
      if (dateParts.length == 3 && timeParts.length >= 2) {
        final day = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final year = int.parse(dateParts[2]);
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        parsedTimestamp = DateTime(year, month, day, hour, minute);
      }
    } catch (_) {
      // Fallback to now
    }

    return SensorData(
      temperature: _toDouble(temp),
      humidity: _toDouble(hum),
      soilMoisture: _toDouble(moisture),
      timestamp: parsedTimestamp,
      deviceId: deviceId,
    );
  }

  /// Legacy fromMap for backward compatibility
  factory SensorData.fromMap(Map<dynamic, dynamic> map, {String? deviceId}) {
    return SensorData.fromLiveMap(map, deviceId: deviceId);
  }

  /// Parse from dailyAvg node
  factory SensorData.fromDailyAvg(String dateKey, Map<dynamic, dynamic> map, {String? deviceId}) {
    final temp = map['temperature'] ?? 0;
    final hum = map['humidity'] ?? 0;
    final moisture = map['soilMoisture'] ?? 0;

    DateTime parsedDate = DateTime.now();
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        parsedDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (_) {}

    return SensorData(
      temperature: _toDouble(temp),
      humidity: _toDouble(hum),
      soilMoisture: _toDouble(moisture),
      timestamp: parsedDate,
      deviceId: deviceId,
    );
  }

  static double _toDouble(dynamic val) {
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'soilMoisture': soilMoisture,
      'pumpStatus': pumpStatus,
      'timestamp': timestamp.millisecondsSinceEpoch,
      if (deviceId != null) 'deviceId': deviceId,
    };
  }

  /// Convert to the new live structure for writing
  Map<String, dynamic> toLiveMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'dht22': {
        'temperature': temperature,
        'humidity': humidity,
      },
      'soilMoisture': soilMoisture,
      'pumpStatus': pumpStatus,
    };
  }

  // Get crop stress level based on sensor values
  CropStressLevel get stressLevel {
    int stressPoints = 0;
    
    // Temperature stress (optimal: 20-30°C)
    if (temperature < 15 || temperature > 35) {
      stressPoints += 2;
    } else if (temperature < 18 || temperature > 32) {
      stressPoints += 1;
    }
    
    // Humidity stress (optimal: 40-70%)
    if (humidity < 30 || humidity > 85) {
      stressPoints += 2;
    } else if (humidity < 35 || humidity > 80) {
      stressPoints += 1;
    }
    
    // Soil moisture stress (optimal: 40-70%)
    if (soilMoisture < 25 || soilMoisture > 85) {
      stressPoints += 3;
    } else if (soilMoisture < 35 || soilMoisture > 75) {
      stressPoints += 2;
    } else if (soilMoisture < 40 || soilMoisture > 70) {
      stressPoints += 1;
    }
    
    if (stressPoints >= 5) return CropStressLevel.critical;
    if (stressPoints >= 3) return CropStressLevel.high;
    if (stressPoints >= 1) return CropStressLevel.moderate;
    return CropStressLevel.healthy;
  }

  String get temperatureStatus {
    if (temperature < 15) return 'Too Cold';
    if (temperature > 35) return 'Too Hot';
    if (temperature < 20 || temperature > 30) return 'Suboptimal';
    return 'Optimal';
  }

  String get humidityStatus {
    if (humidity < 30) return 'Very Dry';
    if (humidity > 85) return 'Too Humid';
    if (humidity < 40 || humidity > 70) return 'Suboptimal';
    return 'Optimal';
  }

  String get soilMoistureStatus {
    if (soilMoisture < 25) return 'Critical - Irrigate Now';
    if (soilMoisture < 40) return 'Low - Needs Water';
    if (soilMoisture > 85) return 'Waterlogged';
    if (soilMoisture > 70) return 'High';
    return 'Optimal';
  }

  bool get needsIrrigation => soilMoisture < 40;
  bool get isWaterlogged => soilMoisture > 85;
}

enum CropStressLevel {
  healthy,
  moderate,
  high,
  critical,
}

extension CropStressLevelExtension on CropStressLevel {
  String get label {
    switch (this) {
      case CropStressLevel.healthy:
        return 'Healthy';
      case CropStressLevel.moderate:
        return 'Moderate Stress';
      case CropStressLevel.high:
        return 'High Stress';
      case CropStressLevel.critical:
        return 'Critical';
    }
  }

  String get description {
    switch (this) {
      case CropStressLevel.healthy:
        return 'Your crops are in optimal condition';
      case CropStressLevel.moderate:
        return 'Minor adjustments may improve growth';
      case CropStressLevel.high:
        return 'Immediate attention recommended';
      case CropStressLevel.critical:
        return 'Take action immediately to prevent crop damage';
    }
  }
}
