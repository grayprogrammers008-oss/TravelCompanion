import '../../../shared/models/trip_model.dart';
import '../../../shared/models/itinerary_model.dart';

/// Smart checklist generator that creates destination and itinerary-aware packing lists
class SmartChecklistGenerator {
  /// Generate a comprehensive checklist based on trip details and itinerary
  static List<SmartChecklistItem> generate({
    required TripModel trip,
    List<ItineraryItemModel>? itinerary,
  }) {
    final items = <SmartChecklistItem>[];

    // 1. Pre-trip tasks (visa, bookings, reservations)
    items.addAll(_generatePreTripTasks(trip, itinerary));

    // 2. Travel documents
    items.addAll(_generateTravelDocuments(trip));

    // 3. Destination-specific items (SIM cards, adapters, etc.)
    items.addAll(_generateDestinationSpecificItems(trip));

    // 4. Electronics & gadgets
    items.addAll(_generateElectronics(trip));

    // 5. Itinerary-based items (activities, restaurants, etc.)
    if (itinerary != null && itinerary.isNotEmpty) {
      items.addAll(_generateItineraryBasedItems(itinerary));
    }

    // 6. Generic packing essentials
    items.addAll(_generatePackingEssentials(trip));

    // 7. Health & safety
    items.addAll(_generateHealthAndSafety(trip));

    return items;
  }

  /// Generate pre-trip tasks based on destination and itinerary
  static List<SmartChecklistItem> _generatePreTripTasks(
    TripModel trip,
    List<ItineraryItemModel>? itinerary,
  ) {
    final tasks = <SmartChecklistItem>[];
    final destination = trip.destination?.toLowerCase() ?? '';

    // Visa requirements for common destinations
    if (_requiresVisa(destination)) {
      tasks.add(SmartChecklistItem(
        title: 'Apply for ${_getDestinationName(destination)} Visa',
        category: 'Pre-Trip Tasks',
        priority: SmartItemPriority.critical,
        reason: 'Required for entry to ${_getDestinationName(destination)}',
      ));
    }

    // Travel insurance
    tasks.add(SmartChecklistItem(
      title: 'Purchase Travel Insurance',
      category: 'Pre-Trip Tasks',
      priority: SmartItemPriority.high,
      reason: 'Recommended for international travel',
    ));

    // Analyze itinerary for booking requirements
    if (itinerary != null) {
      for (final item in itinerary) {
        final location = item.location?.toLowerCase() ?? '';
        final title = item.title.toLowerCase();

        // Theme parks and attractions
        if (_isThemeParkOrAttraction(location, title)) {
          tasks.add(SmartChecklistItem(
            title: 'Book tickets for ${item.title}',
            category: 'Pre-Trip Tasks',
            priority: SmartItemPriority.high,
            reason: 'Advance booking recommended to avoid queues',
          ));
        }

        // Fine dining restaurants
        if (_isFineRestaurant(location, title)) {
          tasks.add(SmartChecklistItem(
            title: 'Reserve table at ${item.title}',
            category: 'Pre-Trip Tasks',
            priority: SmartItemPriority.medium,
            reason: 'Popular restaurants require advance reservations',
          ));
        }

        // Tours and experiences
        if (_isTourOrExperience(title)) {
          tasks.add(SmartChecklistItem(
            title: 'Book ${item.title}',
            category: 'Pre-Trip Tasks',
            priority: SmartItemPriority.high,
            reason: 'Limited availability - book in advance',
          ));
        }
      }
    }

    return tasks;
  }

