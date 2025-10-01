import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_exception.dart';

/// Base API Client with common functionality
class ApiClient {
  final http.Client _client;
  String? _token;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Set authentication token
  void setToken(String? token) {
    _token = token;
  }

  /// Get authentication token
  String? get token => _token;

  /// Check if authenticated
  bool get isAuthenticated => _token != null;

  /// GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse(ApiConfig.url(endpoint))
        .replace(queryParameters: queryParameters);

    final response = await _client
        .get(
          uri,
          headers: _buildHeaders(),
        )
        .timeout(ApiConfig.connectionTimeout);

    return _handleResponse(response);
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(ApiConfig.url(endpoint));

    final response = await _client
        .post(
          uri,
          headers: _buildHeaders(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConfig.connectionTimeout);

    return _handleResponse(response);
  }

  /// PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(ApiConfig.url(endpoint));

    final response = await _client
        .patch(
          uri,
          headers: _buildHeaders(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConfig.connectionTimeout);

    return _handleResponse(response);
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    final uri = Uri.parse(ApiConfig.url(endpoint));

    final response = await _client
        .delete(
          uri,
          headers: _buildHeaders(),
        )
        .timeout(ApiConfig.connectionTimeout);

    return _handleResponse(response);
  }

  /// Build headers with authentication
  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    // Error handling
    String errorMessage = 'Request failed';
    try {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = errorBody['error'] as String? ?? errorMessage;
    } catch (_) {
      errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: errorMessage,
    );
  }

  /// Close the client
  void dispose() {
    _client.close();
  }
}

