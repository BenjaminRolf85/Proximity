import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'auth_api.dart';
import 'proximity_api.dart';
import 'messages_api.dart';
import 'websocket_service.dart';

/// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(() => client.dispose());
  return client;
});

/// Auth API Provider
final authApiProvider = Provider<AuthApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthApi(client);
});

/// Proximity API Provider
final proximityApiProvider = Provider<ProximityApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return ProximityApi(client);
});

/// Messages API Provider
final messagesApiProvider = Provider<MessagesApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return MessagesApi(client);
});

/// WebSocket Service Provider
final websocketServiceProvider = Provider<WebSocketService>((ref) {
  final ws = WebSocketService();
  ref.onDispose(() => ws.dispose());
  return ws;
});

