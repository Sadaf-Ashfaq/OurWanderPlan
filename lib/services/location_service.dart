import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  /// Returns [lat, lon] or null if denied / error.
  /// Works on Flutter Web (browser) and Android/iOS.
  static Future<List<double>?> getCurrentLatLon() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      return [pos.latitude, pos.longitude];
    } catch (_) {
      return null;
    }
  }

  /// Converts lat/lon to a readable city name using OpenStreetMap Nominatim.
  /// Free, no key required.
  static Future<String> reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json');
      final res = await http.get(uri, headers: {'User-Agent': 'TravelGuideApp/1.0'});
      if (res.statusCode != 200) return 'Unknown Location';
      final body = jsonDecode(res.body);
      final address = body['address'] as Map?;
      final city = address?['city'] ??
          address?['town'] ??
          address?['village'] ??
          address?['county'] ??
          'Unknown City';
      final country = address?['country'] ?? '';
      return '$city, $country';
    } catch (_) {
      return 'Unknown Location';
    }
  }
}