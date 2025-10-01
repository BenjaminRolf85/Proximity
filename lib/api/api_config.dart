/// API Configuration
class ApiConfig {
  // Change this to your backend URL
  // For local development:
  // - iOS Simulator: http://localhost:8080
  // - Android Emulator: http://10.0.2.2:8080
  // - Real Device: http://YOUR_COMPUTER_IP:8080
  static const String baseUrl = 'http://localhost:8080';
  static const String wsUrl = 'ws://localhost:8080';

  // Endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authMe = '/auth/me';
  static const String proximityLocation = '/proximity/location';
  static const String proximityNearby = '/proximity/nearby';
  static const String messagesSend = '/messages/send';
  static const String messagesBroadcast = '/messages/broadcast';
  static const String messagesPing = '/messages/ping';
  static const String messagesConversation = '/messages/conversation';
  static const String ws = '/ws';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Get full URL for endpoint
  static String url(String endpoint) => '$baseUrl$endpoint';

  /// Get WebSocket URL
  static String websocketUrl() => '$wsUrl$ws';
}

