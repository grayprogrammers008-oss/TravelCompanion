// Trip Template Entity
//
// Represents a pre-built trip template that users can apply to their trips.

import 'package:flutter/material.dart';

/// Categories for trip templates
enum TemplateCategory {
  adventure,
  pilgrimage,
  beach,
  hillStation,
  heritage,
  wildlife,
  honeymoon,
  family,
  weekend,
  roadTrip,
}

extension TemplateCategoryExtension on TemplateCategory {
  String get displayName {
    switch (this) {
      case TemplateCategory.adventure:
        return 'Adventure';
      case TemplateCategory.pilgrimage:
        return 'Pilgrimage';
      case TemplateCategory.beach:
        return 'Beach';
      case TemplateCategory.hillStation:
        return 'Hill Station';
      case TemplateCategory.heritage:
        return 'Heritage';
      case TemplateCategory.wildlife:
        return 'Wildlife';
      case TemplateCategory.honeymoon:
        return 'Honeymoon';
      case TemplateCategory.family:
        return 'Family';
      case TemplateCategory.weekend:
        return 'Weekend';
      case TemplateCategory.roadTrip:
        return 'Road Trip';
    }
  }

  IconData get icon {
    switch (this) {
      case TemplateCategory.adventure:
        return Icons.terrain;
      case TemplateCategory.pilgrimage:
        return Icons.temple_hindu;
      case TemplateCategory.beach:
        return Icons.beach_access;
      case TemplateCategory.hillStation:
        return Icons.landscape;
      case TemplateCategory.heritage:
        return Icons.account_balance;
      case TemplateCategory.wildlife:
        return Icons.pets;
      case TemplateCategory.honeymoon:
        return Icons.favorite;
      case TemplateCategory.family:
        return Icons.family_restroom;
      case TemplateCategory.weekend:
        return Icons.weekend;
      case TemplateCategory.roadTrip:
        return Icons.directions_car;
    }
  }

  Color get color {
    switch (this) {
      case TemplateCategory.adventure:
        return Colors.orange;
      case TemplateCategory.pilgrimage:
        return Colors.amber;
      case TemplateCategory.beach:
        return Colors.cyan;
      case TemplateCategory.hillStation:
        return Colors.green;
      case TemplateCategory.heritage:
        return Colors.brown;
      case TemplateCategory.wildlife:
        return Colors.teal;
      case TemplateCategory.honeymoon:
        return Colors.pink;
      case TemplateCategory.family:
        return Colors.purple;
      case TemplateCategory.weekend:
        return Colors.blue;
      case TemplateCategory.roadTrip:
        return Colors.indigo;
    }
  }

  static TemplateCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'adventure':
        return TemplateCategory.adventure;
      case 'pilgrimage':
        return TemplateCategory.pilgrimage;
      case 'beach':
        return TemplateCategory.beach;
      case 'hill_station':
      case 'hillstation':
        return TemplateCategory.hillStation;
      case 'heritage':
        return TemplateCategory.heritage;
      case 'wildlife':
        return TemplateCategory.wildlife;
      case 'honeymoon':
        return TemplateCategory.honeymoon;
      case 'family':
        return TemplateCategory.family;
      case 'weekend':
        return TemplateCategory.weekend;
      case 'road_trip':
      case 'roadtrip':
        return TemplateCategory.roadTrip;
      default:
        return TemplateCategory.adventure;
    }
  }
}

/// Difficulty levels for trips
enum DifficultyLevel {
  easy,
  moderate,
  difficult,
}

extension DifficultyLevelExtension on DifficultyLevel {
  String get displayName {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.moderate:
        return 'Moderate';
      case DifficultyLevel.difficult:
        return 'Difficult';
    }
  }

  Color get color {
    switch (this) {
      case DifficultyLevel.easy:
        return Colors.green;
      case DifficultyLevel.moderate:
        return Colors.orange;
      case DifficultyLevel.difficult:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case DifficultyLevel.easy:
        return Icons.sentiment_satisfied;
      case DifficultyLevel.moderate:
        return Icons.sentiment_neutral;
      case DifficultyLevel.difficult:
        return Icons.sentiment_very_dissatisfied;
    }
  }

  static DifficultyLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'easy':
        return DifficultyLevel.easy;
      case 'moderate':
        return DifficultyLevel.moderate;
      case 'difficult':
        return DifficultyLevel.difficult;
      default:
        return DifficultyLevel.easy;
    }
  }
}

/// Itinerary item categories
enum ItineraryItemCategory {
  activity,
  transport,
  food,
  accommodation,
  sightseeing,
}

