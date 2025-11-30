import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:travel_crew/features/itinerary/domain/usecases/get_itinerary_by_days_usecase.dart';
import 'package:travel_crew/shared/models/itinerary_model.dart';

import 'get_itinerary_by_days_usecase_test.mocks.dart';

@GenerateMocks([ItineraryRepository])
void main() {
  late GetItineraryByDaysUseCase useCase;
  late MockItineraryRepository mockRepository;

  setUp(() {
    mockRepository = MockItineraryRepository();
    useCase = GetItineraryByDaysUseCase(mockRepository);
  });

  final now = DateTime.now();
  final tripStartDate = DateTime(2024, 6, 1);

  final day1Item1 = ItineraryItemModel(
    id: 'item-1',
    tripId: 'trip-123',
    title: 'Day 1 Morning Activity',
    dayNumber: 1,
    orderIndex: 0,
    createdAt: now,
  );

  final day1Item2 = ItineraryItemModel(
    id: 'item-2',
    tripId: 'trip-123',
    title: 'Day 1 Afternoon Activity',
    dayNumber: 1,
    orderIndex: 1,
    createdAt: now,
  );

  final day2Item1 = ItineraryItemModel(
    id: 'item-3',
    tripId: 'trip-123',
    title: 'Day 2 Activity',
    dayNumber: 2,
    orderIndex: 0,
    createdAt: now,
  );

  final day1 = ItineraryDay(
    dayNumber: 1,
    date: tripStartDate,
    items: [day1Item1, day1Item2],
  );

  final day2 = ItineraryDay(
    dayNumber: 2,
    date: tripStartDate.add(const Duration(days: 1)),
    items: [day2Item1],
  );

  group('GetItineraryByDaysUseCase', () {
    group('Positive Cases', () {
      test('should return itinerary grouped by days', () async {
        // Arrange
        when(mockRepository.getItineraryByDays('trip-123')).thenAnswer(
          (_) async => [day1, day2],
        );

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result.length, 2);
        expect(result[0].dayNumber, 1);
        expect(result[1].dayNumber, 2);
        verify(mockRepository.getItineraryByDays('trip-123')).called(1);
      });

      test('should return empty list when trip has no itinerary', () async {
        // Arrange
        when(mockRepository.getItineraryByDays('trip-456')).thenAnswer(
          (_) async => [],
        );

        // Act
        final result = await useCase('trip-456');

        // Assert
        expect(result, isEmpty);
      });

      test('should return days with correct item counts', () async {
        // Arrange
        when(mockRepository.getItineraryByDays('trip-123')).thenAnswer(
          (_) async => [day1, day2],
        );

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result[0].itemCount, 2);
        expect(result[1].itemCount, 1);
      });

      test('should return days with items in correct order', () async {
        // Arrange
        when(mockRepository.getItineraryByDays('trip-123')).thenAnswer(
          (_) async => [day1],
        );

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result[0].items[0].title, 'Day 1 Morning Activity');
        expect(result[0].items[1].title, 'Day 1 Afternoon Activity');
      });

      test('should return days with dates', () async {
        // Arrange
        when(mockRepository.getItineraryByDays('trip-123')).thenAnswer(
          (_) async => [day1, day2],
        );

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result[0].date, tripStartDate);
        expect(result[1].date, tripStartDate.add(const Duration(days: 1)));
      });

      test('should handle single day itinerary', () async {
        // Arrange
        when(mockRepository.getItineraryByDays('trip-123')).thenAnswer(
          (_) async => [day1],
        );

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result.length, 1);
        expect(result[0].dayNumber, 1);
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw exception for empty trip ID', () async {
        // Act & Assert
        expect(
          () => useCase(''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip ID is required'),
          )),
        );
        verifyNever(mockRepository.getItineraryByDays(any));
      });

      test('should throw exception for whitespace-only trip ID', () async {
        // Act & Assert
        expect(
          () => useCase('   '),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip ID is required'),
          )),
        );
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should wrap repository exception', () async {
        // Arrange
        when(mockRepository.getItineraryByDays('trip-123')).thenThrow(
          Exception('Database error'),
        );

        // Act & Assert
        expect(
          () => useCase('trip-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to get itinerary by days'),
          )),
        );
      });

      test('should propagate network error', () async {
        // Arrange
        when(mockRepository.getItineraryByDays('trip-123')).thenThrow(
          Exception('Network unavailable'),
        );

        // Act & Assert
        expect(
          () => useCase('trip-123'),
          throwsA(isA<Exception>()),
        );
      });

      test('should propagate trip not found error', () async {
        // Arrange
        when(mockRepository.getItineraryByDays('non-existent')).thenThrow(
          Exception('Trip not found'),
        );

        // Act & Assert
        expect(
          () => useCase('non-existent'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle UUID format trip ID', () async {
        // Arrange
        const uuidTripId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        when(mockRepository.getItineraryByDays(uuidTripId)).thenAnswer(
          (_) async => [day1],
        );

        // Act
        final result = await useCase(uuidTripId);

        // Assert
        expect(result.length, 1);
      });

      test('should handle many days', () async {
        // Arrange
        final manyDays = List.generate(
          30,
          (i) => ItineraryDay(
            dayNumber: i + 1,
            date: tripStartDate.add(Duration(days: i)),
            items: [
              ItineraryItemModel(
                id: 'item-day${i + 1}',
                tripId: 'trip-123',
                title: 'Day ${i + 1} Activity',
                dayNumber: i + 1,
              ),
            ],
          ),
        );
        when(mockRepository.getItineraryByDays('trip-123')).thenAnswer(
          (_) async => manyDays,
        );

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result.length, 30);
        expect(result.last.dayNumber, 30);
      });

      test('should handle day with many items', () async {
        // Arrange
        final manyItems = List.generate(
          50,
          (i) => ItineraryItemModel(
            id: 'item-$i',
            tripId: 'trip-123',
            title: 'Activity $i',
            dayNumber: 1,
            orderIndex: i,
          ),
        );
        final dayWithManyItems = ItineraryDay(
          dayNumber: 1,
          date: tripStartDate,
          items: manyItems,
        );
        when(mockRepository.getItineraryByDays('trip-123')).thenAnswer(
          (_) async => [dayWithManyItems],
        );

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result[0].itemCount, 50);
      });

      test('should handle day without date', () async {
        // Arrange
        final dayWithoutDate = ItineraryDay(
          dayNumber: 1,
          items: [day1Item1],
        );
        when(mockRepository.getItineraryByDays('trip-123')).thenAnswer(
          (_) async => [dayWithoutDate],
        );

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result[0].date, isNull);
        expect(result[0].dayNumber, 1);
      });

      test('should handle day with empty items list', () async {
        // Arrange
        final emptyDay = ItineraryDay(
          dayNumber: 1,
          date: tripStartDate,
          items: [],
        );
        when(mockRepository.getItineraryByDays('trip-123')).thenAnswer(
          (_) async => [emptyDay],
        );

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result[0].items, isEmpty);
        expect(result[0].itemCount, 0);
      });
    });
  });
}
