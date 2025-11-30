import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/shared/models/itinerary_model.dart';

void main() {
  group('ItineraryItemModel', () {
    final now = DateTime.now();
    final startTime = DateTime(2024, 1, 15, 9, 0);
    final endTime = DateTime(2024, 1, 15, 12, 0);

    group('constructor', () {
      test('should create instance with required fields', () {
        const item = ItineraryItemModel(
          id: 'item-1',
          tripId: 'trip-1',
          title: 'Visit Museum',
        );

        expect(item.id, 'item-1');
        expect(item.tripId, 'trip-1');
        expect(item.title, 'Visit Museum');
        expect(item.description, isNull);
        expect(item.location, isNull);
        expect(item.startTime, isNull);
        expect(item.endTime, isNull);
        expect(item.dayNumber, isNull);
        expect(item.orderIndex, 0);
        expect(item.createdBy, isNull);
        expect(item.createdAt, isNull);
        expect(item.updatedAt, isNull);
        expect(item.creatorName, isNull);
      });

      test('should create instance with all fields', () {
        final item = ItineraryItemModel(
          id: 'item-1',
          tripId: 'trip-1',
          title: 'Visit Museum',
          description: 'See the art exhibits',
          location: 'National Museum',
          startTime: startTime,
          endTime: endTime,
          dayNumber: 1,
          orderIndex: 5,
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
          creatorName: 'John Doe',
        );

        expect(item.id, 'item-1');
        expect(item.tripId, 'trip-1');
        expect(item.title, 'Visit Museum');
        expect(item.description, 'See the art exhibits');
        expect(item.location, 'National Museum');
        expect(item.startTime, startTime);
        expect(item.endTime, endTime);
        expect(item.dayNumber, 1);
        expect(item.orderIndex, 5);
        expect(item.createdBy, 'user-1');
        expect(item.createdAt, now);
        expect(item.updatedAt, now);
        expect(item.creatorName, 'John Doe');
      });
    });

    group('fromJson', () {
      test('should parse valid JSON with all fields', () {
        final json = {
          'id': 'item-1',
          'trip_id': 'trip-1',
          'title': 'Visit Museum',
          'description': 'See the art exhibits',
          'location': 'National Museum',
          'start_time': '2024-01-15T09:00:00.000Z',
          'end_time': '2024-01-15T12:00:00.000Z',
          'day_number': 1,
          'order_index': 5,
          'created_by': 'user-1',
          'created_at': '2024-01-15T10:30:00.000Z',
          'updated_at': '2024-01-16T10:30:00.000Z',
          'creator_name': 'John Doe',
        };

        final item = ItineraryItemModel.fromJson(json);

        expect(item.id, 'item-1');
        expect(item.tripId, 'trip-1');
        expect(item.title, 'Visit Museum');
        expect(item.description, 'See the art exhibits');
        expect(item.location, 'National Museum');
        expect(item.startTime, DateTime.parse('2024-01-15T09:00:00.000Z'));
        expect(item.endTime, DateTime.parse('2024-01-15T12:00:00.000Z'));
        expect(item.dayNumber, 1);
        expect(item.orderIndex, 5);
        expect(item.createdBy, 'user-1');
        expect(item.createdAt, DateTime.parse('2024-01-15T10:30:00.000Z'));
        expect(item.updatedAt, DateTime.parse('2024-01-16T10:30:00.000Z'));
        expect(item.creatorName, 'John Doe');
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'item-1',
          'trip_id': 'trip-1',
          'title': 'Visit Museum',
          'description': null,
          'location': null,
          'start_time': null,
          'end_time': null,
          'day_number': null,
          'order_index': null,
          'created_by': null,
          'created_at': null,
          'updated_at': null,
          'creator_name': null,
        };

        final item = ItineraryItemModel.fromJson(json);

        expect(item.id, 'item-1');
        expect(item.tripId, 'trip-1');
        expect(item.title, 'Visit Museum');
        expect(item.description, isNull);
        expect(item.location, isNull);
        expect(item.startTime, isNull);
        expect(item.endTime, isNull);
        expect(item.dayNumber, isNull);
        expect(item.orderIndex, 0);
        expect(item.createdBy, isNull);
        expect(item.createdAt, isNull);
        expect(item.updatedAt, isNull);
        expect(item.creatorName, isNull);
      });

      test('should handle missing order_index with default 0', () {
        final json = {
          'id': 'item-1',
          'trip_id': 'trip-1',
          'title': 'Visit Museum',
        };

        final item = ItineraryItemModel.fromJson(json);

        expect(item.orderIndex, 0);
      });
    });

    group('toJson', () {
      test('should convert to JSON with all fields', () {
        final item = ItineraryItemModel(
          id: 'item-1',
          tripId: 'trip-1',
          title: 'Visit Museum',
          description: 'See the art exhibits',
          location: 'National Museum',
          startTime: DateTime.parse('2024-01-15T09:00:00.000Z'),
          endTime: DateTime.parse('2024-01-15T12:00:00.000Z'),
          dayNumber: 1,
          orderIndex: 5,
          createdBy: 'user-1',
          createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
          updatedAt: DateTime.parse('2024-01-16T10:30:00.000Z'),
          creatorName: 'John Doe',
        );

        final json = item.toJson();

        expect(json['id'], 'item-1');
        expect(json['trip_id'], 'trip-1');
        expect(json['title'], 'Visit Museum');
        expect(json['description'], 'See the art exhibits');
        expect(json['location'], 'National Museum');
        expect(json['start_time'], '2024-01-15T09:00:00.000Z');
        expect(json['end_time'], '2024-01-15T12:00:00.000Z');
        expect(json['day_number'], 1);
        expect(json['order_index'], 5);
        expect(json['created_by'], 'user-1');
        expect(json['created_at'], '2024-01-15T10:30:00.000Z');
        expect(json['updated_at'], '2024-01-16T10:30:00.000Z');
        expect(json['creator_name'], 'John Doe');
      });

      test('should handle null optional fields', () {
        const item = ItineraryItemModel(
          id: 'item-1',
          tripId: 'trip-1',
          title: 'Visit Museum',
        );

        final json = item.toJson();

        expect(json['id'], 'item-1');
        expect(json['trip_id'], 'trip-1');
        expect(json['title'], 'Visit Museum');
        expect(json['description'], isNull);
        expect(json['location'], isNull);
        expect(json['start_time'], isNull);
        expect(json['end_time'], isNull);
        expect(json['day_number'], isNull);
        expect(json['order_index'], 0);
        expect(json['created_by'], isNull);
        expect(json['created_at'], isNull);
        expect(json['updated_at'], isNull);
        expect(json['creator_name'], isNull);
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        final original = ItineraryItemModel(
          id: 'item-1',
          tripId: 'trip-1',
          title: 'Visit Museum',
          description: 'See the art exhibits',
          location: 'National Museum',
          startTime: startTime,
          endTime: endTime,
          dayNumber: 1,
          orderIndex: 5,
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
          creatorName: 'John Doe',
        );

        final copied = original.copyWith(
          title: 'Visit Gallery',
          location: 'Art Gallery',
          dayNumber: 2,
        );

        expect(copied.id, 'item-1');
        expect(copied.tripId, 'trip-1');
        expect(copied.title, 'Visit Gallery');
        expect(copied.description, 'See the art exhibits');
        expect(copied.location, 'Art Gallery');
        expect(copied.startTime, startTime);
        expect(copied.endTime, endTime);
        expect(copied.dayNumber, 2);
        expect(copied.orderIndex, 5);
        expect(copied.createdBy, 'user-1');
        expect(copied.createdAt, now);
        expect(copied.updatedAt, now);
        expect(copied.creatorName, 'John Doe');
      });

      test('should keep original values when not specified', () {
        final original = ItineraryItemModel(
          id: 'item-1',
          tripId: 'trip-1',
          title: 'Visit Museum',
          description: 'See the art exhibits',
          location: 'National Museum',
          startTime: startTime,
          endTime: endTime,
          dayNumber: 1,
          orderIndex: 5,
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
          creatorName: 'John Doe',
        );

        final copied = original.copyWith();

        expect(copied, original);
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        final item1 = ItineraryItemModel(
          id: 'item-1',
          tripId: 'trip-1',
          title: 'Visit Museum',
          description: 'See the art exhibits',
          location: 'National Museum',
          startTime: startTime,
          endTime: endTime,
          dayNumber: 1,
          orderIndex: 5,
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
          creatorName: 'John Doe',
        );

        final item2 = ItineraryItemModel(
          id: 'item-1',
          tripId: 'trip-1',
          title: 'Visit Museum',
          description: 'See the art exhibits',
          location: 'National Museum',
          startTime: startTime,
          endTime: endTime,
          dayNumber: 1,
          orderIndex: 5,
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
          creatorName: 'John Doe',
        );

        expect(item1, item2);
        expect(item1.hashCode, item2.hashCode);
      });

      test('should not be equal when different values', () {
        final item1 = ItineraryItemModel(
          id: 'item-1',
          tripId: 'trip-1',
          title: 'Visit Museum',
        );

        final item2 = ItineraryItemModel(
          id: 'item-2',
          tripId: 'trip-1',
          title: 'Visit Museum',
        );

        expect(item1, isNot(item2));
      });

      test('should be identical to itself', () {
        final item = ItineraryItemModel(
          id: 'item-1',
          tripId: 'trip-1',
          title: 'Visit Museum',
        );

        expect(item == item, true);
      });
    });

    group('toString', () {
      test('should return string representation', () {
        const item = ItineraryItemModel(
          id: 'item-1',
          tripId: 'trip-1',
          title: 'Visit Museum',
        );

        final str = item.toString();

        expect(str, contains('ItineraryItemModel'));
        expect(str, contains('item-1'));
        expect(str, contains('Visit Museum'));
      });
    });
  });

  group('ItineraryDay', () {
    final date = DateTime(2024, 1, 15);
    final items = [
      const ItineraryItemModel(
        id: 'item-1',
        tripId: 'trip-1',
        title: 'Visit Museum',
        dayNumber: 1,
        orderIndex: 0,
      ),
      const ItineraryItemModel(
        id: 'item-2',
        tripId: 'trip-1',
        title: 'Lunch',
        dayNumber: 1,
        orderIndex: 1,
      ),
    ];

    group('constructor', () {
      test('should create instance with required fields', () {
        final day = ItineraryDay(
          dayNumber: 1,
          items: items,
        );

        expect(day.dayNumber, 1);
        expect(day.date, isNull);
        expect(day.items, items);
      });

      test('should create instance with all fields', () {
        final day = ItineraryDay(
          dayNumber: 1,
          date: date,
          items: items,
        );

        expect(day.dayNumber, 1);
        expect(day.date, date);
        expect(day.items, items);
      });
    });

    group('itemCount', () {
      test('should return correct count', () {
        final day = ItineraryDay(
          dayNumber: 1,
          date: date,
          items: items,
        );

        expect(day.itemCount, 2);
      });

      test('should return 0 for empty items', () {
        final day = ItineraryDay(
          dayNumber: 1,
          date: date,
          items: const [],
        );

        expect(day.itemCount, 0);
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        final day1 = ItineraryDay(
          dayNumber: 1,
          date: date,
          items: items,
        );

        final day2 = ItineraryDay(
          dayNumber: 1,
          date: date,
          items: items,
        );

        expect(day1, day2);
        expect(day1.hashCode, day2.hashCode);
      });

      test('should not be equal when different dayNumber', () {
        final day1 = ItineraryDay(
          dayNumber: 1,
          date: date,
          items: items,
        );

        final day2 = ItineraryDay(
          dayNumber: 2,
          date: date,
          items: items,
        );

        expect(day1, isNot(day2));
      });

      test('should not be equal when different date', () {
        final day1 = ItineraryDay(
          dayNumber: 1,
          date: date,
          items: items,
        );

        final day2 = ItineraryDay(
          dayNumber: 1,
          date: date.add(const Duration(days: 1)),
          items: items,
        );

        expect(day1, isNot(day2));
      });

      test('should not be equal when different items', () {
        final day1 = ItineraryDay(
          dayNumber: 1,
          date: date,
          items: items,
        );

        final differentItems = [
          const ItineraryItemModel(
            id: 'item-3',
            tripId: 'trip-1',
            title: 'Different activity',
            dayNumber: 1,
            orderIndex: 0,
          ),
        ];

        final day2 = ItineraryDay(
          dayNumber: 1,
          date: date,
          items: differentItems,
        );

        expect(day1, isNot(day2));
      });

      test('should be identical to itself', () {
        final day = ItineraryDay(
          dayNumber: 1,
          date: date,
          items: items,
        );

        expect(day == day, true);
      });

      test('should handle null date comparison', () {
        final day1 = ItineraryDay(
          dayNumber: 1,
          date: null,
          items: items,
        );

        final day2 = ItineraryDay(
          dayNumber: 1,
          date: null,
          items: items,
        );

        expect(day1, day2);
      });

      test('should not be equal when one date is null and other is not', () {
        final day1 = ItineraryDay(
          dayNumber: 1,
          date: null,
          items: items,
        );

        final day2 = ItineraryDay(
          dayNumber: 1,
          date: date,
          items: items,
        );

        expect(day1, isNot(day2));
      });
    });

    group('toString', () {
      test('should return string representation', () {
        final day = ItineraryDay(
          dayNumber: 1,
          date: date,
          items: items,
        );

        final str = day.toString();

        expect(str, contains('ItineraryDay'));
        expect(str, contains('dayNumber: 1'));
      });
    });
  });
}
