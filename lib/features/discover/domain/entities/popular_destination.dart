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
  /// All destinations from all countries
  static List<PopularDestination> get all => [
    ...india,
    ...thailand,
    ...japan,
    ...indonesia,
    ...singapore,
    ...uae,
    ...france,
    ...italy,
    ...uk,
    ...usa,
    ...australia,
    ...maldives,
    ...switzerland,
  ];

  /// Get all unique countries
  static List<String> getCountries() {
    return all.map((d) => d.country).toSet().toList()..sort();
  }

  /// Get destinations by country
  static List<PopularDestination> getByCountry(String country) {
    return all.where((d) => d.country == country).toList();
  }

  /// Get destinations grouped by country
  static Map<String, List<PopularDestination>> groupByCountry() {
    final Map<String, List<PopularDestination>> grouped = {};
    for (final dest in all) {
      grouped.putIfAbsent(dest.country, () => []).add(dest);
    }
    return grouped;
  }

  // ===== INDIA =====
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

  // ===== THAILAND =====
  static const List<PopularDestination> thailand = [
    PopularDestination(
      id: 'bangkok',
      name: 'Bangkok',
      country: 'Thailand',
      region: 'Central Thailand',
      description: 'Vibrant capital with ornate temples and bustling street life',
      imageUrl: 'https://images.unsplash.com/photo-1508009603885-50cf7c579365?w=400',
      latitude: 13.7563,
      longitude: 100.5018,
      highlights: ['Grand Palace', 'Wat Arun', 'Chatuchak Market', 'Khao San Road'],
      bestTimeToVisit: 'November - February',
    ),
    PopularDestination(
      id: 'phuket',
      name: 'Phuket',
      country: 'Thailand',
      region: 'Southern Thailand',
      description: 'Thailand\'s largest island with stunning beaches and nightlife',
      imageUrl: 'https://images.unsplash.com/photo-1589394815804-964ed0be2eb5?w=400',
      latitude: 7.8804,
      longitude: 98.3923,
      highlights: ['Patong Beach', 'Phi Phi Islands', 'Big Buddha', 'Old Town'],
      bestTimeToVisit: 'November - April',
    ),
    PopularDestination(
      id: 'chiang-mai',
      name: 'Chiang Mai',
      country: 'Thailand',
      region: 'Northern Thailand',
      description: 'Cultural heart of Thailand with ancient temples and mountains',
      imageUrl: 'https://images.unsplash.com/photo-1528181304800-259b08848526?w=400',
      latitude: 18.7883,
      longitude: 98.9853,
      highlights: ['Doi Suthep', 'Old City Temples', 'Night Bazaar', 'Elephant Sanctuaries'],
      bestTimeToVisit: 'November - February',
    ),
  ];

  // ===== JAPAN =====
  static const List<PopularDestination> japan = [
    PopularDestination(
      id: 'tokyo',
      name: 'Tokyo',
      country: 'Japan',
      region: 'Kanto',
      description: 'Ultra-modern metropolis blending tradition with innovation',
      imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400',
      latitude: 35.6762,
      longitude: 139.6503,
      highlights: ['Shibuya Crossing', 'Senso-ji Temple', 'Tokyo Skytree', 'Akihabara'],
      bestTimeToVisit: 'March - May, September - November',
    ),
    PopularDestination(
      id: 'kyoto',
      name: 'Kyoto',
      country: 'Japan',
      region: 'Kansai',
      description: 'Ancient capital with thousands of classical temples and gardens',
      imageUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400',
      latitude: 35.0116,
      longitude: 135.7681,
      highlights: ['Fushimi Inari', 'Kinkaku-ji', 'Arashiyama', 'Gion District'],
      bestTimeToVisit: 'March - May, October - November',
    ),
    PopularDestination(
      id: 'osaka',
      name: 'Osaka',
      country: 'Japan',
      region: 'Kansai',
      description: 'Japan\'s kitchen - famous for street food and vibrant nightlife',
      imageUrl: 'https://images.unsplash.com/photo-1590559899731-a382839e5549?w=400',
      latitude: 34.6937,
      longitude: 135.5023,
      highlights: ['Osaka Castle', 'Dotonbori', 'Universal Studios', 'Kuromon Market'],
      bestTimeToVisit: 'March - May, September - November',
    ),
  ];

  // ===== INDONESIA =====
  static const List<PopularDestination> indonesia = [
    PopularDestination(
      id: 'bali',
      name: 'Bali',
      country: 'Indonesia',
      region: 'Lesser Sunda Islands',
      description: 'Island of the Gods - beaches, temples, and rice terraces',
      imageUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=400',
      latitude: -8.4095,
      longitude: 115.1889,
      highlights: ['Ubud Rice Terraces', 'Tanah Lot', 'Seminyak Beach', 'Mount Batur'],
      bestTimeToVisit: 'April - October',
    ),
    PopularDestination(
      id: 'jakarta',
      name: 'Jakarta',
      country: 'Indonesia',
      region: 'Java',
      description: 'Indonesia\'s massive capital with rich history and culture',
      imageUrl: 'https://images.unsplash.com/photo-1555899434-94d1368aa7af?w=400',
      latitude: -6.2088,
      longitude: 106.8456,
      highlights: ['National Monument', 'Old Town', 'Thousand Islands', 'Taman Mini'],
      bestTimeToVisit: 'June - September',
    ),
  ];

  // ===== SINGAPORE =====
  static const List<PopularDestination> singapore = [
    PopularDestination(
      id: 'singapore-city',
      name: 'Singapore',
      country: 'Singapore',
      region: 'Singapore',
      description: 'Futuristic city-state with stunning architecture and gardens',
      imageUrl: 'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=400',
      latitude: 1.3521,
      longitude: 103.8198,
      highlights: ['Marina Bay Sands', 'Gardens by the Bay', 'Sentosa Island', 'Orchard Road'],
      bestTimeToVisit: 'February - April',
    ),
  ];

  // ===== UAE =====
  static const List<PopularDestination> uae = [
    PopularDestination(
      id: 'dubai',
      name: 'Dubai',
      country: 'UAE',
      region: 'Dubai',
      description: 'City of superlatives - tallest buildings and luxury experiences',
      imageUrl: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=400',
      latitude: 25.2048,
      longitude: 55.2708,
      highlights: ['Burj Khalifa', 'Palm Jumeirah', 'Dubai Mall', 'Desert Safari'],
      bestTimeToVisit: 'November - March',
    ),
    PopularDestination(
      id: 'abu-dhabi',
      name: 'Abu Dhabi',
      country: 'UAE',
      region: 'Abu Dhabi',
      description: 'Capital city with stunning mosques and cultural landmarks',
      imageUrl: 'https://images.unsplash.com/photo-1512632578888-169bbbc64f33?w=400',
      latitude: 24.4539,
      longitude: 54.3773,
      highlights: ['Sheikh Zayed Mosque', 'Louvre Abu Dhabi', 'Yas Island', 'Corniche'],
      bestTimeToVisit: 'October - April',
    ),
  ];

  // ===== FRANCE =====
  static const List<PopularDestination> france = [
    PopularDestination(
      id: 'paris',
      name: 'Paris',
      country: 'France',
      region: 'Île-de-France',
      description: 'City of Light - art, fashion, gastronomy, and romance',
      imageUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=400',
      latitude: 48.8566,
      longitude: 2.3522,
      highlights: ['Eiffel Tower', 'Louvre Museum', 'Notre-Dame', 'Champs-Élysées'],
      bestTimeToVisit: 'April - June, September - November',
    ),
    PopularDestination(
      id: 'nice',
      name: 'Nice',
      country: 'France',
      region: 'French Riviera',
      description: 'Glamorous resort city on the stunning French Riviera',
      imageUrl: 'https://images.unsplash.com/photo-1491166617655-0723a0999cfc?w=400',
      latitude: 43.7102,
      longitude: 7.2620,
      highlights: ['Promenade des Anglais', 'Old Town', 'Castle Hill', 'Beach'],
      bestTimeToVisit: 'May - October',
    ),
  ];

  // ===== ITALY =====
  static const List<PopularDestination> italy = [
    PopularDestination(
      id: 'rome',
      name: 'Rome',
      country: 'Italy',
      region: 'Lazio',
      description: 'Eternal City - ancient ruins, art, and incredible cuisine',
      imageUrl: 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=400',
      latitude: 41.9028,
      longitude: 12.4964,
      highlights: ['Colosseum', 'Vatican City', 'Trevi Fountain', 'Roman Forum'],
      bestTimeToVisit: 'April - June, September - October',
    ),
    PopularDestination(
      id: 'venice',
      name: 'Venice',
      country: 'Italy',
      region: 'Veneto',
      description: 'Floating city of canals, gondolas, and Renaissance art',
      imageUrl: 'https://images.unsplash.com/photo-1514890547357-a9ee288728e0?w=400',
      latitude: 45.4408,
      longitude: 12.3155,
      highlights: ['St. Mark\'s Square', 'Grand Canal', 'Rialto Bridge', 'Murano Island'],
      bestTimeToVisit: 'April - June, September - November',
    ),
    PopularDestination(
      id: 'florence',
      name: 'Florence',
      country: 'Italy',
      region: 'Tuscany',
      description: 'Birthplace of Renaissance - art, architecture, and culture',
      imageUrl: 'https://images.unsplash.com/photo-1543429258-85e68e405fc4?w=400',
      latitude: 43.7696,
      longitude: 11.2558,
      highlights: ['Duomo', 'Uffizi Gallery', 'Ponte Vecchio', 'Piazza della Signoria'],
      bestTimeToVisit: 'April - June, September - October',
    ),
  ];

  // ===== UK =====
  static const List<PopularDestination> uk = [
    PopularDestination(
      id: 'london',
      name: 'London',
      country: 'United Kingdom',
      region: 'England',
      description: 'Historic capital with royal palaces and world-class museums',
      imageUrl: 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=400',
      latitude: 51.5074,
      longitude: -0.1278,
      highlights: ['Big Ben', 'Tower of London', 'British Museum', 'Buckingham Palace'],
      bestTimeToVisit: 'May - September',
    ),
    PopularDestination(
      id: 'edinburgh',
      name: 'Edinburgh',
      country: 'United Kingdom',
      region: 'Scotland',
      description: 'Scotland\'s capital with medieval old town and Georgian new town',
      imageUrl: 'https://images.unsplash.com/photo-1486299267070-83823f5448dd?w=400',
      latitude: 55.9533,
      longitude: -3.1883,
      highlights: ['Edinburgh Castle', 'Royal Mile', 'Arthur\'s Seat', 'Holyrood Palace'],
      bestTimeToVisit: 'May - September',
    ),
  ];

  // ===== USA =====
  static const List<PopularDestination> usa = [
    PopularDestination(
      id: 'new-york',
      name: 'New York City',
      country: 'USA',
      region: 'New York',
      description: 'The city that never sleeps - iconic skyline and diverse culture',
      imageUrl: 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=400',
      latitude: 40.7128,
      longitude: -74.0060,
      highlights: ['Statue of Liberty', 'Central Park', 'Times Square', 'Empire State'],
      bestTimeToVisit: 'April - June, September - November',
    ),
    PopularDestination(
      id: 'los-angeles',
      name: 'Los Angeles',
      country: 'USA',
      region: 'California',
      description: 'Entertainment capital with beaches, Hollywood, and diverse neighborhoods',
      imageUrl: 'https://images.unsplash.com/photo-1534190760961-74e8c1c5c3da?w=400',
      latitude: 34.0522,
      longitude: -118.2437,
      highlights: ['Hollywood Sign', 'Santa Monica', 'Universal Studios', 'Getty Center'],
      bestTimeToVisit: 'March - May, September - November',
    ),
    PopularDestination(
      id: 'san-francisco',
      name: 'San Francisco',
      country: 'USA',
      region: 'California',
      description: 'Iconic city with the Golden Gate Bridge and vibrant neighborhoods',
      imageUrl: 'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=400',
      latitude: 37.7749,
      longitude: -122.4194,
      highlights: ['Golden Gate Bridge', 'Alcatraz', 'Fisherman\'s Wharf', 'Cable Cars'],
      bestTimeToVisit: 'September - November',
    ),
  ];

  // ===== AUSTRALIA =====
  static const List<PopularDestination> australia = [
    PopularDestination(
      id: 'sydney',
      name: 'Sydney',
      country: 'Australia',
      region: 'New South Wales',
      description: 'Harbour city with iconic opera house and beautiful beaches',
      imageUrl: 'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=400',
      latitude: -33.8688,
      longitude: 151.2093,
      highlights: ['Sydney Opera House', 'Harbour Bridge', 'Bondi Beach', 'Taronga Zoo'],
      bestTimeToVisit: 'September - November, March - May',
    ),
    PopularDestination(
      id: 'melbourne',
      name: 'Melbourne',
      country: 'Australia',
      region: 'Victoria',
      description: 'Cultural capital with vibrant arts scene and coffee culture',
      imageUrl: 'https://images.unsplash.com/photo-1514395462725-fb4566210144?w=400',
      latitude: -37.8136,
      longitude: 144.9631,
      highlights: ['Federation Square', 'Great Ocean Road', 'Laneways', 'MCG'],
      bestTimeToVisit: 'March - May, September - November',
    ),
  ];

  // ===== MALDIVES =====
  static const List<PopularDestination> maldives = [
    PopularDestination(
      id: 'male',
      name: 'Malé',
      country: 'Maldives',
      region: 'North Malé Atoll',
      description: 'Capital city and gateway to paradise island resorts',
      imageUrl: 'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?w=400',
      latitude: 4.1755,
      longitude: 73.5093,
      highlights: ['Overwater Villas', 'Snorkeling', 'Island Hopping', 'Sunset Cruises'],
      bestTimeToVisit: 'November - April',
    ),
  ];

  // ===== SWITZERLAND =====
  static const List<PopularDestination> switzerland = [
    PopularDestination(
      id: 'zurich',
      name: 'Zurich',
      country: 'Switzerland',
      region: 'Zurich',
      description: 'Financial hub with medieval old town and stunning lake views',
      imageUrl: 'https://images.unsplash.com/photo-1515488764276-beab7607c1e6?w=400',
      latitude: 47.3769,
      longitude: 8.5417,
      highlights: ['Old Town', 'Lake Zurich', 'Bahnhofstrasse', 'Uetliberg'],
      bestTimeToVisit: 'April - October',
    ),
    PopularDestination(
      id: 'interlaken',
      name: 'Interlaken',
      country: 'Switzerland',
      region: 'Bernese Oberland',
      description: 'Adventure capital nestled between two stunning alpine lakes',
      imageUrl: 'https://images.unsplash.com/photo-1530122037265-a5f1f91d3b99?w=400',
      latitude: 46.6863,
      longitude: 7.8632,
      highlights: ['Jungfraujoch', 'Paragliding', 'Lake Thun', 'Harder Kulm'],
      bestTimeToVisit: 'June - September',
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

/// Country data with icon, color, and flag emoji
class CountryInfo {
  final String name;
  final IconData icon;
  final Color color;
  final String flag;

  const CountryInfo({
    required this.name,
    required this.icon,
    required this.color,
    required this.flag,
  });

  static CountryInfo getInfo(String country) {
    switch (country) {
      case 'India':
        return const CountryInfo(
          name: 'India',
          icon: Icons.temple_hindu,
          color: Color(0xFFFF9933), // Saffron
          flag: '🇮🇳',
        );
      case 'Thailand':
        return const CountryInfo(
          name: 'Thailand',
          icon: Icons.temple_buddhist,
          color: Color(0xFFFFD700), // Gold
          flag: '🇹🇭',
        );
      case 'Japan':
        return const CountryInfo(
          name: 'Japan',
          icon: Icons.local_florist,
          color: Color(0xFFE91E63), // Cherry blossom pink
          flag: '🇯🇵',
        );
      case 'Indonesia':
        return const CountryInfo(
          name: 'Indonesia',
          icon: Icons.beach_access,
          color: Color(0xFF4CAF50), // Green
          flag: '🇮🇩',
        );
      case 'Singapore':
        return const CountryInfo(
          name: 'Singapore',
          icon: Icons.location_city,
          color: Color(0xFFE91E63), // Red
          flag: '🇸🇬',
        );
      case 'UAE':
        return const CountryInfo(
          name: 'UAE',
          icon: Icons.apartment,
          color: Color(0xFF9C27B0), // Purple
          flag: '🇦🇪',
        );
      case 'France':
        return const CountryInfo(
          name: 'France',
          icon: Icons.account_balance,
          color: Color(0xFF2196F3), // Blue
          flag: '🇫🇷',
        );
      case 'Italy':
        return const CountryInfo(
          name: 'Italy',
          icon: Icons.museum,
          color: Color(0xFF4CAF50), // Green
          flag: '🇮🇹',
        );
      case 'United Kingdom':
        return const CountryInfo(
          name: 'United Kingdom',
          icon: Icons.castle,
          color: Color(0xFF3F51B5), // Indigo
          flag: '🇬🇧',
        );
      case 'USA':
        return const CountryInfo(
          name: 'USA',
          icon: Icons.location_city,
          color: Color(0xFF2196F3), // Blue
          flag: '🇺🇸',
        );
      case 'Australia':
        return const CountryInfo(
          name: 'Australia',
          icon: Icons.waves,
          color: Color(0xFF00BCD4), // Cyan
          flag: '🇦🇺',
        );
      case 'Maldives':
        return const CountryInfo(
          name: 'Maldives',
          icon: Icons.water,
          color: Color(0xFF00BCD4), // Cyan
          flag: '🇲🇻',
        );
      case 'Switzerland':
        return const CountryInfo(
          name: 'Switzerland',
          icon: Icons.landscape,
          color: Color(0xFFF44336), // Red
          flag: '🇨🇭',
        );
      default:
        return CountryInfo(
          name: country,
          icon: Icons.place,
          color: const Color(0xFF607D8B), // Grey
          flag: '🌍',
        );
    }
  }
}

/// Region data with icon and color (for backwards compatibility)
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
