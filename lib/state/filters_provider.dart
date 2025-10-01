import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import 'profile_provider.dart';

enum DistanceFilter { all, neighborhood, city, country }

class FiltersState {
  final Set<String> selectedGroupIds;
  final DistanceFilter distance;

  const FiltersState({this.selectedGroupIds = const {}, this.distance = DistanceFilter.all});

  FiltersState copyWith({Set<String>? selectedGroupIds, DistanceFilter? distance}) {
    return FiltersState(
      selectedGroupIds: selectedGroupIds ?? this.selectedGroupIds,
      distance: distance ?? this.distance,
    );
  }
}

final filtersProvider = StateNotifierProvider<FiltersNotifier, FiltersState>((ref) {
  final storage = ref.watch(storageServiceProvider).valueOrNull;
  return FiltersNotifier(storage);
});

class FiltersNotifier extends StateNotifier<FiltersState> {
  FiltersNotifier(this._storage) : super(_loadInitialState(_storage));

  final StorageService? _storage;

  static FiltersState _loadInitialState(StorageService? storage) {
    if (storage == null) return const FiltersState();
    return FiltersState(
      selectedGroupIds: storage.getSelectedGroupIds(),
      distance: storage.getDistanceFilter(),
    );
  }

  void toggleGroup(String groupId) {
    final set = Set<String>.from(state.selectedGroupIds);
    if (!set.add(groupId)) set.remove(groupId);
    state = state.copyWith(selectedGroupIds: set);
    _storage?.saveSelectedGroupIds(set);
  }

  void clearGroups() {
    state = state.copyWith(selectedGroupIds: {});
    _storage?.saveSelectedGroupIds({});
  }

  void setDistance(DistanceFilter f) {
    state = state.copyWith(distance: f);
    _storage?.saveDistanceFilter(f);
  }
}


