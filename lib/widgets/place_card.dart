// lib/widgets/place_card.dart
import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../likes_provider.dart';
import '../theme.dart';

class PlaceCard extends StatefulWidget {
  final Place place;
  const PlaceCard({super.key, required this.place});

  @override
  State<PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<PlaceCard> {
  @override
  void initState() {
    super.initState();
    likesProvider.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    likesProvider.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.place;
    final liked = likesProvider.isLiked(p.id);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // FIX 3: no more hardcoded white
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          // ── Image ──────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: p.image.isNotEmpty
                ? Image.network(
                    p.image,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    // FIX 1: show shimmer while loading
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _shimmer();
                    },
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),

          // ── Details ────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + like button
                  Row(children: [
                    Expanded(
                      child: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => likesProvider.toggle(p),
                      child: Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        color: liked ? Colors.redAccent : Colors.grey.shade400,
                        size: 22,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),

                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _typeColor(p.type).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _typeLabel(p.type),
                      style: TextStyle(
                        fontSize: 11,
                        color: _typeColor(p.type),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Location
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textMid),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        p.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMid),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 2),

                  // Opening hours
                  Row(children: [
                    const Icon(Icons.access_time, size: 13, color: AppTheme.textMid),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        p.openingHours,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMid),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),

                  // FIX 2: show rating (was in model but never displayed)
                  Row(children: [
                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text(
                      p.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pulsing grey box while image loads
  Widget _shimmer() => Container(
        width: 100,
        height: 100,
        color: Colors.grey.shade200,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );

  Widget _placeholder() => Container(
        width: 100,
        height: 100,
        color: Colors.grey.shade200,
        child: const Icon(Icons.photo, color: Colors.grey),
      );

  Color _typeColor(String type) {
    if (type == 'hotel') return Colors.indigo;
    if (type == 'restaurant') return Colors.orange;
    return AppTheme.primary;
  }

  String _typeLabel(String type) {
    if (type == 'hotel') return '🏨 Hotel';
    if (type == 'restaurant') return '🍽️ Food';
    return '🏛️ Attraction';
  }
}