extension ItineraryItemCategoryExtension on ItineraryItemCategory {
  String get displayName {
    switch (this) {
      case ItineraryItemCategory.activity:
        return 'Activity';
      case ItineraryItemCategory.transport:
        return 'Transport';
      case ItineraryItemCategory.food:
        return 'Food';
      case ItineraryItemCategory.accommodation:
        return 'Stay';
      case ItineraryItemCategory.sightseeing:
        return 'Sightseeing';
    }
  }

  IconData get icon {
    switch (this) {
      case ItineraryItemCategory.activity:
        return Icons.directions_run;
      case ItineraryItemCategory.transport:
        return Icons.directions_car;
      case ItineraryItemCategory.food:
        return Icons.restaurant;
      case ItineraryItemCategory.accommodation:
        return Icons.hotel;
      case ItineraryItemCategory.sightseeing:
        return Icons.camera_alt;
    }
  }

  Color get color {
    switch (this) {
      case ItineraryItemCategory.activity:
        return Colors.blue;
      case ItineraryItemCategory.transport:
        return Colors.purple;
      case ItineraryItemCategory.food:
        return Colors.orange;
      case ItineraryItemCategory.accommodation:
        return Colors.teal;
      case ItineraryItemCategory.sightseeing:
        return Colors.pink;
    }
  }

  static ItineraryItemCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'activity':
        return ItineraryItemCategory.activity;
      case 'transport':
        return ItineraryItemCategory.transport;
      case 'food':
        return ItineraryItemCategory.food;
      case 'accommodation':
        return ItineraryItemCategory.accommodation;
      case 'sightseeing':
        return ItineraryItemCategory.sightseeing;
      default:
        return ItineraryItemCategory.activity;
    }
  }
}

/// Trip Template Model
class TripTemplate {
  final String id;
  final String name;
  final String? description;
  final String destination;
  final String? destinationState;
  final int durationDays;
  final double? budgetMin;
  final double? budgetMax;
  final String currency;
  final String? coverImageUrl;
  final TemplateCategory category;
  final List<String> tags;
  final List<String> bestSeason;
  final DifficultyLevel difficultyLevel;
  final bool isActive;
  final bool isFeatured;
  final int useCount;
  final double rating;
  final int ratingCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data (loaded separately)
  final List<TemplateItineraryItem>? itineraryItems;
  final List<TemplateChecklist>? checklists;

  const TripTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.destination,
    this.destinationState,
    required this.durationDays,
    this.budgetMin,
    this.budgetMax,
    this.currency = 'INR',
    this.coverImageUrl,
    required this.category,
    this.tags = const [],
    this.bestSeason = const [],
    this.difficultyLevel = DifficultyLevel.easy,
    this.isActive = true,
    this.isFeatured = false,
    this.useCount = 0,
    this.rating = 0,
    this.ratingCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.itineraryItems,
    this.checklists,
  });

  /// Budget range as formatted string
  String get budgetRange {
    if (budgetMin == null && budgetMax == null) return 'Flexible';
    if (budgetMin == null) return 'Up to ₹${_formatBudget(budgetMax!)}';
    if (budgetMax == null) return 'From ₹${_formatBudget(budgetMin!)}';
    return '₹${_formatBudget(budgetMin!)} - ₹${_formatBudget(budgetMax!)}';
  }

  /// Short budget display for cards
  String get budgetDisplay {
    if (budgetMin == null && budgetMax == null) return 'Flexible';
    if (budgetMax != null) return '₹${_formatBudget(budgetMax!)}';
    if (budgetMin != null) return '₹${_formatBudget(budgetMin!)}+';
    return 'Flexible';
  }

  String _formatBudget(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  /// Duration as formatted string
  String get durationText {
    if (durationDays == 1) return '1 Day';
    return '$durationDays Days';
  }

  factory TripTemplate.fromJson(Map<String, dynamic> json) {
    return TripTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      destination: json['destination'] as String,
      destinationState: json['destination_state'] as String?,
      durationDays: json['duration_days'] as int,
      budgetMin: json['budget_min'] != null
          ? (json['budget_min'] as num).toDouble()
          : null,
      budgetMax: json['budget_max'] != null
          ? (json['budget_max'] as num).toDouble()
          : null,
      currency: json['currency'] as String? ?? 'INR',
      coverImageUrl: json['cover_image_url'] as String?,
      category: TemplateCategoryExtension.fromString(
          json['category'] as String? ?? 'adventure'),
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : const [],
      bestSeason: json['best_season'] != null
          ? List<String>.from(json['best_season'] as List)
          : const [],
      difficultyLevel: DifficultyLevelExtension.fromString(
          json['difficulty_level'] as String? ?? 'easy'),
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      useCount: json['use_count'] as int? ?? 0,
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'destination': destination,
      'destination_state': destinationState,
      'duration_days': durationDays,
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      'currency': currency,
      'cover_image_url': coverImageUrl,
      'category': category.name,
      'tags': tags,
      'best_season': bestSeason,
      'difficulty_level': difficultyLevel.name,
      'is_active': isActive,
      'is_featured': isFeatured,
      'use_count': useCount,
      'rating': rating,
      'rating_count': ratingCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TripTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? destination,
    String? destinationState,
    int? durationDays,
    double? budgetMin,
    double? budgetMax,
    String? currency,
    String? coverImageUrl,
    TemplateCategory? category,
    List<String>? tags,
    List<String>? bestSeason,
    DifficultyLevel? difficultyLevel,
    bool? isActive,
    bool? isFeatured,
    int? useCount,
    double? rating,
    int? ratingCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TemplateItineraryItem>? itineraryItems,
    List<TemplateChecklist>? checklists,
  }) {
    return TripTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      destination: destination ?? this.destination,
      destinationState: destinationState ?? this.destinationState,
      durationDays: durationDays ?? this.durationDays,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      currency: currency ?? this.currency,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      bestSeason: bestSeason ?? this.bestSeason,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      useCount: useCount ?? this.useCount,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itineraryItems: itineraryItems ?? this.itineraryItems,
      checklists: checklists ?? this.checklists,
    );
  }
}

