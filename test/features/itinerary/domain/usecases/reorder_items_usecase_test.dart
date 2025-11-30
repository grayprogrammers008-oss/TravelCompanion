import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:travel_crew/features/itinerary/domain/usecases/reorder_items_usecase.dart';

import 'reorder_items_usecase_test.mocks.dart';

@GenerateMocks([ItineraryRepository])
void main() {
  late ReorderItemsUseCase useCase;
  late MockItineraryRepository mockRepository;

  setUp(() {
    mockRepository = MockItineraryRepository();
    useCase = ReorderItemsUseCase(mockRepository);
  });

  group('ReorderItemsUseCase', () {
    group('Positive Cases', () {
      test('should reorder items successfully', () async {
        // Arrange
        when(mockRepository.reorderItems(
          tripId: anyNamed('tripId'),
          dayNumber: anyNamed('dayNumber'),
          itemIds: anyNamed('itemIds'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        await useCase(
          tripId: 'trip-123',
          dayNumber: 1,
          itemIds: ['item-1', 'item-2', 'item-3'],
        );

        // Assert
        verify(mockRepository.reorderItems(
          tripId: 'trip-123',
          dayNumber: 1,
          itemIds: ['item-1', 'item-2', 'item-3'],
        )).called(1);
      });

      test('should reorder single item', () async {
        // Arrange
        when(mockRepository.reorderItems(
          tripId: anyNamed('tripId'),
          dayNumber: anyNamed('dayNumber'),
          itemIds: anyNamed('itemIds'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        await useCase(
          tripId: 'trip-123',
          dayNumber: 1,
          itemIds: ['item-1'],
        );

        // Assert
        verify(mockRepository.reorderItems(
          tripId: 'trip-123',
          dayNumber: 1,
          itemIds: ['item-1'],
        )).called(1);
      });

      test('should reorder items on different day', () async {
        // Arrange
        when(mockRepository.reorderItems(
          tripId: anyNamed('tripId'),
          dayNumber: anyNamed('dayNumber'),
          itemIds: anyNamed('itemIds'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        await useCase(
          tripId: 'trip-123',
          dayNumber: 5,
          itemIds: ['item-a', 'item-b'],
        );

        // Assert
        verify(mockRepository.reorderItems(
          tripId: 'trip-123',
          dayNumber: 5,
          itemIds: ['item-a', 'item-b'],
        )).called(1);
      });

      test('should reorder many items', () async {
        // Arrange
        final manyItemIds = List.generate(50, (i) => 'item-$i');
        when(mockRepository.reorderItems(
          tripId: anyNamed('tripId'),
          dayNumber: anyNamed('dayNumber'),
          itemIds: anyNamed('itemIds'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        await useCase(
          tripId: 'trip-123',
          dayNumber: 1,
          itemIds: manyItemIds,
        );

        // Assert
        verify(mockRepository.reorderItems(
          tripId: 'trip-123',
          dayNumber: 1,
          itemIds: manyItemIds,
        )).called(1);
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw exception for empty trip ID', () async {
        // Act & Assert
        expect(
          () => useCase(
            tripId: '',
            dayNumber: 1,
            itemIds: ['item-1'],
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip ID is required'),
          )),
        );
        verifyNever(mockRepository.reorderItems(
          tripId: anyNamed('tripId'),
          dayNumber: anyNamed('dayNumber'),
          itemIds: anyNamed('itemIds'),
        ));
      });

      test('should throw exception for whitespace-only trip ID', () async {
        // Act & Assert
        expect(
          () => useCase(
            tripId: '   ',
            dayNumber: 1,
            itemIds: ['item-1'],
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip ID is required'),
          )),
        );
      });

      test('should throw exception for zero day number', () async {
        // Act & Assert
        expect(
          () => useCase(
            tripId: 'trip-123',
            dayNumber: 0,
            itemIds: ['item-1'],
          ),
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
          () => useCase(
            tripId: 'trip-123',
            dayNumber: -1,
            itemIds: ['item-1'],
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Day number must be positive'),
          )),
        );
      });

      test('should throw exception for empty item IDs list', () async {
        // Act & Assert
        expect(
          () => useCase(
            tripId: 'trip-123',
            dayNumber: 1,
            itemIds: [],
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Item IDs cannot be empty'),
          )),
        );
      });

      test('should throw exception when item ID list contains empty string', () async {
        // Act & Assert
        expect(
          () => useCase(
            tripId: 'trip-123',
            dayNumber: 1,
            itemIds: ['item-1', '', 'item-3'],
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Item ID cannot be empty'),
          )),
        );
      });

      test('should throw exception when item ID list contains whitespace-only string', () async {
        // Act & Assert
        expect(
          () => useCase(
            tripId: 'trip-123',
            dayNumber: 1,
            itemIds: ['item-1', '   ', 'item-3'],
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Item ID cannot be empty'),
          )),
        );
      });

      test('should throw exception when first item ID is empty', () async {
        // Act & Assert
        expect(
          () => useCase(
            tripId: 'trip-123',
            dayNumber: 1,
            itemIds: ['', 'item-2', 'item-3'],
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Item ID cannot be empty'),
          )),
        );
      });

      test('should throw exception when last item ID is empty', () async {
        // Act & Assert
        expect(
          () => useCase(
            tripId: 'trip-123',
            dayNumber: 1,
            itemIds: ['item-1', 'item-2', ''],
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Item ID cannot be empty'),
          )),
        );
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should wrap repository exception', () async {
        // Arrange
        when(mockRepository.reorderItems(
          tripId: anyNamed('tripId'),
          dayNumber: anyNamed('dayNumber'),
          itemIds: anyNamed('itemIds'),
        )).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => useCase(
            tripId: 'trip-123',
            dayNumber: 1,
            itemIds: ['item-1'],
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to reorder items'),
          )),
        );
      });

      test('should propagate network error', () async {
        // Arrange
        when(mockRepository.reorderItems(
          tripId: anyNamed('tripId'),
          dayNumber: anyNamed('dayNumber'),
          itemIds: anyNamed('itemIds'),
        )).thenThrow(Exception('Network unavailable'));

        // Act & Assert
        expect(
          () => useCase(
            tripId: 'trip-123',
            dayNumber: 1,
            itemIds: ['item-1'],
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should propagate item not found error', () async {
        // Arrange
        when(mockRepository.reorderItems(
          tripId: anyNamed('tripId'),
          dayNumber: anyNamed('dayNumber'),
          itemIds: anyNamed('itemIds'),
        )).thenThrow(Exception('Item not found'));

        // Act & Assert
        expect(
          () => useCase(
            tripId: 'trip-123',
            dayNumber: 1,
            itemIds: ['non-existent'],
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle UUID format trip ID', () async {
        // Arrange
        const uuidTripId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        when(mockRepository.reorderItems(
          tripId: anyNamed('tripId'),
          dayNumber: anyNamed('dayNumber'),
          itemIds: anyNamed('itemIds'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        await useCase(
          tripId: uuidTripId,
          dayNumber: 1,
          itemIds: ['item-1'],
        );

        // Assert
        verify(mockRepository.reorderItems(
          tripId: uuidTripId,
          dayNumber: 1,
          itemIds: ['item-1'],
        )).called(1);
      });

      test('should handle large day number', () async {
        // Arrange
        when(mockRepository.reorderItems(
          tripId: anyNamed('tripId'),
          dayNumber: anyNamed('dayNumber'),
          itemIds: anyNamed('itemIds'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        await useCase(
          tripId: 'trip-123',
          dayNumber: 365,
          itemIds: ['item-1'],
        );

        // Assert
        verify(mockRepository.reorderItems(
          tripId: 'trip-123',
          dayNumber: 365,
          itemIds: ['item-1'],
        )).called(1);
      });

      test('should handle UUID format item IDs', () async {
        // Arrange
        final uuidItemIds = [
          'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
          'b2c3d4e5-f6a7-8901-bcde-f12345678901',
        ];
        when(mockRepository.reorderItems(
          tripId: anyNamed('tripId'),
          dayNumber: anyNamed('dayNumber'),
          itemIds: anyNamed('itemIds'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        await useCase(
          tripId: 'trip-123',
          dayNumber: 1,
          itemIds: uuidItemIds,
        );

        // Assert
        verify(mockRepository.reorderItems(
          tripId: 'trip-123',
          dayNumber: 1,
          itemIds: uuidItemIds,
        )).called(1);
      });

      test('should accept day number of 1 (boundary)', () async {
        // Arrange
        when(mockRepository.reorderItems(
          tripId: anyNamed('tripId'),
          dayNumber: anyNamed('dayNumber'),
          itemIds: anyNamed('itemIds'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        await useCase(
          tripId: 'trip-123',
          dayNumber: 1,
          itemIds: ['item-1'],
        );

        // Assert
        verify(mockRepository.reorderItems(
          tripId: 'trip-123',
          dayNumber: 1,
          itemIds: ['item-1'],
        )).called(1);
      });
    });
  });
}
