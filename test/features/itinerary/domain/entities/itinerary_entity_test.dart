import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_crew/shared/models/itinerary_model.dart';

void main() {
  group('ItineraryEntity type aliases', () {
    test('ItineraryItemEntity is an alias for ItineraryItemModel', () {
      const item = ItineraryItemModel(
        id: 'item-1',
        tripId: 'trip-1',
        title: 'Visit Museum',
      );
      // Since it's a typedef, an instance of one is an instance of the other.
      expect(item, isA<ItineraryItemEntity>());
      expect(item, isA<ItineraryItemModel>());
    });

    test('ItineraryDayEntity is an alias for ItineraryDay', () {
      final day = ItineraryDay(dayNumber: 1, items: const []);
      expect(day, isA<ItineraryDayEntity>());
      expect(day, isA<ItineraryDay>());
    });
  });

  group('ItineraryItemEntityExtension.date / time', () {
    test('date returns startTime when set', () {
      final start = DateTime(2024, 1, 1, 10);
      final item = ItineraryItemModel(
        id: 'i',
        tripId: 't',
        title: 'Visit',
        startTime: start,
      );
      expect(item.date, start);
      expect(item.time, start);
    });

    test('date and time are null when startTime is null', () {
      const item = ItineraryItemModel(
        id: 'i',
        tripId: 't',
        title: 'Visit',
      );
      expect(item.date, isNull);
      expect(item.time, isNull);
    });
  });

  group('ItineraryItemEntityExtension.isScheduled', () {
    test('returns true when startTime is non-null', () {
      final item = ItineraryItemModel(
        id: 'i',
        tripId: 't',
        title: 'Visit',
        startTime: DateTime(2024, 1, 1, 10),
      );
      expect(item.isScheduled, isTrue);
    });

    test('returns false when startTime is null', () {
      const item = ItineraryItemModel(
        id: 'i',
        tripId: 't',
        title: 'Visit',
      );
      expect(item.isScheduled, isFalse);
    });
  });

  group('ItineraryItemEntityExtension.timeRange', () {
    test('returns null when startTime is null', () {
      const item = ItineraryItemModel(
        id: 'i',
        tripId: 't',
        title: 'Visit',
      );
      expect(item.timeRange, isNull);
    });

    test('returns single formatted time when only startTime set', () {
      final item = ItineraryItemModel(
        id: 'i',
        tripId: 't',
        title: 'Visit',
        startTime: DateTime(2024, 1, 1, 9, 30),
      );
      expect(item.timeRange, '9:30 AM');
    });

    test('returns range when both start and end times set', () {
      final item = ItineraryItemModel(
        id: 'i',
        tripId: 't',
        title: 'Visit',
        startTime: DateTime(2024, 1, 1, 9, 0),
        endTime: DateTime(2024, 1, 1, 11, 30),
      );
      expect(item.timeRange, '9:00 AM - 11:30 AM');
    });

    test('formats midnight (00:00) as 12:00 AM', () {
      final item = ItineraryItemModel(
        id: 'i',
        tripId: 't',
        title: 'Visit',
        startTime: DateTime(2024, 1, 1, 0, 0),
      );
      expect(item.timeRange, '12:00 AM');
    });

    test('formats noon (12:00) as 12:00 PM', () {
      final item = ItineraryItemModel(
        id: 'i',
        tripId: 't',
        title: 'Visit',
        startTime: DateTime(2024, 1, 1, 12, 0),
      );
      expect(item.timeRange, '12:00 PM');
    });

    test('formats afternoon hour as PM with 12-hour clock', () {
      final item = ItineraryItemModel(
        id: 'i',
        tripId: 't',
        title: 'Visit',
        startTime: DateTime(2024, 1, 1, 15, 5),
      );
      expect(item.timeRange, '3:05 PM');
    });

    test('pads single-digit minutes with leading zero', () {
      final item = ItineraryItemModel(
        id: 'i',
        tripId: 't',
        title: 'Visit',
        startTime: DateTime(2024, 1, 1, 6, 7),
      );
      expect(item.timeRange, '6:07 AM');
    });

    test('formats end-of-day (23:59) correctly as PM', () {
      final item = ItineraryItemModel(
        id: 'i',
        tripId: 't',
        title: 'Visit',
        startTime: DateTime(2024, 1, 1, 23, 59),
        endTime: DateTime(2024, 1, 1, 23, 59),
      );
      // Range will look the same on both sides
      expect(item.timeRange, '11:59 PM - 11:59 PM');
    });
  });
}