/// Template Itinerary Item
class TemplateItineraryItem {
  final String id;
  final String templateId;
  final int dayNumber;
  final int orderIndex;
  final String title;
  final String? description;
  final String? location;
  final String? locationUrl;
  final String? startTime; // HH:mm format
  final String? endTime;
  final int? durationMinutes;
  final String _categoryString;
  final double? estimatedCost;
  final String? tips;
  final DateTime createdAt;

  const TemplateItineraryItem({
    required this.id,
    required this.templateId,
    required this.dayNumber,
    required this.orderIndex,
    required this.title,
    this.description,
    this.location,
    this.locationUrl,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    String category = 'activity',
    this.estimatedCost,
    this.tips,
    required this.createdAt,
  }) : _categoryString = category;

  /// Get the category as an enum
  ItineraryItemCategory get category =>
      ItineraryItemCategoryExtension.fromString(_categoryString);

  /// Get the raw category string
  String get categoryString => _categoryString;

  factory TemplateItineraryItem.fromJson(Map<String, dynamic> json) {
    return TemplateItineraryItem(
      id: json['id'] as String,
      templateId: json['template_id'] as String,
      dayNumber: json['day_number'] as int,
      orderIndex: json['order_index'] as int? ?? 0,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      locationUrl: json['location_url'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      category: json['category'] as String? ?? 'activity',
      estimatedCost: json['estimated_cost'] != null
          ? (json['estimated_cost'] as num).toDouble()
          : null,
      tips: json['tips'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'template_id': templateId,
      'day_number': dayNumber,
      'order_index': orderIndex,
      'title': title,
      'description': description,
      'location': location,
      'location_url': locationUrl,
      'start_time': startTime,
      'end_time': endTime,
      'duration_minutes': durationMinutes,
      'category': categoryString,
      'estimated_cost': estimatedCost,
      'tips': tips,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Template Checklist
class TemplateChecklist {
  final String id;
  final String templateId;
  final String name;
  final String icon;
  final int orderIndex;
  final DateTime createdAt;
  final List<TemplateChecklistItem>? items;

  const TemplateChecklist({
    required this.id,
    required this.templateId,
    required this.name,
    this.icon = 'checklist',
    required this.orderIndex,
    required this.createdAt,
    this.items,
  });

  factory TemplateChecklist.fromJson(Map<String, dynamic> json) {
    return TemplateChecklist(
      id: json['id'] as String,
      templateId: json['template_id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'checklist',
      orderIndex: json['order_index'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((e) => TemplateChecklistItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'template_id': templateId,
      'name': name,
      'icon': icon,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'items': items?.map((e) => e.toJson()).toList(),
    };
  }
}

/// Template Checklist Item
class TemplateChecklistItem {
  final String id;
  final String checklistId;
  final String content;
  final int orderIndex;
  final bool isEssential;
  final String? category;
  final DateTime createdAt;

  const TemplateChecklistItem({
    required this.id,
    required this.checklistId,
    required this.content,
    required this.orderIndex,
    this.isEssential = false,
    this.category,
    required this.createdAt,
  });

  factory TemplateChecklistItem.fromJson(Map<String, dynamic> json) {
    return TemplateChecklistItem(
      id: json['id'] as String,
      checklistId: json['checklist_id'] as String,
      content: json['content'] as String,
      orderIndex: json['order_index'] as int? ?? 0,
      isEssential: json['is_essential'] as bool? ?? false,
      category: json['category'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'checklist_id': checklistId,
      'content': content,
      'order_index': orderIndex,
      'is_essential': isEssential,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