  /// Generate travel documents based on destination
  static List<SmartChecklistItem> _generateTravelDocuments(TripModel trip) {
    final docs = <SmartChecklistItem>[];
    final isInternational = _isInternationalDestination(trip.destination ?? '');

    if (isInternational) {
      docs.add(SmartChecklistItem(
        title: 'Valid Passport (6+ months validity)',
        category: 'Travel Documents',
        priority: SmartItemPriority.critical,
        reason: 'Required for international travel',
      ));

      docs.add(SmartChecklistItem(
        title: 'Visa / Entry Permit (if required)',
        category: 'Travel Documents',
        priority: SmartItemPriority.critical,
        reason: 'Check visa requirements for ${trip.destination}',
      ));

      docs.add(SmartChecklistItem(
        title: 'Travel Insurance Documents',
        category: 'Travel Documents',
        priority: SmartItemPriority.high,
        reason: 'Keep physical and digital copies',
      ));
    } else {
      docs.add(SmartChecklistItem(
        title: 'ID Card / Passport',
        category: 'Travel Documents',
        priority: SmartItemPriority.critical,
        reason: 'Required for domestic travel',
      ));
    }

    docs.addAll([
      SmartChecklistItem(
        title: 'Flight Tickets (print + digital)',
        category: 'Travel Documents',
        priority: SmartItemPriority.critical,
        reason: 'Keep both formats for backup',
      ),
      SmartChecklistItem(
        title: 'Hotel Booking Confirmations',
        category: 'Travel Documents',
        priority: SmartItemPriority.high,
        reason: 'May be required at immigration',
      ),
      SmartChecklistItem(
        title: 'Emergency Contact Numbers',
        category: 'Travel Documents',
        priority: SmartItemPriority.high,
        reason: 'Embassy, insurance, family contacts',
      ),
    ]);

    return docs;
  }

  /// Generate destination-specific items (SIM cards, adapters, currency)
  static List<SmartChecklistItem> _generateDestinationSpecificItems(TripModel trip) {
    final items = <SmartChecklistItem>[];
    final destination = trip.destination?.toLowerCase() ?? '';
    final isInternational = _isInternationalDestination(destination);

    if (isInternational) {
      // SIM card specific to destination
      final simCardName = _getDestinationSIMCard(destination);
      if (simCardName != null) {
        items.add(SmartChecklistItem(
          title: simCardName,
          category: 'Destination Essentials',
          priority: SmartItemPriority.high,
          reason: 'Stay connected in ${_getDestinationName(destination)}',
        ));
      } else {
        items.add(SmartChecklistItem(
          title: 'International SIM Card / eSIM',
          category: 'Destination Essentials',
          priority: SmartItemPriority.high,
          reason: 'Mobile data in ${_getDestinationName(destination)}',
        ));
      }

      // Power adapter
      final adapterType = _getPowerAdapter(destination);
      items.add(SmartChecklistItem(
        title: 'Power Adapter ($adapterType)',
        category: 'Destination Essentials',
        priority: SmartItemPriority.high,
        reason: '${_getDestinationName(destination)} uses $adapterType plug',
      ));

      // Currency
      final currency = _getCurrencyName(destination);
      items.add(SmartChecklistItem(
        title: 'Local Currency ($currency)',
        category: 'Destination Essentials',
        priority: SmartItemPriority.medium,
        reason: 'Exchange some cash for immediate expenses',
      ));
    }

    // Weather-based items
    final weatherItems = _getWeatherBasedItems(destination, trip.startDate);
    items.addAll(weatherItems);

    return items;
  }

  /// Generate electronics and gadgets
  static List<SmartChecklistItem> _generateElectronics(TripModel trip) {
    return [
      SmartChecklistItem(
        title: 'Phone & Charger',
        category: 'Electronics',
        priority: SmartItemPriority.critical,
        reason: 'Essential for navigation and communication',
      ),
      SmartChecklistItem(
        title: 'Power Bank (20000mAh+)',
        category: 'Electronics',
        priority: SmartItemPriority.high,
        reason: 'Stay charged during long travel days',
      ),
      SmartChecklistItem(
        title: 'Universal Travel Adapter',
        category: 'Electronics',
        priority: SmartItemPriority.high,
        reason: 'Compatible with multiple plug types',
      ),
      SmartChecklistItem(
        title: 'Headphones / Earbuds',
        category: 'Electronics',
        priority: SmartItemPriority.medium,
        reason: 'For flights and entertainment',
      ),
      SmartChecklistItem(
        title: 'Camera (if not using phone)',
        category: 'Electronics',
        priority: SmartItemPriority.low,
        reason: 'Capture memories in better quality',
      ),
      SmartChecklistItem(
        title: 'USB Cables & Cable Organizer',
        category: 'Electronics',
        priority: SmartItemPriority.medium,
        reason: 'Keep charging cables organized',
      ),
    ];
  }

