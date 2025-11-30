import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:travel_crew/features/itinerary/domain/usecases/update_itinerary_item_usecase.dart';
import 'package:travel_crew/shared/models/itinerary_model.dart';

import 'update_itinerary_item_usecase_test.mocks.dart';

@GenerateMocks([ItineraryRepository])
void main() {
  late UpdateItineraryItemUseCase useCase;
  late MockItineraryRepository mockRepository;

  setUp(() {
    mockRepository = MockItineraryRepository();
    useCase = UpdateItineraryItemUseCase(mockRepository);
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
    updatedAt: now,
  );

  group('UpdateItineraryItemUseCase', () {
    group('Positive Cases', () {
      test('should update item title', () async {
        // Arrange
        final updatedItem = testItem.copyWith(title: 'Updated Title');
        when(mockRepository.updateItineraryItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          location: anyNamed('location'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          dayNumber: anyNamed('dayNumber'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => updatedItem);

        // Act
        final result = await useCase(
          itemId: 'item-123',
          title: 'Updated Title',
        );

        // Assert
        expect(result.title, 'Updated Title');
        verify(mockRepository.updateItineraryItem(
          itemId: 'item-123',
          title: 'Updated Title',
          description: null,
          location: null,
          startTime: null,
          endTime: null,
          dayNumber: null,
          orderIndex: null,
        )).called(1);
      });

      test('should update item description', () async {
        // Arrange
        final updatedItem = testItem.copyWith(description: 'Updated description');
        when(mockRepository.updateItineraryItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          location: anyNamed('location'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          dayNumber: anyNamed('dayNumber'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => updatedItem);

        // Act
        final result = await useCase(
          itemId: 'item-123',
          description: 'Updated description',
        );

        // Assert
        expect(result.description, 'Updated description');
      });

      test('should update item location', () async {
        // Arrange
        final updatedItem = testItem.copyWith(location: 'New Location');
        when(mockRepository.updateItineraryItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          location: anyNamed('location'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          dayNumber: anyNamed('dayNumber'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => updatedItem);

        // Act
        final result = await useCase(
          itemId: 'item-123',
          location: 'New Location',
        );

        // Assert
        expect(result.location, 'New Location');
      });

      test('should update item times', () async {
        // Arrange
        final newStartTime = now.add(const Duration(hours: 5));
        final newEndTime = now.add(const Duration(hours: 7));
        final updatedItem = testItem.copyWith(
          startTime: newStartTime,
          endTime: newEndTime,
        );
        when(mockRepository.updateItineraryItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          location: anyNamed('location'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          dayNumber: anyNamed('dayNumber'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => updatedItem);

        // Act
        final result = await useCase(
          itemId: 'item-123',
          startTime: newStartTime,
          endTime: newEndTime,
        );

        // Assert
        expect(result.startTime, newStartTime);
        expect(result.endTime, newEndTime);
      });

      test('should update day number', () async {
        // Arrange
        final updatedItem = testItem.copyWith(dayNumber: 2);
        when(mockRepository.updateItineraryItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          location: anyNamed('location'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          dayNumber: anyNamed('dayNumber'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => updatedItem);

        // Act
        final result = await useCase(
          itemId: 'item-123',
          dayNumber: 2,
        );

        // Assert
        expect(result.dayNumber, 2);
      });

      test('should update order index', () async {
        // Arrange
        final updatedItem = testItem.copyWith(orderIndex: 5);
        when(mockRepository.updateItineraryItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          location: anyNamed('location'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          dayNumber: anyNamed('dayNumber'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => updatedItem);

        // Act
        final result = await useCase(
          itemId: 'item-123',
          orderIndex: 5,
        );

        // Assert
        expect(result.orderIndex, 5);
      });

      test('should trim title whitespace', () async {
        // Arrange
        when(mockRepository.updateItineraryItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          location: anyNamed('location'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          dayNumber: anyNamed('dayNumber'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => testItem);

        // Act
        await useCase(
          itemId: 'item-123',
          title: '  Updated Title  ',
        );

        // Assert
        verify(mockRepository.updateItineraryItem(
          itemId: 'item-123',
          title: 'Updated Title',
          description: null,
          location: null,
          startTime: null,
          endTime: null,
          dayNumber: null,
          orderIndex: null,
        )).called(1);
      });

      test('should update multiple fields at once', () async {
        // Arrange
        final updatedItem = testItem.copyWith(
          title: 'New Title',
          description: 'New description',
          location: 'New place',
        );
        when(mockRepository.updateItineraryItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          location: anyNamed('location'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          dayNumber: anyNamed('dayNumber'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => updatedItem);

        // Act
        final result = await useCase(
          itemId: 'item-123',
          title: 'New Title',
          description: 'New description',
          location: 'New place',
        );

        // Assert
        expect(result.title, 'New Title');
        expect(result.description, 'New description');
        expect(result.location, 'New place');
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw exception for empty item ID', () async {
        // Act & Assert
        expect(
          () => useCase(itemId: '', title: 'New Title'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Item ID is required'),
          )),
        );
        verifyNever(mockRepository.updateItineraryItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          location: anyNamed('location'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          dayNumber: anyNamed('dayNumber'),
          orderIndex: anyNamed('orderIndex'),
        ));
      });

      test('should throw exception for whitespace-only item ID', () async {
        // Act & Assert
        expect(
          () => useCase(itemId: '   ', title: 'New Title'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Item ID is required'),
          )),
        );
      });

      test('should throw exception for empty title', () async {
        // Act & Assert
        expect(
          () => useCase(itemId: 'item-123', title: ''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Title cannot be empty'),
          )),
        );
      });

      test('should throw exception for whitespace-only title', () async {
        // Act & Assert
        expect(
          () => useCase(itemId: 'item-123', title: '   '),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Title cannot be empty'),
          )),
        );
      });

      test('should throw exception for title less than 3 characters', () async {
        // Act & Assert
        expect(
          () => useCase(itemId: 'item-123', title: 'AB'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Title must be at least 3 characters'),
          )),
        );
      });

      test('should throw exception when end time is before start time', () async {
        // Arrange
        final startTime = now.add(const Duration(hours: 5));
        final endTime = now.add(const Duration(hours: 3)); // Before start

        // Act & Assert
        expect(
          () => useCase(
            itemId: 'item-123',
            startTime: startTime,
            endTime: endTime,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('End time must be after start time'),
          )),
        );
      });

      test('should throw exception when end time equals start time', () async {
        // Arrange
        final sameTime = now.add(const Duration(hours: 5));

        // Act & Assert
        expect(
          () => useCase(
            itemId: 'item-123',
            startTime: sameTime,
            endTime: sameTime,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('End time must be after start time'),
          )),
        );
      });

      test('should throw exception for non-positive day number', () async {
        // Act & Assert
        expect(
          () => useCase(itemId: 'item-123', dayNumber: 0),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Day number must be positive'),
          )),
        );
      });

      test('should throw exception for negative day number', () async {
        // Act & Assert
        expect(
          () => useCase(itemId: 'item-123', dayNumber: -1),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Day number must be positive'),
          )),
        );
      });

      test('should throw exception for negative order index', () async {
        // Act & Assert
        expect(
          () => useCase(itemId: 'item-123', orderIndex: -1),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Order index cannot be negative'),
          )),
        );
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should wrap repository exception', () async {
        // Arrange
        when(mockRepository.updateItineraryItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          location: anyNamed('location'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          dayNumber: anyNamed('dayNumber'),
          orderIndex: anyNamed('orderIndex'),
        )).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => useCase(itemId: 'item-123', title: 'New Title'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to update itinerary item'),
          )),
        );
      });

      test('should propagate item not found error', () async {
        // Arrange
        when(mockRepository.updateItineraryItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          location: anyNamed('location'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          dayNumber: anyNamed('dayNumber'),
          orderIndex: anyNamed('orderIndex'),
        )).thenThrow(Exception('Item not found'));

        // Act & Assert
        expect(
          () => useCase(itemId: 'non-existent'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should accept title with exactly 3 characters', () async {
        // Arrange
        when(mockRepository.updateItineraryItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          location: anyNamed('location'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          dayNumber: anyNamed('dayNumber'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => testItem);

        // Act & Assert - should not throw
        await useCase(itemId: 'item-123', title: 'ABC');

        verify(mockRepository.updateItineraryItem(
          itemId: 'item-123',
          title: 'ABC',
          description: null,
          location: null,
          startTime: null,
          endTime: null,
          dayNumber: null,
          orderIndex: null,
        )).called(1);
      });

      test('should accept order index of 0', () async {
        // Arrange
        when(mockRepository.updateItineraryItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          location: anyNamed('location'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          dayNumber: anyNamed('dayNumber'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => testItem);

        // Act & Assert - should not throw
        await useCase(itemId: 'item-123', orderIndex: 0);

        verify(mockRepository.updateItineraryItem(
          itemId: 'item-123',
          title: null,
          description: null,
          location: null,
          startTime: null,
          endTime: null,
          dayNumber: null,
          orderIndex: 0,
        )).called(1);
      });

      test('should handle updating only start time', () async {
        // Arrange - only start time, no end time validation needed
        final newStartTime = now.add(const Duration(hours: 10));
        when(mockRepository.updateItineraryItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          location: anyNamed('location'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          dayNumber: anyNamed('dayNumber'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => testItem);

        // Act & Assert - should not throw since only start time
        await useCase(itemId: 'item-123', startTime: newStartTime);

        verify(mockRepository.updateItineraryItem(
          itemId: 'item-123',
          title: null,
          description: null,
          location: null,
          startTime: newStartTime,
          endTime: null,
          dayNumber: null,
          orderIndex: null,
        )).called(1);
      });
    });
  });
}
