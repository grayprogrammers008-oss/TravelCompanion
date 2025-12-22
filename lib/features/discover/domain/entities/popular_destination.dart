import 'package:flutter/material.dart';

/// Model for a popular tourist destination
class PopularDestination {
  final String id;
  final String name;
  final String country;
  final String region;
  final String description;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final List<String> highlights;
  final String bestTimeToVisit;

  const PopularDestination({
    required this.id,
    required this.name,
    required this.country,
    required this.region,
    required this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.highlights,
    required this.bestTimeToVisit,
  });
}

/// Static data for popular destinations grouped by country
class PopularDestinations {
  static const List<PopularDestination> india = [
    // North India
    PopularDestination(
      id: 'jaipur',
      name: 'Jaipur',
      country: 'India',
      region: 'North India',
      description: 'The Pink City - known for majestic forts and vibrant culture',
      imageUrl: 'https://images.unsplash.com/photo-1477587458883-47145ed94245?w=400',
      latitude: 26.9124,
      longitude: 75.7873,
      highlights: ['Amber Fort', 'Hawa Mahal', 'City Palace', 'Nahargarh Fort'],
      bestTimeToVisit: 'October - March',
    ),
    PopularDestination(
      id: 'agra',
      name: 'Agra',
      country: 'India',
      region: 'North India',
      description: 'Home to the iconic Taj Mahal, a UNESCO World Heritage Site',
      imageUrl: 'https://images.unsplash.com/photo-1564507592333-c60657eea523?w=400',
      latitude: 27.1767,
      longitude: 78.0081,
      highlights: ['Taj Mahal', 'Agra Fort', 'Fatehpur Sikri', 'Mehtab Bagh'],
      bestTimeToVisit: 'October - March',
    ),
    PopularDestination(
      id: 'varanasi',
      name: 'Varanasi',
      country: 'India',
      region: 'North India',
      description: 'One of the oldest living cities, spiritual capital of India',
      imageUrl: 'https://images.unsplash.com/photo-1561361513-2d000a50f0dc?w=400',
      latitude: 25.3176,
      longitude: 82.9739,
      highlights: ['Dashashwamedh Ghat', 'Kashi Vishwanath', 'Sarnath', 'Boat Rides'],
      bestTimeToVisit: 'November - February',
    ),
    PopularDestination(
      id: 'shimla',
      name: 'Shimla',
      country: 'India',
      region: 'North India',
      description: 'Queen of Hills - colonial charm meets mountain beauty',
      imageUrl: 'https://images.unsplash.com/photo-1597074866923-dc0589150358?w=400',
      latitude: 31.1048,
      longitude: 77.1734,
      highlights: ['Mall Road', 'Ridge', 'Christ Church', 'Jakhoo Temple'],
      bestTimeToVisit: 'March - June',
    ),
    // South India
    PopularDestination(
      id: 'kerala',
      name: 'Kerala Backwaters',
      country: 'India',
      region: 'South India',
      description: 'God\'s Own Country - serene backwaters and lush greenery',
      imageUrl: 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?w=400',
      latitude: 9.4981,
      longitude: 76.3388,
      highlights: ['Houseboat Stay', 'Munnar', 'Thekkady', 'Kovalam Beach'],
      bestTimeToVisit: 'September - March',
    ),
    PopularDestination(
      id: 'mysore',
      name: 'Mysore',
      country: 'India',
      region: 'South India',
      description: 'City of Palaces - rich heritage and royal grandeur',
      imageUrl: 'https://images.unsplash.com/photo-1600100397608-e1bd6ba9c8e1?w=400',
      latitude: 12.2958,
      longitude: 76.6394,
      highlights: ['Mysore Palace', 'Chamundi Hills', 'Brindavan Gardens', 'St. Philomena\'s Church'],
      bestTimeToVisit: 'October - February',
    ),
    PopularDestination(
      id: 'ooty',
      name: 'Ooty',
      country: 'India',
      region: 'South India',
      description: 'Queen of Hill Stations - tea gardens and misty mountains',
      imageUrl: 'https://images.unsplash.com/photo-1585136917228-b5e7a44a8e40?w=400',
      latitude: 11.4102,
      longitude: 76.6950,
      highlights: ['Botanical Garden', 'Ooty Lake', 'Tea Factory', 'Nilgiri Mountain Railway'],
      bestTimeToVisit: 'April - June',
    ),
    // West India
    PopularDestination(
      id: 'goa',
      name: 'Goa',
      country: 'India',
      region: 'West India',
      description: 'Beach paradise with Portuguese heritage and vibrant nightlife',
      imageUrl: 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=400',
      latitude: 15.2993,
      longitude: 74.1240,
      highlights: ['Baga Beach', 'Basilica of Bom Jesus', 'Dudhsagar Falls', 'Fort Aguada'],
      bestTimeToVisit: 'November - February',
    ),
    PopularDestination(
      id: 'udaipur',
      name: 'Udaipur',
      country: 'India',
      region: 'West India',
      description: 'City of Lakes - romantic palaces and stunning sunsets',
      imageUrl: 'https://images.unsplash.com/photo-1568495248636-6432b97bd949?w=400',
      latitude: 24.5854,
      longitude: 73.7125,
      highlights: ['Lake Pichola', 'City Palace', 'Jag Mandir', 'Jagdish Temple'],
      bestTimeToVisit: 'September - March',
    ),
    // East India
    PopularDestination(
      id: 'darjeeling',
      name: 'Darjeeling',
      country: 'India',
      region: 'East India',
      description: 'Land of Thunderbolt - tea estates and Himalayan views',
      imageUrl: 'https://images.unsplash.com/photo-1544634076-a90c05b27551?w=400',
      latitude: 27.0410,
      longitude: 88.2663,
      highlights: ['Tiger Hill', 'Batasia Loop', 'Tea Gardens', 'Peace Pagoda'],
      bestTimeToVisit: 'March - May, October - November',
    ),
    PopularDestination(
      id: 'sundarbans',
      name: 'Sundarbans',
      country: 'India',
      region: 'East India',
      description: 'World\'s largest mangrove forest - home to Royal Bengal Tigers',
      imageUrl: 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=400',
      latitude: 21.9497,
      longitude: 89.1833,
      highlights: ['Tiger Safari', 'Mangrove Forests', 'Boat Rides', 'Bird Watching'],
      bestTimeToVisit: 'September - March',
    ),
  ];

