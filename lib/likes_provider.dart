import 'package:flutter/foundation.dart';
import 'models/place_model.dart';

class LikesProvider extends ChangeNotifier {
  final List<Place> _liked = [];

  List<Place> get liked => List.unmodifiable(_liked);

  bool isLiked(String id) => _liked.any((p) => p.id == id);

  void toggle(Place place) {
    if (isLiked(place.id)) {
      _liked.removeWhere((p) => p.id == place.id);
    } else {
      _liked.add(place);
    }
    notifyListeners();
  }
}

final likesProvider = LikesProvider();