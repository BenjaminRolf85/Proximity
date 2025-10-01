import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

enum WebSocketEventType {
  locationUpdate,
  newMessage,
  userOnline,
  userOffline,
  broadcast,
  ping,
}

class WebSocketMessage {
  final WebSocketEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WebSocketMessage({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: WebSocketEventType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());
}

class WebSocketService {
  final Map<String, WebSocketChannel> _connections = {};
  final Map<String, String> _userToConnection = {};
  
  // Broadcast to all connected clients
  void broadcastToAll(WebSocketMessage message) {
    final jsonString = message.toJsonString();
    for (final channel in _connections.values) {
      try {
        channel.sink.add(jsonString);
      } catch (e) {
        print('Error broadcasting to client: $e');
      }
    }
  }

  // Send message to specific user
  void sendToUser(String userId, WebSocketMessage message) {
    final connectionId = _userToConnection[userId];
    if (connectionId != null) {
      final channel = _connections[connectionId];
      if (channel != null) {
        try {
          channel.sink.add(message.toJsonString());
        } catch (e) {
          print('Error sending to user $userId: $e');
        }
      }
    }
  }

  // Send message to multiple users
  void sendToUsers(List<String> userIds, WebSocketMessage message) {
    final jsonString = message.toJsonString();
    for (final userId in userIds) {
      final connectionId = _userToConnection[userId];
      if (connectionId != null) {
        final channel = _connections[connectionId];
        if (channel != null) {
          try {
            channel.sink.add(jsonString);
          } catch (e) {
            print('Error sending to user $userId: $e');
          }
        }
      }
    }
  }

  // Register new connection
  void registerConnection(String connectionId, String userId, WebSocketChannel channel) {
    _connections[connectionId] = channel;
    _userToConnection[userId] = connectionId;

    // Notify others that user is online
    broadcastToAll(WebSocketMessage(
      type: WebSocketEventType.userOnline,
      data: {'userId': userId},
    ));

    print('✅ User $userId connected (${_connections.length} active connections)');
  }

  // Remove connection
  void removeConnection(String connectionId) {
    final userId = _userToConnection.entries
        .firstWhere(
          (entry) => entry.value == connectionId,
          orElse: () => MapEntry('', ''),
        )
        .key;

    _connections.remove(connectionId);
    if (userId.isNotEmpty) {
      _userToConnection.remove(userId);

      // Notify others that user is offline
      broadcastToAll(WebSocketMessage(
        type: WebSocketEventType.userOffline,
        data: {'userId': userId},
      ));

      print('❌ User $userId disconnected (${_connections.length} active connections)');
    }
  }

  // Get active user count
  int get activeUserCount => _userToConnection.length;

  // Check if user is connected
  bool isUserConnected(String userId) {
    return _userToConnection.containsKey(userId);
  }

  // Get all connected user IDs
  List<String> get connectedUserIds => _userToConnection.keys.toList();
}

