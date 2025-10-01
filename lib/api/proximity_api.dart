import 'api_client.dart';
import 'api_config.dart';
import '../models/person.dart';

class ProximityApi {
  final ApiClient _client;

  ProximityApi(this._client);

  /// Update user's location
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    await _client.post(
      ApiConfig.proximityLocation,
      body: {
        'latitude': latitude,
        'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
      },
    );
  }

  /// Get nearby users
  Future<List<Person>> getNearbyUsers({
    double maxDistanceMeters = 30000,
    int? limit,
  }) async {
    final queryParams = <String, String>{
      'maxDistance': maxDistanceMeters.toString(),
      if (limit != null) 'limit': limit.toString(),
    };

    final response = await _client.get(
      ApiConfig.proximityNearby,
      queryParameters: queryParams,
    );

    final users = response['users'] as List;
    return users.map((json) => _parseNearbyUser(json)).toList();
  }

  Person _parseNearbyUser(dynamic json) {
    final userData = json['user'] as Map<String, dynamic>;
    final distanceMeters = (json['distanceMeters'] as num).toDouble();
    final bearing = json['bearing'] != null ? (json['bearing'] as num).toDouble() : 0.0;

    // Convert bearing (0-360 degrees) to radians for angleRadians
    final angleRadians = bearing * 3.14159265359 / 180.0;

    return Person(
      id: userData['id'] as String,
      name: userData['name'] as String,
      avatarUrl: userData['avatarUrl'] as String?,
      groupIds: const {}, // Groups will be synced separately
      distanceMeters: distanceMeters,
      angleRadians: angleRadians,
      isOnline: true, // From backend, we assume they're online if they appear
    );
  }
}

