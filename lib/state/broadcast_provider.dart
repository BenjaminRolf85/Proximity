import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../constants.dart';

class Broadcast {
  final String id;
  final String text;
  final DateTime createdAt;
  const Broadcast(this.id, this.text, this.createdAt);
}

final broadcastProvider = StateNotifierProvider<BroadcastNotifier, List<Broadcast>>((ref) {
  return BroadcastNotifier();
});

class BroadcastNotifier extends StateNotifier<List<Broadcast>> {
  BroadcastNotifier() : super(const []);
  final _uuid = const Uuid();

  void broadcast(String text) {
    final b = Broadcast(_uuid.v4(), text, DateTime.now());
    state = [...state, b];
    // Auto-expire after broadcast lifetime
    Future.delayed(ProximityConstants.broadcastLifetime, () {
      state = state.where((x) => x.id != b.id).toList();
    });
  }

  /// Receive broadcast from WebSocket
  void receiveFromWebSocket(String text) {
    final b = Broadcast(_uuid.v4(), text, DateTime.now());
    state = [...state, b];
    // Auto-expire after broadcast lifetime
    Future.delayed(ProximityConstants.broadcastLifetime, () {
      state = state.where((x) => x.id != b.id).toList();
    });
  }

  List<Broadcast> activeOverlays() {
    final now = DateTime.now();
    return state.where((b) => now.difference(b.createdAt) < ProximityConstants.broadcastLifetime).toList();
  }
}


