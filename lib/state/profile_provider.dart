import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

class ProfileState {
  final String name;
  final String? avatarUrl;
  final String bio;

  const ProfileState({this.name = 'You', this.avatarUrl, this.bio = ''});

  ProfileState copyWith({String? name, String? avatarUrl, String? bio}) {
    return ProfileState(
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
    );
  }
}

final storageServiceProvider = FutureProvider<StorageService>((ref) async {
  return await StorageService.create();
});

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final storage = ref.watch(storageServiceProvider).valueOrNull;
  return ProfileNotifier(storage);
});

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._storage) : super(_loadInitialState(_storage));
  
  final StorageService? _storage;

  static ProfileState _loadInitialState(StorageService? storage) {
    if (storage == null) return const ProfileState();
    return ProfileState(
      name: storage.getProfileName(),
      avatarUrl: storage.getProfileAvatar(),
      bio: storage.getProfileBio(),
    );
  }

  void updateName(String value) {
    state = state.copyWith(name: value);
    _storage?.saveProfileName(value);
  }
  
  void updateAvatarUrl(String? value) {
    state = state.copyWith(avatarUrl: value);
    _storage?.saveProfileAvatar(value);
  }
  
  void updateBio(String value) {
    state = state.copyWith(bio: value);
    _storage?.saveProfileBio(value);
  }
}


