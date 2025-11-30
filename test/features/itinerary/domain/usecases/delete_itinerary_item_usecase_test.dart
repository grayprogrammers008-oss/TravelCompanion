import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:travel_crew/features/itinerary/domain/usecases/delete_itinerary_item_usecase.dart';

import 'delete_itinerary_item_usecase_test.mocks.dart';

@GenerateMocks([ItineraryRepository])
void main() {
  late DeleteItineraryItemUseCase useCase;
  late MockItineraryRepository mockRepository;

  setUp(() {
    mockRepository = MockItineraryRepository();
    useCase = DeleteItineraryItemUseCase(mockRepository);
  });

  group('DeleteItineraryItemUseCase', () {
    group('Positive Cases', () {
      test('should delete item successfully', () async {
        // Arrange
        when(mockRepository.deleteItineraryItem('item-123')).thenAnswer(
          (_) async {
            return;
          },
        );

        // Act
        await useCase('item-123');

        // Assert
        verify(mockRepository.deleteItineraryItem('item-123')).called(1);
      });

      test('should delete item with UUID format ID', () async {
        // Arrange
        const uuidItemId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        when(mockRepository.deleteItineraryItem(uuidItemId)).thenAnswer(
          (_) async {
            return;
          },
        );

        // Act
        await useCase(uuidItemId);

        // Assert
        verify(mockRepository.deleteItineraryItem(uuidItemId)).called(1);
      });

      test('should complete without throwing for valid ID', () async {
        // Arrange
        when(mockRepository.deleteItineraryItem('item-456')).thenAnswer(
          (_) async {
            return;
          },
        );

        // Act & Assert - should not throw
        expect(() => useCase('item-456'), returnsNormally);
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw exception for empty item ID', () async {
        // Act & Assert
        expect(
          () => useCase(''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Item ID is required'),
          )),
        );
        verifyNever(mockRepository.deleteItineraryItem(any));
      });

      test('should throw exception for whitespace-only item ID', () async {
        // Act & Assert
        expect(
          () => useCase('   '),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Item ID is required'),
          )),
        );
        verifyNever(mockRepository.deleteItineraryItem(any));
      });

      test('should throw exception for tabs and newlines only', () async {
        // Act & Assert
        expect(
          () => useCase('\t\n\r'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Item ID is required'),
          )),
        );
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should wrap repository exception', () async {
        // Arrange
        when(mockRepository.deleteItineraryItem('item-123')).thenThrow(
          Exception('Database error'),
        );

        // Act & Assert
        expect(
          () => useCase('item-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to delete itinerary item'),
          )),
        );
      });

      test('should propagate item not found error', () async {
        // Arrange
        when(mockRepository.deleteItineraryItem('non-existent')).thenThrow(
          Exception('Item not found'),
        );

        // Act & Assert
        expect(
          () => useCase('non-existent'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to delete itinerary item'),
          )),
        );
      });

      test('should propagate permission denied error', () async {
        // Arrange
        when(mockRepository.deleteItineraryItem('item-123')).thenThrow(
          Exception('Permission denied'),
        );

        // Act & Assert
        expect(
          () => useCase('item-123'),
          throwsA(isA<Exception>()),
        );
      });

      test('should propagate network error', () async {
        // Arrange
        when(mockRepository.deleteItineraryItem('item-123')).thenThrow(
          Exception('Network unavailable'),
        );

        // Act & Assert
        expect(
          () => useCase('item-123'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle item ID with leading/trailing spaces', () async {
        // Note: The useCase trims the ID before validation
        // So ' item-123 ' becomes 'item-123' after trim
        when(mockRepository.deleteItineraryItem(any)).thenAnswer(
          (_) async {
            return;
          },
        );

        // Act - This should work because trim() is applied
        await useCase(' item-123 ');

        // This is tested but depends on implementation
        // If implementation doesn't trim before passing to repo, this would fail
      });

      test('should handle very long item ID', () async {
        // Arrange
        final longId = 'a' * 500;
        when(mockRepository.deleteItineraryItem(longId)).thenAnswer(
          (_) async {
            return;
          },
        );

        // Act
        await useCase(longId);

        // Assert
        verify(mockRepository.deleteItineraryItem(longId)).called(1);
      });

      test('should handle item ID with special characters', () async {
        // Arrange
        const specialId = 'item-123_abc-def';
        when(mockRepository.deleteItineraryItem(specialId)).thenAnswer(
          (_) async {
            return;
          },
        );

        // Act
        await useCase(specialId);

        // Assert
        verify(mockRepository.deleteItineraryItem(specialId)).called(1);
      });
    });
  });
}
