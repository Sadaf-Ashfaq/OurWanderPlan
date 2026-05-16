import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/trip_model.dart';
import '../services/storage_service.dart';
import '../widgets/trip_card.dart';
import 'create_trip_page.dart';
import 'trip_detail_page.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  bool _syncing = true;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    await StorageService.syncTripsFromFirestore();
    await StorageService.syncExpensesFromFirestore();
    if (mounted) setState(() => _syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final trips = StorageService.getAllTrips()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Trips'),
        elevation: 0,
        actions: [
          // Manual refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _sync,
          ),
        ],
      ),
      body: _syncing
          ? const Center(child: CircularProgressIndicator())
          : trips.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    return TripCard(
                      trip: trips[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripDetailPage(trip: trips[index]),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTripPage()),
          ).then((_) => setState(() {}));
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.luggage_outlined, size: 64, color: AppTheme.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'No trips yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create one to get started!',
            style: TextStyle(color: AppTheme.textMid),
          ),
        ],
      ),
    );
  }
}