import 'api_client.dart';
import 'api_config.dart';
import '../models/message.dart';

class MessagesApi {
  final ApiClient _client;

  MessagesApi(this._client);

  /// Send a direct message
  Future<ChatMessage> sendMessage({
    required String toUserId,
    required String text,
  }) async {
    final response = await _client.post(
      ApiConfig.messagesSend,
      body: {
        'toUserId': toUserId,
        'text': text,
      },
    );

    return _parseMessage(response);
  }

  /// Send a broadcast message
  Future<ChatMessage> sendBroadcast({
    required String text,
  }) async {
    final response = await _client.post(
      ApiConfig.messagesBroadcast,
      body: {
        'text': text,
      },
    );

    return _parseMessage(response['message'] as Map<String, dynamic>);
  }

  /// Send a ping notification
  Future<void> sendPing({
    required String toUserId,
  }) async {
    await _client.post('${ApiConfig.messagesPing}/$toUserId');
  }

  /// Get conversation with another user
  Future<List<ChatMessage>> getConversation({
    required String otherUserId,
    int limit = 50,
  }) async {
    final response = await _client.get(
      '${ApiConfig.messagesConversation}/$otherUserId',
      queryParameters: {'limit': limit.toString()},
    );

    final messages = response['messages'] as List;
    return messages.map((json) => _parseMessage(json)).toList();
  }

  /// Parse message from API response
  ChatMessage _parseMessage(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      fromId: json['fromUserId'] as String,
      toId: json['toUserId'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['createdAt'] as String),
      isBroadcast: json['type'] == 'broadcast',
    );
  }
}