  /// Generate itinerary-based items (activities, clothing, gear)
  static List<SmartChecklistItem> _generateItineraryBasedItems(
    List<ItineraryItemModel> itinerary,
  ) {
    final items = <SmartChecklistItem>[];
    final activities = <String>{};

    for (final item in itinerary) {
      final title = item.title.toLowerCase();
      final location = item.location?.toLowerCase() ?? '';

      // Beach activities
      if (_hasKeywords(title, location, ['beach', 'swim', 'snorkel', 'dive', 'surf'])) {
        if (activities.add('beach')) {
          items.addAll([
            SmartChecklistItem(
              title: 'Swimsuit / Bikini',
              category: 'Activity Gear',
              priority: SmartItemPriority.high,
              reason: 'Beach activity: ${item.title}',
            ),
            SmartChecklistItem(
              title: 'Sunscreen SPF 50+',
              category: 'Activity Gear',
              priority: SmartItemPriority.high,
              reason: 'Sun protection for beach day',
            ),
            SmartChecklistItem(
              title: 'Beach Towel',
              category: 'Activity Gear',
              priority: SmartItemPriority.medium,
              reason: 'For ${item.title}',
            ),
          ]);
        }
      }

      // Hiking/trekking
      if (_hasKeywords(title, location, ['hike', 'trek', 'trail', 'mountain', 'climb'])) {
        if (activities.add('hiking')) {
          items.addAll([
            SmartChecklistItem(
              title: 'Hiking Shoes / Trekking Boots',
              category: 'Activity Gear',
              priority: SmartItemPriority.critical,
              reason: 'Required for ${item.title}',
            ),
            SmartChecklistItem(
              title: 'Trekking Poles (if needed)',
              category: 'Activity Gear',
              priority: SmartItemPriority.medium,
              reason: 'Helpful for steep terrain',
            ),
            SmartChecklistItem(
              title: 'Daypack / Backpack',
              category: 'Activity Gear',
              priority: SmartItemPriority.high,
              reason: 'Carry water and snacks during hike',
            ),
          ]);
        }
      }

      // Fine dining
      if (_hasKeywords(title, location, ['restaurant', 'dinner', 'michelin', 'fine dining'])) {
        if (activities.add('fine_dining')) {
          items.addAll([
            SmartChecklistItem(
              title: 'Formal Outfit (dress/suit)',
              category: 'Clothing',
              priority: SmartItemPriority.high,
              reason: 'Dress code for ${item.title}',
            ),
            SmartChecklistItem(
              title: 'Dress Shoes',
              category: 'Clothing',
              priority: SmartItemPriority.high,
              reason: 'Match formal attire',
            ),
          ]);
        }
      }

      // Water sports
      if (_hasKeywords(title, location, ['kayak', 'rafting', 'jet ski', 'parasail', 'boat'])) {
        if (activities.add('water_sports')) {
          items.addAll([
            SmartChecklistItem(
              title: 'Waterproof Phone Pouch',
              category: 'Activity Gear',
              priority: SmartItemPriority.high,
              reason: 'Protect phone during ${item.title}',
            ),
            SmartChecklistItem(
              title: 'Quick-dry Clothes',
              category: 'Clothing',
              priority: SmartItemPriority.medium,
              reason: 'For water activities',
            ),
          ]);
        }
      }

      // Nightlife/clubs
      if (_hasKeywords(title, location, ['club', 'bar', 'nightlife', 'party'])) {
        if (activities.add('nightlife')) {
          items.add(SmartChecklistItem(
            title: 'Party Outfit & Accessories',
            category: 'Clothing',
            priority: SmartItemPriority.medium,
            reason: 'For ${item.title}',
          ));
        }
      }

      // Safari/wildlife
      if (_hasKeywords(title, location, ['safari', 'wildlife', 'zoo', 'animal'])) {
        if (activities.add('wildlife')) {
          items.addAll([
            SmartChecklistItem(
              title: 'Binoculars',
              category: 'Activity Gear',
              priority: SmartItemPriority.medium,
              reason: 'Wildlife viewing at ${item.title}',
            ),
            SmartChecklistItem(
              title: 'Neutral-colored Clothing',
              category: 'Clothing',
              priority: SmartItemPriority.medium,
              reason: 'Recommended for safari',
            ),
          ]);
        }
      }
    }

    return items;
  }

