class ChatMessage {
  final String id;
  final String fromId;
  final String toId; // person id
  final String text;
  final DateTime timestamp;
  final bool isBroadcast;

  const ChatMessage({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.text,
    required this.timestamp,
    this.isBroadcast = false,
  });
}


