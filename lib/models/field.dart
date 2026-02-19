import 'sensor_data.dart';

/// Represents a crop under a user in the new Firebase structure:
/// /users/{userId}/crops/{cropId}
class Field {
  final String id;        // cropId
  final String name;      // cropName (e.g., "Paddy", "Groundnut")
  final String cropType;  // alias for name, used across the app
  final String? fieldName; // field name (e.g., "Main Field", "North Plot")
  final String? location;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? plantingDate;
  final FieldSettings settings;
  SensorData? latestData;
  bool isPumpOn;

  Field({
    required this.id,
    required this.name,
    String? cropType,
    this.fieldName,
    this.location,
    this.imageUrl,
    this.createdAt,
    this.plantingDate,
    FieldSettings? settings,
    this.latestData,
    this.isPumpOn = false,
  }) : cropType = cropType ?? name,
       settings = settings ?? FieldSettings();

  /// Parse from the new Firebase structure:
  /// /users/{userId}/crops/{cropId}: { cropName, fieldName, live: {...}, ... }
  factory Field.fromMap(String id, Map<dynamic, dynamic> map) {
    final cropName = map['cropName'] ?? map['name'] ?? 'Unknown Crop';
    final fieldNameVal = map['fieldName'] ?? map['location'] ?? '';
    
    // Parse live data if present
    SensorData? liveData;
    bool pumpOn = false;
    if (map['live'] != null && map['live'] is Map) {
      final liveMap = map['live'] as Map<dynamic, dynamic>;
      liveData = SensorData.fromLiveMap(liveMap, deviceId: id);
      pumpOn = liveData.pumpStatus;
    }
    
    return Field(
      id: id,
      name: cropName.toString(),
      cropType: cropName.toString(),
      fieldName: fieldNameVal.toString().isNotEmpty ? fieldNameVal.toString() : null,
      location: fieldNameVal.toString().isNotEmpty ? fieldNameVal.toString() : map['location']?.toString(),
      imageUrl: map['imageUrl']?.toString(),
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
      plantingDate: map['plantingDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['plantingDate'])
          : null,
      settings: map['settings'] != null 
          ? FieldSettings.fromMap(map['settings'])
          : FieldSettings(),
      latestData: liveData,
      isPumpOn: pumpOn,
    );
  }

  /// Serialize to the new Firebase structure
  Map<String, dynamic> toMap() {
    return {
      'cropName': name,
      'fieldName': fieldName ?? location ?? '',
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (createdAt != null) 'createdAt': createdAt!.millisecondsSinceEpoch,
      if (plantingDate != null) 'plantingDate': plantingDate!.millisecondsSinceEpoch,
      if (settings != FieldSettings()) 'settings': settings.toMap(),
    };
  }

  String get displayName => fieldName != null && fieldName!.isNotEmpty
      ? '$name - $fieldName'
      : name;

  String get cropEmoji {
    switch ((cropType).toLowerCase()) {
      case 'paddy':
      case 'rice':
        return '🌾';
      case 'wheat':
        return '🌾';
      case 'groundnut':
      case 'peanut':
        return '🥜';
      case 'cotton':
        return '🌿';
      case 'sugarcane':
        return '🎋';
      case 'maize':
      case 'corn':
        return '🌽';
      case 'tomato':
        return '🍅';
      case 'potato':
        return '🥔';
      case 'onion':
        return '🧅';
      case 'chili':
      case 'chilli':
        return '🌶️';
      case 'mango':
        return '🥭';
      case 'banana':
        return '🍌';
      case 'coconut':
        return '🥥';
      case 'tea':
        return '🍵';
      case 'coffee':
        return '☕';
      default:
        return '🌱';
    }
  }
}

class FieldSettings {
  final double minMoisture;
  final double maxMoisture;
  final double minTemperature;
  final double maxTemperature;
  final double minHumidity;
  final double maxHumidity;
  final int samplingIntervalMinutes;
  final bool autoIrrigation;
  final String wifiSsid;
  final String wifiPassword;

  FieldSettings({
    this.minMoisture = 35.0,
    this.maxMoisture = 75.0,
    this.minTemperature = 18.0,
    this.maxTemperature = 32.0,
    this.minHumidity = 40.0,
    this.maxHumidity = 70.0,
    this.samplingIntervalMinutes = 5,
    this.autoIrrigation = false,
    this.wifiSsid = '',
    this.wifiPassword = '',
  });

