import 'package:flutter/material.dart';
import 'discover_place.dart';
import 'place_category.dart';

/// Pace options for trip planning
enum TripPace {
  relaxed,
  moderate,
  packed;

  String get displayName {
    switch (this) {
      case TripPace.relaxed:
        return 'Relaxed';
      case TripPace.moderate:
        return 'Moderate';
      case TripPace.packed:
        return 'Packed';
    }
  }

  String get description {
    switch (this) {
      case TripPace.relaxed:
        return '2-3 activities per day';
      case TripPace.moderate:
        return '3-4 activities per day';
      case TripPace.packed:
        return '5+ activities per day';
    }
  }

  int get activitiesPerDay {
    switch (this) {
      case TripPace.relaxed:
        return 3;
      case TripPace.moderate:
        return 4;
      case TripPace.packed:
        return 6;
    }
  }

  IconData get icon {
    switch (this) {
      case TripPace.relaxed:
        return Icons.spa;
      case TripPace.moderate:
        return Icons.directions_walk;
      case TripPace.packed:
        return Icons.directions_run;
    }
  }

  Color get color {
    switch (this) {
      case TripPace.relaxed:
        return Colors.green;
      case TripPace.moderate:
        return Colors.blue;
      case TripPace.packed:
        return Colors.orange;
    }
  }
}

/// Trip planning preferences
class TripPlanPreferences {
  final TripPace pace;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool includeBreaks;
  final Duration breakDuration;
  final List<PlaceCategory> priorityCategories;

  const TripPlanPreferences({
    this.pace = TripPace.moderate,
    this.startTime = const TimeOfDay(hour: 9, minute: 0),
    this.endTime = const TimeOfDay(hour: 21, minute: 0),
    this.includeBreaks = true,
    this.breakDuration = const Duration(hours: 1),
    this.priorityCategories = const [],
  });

  TripPlanPreferences copyWith({
    TripPace? pace,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? includeBreaks,
    Duration? breakDuration,
    List<PlaceCategory>? priorityCategories,
  }) {
    return TripPlanPreferences(
      pace: pace ?? this.pace,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      includeBreaks: includeBreaks ?? this.includeBreaks,
      breakDuration: breakDuration ?? this.breakDuration,
      priorityCategories: priorityCategories ?? this.priorityCategories,
    );
  }

  /// Get total active hours per day
  double get activeHours {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    final totalMinutes = endMinutes - startMinutes;
    final breakMinutes = includeBreaks ? breakDuration.inMinutes : 0;
    return (totalMinutes - breakMinutes) / 60;
  }
}

/// A planned activity in the itinerary
class PlannedActivity {
  final DiscoverPlace place;
  final int dayNumber;
  final TimeOfDay suggestedStartTime;
  final Duration suggestedDuration;
  final String? notes;
  final int orderIndex;

  const PlannedActivity({
    required this.place,
    required this.dayNumber,
    required this.suggestedStartTime,
    required this.suggestedDuration,
    this.notes,
    required this.orderIndex,
  });

  /// Get suggested end time
  TimeOfDay get suggestedEndTime {
    final totalMinutes = suggestedStartTime.hour * 60 +
        suggestedStartTime.minute +
        suggestedDuration.inMinutes;
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }

  /// Format duration as string
  String get durationText {
    if (suggestedDuration.inHours >= 1) {
      final hours = suggestedDuration.inHours;
      final minutes = suggestedDuration.inMinutes % 60;
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    }
    return '${suggestedDuration.inMinutes}m';
  }
}

/// A day in the generated trip plan
class PlannedDay {
  final int dayNumber;
  final List<PlannedActivity> activities;
  final String? theme;

  const PlannedDay({
    required this.dayNumber,
    required this.activities,
    this.theme,
  });

  /// Get total planned duration for the day
  Duration get totalDuration {
    return activities.fold(
      Duration.zero,
      (total, activity) => total + activity.suggestedDuration,
    );
  }

  /// Get the number of activities
  int get activityCount => activities.length;
}

/// The complete generated trip plan
class GeneratedTripPlan {
  final List<PlannedDay> days;
  final TripPlanPreferences preferences;
  final List<DiscoverPlace> allPlaces;
  final DateTime generatedAt;

  const GeneratedTripPlan({
    required this.days,
    required this.preferences,
    required this.allPlaces,
    required this.generatedAt,
  });

  /// Get total number of activities planned
  int get totalActivities {
    return days.fold(0, (total, day) => total + day.activityCount);
  }

  /// Get places that weren't included
  List<DiscoverPlace> get unscheduledPlaces {
    final scheduledIds = days
        .expand((day) => day.activities)
        .map((activity) => activity.place.placeId)
        .toSet();
    return allPlaces.where((p) => !scheduledIds.contains(p.placeId)).toList();
  }
}

