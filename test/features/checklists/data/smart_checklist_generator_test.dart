import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/checklists/data/smart_checklist_generator.dart';
import 'package:travel_crew/shared/models/itinerary_model.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

/// Comprehensive unit tests for [SmartChecklistGenerator].
///
/// All branches of the public `generate(...)` method are exercised, plus the
/// indirect coverage of every `_generate*` helper, every helper-classifier
/// (`_requiresVisa`, `_isInternationalDestination`, `_isThemeParkOrAttraction`,
/// `_isFineRestaurant`, `_isTourOrExperience`, `_hasKeywords`,
/// `_getDestinationSIMCard`, `_getPowerAdapter`, `_getCurrencyName`,
/// `_getDestinationName`, `_getTripDuration`, `_getWeatherBasedItems`).
///
/// We assert by category + title rather than exact list equality so the tests
/// stay robust to ordering and additive changes.

TripModel _trip({
  String name = 'My Trip',
  String? destination,
  DateTime? startDate,
  DateTime? endDate,
}) {
  return TripModel(
    id: 't1',
    name: name,
    destination: destination,
    startDate: startDate,
    endDate: endDate,
    createdBy: 'u1',
  );
}

ItineraryItemModel _item({
  String title = 'X',
  String? location,
}) {
  return ItineraryItemModel(
    id: 'i1',
    tripId: 't1',
    title: title,
    location: location,
  );
}

bool _has(List<SmartChecklistItem> items, String title) =>
    items.any((i) => i.title == title);

bool _hasContains(List<SmartChecklistItem> items, String fragment) =>
    items.any((i) => i.title.contains(fragment));

SmartChecklistItem? _find(List<SmartChecklistItem> items, String title) {
  for (final i in items) {
    if (i.title == title) return i;
  }
  return null;
}

