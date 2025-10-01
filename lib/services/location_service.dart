import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<bool> ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Stream<Position> positionStream() {
    const settings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5);
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  Future<Position?> getCurrentPositionSafe() async {
    final ok = await ensurePermission();
    if (!ok) return null;
    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) {
      return null;
    }
  }
}


