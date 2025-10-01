import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/geocoding_service.dart';

class LocationState {
  final Position? position;
  final String? cityName;
  final bool isLoading;

  const LocationState({
    this.position,
    this.cityName,
    this.isLoading = false,
  });

  LocationState copyWith({
    Position? position,
    String? cityName,
    bool? isLoading,
  }) {
    return LocationState(
      position: position ?? this.position,
      cityName: cityName ?? this.cityName,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(const LocationState()) {
    _init();
  }

  final _locationService = LocationService();
  final _geocodingService = GeocodingService();
  Timer? _timer;

  Future<void> _init() async {
    await _updateLocation();
    
    // Update location periodically
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      _updateLocation();
    });
  }

  Future<void> _updateLocation() async {
    state = state.copyWith(isLoading: true);
    
    print('🌍 Fetching location...');
    final position = await _locationService.getCurrentPositionSafe();
    print('📍 Position: ${position?.latitude}, ${position?.longitude}');
    
    if (position != null) {
      // Get city name
      print('🔍 Getting city name...');
      final cityName = await _geocodingService.getShortLocation(position);
      print('🏙️ City: $cityName');
      
      state = LocationState(
        position: position,
        cityName: cityName ?? 'Location: ${position.latitude.toStringAsFixed(2)}°, ${position.longitude.toStringAsFixed(2)}°',
        isLoading: false,
      );
    } else {
      print('❌ No position available');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Manually refresh location
  Future<void> refresh() async {
    await _updateLocation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

