import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';

class MessageService {
  final Connection _db;
  final _uuid = const Uuid();

  MessageService(this._db);

  /// Send a direct message
  Future<Message> sendMessage({
    required String fromUserId,
    required String toUserId,
    required String text,
  }) async {
    final messageId = _uuid.v4();

    await _db.execute(
      '''
      INSERT INTO messages (id, from_user_id, to_user_id, text, type, created_at)
      VALUES (@id, @from_user_id, @to_user_id, @text, @type, NOW())
      ''',
      parameters: {
        'id': messageId,
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'text': text,
        'type': MessageType.text.name,
      },
    );

    final result = await _db.execute(
      'SELECT * FROM messages WHERE id = @id',
      parameters: {'id': messageId},
    );

    return Message.fromDb(result.first.toColumnMap());
  }

  /// Send a broadcast message
  Future<Message> sendBroadcast({
    required String fromUserId,
    required String text,
  }) async {
    final messageId = _uuid.v4();

    await _db.execute(
      '''
      INSERT INTO messages (id, from_user_id, to_user_id, text, type, created_at)
      VALUES (@id, @from_user_id, NULL, @text, @type, NOW())
      ''',
      parameters: {
        'id': messageId,
        'from_user_id': fromUserId,
        'text': text,
        'type': MessageType.broadcast.name,
      },
    );

    final result = await _db.execute(
      'SELECT * FROM messages WHERE id = @id',
      parameters: {'id': messageId},
    );

    return Message.fromDb(result.first.toColumnMap());
  }

  /// Send a ping notification
  Future<Message> sendPing({
    required String fromUserId,
    required String toUserId,
  }) async {
    final messageId = _uuid.v4();

    await _db.execute(
      '''
      INSERT INTO messages (id, from_user_id, to_user_id, text, type, created_at)
      VALUES (@id, @from_user_id, @to_user_id, @text, @type, NOW())
      ''',
      parameters: {
        'id': messageId,
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'text': 'I\'m nearby!',
        'type': MessageType.ping.name,
      },
    );

    final result = await _db.execute(
      'SELECT * FROM messages WHERE id = @id',
      parameters: {'id': messageId},
    );

    return Message.fromDb(result.first.toColumnMap());
  }

  /// Get conversation between two users
  Future<List<Message>> getConversation({
    required String userId1,
    required String userId2,
    int limit = 50,
  }) async {
    final result = await _db.execute(
      '''
      SELECT * FROM messages
      WHERE (from_user_id = @user1 AND to_user_id = @user2)
         OR (from_user_id = @user2 AND to_user_id = @user1)
      ORDER BY created_at DESC
      LIMIT @limit
      ''',
      parameters: {
        'user1': userId1,
        'user2': userId2,
        'limit': limit,
      },
    );

    return result.map((row) => Message.fromDb(row.toColumnMap())).toList();
  }

  /// Get recent broadcasts (within last 5 minutes)
  Future<List<Message>> getRecentBroadcasts({
    Duration maxAge = const Duration(minutes: 5),
  }) async {
    final result = await _db.execute(
      '''
      SELECT * FROM messages
      WHERE type = @type
        AND created_at > NOW() - @interval::INTERVAL
      ORDER BY created_at DESC
      ''',
      parameters: {
        'type': MessageType.broadcast.name,
        'interval': '${maxAge.inSeconds} seconds',
      },
    );

    return result.map((row) => Message.fromDb(row.toColumnMap())).toList();
  }

  /// Mark messages as read
  Future<void> markAsRead({
    required String userId,
    required List<String> messageIds,
  }) async {
    if (messageIds.isEmpty) return;

    await _db.execute(
      '''
      UPDATE messages
      SET is_read = TRUE
      WHERE id = ANY(@message_ids)
        AND to_user_id = @user_id
      ''',
      parameters: {
        'message_ids': messageIds,
        'user_id': userId,
      },
    );
  }

  /// Get unread message count
  Future<int> getUnreadCount(String userId) async {
    final result = await _db.execute(
      '''
      SELECT COUNT(*) as count
      FROM messages
      WHERE to_user_id = @user_id
        AND is_read = FALSE
      ''',
      parameters: {'user_id': userId},
    );

    return result.first.toColumnMap()['count'] as int;
  }
}

