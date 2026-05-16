// lib/widgets/carousel_card.dart
import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../likes_provider.dart';
import '../theme.dart';

class CarouselCard extends StatefulWidget {
  final Place place;
  const CarouselCard({super.key, required this.place});

  @override
  State<CarouselCard> createState() => _CarouselCardState();
}

class _CarouselCardState extends State<CarouselCard> {
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
      width: 200,
      margin: const EdgeInsets.only(right: 16, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.09), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: p.image.isNotEmpty
                ? Image.network(p.image, height: 140, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
                  ),
                  GestureDetector(
                    onTap: () => likesProvider.toggle(p),
                    child: Icon(liked ? Icons.favorite : Icons.favorite_border,
                        color: liked ? Colors.redAccent : Colors.grey.shade400, size: 20),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(p.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.star, size: 13, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(p.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
      height: 140, color: Colors.grey.shade200,
      child: const Icon(Icons.photo, color: Colors.grey, size: 40));
}