  factory FieldSettings.fromMap(Map<dynamic, dynamic> map) {
    return FieldSettings(
      minMoisture: (map['minMoisture'] ?? 35.0).toDouble(),
      maxMoisture: (map['maxMoisture'] ?? 75.0).toDouble(),
      minTemperature: (map['minTemperature'] ?? 18.0).toDouble(),
      maxTemperature: (map['maxTemperature'] ?? 32.0).toDouble(),
      minHumidity: (map['minHumidity'] ?? 40.0).toDouble(),
      maxHumidity: (map['maxHumidity'] ?? 70.0).toDouble(),
      samplingIntervalMinutes: map['samplingIntervalMinutes'] ?? 5,
      autoIrrigation: map['autoIrrigation'] ?? false,
      wifiSsid: map['wifiSsid'] ?? '',
      wifiPassword: map['wifiPassword'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minMoisture': minMoisture,
      'maxMoisture': maxMoisture,
      'minTemperature': minTemperature,
      'maxTemperature': maxTemperature,
      'minHumidity': minHumidity,
      'maxHumidity': maxHumidity,
      'samplingIntervalMinutes': samplingIntervalMinutes,
      'autoIrrigation': autoIrrigation,
      'wifiSsid': wifiSsid,
      'wifiPassword': wifiPassword,
    };
  }

  FieldSettings copyWith({
    double? minMoisture,
    double? maxMoisture,
    double? minTemperature,
    double? maxTemperature,
    double? minHumidity,
    double? maxHumidity,
    int? samplingIntervalMinutes,
    bool? autoIrrigation,
    String? wifiSsid,
    String? wifiPassword,
  }) {
    return FieldSettings(
      minMoisture: minMoisture ?? this.minMoisture,
      maxMoisture: maxMoisture ?? this.maxMoisture,
      minTemperature: minTemperature ?? this.minTemperature,
      maxTemperature: maxTemperature ?? this.maxTemperature,
      minHumidity: minHumidity ?? this.minHumidity,
      maxHumidity: maxHumidity ?? this.maxHumidity,
      samplingIntervalMinutes: samplingIntervalMinutes ?? this.samplingIntervalMinutes,
      autoIrrigation: autoIrrigation ?? this.autoIrrigation,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      wifiPassword: wifiPassword ?? this.wifiPassword,
    );
  }
  static FieldSettings getDefaultSettings(String cropType) {
    switch (cropType.toLowerCase()) {
      case 'paddy':
        return FieldSettings(
          minMoisture: 45.0,
          maxMoisture: 85.0,
          minTemperature: 20.0,
          maxTemperature: 35.0,
          minHumidity: 60.0,
          maxHumidity: 85.0,
        );
      case 'wheat':
        return FieldSettings(
          minMoisture: 30.0,
          maxMoisture: 60.0,
          minTemperature: 15.0,
          maxTemperature: 28.0,
          minHumidity: 40.0,
          maxHumidity: 65.0,
        );
      case 'groundnut':
        return FieldSettings(
          minMoisture: 40.0,
          maxMoisture: 70.0,
          minTemperature: 22.0,
          maxTemperature: 32.0,
          minHumidity: 50.0,
          maxHumidity: 75.0,
        );
      case 'maize':
        return FieldSettings(
          minMoisture: 35.0,
          maxMoisture: 75.0,
          minTemperature: 18.0,
          maxTemperature: 32.0,
          minHumidity: 45.0,
          maxHumidity: 70.0,
        );
      case 'sugarcane':
        return FieldSettings(
          minMoisture: 50.0,
          maxMoisture: 80.0,
          minTemperature: 20.0,
          maxTemperature: 38.0,
          minHumidity: 55.0,
          maxHumidity: 80.0,
        );
      case 'cotton':
        return FieldSettings(
          minMoisture: 35.0,
          maxMoisture: 65.0,
          minTemperature: 22.0,
          maxTemperature: 35.0,
          minHumidity: 40.0,
          maxHumidity: 70.0,
        );
      default:
        return FieldSettings();
    }
  }
}
