import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_providers.dart';
import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../api/api_exception.dart';
import '../services/storage_service.dart';
import 'profile_provider.dart';

class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? token;
  final String? email;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.token,
    this.email,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? token,
    String? email,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Auth State Provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authApi = ref.watch(authApiProvider);
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(storageServiceProvider).valueOrNull;
  return AuthNotifier(authApi, apiClient, storage);
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authApi, this._apiClient, this._storage) : super(const AuthState()) {
    _loadSavedAuth();
  }

  final AuthApi _authApi;
  final ApiClient _apiClient;
  final StorageService? _storage;

  /// Load saved authentication on startup
  Future<void> _loadSavedAuth() async {
    final token = _storage?.getToken();
    final userId = _storage?.getUserId();
    
    if (token != null && userId != null) {
      _apiClient.setToken(token);
      state = AuthState(
        isAuthenticated: true,
        token: token,
        userId: userId,
      );
    }
  }

  /// Register new user
  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authApi.register(
        email: email,
        password: password,
        name: name,
      );

      // Save to storage
      await _storage?.saveToken(response.token);
      await _storage?.saveUserId(response.userId);

      state = AuthState(
        isAuthenticated: true,
        userId: response.userId,
        token: response.token,
        email: response.email,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    }
  }

  /// Login
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authApi.login(
        email: email,
        password: password,
      );

      // Save to storage
      await _storage?.saveToken(response.token);
      await _storage?.saveUserId(response.userId);

      state = AuthState(
        isAuthenticated: true,
        userId: response.userId,
        token: response.token,
        email: response.email,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    _apiClient.setToken(null);
    await _storage?.clearToken();
    await _storage?.clearUserId();
    state = const AuthState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

