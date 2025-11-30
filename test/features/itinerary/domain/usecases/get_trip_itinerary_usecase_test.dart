import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:travel_crew/features/itinerary/domain/usecases/get_trip_itinerary_usecase.dart';
import 'package:travel_crew/shared/models/itinerary_model.dart';

import 'get_trip_itinerary_usecase_test.mocks.dart';

@GenerateMocks([ItineraryRepository])
void main() {
  late GetTripItineraryUseCase useCase;
  late MockItineraryRepository mockRepository;

  setUp(() {
    mockRepository = MockItineraryRepository();
    useCase = GetTripItineraryUseCase(mockRepository);
  });

  final now = DateTime.now();

  final testItem = ItineraryItemModel(
    id: 'item-123',
    tripId: 'trip-123',
    title: 'Visit Museum',
    description: 'Morning museum tour',
    location: 'National Museum',
    startTime: now,
    endTime: now.add(const Duration(hours: 2)),
    dayNumber: 1,
    orderIndex: 0,
    createdBy: 'user-123',
    createdAt: now,
    creatorName: 'John Doe',
  );

  final testItem2 = ItineraryItemModel(
    id: 'item-456',
    tripId: 'trip-123',
    title: 'Lunch at Restaurant',
    description: 'Italian restaurant',
    location: 'Downtown',
    startTime: now.add(const Duration(hours: 3)),
    endTime: now.add(const Duration(hours: 4)),
    dayNumber: 1,
    orderIndex: 1,
    createdBy: 'user-123',
    createdAt: now,
  );

  group('GetTripItineraryUseCase', () {
    group('Positive Cases', () {
      test('should return list of itinerary items for trip', () async {
        // Arrange
        when(mockRepository.getTripItinerary('trip-123')).thenAnswer(
          (_) async => [testItem],
        );

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result.length, 1);
        expect(result.first.id, 'item-123');
        expect(result.first.title, 'Visit Museum');
        verify(mockRepository.getTripItinerary('trip-123')).called(1);
      });

      test('should return empty list when trip has no itinerary', () async {
        // Arrange
        when(mockRepository.getTripItinerary('trip-456')).thenAnswer(
          (_) async => [],
        );

        // Act
        final result = await useCase('trip-456');

        // Assert
        expect(result, isEmpty);
        verify(mockRepository.getTripItinerary('trip-456')).called(1);
      });

      test('should return multiple itinerary items', () async {
        // Arrange
        when(mockRepository.getTripItinerary('trip-123')).thenAnswer(
          (_) async => [testItem, testItem2],
        );

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result.length, 2);
        expect(result[0].title, 'Visit Museum');
        expect(result[1].title, 'Lunch at Restaurant');
      });

      test('should return items with all properties', () async {
        // Arrange
        when(mockRepository.getTripItinerary('trip-123')).thenAnswer(
          (_) async => [testItem],
        );

        // Act
        final result = await useCase('trip-123');

        // Assert
        final item = result.first;
        expect(item.id, 'item-123');
        expect(item.tripId, 'trip-123');
        expect(item.title, 'Visit Museum');
        expect(item.description, 'Morning museum tour');
        expect(item.location, 'National Museum');
        expect(item.startTime, isNotNull);
        expect(item.endTime, isNotNull);
        expect(item.dayNumber, 1);
        expect(item.orderIndex, 0);
        expect(item.createdBy, 'user-123');
        expect(item.creatorName, 'John Doe');
      });

      test('should handle items from different days', () async {
        // Arrange
        final day2Item = testItem.copyWith(
          id: 'item-789',
          dayNumber: 2,
          title: 'Day 2 Activity',
        );
        when(mockRepository.getTripItinerary('trip-123')).thenAnswer(
          (_) async => [testItem, day2Item],
        );

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result.length, 2);
        expect(result[0].dayNumber, 1);
        expect(result[1].dayNumber, 2);
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
        verifyNever(mockRepository.getTripItinerary(any));
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
        when(mockRepository.getTripItinerary('trip-123')).thenThrow(
          Exception('Database error'),
        );

        // Act & Assert
        expect(
          () => useCase('trip-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to get trip itinerary'),
          )),
        );
      });

      test('should propagate network error', () async {
        // Arrange
        when(mockRepository.getTripItinerary('trip-123')).thenThrow(
          Exception('Network unavailable'),
        );

        // Act & Assert
        expect(
          () => useCase('trip-123'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle UUID format trip ID', () async {
        // Arrange
        const uuidTripId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        when(mockRepository.getTripItinerary(uuidTripId)).thenAnswer(
          (_) async => [testItem],
        );

        // Act
        final result = await useCase(uuidTripId);

        // Assert
        expect(result.length, 1);
      });

      test('should handle large number of itinerary items', () async {
        // Arrange
        final manyItems = List.generate(
          100,
          (i) => ItineraryItemModel(
            id: 'item-$i',
            tripId: 'trip-123',
            title: 'Activity $i',
            dayNumber: (i ~/ 10) + 1,
            orderIndex: i % 10,
            createdAt: now,
          ),
        );
        when(mockRepository.getTripItinerary('trip-123')).thenAnswer(
          (_) async => manyItems,
        );

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result.length, 100);
      });

      test('should handle items without optional fields', () async {
        // Arrange
        final minimalItem = ItineraryItemModel(
          id: 'item-minimal',
          tripId: 'trip-123',
          title: 'Minimal Item',
        );
        when(mockRepository.getTripItinerary('trip-123')).thenAnswer(
          (_) async => [minimalItem],
        );

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result.first.description, isNull);
        expect(result.first.location, isNull);
        expect(result.first.startTime, isNull);
        expect(result.first.endTime, isNull);
        expect(result.first.dayNumber, isNull);
      });
    });
  });
}
