import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/group.dart';
import '../state/filters_provider.dart';

/// Service for persisting app data using SharedPreferences
class StorageService {
  static const String _keyProfileName = 'profile_name';
  static const String _keyProfileAvatar = 'profile_avatar';
  static const String _keyProfileBio = 'profile_bio';
  static const String _keyGroups = 'groups';
  static const String _keySelectedGroupIds = 'selected_group_ids';
  static const String _keyDistanceFilter = 'distance_filter';
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserId = 'user_id';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Profile methods
  Future<void> saveProfileName(String name) async {
    await _prefs.setString(_keyProfileName, name);
  }

  String getProfileName() {
    return _prefs.getString(_keyProfileName) ?? 'You';
  }

  Future<void> saveProfileAvatar(String? avatarUrl) async {
    if (avatarUrl == null) {
      await _prefs.remove(_keyProfileAvatar);
    } else {
      await _prefs.setString(_keyProfileAvatar, avatarUrl);
    }
  }

  String? getProfileAvatar() {
    return _prefs.getString(_keyProfileAvatar);
  }

  Future<void> saveProfileBio(String bio) async {
    await _prefs.setString(_keyProfileBio, bio);
  }

  String getProfileBio() {
    return _prefs.getString(_keyProfileBio) ?? '';
  }

  // Groups methods
  Future<void> saveGroups(List<Group> groups) async {
    final json = groups.map((g) => {
      'id': g.id,
      'name': g.name,
      'type': g.type.name,
    }).toList();
    await _prefs.setString(_keyGroups, jsonEncode(json));
  }

  List<Group> getGroups() {
    final String? data = _prefs.getString(_keyGroups);
    if (data == null) return [];
    
    try {
      final List<dynamic> json = jsonDecode(data);
      return json.map((item) {
        final type = GroupType.values.firstWhere(
          (t) => t.name == item['type'],
          orElse: () => GroupType.custom,
        );
        return Group(
          id: item['id'] as String,
          name: item['name'] as String,
          type: type,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Filter methods
  Future<void> saveSelectedGroupIds(Set<String> groupIds) async {
    await _prefs.setStringList(_keySelectedGroupIds, groupIds.toList());
  }

  Set<String> getSelectedGroupIds() {
    final list = _prefs.getStringList(_keySelectedGroupIds);
    return list?.toSet() ?? {};
  }

  Future<void> saveDistanceFilter(DistanceFilter filter) async {
    await _prefs.setString(_keyDistanceFilter, filter.name);
  }

  DistanceFilter getDistanceFilter() {
    final String? name = _prefs.getString(_keyDistanceFilter);
    if (name == null) return DistanceFilter.all;
    
    return DistanceFilter.values.firstWhere(
      (f) => f.name == name,
      orElse: () => DistanceFilter.all,
    );
  }

  // Auth methods
  Future<void> saveToken(String token) async {
    await _prefs.setString(_keyAuthToken, token);
  }

  String? getToken() {
    return _prefs.getString(_keyAuthToken);
  }

  Future<void> clearToken() async {
    await _prefs.remove(_keyAuthToken);
  }

  Future<void> saveUserId(String userId) async {
    await _prefs.setString(_keyUserId, userId);
  }

  String? getUserId() {
    return _prefs.getString(_keyUserId);
  }

  Future<void> clearUserId() async {
    await _prefs.remove(_keyUserId);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