  /// Get destinations grouped by region
  static Map<String, List<PopularDestination>> getByRegion() {
    final Map<String, List<PopularDestination>> grouped = {};
    for (final dest in india) {
      grouped.putIfAbsent(dest.region, () => []).add(dest);
    }
    return grouped;
  }

  /// Get all unique regions
  static List<String> getRegions() {
    return india.map((d) => d.region).toSet().toList();
  }
}

/// Region data with icon and color
class RegionInfo {
  final String name;
  final IconData icon;
  final Color color;

  const RegionInfo({
    required this.name,
    required this.icon,
    required this.color,
  });

  static RegionInfo getInfo(String region) {
    switch (region) {
      case 'North India':
        return const RegionInfo(
          name: 'North India',
          icon: Icons.landscape,
          color: Color(0xFF2196F3), // Blue
        );
      case 'South India':
        return const RegionInfo(
          name: 'South India',
          icon: Icons.water,
          color: Color(0xFF4CAF50), // Green
        );
      case 'West India':
        return const RegionInfo(
          name: 'West India',
          icon: Icons.beach_access,
          color: Color(0xFFFF9800), // Orange
        );
      case 'East India':
        return const RegionInfo(
          name: 'East India',
          icon: Icons.forest,
          color: Color(0xFF9C27B0), // Purple
        );
      default:
        return const RegionInfo(
          name: 'Other',
          icon: Icons.place,
          color: Color(0xFF607D8B), // Grey
        );
    }
  }
}