  /// Generate generic packing essentials
  static List<SmartChecklistItem> _generatePackingEssentials(TripModel trip) {
    final duration = _getTripDuration(trip);

    return [
      SmartChecklistItem(
        title: 'Clothes ($duration days)',
        category: 'Packing Essentials',
        priority: SmartItemPriority.critical,
        reason: 'Pack enough for the trip duration',
      ),
      SmartChecklistItem(
        title: 'Underwear & Socks',
        category: 'Packing Essentials',
        priority: SmartItemPriority.critical,
        reason: 'Pack $duration sets + extras',
      ),
      SmartChecklistItem(
        title: 'Sleepwear',
        category: 'Packing Essentials',
        priority: SmartItemPriority.high,
        reason: 'Comfortable sleep clothes',
      ),
      SmartChecklistItem(
        title: 'Comfortable Walking Shoes',
        category: 'Packing Essentials',
        priority: SmartItemPriority.critical,
        reason: 'Essential for sightseeing',
      ),
      SmartChecklistItem(
        title: 'Toiletries Bag',
        category: 'Packing Essentials',
        priority: SmartItemPriority.critical,
        reason: 'Toothbrush, paste, soap, shampoo, etc.',
      ),
      SmartChecklistItem(
        title: 'Sunglasses',
        category: 'Packing Essentials',
        priority: SmartItemPriority.medium,
        reason: 'Eye protection from sun',
      ),
      SmartChecklistItem(
        title: 'Light Jacket / Hoodie',
        category: 'Packing Essentials',
        priority: SmartItemPriority.medium,
        reason: 'For air-conditioned places and evenings',
      ),
      SmartChecklistItem(
        title: 'Reusable Water Bottle',
        category: 'Packing Essentials',
        priority: SmartItemPriority.medium,
        reason: 'Stay hydrated and reduce plastic',
      ),
    ];
  }

  /// Generate health and safety items
  static List<SmartChecklistItem> _generateHealthAndSafety(TripModel trip) {
    return [
      SmartChecklistItem(
        title: 'Prescription Medications',
        category: 'Health & Safety',
        priority: SmartItemPriority.critical,
        reason: 'Pack enough for entire trip + extras',
      ),
      SmartChecklistItem(
        title: 'First Aid Kit',
        category: 'Health & Safety',
        priority: SmartItemPriority.high,
        reason: 'Band-aids, pain relievers, antiseptic',
      ),
      SmartChecklistItem(
        title: 'Hand Sanitizer',
        category: 'Health & Safety',
        priority: SmartItemPriority.high,
        reason: 'Hygiene on the go',
      ),
      SmartChecklistItem(
        title: 'Face Masks',
        category: 'Health & Safety',
        priority: SmartItemPriority.medium,
        reason: 'May be required in some places',
      ),
      SmartChecklistItem(
        title: 'Insect Repellent',
        category: 'Health & Safety',
        priority: SmartItemPriority.medium,
        reason: 'Protection from mosquitoes',
      ),
    ];
  }

  // ========== HELPER METHODS ==========

  static bool _requiresVisa(String destination) {
    // Common countries requiring visa for Indian citizens (example)
    const visaRequired = [
      'singapore', 'usa', 'uk', 'australia', 'canada', 'china',
      'japan', 'france', 'germany', 'italy', 'spain',
    ];
    return visaRequired.any((country) => destination.contains(country));
  }

  static bool _isInternationalDestination(String destination) {
    // List of domestic destinations (India example)
    const domestic = [
      'delhi', 'mumbai', 'bangalore', 'chennai', 'kolkata', 'goa',
      'jaipur', 'agra', 'kerala', 'kashmir', 'ladakh', 'manali',
      'shimla', 'darjeeling', 'varanasi', 'rishikesh',
    ];
    return !domestic.any((city) => destination.contains(city));
  }

