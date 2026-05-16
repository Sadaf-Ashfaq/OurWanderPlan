import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_model.dart';

class OpenTripMapService {
  static const _apiKey = '5ae2e3f221c38a28845f05b6e71aef74dc5b4a1f2538c8f75247b82d';
  static const _base = 'https://api.opentripmap.com/0.1/en/places';

  static Future<List<Place>> fetchNearby({
    required double lat,
    required double lon,
    // FIX 2: much more diverse kinds — not just interesting_places
    String kind = 'interesting_places,cultural,historic,architecture,natural,amusements,sport,shops,foods,restaurants,cafes',
    int radius = 5000,
    int limit = 20,
  }) async {
    final listUrl = Uri.parse(
      '$_base/radius?radius=$radius&lon=$lon&lat=$lat'
      '&kinds=$kind&limit=$limit&apikey=$_apiKey',
    );

    final listRes = await http.get(listUrl);
    if (listRes.statusCode != 200) return [];

    final features = (jsonDecode(listRes.body)['features'] as List?) ?? [];
    if (features.isEmpty) return [];

    // FIX 4: fetch all details in parallel instead of one by one
    final xids = features
        .map((f) => f['properties']?['xid'] as String?)
        .whereType<String>()
        .take(limit)
        .toList();

    final results = await Future.wait(xids.map((xid) => _fetchDetail(xid)));
    return results.whereType<Place>().toList();
  }

  static Future<Place?> _fetchDetail(String xid) async {
    final url = Uri.parse('$_base/xid/$xid?apikey=$_apiKey');
    final res = await http.get(url);
    if (res.statusCode != 200) return null;

    final d = jsonDecode(res.body);
    final name = (d['name'] ?? '').toString().trim();
    if (name.isEmpty) return null;

    final kinds = (d['kinds'] ?? '') as String;

    // Determine type
    String type = 'attraction';
    if (kinds.contains('accomodations') || kinds.contains('hotel')) {
      type = 'hotel';
    } else if (kinds.contains('foods') || kinds.contains('restaurants') || kinds.contains('cafe')) {
      type = 'restaurant';
    }

    final address = d['address'];
    final locationText = address != null
        ? [address['city'], address['country']]
            .where((e) => e != null && e.toString().isNotEmpty)
            .join(', ')
        : '';

    // FIX 1: if no image, use Unsplash fallback based on place name/type
    final rawImage = (d['preview']?['source'] ?? d['image'] ?? '').toString();
    final image = rawImage.isNotEmpty
        ? rawImage
        : _fallbackImage(name, type);

    // FIX 3: OTM rate is 1–7, map it to a 1.0–5.0 star scale
    final rawRate = d['rate'];
    double rating = 3.0; // default to 3 stars
    if (rawRate != null) {
      final r = double.tryParse(rawRate.toString()) ?? 0;
      // OTM scale: 1=low, 7=high → map to 1.0–5.0
      rating = r > 0 ? ((r / 7) * 4 + 1).clamp(1.0, 5.0) : 3.0;
      rating = double.parse(rating.toStringAsFixed(1));
    }

    return Place(
      id: xid,
      name: name,
      description: d['wikipedia_extracts']?['text'] ??
          kinds.replaceAll(',', ', '),
      image: image,
      type: type,
      location: locationText,
      openingHours: d['opening_hours']?.toString() ?? 'Check locally',
      rating: rating,
    );
  }

  // FIX 1 helper: free Unsplash image based on category
  static String _fallbackImage(String name, String type) {
    final query = Uri.encodeComponent(
      type == 'hotel'
          ? 'hotel building'
          : type == 'restaurant'
              ? 'restaurant food'
              : name.length > 3
                  ? name
                  : 'karachi landmark',
    );
    // Unsplash Source — free, no API key needed
    return 'https://source.unsplash.com/400x300/?$query';
  }

  static Future<List<Place>> fetchAttractions(double lat, double lon) =>
      fetchNearby(
        lat: lat,
        lon: lon,
        kind: 'interesting_places,cultural,historic,architecture,natural,amusements',
      );

  static Future<List<Place>> fetchHotels(double lat, double lon) =>
      fetchNearby(lat: lat, lon: lon, kind: 'accomodations');

  static Future<List<Place>> fetchFood(double lat, double lon) =>
      fetchNearby(lat: lat, lon: lon, kind: 'foods,restaurants,cafes');
}