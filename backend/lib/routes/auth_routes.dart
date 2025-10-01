import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';
import '../middleware/auth_middleware.dart';

class AuthRoutes {
  final AuthService _authService;

  AuthRoutes(this._authService);

  Router get router {
    final router = Router();

    router.post('/register', _register);
    router.post('/login', _login);
    router.get('/me', _getProfile);
    router.patch('/me', _updateProfile);

    return router;
  }

  Future<Response> _register(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      
      final email = body['email'] as String?;
      final password = body['password'] as String?;
      final name = body['name'] as String?;

      if (email == null || password == null || name == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Missing required fields'}),
        );
      }

      if (password.length < 6) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Password must be at least 6 characters'}),
        );
      }

      final result = await _authService.register(
        email: email,
        password: password,
        name: name,
      );

      return Response.ok(
        jsonEncode(result),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _login(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      
      final email = body['email'] as String?;
      final password = body['password'] as String?;

      if (email == null || password == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Missing email or password'}),
        );
      }

      final result = await _authService.login(
        email: email,
        password: password,
      );

      return Response.ok(
        jsonEncode(result),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.unauthorized(
        jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _getProfile(Request request) async {
    try {
      final userId = request.userId;
      final user = await _authService.getUserById(userId);

      if (user == null) {
        return Response.notFound(
          jsonEncode({'error': 'User not found'}),
        );
      }

      return Response.ok(
        jsonEncode(user.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _updateProfile(Request request) async {
    try {
      final userId = request.userId;
      final body = jsonDecode(await request.readAsString());

      await _authService.updateUser(
        userId: userId,
        name: body['name'] as String?,
        avatarUrl: body['avatarUrl'] as String?,
        bio: body['bio'] as String?,
      );

      final user = await _authService.getUserById(userId);
      return Response.ok(
        jsonEncode(user?.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }
}

