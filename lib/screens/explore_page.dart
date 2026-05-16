// lib/pages/explore_page.dart
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/place_model.dart';
import '../services/opentripmap_service.dart';
import '../widgets/place_card.dart';

class ExplorePage extends StatefulWidget {
  final double? lat;
  final double? lon;
  const ExplorePage({super.key, this.lat, this.lon});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String _filter = 'All';
  final _filters = ['All', 'Hotels', 'Food', 'Places'];
  List<Place> _all = [];
  bool _loading = true;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _query = _searchController.text.trim().toLowerCase()),
    );
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ExplorePage old) {
    super.didUpdateWidget(old);
    if (old.lat != widget.lat || old.lon != widget.lon) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final lat = widget.lat ?? 24.8607;
    final lon = widget.lon ?? 67.0011;
    try {
      final results = await Future.wait([
        OpenTripMapService.fetchAttractions(lat, lon),
        OpenTripMapService.fetchHotels(lat, lon),
        OpenTripMapService.fetchFood(lat, lon),
      ]);
      if (!mounted) return;
      final combined = [...results[0], ...results[1], ...results[2]];
      setState(() {
        _all = combined.isEmpty ? samplePlaces : combined;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _all = samplePlaces;
        _loading = false;
      });
    }
  }

  List<Place> get _filtered {
    // First apply type filter
    List<Place> byType;
    switch (_filter) {
      case 'Hotels':  byType = _all.where((p) => p.type == 'hotel').toList();
      case 'Food':    byType = _all.where((p) => p.type == 'restaurant').toList();
      case 'Places':  byType = _all.where((p) => p.type == 'attraction').toList();
      default:        byType = _all;
    }
    // Then apply search query on top
    if (_query.isEmpty) return byType;
    return byType
        .where((p) =>
            p.name.toLowerCase().contains(_query) ||
            p.location.toLowerCase().contains(_query) ||
            p.description.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Explore',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const Text('Discover amazing places near you',
                  style: TextStyle(color: AppTheme.textMid)),
              const SizedBox(height: 16),
              // ── Search bar ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
                ),
                child: Row(children: [
                  const Icon(Icons.search, color: AppTheme.textMid),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search places...',
                        hintStyle: TextStyle(color: AppTheme.textMid, fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () => _searchController.clear(),
                      child: const Icon(Icons.close, color: AppTheme.textMid, size: 18),
                    ),
                ]),
              ),
              const SizedBox(height: 16),
              // ── Filter chips ──
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _filters.map((f) {
                    final selected = _filter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
                        ),
                        child: Text(f,
                            style: TextStyle(
                              color: selected ? Colors.white : AppTheme.textMid,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            )),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            _query.isNotEmpty ? 'No results for "$_query"' : 'No $_filter found nearby',
                            style: const TextStyle(color: AppTheme.textMid, fontSize: 16),
                          ),
                        ]),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => PlaceCard(place: _filtered[i]),
                      ),
          ),
        ],
      ),
    );
  }
}