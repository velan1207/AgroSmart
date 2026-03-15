import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// Firebase Service for Crop Monitoring
/// New structure: /users/{userId}/crops/{cropId}/...
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final Map<String, StreamController<SensorData>> _sensorStreams = {};
  final Map<String, StreamSubscription> _databaseSubscriptions = {};
  final Map<String, Timer> _restLivePollTimers = {};
  static const String _restDatabaseUrl = 'https://fir-42101-default-rtdb.firebaseio.com';
  
  // Firebase Database reference
  DatabaseReference? _database;
  bool _isInitialized = false;
  bool _useRestApi = false;

  bool get isAvailable => true;
  
  // Current user ID
  String? _currentUserId;
  String? _lastDeviceId;
  
  // Alert stream
  final StreamController<Alert> _alertController = StreamController<Alert>.broadcast();
  Stream<Alert> get alertStream => _alertController.stream;
  
  // Track last alert time for de-duplication: Map<"fieldId_alertType", DateTime>
  final Map<String, DateTime> _lastAlertTime = {};

  // Hardware status monitor
  final StreamController<bool> _hardwareStatusController = StreamController<bool>.broadcast();
  Stream<bool> get hardwareStatusStream => _hardwareStatusController.stream;
  static const Duration _hardwareHeartbeatTimeout = Duration(seconds: 15);
  static const Duration _hardwareFutureSkewTolerance = Duration(seconds: 5);
  
  int? _lastHeartbeat;
  DateTime? _lastHeartbeatTime;
  Timer? _statusTimer;
  bool _isHardwareOnlineValue = false;
  bool get isHardwareOnline => _isHardwareOnlineValue;

  // Real fields cache
  final List<Field> _realFieldsCache = [];

  String get currentUserId {
    if (_useRestApi) {
      return _currentUserId ?? 'default_user';
    }

    if (_currentUserId != null) return _currentUserId!;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentUserId = user.uid;
        return user.uid;
      }
    } catch (e) {
      debugPrint('[Firebase] Error getting current user: $e');
    }
    return _currentUserId ?? 'default_user';
  }

  /// Reference to current user's data
  DatabaseReference get _userRef {
    final uid = currentUserId;
    if (uid.isEmpty) return _database!.child('users/default_user');
    return _database!.child('users/$uid');
  }

  /// Reference to current user's field (Single field architecture)
  DatabaseReference get _fieldRef => _userRef.child('field');

  /// Set user ID manually (for testing or when auth is not available)
  void setUserId(String userId) {
    _currentUserId = userId;
    debugPrint('[Firebase] User ID set to: $userId');
  }

  /// Use REST API mode when FlutterFire plugins are unavailable on the platform.
  void configureRestFallback({required bool enabled}) {
    _useRestApi = enabled;
    if (enabled) {
      _database = null;
      _isInitialized = true;
      _startStatusCheckTimer();
      debugPrint('[Firebase] Using REST fallback for cloud backend');
    }
  }

  /// Initialize Firebase
  Future<void> initialize() async {
    if (_useRestApi) {
      _isInitialized = true;
      _startStatusCheckTimer();
      debugPrint('[Firebase] REST fallback initialized');
      return;
    }

    try {
      _database = FirebaseDatabase.instance.ref();
      _isInitialized = true;
      debugPrint('[Firebase] Connected to Firebase Realtime Database');
      debugPrint('[Firebase] Current user ID: $currentUserId');
      
      _startStatusCheckTimer();
    } catch (e) {
      debugPrint('[Firebase] Failed to initialize database: $e');
    }
  }

  /// Ensure database is available, auto-initialize if needed
  Future<bool> _ensureDatabase() async {
    if (_useRestApi) {
      return true;
    }

    if (_database != null) return true;
    try {
      _database = FirebaseDatabase.instance.ref();
      _isInitialized = true;
      debugPrint('[Firebase] Auto-initialized database reference');
      return true;
    } catch (e) {
      debugPrint('[Firebase] Failed to auto-initialize database: $e');
      return false;
    }
  }

  void _setHardwareStatus(bool online) {
    if (_isHardwareOnlineValue != online) {
      _isHardwareOnlineValue = online;
      _hardwareStatusController.add(online);
      debugPrint('[Firebase] Hardware is now ${online ? 'ONLINE' : 'OFFLINE'}');
    }
  }

  bool _hasLiveTimestamp(Map<dynamic, dynamic> dataMap) {
    return dataMap['timestamp'] != null ||
        dataMap['ts'] != null ||
        dataMap['time'] != null;
  }

  bool _isFreshDeviceTimestamp(DateTime timestamp) {
    final age = DateTime.now().difference(timestamp);
    if (age.isNegative) {
      return age.abs() <= _hardwareFutureSkewTolerance;
    }
    return age <= _hardwareHeartbeatTimeout;
  }

  void _updateHardwareStatusFromLiveData(
    Map<dynamic, dynamic> dataMap,
    SensorData data,
  ) {
    final heartbeat = data.heartbeat;
    final hasTimestamp = _hasLiveTimestamp(dataMap);
    final isFresh = hasTimestamp && _isFreshDeviceTimestamp(data.timestamp);

    if (!isFresh || heartbeat == null) {
      if (!isFresh) {
        debugPrint(
          '[Firebase] Ignoring stale live payload for hardware status '
          '(timestamp: ${data.timestamp.toIso8601String()}, heartbeat: $heartbeat)',
        );
      }
      _lastHeartbeat = heartbeat;
      _lastHeartbeatTime = hasTimestamp ? data.timestamp : null;
      _setHardwareStatus(false);
      return;
    }

    if (_lastHeartbeat != heartbeat ||
        _lastHeartbeatTime == null ||
        data.timestamp.isAfter(_lastHeartbeatTime!)) {
      _lastHeartbeat = heartbeat;
      _lastHeartbeatTime = data.timestamp;
    }

    _setHardwareStatus(true);
  }

  void _startStatusCheckTimer() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_lastHeartbeatTime != null) {
        final difference = DateTime.now().difference(_lastHeartbeatTime!);
        if (difference.isNegative) {
          if (difference.abs() > _hardwareFutureSkewTolerance) {
            _setHardwareStatus(false);
          }
          return;
        }

        if (difference > _hardwareHeartbeatTimeout) {
          _setHardwareStatus(false);
        }
      } else {
        _setHardwareStatus(false);
      }
    });
  }

  // ==================== CROP/FIELD METHODS ====================

  /// Get the single field for the current user
  /// Path: /users/{userId}/field
  Future<List<Field>> getFields() async {
    debugPrint('[FirebaseService] getField() called for user: $currentUserId');

    if (_useRestApi) {
      return _getFieldsViaRest();
    }
    
    if (!_isInitialized || _database == null) {
      debugPrint('[FirebaseService] Not initialized');
      return _realFieldsCache.isNotEmpty ? List.from(_realFieldsCache) : [];
    }

    try {
      final snapshot = await _fieldRef.get().timeout(const Duration(seconds: 5));
      
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        // Use 'main_field' as a fixed ID since we only have one
        final field = Field.fromMap('main_field', data);
        
        _realFieldsCache.clear();
        _realFieldsCache.add(field);
        debugPrint('[FirebaseService] Loaded single field from Firebase');
        return [field];
      }

      // Fallback 1: Check if data exists in old 'crops' node (Migration support)
      final cropsRef = _userRef.child('crops');
      final cropsSnapshot = await cropsRef.get().timeout(const Duration(seconds: 3));
      if (cropsSnapshot.exists && cropsSnapshot.value != null) {
        final cropsData = cropsSnapshot.value as Map<dynamic, dynamic>;
        if (cropsData.isNotEmpty) {
          final firstCropId = cropsData.keys.first.toString();
          final firstCropMap = cropsData[firstCropId] as Map<dynamic, dynamic>;
          debugPrint('[FirebaseService] Found legacy crop data for: $firstCropId. Migrating...');
          
          // Auto-migrate to the new structure
          await _fieldRef.set(firstCropMap);
          
          final field = Field.fromMap('main_field', firstCropMap);
          _realFieldsCache.clear();
          _realFieldsCache.add(field);
          return [field];
        }
      }

      // Fallback 2: If user is 'default_user' and still no data, auto-seed for a better first experience
      if (currentUserId == 'default_user') {
        debugPrint('[FirebaseService] No data for default_user. Seeding dummy data...');
        await seedDummyData();
        return getFields(); // Recursive call to fetch the newly seeded data
      }
      
      debugPrint('[FirebaseService] No field found for user: $currentUserId');
      return [];
    } catch (e) {
      debugPrint('[Firebase] Error fetching field: $e');
      return [];
    }
  }

  bool get isHardwareConnected => _database != null && _isInitialized;

  /// Get a specific crop by ID
  /// Path: /users/{userId}/crops/{cropId}
  Future<Field?> getField(String cropId) async {
    if (_database == null) return null;

    try {
      final snapshot = await _fieldRef.get(); // Changed from _cropsRef.child(cropId).get()
      if (snapshot.exists) {
        return Field.fromMap(cropId, snapshot.value as Map<dynamic, dynamic>);
      }
    } catch (e) {
      debugPrint('[Firebase] Error fetching crop: $e');
    }
    return null;
  }

  /// Add a new crop
  /// Path: /users/{userId}/crops/{cropId}
  Future<Field> addField({
    required String name,
    required String cropType,
    String? location,
    DateTime? plantingDate,
  }) async {
    const cropId = 'main_field';
    final newField = Field(
      id: cropId,
      name: cropType,
      cropType: cropType,
      fieldName: name,
      location: location,
      createdAt: DateTime.now(),
      plantingDate: plantingDate,
    );

    if (_database == null) return newField;

    try {
      await _fieldRef.set({
        'cropName': cropType,
        'fieldName': name,
        if (plantingDate != null) 'plantingDate': plantingDate.millisecondsSinceEpoch,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('[Firebase] Set main field');
    } catch (e) {
      debugPrint('[Firebase] Error setting field: $e');
    }
    return newField;
  }

  /// Update crop metadata
  /// Path: /users/{userId}/crops/{cropId}
  Future<void> updateField(
    String cropId, {
    required String name,
    required String cropType,
    String? location,
    DateTime? plantingDate,
  }) async {
    if (_database == null) return;

    try {
      await _fieldRef.update({
        'cropName': cropType,
        'fieldName': name,
        if (plantingDate != null) 'plantingDate': plantingDate.millisecondsSinceEpoch,
      });
      
      // Update cache
      final cacheIndex = _realFieldsCache.indexWhere((f) => f.id == cropId);
      if (cacheIndex != -1) {
        final old = _realFieldsCache[cacheIndex];
        _realFieldsCache[cacheIndex] = Field(
          id: old.id,
          name: cropType,
          cropType: cropType,
          fieldName: name,
          location: location,
          createdAt: old.createdAt,
          plantingDate: plantingDate,
          settings: old.settings,
        )
          ..isPumpOn = old.isPumpOn
          ..latestData = old.latestData;
      }
    } catch (e) {
      debugPrint('[Firebase] Error updating crop: $e');
    }
  }

  /// Update field settings
  /// Path: /users/{userId}/field/settings
  Future<bool> updateFieldSettings(String cropId, FieldSettings settings) async {
    if (_useRestApi) {
      try {
        await _restPut('users/${currentUserId}/field/settings', settings.toMap());
        debugPrint('[Firebase][REST] Updated field settings for crop: $cropId');
        return true;
      } catch (e) {
        debugPrint('[Firebase][REST] Error updating settings: $e');
        return false;
      }
    }

    if (!await _ensureDatabase()) return false;

    try {
      await _fieldRef.child('settings').set(settings.toMap());
      debugPrint('[Firebase] Updated field settings for crop: $cropId');
      return true;
    } catch (e) {
      debugPrint('[Firebase] Error updating settings: $e');
      return false;
    }
  }

  // ==================== LIVE SENSOR DATA ====================

  /// Get real-time sensor data stream for a crop
  /// Path: /users/{userId}/crops/{cropId}/live
  Stream<SensorData> getSensorDataStream(String cropId) {
    if (!_sensorStreams.containsKey(cropId)) {
      _sensorStreams[cropId] = StreamController<SensorData>.broadcast();

      if (_useRestApi) {
        _startRestLiveDataPolling(cropId);
      } else if (_database == null) {
        debugPrint('[Firebase] No database, cannot start live listener');
      } else {
        _startLiveDataListener(cropId);
      }
    }
    return _sensorStreams[cropId]!.stream;
  }

  void _startLiveDataListener(String cropId) {
    final liveRef = _fieldRef.child('live');
    final uid = currentUserId;
    
    debugPrint('[Firebase] Starting live listener on path: users/$uid/field/live');
    
    _databaseSubscriptions[cropId] = liveRef.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final dataMap = event.snapshot.value as Map<dynamic, dynamic>;
        debugPrint('[Firebase] Raw map: $dataMap');
        final data = SensorData.fromLiveMap(dataMap, deviceId: cropId);
        _lastDeviceId = data.deviceId ?? cropId;
        
        debugPrint('[Firebase] Live data: temp=${data.temperature}, hum=${data.humidity}, soil=${data.soilMoisture}, pump=${data.pumpStatus}, hb=${data.heartbeat}');

        _updateHardwareStatusFromLiveData(dataMap, data);

        _sensorStreams[cropId]?.add(data);
        _checkAndGenerateAlerts(cropId, data);
        
        // Update pump status in cache
        final fieldIndex = _realFieldsCache.indexWhere((f) => f.id == cropId);
        if (fieldIndex != -1) {
          _realFieldsCache[fieldIndex].isPumpOn = data.pumpStatus;
          _realFieldsCache[fieldIndex].latestData = data;
        }
      }
    }, onError: (error) {
      debugPrint('[Firebase] Error listening to live data for $cropId: $error');
    });
  }

  void _checkAndGenerateAlerts(String cropId, SensorData data) {
    String fieldName = cropId;
    double minMoisture = 35.0;
    double maxTemperature = 32.0;

    try {
      final field = _realFieldsCache.firstWhere((f) => f.id == cropId);
      fieldName = field.displayName;
      minMoisture = field.settings.minMoisture;
      maxTemperature = field.settings.maxTemperature;
    } catch (e) {
      // Fallback
    }
    
    final now = DateTime.now();
    
    // Low moisture alert - Only notify every 30 minutes
    if (data.soilMoisture < minMoisture) {
      final key = '${cropId}_low_moisture';
      if (!_lastAlertTime.containsKey(key) || 
          now.difference(_lastAlertTime[key]!).inMinutes >= 30) {
        
        _lastAlertTime[key] = now;
        _alertController.add(Alert(
          id: 'alert-${now.millisecondsSinceEpoch}',
          fieldId: cropId,
          fieldName: fieldName,
          type: AlertType.lowMoisture,
          severity: data.soilMoisture < 25 ? AlertSeverity.critical : AlertSeverity.warning,
          message: 'Soil moisture is below threshold. Consider irrigation.',
          value: data.soilMoisture,
          threshold: minMoisture,
          timestamp: now,
          currentTemp: data.temperature,
          currentHumidity: data.humidity,
          currentMoisture: data.soilMoisture,
        ));
      }
    }
    
    // High temperature alert - Only notify every 30 minutes
    if (data.temperature > maxTemperature) {
      final key = '${cropId}_high_temp';
      if (!_lastAlertTime.containsKey(key) || 
          now.difference(_lastAlertTime[key]!).inMinutes >= 30) {
        
        _lastAlertTime[key] = now;
        _alertController.add(Alert(
          id: 'alert-${now.millisecondsSinceEpoch}-temp',
          fieldId: cropId,
          fieldName: fieldName,
          type: AlertType.highTemperature,
          severity: data.temperature > 38 ? AlertSeverity.critical : AlertSeverity.warning,
          message: 'Temperature is above safe limit for crops.',
          value: data.temperature,
          threshold: maxTemperature,
          timestamp: now,
          currentTemp: data.temperature,
          currentHumidity: data.humidity,
          currentMoisture: data.soilMoisture,
        ));
      }
    }

    // Critical stress alert
    if (data.stressLevel == CropStressLevel.critical) {
      _alertController.add(Alert(
        id: 'alert-${DateTime.now().millisecondsSinceEpoch}-stress',
        fieldId: cropId,
        fieldName: fieldName,
        type: AlertType.criticalStress,
        severity: AlertSeverity.critical,
        message: 'Crops are under critical stress. Immediate action required!',
        timestamp: DateTime.now(),
        currentTemp: data.temperature,
        currentHumidity: data.humidity,
        currentMoisture: data.soilMoisture,
      ));
    }
  }

  // ==================== HISTORICAL DATA ====================

  /// Get historical data for a crop
  /// Path: /users/{userId}/crops/{cropId}/history/{yyyy-mm}/days/{dd-mm-yyyy}/records/{hh:mm}
  Future<List<SensorData>> getHistoricalData(
    String cropId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_database == null) return [];

    try {
      final List<SensorData> allRecords = [];
      
      // Determine which months to fetch
      final months = <String>{};
      var current = DateTime(startDate.year, startDate.month);
      final end = DateTime(endDate.year, endDate.month);
      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        months.add('${current.year}-${current.month.toString().padLeft(2, '0')}');
        current = DateTime(current.year, current.month + 1);
      }

      debugPrint('[Firebase] Fetching history for months: $months');

      for (final month in months) {
        try {
          final daysRef = _fieldRef.child('history/$month/days');
          final snapshot = await daysRef.get().timeout(const Duration(seconds: 5));
          
          if (snapshot.exists && snapshot.value != null) {
            final daysData = snapshot.value as Map<dynamic, dynamic>;
            
            daysData.forEach((dateKey, dayData) {
              if (dayData is Map && dayData['records'] != null) {
                final records = dayData['records'] as Map<dynamic, dynamic>;
                records.forEach((timeKey, recordData) {
                  if (recordData is Map) {
                    final sensorData = SensorData.fromHistoryRecord(
                      timeKey.toString(),
                      dateKey.toString(),
                      recordData as Map<dynamic, dynamic>,
                      deviceId: cropId,
                    );
                    
                    // Only include data within the requested range
                    if (sensorData.timestamp.isAfter(startDate) && 
                        sensorData.timestamp.isBefore(endDate)) {
                      allRecords.add(sensorData);
                    }
                  }
                });
              }
            });
          }
        } catch (e) {
          debugPrint('[Firebase] Error fetching history for month $month: $e');
        }
      }

      // Fallback: Check flat push-key entries in /users/{userId}/field/history
      // These are ESP32-written records of the form {humidity, soilMoisture, temperature, timestamp}
      try {
        debugPrint('[Firebase] Checking fallback flat history in: users/$currentUserId/field/history');
        final flatHistoryRef = _fieldRef.child('history');
        final flatSnapshot = await flatHistoryRef
            .orderByChild('timestamp')
            .startAt(startDate.millisecondsSinceEpoch.toDouble())
            .endAt(endDate.millisecondsSinceEpoch.toDouble())
            .limitToLast(300)
            .get();

        if (flatSnapshot.exists && flatSnapshot.value != null) {
          final historyMap = flatSnapshot.value as Map<dynamic, dynamic>;
          historyMap.forEach((key, value) {
            if (value is Map) {
              final ts = value['timestamp'];
              if (ts != null) {
                final sensorData = SensorData.fromLiveMap(value as Map<dynamic, dynamic>, deviceId: cropId);
                allRecords.add(sensorData);
              }
            }
          });
          debugPrint('[Firebase] Fetched flat history entries: ${allRecords.length} total records');
        }
      } catch (e) {
        debugPrint('[Firebase] Flat history fallback error: $e');
      }

      // Sort by timestamp
      allRecords.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      debugPrint('[Firebase] Total records for chart: ${allRecords.length}');
      return allRecords;
    } catch (e) {
      debugPrint('[Firebase] Error fetching historical data: $e');
      return [];
    }
  }

  /// Get daily averages from history
  /// Path: /users/{userId}/crops/{cropId}/history/{yyyy-mm}/days/{dd-mm-yyyy}/dailyAvg
  Future<List<Map<String, dynamic>>> getDailyAverages(
    String cropId, {
    int days = 7,
  }) async {
    if (_database == null) return [];

    try {
      final List<Map<String, dynamic>> averages = [];
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      // Determine months to fetch
      final months = <String>{};
      var current = DateTime(startDate.year, startDate.month);
      final end = DateTime(now.year, now.month);
      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        months.add('${current.year}-${current.month.toString().padLeft(2, '0')}');
        current = DateTime(current.year, current.month + 1);
      }

      for (final month in months) {
        try {
          final daysRef = _fieldRef.child('history/$month/days');
          final snapshot = await daysRef.get().timeout(const Duration(seconds: 5));
          
          if (snapshot.exists && snapshot.value != null) {
            final daysData = snapshot.value as Map<dynamic, dynamic>;
            
            daysData.forEach((dateKey, dayData) {
              if (dayData is Map && dayData['dailyAvg'] != null) {
                final avgData = dayData['dailyAvg'] as Map<dynamic, dynamic>;
                
                // Parse date
                DateTime? parsedDate;
                try {
                  final parts = dateKey.toString().split('-');
                  if (parts.length == 3) {
                    parsedDate = DateTime(
                      int.parse(parts[2]),
                      int.parse(parts[1]),
                      int.parse(parts[0]),
                    );
                  }
                } catch (_) {}

                if (parsedDate != null && parsedDate.isAfter(startDate)) {
                  averages.add({
                    'date': parsedDate,
                    'temperature': (avgData['temperature'] ?? 0).toDouble(),
                    'humidity': (avgData['humidity'] ?? 0).toDouble(),
                    'soilMoisture': (avgData['soilMoisture'] ?? 0).toDouble(),
                  });
                }
              }
            });
          }
        } catch (e) {
          debugPrint('[Firebase] Error fetching averages for $month: $e');
        }
      }

      // Sort by date
      averages.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      debugPrint('[Firebase] Fetched ${averages.length} daily averages');
      return averages;
    } catch (e) {
      debugPrint('[Firebase] Error fetching daily averages: $e');
      return [];
    }
  }

  /// Get stream of daily averages for the current month
  Stream<List<Map<String, dynamic>>> getDailyAveragesStream(String cropId) {
    if (_database == null) return Stream.value([]);

    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    
    return _fieldRef.child('history/$monthKey/days').onValue.map((event) {
      final List<Map<String, dynamic>> averages = [];
      if (event.snapshot.exists && event.snapshot.value != null) {
        final daysData = event.snapshot.value as Map<dynamic, dynamic>;
        daysData.forEach((dateKey, dayData) {
          if (dayData is Map && dayData['dailyAvg'] != null) {
            final avgData = dayData['dailyAvg'] as Map<dynamic, dynamic>;
            
            DateTime? parsedDate;
            try {
              final parts = dateKey.toString().split('-');
              if (parts.length == 3) {
                parsedDate = DateTime(
                  int.parse(parts[2]),
                  int.parse(parts[1]),
                  int.parse(parts[0]),
                );
              }
            } catch (_) {}

            if (parsedDate != null) {
              averages.add({
                'date': parsedDate,
                'temperature': (avgData['temperature'] ?? 0).toDouble(),
                'humidity': (avgData['humidity'] ?? 0).toDouble(),
                'soilMoisture': (avgData['soilMoisture'] ?? 0).toDouble(),
              });
            }
          }
        });
      }
      // Sort by date
      averages.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      return averages;
    });
  }

  /// Get monthly average
  /// Path: /users/{userId}/crops/{cropId}/history/{yyyy-mm}/monthlyAvg
  Future<Map<String, double>?> getMonthlyAverage(String cropId, {String? month}) async {
    if (_database == null) return null;

    final targetMonth = month ?? '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

    try {
      final snapshot = await _fieldRef
          .child('history/$targetMonth/monthlyAvg')
          .get()
          .timeout(const Duration(seconds: 3));
      
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return {
          'temperature': (data['temperature'] ?? 0).toDouble(),
          'humidity': (data['humidity'] ?? 0).toDouble(),
          'soilMoisture': (data['soilMoisture'] ?? 0).toDouble(),
        };
      }
    } catch (e) {
      debugPrint('[Firebase] Error fetching monthly average: $e');
    }
    return null;
  }

  // ==================== PUMP CONTROL ====================

  /// Control pump - write to /live/pumpCommand
  /// The ESP reads pumpCommand and writes pumpStatus (actual relay state).
  /// Path: /users/{userId}/field/live/pumpCommand
  Future<bool> controlPump(String cropId, bool turnOn) async {
    if (_useRestApi) {
      try {
        final commandPaths = <String>{
          'users/${currentUserId}/field/live/pumpCommand',
          // Firmware sample uses default_user; mirror command for compatibility.
          'users/default_user/field/live/pumpCommand',
        };

        for (final path in commandPaths) {
          await _restPut(path, turnOn);
        }

        debugPrint('[Firebase][REST] Pump command ${turnOn ? 'ON' : 'OFF'} for crop: $cropId');

        final fieldIndex = _realFieldsCache.indexWhere((f) => f.id == cropId);
        if (fieldIndex != -1) {
          _realFieldsCache[fieldIndex].isPumpOn = turnOn;

          _alertController.add(Alert(
            id: 'alert-${DateTime.now().millisecondsSinceEpoch}',
            fieldId: cropId,
            fieldName: _realFieldsCache[fieldIndex].displayName,
            type: turnOn ? AlertType.pumpActivated : AlertType.pumpDeactivated,
            severity: AlertSeverity.info,
            message: turnOn
                ? 'Irrigation pump has been activated.'
                : 'Irrigation pump has been deactivated.',
            timestamp: DateTime.now(),
          ));
        }

        return true;
      } catch (e) {
        debugPrint('[Firebase][REST] Error controlling pump: $e');
        return false;
      }
    }

    if (!await _ensureDatabase()) return false;

    try {
      // Write to pumpCommand (ESP reads this)
      await _fieldRef.child('live/pumpCommand').set(turnOn);

      // Mirror to default_user path for firmware compatibility when app userId differs.
      if (currentUserId != 'default_user') {
        await _database!.child('users/default_user/field/live/pumpCommand').set(turnOn);
      }

      debugPrint('[Firebase] Pump command ${turnOn ? 'ON' : 'OFF'} for crop: $cropId');
      
      // Update cache
      final fieldIndex = _realFieldsCache.indexWhere((f) => f.id == cropId);
      if (fieldIndex != -1) {
        _realFieldsCache[fieldIndex].isPumpOn = turnOn;
        
        _alertController.add(Alert(
          id: 'alert-${DateTime.now().millisecondsSinceEpoch}',
          fieldId: cropId,
          fieldName: _realFieldsCache[fieldIndex].displayName,
          type: turnOn ? AlertType.pumpActivated : AlertType.pumpDeactivated,
          severity: AlertSeverity.info,
          message: turnOn 
              ? 'Irrigation pump has been activated.' 
              : 'Irrigation pump has been deactivated.',
          timestamp: DateTime.now(),
        ));
      }
      
      return true;
    } catch (e) {
      debugPrint('[Firebase] Error controlling pump: $e');
      return false;
    }
  }

  /// Store a historical record for a crop
  /// Path: /users/{userId}/crops/{cropId}/history/{yyyy-mm}/days/{dd-mm-yyyy}/records/{hh:mm}
  Future<void> addHistoryRecord(String cropId, SensorData data) async {
    if (_database == null) return;

    final now = data.timestamp;
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final dateKey = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    final timeKey = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    try {
      final recordRef = _fieldRef.child('history/$monthKey/days/$dateKey/records/$timeKey');
      await recordRef.set({
        'dht22': {
          'temperature': data.temperature,
          'humidity': data.humidity,
        },
        'soilMoisture': data.soilMoisture,
      });
      debugPrint('[Firebase] Stored history record for $cropId at $dateKey $timeKey');
      
      // After adding a record, we should update the daily and monthly averages
      await calculateAndStoreDailyAverage(cropId, now);
    } catch (e) {
      debugPrint('[Firebase] Error storing history record: $e');
    }
  }

  /// Recalculate and store daily average for a specific date
  Future<void> calculateAndStoreDailyAverage(String cropId, DateTime date) async {
    if (_database == null) return;

    final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    final dateKey = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';

    try {
      final recordsRef = _fieldRef.child('history/$monthKey/days/$dateKey/records');
      final snapshot = await recordsRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final records = snapshot.value as Map<dynamic, dynamic>;
        double totalTemp = 0;
        double totalHum = 0;
        double totalMoisture = 0;
        int count = 0;

        records.forEach((_, recordData) {
          if (recordData is Map) {
            final dht = recordData['dht22'] as Map<dynamic, dynamic>?;
            totalTemp += (dht?['temperature'] ?? 0).toDouble();
            totalHum += (dht?['humidity'] ?? 0).toDouble();
            totalMoisture += (recordData['soilMoisture'] ?? 0).toDouble();
            count++;
          }
        });

        if (count > 0) {
          final avgRef = _fieldRef.child('history/$monthKey/days/$dateKey/dailyAvg');
          await avgRef.set({
            'temperature': double.parse((totalTemp / count).toStringAsFixed(2)),
            'humidity': double.parse((totalHum / count).toStringAsFixed(2)),
            'soilMoisture': double.parse((totalMoisture / count).toStringAsFixed(2)),
          });
          
          // Also update monthly average
          await calculateAndStoreMonthlyAverage(cropId, monthKey);
        }
      }
    } catch (e) {
      debugPrint('[Firebase] Error calculating daily average: $e');
    }
  }

  /// Recalculate and store monthly average
  Future<void> calculateAndStoreMonthlyAverage(String cropId, String monthKey) async {
    if (_database == null) return;

    try {
      final daysRef = _fieldRef.child('history/$monthKey/days');
      final snapshot = await daysRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final days = snapshot.value as Map<dynamic, dynamic>;
        double totalTemp = 0;
        double totalHum = 0;
        double totalMoisture = 0;
        int count = 0;

        days.forEach((_, dayData) {
          if (dayData is Map && dayData['dailyAvg'] != null) {
            final avg = dayData['dailyAvg'] as Map<dynamic, dynamic>;
            totalTemp += (avg['temperature'] ?? 0).toDouble();
            totalHum += (avg['humidity'] ?? 0).toDouble();
            totalMoisture += (avg['soilMoisture'] ?? 0).toDouble();
            count++;
          }
        });

        if (count > 0) {
          final monthAvgRef = _fieldRef.child('history/$monthKey/monthlyAvg');
          await monthAvgRef.set({
            'temperature': double.parse((totalTemp / count).toStringAsFixed(2)),
            'humidity': double.parse((totalHum / count).toStringAsFixed(2)),
            'soilMoisture': double.parse((totalMoisture / count).toStringAsFixed(2)),
          });
        }
      }
    } catch (e) {
      debugPrint('[Firebase] Error calculating monthly average: $e');
    }
  }

  /// Get pump status (actual relay state, written by ESP8266)
  /// Path: /users/{userId}/field/live/pumpStatus
  Future<bool> getPumpStatus(String cropId) async {
    if (_useRestApi) {
      final live = await _restGet('users/${currentUserId}/field/live');
      if (live is Map && live['pumpStatus'] != null) {
        final val = live['pumpStatus'];
        return val is bool ? val : val.toString().toLowerCase() == 'true' || val == 1;
      }

      // Fallback for firmware configured with USER_ID = default_user.
      if (currentUserId != 'default_user') {
        final fallbackLive = await _restGet('users/default_user/field/live');
        if (fallbackLive is Map && fallbackLive['pumpStatus'] != null) {
          final fallbackVal = fallbackLive['pumpStatus'];
          return fallbackVal is bool
              ? fallbackVal
              : fallbackVal.toString().toLowerCase() == 'true' || fallbackVal == 1;
        }
      }

      return false;
    }

    if (_database == null) return false;

    try {
      final snapshot = await _fieldRef
          .child('live/pumpStatus')
          .get()
          .timeout(const Duration(seconds: 3));
      if (snapshot.exists) {
        final val = snapshot.value;
        return val is bool ? val : val.toString().toLowerCase() == 'true' || val == 1;
      }
    } catch (e) {
      debugPrint('[Firebase] Error getting pump status: $e');
    }
    return false;
  }

  // ==================== ALERTS ====================

  /// Get alerts for a crop
  /// Path: /users/{userId}/crops/{cropId}/alerts
  Future<List<Alert>> getRecentAlerts({int limit = 20}) async {
    if (_database == null) return [];

    try {
      final List<Alert> allAlerts = [];
      
      // Fetch alerts from the single field
      final snapshot = await _fieldRef.child('alerts').get().timeout(const Duration(seconds: 5));
      
      if (snapshot.exists && snapshot.value != null) {
        final alertsData = snapshot.value as Map<dynamic, dynamic>;
        
        // Get field info from cache or direct
        final fields = await getFields();
        final field = fields.isNotEmpty ? fields.first : null;
        final cropName = field?.name ?? 'Unknown';
        final fieldName = field?.fieldName ?? '';

        alertsData.forEach((alertId, alertData) {
          if (alertData is Map) {
            allAlerts.add(_parseFirebaseAlert(
              alertId.toString(), 
              'main_field', 
              '$cropName${fieldName.isNotEmpty ? " - $fieldName" : ""}',
              alertData as Map<dynamic, dynamic>,
            ));
          }
        });
      }
      
      // Sort by timestamp, newest first
      allAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return allAlerts.take(limit).toList();
    } catch (e) {
      debugPrint('[Firebase] Error fetching alerts: $e');
      return [];
    }
  }

  /// Delete a specific alert
  Future<void> deleteAlert(String alertId) async {
    if (_database == null) return;
    try {
      await _fieldRef.child('alerts/$alertId').remove();
      debugPrint('[Firebase] Alert $alertId deleted');
    } catch (e) {
      debugPrint('[Firebase] Error deleting alert: $e');
    }
  }

  /// Clear all alerts for the current field
  Future<void> clearAllAlerts() async {
    if (_database == null) return;
    try {
      await _fieldRef.child('alerts').remove();
      debugPrint('[Firebase] All alerts cleared');
    } catch (e) {
      debugPrint('[Firebase] Error clearing alerts: $e');
    }
  }

  Alert _parseFirebaseAlert(String alertId, String cropId, String cropDisplayName, Map<dynamic, dynamic> data) {
    // Parse alert type
    AlertType alertType = AlertType.criticalStress;
    final typeStr = data['type']?.toString() ?? '';
    try {
      alertType = AlertType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => AlertType.criticalStress,
      );
    } catch (_) {}

    // Parse severity
    AlertSeverity severity = AlertSeverity.warning;
    // Determine severity from type string
    if (typeStr.toLowerCase().contains('critical') || typeStr.toLowerCase().contains('high')) {
      severity = AlertSeverity.critical;
    } else if (typeStr.toLowerCase().contains('info')) {
      severity = AlertSeverity.info;
    }

    return Alert(
      id: alertId,
      fieldId: cropId,
      fieldName: cropDisplayName,
      type: alertType,
      severity: severity,
      message: data['message']?.toString() ?? 'Alert',
      timestamp: data['ts'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['ts'] is int ? data['ts'] : int.tryParse(data['ts'].toString()) ?? DateTime.now().millisecondsSinceEpoch)
          : DateTime.now(),
    );
  }

  /// Listen to alerts for a specific crop in real-time
  /// Path: /users/{userId}/crops/{cropId}/alerts
  void startAlertListener(String cropId) {
    if (_database == null) return;

    final alertsRef = _fieldRef.child('alerts');
    
    _databaseSubscriptions['${cropId}_alerts'] = alertsRef.onChildAdded.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final alertData = event.snapshot.value as Map<dynamic, dynamic>;
        final cropDisplayName = _realFieldsCache
            .where((f) => f.id == cropId)
            .map((f) => f.displayName)
            .firstOrNull ?? cropId;
        
        final alert = _parseFirebaseAlert(
          event.snapshot.key ?? 'unknown',
          cropId,
          cropDisplayName,
          alertData,
        );
        
        _alertController.add(alert);
      }
    });
  }

  // ==================== USER PROFILE METHODS ====================
  
  /// Get user profile from Firebase
  /// Path: /users/{userId}/profile
  /// Also checks if the user node exists at all (e.g. data from ESP32)
  Future<UserProfile?> getUserProfile(String uid) async {
    if (_useRestApi) {
      return _getUserProfileViaRest(uid);
    }

    if (!await _ensureDatabase()) {
      debugPrint('[Firebase] getUserProfile: Cannot connect to Firebase.');
      return null;
    }

    try {
      // 1. Try the explicit profile node first
      debugPrint('[Firebase] Checking profile at: users/$uid/profile');
      final profileSnapshot = await _database!.child('users/$uid/profile').get();
      if (profileSnapshot.exists && profileSnapshot.value != null) {
        debugPrint('[Firebase] Found profile node for $uid');
        return UserProfile.fromMap(uid, {'profile': profileSnapshot.value as Map<dynamic, dynamic>});
      }

      // 2. Check if user node exists at all (ESP32 may have created /users/{uid}/field/...)
      debugPrint('[Firebase] No profile node. Checking user node: users/$uid');
      final userSnapshot = await _database!.child('users/$uid').get();
      if (userSnapshot.exists && userSnapshot.value != null) {
        debugPrint('[Firebase] User node exists for $uid (likely ESP32-created). Data keys: ${(userSnapshot.value as Map?)?.keys}');
        
        // Try to extract profile data from the user node if it has profile-like fields
        final userData = userSnapshot.value;
        if (userData is Map) {
          // If user node has a 'profile' map inside it
          if (userData.containsKey('profile') && userData['profile'] is Map) {
            return UserProfile.fromMap(uid, userData as Map<dynamic, dynamic>);
          }
          // If user node has a 'name' field directly
          if (userData.containsKey('name')) {
            return UserProfile.fromMap(uid, userData as Map<dynamic, dynamic>);
          }
        }
        
        // User node exists but no profile data — return a minimal profile
        // so the setup screen knows the user ID is valid
        debugPrint('[Firebase] User node exists but no profile. Returning minimal profile.');
        return UserProfile(uid: uid, name: 'User');
      }

      debugPrint('[Firebase] No user data found for $uid');
    } catch (e) {
      debugPrint('[Firebase] Error fetching user profile for $uid: $e');
    }
    return null;
  }

  /// Check if a user node exists at all in Firebase
  /// Path: /users/{userId}
  /// Returns true even if there's no profile — just any data (e.g. sensor data from ESP32)
  Future<bool> userNodeExists(String uid) async {
    if (_database == null) return false;

    try {
      final snapshot = await _database!.child('users/$uid').get();
      return snapshot.exists;
    } catch (e) {
      debugPrint('[Firebase] Error checking user node: $e');
      return false;
    }
  }

  /// Get user profile stream for real-time updates
  Stream<UserProfile?> getUserProfileStream(String uid) {
    if (_database == null) {
      return Stream.value(null);
    }

    return _database!.child('users/$uid/profile').onValue.map((event) {
      if (event.snapshot.exists) {
        return UserProfile.fromMap(uid, {'profile': event.snapshot.value as Map<dynamic, dynamic>});
      }
      return null;
    });
  }

  /// Update user profile
  /// Path: /users/{userId}/profile
  Future<void> updateUserProfile(UserProfile profile) async {
    if (_useRestApi) {
      await _restPatch('users/${profile.uid}/profile', profile.toMap());
      debugPrint('[Firebase] User profile updated via REST');
      return;
    }

    if (_database == null) return;

    try {
      await _database!.child('users/${profile.uid}/profile').update(profile.toMap());
      debugPrint('[Firebase] User profile updated');
    } catch (e) {
      debugPrint('[Firebase] Error updating user profile: $e');
    }
  }

  /// Update last active timestamp
  Future<void> updateLastActive(String uid) async {
    if (_useRestApi) {
      await _restPut('users/$uid/profile/lastActive', DateTime.now().millisecondsSinceEpoch);
      return;
    }

    if (_database == null) return;

    try {
      await _database!.child('users/$uid/profile/lastActive').set(DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[Firebase] Error updating last active: $e');
    }
  }

  // ==================== DEVICE STATUS METHODS ====================
  // Reads from /users/{userId}/field/live — no separate deviceStatus collection.

  DeviceStatus _deviceStatusFromLive(Map<dynamic, dynamic> liveData) {
    final deviceId = liveData['deviceId']?.toString() ?? currentUserId;
    final ts = liveData['timestamp'];
    final lastSeen = ts != null
        ? DateTime.fromMillisecondsSinceEpoch(ts is int ? ts : int.tryParse(ts.toString()) ?? 0)
        : DateTime.now();
    final age = DateTime.now().difference(lastSeen);
    final isOnline = !age.isNegative && age <= _hardwareHeartbeatTimeout;
    return DeviceStatus(
      deviceId: deviceId,
      isOnline: isOnline,
      isConnected: isOnline,
      lastSeen: lastSeen,
    );
  }

  Future<DeviceStatus?> getDeviceStatus(String deviceId) async {
    if (!await _ensureDatabase()) return null;

    try {
      final snapshot = await _fieldRef.child('live').get();
      if (snapshot.exists && snapshot.value != null) {
        return _deviceStatusFromLive(snapshot.value as Map<dynamic, dynamic>);
      }
    } catch (e) {
      debugPrint('[Firebase] Error fetching device status: $e');
    }
    return null;
  }

  Stream<DeviceStatus?> getDeviceStatusStream(String deviceId) {
    if (_database == null) return Stream.value(null);

    return _fieldRef.child('live').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        return _deviceStatusFromLive(event.snapshot.value as Map<dynamic, dynamic>);
      }
      return null;
    });
  }

  Future<Map<String, DeviceStatus>> getAllDeviceStatuses() async {
    final status = await getDeviceStatus(currentUserId);
    if (status != null) {
      return {status.deviceId: status};
    }
    return {};
  }

  Future<void> updateDeviceStatus(DeviceStatus status) async {
    // Device status is written by the ESP32 hardware; no manual update needed.
    debugPrint('[Firebase] updateDeviceStatus: managed by ESP32 hardware via field/live');
  }

  Future<List<Field>> _getFieldsViaRest() async {
    try {
      final fieldData = await _restGet('users/${currentUserId}/field');
      if (fieldData is Map) {
        final field = Field.fromMap('main_field', fieldData);
        _realFieldsCache
          ..clear()
          ..add(field);
        debugPrint('[FirebaseService] Loaded single field from REST');
        return [field];
      }

      final cropsData = await _restGet('users/${currentUserId}/crops');
      if (cropsData is Map && cropsData.isNotEmpty) {
        final firstCropId = cropsData.keys.first.toString();
        final firstCropMap = cropsData[firstCropId];
        if (firstCropMap is Map) {
          final field = Field.fromMap('main_field', firstCropMap);
          _realFieldsCache
            ..clear()
            ..add(field);
          debugPrint('[FirebaseService] Loaded legacy field from REST');
          return [field];
        }
      }
    } catch (e) {
      debugPrint('[Firebase] Error fetching field via REST: $e');
    }

    debugPrint('[FirebaseService] No field found for user via REST: $currentUserId');
    return [];
  }

  Future<UserProfile?> _getUserProfileViaRest(String uid) async {
    try {
      debugPrint('[Firebase] Checking profile via REST at: users/$uid/profile');
      final profileData = await _restGet('users/$uid/profile');
      if (profileData is Map) {
        debugPrint('[Firebase] Found profile node for $uid via REST');
        return UserProfile.fromMap(uid, {'profile': profileData});
      }

      debugPrint('[Firebase] No profile node. Checking user node via REST: users/$uid');
      final userData = await _restGet('users/$uid');
      if (userData is Map) {
        if (userData.containsKey('profile') && userData['profile'] is Map) {
          return UserProfile.fromMap(uid, userData);
        }
        if (userData.containsKey('name')) {
          return UserProfile.fromMap(uid, userData);
        }
        return UserProfile(uid: uid, name: 'User');
      }
    } catch (e) {
      debugPrint('[Firebase] Error fetching user profile via REST for $uid: $e');
    }
    return null;
  }

  void _startRestLiveDataPolling(String cropId) {
    _restLivePollTimers[cropId]?.cancel();

    Future<void> pollOnce() async {
      try {
        final liveData = await _restGet('users/${currentUserId}/field/live');
        if (liveData is! Map) {
          return;
        }

        debugPrint('[Firebase] Raw map via REST: $liveData');
        final data = SensorData.fromLiveMap(liveData, deviceId: cropId);
        _lastDeviceId = data.deviceId ?? cropId;

        _updateHardwareStatusFromLiveData(liveData, data);

        _sensorStreams[cropId]?.add(data);
        _checkAndGenerateAlerts(cropId, data);

        final fieldIndex = _realFieldsCache.indexWhere((f) => f.id == cropId);
        if (fieldIndex != -1) {
          _realFieldsCache[fieldIndex].isPumpOn = data.pumpStatus;
          _realFieldsCache[fieldIndex].latestData = data;
        }
      } catch (e) {
        debugPrint('[Firebase] Error polling live data via REST for $cropId: $e');
      }
    }

    pollOnce();
    _restLivePollTimers[cropId] = Timer.periodic(const Duration(seconds: 3), (_) {
      pollOnce();
    });
  }

  Future<dynamic> _restGet(String path) async {
    final uri = Uri.parse('$_restDatabaseUrl/$path.json');
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('REST GET failed for $path: ${response.statusCode}');
    }

    if (response.body == 'null' || response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body);
  }

  Future<void> _restPatch(String path, Map<String, dynamic> data) async {
    final uri = Uri.parse('$_restDatabaseUrl/$path.json');
    final response = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('REST PATCH failed for $path: ${response.statusCode}');
    }
  }

  Future<void> _restPut(String path, dynamic data) async {
    final uri = Uri.parse('$_restDatabaseUrl/$path.json');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('REST PUT failed for $path: ${response.statusCode}');
    }
  }

  // ==================== NOTIFICATIONS METHODS ====================
  
  Future<List<Alert>> getUnreadNotifications(String userId) async {
    if (_database == null) return [];

    try {
      final snapshot = await _database!.child('notifications/$userId').get();
      if (snapshot.exists) {
        final alerts = <Alert>[];
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final alertData = value as Map<dynamic, dynamic>;
          if (alertData['isRead'] != true && alertData['isDeleted'] != true) {
            alerts.add(Alert.fromMap(key.toString(), alertData));
          }
        });
        alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return alerts;
      }
    } catch (e) {
      debugPrint('[Firebase] Error fetching notifications: $e');
    }
    return [];
  }

  Stream<List<Alert>> getNotificationsStream(String userId) {
    if (_database == null) return Stream.value([]);

    return _database!.child('notifications/$userId').onValue.map((event) {
      if (event.snapshot.exists) {
        final alerts = <Alert>[];
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final alertData = value as Map<dynamic, dynamic>;
          if (alertData['isDeleted'] != true) {
            alerts.add(Alert.fromMap(key.toString(), alertData));
          }
        });
        alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return alerts;
      }
      return <Alert>[];
    });
  }

  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    if (_database == null) return;

    try {
      await _database!.child('notifications/$userId/$notificationId/isRead').set(true);
    } catch (e) {
      debugPrint('[Firebase] Error marking notification as read: $e');
    }
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    if (_database == null) return;

    try {
      await _database!.child('notifications/$userId/$notificationId/isDeleted').set(true);
    } catch (e) {
      debugPrint('[Firebase] Error deleting notification: $e');
    }
  }

  /// Seed dummy data for testing (Updated for single field)
  Future<void> seedDummyData() async {
    if (_database == null) return;

    final userId = currentUserId;
    debugPrint('[Firebase] Seeding dummy data for user: $userId');

    try {
      // 1. Seed Profile
      final profile = UserProfile(
        uid: userId,
        name: 'Farmer Ramesh',
        phone: '+91 9123456789',
        language: 'te',
        location: 'Kadapa, Andhra Pradesh',
      );
      await updateUserProfile(profile);

      // 2. Set Main Field
      await _fieldRef.set({
        'cropName': 'Paddy',
        'fieldName': 'Main Field',
        'plantingDate': DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch,
        'createdAt': DateTime.now().subtract(const Duration(days: 35)).millisecondsSinceEpoch,
        'live': {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'dht22': {
            'temperature': 28.5,
            'humidity': 62.0,
          },
          'soilMoisture': 48.0,
          'pumpStatus': false,
        }
      });

      // 3. Add History
      final now = DateTime.now();
      for (int i = 0; i < 12; i++) {
        final recordTime = now.subtract(Duration(hours: i));
        await addHistoryRecord('main_field', SensorData(
          temperature: 24.0 + (i % 5),
          humidity: 60.0 + (i % 10),
          soilMoisture: 45.0 + (i % 3),
          timestamp: recordTime,
        ));
      }

      // 4. Add some Alerts
      final alertRef = _fieldRef.child('alerts').push();
      await alertRef.set({
        'type': AlertType.highTemperature.name,
        'message': 'Temperature spike detected: 34°C',
        'ts': DateTime.now().subtract(const Duration(hours: 5)).millisecondsSinceEpoch,
      });

      debugPrint('[Firebase] Dummy data seeding complete!');
    } catch (e) {
      debugPrint('[Firebase] Error seeding dummy data: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    for (var subscription in _databaseSubscriptions.values) {
      subscription.cancel();
    }
    for (var controller in _sensorStreams.values) {
      controller.close();
    }
    _alertController.close();
  }
}
