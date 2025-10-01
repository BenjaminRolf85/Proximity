import 'dart:math';
import 'package:postgres/postgres.dart';
import '../models/user.dart';

class ProximityService {
  final Connection _db;

  ProximityService(this._db);

  /// Update user's location
  Future<void> updateLocation({
    required String userId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    await _db.execute(
      Sql.named('''
      INSERT INTO user_locations (user_id, location, accuracy, updated_at)
      VALUES (@user_id, ST_SetSRID(ST_MakePoint(@longitude, @latitude), 4326), @accuracy, NOW())
      ON CONFLICT (user_id) 
      DO UPDATE SET 
        location = ST_SetSRID(ST_MakePoint(@longitude, @latitude), 4326),
        accuracy = @accuracy,
        updated_at = NOW()
      '''),
      parameters: {
        'user_id': TypedValue(Type.uuid, userId),
        'latitude': TypedValue(Type.double, latitude),
        'longitude': TypedValue(Type.double, longitude),
        'accuracy': TypedValue(Type.double, accuracy),
      },
    );
  }

  /// Find nearby users within specified radius (in meters)
  Future<List<NearbyUser>> findNearbyUsers({
    required String userId,
    required double maxDistanceMeters,
    int? limit,
  }) async {
    final query = '''
      SELECT 
        u.id, u.email, u.name, u.avatar_url, u.bio, u.created_at, u.last_seen,
        ST_Distance(
          ul1.location::geography,
          ul2.location::geography
        ) as distance,
        DEGREES(
          ST_Azimuth(
            ul1.location::geometry,
            ul2.location::geometry
          )
        ) as bearing
      FROM user_locations ul1
      CROSS JOIN user_locations ul2
      JOIN users u ON ul2.user_id = u.id
      WHERE ul1.user_id = @user_id
        AND ul2.user_id != @user_id
        AND ST_DWithin(
          ul1.location::geography,
          ul2.location::geography,
          @max_distance
        )
        AND ul2.updated_at > NOW() - INTERVAL '15 minutes'
      ORDER BY distance ASC
      ${limit != null ? 'LIMIT @limit' : ''}
    ''';

    final params = <String, TypedValue>{
      'user_id': TypedValue(Type.uuid, userId),
      'max_distance': TypedValue(Type.double, maxDistanceMeters),
      if (limit != null) 'limit': TypedValue(Type.integer, limit),
    };

    final result = await _db.execute(Sql.named(query), parameters: params);

    return result.map((row) {
      final map = row.toColumnMap();
      final user = User.fromDb(map);
      final distance = (map['distance'] as num).toDouble();
      final bearing = map['bearing'] != null ? (map['bearing'] as num).toDouble() : null;

      return NearbyUser(
        user: user,
        distanceMeters: distance,
        bearing: bearing,
      );
    }).toList();
  }

  /// Get users within broadcast range (100m by default)
  Future<List<String>> getUsersInBroadcastRange({
    required String userId,
    double rangeMeters = 100,
  }) async {
    final result = await _db.execute(
      '''
      SELECT ul2.user_id
      FROM user_locations ul1
      CROSS JOIN user_locations ul2
      WHERE ul1.user_id = @user_id
        AND ul2.user_id != @user_id
        AND ST_DWithin(
          ul1.location::geography,
          ul2.location::geography,
          @range
        )
        AND ul2.updated_at > NOW() - INTERVAL '5 minutes'
      ''',
      parameters: {
        'user_id': userId,
        'range': rangeMeters,
      },
    );

    return result.map((row) => row.toColumnMap()['user_id'] as String).toList();
  }

  /// Calculate distance between two points (Haversine formula)
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0; // meters

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  /// Get user's current location
  Future<UserLocation?> getUserLocation(String userId) async {
    final result = await _db.execute(
      '''
      SELECT 
        user_id,
        ST_Y(location::geometry) as latitude,
        ST_X(location::geometry) as longitude,
        accuracy,
        updated_at
      FROM user_locations
      WHERE user_id = @user_id
      ''',
      parameters: {'user_id': userId},
    );

    if (result.isEmpty) return null;

    final map = result.first.toColumnMap();
    return UserLocation(
      userId: map['user_id'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: map['updated_at'] as DateTime,
      accuracy: map['accuracy'] != null ? (map['accuracy'] as num).toDouble() : null,
    );
  }

  /// Remove stale locations (older than specified duration)
  Future<int> cleanupStaleLocations({Duration maxAge = const Duration(hours: 24)}) async {
    final result = await _db.execute(
      '''
      DELETE FROM user_locations
      WHERE updated_at < NOW() - @interval::INTERVAL
      RETURNING user_id
      ''',
      parameters: {'interval': '${maxAge.inSeconds} seconds'},
    );

    return result.length;
  }
}

