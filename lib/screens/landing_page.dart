import 'package:flutter/material.dart';
import 'login_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          //background image
          Image.network(
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Dark overlay for readability
          Container(color: Colors.black.withOpacity(0.4)),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),
                  // Logo
                  Row(children: [
                    const Icon(Icons.flight_takeoff, color: Colors.white, size: 32),
                    const SizedBox(width: 10),
                    Text('WanderPlan',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2,
                        )),
                  ]),
                  const SizedBox(height: 24),
                  // Main tagline
                  const Text('Explore.',
                      style: TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w800, height: 1.1)),
                  const Text('Travel.',
                      style: TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w800, height: 1.1)),
                  const Text('Inspire.',
                      style: TextStyle(color: Color(0xFF80DEEA), fontSize: 52, fontWeight: FontWeight.w800, height: 1.1)),
                  const SizedBox(height: 20),
                  Text('Discover beautiful destinations\naround the world.',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, height: 1.5)),
                  const Spacer(flex: 3),
                  // Get Started button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const LoginPage())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Get Started', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
