class UserProfile {
  final String uid;
  final String name;
  final String? phone;
  final String? language;
  final String? location;
  final String? email;
  final String? photoUrl;

  UserProfile({
    required this.uid,
    required this.name,
    this.phone,
    this.language,
    this.location,
    this.email,
    this.photoUrl,
  });

  /// Parse from the new structure: /users/{userId}/profile
  factory UserProfile.fromMap(String uid, Map<dynamic, dynamic> map) {
    // Support both flat and nested "profile" structures
    final profileData = map['profile'] as Map<dynamic, dynamic>? ?? map;
    return UserProfile(
      uid: uid,
      name: profileData['name'] ?? 'User',
      phone: profileData['phone']?.toString(),
      language: profileData['language']?.toString(),
      location: profileData['location']?.toString(),
      email: profileData['email']?.toString(),
      photoUrl: profileData['photoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (phone != null) 'phone': phone,
      if (language != null) 'language': language,
      if (location != null) 'location': location,
      if (email != null) 'email': email,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }

  UserProfile copyWith({
    String? name,
    String? phone,
    String? language,
    String? location,
    String? email,
    String? photoUrl,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      language: language ?? this.language,
      location: location ?? this.location,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

class DeviceStatus {
  final String deviceId;
  final bool isOnline;
  final bool isConnected;
  final DateTime lastSeen;
  final String? firmwareVersion;
  final int? signalStrength;

  DeviceStatus({
    required this.deviceId,
    required this.isOnline,
    required this.isConnected,
    required this.lastSeen,
    this.firmwareVersion,
    this.signalStrength,
  });

  factory DeviceStatus.fromMap(String deviceId, Map<dynamic, dynamic> map) {
    return DeviceStatus(
      deviceId: deviceId,
      isOnline: map['isOnline'] ?? false,
      isConnected: map['isConnected'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen'])
          : DateTime.now(),
      firmwareVersion: map['firmwareVersion'],
      signalStrength: map['signalStrength'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isOnline': isOnline,
      'isConnected': isConnected,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      if (firmwareVersion != null) 'firmwareVersion': firmwareVersion,
      if (signalStrength != null) 'signalStrength': signalStrength,
    };
  }

  bool get isRecentlyActive {
    final difference = DateTime.now().difference(lastSeen);
    return difference.inMinutes < 5;
  }
}
