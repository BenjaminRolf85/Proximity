import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group.dart';
import '../repositories/mock_repository.dart';
import '../services/storage_service.dart';
import 'profile_provider.dart';

final groupsProvider = StateNotifierProvider<GroupsNotifier, List<Group>>((ref) {
  final storage = ref.watch(storageServiceProvider).valueOrNull;
  return GroupsNotifier(MockRepository(), storage);
});

class GroupsNotifier extends StateNotifier<List<Group>> {
  GroupsNotifier(MockRepository repo, this._storage) : super(_loadInitialGroups(repo, _storage));

  final StorageService? _storage;

  static List<Group> _loadInitialGroups(MockRepository repo, StorageService? storage) {
    if (storage == null) return repo.loadGroups();
    
    final saved = storage.getGroups();
    if (saved.isEmpty) {
      // First launch, use defaults
      final defaults = repo.loadGroups();
      storage.saveGroups(defaults);
      return defaults;
    }
    return saved;
  }

  void addCustomGroup(String name) {
    final id = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    if (id.isEmpty) return;
    if (state.any((g) => g.id == id)) return;
    state = [
      ...state,
      Group(id: id, name: name.trim(), type: GroupType.custom),
    ];
    _storage?.saveGroups(state);
  }
}


