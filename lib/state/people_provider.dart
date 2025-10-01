import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../models/person.dart';
import '../repositories/mock_repository.dart';
import '../api/api_providers.dart';
import '../api/proximity_api.dart';
import '../services/location_service.dart';
import 'filters_provider.dart';
import 'auth_state.dart';

final peopleProvider = StateNotifierProvider<PeopleNotifier, List<Person>>((ref) {
  final proximityApi = ref.watch(proximityApiProvider);
  final authState = ref.watch(authStateProvider);
  final locationService = LocationService();
  
  return PeopleNotifier(
    MockRepository(), 
    proximityApi,
    authState.isAuthenticated,
    locationService,
  );
});

final filteredPeopleProvider = Provider<List<Person>>((ref) {
  final people = ref.watch(peopleProvider);
  final filters = ref.watch(filtersProvider);
  return people.where((p) {
    // Group filter
    if (filters.selectedGroupIds.isNotEmpty &&
        p.groupIds.intersection(filters.selectedGroupIds).isEmpty) {
      return false;
    }
    // Distance filter
    switch (filters.distance) {
      case DistanceFilter.all:
        return true; // show all rings
      case DistanceFilter.neighborhood:
        return p.distanceMeters < ProximityConstants.neighborhoodRangeM;
      case DistanceFilter.city:
        return p.distanceMeters < ProximityConstants.cityRangeM; // includes neighborhood
      case DistanceFilter.country:
        return p.distanceMeters < ProximityConstants.countryRangeM; // includes city + neighborhood
    }
  }).toList()
    ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
});

class PeopleNotifier extends StateNotifier<List<Person>> {
  PeopleNotifier(
    this._mockRepo,
    this._proximityApi,
    this._isAuthenticated,
    this._locationService,
  ) : super([]) {
    if (_isAuthenticated) {
      _startLocationUpdates();
      loadNearbyPeople();
    } else {
      // Use mock data when not authenticated
      state = _mockRepo.loadPeople();
    }
  }

  final MockRepository _mockRepo;
  final ProximityApi _proximityApi;
  final bool _isAuthenticated;
  final LocationService _locationService;
  Timer? _locationTimer;

  /// Start periodic location updates to backend
  void _startLocationUpdates() async {
    if (!_isAuthenticated) return;

    // Update location every 30 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _sendLocationUpdate();
    });

    // Initial location update
    await _sendLocationUpdate();
  }

  /// Send location update to backend and via WebSocket
  Future<void> _sendLocationUpdate() async {
    final position = await _locationService.getCurrentPositionSafe();
    if (position != null) {
      try {
        // Send to REST API
        await _proximityApi.updateLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
        );
        
        // Refresh nearby people after location update
        await loadNearbyPeople();
      } catch (e) {
        print('Error updating location: $e');
      }
    }
  }

  /// Load nearby people from backend
  Future<void> loadNearbyPeople() async {
    if (!_isAuthenticated) return;

    try {
      final people = await _proximityApi.getNearbyUsers(
        maxDistanceMeters: ProximityConstants.maxRadarRangeM,
        limit: 100,
      );
      state = people;
    } catch (e) {
      print('Error loading nearby people: $e');
      // Fallback to mock data on error
      if (state.isEmpty) {
        state = _mockRepo.loadPeople();
      }
    }
  }

  void ping(String personId) {
    // Ping is handled by MessagesApi now
  }

  void randomizeSlightMovement() {
    // Keep for backwards compatibility with mock mode
    if (_isAuthenticated) return;
    
    final rng = Random();
    state = [
      for (final p in state)
        p.copyWith(
          distanceMeters: (p.distanceMeters + (rng.nextDouble() - 0.5) * 2 * ProximityConstants.movementJitterM)
              .clamp(ProximityConstants.minMockDistanceM, ProximityConstants.maxMockDistanceM)
              .toDouble(),
          angleRadians: p.angleRadians + (rng.nextDouble() - 0.5) * 0.1,
        )
    ];
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }
}


