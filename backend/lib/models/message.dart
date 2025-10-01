import 'dart:convert';

enum MessageType { text, broadcast, ping }

class Message {
  final String id;
  final String fromUserId;
  final String? toUserId; // null for broadcasts
  final String text;
  final MessageType type;
  final DateTime createdAt;
  final bool isRead;

  const Message({
    required this.id,
    required this.fromUserId,
    this.toUserId,
    required this.text,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'text': text,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String?,
      text: json['text'] as String,
      type: MessageType.values.firstWhere((e) => e.name == json['type']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  factory Message.fromDb(Map<String, dynamic> row) {
    return Message(
      id: row['id'] as String,
      fromUserId: row['from_user_id'] as String,
      toUserId: row['to_user_id'] as String?,
      text: row['text'] as String,
      type: MessageType.values.firstWhere((e) => e.name == row['type']),
      createdAt: row['created_at'] as DateTime,
      isRead: row['is_read'] as bool,
    );
  }

  String toJsonString() => jsonEncode(toJson());
}

