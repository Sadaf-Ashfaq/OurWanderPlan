import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_page.dart';
import 'location_page.dart';
import 'explore_page.dart';
import 'trips_page.dart';
import 'likes_page.dart';
import 'profile_page.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;
  String _city = 'Detecting...';
  double _lat = 24.8607;
  double _lon = 67.0011;

  void _onCitySelected(String city, double lat, double lon) {
    setState(() {
      _city = city;
      _lat = lat;
      _lon = lon;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(city: _city, lat: _lat, lon: _lon),
      LocationPage(onCitySelected: _onCitySelected, currentCity: _city),
      ExplorePage(lat: _lat, lon: _lon),
      const TripsPage(),
      const LikesPage(),
      const ProfilePage(), // ← Profile page hai, lekin navbar mein nahi dikhega
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primary.withOpacity(0.15),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.location_on_outlined),
              selectedIcon: Icon(Icons.location_on),
              label: 'Location',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.luggage_outlined),
              selectedIcon: Icon(Icons.luggage),
              label: 'Trips',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_outline),
              selectedIcon: Icon(Icons.favorite),
              label: 'Likes',
            ),
        
          ],
        ),
      ),
    );
  }
}