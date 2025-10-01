import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/proximity_service.dart';
import '../middleware/auth_middleware.dart';

class ProximityRoutes {
  final ProximityService _proximityService;

  ProximityRoutes(this._proximityService);

  Router get router {
    final router = Router();

    router.post('/location', _updateLocation);
    router.get('/nearby', _getNearbyUsers);
    router.get('/location/<userId>', _getUserLocation);

    return router;
  }

  Future<Response> _updateLocation(Request request) async {
    try {
      final userId = request.userId;
      final body = jsonDecode(await request.readAsString());

      final latitude = body['latitude'] as num?;
      final longitude = body['longitude'] as num?;
      final accuracy = body['accuracy'] as num?;

      if (latitude == null || longitude == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Missing latitude or longitude'}),
        );
      }

      if (latitude < -90 || latitude > 90) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid latitude'}),
        );
      }

      if (longitude < -180 || longitude > 180) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid longitude'}),
        );
      }

      await _proximityService.updateLocation(
        userId: userId,
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
        accuracy: accuracy?.toDouble(),
      );

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _getNearbyUsers(Request request) async {
    try {
      final userId = request.userId;
      final maxDistance = double.tryParse(request.url.queryParameters['maxDistance'] ?? '30000') ?? 30000;
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '100');

      final nearbyUsers = await _proximityService.findNearbyUsers(
        userId: userId,
        maxDistanceMeters: maxDistance,
        limit: limit,
      );

      return Response.ok(
        jsonEncode({
          'users': nearbyUsers.map((u) => u.toJson()).toList(),
          'count': nearbyUsers.length,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _getUserLocation(Request request, String userId) async {
    try {
      final location = await _proximityService.getUserLocation(userId);

      if (location == null) {
        return Response.notFound(
          jsonEncode({'error': 'Location not found'}),
        );
      }

      return Response.ok(
        jsonEncode(location.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }
}

