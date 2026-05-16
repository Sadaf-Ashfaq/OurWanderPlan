// lib/pages/location_page.dart
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/location_service.dart';

class LocationPage extends StatefulWidget {
  /// Called when user selects/detects a city.
  /// Passes city name, latitude, longitude.
  final Function(String city, double lat, double lon) onCitySelected;
  final String currentCity;

  const LocationPage({
    super.key,
    required this.onCitySelected,
    required this.currentCity,
  });

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  late String _selectedCity;
  bool _detecting = false;

  // Each city has a name, icon, lat, lon
  final List<Map<String, dynamic>> _cities = [
    {'name': 'Karachi, Pakistan',   'icon': Icons.waves,            'lat': 24.8607, 'lon': 67.0011},
    {'name': 'Lahore, Pakistan',    'icon': Icons.account_balance,  'lat': 31.5204, 'lon': 74.3587},
    {'name': 'Islamabad, Pakistan', 'icon': Icons.park,             'lat': 33.6844, 'lon': 73.0479},
    {'name': 'Peshawar, Pakistan',  'icon': Icons.landscape,        'lat': 34.0150, 'lon': 71.5249},
    {'name': 'Quetta, Pakistan',    'icon': Icons.terrain,          'lat': 30.1798, 'lon': 66.9750},
    {'name': 'Multan, Pakistan',    'icon': Icons.sunny,            'lat': 30.1575, 'lon': 71.5249},
    {'name': 'Hunza, Pakistan',     'icon': Icons.ac_unit,          'lat': 36.3167, 'lon': 74.6500},
    {'name': 'Dubai, UAE',          'icon': Icons.location_city,    'lat': 25.2048, 'lon': 55.2708},
    {'name': 'Istanbul, Turkey',    'icon': Icons.mosque,           'lat': 41.0082, 'lon': 28.9784},
    {'name': 'Bali, Indonesia',     'icon': Icons.beach_access,     'lat': -8.3405, 'lon': 115.0920},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.currentCity;
  }

  Future<void> _detectLocation() async {
    setState(() => _detecting = true);
    final coords = await LocationService.getCurrentLatLon();
    if (!mounted) return;

    if (coords != null) {
      final cityName = await LocationService.reverseGeocode(coords[0], coords[1]);
      if (!mounted) return;
      setState(() {
        _detecting = false;
        _selectedCity = cityName;
      });
      widget.onCitySelected(cityName, coords[0], coords[1]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📍 Location detected: $cityName'), backgroundColor: const Color(0xFF26C6DA)),
      );
    } else {
      setState(() => _detecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Could not get location. Please allow access.'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your Location',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 4),
              const Text('Select or detect your current city',
                  style: TextStyle(color: AppTheme.textMid)),
              const SizedBox(height: 20),

              // Current city card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FC3F7), Color(0xFF26C6DA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Current City', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(_selectedCity,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),

              // Detect button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _detecting ? null : _detectLocation,
                  icon: _detecting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                      : const Icon(Icons.my_location, color: AppTheme.primary),
                  label: Text(_detecting ? 'Detecting...' : 'Detect My Location',
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ]),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Choose a City',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _cities.length,
              itemBuilder: (_, i) {
                final city = _cities[i];
                final selected = _selectedCity == city['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCity = city['name'] as String);
                    widget.onCitySelected(
                      city['name'] as String,
                      city['lat'] as double,
                      city['lon'] as double,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected ? AppTheme.primary : Colors.transparent),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                    ),
                    child: Row(children: [
                      Icon(city['icon'] as IconData, color: selected ? AppTheme.primary : AppTheme.textMid, size: 22),
                      const SizedBox(width: 14),
                      Text(city['name'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected ? AppTheme.primary : AppTheme.textDark,
                          )),
                      const Spacer(),
                      if (selected) const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}