void main() {
  group('SmartChecklistItem', () {
    test('exposes all constructor fields', () {
      const item = SmartChecklistItem(
        title: 'A',
        category: 'B',
        priority: SmartItemPriority.high,
        reason: 'C',
      );
      expect(item.title, 'A');
      expect(item.category, 'B');
      expect(item.priority, SmartItemPriority.high);
      expect(item.reason, 'C');
    });

    test('SmartItemPriority enum has expected values', () {
      expect(SmartItemPriority.values, hasLength(4));
      expect(SmartItemPriority.values, containsAll([
        SmartItemPriority.critical,
        SmartItemPriority.high,
        SmartItemPriority.medium,
        SmartItemPriority.low,
      ]));
    });
  });

  group('generate – top-level shape', () {
    test('always includes the seven section blocks for a minimal trip', () {
      final items = SmartChecklistGenerator.generate(trip: _trip());

      // Pre-Trip Tasks always include "Purchase Travel Insurance".
      expect(_has(items, 'Purchase Travel Insurance'), isTrue);
      // Travel Documents always include flight tickets, hotel confirmations, emergency contacts.
      expect(_has(items, 'Flight Tickets (print + digital)'), isTrue);
      expect(_has(items, 'Hotel Booking Confirmations'), isTrue);
      expect(_has(items, 'Emergency Contact Numbers'), isTrue);
      // Electronics block is unconditional.
      expect(_has(items, 'Phone & Charger'), isTrue);
      expect(_has(items, 'Power Bank (20000mAh+)'), isTrue);
      expect(_has(items, 'Universal Travel Adapter'), isTrue);
      expect(_has(items, 'Headphones / Earbuds'), isTrue);
      expect(_has(items, 'Camera (if not using phone)'), isTrue);
      expect(_has(items, 'USB Cables & Cable Organizer'), isTrue);
      // Packing essentials block is unconditional.
      expect(_has(items, 'Underwear & Socks'), isTrue);
      expect(_has(items, 'Sleepwear'), isTrue);
      expect(_has(items, 'Comfortable Walking Shoes'), isTrue);
      expect(_has(items, 'Toiletries Bag'), isTrue);
      expect(_has(items, 'Sunglasses'), isTrue);
      expect(_has(items, 'Light Jacket / Hoodie'), isTrue);
      expect(_has(items, 'Reusable Water Bottle'), isTrue);
      // Health & safety block is unconditional.
      expect(_has(items, 'Prescription Medications'), isTrue);
      expect(_has(items, 'First Aid Kit'), isTrue);
      expect(_has(items, 'Hand Sanitizer'), isTrue);
      expect(_has(items, 'Face Masks'), isTrue);
      expect(_has(items, 'Insect Repellent'), isTrue);
    });

    test('accepts null itinerary without error and skips activity gear', () {
      final items =
          SmartChecklistGenerator.generate(trip: _trip(), itinerary: null);
      expect(items.where((i) => i.category == 'Activity Gear'), isEmpty);
    });

    test('accepts empty itinerary list and skips activity gear', () {
      final items =
          SmartChecklistGenerator.generate(trip: _trip(), itinerary: const []);
      expect(items.where((i) => i.category == 'Activity Gear'), isEmpty);
    });
  });

  group('Pre-trip tasks', () {
    test('adds a visa task for visa-required destinations', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'Singapore'),
      );
      expect(
        items.any((i) => i.title.startsWith('Apply for') && i.title.contains('Visa')),
        isTrue,
      );
      // "destination" preserves user input
      expect(_hasContains(items, 'singapore'), isTrue);
    });

    test('does NOT add a visa task for visa-free destinations', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'Goa'),
      );
      expect(
        items.any((i) => i.title.startsWith('Apply for')),
        isFalse,
      );
    });

    test('itinerary triggers theme-park booking task', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'Goa'),
        itinerary: [
          _item(title: 'Universal Studios', location: 'Sentosa'),
        ],
      );
      expect(_has(items, 'Book tickets for Universal Studios'), isTrue);
    });

    test('itinerary triggers fine-dining reservation task', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'Goa'),
        itinerary: [
          _item(title: 'Dinner at Le Cirque', location: 'fine dining venue'),
        ],
      );
      expect(_hasContains(items, 'Reserve table at Dinner at Le Cirque'), isTrue);
    });

    test('itinerary triggers tour booking task', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'Goa'),
        itinerary: [_item(title: 'Sunset Cruise')],
      );
      expect(_has(items, 'Book Sunset Cruise'), isTrue);
    });

    test('non-matching itinerary entries add no booking tasks', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'Goa'),
        itinerary: [_item(title: 'Plain old activity')],
      );
      expect(
        items.any((i) => i.title.startsWith('Book ')),
        isFalse,
      );
      expect(
        items.any((i) => i.title.startsWith('Reserve table at')),
        isFalse,
      );
    });
  });

  group('Travel documents', () {
    test('international destination returns passport + visa blocks', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'Tokyo Japan'),
      );
      expect(_has(items, 'Valid Passport (6+ months validity)'), isTrue);
      expect(_has(items, 'Visa / Entry Permit (if required)'), isTrue);
      expect(_has(items, 'Travel Insurance Documents'), isTrue);
      expect(_has(items, 'ID Card / Passport'), isFalse);
    });

    test('domestic destination returns the simpler ID-only block', () {
      // Note: _isInternationalDestination is called with the raw destination
      // string (no lowercasing), so the destination must be lowercase here
      // to match the domestic-cities list.
      final items =
          SmartChecklistGenerator.generate(trip: _trip(destination: 'goa'));
      expect(_has(items, 'ID Card / Passport'), isTrue);
      expect(_has(items, 'Valid Passport (6+ months validity)'), isFalse);
      expect(_has(items, 'Visa / Entry Permit (if required)'), isFalse);
    });

    test('destination is null falls back to international branch', () {
      // _isInternationalDestination(empty) returns true.
      final items = SmartChecklistGenerator.generate(trip: _trip());
      expect(_has(items, 'Valid Passport (6+ months validity)'), isTrue);
    });
  });

  group('Destination-specific items', () {
    test('Singapore – maps to Type G adapter, SGD currency, Singtel SIM, weather extras', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'singapore'),
      );
      expect(_has(items, 'Singapore Tourist SIM (Singtel/StarHub)'), isTrue);
      expect(_has(items, 'Power Adapter (Type G (UK-style))'), isTrue);
      expect(_has(items, 'Local Currency (SGD)'), isTrue);
      // Weather-based items
      expect(_has(items, 'Light, breathable clothing'), isTrue);
      expect(_has(items, 'Umbrella (rain & sun)'), isTrue);
    });

    test('Thailand – maps to Type A/B/C and Thai Baht', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'thailand bangkok'),
      );
      expect(_has(items, 'Thai Tourist SIM (AIS/DTAC)'), isTrue);
      expect(_has(items, 'Power Adapter (Type A/B/C)'), isTrue);
      expect(_has(items, 'Local Currency (Thai Baht)'), isTrue);
    });

    test('Japan – Type A power, Japan SIM, Yen', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'japan'),
      );
      expect(_has(items, 'Japan Tourist SIM / Pocket WiFi'), isTrue);
      expect(_has(items, 'Power Adapter (Type A (US-style))'), isTrue);
      expect(_has(items, 'Local Currency (Japanese Yen)'), isTrue);
    });

    test('USA – Type A/B, US SIM, USD', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'usa new york'),
      );
      expect(_has(items, 'US Prepaid SIM (T-Mobile/AT&T)'), isTrue);
      expect(_has(items, 'Power Adapter (Type A/B)'), isTrue);
      expect(_has(items, 'Local Currency (USD)'), isTrue);
    });

    test('UK – Type G, EE SIM, GBP', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'uk london'),
      );
      expect(_has(items, 'UK SIM (EE/Vodafone)'), isTrue);
      expect(_has(items, 'Power Adapter (Type G)'), isTrue);
      expect(_has(items, 'Local Currency (GBP)'), isTrue);
    });

    test('Dubai – D/G adapter, Etisalat SIM, AED', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'dubai uae'),
      );
      expect(_has(items, 'UAE Tourist SIM (Etisalat/du)'), isTrue);
      expect(_has(items, 'Power Adapter (Type D/G)'), isTrue);
      expect(_has(items, 'Local Currency (AED)'), isTrue);
    });

    test('Malaysia – Maxis SIM and MYR', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'malaysia kuala lumpur'),
      );
      expect(_has(items, 'Malaysian SIM (Maxis/Celcom)'), isTrue);
      expect(_has(items, 'Local Currency (MYR)'), isTrue);
    });

    test('Australia – power adapter Type I, generic SIM, generic currency', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'australia sydney'),
      );
      expect(_has(items, 'International SIM Card / eSIM'), isTrue);
      expect(_has(items, 'Power Adapter (Type I)'), isTrue);
      expect(_has(items, 'Local Currency (Local Currency)'), isTrue);
    });

    test('"europe" hits the europe adapter mapping', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'europe paris'),
      );
      expect(_has(items, 'Power Adapter (Type C/E/F)'), isTrue);
    });

    test('unknown international destination -> Universal Adapter + generic SIM', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'iceland'),
      );
      expect(_has(items, 'International SIM Card / eSIM'), isTrue);
      expect(_has(items, 'Power Adapter (Universal Adapter)'), isTrue);
      expect(_has(items, 'Local Currency (Local Currency)'), isTrue);
    });

    test('domestic destination skips SIM/adapter/currency block', () {
      final items =
          SmartChecklistGenerator.generate(trip: _trip(destination: 'goa'));
      expect(
        items.any((i) => i.category == 'Destination Essentials'),
        isFalse,
      );
    });
  });

  group('Itinerary-based gear', () {
    test('beach activity adds swimsuit, sunscreen, towel exactly once', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'goa'),
        itinerary: [
          _item(title: 'Beach Day', location: 'beachfront'),
          // Second beach entry should NOT duplicate items thanks to dedup set.
          _item(title: 'Snorkel run', location: 'reef'),
        ],
      );
      expect(items.where((i) => i.title == 'Swimsuit / Bikini'), hasLength(1));
      expect(items.where((i) => i.title == 'Sunscreen SPF 50+'), hasLength(1));
      expect(items.where((i) => i.title == 'Beach Towel'), hasLength(1));
    });

    test('hiking activity adds boots/poles/daypack', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'goa'),
        itinerary: [_item(title: 'Hike to summit', location: 'mountain')],
      );
      expect(_has(items, 'Hiking Shoes / Trekking Boots'), isTrue);
      expect(_has(items, 'Trekking Poles (if needed)'), isTrue);
      expect(_has(items, 'Daypack / Backpack'), isTrue);
    });

    test('fine-dining activity adds formal outfit + dress shoes', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'goa'),
        itinerary: [
          _item(title: 'Michelin dinner', location: 'rooftop restaurant'),
        ],
      );
      expect(_has(items, 'Formal Outfit (dress/suit)'), isTrue);
      expect(_has(items, 'Dress Shoes'), isTrue);
    });

    test('water-sports activity adds waterproof pouch + quick-dry clothes', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'goa'),
        itinerary: [_item(title: 'kayak tour', location: 'river')],
      );
      expect(_has(items, 'Waterproof Phone Pouch'), isTrue);
      expect(_has(items, 'Quick-dry Clothes'), isTrue);
    });

    test('nightlife activity adds party outfit', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'goa'),
        itinerary: [_item(title: 'rooftop club night', location: 'club')],
      );
      expect(_has(items, 'Party Outfit & Accessories'), isTrue);
    });

    test('safari/wildlife activity adds binoculars + neutral clothing', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'goa'),
        itinerary: [_item(title: 'wildlife safari', location: 'park')],
      );
      expect(_has(items, 'Binoculars'), isTrue);
      expect(_has(items, 'Neutral-colored Clothing'), isTrue);
    });

    test('a single itinerary entry can match multiple categories', () {
      // One item matching beach+nightlife+safari-style keywords through location.
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'goa'),
        itinerary: [
          _item(title: 'beach club party with zoo trip', location: ''),
        ],
      );
      expect(_has(items, 'Swimsuit / Bikini'), isTrue);
      expect(_has(items, 'Party Outfit & Accessories'), isTrue);
      expect(_has(items, 'Binoculars'), isTrue);
    });

    test('completely unmatched itinerary entry produces no Activity Gear', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'goa'),
        itinerary: [_item(title: 'plain meeting', location: 'office')],
      );
      expect(
        items.any((i) => i.category == 'Activity Gear'),
        isFalse,
      );
    });
  });

  group('Packing essentials – duration math', () {
    test('uses inclusive day-difference + 1 when both dates are present', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 4),
        ),
      );
      expect(_has(items, 'Clothes (4 days)'), isTrue);
      final us = _find(items, 'Underwear & Socks')!;
      expect(us.reason, contains('4 sets'));
    });

    test('falls back to 7 days when dates are missing', () {
      final items = SmartChecklistGenerator.generate(trip: _trip());
      expect(_has(items, 'Clothes (7 days)'), isTrue);
    });

    test('falls back to 7 days when only startDate is present', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(startDate: DateTime(2024, 6, 1)),
      );
      expect(_has(items, 'Clothes (7 days)'), isTrue);
    });

    test('falls back to 7 days when only endDate is present', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(endDate: DateTime(2024, 6, 1)),
      );
      expect(_has(items, 'Clothes (7 days)'), isTrue);
    });
  });

  group('Priorities', () {
    test('passport is critical and travel-insurance-task is high', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'singapore'),
      );
      expect(
        _find(items, 'Valid Passport (6+ months validity)')!.priority,
        SmartItemPriority.critical,
      );
      expect(
        _find(items, 'Purchase Travel Insurance')!.priority,
        SmartItemPriority.high,
      );
      expect(
        _find(items, 'Camera (if not using phone)')!.priority,
        SmartItemPriority.low,
      );
      expect(
        _find(items, 'Hiking Shoes / Trekking Boots'),
        isNull,
      );
    });

    test('reasons are non-empty for every generated item', () {
      final items = SmartChecklistGenerator.generate(
        trip: _trip(destination: 'singapore'),
        itinerary: [_item(title: 'beach hike club safari', location: 'reef')],
      );
      expect(items, isNotEmpty);
      expect(items.every((i) => i.reason.isNotEmpty), isTrue);
      expect(items.every((i) => i.title.isNotEmpty), isTrue);
      expect(items.every((i) => i.category.isNotEmpty), isTrue);
    });
  });
}
