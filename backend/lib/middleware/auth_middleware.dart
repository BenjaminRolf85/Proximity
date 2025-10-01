import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../services/auth_service.dart';

Middleware authMiddleware(AuthService authService) {
  return (Handler handler) {
    return (Request request) async {
      // Allow CORS preflight
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }

      // Skip auth for public endpoints
      if (_isPublicEndpoint(request.url.path)) {
        return await handler(request);
      }

      // Get token from Authorization header
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.unauthorized(
          jsonEncode({'error': 'Missing or invalid authorization header'}),
          headers: {..._jsonHeaders, ..._corsHeaders},
        );
      }

      final token = authHeader.substring(7); // Remove 'Bearer '
      final userId = await authService.verifyToken(token);

      if (userId == null) {
        return Response.unauthorized(
          jsonEncode({'error': 'Invalid or expired token'}),
          headers: {..._jsonHeaders, ..._corsHeaders},
        );
      }

      // Add userId to request context
      final updatedRequest = request.change(context: {'userId': userId});
      return await handler(updatedRequest);
    };
  };
}

bool _isPublicEndpoint(String path) {
  return path.startsWith('auth/register') ||
      path.startsWith('auth/login') ||
      path.startsWith('health');
}

final _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
};

final _jsonHeaders = {
  'Content-Type': 'application/json',
};

extension RequestExtension on Request {
  String get userId => context['userId'] as String;
}

