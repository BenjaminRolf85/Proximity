import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/message_service.dart';
import '../services/proximity_service.dart';
import '../middleware/auth_middleware.dart';

class MessageRoutes {
  final MessageService _messageService;
  final ProximityService _proximityService;

  MessageRoutes(this._messageService, this._proximityService);

  Router get router {
    final router = Router();

    router.post('/send', _sendMessage);
    router.post('/broadcast', _sendBroadcast);
    router.post('/ping/<toUserId>', _sendPing);
    router.get('/conversation/<otherUserId>', _getConversation);
    router.get('/broadcasts', _getRecentBroadcasts);
    router.patch('/read', _markAsRead);
    router.get('/unread-count', _getUnreadCount);

    return router;
  }

  Future<Response> _sendMessage(Request request) async {
    try {
      final userId = request.userId;
      final body = jsonDecode(await request.readAsString());

      final toUserId = body['toUserId'] as String?;
      final text = body['text'] as String?;

      if (toUserId == null || text == null || text.trim().isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Missing toUserId or text'}),
        );
      }

      final message = await _messageService.sendMessage(
        fromUserId: userId,
        toUserId: toUserId,
        text: text.trim(),
      );

      return Response.ok(
        jsonEncode(message.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _sendBroadcast(Request request) async {
    try {
      final userId = request.userId;
      final body = jsonDecode(await request.readAsString());

      final text = body['text'] as String?;

      if (text == null || text.trim().isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Missing text'}),
        );
      }

      final message = await _messageService.sendBroadcast(
        fromUserId: userId,
        text: text.trim(),
      );

      // Get users in broadcast range
      final nearbyUserIds = await _proximityService.getUsersInBroadcastRange(
        userId: userId,
        rangeMeters: 100,
      );

      return Response.ok(
        jsonEncode({
          'message': message.toJson(),
          'recipientCount': nearbyUserIds.length,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _sendPing(Request request, String toUserId) async {
    try {
      final userId = request.userId;

      final message = await _messageService.sendPing(
        fromUserId: userId,
        toUserId: toUserId,
      );

      return Response.ok(
        jsonEncode(message.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _getConversation(Request request, String otherUserId) async {
    try {
      final userId = request.userId;
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '50') ?? 50;

      final messages = await _messageService.getConversation(
        userId1: userId,
        userId2: otherUserId,
        limit: limit,
      );

      return Response.ok(
        jsonEncode({
          'messages': messages.map((m) => m.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _getRecentBroadcasts(Request request) async {
    try {
      final messages = await _messageService.getRecentBroadcasts();

      return Response.ok(
        jsonEncode({
          'messages': messages.map((m) => m.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _markAsRead(Request request) async {
    try {
      final userId = request.userId;
      final body = jsonDecode(await request.readAsString());

      final messageIds = (body['messageIds'] as List?)?.cast<String>();

      if (messageIds == null || messageIds.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Missing messageIds'}),
        );
      }

      await _messageService.markAsRead(
        userId: userId,
        messageIds: messageIds,
      );

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _getUnreadCount(Request request) async {
    try {
      final userId = request.userId;
      final count = await _messageService.getUnreadCount(userId);

      return Response.ok(
        jsonEncode({'count': count}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }
}

