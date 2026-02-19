import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

class FieldProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<Field> _fields = [];
  Field? _selectedField;
  SensorData? _currentSensorData;
  List<Map<String, dynamic>> _dailyAverages = [];
  bool _isLoading = false;
  String? _error;
  bool _isHardwareOnline = false;
  
  StreamSubscription<SensorData>? _sensorSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _avgSubscription;
  StreamSubscription<bool>? _hardwareStatusSubscription;

  FieldProvider() {
    _hardwareStatusSubscription = _firebaseService.hardwareStatusStream.listen((status) {
      _isHardwareOnline = status;
      notifyListeners();
    });
    // Set initial value
    _isHardwareOnline = _firebaseService.isHardwareOnline;
  }

  // Getters
  List<Field> get fields => _fields;
  Field? get selectedField => _selectedField;
  SensorData? get currentSensorData => _currentSensorData;
  List<Map<String, dynamic>> get dailyAverages => _dailyAverages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasFields => _fields.isNotEmpty;
  bool get isHardwareOnline => _isHardwareOnline;

  // Load all crops/fields from Firebase
  Future<void> loadFields() async {
    debugPrint('[FieldProvider] ========== loadFields() START ==========');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('[FieldProvider] Fetching crops from Firebase...');
      _fields = await _firebaseService.getFields();
      debugPrint('[FieldProvider] Received ${_fields.length} crops from Firebase');
      
      if (_fields.isNotEmpty) {
        if (_selectedField == null || !_fields.any((f) => f.id == _selectedField!.id)) {
          await selectField(_fields.first.id);
        } else {
          final updatedField = _fields.firstWhere((f) => f.id == _selectedField!.id);
          _selectedField = updatedField;
          if (updatedField.latestData != null) {
            _currentSensorData = updatedField.latestData;
          }
        }
      } else {
        _selectedField = null;
        _currentSensorData = null;
      }
    } catch (e) {
      _error = 'Failed to load crops: $e';
      debugPrint('[FieldProvider] ERROR: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh fields (explicit fetch)
  Future<void> refreshFields() async {
    return loadFields();
  }

  // Select a crop and start listening to live sensor data
  Future<void> selectField(String cropId) async {
    await _sensorSubscription?.cancel();
    await _avgSubscription?.cancel();

    try {
      _selectedField = _fields.firstWhere((f) => f.id == cropId);
      
      if (_selectedField?.latestData != null) {
        _currentSensorData = _selectedField!.latestData;
      }
      
      // Listen to live sensor data
      _sensorSubscription = _firebaseService
          .getSensorDataStream(cropId)
          .listen((data) {
        _currentSensorData = data;
        _selectedField?.latestData = data;
        _selectedField?.isPumpOn = data.pumpStatus;
        notifyListeners();
      });

      // Listen to daily averages
      _avgSubscription = _firebaseService
          .getDailyAveragesStream(cropId)
          .listen((averages) {
        _dailyAverages = averages;
        notifyListeners();
      });

      _selectedField!.isPumpOn = await _firebaseService.getPumpStatus(cropId);
      _firebaseService.startAlertListener(cropId);
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to select crop: $e';
      debugPrint(_error);
    }
  }

  // Add a new crop
  Future<bool> addField({
    required String name,
    required String cropType,
    String? location,
    DateTime? plantingDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newField = await _firebaseService.addField(
        name: name,
        cropType: cropType,
        location: location,
        plantingDate: plantingDate,
      );
      _fields.add(newField);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add crop: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update an existing crop
  Future<bool> updateField(
    String cropId, {
    required String name,
    required String cropType,
    String? location,
    DateTime? plantingDate,
  }) async {
    final index = _fields.indexWhere((f) => f.id == cropId);
    if (index != -1) {
      final oldField = _fields[index];
      try {
        await _firebaseService.updateField(
          cropId,
          name: name,
          cropType: cropType,
          location: location,
          plantingDate: plantingDate,
        );
        final updatedField = Field(
          id: oldField.id,
          name: cropType,
          cropType: cropType,
          fieldName: name,
          location: location,
          createdAt: oldField.createdAt,
          plantingDate: plantingDate,
          settings: oldField.settings,
        );
        updatedField.isPumpOn = oldField.isPumpOn;
        updatedField.latestData = oldField.latestData;

        _fields[index] = updatedField;

        if (_selectedField?.id == cropId) {
          _selectedField = updatedField;
        }

        notifyListeners();
        return true;
      } catch (e) {
        _error = 'Failed to update crop: $e';
        debugPrint(_error);
        notifyListeners();
        return false;
      }
    }
    return false;
  }

  // Delete a crop
  void deleteField(String cropId) {
    _fields.removeWhere((f) => f.id == cropId);
    
    if (_selectedField?.id == cropId) {
      _sensorSubscription?.cancel();
      _currentSensorData = null;
      if (_fields.isNotEmpty) {
        selectField(_fields.first.id);
      } else {
        _selectedField = null;
      }
    }
    
    notifyListeners();
  }

  // Update field settings
  Future<bool> updateFieldSettings(String cropId, FieldSettings settings) async {
    try {
      await _firebaseService.updateFieldSettings(cropId, settings);
      
      final index = _fields.indexWhere((f) => f.id == cropId);
      if (index != -1) {
        final oldField = _fields[index];
        final updatedField = Field(
          id: oldField.id,
          name: oldField.name,
          cropType: oldField.cropType,
          fieldName: oldField.fieldName,
          location: oldField.location,
          createdAt: oldField.createdAt,
          plantingDate: oldField.plantingDate,
          settings: settings,
        );
        updatedField.isPumpOn = oldField.isPumpOn;
        updatedField.latestData = oldField.latestData;
        
        _fields[index] = updatedField;
        
        if (_selectedField?.id == cropId) {
          _selectedField = updatedField;
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update settings: $e';
      return false;
    }
  }

  // Clear all data (on logout)
  void clear() {
    _sensorSubscription?.cancel();
    _avgSubscription?.cancel();
    _hardwareStatusSubscription?.cancel();
    _sensorSubscription = null;
    _avgSubscription = null;
    _hardwareStatusSubscription = null;
    _fields = [];
    _selectedField = null;
    _currentSensorData = null;
    _dailyAverages = [];
    _isLoading = false;
    _error = null;
    _isHardwareOnline = false;
    notifyListeners();
  }

  // Control irrigation pump
  Future<bool> togglePump() async {
    if (_selectedField == null) return false;

    try {
      final newState = !_selectedField!.isPumpOn;
      final success = await _firebaseService.controlPump(
        _selectedField!.id,
        newState,
      );
      
      if (success) {
        _selectedField!.isPumpOn = newState;
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      _error = 'Failed to control pump: $e';
      return false;
    }
  }

  // Get historical data for charts
  Future<List<SensorData>> getHistoricalData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_selectedField == null) return [];
    
    return await _firebaseService.getHistoricalData(
      _selectedField!.id,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Get daily averages for charts
  Future<List<Map<String, dynamic>>> getDailyAverages({int days = 7}) async {
    if (_selectedField == null) return [];
    
    return await _firebaseService.getDailyAverages(
      _selectedField!.id,
      days: days,
    );
  }

  // Dispose resources
  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _avgSubscription?.cancel();
    _hardwareStatusSubscription?.cancel();
    super.dispose();
  }
}
