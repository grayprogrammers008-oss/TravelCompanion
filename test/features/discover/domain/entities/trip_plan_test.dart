import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/discover/domain/entities/discover_place.dart';
import 'package:travel_crew/features/discover/domain/entities/place_category.dart';
import 'package:travel_crew/features/discover/domain/entities/trip_plan.dart';

DiscoverPlace _place({
  String id = 'p',
  String name = 'P',
  PlaceCategory category = PlaceCategory.nature,
  double? rating,
  bool? openNow,
  double? lat,
  double? lng,
}) =>
    DiscoverPlace(
      placeId: id,
      name: name,
      latitude: lat,
      longitude: lng,
      types: const [],
      photos: const [],
      category: category,
      rating: rating,
      openNow: openNow,
    );

void main() {
  group('TripPace', () {
    test('has 3 values', () {
      expect(TripPace.values, hasLength(3));
    });

    test('every pace has displayName / description / activitiesPerDay / icon / color', () {
      for (final p in TripPace.values) {
        expect(p.displayName, isNotEmpty);
        expect(p.description, isNotEmpty);
        expect(p.activitiesPerDay, greaterThan(0));
        expect(p.icon, isA<IconData>());
        expect(p.color, isA<Color>());
      }
    });

    test('packed has more activities per day than relaxed', () {
      expect(
        TripPace.packed.activitiesPerDay,
        greaterThan(TripPace.relaxed.activitiesPerDay),
      );
    });
  });

  group('TripPlanPreferences', () {
    test('default constructor uses moderate pace, 9-21 hours, with breaks', () {
      const prefs = TripPlanPreferences();
      expect(prefs.pace, TripPace.moderate);
      expect(prefs.startTime, const TimeOfDay(hour: 9, minute: 0));
      expect(prefs.endTime, const TimeOfDay(hour: 21, minute: 0));
      expect(prefs.includeBreaks, isTrue);
      expect(prefs.breakDuration, const Duration(hours: 1));
      expect(prefs.priorityCategories, isEmpty);
    });

    test('copyWith overrides specified fields', () {
      const prefs = TripPlanPreferences();
      final next = prefs.copyWith(
        pace: TripPace.packed,
        startTime: const TimeOfDay(hour: 7, minute: 30),
      );
      expect(next.pace, TripPace.packed);
      expect(next.startTime, const TimeOfDay(hour: 7, minute: 30));
      expect(next.endTime, prefs.endTime); // unchanged
    });

    test('activeHours subtracts break when includeBreaks is true', () {
      const prefs = TripPlanPreferences(); // 9-21 with 1h break = 11h
      expect(prefs.activeHours, 11.0);
    });

    test('activeHours equals full window when includeBreaks is false', () {
      const prefs = TripPlanPreferences(includeBreaks: false);
      expect(prefs.activeHours, 12.0);
    });
  });

  group('PlannedActivity', () {
    test('suggestedEndTime adds duration to start', () {
      final activity = PlannedActivity(
        place: _place(),
        dayNumber: 1,
        suggestedStartTime: const TimeOfDay(hour: 9, minute: 30),
        suggestedDuration: const Duration(hours: 2, minutes: 15),
        orderIndex: 0,
      );
      expect(activity.suggestedEndTime, const TimeOfDay(hour: 11, minute: 45));
    });

    test('suggestedEndTime wraps past 24h via modulo', () {
      final activity = PlannedActivity(
        place: _place(),
        dayNumber: 1,
        suggestedStartTime: const TimeOfDay(hour: 23, minute: 0),
        suggestedDuration: const Duration(hours: 2),
        orderIndex: 0,
      );
      expect(activity.suggestedEndTime, const TimeOfDay(hour: 1, minute: 0));
    });

    test('durationText formats hours / minutes / mixed', () {
      PlannedActivity build(Duration d) => PlannedActivity(
            place: _place(),
            dayNumber: 1,
            suggestedStartTime: const TimeOfDay(hour: 9, minute: 0),
            suggestedDuration: d,
            orderIndex: 0,
          );
      expect(build(const Duration(hours: 2)).durationText, '2h');
      expect(build(const Duration(hours: 1, minutes: 30)).durationText, '1h 30m');
      expect(build(const Duration(minutes: 45)).durationText, '45m');
    });
  });

  group('PlannedDay', () {
    final activity1 = PlannedActivity(
      place: _place(id: 'a'),
      dayNumber: 1,
      suggestedStartTime: const TimeOfDay(hour: 9, minute: 0),
      suggestedDuration: const Duration(hours: 2),
      orderIndex: 0,
    );
    final activity2 = PlannedActivity(
      place: _place(id: 'b'),
      dayNumber: 1,
      suggestedStartTime: const TimeOfDay(hour: 12, minute: 0),
      suggestedDuration: const Duration(hours: 3),
      orderIndex: 1,
    );

    test('totalDuration sums activity durations', () {
      final day = PlannedDay(dayNumber: 1, activities: [activity1, activity2]);
      expect(day.totalDuration, const Duration(hours: 5));
    });

    test('activityCount returns list length', () {
      final day = PlannedDay(dayNumber: 1, activities: [activity1, activity2]);
      expect(day.activityCount, 2);
    });

    test('totalDuration is zero for empty day', () {
      const day = PlannedDay(dayNumber: 1, activities: []);
      expect(day.totalDuration, Duration.zero);
      expect(day.activityCount, 0);
    });
  });

  group('GeneratedTripPlan', () {
    test('totalActivities sums activities across days', () {
      final placeA = _place(id: 'a');
      final placeB = _place(id: 'b');
      final activityA = PlannedActivity(
        place: placeA,
        dayNumber: 1,
        suggestedStartTime: const TimeOfDay(hour: 9, minute: 0),
        suggestedDuration: const Duration(hours: 2),
        orderIndex: 0,
      );
      final activityB = PlannedActivity(
        place: placeB,
        dayNumber: 2,
        suggestedStartTime: const TimeOfDay(hour: 9, minute: 0),
        suggestedDuration: const Duration(hours: 2),
        orderIndex: 0,
      );
      final plan = GeneratedTripPlan(
        days: [
          PlannedDay(dayNumber: 1, activities: [activityA]),
          PlannedDay(dayNumber: 2, activities: [activityB]),
        ],
        preferences: const TripPlanPreferences(),
        allPlaces: [placeA, placeB],
        generatedAt: DateTime(2025, 6, 1),
      );
      expect(plan.totalActivities, 2);
    });

    test('unscheduledPlaces returns places not in any day activity', () {
      final scheduled = _place(id: 'scheduled');
      final unscheduled = _place(id: 'unscheduled');
      final plan = GeneratedTripPlan(
        days: [
          PlannedDay(
            dayNumber: 1,
            activities: [
              PlannedActivity(
                place: scheduled,
                dayNumber: 1,
                suggestedStartTime: const TimeOfDay(hour: 9, minute: 0),
                suggestedDuration: const Duration(hours: 2),
                orderIndex: 0,
              ),
            ],
          ),
        ],
        preferences: const TripPlanPreferences(),
        allPlaces: [scheduled, unscheduled],
        generatedAt: DateTime(2025),
      );
      expect(plan.unscheduledPlaces.map((p) => p.placeId), ['unscheduled']);
    });
  });

  group('TripPlanEngine.generatePlan', () {
    test('returns empty plan for empty places', () {
      final plan = TripPlanEngine.generatePlan(
        places: const [],
        numberOfDays: 3,
        preferences: const TripPlanPreferences(),
      );
      expect(plan.days, isEmpty);
      expect(plan.totalActivities, 0);
    });

    test('returns empty plan for zero days', () {
      final plan = TripPlanEngine.generatePlan(
        places: [_place()],
        numberOfDays: 0,
        preferences: const TripPlanPreferences(),
      );
      expect(plan.days, isEmpty);
    });

    test('schedules activities up to pace.activitiesPerDay per day', () {
      // 8 places, packed pace (6 per day), 2 days → all 8 fit
      final places = List.generate(
        8,
        (i) => _place(id: 'p$i', category: PlaceCategory.heritage),
      );
      final plan = TripPlanEngine.generatePlan(
        places: places,
        numberOfDays: 2,
        preferences: const TripPlanPreferences(pace: TripPace.packed),
      );
      // Day 1 should have up to 6 activities; total 8 across both days.
      expect(plan.totalActivities, lessThanOrEqualTo(8));
      expect(plan.days.first.activityCount,
          lessThanOrEqualTo(TripPace.packed.activitiesPerDay));
    });

    test('preserves all places across days when pace and time allow', () {
      final places = List.generate(
        3,
        (i) => _place(id: 'p$i', category: PlaceCategory.heritage), // 2h each
      );
      final plan = TripPlanEngine.generatePlan(
        places: places,
        numberOfDays: 1,
        preferences: const TripPlanPreferences(),
      );
      // All 3 should fit (3 x 2h = 6h within 9-21 window with break)
      expect(plan.totalActivities, 3);
    });

    test('every PlannedActivity has dayNumber matching its containing day', () {
      final places = List.generate(
        4,
        (i) => _place(id: 'p$i', category: PlaceCategory.heritage),
      );
      final plan = TripPlanEngine.generatePlan(
        places: places,
        numberOfDays: 2,
        preferences: const TripPlanPreferences(pace: TripPace.relaxed),
      );
      for (final day in plan.days) {
        for (final activity in day.activities) {
          expect(activity.dayNumber, day.dayNumber);
        }
      }
    });

    test('orderIndex starts at 0 within each day and increments by 1', () {
      final places = List.generate(
        4,
        (i) => _place(id: 'p$i', category: PlaceCategory.heritage),
      );
      final plan = TripPlanEngine.generatePlan(
        places: places,
        numberOfDays: 1,
        preferences: const TripPlanPreferences(pace: TripPace.packed),
      );
      for (var i = 0; i < plan.days.first.activities.length; i++) {
        expect(plan.days.first.activities[i].orderIndex, i);
      }
    });

    test('day theme is set on every day with at least one activity', () {
      final places = [
        _place(id: 'a', category: PlaceCategory.heritage),
      ];
      final plan = TripPlanEngine.generatePlan(
        places: places,
        numberOfDays: 1,
        preferences: const TripPlanPreferences(),
      );
      expect(plan.days.first.theme, isNotNull);
      expect(plan.days.first.theme, isNotEmpty);
    });

    test('generated plan estimates duration per category', () {
      // beach=3h, heritage=2h, religious=1h30m, etc.
      final beach = _place(id: 'b', category: PlaceCategory.beach);
      final heritage = _place(id: 'h', category: PlaceCategory.heritage);
      final religious = _place(id: 'r', category: PlaceCategory.religious);
      final plan = TripPlanEngine.generatePlan(
        places: [beach, heritage, religious],
        numberOfDays: 1,
        preferences: const TripPlanPreferences(),
      );
      // Find each activity by placeId; check duration matches category estimate.
      final flatActivities =
          plan.days.expand((d) => d.activities).toList();
      Duration durOf(String id) =>
          flatActivities.firstWhere((a) => a.place.placeId == id).suggestedDuration;
      expect(durOf('b'), const Duration(hours: 3));
      expect(durOf('h'), const Duration(hours: 2));
      expect(durOf('r'), const Duration(hours: 1, minutes: 30));
    });

    test('notes contain category-specific guidance', () {
      final beach = _place(id: 'b', category: PlaceCategory.beach);
      final plan = TripPlanEngine.generatePlan(
        places: [beach],
        numberOfDays: 1,
        preferences: const TripPlanPreferences(),
      );
      final notes = plan.days.first.activities.first.notes;
      expect(notes, isNotNull);
      expect(notes!.toLowerCase(), contains('sunscreen'));
    });

    test('respects user location for proximity-based ordering', () {
      // When userLat/Lng given, the engine groups by category and orders within
      // each category by distance. With one category and two places, the
      // closer one should appear first.
      final far = _place(
        id: 'far',
        category: PlaceCategory.heritage,
        lat: 1.0,
        lng: 1.0,
      );
      final close = _place(
        id: 'close',
        category: PlaceCategory.heritage,
        lat: 0.0,
        lng: 0.001,
      );
      final plan = TripPlanEngine.generatePlan(
        places: [far, close],
        numberOfDays: 1,
        preferences: const TripPlanPreferences(),
        userLatitude: 0.0,
        userLongitude: 0.0,
      );
      final order =
          plan.days.first.activities.map((a) => a.place.placeId).toList();
      expect(order.first, 'close');
    });
  });
}
