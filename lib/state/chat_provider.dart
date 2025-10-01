import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../repositories/mock_repository.dart';
import '../api/api_providers.dart';
import '../api/messages_api.dart';
import 'auth_state.dart';

final chatProvider = StateNotifierProvider<ChatNotifier, Map<String, List<ChatMessage>>>((ref) {
  final messagesApi = ref.watch(messagesApiProvider);
  final authState = ref.watch(authStateProvider);
  return ChatNotifier(MockRepository(), messagesApi, authState.isAuthenticated);
});

class ChatNotifier extends StateNotifier<Map<String, List<ChatMessage>>> {
  ChatNotifier(this._repo, this._messagesApi, this._isAuthenticated) : super({});
  
  final MockRepository _repo;
  final MessagesApi _messagesApi;
  final bool _isAuthenticated;
  final _uuid = const Uuid();

  /// Load messages for a person
  Future<List<ChatMessage>> messagesFor(String personId) async {
    // Return cached if available
    if (state.containsKey(personId)) {
      return state[personId]!;
    }

    // Load from backend if authenticated
    if (_isAuthenticated) {
      try {
        final messages = await _messagesApi.getConversation(
          otherUserId: personId,
          limit: 100,
        );
        state = {...state, personId: messages};
        return messages;
      } catch (e) {
        print('Error loading messages: $e');
        // Fallback to mock data
        final messages = _repo.initialMessagesFor(personId);
        state = {...state, personId: messages};
        return messages;
      }
    } else {
      // Use mock data when not authenticated
      final messages = _repo.initialMessagesFor(personId);
      state = {...state, personId: messages};
      return messages;
    }
  }

  /// Send message to a person
  Future<void> sendTo(String personId, String text) async {
    if (_isAuthenticated) {
      try {
        // Send to backend
        final message = await _messagesApi.sendMessage(
          toUserId: personId,
          text: text,
        );
        
        // Add to local state
        final list = List<ChatMessage>.from(state[personId] ?? []);
        list.add(message);
        state = {...state, personId: list};
      } catch (e) {
        print('Error sending message: $e');
        // Add to local state anyway
        _addLocalMessage(personId, text, fromMe: true);
      }
    } else {
      // Mock mode
      _addLocalMessage(personId, text, fromMe: true);
    }
  }

  /// Add local message (fallback or mock mode)
  void _addLocalMessage(String personId, String text, {required bool fromMe}) {
    final list = List<ChatMessage>.from(state[personId] ?? []);
    list.add(ChatMessage(
      id: _uuid.v4(),
      fromId: fromMe ? 'me' : personId,
      toId: fromMe ? personId : 'me',
      text: text,
      timestamp: DateTime.now(),
    ));
    state = {...state, personId: list};
  }

  /// Receive message from WebSocket
  void receiveFrom(String personId, String text) {
    _addLocalMessage(personId, text, fromMe: false);
  }

  /// Reload conversation from backend
  Future<void> reloadConversation(String personId) async {
    if (!_isAuthenticated) return;

    try {
      final messages = await _messagesApi.getConversation(
        otherUserId: personId,
        limit: 100,
      );
      state = {...state, personId: messages};
    } catch (e) {
      print('Error reloading conversation: $e');
    }
  }
}


