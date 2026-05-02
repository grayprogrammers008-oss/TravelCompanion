import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/templates/domain/entities/trip_template.dart';

TripTemplate _template({
  String id = 't-1',
  String name = 'Goa Beach Hop',
  String? description = 'Sunny days',
  String destination = 'Goa',
  String? destinationState = 'Goa',
  int durationDays = 3,
  double? budgetMin,
  double? budgetMax,
  String currency = 'INR',
  String? coverImageUrl,
  TemplateCategory category = TemplateCategory.beach,
  List<String> tags = const ['sun', 'sand'],
  List<String> bestSeason = const ['Nov', 'Dec'],
  DifficultyLevel difficultyLevel = DifficultyLevel.easy,
  bool isActive = true,
  bool isFeatured = false,
  int useCount = 0,
  double rating = 0,
  int ratingCount = 0,
}) {
  final now = DateTime.parse('2026-01-01T00:00:00Z');
  return TripTemplate(
    id: id,
    name: name,
    description: description,
    destination: destination,
    destinationState: destinationState,
    durationDays: durationDays,
    budgetMin: budgetMin,
    budgetMax: budgetMax,
    currency: currency,
    coverImageUrl: coverImageUrl,
    category: category,
    tags: tags,
    bestSeason: bestSeason,
    difficultyLevel: difficultyLevel,
    isActive: isActive,
    isFeatured: isFeatured,
    useCount: useCount,
    rating: rating,
    ratingCount: ratingCount,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('TemplateCategory.fromString', () {
    test('maps known lowercase strings to correct enum', () {
      expect(TemplateCategoryExtension.fromString('adventure'),
          TemplateCategory.adventure);
      expect(TemplateCategoryExtension.fromString('pilgrimage'),
          TemplateCategory.pilgrimage);
      expect(TemplateCategoryExtension.fromString('beach'),
          TemplateCategory.beach);
      expect(TemplateCategoryExtension.fromString('heritage'),
          TemplateCategory.heritage);
      expect(TemplateCategoryExtension.fromString('wildlife'),
          TemplateCategory.wildlife);
      expect(TemplateCategoryExtension.fromString('honeymoon'),
          TemplateCategory.honeymoon);
      expect(TemplateCategoryExtension.fromString('family'),
          TemplateCategory.family);
      expect(TemplateCategoryExtension.fromString('weekend'),
          TemplateCategory.weekend);
    });

    test('handles snake_case and camelCase aliases', () {
      expect(TemplateCategoryExtension.fromString('hill_station'),
          TemplateCategory.hillStation);
      expect(TemplateCategoryExtension.fromString('hillstation'),
          TemplateCategory.hillStation);
      expect(TemplateCategoryExtension.fromString('road_trip'),
          TemplateCategory.roadTrip);
      expect(TemplateCategoryExtension.fromString('roadtrip'),
          TemplateCategory.roadTrip);
    });

    test('is case-insensitive', () {
      expect(TemplateCategoryExtension.fromString('BEACH'),
          TemplateCategory.beach);
      expect(TemplateCategoryExtension.fromString('Adventure'),
          TemplateCategory.adventure);
    });

    test('returns adventure as fallback for unknown', () {
      expect(TemplateCategoryExtension.fromString('unknown-cat'),
          TemplateCategory.adventure);
      expect(TemplateCategoryExtension.fromString(''),
          TemplateCategory.adventure);
    });
  });

  group('TemplateCategoryExtension display data', () {
    test('displayName returns human-readable strings', () {
      expect(TemplateCategory.adventure.displayName, 'Adventure');
      expect(TemplateCategory.hillStation.displayName, 'Hill Station');
      expect(TemplateCategory.roadTrip.displayName, 'Road Trip');
    });

    test('icon and color are non-null for every category', () {
      for (final cat in TemplateCategory.values) {
        expect(cat.icon, isA<IconData>());
        expect(cat.color, isA<Color>());
      }
    });
  });

  group('DifficultyLevel.fromString', () {
    test('maps standard strings', () {
      expect(DifficultyLevelExtension.fromString('easy'),
          DifficultyLevel.easy);
      expect(DifficultyLevelExtension.fromString('moderate'),
          DifficultyLevel.moderate);
      expect(DifficultyLevelExtension.fromString('difficult'),
          DifficultyLevel.difficult);
    });

    test('is case-insensitive', () {
      expect(DifficultyLevelExtension.fromString('MODERATE'),
          DifficultyLevel.moderate);
    });

    test('falls back to easy on unknown', () {
      expect(DifficultyLevelExtension.fromString('extreme'),
          DifficultyLevel.easy);
    });

    test('display data is populated for every level', () {
      for (final lvl in DifficultyLevel.values) {
        expect(lvl.displayName.isNotEmpty, isTrue);
        expect(lvl.color, isA<Color>());
        expect(lvl.icon, isA<IconData>());
      }
    });
  });

  group('ItineraryItemCategory.fromString', () {
    test('maps known strings', () {
      expect(ItineraryItemCategoryExtension.fromString('activity'),
          ItineraryItemCategory.activity);
      expect(ItineraryItemCategoryExtension.fromString('transport'),
          ItineraryItemCategory.transport);
      expect(ItineraryItemCategoryExtension.fromString('food'),
          ItineraryItemCategory.food);
      expect(ItineraryItemCategoryExtension.fromString('accommodation'),
          ItineraryItemCategory.accommodation);
      expect(ItineraryItemCategoryExtension.fromString('sightseeing'),
          ItineraryItemCategory.sightseeing);
    });

    test('falls back to activity on unknown', () {
      expect(ItineraryItemCategoryExtension.fromString('whatever'),
          ItineraryItemCategory.activity);
    });

    test('displayName for accommodation is "Stay"', () {
      expect(ItineraryItemCategory.accommodation.displayName, 'Stay');
    });
  });

  group('TripTemplate.budgetRange', () {
    test('returns Flexible when both bounds are null', () {
      expect(_template().budgetRange, 'Flexible');
    });

    test('formats only-max as "Up to ..."', () {
      expect(_template(budgetMax: 50000).budgetRange, contains('Up to'));
      expect(_template(budgetMax: 50000).budgetRange, contains('50K'));
    });

    test('formats only-min as "From ..."', () {
      expect(_template(budgetMin: 25000).budgetRange, contains('From'));
      expect(_template(budgetMin: 25000).budgetRange, contains('25K'));
    });

    test('formats range with both bounds', () {
      final r = _template(budgetMin: 10000, budgetMax: 50000).budgetRange;
      expect(r, contains('10K'));
      expect(r, contains('50K'));
      expect(r, contains('-'));
    });

    test('formats lakhs with L suffix', () {
      expect(_template(budgetMax: 250000).budgetRange, contains('2.5L'));
    });

    test('formats sub-thousand budgets verbatim', () {
      // 500 -> formatted as "500"
      expect(_template(budgetMax: 500).budgetRange, contains('500'));
    });
  });

  group('TripTemplate.budgetDisplay', () {
    test('returns Flexible when both bounds are null', () {
      expect(_template().budgetDisplay, 'Flexible');
    });

    test('uses max value when present', () {
      expect(_template(budgetMin: 1000, budgetMax: 5000).budgetDisplay,
          contains('5K'));
    });

    test('uses min with + suffix when only min set', () {
      final disp = _template(budgetMin: 1000).budgetDisplay;
      expect(disp, contains('1K'));
      expect(disp.endsWith('+'), isTrue);
    });
  });

  group('TripTemplate.durationText', () {
    test('returns singular for 1 day', () {
      expect(_template(durationDays: 1).durationText, '1 Day');
    });

    test('returns plural for >1 days', () {
      expect(_template(durationDays: 5).durationText, '5 Days');
    });
  });

  group('TripTemplate.fromJson', () {
    test('parses required fields', () {
      final json = {
        'id': 'abc',
        'name': 'Sample',
        'destination': 'Paris',
        'duration_days': 4,
        'category': 'beach',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
      };
      final t = TripTemplate.fromJson(json);
      expect(t.id, 'abc');
      expect(t.name, 'Sample');
      expect(t.destination, 'Paris');
      expect(t.durationDays, 4);
      expect(t.category, TemplateCategory.beach);
      expect(t.currency, 'INR'); // default
      expect(t.isActive, isTrue);
      expect(t.isFeatured, isFalse);
      expect(t.useCount, 0);
      expect(t.tags, isEmpty);
      expect(t.bestSeason, isEmpty);
      expect(t.difficultyLevel, DifficultyLevel.easy);
    });

    test('parses optional/nested fields when present', () {
      final json = {
        'id': 'abc',
        'name': 'Trek',
        'description': 'Mountain trek',
        'destination': 'Manali',
        'destination_state': 'Himachal',
        'duration_days': 7,
        'budget_min': 10000,
        'budget_max': 50000.5,
        'currency': 'USD',
        'cover_image_url': 'http://example.com/img.jpg',
        'category': 'adventure',
        'tags': ['trek', 'snow'],
        'best_season': ['Dec', 'Jan'],
        'difficulty_level': 'difficult',
        'is_active': false,
        'is_featured': true,
        'use_count': 42,
        'rating': 4.7,
        'rating_count': 12,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
      };
      final t = TripTemplate.fromJson(json);
      expect(t.description, 'Mountain trek');
      expect(t.destinationState, 'Himachal');
      expect(t.budgetMin, 10000);
      expect(t.budgetMax, closeTo(50000.5, 0.0001));
      expect(t.currency, 'USD');
      expect(t.coverImageUrl, 'http://example.com/img.jpg');
      expect(t.category, TemplateCategory.adventure);
      expect(t.tags, ['trek', 'snow']);
      expect(t.bestSeason, ['Dec', 'Jan']);
      expect(t.difficultyLevel, DifficultyLevel.difficult);
      expect(t.isActive, isFalse);
      expect(t.isFeatured, isTrue);
      expect(t.useCount, 42);
      expect(t.rating, closeTo(4.7, 0.0001));
      expect(t.ratingCount, 12);
    });

    test('handles missing optional collections gracefully', () {
      final json = {
        'id': 'a',
        'name': 'b',
        'destination': 'c',
        'duration_days': 1,
        'category': 'unknown', // falls back to adventure
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final t = TripTemplate.fromJson(json);
      expect(t.category, TemplateCategory.adventure);
      expect(t.tags, isEmpty);
      expect(t.bestSeason, isEmpty);
    });
  });

  group('TripTemplate.toJson', () {
    test('emits expected snake_case keys', () {
      final t = _template(
        budgetMin: 100,
        budgetMax: 500,
        coverImageUrl: 'http://x',
        category: TemplateCategory.heritage,
        difficultyLevel: DifficultyLevel.moderate,
      );
      final json = t.toJson();

      expect(json['id'], 't-1');
      expect(json['name'], 'Goa Beach Hop');
      expect(json['destination'], 'Goa');
      expect(json['destination_state'], 'Goa');
      expect(json['duration_days'], 3);
      expect(json['budget_min'], 100);
      expect(json['budget_max'], 500);
      expect(json['currency'], 'INR');
      expect(json['cover_image_url'], 'http://x');
      expect(json['category'], 'heritage');
      expect(json['difficulty_level'], 'moderate');
      expect(json['is_active'], isTrue);
      expect(json['tags'], ['sun', 'sand']);
      expect(json['best_season'], ['Nov', 'Dec']);
      expect(json['created_at'], isA<String>());
      expect(json['updated_at'], isA<String>());
    });

    test('round-trips through fromJson', () {
      final t = _template(
        budgetMin: 1000,
        budgetMax: 5000,
        category: TemplateCategory.weekend,
      );
      final round = TripTemplate.fromJson(t.toJson());
      expect(round.id, t.id);
      expect(round.name, t.name);
      expect(round.budgetMin, t.budgetMin);
      expect(round.budgetMax, t.budgetMax);
      expect(round.category, t.category);
      expect(round.tags, t.tags);
      expect(round.bestSeason, t.bestSeason);
    });
  });

  group('TripTemplate.copyWith', () {
    test('returns identical fields when no overrides', () {
      final t = _template();
      final c = t.copyWith();
      expect(c.id, t.id);
      expect(c.name, t.name);
      expect(c.category, t.category);
    });

    test('overrides only specified fields', () {
      final t = _template(name: 'Old', useCount: 1);
      final c = t.copyWith(name: 'New', useCount: 99);
      expect(c.name, 'New');
      expect(c.useCount, 99);
      // Other fields preserved
      expect(c.id, t.id);
      expect(c.destination, t.destination);
    });

    test('can add itineraryItems and checklists', () {
      final t = _template();
      final item = TemplateItineraryItem(
        id: 'i-1',
        templateId: t.id,
        dayNumber: 1,
        orderIndex: 0,
        title: 'Hello',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );
      final cl = TemplateChecklist(
        id: 'cl-1',
        templateId: t.id,
        name: 'Pack',
        orderIndex: 0,
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );
      final c = t.copyWith(itineraryItems: [item], checklists: [cl]);
      expect(c.itineraryItems!.first.title, 'Hello');
      expect(c.checklists!.first.name, 'Pack');
    });
  });

  group('TemplateItineraryItem', () {
    test('exposes category enum from raw string', () {
      final item = TemplateItineraryItem(
        id: 'i',
        templateId: 't',
        dayNumber: 1,
        orderIndex: 0,
        title: 'Lunch',
        category: 'food',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );
      expect(item.category, ItineraryItemCategory.food);
      expect(item.categoryString, 'food');
    });

    test('falls back to activity when category string unknown', () {
      final item = TemplateItineraryItem(
        id: 'i',
        templateId: 't',
        dayNumber: 1,
        orderIndex: 0,
        title: 'X',
        category: 'wat',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );
      expect(item.category, ItineraryItemCategory.activity);
      expect(item.categoryString, 'wat'); // raw preserved
    });

    test('fromJson parses fields and toJson round-trips', () {
      final json = {
        'id': 'i1',
        'template_id': 't1',
        'day_number': 2,
        'order_index': 3,
        'title': 'Hike',
        'description': 'Up the hill',
        'location': 'Manali',
        'location_url': 'http://maps',
        'start_time': '08:00',
        'end_time': '12:00',
        'duration_minutes': 240,
        'category': 'sightseeing',
        'estimated_cost': 1500.50,
        'tips': 'Bring water',
        'created_at': '2026-01-01T00:00:00Z',
      };
      final item = TemplateItineraryItem.fromJson(json);
      expect(item.id, 'i1');
      expect(item.dayNumber, 2);
      expect(item.orderIndex, 3);
      expect(item.title, 'Hike');
      expect(item.location, 'Manali');
      expect(item.startTime, '08:00');
      expect(item.endTime, '12:00');
      expect(item.durationMinutes, 240);
      expect(item.category, ItineraryItemCategory.sightseeing);
      expect(item.estimatedCost, closeTo(1500.5, 0.0001));
      expect(item.tips, 'Bring water');

      final back = item.toJson();
      expect(back['id'], 'i1');
      expect(back['template_id'], 't1');
      expect(back['day_number'], 2);
      expect(back['category'], 'sightseeing');
      expect(back['estimated_cost'], closeTo(1500.5, 0.0001));
    });
  });

  group('TemplateChecklist & TemplateChecklistItem', () {
    test('TemplateChecklist.fromJson parses without items list', () {
      final json = {
        'id': 'cl-1',
        'template_id': 't-1',
        'name': 'Packing',
        'icon': 'luggage',
        'order_index': 1,
        'created_at': '2026-01-01T00:00:00Z',
      };
      final cl = TemplateChecklist.fromJson(json);
      expect(cl.id, 'cl-1');
      expect(cl.name, 'Packing');
      expect(cl.icon, 'luggage');
      expect(cl.orderIndex, 1);
      expect(cl.items, isNull);
    });

    test('TemplateChecklist.fromJson parses with nested items', () {
      final json = {
        'id': 'cl-1',
        'template_id': 't-1',
        'name': 'Pack',
        'order_index': 0,
        'created_at': '2026-01-01T00:00:00Z',
        'items': [
          {
            'id': 'it-1',
            'checklist_id': 'cl-1',
            'content': 'Passport',
            'order_index': 0,
            'is_essential': true,
            'created_at': '2026-01-01T00:00:00Z',
          },
        ],
      };
      final cl = TemplateChecklist.fromJson(json);
      expect(cl.items, hasLength(1));
      expect(cl.items!.first.content, 'Passport');
      expect(cl.items!.first.isEssential, isTrue);
    });

    test('TemplateChecklistItem.toJson emits expected fields', () {
      final item = TemplateChecklistItem(
        id: 'i',
        checklistId: 'cl',
        content: 'Towel',
        orderIndex: 2,
        isEssential: false,
        category: 'misc',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );
      final j = item.toJson();
      expect(j['id'], 'i');
      expect(j['checklist_id'], 'cl');
      expect(j['content'], 'Towel');
      expect(j['order_index'], 2);
      expect(j['is_essential'], isFalse);
      expect(j['category'], 'misc');
    });

    test('default icon for TemplateChecklist is "checklist"', () {
      final json = {
        'id': 'cl',
        'template_id': 't',
        'name': 'X',
        'order_index': 0,
        'created_at': '2026-01-01T00:00:00Z',
      };
      final cl = TemplateChecklist.fromJson(json);
      expect(cl.icon, 'checklist');
    });
  });
}
