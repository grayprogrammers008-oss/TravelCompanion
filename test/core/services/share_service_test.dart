// Tests for ShareService formatter methods.
//
// Network/launchUrl/clipboard methods are intentionally NOT tested - they
// require real platform channels. The pure formatTrip / formatAiItinerary /
// formatExpenseSummary / formatChecklist functions are pure string builders
// and can be exercised directly.

import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/services/share_service.dart';
import 'package:travel_crew/features/ai_itinerary/domain/entities/ai_itinerary.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

TripModel _trip({
  String? destination,
  DateTime? start,
  DateTime? end,
  double? cost,
  String? description,
}) {
  return TripModel(
    id: 't1',
    name: 'Goa Getaway',
    description: description,
    destination: destination,
    startDate: start,
    endDate: end,
    createdBy: 'user1',
    cost: cost,
    currency: '\$',
  );
}

AiGeneratedItinerary _itin({
  double? budget,
  List<AiItineraryDay>? days,
  List<AiPackingItem>? packing,
  List<String>? tips,
}) {
  return AiGeneratedItinerary(
    destination: 'Bali',
    durationDays: 3,
    budget: budget,
    currency: '\$',
    interests: const [],
    days: days ?? const [],
    packingList: packing ?? const [],
    tips: tips ?? const [],
    generatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  group('ShareService.formatTrip', () {
    test('includes the trip name', () {
      final out = ShareService.formatTrip(_trip());
      expect(out, contains('Goa Getaway'));
    });

    test('includes destination when set', () {
      final out = ShareService.formatTrip(_trip(destination: 'Goa, India'));
      expect(out, contains('Goa, India'));
      expect(out, contains('Destination'));
    });

    test('omits destination row when null', () {
      final out = ShareService.formatTrip(_trip());
      expect(out, isNot(contains('Destination:')));
    });

    test('formats date range and duration when both dates are set', () {
      final out = ShareService.formatTrip(_trip(
        start: DateTime(2024, 6, 1),
        end: DateTime(2024, 6, 5),
      ));
      expect(out, contains('Dates'));
      expect(out, contains('Duration'));
      // 5 days inclusive = 5 days
      expect(out, contains('5 days'));
    });

    test('uses singular "day" for one-day trip', () {
      final out = ShareService.formatTrip(_trip(
        start: DateTime(2024, 6, 1),
        end: DateTime(2024, 6, 1),
      ));
      expect(out, contains('1 day'));
      expect(out, isNot(contains('1 days')));
    });

    test('includes cost when greater than zero', () {
      final out = ShareService.formatTrip(_trip(cost: 5000));
      expect(out, contains('Cost'));
      expect(out, contains('5,000'));
    });

    test('omits cost row when zero or null', () {
      expect(ShareService.formatTrip(_trip(cost: 0)),
          isNot(contains('Cost:')));
      expect(ShareService.formatTrip(_trip()),
          isNot(contains('Cost:')));
    });

    test('includes description when present', () {
      final out =
          ShareService.formatTrip(_trip(description: 'Beach holiday with friends'));
      expect(out, contains('Beach holiday with friends'));
    });

    test('appends invite code section when requested', () {
      final out = ShareService.formatTrip(
        _trip(),
        includeInviteLink: true,
        inviteCode: 'ABC123',
      );
      expect(out, contains('ABC123'));
      expect(out, contains('Join this trip'));
    });

    test('includes the TravelCompanion footer', () {
      final out = ShareService.formatTrip(_trip());
      expect(out, contains('TravelCompanion'));
    });
  });

  group('ShareService.formatAiItinerary', () {
    test('includes destination and duration', () {
      final out = ShareService.formatAiItinerary(_itin());
      expect(out, contains('Bali'));
      expect(out, contains('3 days'));
    });

    test('uses singular "day" for one-day itinerary', () {
      final itin = AiGeneratedItinerary(
        destination: 'X',
        durationDays: 1,
        currency: '\$',
        interests: const [],
        days: const [],
        packingList: const [],
        tips: const [],
        generatedAt: DateTime(2024, 1, 1),
      );
      final out = ShareService.formatAiItinerary(itin);
      expect(out, contains('1 day'));
    });

    test('includes budget when set', () {
      final out = ShareService.formatAiItinerary(_itin(budget: 30000));
      expect(out, contains('Estimated Budget'));
      expect(out, contains('30,000'));
    });

    test('omits budget when zero or null', () {
      expect(ShareService.formatAiItinerary(_itin()),
          isNot(contains('Estimated Budget')));
      expect(ShareService.formatAiItinerary(_itin(budget: 0)),
          isNot(contains('Estimated Budget')));
    });

    test('renders day titles and activities', () {
      final out = ShareService.formatAiItinerary(_itin(days: const [
        AiItineraryDay(
          dayNumber: 1,
          title: 'Arrival',
          activities: [
            AiItineraryActivity(
              title: 'Check into hotel',
              location: 'Kuta',
            ),
            AiItineraryActivity(
              title: 'Sunset at beach',
              startTime: '18:00',
            ),
          ],
        ),
      ]));
      expect(out, contains('Day 1'));
      expect(out, contains('Arrival'));
      expect(out, contains('Check into hotel'));
      expect(out, contains('Kuta'));
      expect(out, contains('Sunset at beach'));
      expect(out, contains('18:00'));
    });

    test('groups packing items by category', () {
      final out = ShareService.formatAiItinerary(_itin(packing: const [
        AiPackingItem(item: 'Sunscreen', category: 'Toiletries'),
        AiPackingItem(item: 'T-Shirt', category: 'Clothing'),
        AiPackingItem(item: 'Swim trunks', category: 'Clothing'),
      ]));
      expect(out, contains('PACKING LIST'));
      expect(out, contains('Toiletries'));
      expect(out, contains('Clothing'));
      expect(out, contains('Sunscreen'));
      expect(out, contains('T-Shirt'));
      expect(out, contains('Swim trunks'));
    });

    test('uses "Other" category when item has no category', () {
      final out = ShareService.formatAiItinerary(_itin(packing: const [
        AiPackingItem(item: 'Random thing'),
      ]));
      expect(out, contains('Other'));
      expect(out, contains('Random thing'));
    });

    test('renders travel tips when present', () {
      final out = ShareService.formatAiItinerary(_itin(tips: const [
        'Carry cash',
        'Drink bottled water',
      ]));
      expect(out, contains('TRAVEL TIPS'));
      expect(out, contains('Carry cash'));
      expect(out, contains('Drink bottled water'));
    });

    test('omits packing/tips sections when empty', () {
      final out = ShareService.formatAiItinerary(_itin());
      expect(out, isNot(contains('PACKING LIST')));
      expect(out, isNot(contains('TRAVEL TIPS')));
    });
  });

  group('ShareService.formatAiItineraryCompact', () {
    test('includes destination header line', () {
      final out = ShareService.formatAiItineraryCompact(_itin());
      expect(out, contains('Bali'));
      expect(out, contains('3 days'));
    });

    test('shows budget when set', () {
      final out =
          ShareService.formatAiItineraryCompact(_itin(budget: 25000));
      expect(out, contains('25,000'));
    });

    test('limits day highlights to first 3 activities', () {
      final out = ShareService.formatAiItineraryCompact(_itin(days: const [
        AiItineraryDay(
          dayNumber: 1,
          activities: [
            AiItineraryActivity(title: 'A1'),
            AiItineraryActivity(title: 'A2'),
            AiItineraryActivity(title: 'A3'),
            AiItineraryActivity(title: 'A4'),
          ],
        ),
      ]));
      expect(out, contains('A1'));
      expect(out, contains('A2'));
      expect(out, contains('A3'));
      // A4 should NOT appear because of .take(3)
      expect(out, isNot(contains('A4')));
    });
  });

  group('ShareService.formatExpenseSummary', () {
    test('renders trip name, total, and member count', () {
      final out = ShareService.formatExpenseSummary(
        tripName: 'Goa Trip',
        totalExpenses: 1500.0,
        currency: '\$',
        memberCount: 4,
      );
      expect(out, contains('Goa Trip'));
      expect(out, contains('1,500'));
      expect(out, contains('4'));
    });

    test('shows remaining budget when under', () {
      final out = ShareService.formatExpenseSummary(
        tripName: 'Trip',
        totalExpenses: 800,
        currency: '\$',
        memberCount: 2,
        budget: 1000,
      );
      expect(out, contains('Remaining'));
      expect(out, contains('200'));
    });

    test('shows over-budget warning when exceeded', () {
      final out = ShareService.formatExpenseSummary(
        tripName: 'Trip',
        totalExpenses: 1500,
        currency: '\$',
        memberCount: 2,
        budget: 1000,
      );
      expect(out, contains('Over Budget'));
      expect(out, contains('500'));
    });

    test('renders category breakdown when provided', () {
      final out = ShareService.formatExpenseSummary(
        tripName: 'Trip',
        totalExpenses: 1000,
        currency: '\$',
        memberCount: 2,
        categoryBreakdown: const {
          'Food': 400,
          'Transport': 300,
          'Shopping': 300,
        },
      );
      expect(out, contains('By Category'));
      expect(out, contains('Food'));
      expect(out, contains('Transport'));
      expect(out, contains('Shopping'));
    });
  });

  group('ShareService.formatChecklist', () {
    test('renders name, items and completion status', () {
      final out = ShareService.formatChecklist(
        checklistName: 'Packing',
        items: const ['Passport', 'Charger', 'Sunscreen'],
        completedStatus: const [true, false, true],
      );
      expect(out, contains('Packing'));
      expect(out, contains('Passport'));
      expect(out, contains('Charger'));
      expect(out, contains('Sunscreen'));
      // Progress: 2 of 3 completed
      expect(out, contains('2/3'));
    });

    test('includes trip name when provided', () {
      final out = ShareService.formatChecklist(
        checklistName: 'X',
        items: const ['A'],
        completedStatus: const [false],
        tripName: 'Goa Trip',
      );
      expect(out, contains('Goa Trip'));
    });

    test('handles all items completed', () {
      final out = ShareService.formatChecklist(
        checklistName: 'X',
        items: const ['A', 'B'],
        completedStatus: const [true, true],
      );
      expect(out, contains('2/2'));
    });

    test('handles missing completion status entries safely', () {
      // completedStatus shorter than items - extra items should be unchecked.
      final out = ShareService.formatChecklist(
        checklistName: 'X',
        items: const ['A', 'B', 'C'],
        completedStatus: const [true],
      );
      expect(out, contains('1/3'));
      expect(out, contains('A'));
      expect(out, contains('B'));
      expect(out, contains('C'));
    });
  });
}