/// Engine for generating smart trip plans
class TripPlanEngine {
  /// Generate a trip plan from selected places
  static GeneratedTripPlan generatePlan({
    required List<DiscoverPlace> places,
    required int numberOfDays,
    required TripPlanPreferences preferences,
    double? userLatitude,
    double? userLongitude,
  }) {
    if (places.isEmpty || numberOfDays <= 0) {
      return GeneratedTripPlan(
        days: [],
        preferences: preferences,
        allPlaces: places,
        generatedAt: DateTime.now(),
      );
    }

    // Sort places by distance if user location available
    final sortedPlaces = _sortByProximity(
      places,
      userLatitude,
      userLongitude,
    );

    // Calculate how many places per day
    final activitiesPerDay = preferences.pace.activitiesPerDay;
    final totalPlaces = sortedPlaces.length;

    // Distribute places across days
    final days = <PlannedDay>[];
    var placeIndex = 0;

    for (var day = 1; day <= numberOfDays && placeIndex < totalPlaces; day++) {
      final dayActivities = <PlannedActivity>[];
      var currentTime = preferences.startTime;
      var orderIndex = 0;

      // Fill the day with activities
      while (dayActivities.length < activitiesPerDay &&
          placeIndex < totalPlaces) {
        final place = sortedPlaces[placeIndex];
        final duration = _estimateDuration(place);

        // Check if we have time for this activity
        final endTimeMinutes =
            preferences.endTime.hour * 60 + preferences.endTime.minute;
        final activityEndMinutes = currentTime.hour * 60 +
            currentTime.minute +
            duration.inMinutes;

        if (activityEndMinutes > endTimeMinutes) {
          // No more time today
          break;
        }

        dayActivities.add(PlannedActivity(
          place: place,
          dayNumber: day,
          suggestedStartTime: currentTime,
          suggestedDuration: duration,
          notes: _generateNotes(place),
          orderIndex: orderIndex,
        ));

        // Advance time (activity + break/travel)
        var nextMinutes = currentTime.hour * 60 +
            currentTime.minute +
            duration.inMinutes +
            30; // 30 min travel/buffer

        // Add lunch break around noon
        if (preferences.includeBreaks &&
            currentTime.hour < 12 &&
            (nextMinutes ~/ 60) >= 12) {
          nextMinutes += preferences.breakDuration.inMinutes;
        }

        currentTime = TimeOfDay(
          hour: (nextMinutes ~/ 60) % 24,
          minute: nextMinutes % 60,
        );

        placeIndex++;
        orderIndex++;
      }

      if (dayActivities.isNotEmpty) {
        days.add(PlannedDay(
          dayNumber: day,
          activities: dayActivities,
          theme: _generateDayTheme(dayActivities),
        ));
      }
    }

    return GeneratedTripPlan(
      days: days,
      preferences: preferences,
      allPlaces: places,
      generatedAt: DateTime.now(),
    );
  }

  /// Sort places by proximity to optimize travel
  static List<DiscoverPlace> _sortByProximity(
    List<DiscoverPlace> places,
    double? userLat,
    double? userLng,
  ) {
    if (userLat == null || userLng == null) return places;

    // Group places by category first for variety
    final byCategory = <PlaceCategory, List<DiscoverPlace>>{};
    for (final place in places) {
      byCategory.putIfAbsent(place.category, () => []).add(place);
    }

    // Sort each category by distance
    for (final category in byCategory.keys) {
      byCategory[category]!.sort((a, b) {
        final distA = a.distanceFrom(userLat, userLng) ?? double.infinity;
        final distB = b.distanceFrom(userLat, userLng) ?? double.infinity;
        return distA.compareTo(distB);
      });
    }

    // Interleave categories for variety
    final result = <DiscoverPlace>[];
    final categories = byCategory.keys.toList();
    var catIndex = 0;

    while (result.length < places.length) {
      for (var i = 0; i < categories.length && result.length < places.length; i++) {
        final cat = categories[(catIndex + i) % categories.length];
        final catPlaces = byCategory[cat]!;
        if (catPlaces.isNotEmpty) {
          result.add(catPlaces.removeAt(0));
        }
      }
      catIndex++;
    }

    return result;
  }

  /// Estimate duration based on place type
  static Duration _estimateDuration(DiscoverPlace place) {
    switch (place.category) {
      case PlaceCategory.beach:
        return const Duration(hours: 3);
      case PlaceCategory.hillStation:
        return const Duration(hours: 4);
      case PlaceCategory.heritage:
        return const Duration(hours: 2);
      case PlaceCategory.adventure:
        return const Duration(hours: 3);
      case PlaceCategory.wildlife:
        return const Duration(hours: 3);
      case PlaceCategory.religious:
        return const Duration(hours: 1, minutes: 30);
      case PlaceCategory.nature:
        return const Duration(hours: 2);
      case PlaceCategory.urban:
        return const Duration(hours: 2);
    }
  }

  /// Generate contextual notes for a place
  static String? _generateNotes(DiscoverPlace place) {
    final notes = <String>[];

    if (place.openNow == false) {
      notes.add('Check opening hours before visiting');
    }

    if (place.rating != null && place.rating! >= 4.5) {
      notes.add('Highly rated - popular spot');
    }

    switch (place.category) {
      case PlaceCategory.beach:
        notes.add('Bring sunscreen and beach essentials');
        break;
      case PlaceCategory.hillStation:
        notes.add('Carry warm clothing');
        break;
      case PlaceCategory.heritage:
        notes.add('Guided tours may be available');
        break;
      case PlaceCategory.religious:
        notes.add('Dress modestly');
        break;
      case PlaceCategory.adventure:
        notes.add('Wear comfortable shoes');
        break;
      case PlaceCategory.wildlife:
        notes.add('Bring binoculars and camera');
        break;
      default:
        break;
    }

    return notes.isNotEmpty ? notes.join('. ') : null;
  }

  /// Generate a theme for the day based on activities
  static String _generateDayTheme(List<PlannedActivity> activities) {
    if (activities.isEmpty) return 'Rest Day';

    // Count categories
    final categoryCounts = <PlaceCategory, int>{};
    for (final activity in activities) {
      final cat = activity.place.category;
      categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
    }

    // Find dominant category
    final sorted = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.length == 1) {
      return '${sorted.first.key.displayName} Day';
    }

    if (sorted.first.value > activities.length / 2) {
      return '${sorted.first.key.displayName} & More';
    }

    // Mixed day - create descriptive theme
    final top2 = sorted.take(2).map((e) => e.key.displayName).join(' & ');
    return 'Exploring $top2';
  }
}
