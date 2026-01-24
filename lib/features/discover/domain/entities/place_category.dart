import 'package:flutter/material.dart';

/// Categories for discovering tourist places
/// Maps to Google Places API types and keywords
enum PlaceCategory {
  beach,
  hillStation,
  heritage,
  adventure,
  wildlife,
  religious,
  nature,
  urban,
  familyKids,      // Family-friendly places for kids
  honeymoon,       // Romantic destinations for couples
  pilgrimage,      // Temple/spiritual places for senior citizens
  seniorFriendly,  // Accessible, calm places for elderly
}

/// Extension to provide category metadata
extension PlaceCategoryExtension on PlaceCategory {
  /// Display name for the category
  String get displayName {
    switch (this) {
      case PlaceCategory.beach:
        return 'Beaches';
      case PlaceCategory.hillStation:
        return 'Hill Stations';
      case PlaceCategory.heritage:
        return 'Heritage';
      case PlaceCategory.adventure:
        return 'Adventure';
      case PlaceCategory.wildlife:
        return 'Wildlife';
      case PlaceCategory.religious:
        return 'Religious';
      case PlaceCategory.nature:
        return 'Nature';
      case PlaceCategory.urban:
        return 'Urban';
      case PlaceCategory.familyKids:
        return 'Family & Kids';
      case PlaceCategory.honeymoon:
        return 'Honeymoon';
      case PlaceCategory.pilgrimage:
        return 'Pilgrimage';
      case PlaceCategory.seniorFriendly:
        return 'Senior Friendly';
    }
  }

  /// Icon for the category
  IconData get icon {
    switch (this) {
      case PlaceCategory.beach:
        return Icons.beach_access;
      case PlaceCategory.hillStation:
        return Icons.terrain;
      case PlaceCategory.heritage:
        return Icons.account_balance;
      case PlaceCategory.adventure:
        return Icons.hiking;
      case PlaceCategory.wildlife:
        return Icons.pets;
      case PlaceCategory.religious:
        return Icons.church; // Universal worship icon
      case PlaceCategory.nature:
        return Icons.forest;
      case PlaceCategory.urban:
        return Icons.location_city;
      case PlaceCategory.familyKids:
        return Icons.family_restroom;
      case PlaceCategory.honeymoon:
        return Icons.favorite;
      case PlaceCategory.pilgrimage:
        return Icons.temple_buddhist;
      case PlaceCategory.seniorFriendly:
        return Icons.elderly;
    }
  }

  /// Color for the category
  Color get color {
    switch (this) {
      case PlaceCategory.beach:
        return const Color(0xFF00BCD4); // Cyan
      case PlaceCategory.hillStation:
        return const Color(0xFF4CAF50); // Green
      case PlaceCategory.heritage:
        return const Color(0xFF795548); // Brown
      case PlaceCategory.adventure:
        return const Color(0xFFFF5722); // Deep Orange
      case PlaceCategory.wildlife:
        return const Color(0xFF8BC34A); // Light Green
      case PlaceCategory.religious:
        return const Color(0xFFFF9800); // Orange
      case PlaceCategory.nature:
        return const Color(0xFF009688); // Teal
      case PlaceCategory.urban:
        return const Color(0xFF607D8B); // Blue Grey
      case PlaceCategory.familyKids:
        return const Color(0xFF9C27B0); // Purple
      case PlaceCategory.honeymoon:
        return const Color(0xFFE91E63); // Pink
      case PlaceCategory.pilgrimage:
        return const Color(0xFFFF5722); // Deep Orange (saffron-ish)
      case PlaceCategory.seniorFriendly:
        return const Color(0xFF3F51B5); // Indigo
    }
  }

  /// Google Places API type for nearby search
  String? get googlePlaceType {
    switch (this) {
      case PlaceCategory.beach:
        return null; // Use keyword instead
      case PlaceCategory.hillStation:
        return null; // Use keyword instead
      case PlaceCategory.heritage:
        return null; // Use keyword search for better coverage of all heritage sites
      case PlaceCategory.adventure:
        return null; // Use keyword search for comprehensive adventure activity coverage
      case PlaceCategory.wildlife:
        return null; // Use keyword search to include all wildlife areas, not just zoos
      case PlaceCategory.religious:
        return null; // Use keyword search for better global coverage
      case PlaceCategory.nature:
        return 'park';
      case PlaceCategory.urban:
        return 'point_of_interest';
      case PlaceCategory.familyKids:
        return 'amusement_park';
      case PlaceCategory.honeymoon:
        return 'lodging'; // Hotels, resorts for romantic stays
      case PlaceCategory.pilgrimage:
        return null; // Use keyword search for better global coverage
      case PlaceCategory.seniorFriendly:
        return 'park';
    }
  }

