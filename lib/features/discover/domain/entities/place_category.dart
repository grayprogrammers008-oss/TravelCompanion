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
        return Icons.temple_hindu;
      case PlaceCategory.nature:
        return Icons.forest;
      case PlaceCategory.urban:
        return Icons.location_city;
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
        return 'museum';
      case PlaceCategory.adventure:
        return 'tourist_attraction';
      case PlaceCategory.wildlife:
        return 'zoo';
      case PlaceCategory.religious:
        return 'place_of_worship';
      case PlaceCategory.nature:
        return 'park';
      case PlaceCategory.urban:
        return 'point_of_interest';
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
        return 'heritage monument historical';
      case PlaceCategory.adventure:
        return 'adventure trekking sports';
      case PlaceCategory.wildlife:
        return 'wildlife sanctuary national park';
      case PlaceCategory.religious:
        return 'temple church mosque';
      case PlaceCategory.nature:
        return 'waterfall lake garden nature';
      case PlaceCategory.urban:
        return 'shopping mall entertainment';
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
        return 'Temples, churches & spiritual places';
      case PlaceCategory.nature:
        return 'Parks, waterfalls & natural beauty';
      case PlaceCategory.urban:
        return 'City attractions & entertainment';
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
    }
  }
}