  static String? _getDestinationSIMCard(String destination) {
    const simCards = {
      'singapore': 'Singapore Tourist SIM (Singtel/StarHub)',
      'thailand': 'Thai Tourist SIM (AIS/DTAC)',
      'japan': 'Japan Tourist SIM / Pocket WiFi',
      'usa': 'US Prepaid SIM (T-Mobile/AT&T)',
      'uk': 'UK SIM (EE/Vodafone)',
      'dubai': 'UAE Tourist SIM (Etisalat/du)',
      'malaysia': 'Malaysian SIM (Maxis/Celcom)',
    };

    for (final entry in simCards.entries) {
      if (destination.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  static String _getPowerAdapter(String destination) {
    const adapters = {
      'singapore': 'Type G (UK-style)',
      'thailand': 'Type A/B/C',
      'japan': 'Type A (US-style)',
      'usa': 'Type A/B',
      'uk': 'Type G',
      'europe': 'Type C/E/F',
      'dubai': 'Type D/G',
      'australia': 'Type I',
    };

    for (final entry in adapters.entries) {
      if (destination.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'Universal Adapter';
  }

  static String _getCurrencyName(String destination) {
    const currencies = {
      'singapore': 'SGD',
      'thailand': 'Thai Baht',
      'japan': 'Japanese Yen',
      'usa': 'USD',
      'uk': 'GBP',
      'dubai': 'AED',
      'malaysia': 'MYR',
    };

    for (final entry in currencies.entries) {
      if (destination.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'Local Currency';
  }

  static String _getDestinationName(String destination) {
    final cleaned = destination.trim();
    return cleaned.isEmpty ? 'destination' : cleaned;
  }

  static int _getTripDuration(TripModel trip) {
    if (trip.startDate != null && trip.endDate != null) {
      return trip.endDate!.difference(trip.startDate!).inDays + 1;
    }
    return 7; // Default
  }

  static bool _isThemeParkOrAttraction(String location, String title) {
    const keywords = [
      'universal studios', 'disneyland', 'disney', 'theme park',
      'gardens by the bay', 'sentosa', 'marina bay sands',
      'observation deck', 'tower', 'aquarium', 'zoo',
    ];
    return keywords.any((k) =>
      location.contains(k) || title.contains(k)
    );
  }

  static bool _isFineRestaurant(String location, String title) {
    const keywords = [
      'michelin', 'fine dining', 'restaurant', 'dinner',
      'reservation', 'rooftop', 'steakhouse',
    ];
    return keywords.any((k) =>
      location.contains(k) || title.contains(k)
    );
  }

  static bool _isTourOrExperience(String title) {
    const keywords = [
      'tour', 'cruise', 'show', 'experience', 'ticket',
      'admission', 'visit', 'guided',
    ];
    return keywords.any((k) => title.contains(k));
  }

  static bool _hasKeywords(String title, String location, List<String> keywords) {
    return keywords.any((k) =>
      title.contains(k) || location.contains(k)
    );
  }

  static List<SmartChecklistItem> _getWeatherBasedItems(
    String destination,
    DateTime? startDate,
  ) {
    // This is a simplified version - can be enhanced with real weather API
    final items = <SmartChecklistItem>[];

    // Example: Singapore is hot and humid year-round
    if (destination.contains('singapore')) {
      items.add(SmartChecklistItem(
        title: 'Light, breathable clothing',
        category: 'Destination Essentials',
        priority: SmartItemPriority.high,
        reason: 'Singapore is hot and humid (30-35°C)',
      ));
      items.add(SmartChecklistItem(
        title: 'Umbrella (rain & sun)',
        category: 'Destination Essentials',
        priority: SmartItemPriority.high,
        reason: 'Frequent rain showers in Singapore',
      ));
    }

    return items;
  }
}

/// Represents a smart checklist item with metadata
class SmartChecklistItem {
  final String title;
  final String category;
  final SmartItemPriority priority;
  final String reason;

  const SmartChecklistItem({
    required this.title,
    required this.category,
    required this.priority,
    required this.reason,
  });
}

/// Priority levels for smart checklist items
enum SmartItemPriority {
  critical,  // Must have (passport, visa)
  high,      // Very important (SIM card, power adapter)
  medium,    // Important but not critical
  low,       // Nice to have
}
