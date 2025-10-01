import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_config.dart';

enum WebSocketStatus { disconnected, connecting, connected, error }

class WebSocketService {
  WebSocketChannel? _channel;
  WebSocketStatus _status = WebSocketStatus.disconnected;
  final _statusController = StreamController<WebSocketStatus>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  String? _userId;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  WebSocketStatus get status => _status;
  Stream<WebSocketStatus> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Connect to WebSocket
  void connect(String userId) {
    if (_status == WebSocketStatus.connected) {
      return;
    }

    _userId = userId;
    _status = WebSocketStatus.connecting;
    _statusController.add(_status);

    try {
      final uri = Uri.parse(ApiConfig.websocketUrl());
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      // Send authentication
      _send({
        'type': 'authenticate',
        'userId': userId,
      });

      _status = WebSocketStatus.connected;
      _statusController.add(_status);
      _reconnectAttempts = 0;
      
      print('✅ WebSocket connected');
    } catch (e) {
      print('❌ WebSocket connection error: $e');
      _status = WebSocketStatus.error;
      _statusController.add(_status);
      _scheduleReconnect();
    }
  }

  /// Send message
  void _send(Map<String, dynamic> data) {
    if (_channel != null && _status == WebSocketStatus.connected) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  /// Send location update
  void sendLocationUpdate({
    required double latitude,
    required double longitude,
  }) {
    _send({
      'type': 'location_update',
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  /// Handle incoming message
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      _messageController.add(data);
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  /// Handle error
  void _handleError(error) {
    print('WebSocket error: $error');
    _status = WebSocketStatus.error;
    _statusController.add(_status);
    _scheduleReconnect();
  }

  /// Handle disconnect
  void _handleDisconnect() {
    print('WebSocket disconnected');
    _status = WebSocketStatus.disconnected;
    _statusController.add(_status);
    _scheduleReconnect();
  }

  /// Schedule reconnection
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    final delay = Duration(seconds: 2 * (_reconnectAttempts + 1));
    
    print('Reconnecting in ${delay.inSeconds}s (attempt ${_reconnectAttempts + 1})');
    
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      if (_userId != null) {
        connect(_userId!);
      }
    });
  }

  /// Disconnect
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _status = WebSocketStatus.disconnected;
    _statusController.add(_status);
    print('WebSocket disconnected manually');
  }

  /// Dispose
  void dispose() {
    disconnect();
    _statusController.close();
    _messageController.close();
  }
}

