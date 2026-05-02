// Tests for AI itinerary domain entities
//
// Covers AiGeneratedItinerary, AiItineraryDay, AiItineraryActivity,
// AiPackingItem, AiActivityCategory + extension, AiItineraryRequest,
// TripCompanion, and DailyTiming.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/ai_itinerary/domain/entities/ai_itinerary.dart';

void main() {
  group('AiActivityCategoryExtension', () {
    test('fromString returns correct category for known values', () {
      expect(AiActivityCategoryExtension.fromString('activity'),
          AiActivityCategory.activity);
      expect(AiActivityCategoryExtension.fromString('transport'),
          AiActivityCategory.transport);
      expect(AiActivityCategoryExtension.fromString('food'),
          AiActivityCategory.food);
      expect(AiActivityCategoryExtension.fromString('accommodation'),
          AiActivityCategory.accommodation);
      expect(AiActivityCategoryExtension.fromString('sightseeing'),
          AiActivityCategory.sightseeing);
    });

    test('fromString is case-insensitive', () {
      expect(AiActivityCategoryExtension.fromString('FOOD'),
          AiActivityCategory.food);
      expect(AiActivityCategoryExtension.fromString('SightSeeing'),
          AiActivityCategory.sightseeing);
    });

    test('fromString defaults to activity for unknown values', () {
      expect(AiActivityCategoryExtension.fromString('unknown'),
          AiActivityCategory.activity);
      expect(AiActivityCategoryExtension.fromString(''),
          AiActivityCategory.activity);
    });

    test('displayName returns human-readable text per category', () {
      expect(AiActivityCategory.activity.displayName, 'Activity');
      expect(AiActivityCategory.transport.displayName, 'Transport');
      expect(AiActivityCategory.food.displayName, 'Food');
      expect(AiActivityCategory.accommodation.displayName, 'Stay');
      expect(AiActivityCategory.sightseeing.displayName, 'Sightseeing');
    });

    test('icon returns a unique icon per category', () {
      final icons = <IconData>{
        AiActivityCategory.activity.icon,
        AiActivityCategory.transport.icon,
        AiActivityCategory.food.icon,
        AiActivityCategory.accommodation.icon,
        AiActivityCategory.sightseeing.icon,
      };
      // 5 distinct icons
      expect(icons.length, 5);
      expect(AiActivityCategory.food.icon, Icons.restaurant);
      expect(AiActivityCategory.transport.icon, Icons.directions_car);
    });

    test('color returns a non-null Color per category', () {
      for (final cat in AiActivityCategory.values) {
        expect(cat.color, isA<Color>());
      }
      expect(AiActivityCategory.food.color, Colors.orange);
    });
  });

  group('AiPackingItem', () {
    test('default constructor sets isEssential=false and null category', () {
      const item = AiPackingItem(item: 'Sunscreen');
      expect(item.item, 'Sunscreen');
      expect(item.isEssential, false);
      expect(item.category, isNull);
    });

    test('fromJson parses standard payload', () {
      final item = AiPackingItem.fromJson({
        'item': 'Passport',
        'category': 'Documents',
        'is_essential': true,
      });
      expect(item.item, 'Passport');
      expect(item.category, 'Documents');
      expect(item.isEssential, true);
    });

    test('fromJson supports legacy "title" field as fallback', () {
      final item =
          AiPackingItem.fromJson({'title': 'Charger', 'isEssential': false});
      expect(item.item, 'Charger');
      expect(item.isEssential, false);
    });

    test('fromJson supports camelCase isEssential', () {
      final item = AiPackingItem.fromJson({
        'item': 'First-Aid Kit',
        'isEssential': true,
      });
      expect(item.isEssential, true);
    });

    test('fromJson falls back to "Unknown item" when no name field present',
        () {
      final item = AiPackingItem.fromJson({});
      expect(item.item, 'Unknown item');
      expect(item.isEssential, false);
    });

    test('toJson round-trips', () {
      const item = AiPackingItem(
          item: 'Tent', category: 'Camping', isEssential: true);
      final json = item.toJson();
      expect(json['item'], 'Tent');
      expect(json['category'], 'Camping');
      expect(json['is_essential'], true);

      final back = AiPackingItem.fromJson(json);
      expect(back.item, item.item);
      expect(back.category, item.category);
      expect(back.isEssential, item.isEssential);
    });
  });

  group('AiItineraryActivity', () {
    test('constructor uses sensible defaults', () {
      const activity = AiItineraryActivity(title: 'Walk');
      expect(activity.title, 'Walk');
      expect(activity.category, AiActivityCategory.activity);
      expect(activity.description, isNull);
      expect(activity.estimatedCost, isNull);
    });

    test('fromJson parses fully populated payload', () {
      final activity = AiItineraryActivity.fromJson({
        'title': 'Beach Visit',
        'description': 'Relax at Baga Beach',
        'location': 'Baga Beach',
        'start_time': '10:00',
        'end_time': '12:00',
        'duration_minutes': 120,
        'category': 'sightseeing',
        'estimated_cost': 500,
        'tip': 'Carry sunscreen',
      });

      expect(activity.title, 'Beach Visit');
      expect(activity.description, 'Relax at Baga Beach');
      expect(activity.location, 'Baga Beach');
      expect(activity.startTime, '10:00');
      expect(activity.endTime, '12:00');
      expect(activity.durationMinutes, 120);
      expect(activity.category, AiActivityCategory.sightseeing);
      expect(activity.estimatedCost, 500.0);
      expect(activity.tip, 'Carry sunscreen');
    });

    test('fromJson defaults category when missing', () {
      final activity = AiItineraryActivity.fromJson({'title': 'X'});
      expect(activity.category, AiActivityCategory.activity);
    });

    test('fromJson handles int estimated_cost via num.toDouble()', () {
      final activity = AiItineraryActivity.fromJson({
        'title': 'X',
        'estimated_cost': 250, // int -> num
      });
      expect(activity.estimatedCost, 250.0);
    });

    test('toJson round-trip preserves all fields', () {
      const activity = AiItineraryActivity(
        title: 'Lunch',
        description: 'Local thali',
        location: 'Restaurant XYZ',
        startTime: '13:00',
        endTime: '14:00',
        durationMinutes: 60,
        category: AiActivityCategory.food,
        estimatedCost: 350.0,
        tip: 'Order veg thali',
      );

      final json = activity.toJson();
      expect(json['category'], 'food');

      final back = AiItineraryActivity.fromJson(json);
      expect(back.title, activity.title);
      expect(back.description, activity.description);
      expect(back.location, activity.location);
      expect(back.startTime, activity.startTime);
      expect(back.endTime, activity.endTime);
      expect(back.durationMinutes, activity.durationMinutes);
      expect(back.category, activity.category);
      expect(back.estimatedCost, activity.estimatedCost);
      expect(back.tip, activity.tip);
    });
  });

  group('AiItineraryDay', () {
    test('fromJson parses day with multiple activities', () {
      final day = AiItineraryDay.fromJson({
        'day_number': 2,
        'title': 'Beach Day',
        'description': 'Coastal exploration',
        'activities': [
          {'title': 'Breakfast', 'category': 'food'},
          {'title': 'Sun bathe', 'category': 'sightseeing'},
        ],
      });

      expect(day.dayNumber, 2);
      expect(day.title, 'Beach Day');
      expect(day.description, 'Coastal exploration');
      expect(day.activities.length, 2);
      expect(day.activities[0].title, 'Breakfast');
      expect(day.activities[1].category, AiActivityCategory.sightseeing);
    });

    test('toJson round-trips empty-activity day', () {
      const day = AiItineraryDay(dayNumber: 1, activities: []);
      final json = day.toJson();
      expect(json['day_number'], 1);
      expect(json['activities'], isEmpty);
      expect(json['title'], isNull);

      final back = AiItineraryDay.fromJson(json);
      expect(back.dayNumber, 1);
      expect(back.activities, isEmpty);
    });
  });

  group('AiGeneratedItinerary', () {
    AiGeneratedItinerary sampleItinerary() {
      return AiGeneratedItinerary(
        destination: 'Goa',
        durationDays: 3,
        budget: 25000.0,
        currency: 'INR',
        interests: const ['Beach', 'Food'],
        days: const [
          AiItineraryDay(
            dayNumber: 1,
            title: 'Arrival',
            activities: [AiItineraryActivity(title: 'Check in')],
          ),
        ],
        packingList: const [
          AiPackingItem(item: 'Sunscreen', isEssential: true),
        ],
        tips: const ['Carry cash', 'Hydrate'],
        summary: 'Quick beach trip',
        generatedAt: DateTime.utc(2024, 1, 1, 12, 0, 0),
      );
    }

    test('default values applied via constructor', () {
      final itinerary = AiGeneratedItinerary(
        destination: 'X',
        durationDays: 1,
        days: const [],
        generatedAt: DateTime(2024),
      );
      expect(itinerary.currency, 'INR');
      expect(itinerary.interests, isEmpty);
      expect(itinerary.packingList, isEmpty);
      expect(itinerary.tips, isEmpty);
      expect(itinerary.budget, isNull);
      expect(itinerary.summary, isNull);
    });

    test('fromJson parses minimal required fields', () {
      final itinerary = AiGeneratedItinerary.fromJson({
        'destination': 'Bali',
        'duration_days': 5,
        'days': [
          {
            'day_number': 1,
            'activities': [
              {'title': 'Arrival'}
            ],
          }
        ],
      });

      expect(itinerary.destination, 'Bali');
      expect(itinerary.durationDays, 5);
      expect(itinerary.currency, 'INR'); // default
      expect(itinerary.interests, isEmpty);
      expect(itinerary.packingList, isEmpty);
      expect(itinerary.tips, isEmpty);
      expect(itinerary.budget, isNull);
      expect(itinerary.summary, isNull);
      expect(itinerary.days.length, 1);
    });

    test('fromJson parses fully populated payload', () {
      final itinerary = AiGeneratedItinerary.fromJson({
        'destination': 'Tokyo',
        'duration_days': 7,
        'budget': 100000,
        'currency': 'JPY',
        'interests': ['Anime', 'Food'],
        'days': [
          {
            'day_number': 1,
            'title': 'Shibuya day',
            'activities': [
              {'title': 'Ramen lunch', 'category': 'food'}
            ],
          }
        ],
        'packing_list': [
          {'item': 'JR Pass', 'is_essential': true}
        ],
        'tips': ['Get a Suica card'],
        'summary': 'Anime adventure',
        'generated_at': '2024-05-01T10:00:00.000Z',
      });

      expect(itinerary.destination, 'Tokyo');
      expect(itinerary.budget, 100000.0);
      expect(itinerary.currency, 'JPY');
      expect(itinerary.interests, ['Anime', 'Food']);
      expect(itinerary.packingList.length, 1);
      expect(itinerary.packingList.first.item, 'JR Pass');
      expect(itinerary.tips, ['Get a Suica card']);
      expect(itinerary.summary, 'Anime adventure');
      expect(itinerary.generatedAt.toUtc(),
          DateTime.utc(2024, 5, 1, 10, 0, 0));
    });

    test('fromJson uses DateTime.now when generated_at is missing', () {
      final before = DateTime.now();
      final itinerary = AiGeneratedItinerary.fromJson({
        'destination': 'X',
        'duration_days': 1,
        'days': [],
      });
      final after = DateTime.now();
      // generatedAt should fall between before and after.
      expect(
        itinerary.generatedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        itinerary.generatedAt.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });

    test('toJson includes all top-level keys', () {
      final itinerary = sampleItinerary();
      final json = itinerary.toJson();

      expect(json['destination'], 'Goa');
      expect(json['duration_days'], 3);
      expect(json['budget'], 25000.0);
      expect(json['currency'], 'INR');
      expect(json['interests'], ['Beach', 'Food']);
      expect(json['days'], isA<List>());
      expect((json['days'] as List).first, isA<Map<String, dynamic>>());
      expect(json['packing_list'], isA<List>());
      expect(json['tips'], ['Carry cash', 'Hydrate']);
      expect(json['summary'], 'Quick beach trip');
      expect(json['generated_at'], '2024-01-01T12:00:00.000Z');
    });

    test('round-trip toJson -> fromJson preserves data', () {
      final original = sampleItinerary();
      final back = AiGeneratedItinerary.fromJson(original.toJson());

      expect(back.destination, original.destination);
      expect(back.durationDays, original.durationDays);
      expect(back.budget, original.budget);
      expect(back.currency, original.currency);
      expect(back.interests, original.interests);
      expect(back.tips, original.tips);
      expect(back.summary, original.summary);
      expect(back.days.length, original.days.length);
      expect(back.days.first.title, original.days.first.title);
      expect(back.packingList.length, original.packingList.length);
      expect(back.packingList.first.item, original.packingList.first.item);
      expect(back.generatedAt, original.generatedAt);
    });
  });

  group('TripCompanion', () {
    test('toJson omits null optional fields', () {
      const companion = TripCompanion(name: 'Alice');
      final json = companion.toJson();
      expect(json['name'], 'Alice');
      expect(json.containsKey('relation'), false);
      expect(json.containsKey('age'), false);
    });

    test('toJson includes optional fields when set', () {
      const companion =
          TripCompanion(name: 'Bob', relation: 'partner', age: 30);
      final json = companion.toJson();
      expect(json['relation'], 'partner');
      expect(json['age'], 30);
    });

    test('fromJson parses payload', () {
      final companion = TripCompanion.fromJson({
        'name': 'Carol',
        'relation': 'friend',
        'age': 25,
      });
      expect(companion.name, 'Carol');
      expect(companion.relation, 'friend');
      expect(companion.age, 25);
    });
  });

  group('DailyTiming', () {
    test('toJson skips all null fields', () {
      const timing = DailyTiming();
      expect(timing.toJson(), isEmpty);
    });

    test('toJson includes only provided keys', () {
      const timing =
          DailyTiming(wakeUpTime: '06:00', dinnerTime: '20:00');
      final json = timing.toJson();
      expect(json['wake_up_time'], '06:00');
      expect(json['dinner_time'], '20:00');
      expect(json.containsKey('sleep_time'), false);
      expect(json.containsKey('breakfast_time'), false);
      expect(json.containsKey('lunch_time'), false);
    });

    test('fromJson round-trip', () {
      const timing = DailyTiming(
        wakeUpTime: '07:00',
        sleepTime: '23:00',
        breakfastTime: '08:30',
        lunchTime: '13:00',
        dinnerTime: '20:30',
      );
      final back = DailyTiming.fromJson(timing.toJson());
      expect(back.wakeUpTime, timing.wakeUpTime);
      expect(back.sleepTime, timing.sleepTime);
      expect(back.breakfastTime, timing.breakfastTime);
      expect(back.lunchTime, timing.lunchTime);
      expect(back.dinnerTime, timing.dinnerTime);
    });
  });

  group('AiItineraryRequest', () {
    test('toJson includes required fields and defaults', () {
      const request = AiItineraryRequest(
        destination: 'Manali',
        durationDays: 4,
      );
      final json = request.toJson();
      expect(json['destination'], 'Manali');
      expect(json['duration_days'], 4);
      expect(json['currency'], 'INR');
      expect(json['interests'], isEmpty);
      expect(json['include_food'], true);
      expect(json['include_accommodation'], true);
      expect(json['include_transport'], true);

      // Optional keys are omitted when null.
      expect(json.containsKey('voice_prompt'), false);
      expect(json.containsKey('companions'), false);
      expect(json.containsKey('primary_transport'), false);
      expect(json.containsKey('local_transport'), false);
      expect(json.containsKey('weather_context'), false);
      expect(json.containsKey('local_events'), false);
      expect(json.containsKey('preferred_timing'), false);
      expect(json.containsKey('start_date'), false);
      expect(json.containsKey('end_date'), false);
    });

    test('toJson serializes all enhanced context when provided', () {
      final request = AiItineraryRequest(
        destination: 'Kerala',
        durationDays: 6,
        budget: 50000,
        currency: 'INR',
        interests: const ['Nature'],
        travelStyle: 'Moderate',
        groupSize: 4,
        includeFood: false,
        includeAccommodation: false,
        includeTransport: false,
        voicePrompt: 'family vacation',
        companions: const [TripCompanion(name: 'Spouse')],
        primaryTransport: TransportMode.flight,
        localTransport: TransportMode.car,
        weatherContext: 'Monsoon expected',
        localEvents: 'Onam',
        preferredTiming: const DailyTiming(wakeUpTime: '06:00'),
        startDate: DateTime.utc(2024, 8, 1),
        endDate: DateTime.utc(2024, 8, 7),
      );

      final json = request.toJson();
      expect(json['voice_prompt'], 'family vacation');
      expect(json['primary_transport'], 'flight');
      expect(json['local_transport'], 'car');
      expect(json['weather_context'], 'Monsoon expected');
      expect(json['local_events'], 'Onam');
      expect(json['travel_style'], 'Moderate');
      expect(json['group_size'], 4);
      expect(json['include_food'], false);
      expect(json['preferred_timing'], isA<Map<String, dynamic>>());
      expect((json['preferred_timing'] as Map)['wake_up_time'], '06:00');
      expect(json['start_date'], '2024-08-01T00:00:00.000Z');
      expect(json['end_date'], '2024-08-07T00:00:00.000Z');
      final companions = json['companions'] as List;
      expect(companions.length, 1);
      expect((companions.first as Map)['name'], 'Spouse');
    });
  });

  group('TransportMode enum', () {
    test('exposes expected values', () {
      // Ensures none of the named values were renamed/removed.
      expect(TransportMode.values, containsAll(<TransportMode>[
        TransportMode.flight,
        TransportMode.train,
        TransportMode.bus,
        TransportMode.car,
        TransportMode.bike,
        TransportMode.auto,
        TransportMode.uber,
        TransportMode.metro,
        TransportMode.walk,
        TransportMode.mix,
      ]));
    });
  });
}
