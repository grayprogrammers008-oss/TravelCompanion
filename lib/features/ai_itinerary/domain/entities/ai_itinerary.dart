// AI Generated Itinerary Entity
//
// Represents an AI-generated trip itinerary with all activities.

import 'package:flutter/material.dart';

/// A complete AI-generated itinerary
class AiGeneratedItinerary {
  final String destination;
  final int durationDays;
  final double? budget;
  final String currency;
  final List<String> interests;
  final List<AiItineraryDay> days;
  final List<AiPackingItem> packingList;
  final List<String> tips;
  final String? summary;
  final DateTime generatedAt;

  const AiGeneratedItinerary({
    required this.destination,
    required this.durationDays,
    this.budget,
    this.currency = 'INR',
    this.interests = const [],
    required this.days,
    this.packingList = const [],
    this.tips = const [],
    this.summary,
    required this.generatedAt,
  });

  factory AiGeneratedItinerary.fromJson(Map<String, dynamic> json) {
    return AiGeneratedItinerary(
      destination: json['destination'] as String,
      durationDays: json['duration_days'] as int,
      budget: json['budget'] != null ? (json['budget'] as num).toDouble() : null,
      currency: json['currency'] as String? ?? 'INR',
      interests: json['interests'] != null
          ? List<String>.from(json['interests'] as List)
          : const [],
      days: (json['days'] as List)
          .map((e) => AiItineraryDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      packingList: json['packing_list'] != null
          ? (json['packing_list'] as List)
              .map((e) => AiPackingItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      tips: json['tips'] != null
          ? List<String>.from(json['tips'] as List)
          : const [],
      summary: json['summary'] as String?,
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'destination': destination,
      'duration_days': durationDays,
      'budget': budget,
      'currency': currency,
      'interests': interests,
      'days': days.map((e) => e.toJson()).toList(),
      'packing_list': packingList.map((e) => e.toJson()).toList(),
      'tips': tips,
      'summary': summary,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

/// A single day in the AI-generated itinerary
class AiItineraryDay {
  final int dayNumber;
  final String? title;
  final String? description;
  final List<AiItineraryActivity> activities;

  const AiItineraryDay({
    required this.dayNumber,
    this.title,
    this.description,
    required this.activities,
  });

  factory AiItineraryDay.fromJson(Map<String, dynamic> json) {
    return AiItineraryDay(
      dayNumber: json['day_number'] as int,
      title: json['title'] as String?,
      description: json['description'] as String?,
      activities: (json['activities'] as List)
          .map((e) => AiItineraryActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_number': dayNumber,
      'title': title,
      'description': description,
      'activities': activities.map((e) => e.toJson()).toList(),
    };
  }
}

/// A single activity in the itinerary
class AiItineraryActivity {
  final String title;
  final String? description;
  final String? location;
  final String? startTime;
  final String? endTime;
  final int? durationMinutes;
  final AiActivityCategory category;
  final double? estimatedCost;
  final String? tip;

  const AiItineraryActivity({
    required this.title,
    this.description,
    this.location,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.category = AiActivityCategory.activity,
    this.estimatedCost,
    this.tip,
  });

  factory AiItineraryActivity.fromJson(Map<String, dynamic> json) {
    return AiItineraryActivity(
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      category: AiActivityCategoryExtension.fromString(
          json['category'] as String? ?? 'activity'),
      estimatedCost: json['estimated_cost'] != null
          ? (json['estimated_cost'] as num).toDouble()
          : null,
      tip: json['tip'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'start_time': startTime,
      'end_time': endTime,
      'duration_minutes': durationMinutes,
      'category': category.name,
      'estimated_cost': estimatedCost,
      'tip': tip,
    };
  }
}

/// Activity categories
enum AiActivityCategory {
  activity,
  transport,
  food,
  accommodation,
  sightseeing,
}

extension AiActivityCategoryExtension on AiActivityCategory {
  String get displayName {
    switch (this) {
      case AiActivityCategory.activity:
        return 'Activity';
      case AiActivityCategory.transport:
        return 'Transport';
      case AiActivityCategory.food:
        return 'Food';
      case AiActivityCategory.accommodation:
        return 'Stay';
      case AiActivityCategory.sightseeing:
        return 'Sightseeing';
    }
  }

  IconData get icon {
    switch (this) {
      case AiActivityCategory.activity:
        return Icons.directions_run;
      case AiActivityCategory.transport:
        return Icons.directions_car;
      case AiActivityCategory.food:
        return Icons.restaurant;
      case AiActivityCategory.accommodation:
        return Icons.hotel;
      case AiActivityCategory.sightseeing:
        return Icons.camera_alt;
    }
  }

  Color get color {
    switch (this) {
      case AiActivityCategory.activity:
        return Colors.blue;
      case AiActivityCategory.transport:
        return Colors.purple;
      case AiActivityCategory.food:
        return Colors.orange;
      case AiActivityCategory.accommodation:
        return Colors.teal;
      case AiActivityCategory.sightseeing:
        return Colors.pink;
    }
  }

  static AiActivityCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'activity':
        return AiActivityCategory.activity;
      case 'transport':
        return AiActivityCategory.transport;
      case 'food':
        return AiActivityCategory.food;
      case 'accommodation':
        return AiActivityCategory.accommodation;
      case 'sightseeing':
        return AiActivityCategory.sightseeing;
      default:
        return AiActivityCategory.activity;
    }
  }
}

/// Packing list item
class AiPackingItem {
  final String item;
  final String? category;
  final bool isEssential;

  const AiPackingItem({
    required this.item,
    this.category,
    this.isEssential = false,
  });

  factory AiPackingItem.fromJson(Map<String, dynamic> json) {
    return AiPackingItem(
      item: json['item'] as String,
      category: json['category'] as String?,
      isEssential: json['is_essential'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item': item,
      'category': category,
      'is_essential': isEssential,
    };
  }
}

/// Request parameters for AI itinerary generation
class AiItineraryRequest {
  final String destination;
  final int durationDays;
  final double? budget;
  final String currency;
  final List<String> interests;
  final String? travelStyle; // budget, moderate, luxury
  final int? groupSize;
  final bool includeFood;
  final bool includeAccommodation;
  final bool includeTransport;
  final String? voicePrompt; // Additional context from voice input

  // Enhanced context for comprehensive itinerary generation
  final List<TripCompanion>? companions; // Who's traveling (family, friends, couple, solo)
  final TransportMode? primaryTransport; // How they're traveling to destination
  final TransportMode? localTransport; // How they'll move around locally
  final String? weatherContext; // Weather information for the trip dates
  final String? localEvents; // Festivals, events happening during the trip
  final DailyTiming? preferredTiming; // When to wake up, sleep, etc.
  final DateTime? startDate; // Actual trip start date for weather/events
  final DateTime? endDate; // Actual trip end date

  const AiItineraryRequest({
    required this.destination,
    required this.durationDays,
    this.budget,
    this.currency = 'INR',
    this.interests = const [],
    this.travelStyle,
    this.groupSize,
    this.includeFood = true,
    this.includeAccommodation = true,
    this.includeTransport = true,
    this.voicePrompt,
    this.companions,
    this.primaryTransport,
    this.localTransport,
    this.weatherContext,
    this.localEvents,
    this.preferredTiming,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'destination': destination,
      'duration_days': durationDays,
      'budget': budget,
      'currency': currency,
      'interests': interests,
      'travel_style': travelStyle,
      'group_size': groupSize,
      'include_food': includeFood,
      'include_accommodation': includeAccommodation,
      'include_transport': includeTransport,
      if (voicePrompt != null) 'voice_prompt': voicePrompt,
      if (companions != null) 'companions': companions!.map((c) => c.toJson()).toList(),
      if (primaryTransport != null) 'primary_transport': primaryTransport!.name,
      if (localTransport != null) 'local_transport': localTransport!.name,
      if (weatherContext != null) 'weather_context': weatherContext,
      if (localEvents != null) 'local_events': localEvents,
      if (preferredTiming != null) 'preferred_timing': preferredTiming!.toJson(),
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
    };
  }
}

/// Trip companion information (who's traveling)
class TripCompanion {
  final String name;
  final String? relation; // family, friend, partner, colleague
  final int? age;

  const TripCompanion({
    required this.name,
    this.relation,
    this.age,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (relation != null) 'relation': relation,
      if (age != null) 'age': age,
    };
  }

  factory TripCompanion.fromJson(Map<String, dynamic> json) {
    return TripCompanion(
      name: json['name'] as String,
      relation: json['relation'] as String?,
      age: json['age'] as int?,
    );
  }
}

/// Transport modes
enum TransportMode {
  flight,
  train,
  bus,
  car,
  bike,
  auto, // Auto-rickshaw
  uber, // Ride-sharing
  metro,
  walk,
  mix, // Multiple modes
}

/// Daily timing preferences
class DailyTiming {
  final String? wakeUpTime; // e.g., "06:00"
  final String? sleepTime; // e.g., "22:00"
  final String? breakfastTime; // e.g., "08:00"
  final String? lunchTime; // e.g., "13:00"
  final String? dinnerTime; // e.g., "20:00"

  const DailyTiming({
    this.wakeUpTime,
    this.sleepTime,
    this.breakfastTime,
    this.lunchTime,
    this.dinnerTime,
  });

  Map<String, dynamic> toJson() {
    return {
      if (wakeUpTime != null) 'wake_up_time': wakeUpTime,
      if (sleepTime != null) 'sleep_time': sleepTime,
      if (breakfastTime != null) 'breakfast_time': breakfastTime,
      if (lunchTime != null) 'lunch_time': lunchTime,
      if (dinnerTime != null) 'dinner_time': dinnerTime,
    };
  }

  factory DailyTiming.fromJson(Map<String, dynamic> json) {
    return DailyTiming(
      wakeUpTime: json['wake_up_time'] as String?,
      sleepTime: json['sleep_time'] as String?,
      breakfastTime: json['breakfast_time'] as String?,
      lunchTime: json['lunch_time'] as String?,
      dinnerTime: json['dinner_time'] as String?,
    );
  }
}
