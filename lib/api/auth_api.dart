import 'api_client.dart';
import 'api_config.dart';

class AuthResponse {
  final String token;
  final String userId;
  final String email;
  final String name;
  final String? avatarUrl;
  final String? bio;

  AuthResponse({
    required this.token,
    required this.userId,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.bio,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return AuthResponse(
      token: json['token'] as String,
      userId: user['id'] as String,
      email: user['email'] as String,
      name: user['name'] as String,
      avatarUrl: user['avatarUrl'] as String?,
      bio: user['bio'] as String?,
    );
  }
}

class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  /// Register new user
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _client.post(
      ApiConfig.authRegister,
      body: {
        'email': email,
        'password': password,
        'name': name,
      },
    );

    final authResponse = AuthResponse.fromJson(response);
    _client.setToken(authResponse.token);
    return authResponse;
  }

  /// Login
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      ApiConfig.authLogin,
      body: {
        'email': email,
        'password': password,
      },
    );

    final authResponse = AuthResponse.fromJson(response);
    _client.setToken(authResponse.token);
    return authResponse;
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getProfile() async {
    return await _client.get(ApiConfig.authMe);
  }

  /// Update profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? avatarUrl,
    String? bio,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
    if (bio != null) body['bio'] = bio;

    return await _client.patch(
      ApiConfig.authMe,
      body: body,
    );
  }

  /// Logout (clear token)
  void logout() {
    _client.setToken(null);
  }
}

