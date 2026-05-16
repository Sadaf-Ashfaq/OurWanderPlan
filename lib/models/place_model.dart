// lib/models/place_model.dart

class Place {
  final String id;
  final String name;
  final String description;
  final String image;       // URL string (may be empty)
  final String type;        // 'hotel' | 'restaurant' | 'attraction'
  final String location;
  final String openingHours;
  final double rating;

  const Place({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.type,
    required this.location,
    required this.openingHours,
    required this.rating,
  });
}

// Fallback / sample data (used only when API fails or has no results) 

const List<Place> samplePlaces = [
  Place(
    id: 's1',
    name: 'Mohatta Palace',
    description: 'A beautiful palace museum in Karachi with historical artifacts.',
    image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7e/Mohatta_Palace_Museum.jpg/640px-Mohatta_Palace_Museum.jpg',
    type: 'attraction',
    location: 'Clifton, Karachi',
    openingHours: '9 AM – 6 PM',
    rating: 4.5,
  ),
  Place(
    id: 's2',
    name: 'Monal Restaurant',
    description: 'Popular restaurant with scenic views and Pakistani cuisine.',
    image: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400',
    type: 'restaurant',
    location: 'Islamabad',
    openingHours: '12 PM – 11 PM',
    rating: 4.3,
  ),
  Place(
    id: 's3',
    name: 'Pearl Continental Hotel',
    description: 'Five-star luxury hotel in the heart of the city.',
    image: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400',
    type: 'hotel',
    location: 'Karachi',
    openingHours: 'Open 24 hours',
    rating: 4.6,
  ),
  Place(
    id: 's4',
    name: 'Lahore Fort',
    description: 'UNESCO World Heritage Site — a Mughal masterpiece.',
    image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/04/Lahore_Fort_2.jpg/640px-Lahore_Fort_2.jpg',
    type: 'attraction',
    location: 'Lahore',
    openingHours: '8 AM – 5 PM',
    rating: 4.7,
  ),
  Place(
    id: 's5',
    name: 'Avari Hotel Lahore',
    description: 'Luxury hotel with top-class amenities in Lahore.',
    image: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=400',
    type: 'hotel',
    location: 'Lahore',
    openingHours: 'Open 24 hours',
    rating: 4.4,
  ),
];

// Carousel uses the first 3 from sample as a fallback
List<Place> carouselPlaces = samplePlaces.take(3).toList();