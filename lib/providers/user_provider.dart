import 'package:flutter/material.dart';
import '../services/services.dart';
import '../models/models.dart';

class UserProvider with ChangeNotifier {
  UserProfile? _profile;
  bool _isLoading = false;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String get displayName => _profile?.name ?? 'Farmer';

  Future<void> loadProfile(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      final profile = await FirebaseService().getUserProfile(uid);
      _profile = profile;
    } catch (e) {
      debugPrint('[UserProvider] Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setProfile(UserProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  void clear() {
    _profile = null;
    notifyListeners();
  }
}
