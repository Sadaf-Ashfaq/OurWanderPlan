import 'package:flutter/material.dart';
import '../theme.dart';
import '../likes_provider.dart';
import '../widgets/place_card.dart';

class LikesPage extends StatefulWidget {
  const LikesPage({super.key});

  @override
  State<LikesPage> createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> {
  @override
  void initState() {
    super.initState();
    likesProvider.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    likesProvider.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liked = likesProvider.liked;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Saved Places', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              Text('${liked.length} place${liked.length == 1 ? '' : 's'} saved',
                  style: const TextStyle(color: AppTheme.textMid)),
            ]),
          ),
          Expanded(
            child: liked.isEmpty
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No saved places yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textMid)),
                      const SizedBox(height: 8),
                      const Text('Heart a place to save it here', style: TextStyle(color: AppTheme.textMid)),
                    ]),
                  )
                : ListView.builder(
                    itemCount: liked.length,
                    itemBuilder: (_, i) => PlaceCard(place: liked[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
