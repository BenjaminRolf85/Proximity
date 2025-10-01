import 'dart:convert';

class User {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime? lastSeen;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
    this.lastSeen,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen'] as String) : null,
    );
  }

  factory User.fromDb(Map<String, dynamic> row) {
    return User(
      id: row['id'] as String,
      email: row['email'] as String,
      name: row['name'] as String,
      avatarUrl: row['avatar_url'] as String?,
      bio: row['bio'] as String?,
      createdAt: row['created_at'] as DateTime,
      lastSeen: row['last_seen'] as DateTime?,
    );
  }

  String toJsonString() => jsonEncode(toJson());
}

class UserLocation {
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;

  const UserLocation({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
    };
  }

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      userId: json['userId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
    );
  }
}

class NearbyUser {
  final User user;
  final double distanceMeters;
  final double? bearing; // Direction in degrees (0-360)

  const NearbyUser({
    required this.user,
    required this.distanceMeters,
    this.bearing,
  });

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'distanceMeters': distanceMeters,
      'bearing': bearing,
    };
  }
}

