import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_providers.dart';
import '../api/websocket_service.dart';
import 'auth_state.dart';
import 'people_provider.dart';
import 'broadcast_provider.dart';

/// WebSocket connection state provider
final websocketConnectionProvider = StateNotifierProvider<WebSocketConnectionNotifier, WebSocketStatus>((ref) {
  final wsService = ref.watch(websocketServiceProvider);
  final authState = ref.watch(authStateProvider);
  
  final notifier = WebSocketConnectionNotifier(wsService, authState.userId);
  
  // Auto-connect when authenticated
  if (authState.isAuthenticated && authState.userId != null) {
    notifier.connect(authState.userId!);
  }
  
  // Listen to auth changes
  ref.listen<AuthState>(authStateProvider, (previous, next) {
    if (next.isAuthenticated && next.userId != null) {
      notifier.connect(next.userId!);
    } else {
      notifier.disconnect();
    }
  });
  
  return notifier;
});

class WebSocketConnectionNotifier extends StateNotifier<WebSocketStatus> {
  WebSocketConnectionNotifier(this._wsService, this._userId) : super(WebSocketStatus.disconnected) {
    _statusSubscription = _wsService.statusStream.listen((status) {
      state = status;
    });
  }

  final WebSocketService _wsService;
  final String? _userId;
  StreamSubscription<WebSocketStatus>? _statusSubscription;

  void connect(String userId) {
    _wsService.connect(userId);
  }

  void disconnect() {
    _wsService.disconnect();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }
}

/// WebSocket message handler provider
final websocketMessageHandlerProvider = Provider<WebSocketMessageHandler>((ref) {
  final wsService = ref.watch(websocketServiceProvider);
  final peopleNotifier = ref.read(peopleProvider.notifier);
  final broadcastNotifier = ref.read(broadcastProvider.notifier);
  
  return WebSocketMessageHandler(
    wsService,
    peopleNotifier,
    broadcastNotifier,
  );
});

class WebSocketMessageHandler {
  WebSocketMessageHandler(
    this._wsService,
    this._peopleNotifier,
    this._broadcastNotifier,
  ) {
    _startListening();
  }

  final WebSocketService _wsService;
  final PeopleNotifier _peopleNotifier;
  final BroadcastNotifier _broadcastNotifier;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;

  void _startListening() {
    _messageSubscription = _wsService.messageStream.listen(_handleMessage);
  }

  void _handleMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    final data = message['data'] as Map<String, dynamic>?;

    if (type == null || data == null) return;

    switch (type) {
      case 'locationUpdate':
        _handleLocationUpdate(data);
        break;
      case 'newMessage':
        _handleNewMessage(data);
        break;
      case 'userOnline':
        _handleUserOnline(data);
        break;
      case 'userOffline':
        _handleUserOffline(data);
        break;
      case 'broadcast':
        _handleBroadcast(data);
        break;
      case 'ping':
        _handlePing(data);
        break;
      default:
        print('Unknown WebSocket message type: $type');
    }
  }

  void _handleLocationUpdate(Map<String, dynamic> data) {
    // Refresh nearby people when someone updates their location
    _peopleNotifier.loadNearbyPeople();
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    // Messages will be handled by chat_provider
    print('New message received: $data');
  }

  void _handleUserOnline(Map<String, dynamic> data) {
    final userId = data['userId'] as String?;
    if (userId != null) {
      print('User $userId came online');
      _peopleNotifier.loadNearbyPeople();
    }
  }

  void _handleUserOffline(Map<String, dynamic> data) {
    final userId = data['userId'] as String?;
    if (userId != null) {
      print('User $userId went offline');
      _peopleNotifier.loadNearbyPeople();
    }
  }

  void _handleBroadcast(Map<String, dynamic> data) {
    final text = data['text'] as String?;
    if (text != null) {
      _broadcastNotifier.receiveFromWebSocket(text);
    }
  }

  void _handlePing(Map<String, dynamic> data) {
    final fromUserId = data['fromUserId'] as String?;
    final fromUserName = data['fromUserName'] as String?;
    if (fromUserName != null) {
      print('Ping from $fromUserName');
      // Show notification
    }
  }

  void dispose() {
    _messageSubscription?.cancel();
  }
}

