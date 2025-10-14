// App Images - Asset paths and default images for the Travel Crew app
//
// This class manages all image assets, including default trip destination images,
// illustrations, and placeholder images for a premium visual experience.

class AppImages {
  // Private constructor to prevent instantiation
  AppImages._();

  // ==================== DESTINATION IMAGES ====================
  // Premium travel destination images for default trips and placeholders

  static const String destinationsPath = 'assets/images/destinations';

  // Default destination images (will be used for trips without custom images)
  static const List<String> defaultDestinations = [
    '$destinationsPath/bali.jpg',
    '$destinationsPath/paris.jpg',
    '$destinationsPath/tokyo.jpg',
    '$destinationsPath/santorini.jpg',
    '$destinationsPath/dubai.jpg',
    '$destinationsPath/maldives.jpg',
    '$destinationsPath/new_york.jpg',
    '$destinationsPath/iceland.jpg',
    '$destinationsPath/switzerland.jpg',
    '$destinationsPath/bora_bora.jpg',
  ];

  // Map of destination names to their image paths
  static const Map<String, String> destinationImageMap = {
    'bali': '$destinationsPath/bali.jpg',
    'paris': '$destinationsPath/paris.jpg',
    'tokyo': '$destinationsPath/tokyo.jpg',
    'santorini': '$destinationsPath/santorini.jpg',
    'dubai': '$destinationsPath/dubai.jpg',
    'maldives': '$destinationsPath/maldives.jpg',
    'new york': '$destinationsPath/new_york.jpg',
    'nyc': '$destinationsPath/new_york.jpg',
    'iceland': '$destinationsPath/iceland.jpg',
    'switzerland': '$destinationsPath/switzerland.jpg',
    'bora bora': '$destinationsPath/bora_bora.jpg',
    'beach': '$destinationsPath/maldives.jpg',
    'mountain': '$destinationsPath/switzerland.jpg',
    'city': '$destinationsPath/new_york.jpg',
    'island': '$destinationsPath/bali.jpg',
  };

  // ==================== ILLUSTRATION IMAGES ====================
  // Illustrations for empty states, onboarding, etc.

  static const String illustrationsPath = 'assets/images/illustrations';

  static const String emptyTrips = '$illustrationsPath/empty_trips.png';
  static const String emptyExpenses = '$illustrationsPath/empty_expenses.png';
  static const String emptyItinerary = '$illustrationsPath/empty_itinerary.png';
  static const String emptyChecklists = '$illustrationsPath/empty_checklists.png';
  static const String errorState = '$illustrationsPath/error_state.png';
  static const String noConnection = '$illustrationsPath/no_connection.png';

  // ==================== PLACEHOLDER IMAGES ====================
  // Gradient placeholders when no image is available

  static const String placeholdersPath = 'assets/images/placeholders';

  static const String tripPlaceholder = '$placeholdersPath/trip_placeholder.png';
  static const String userAvatar = '$placeholdersPath/user_avatar.png';

  // ==================== HELPER METHODS ====================

  /// Get a destination image based on trip name or destination
  /// Falls back to a random default image if no match found
  static String getDestinationImage(String? tripName, {int? seed}) {
    if (tripName == null || tripName.isEmpty) {
      return getRandomDestinationImage(seed: seed);
    }

    final lowerName = tripName.toLowerCase();

    // Check if trip name contains any known destination keyword
    for (final entry in destinationImageMap.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }

    // Fallback to random image based on trip name hash
    return getRandomDestinationImage(seed: tripName.hashCode);
  }

  /// Get a random destination image
  static String getRandomDestinationImage({int? seed}) {
    final index = seed != null
        ? seed.abs() % defaultDestinations.length
        : DateTime.now().millisecondsSinceEpoch % defaultDestinations.length;
    return defaultDestinations[index];
  }

  /// Get destination image by index
  static String getDestinationImageByIndex(int index) {
    return defaultDestinations[index % defaultDestinations.length];
  }

  /// Get user avatar with fallback
  static String getUserAvatar(String? avatarUrl) {
    return avatarUrl ?? userAvatar;
  }

  /// Check if image is from assets
  static bool isAssetImage(String? imagePath) {
    return imagePath?.startsWith('assets/') ?? false;
  }

  /// Check if image is from network
  static bool isNetworkImage(String? imagePath) {
    return imagePath?.startsWith('http') ?? false;
  }
}

/// Extension on String to easily get destination colors for gradients
extension DestinationColors on String {
  /// Get a gradient color pair based on destination name
  List<int> get destinationColorPair {
    final hash = hashCode.abs();
    final colorPairs = [
      [0xFF00B8A9, 0xFF008C7D], // Teal (tropical)
      [0xFFFF6B9D, 0xFFFFC145], // Coral to Gold (sunset)
      [0xFF9B5DE5, 0xFFFF6B9D], // Purple to Pink (twilight)
      [0xFF3B82F6, 0xFF00B8A9], // Blue to Teal (ocean)
      [0xFFFF8A65, 0xFFFFC145], // Orange to Gold (warm)
      [0xFF10B981, 0xFF00B8A9], // Green to Teal (tropical forest)
    ];
    final pairIndex = hash % colorPairs.length;
    return colorPairs[pairIndex];
  }
}