  /// Google Places API keyword for nearby search
  String get googlePlaceKeyword {
    switch (this) {
      case PlaceCategory.beach:
        return 'beach';
      case PlaceCategory.hillStation:
        return 'hill station mountain viewpoint';
      case PlaceCategory.heritage:
        return 'heritage monument historical fort palace castle museum archaeological ruins landmark memorial statue colonial ancient UNESCO historical site';
      case PlaceCategory.adventure:
        return 'adventure trekking hiking rafting paragliding zip line rock climbing bungee jumping skydiving kayaking scuba diving snorkeling safari jeep tour mountain biking camping adventure sports activity center';
      case PlaceCategory.wildlife:
        return 'wildlife sanctuary national park safari zoo nature reserve tiger reserve bird sanctuary elephant reserve biosphere jungle forest conservation area animal viewing wildlife park game reserve';
      case PlaceCategory.religious:
        return 'hindu temple mandir kovil temple shrine place of worship church mosque masjid cathedral gurudwara dargah pagoda monastery basilica synagogue';
      case PlaceCategory.nature:
        return 'waterfall lake garden nature';
      case PlaceCategory.urban:
        return 'shopping mall entertainment';
      case PlaceCategory.familyKids:
        return 'amusement park water park kids play area zoo aquarium';
      case PlaceCategory.honeymoon:
        return 'resort spa luxury hotel romantic';
      case PlaceCategory.pilgrimage:
        return 'hindu temple mandir kovil shrine temple pilgrimage spiritual sacred holy place worship church mosque cathedral gurudwara dargah monastery synagogue';
      case PlaceCategory.seniorFriendly:
        return 'garden park peaceful scenic viewpoint accessible';
    }
  }

  /// Description for the category
  String get description {
    switch (this) {
      case PlaceCategory.beach:
        return 'Coastal getaways & seaside destinations';
      case PlaceCategory.hillStation:
        return 'Mountain retreats & scenic viewpoints';
      case PlaceCategory.heritage:
        return 'Historical monuments & cultural sites';
      case PlaceCategory.adventure:
        return 'Thrilling activities & outdoor sports';
      case PlaceCategory.wildlife:
        return 'Safari parks & nature reserves';
      case PlaceCategory.religious:
        return 'Temples, churches, mosques & all places of worship';
      case PlaceCategory.nature:
        return 'Parks, waterfalls & natural beauty';
      case PlaceCategory.urban:
        return 'City attractions & entertainment';
      case PlaceCategory.familyKids:
        return 'Theme parks, zoos & kid-friendly attractions';
      case PlaceCategory.honeymoon:
        return 'Romantic getaways & couple retreats';
      case PlaceCategory.pilgrimage:
        return 'Sacred temples & spiritual journeys';
      case PlaceCategory.seniorFriendly:
        return 'Peaceful, accessible & relaxing places';
    }
  }

  /// Sample image URL for the category (fallback)
  String get sampleImageUrl {
    switch (this) {
      case PlaceCategory.beach:
        return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400';
      case PlaceCategory.hillStation:
        return 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400';
      case PlaceCategory.heritage:
        return 'https://images.unsplash.com/photo-1548013146-72479768bada?w=400';
      case PlaceCategory.adventure:
        return 'https://images.unsplash.com/photo-1551632811-561732d1e306?w=400';
      case PlaceCategory.wildlife:
        return 'https://images.unsplash.com/photo-1474511320723-9a56873571b7?w=400';
      case PlaceCategory.religious:
        return 'https://images.unsplash.com/photo-1564507592333-c60657eea523?w=400';
      case PlaceCategory.nature:
        return 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400';
      case PlaceCategory.urban:
        return 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=400';
      case PlaceCategory.familyKids:
        return 'https://images.unsplash.com/photo-1536768139911-e290a59011e4?w=400';
      case PlaceCategory.honeymoon:
        return 'https://images.unsplash.com/photo-1540541338287-41700207dee6?w=400';
      case PlaceCategory.pilgrimage:
        return 'https://images.unsplash.com/photo-1544006659-f0b21884ce1d?w=400';
      case PlaceCategory.seniorFriendly:
        return 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400';
    }
  }
}
