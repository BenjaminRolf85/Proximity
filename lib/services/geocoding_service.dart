import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class GeocodingService {
  /// Get short location string (City, Country)
  /// Uses Nominatim API for web compatibility
  Future<String?> getShortLocation(Position position) async {
    try {
      // Try native geocoding first (works on mobile)
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea;
          final country = place.country;
          
          if (city != null && country != null) {
            return '$city, $country';
          } else if (city != null) {
            return city;
          } else if (country != null) {
            return country;
          }
        }
      } catch (e) {
        print('Native geocoding failed, trying Nominatim: $e');
      }

      // Fallback to Nominatim for web
      return await _getNominatimLocation(position);
    } catch (e) {
      print('Geocoding error: $e');
      // Fallback: show coordinates
      return '${position.latitude.toStringAsFixed(2)}°, ${position.longitude.toStringAsFixed(2)}°';
    }
  }

  /// Use Nominatim OpenStreetMap API (free, no API key needed)
  Future<String?> _getNominatimLocation(Position position) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
        'format=json&'
        'lat=${position.latitude}&'
        'lon=${position.longitude}&'
        'zoom=10&'
        'addressdetails=1'
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'ProximitySocialApp/1.0'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        
        if (address != null) {
          final city = address['city'] as String? ?? 
                      address['town'] as String? ?? 
                      address['village'] as String? ??
                      address['municipality'] as String?;
          final country = address['country'] as String?;
          
          if (city != null && country != null) {
            return '$city, $country';
          } else if (city != null) {
            return city;
          } else if (country != null) {
            return country;
          }
        }
      }
      return null;
    } catch (e) {
      print('Nominatim error: $e');
      return null;
    }
  }
}

