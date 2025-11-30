import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/messaging/domain/repositories/message_repository.dart';
import 'package:travel_crew/features/messaging/domain/usecases/get_unread_count_usecase.dart';

import 'get_unread_count_usecase_test.mocks.dart';

@GenerateMocks([MessageRepository])
void main() {
  late GetUnreadCountUseCase useCase;
  late MockMessageRepository mockRepository;

  setUp(() {
    mockRepository = MockMessageRepository();
    useCase = GetUnreadCountUseCase(mockRepository);
  });

  group('GetUnreadCountUseCase', () {
    group('Positive Cases', () {
      test('should return unread count successfully', () async {
        // Arrange
        when(mockRepository.getUnreadCount(
          tripId: anyNamed('tripId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => 5);

        // Act
        final result = await useCase.execute(
          tripId: 'trip-123',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, 5);
        verify(mockRepository.getUnreadCount(
          tripId: 'trip-123',
          userId: 'user-123',
        )).called(1);
      });

      test('should return zero when no unread messages', () async {
        // Arrange
        when(mockRepository.getUnreadCount(
          tripId: anyNamed('tripId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => 0);

        // Act
        final result = await useCase.execute(
          tripId: 'trip-123',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, 0);
      });

      test('should return high unread count', () async {
        // Arrange
        when(mockRepository.getUnreadCount(
          tripId: anyNamed('tripId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => 999);

        // Act
        final result = await useCase.execute(
          tripId: 'trip-123',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, 999);
      });

      test('should work with different trip IDs', () async {
        // Arrange
        when(mockRepository.getUnreadCount(
          tripId: anyNamed('tripId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => 10);

        // Act
        final result = await useCase.execute(
          tripId: 'another-trip',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, true);
        verify(mockRepository.getUnreadCount(
          tripId: 'another-trip',
          userId: 'user-123',
        )).called(1);
      });

      test('should work with different user IDs', () async {
        // Arrange
        when(mockRepository.getUnreadCount(
          tripId: anyNamed('tripId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => 3);

        // Act
        final result = await useCase.execute(
          tripId: 'trip-123',
          userId: 'different-user',
        );

        // Assert
        expect(result.isSuccess, true);
        verify(mockRepository.getUnreadCount(
          tripId: 'trip-123',
          userId: 'different-user',
        )).called(1);
      });
    });

    group('Negative Cases - Validation', () {
      test('should return failure for empty trip ID', () async {
        // Act
        final result = await useCase.execute(
          tripId: '',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Trip ID cannot be empty'));
        verifyNever(mockRepository.getUnreadCount(
          tripId: anyNamed('tripId'),
          userId: anyNamed('userId'),
        ));
      });

      test('should return failure for empty user ID', () async {
        // Act
        final result = await useCase.execute(
          tripId: 'trip-123',
          userId: '',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('User ID cannot be empty'));
        verifyNever(mockRepository.getUnreadCount(
          tripId: anyNamed('tripId'),
          userId: anyNamed('userId'),
        ));
      });

      test('should return failure for both empty IDs', () async {
        // Act
        final result = await useCase.execute(
          tripId: '',
          userId: '',
        );

        // Assert
        expect(result.isSuccess, false);
        // Should fail on first validation
        expect(result.error, contains('Trip ID cannot be empty'));
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should return failure when repository throws exception', () async {
        // Arrange
        when(mockRepository.getUnreadCount(
          tripId: anyNamed('tripId'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('Network error'));

        // Act
        final result = await useCase.execute(
          tripId: 'trip-123',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Failed to get unread count'));
      });

      test('should handle database error', () async {
        // Arrange
        when(mockRepository.getUnreadCount(
          tripId: anyNamed('tripId'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('Database unavailable'));

        // Act
        final result = await useCase.execute(
          tripId: 'trip-123',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Database unavailable'));
      });

      test('should handle authentication error', () async {
        // Arrange
        when(mockRepository.getUnreadCount(
          tripId: anyNamed('tripId'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('User not authenticated'));

        // Act
        final result = await useCase.execute(
          tripId: 'trip-123',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('User not authenticated'));
      });
    });

    group('Edge Cases', () {
      test('should handle UUID format trip ID', () async {
        // Arrange
        const uuidTripId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        when(mockRepository.getUnreadCount(
          tripId: anyNamed('tripId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => 1);

        // Act
        final result = await useCase.execute(
          tripId: uuidTripId,
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, true);
        verify(mockRepository.getUnreadCount(
          tripId: uuidTripId,
          userId: 'user-123',
        )).called(1);
      });

      test('should handle UUID format user ID', () async {
        // Arrange
        const uuidUserId = 'b2c3d4e5-f6a7-8901-bcde-f12345678901';
        when(mockRepository.getUnreadCount(
          tripId: anyNamed('tripId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => 2);

        // Act
        final result = await useCase.execute(
          tripId: 'trip-123',
          userId: uuidUserId,
        );

        // Assert
        expect(result.isSuccess, true);
        verify(mockRepository.getUnreadCount(
          tripId: 'trip-123',
          userId: uuidUserId,
        )).called(1);
      });

      test('should handle very large unread count', () async {
        // Arrange
        when(mockRepository.getUnreadCount(
          tripId: anyNamed('tripId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => 100000);

        // Act
        final result = await useCase.execute(
          tripId: 'trip-123',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, 100000);
      });

      test('should handle special characters in IDs', () async {
        // Arrange
        when(mockRepository.getUnreadCount(
          tripId: anyNamed('tripId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => 5);

        // Act
        final result = await useCase.execute(
          tripId: 'trip_123_test',
          userId: 'user_123_test',
        );

        // Assert
        expect(result.isSuccess, true);
      });
    });
  });
}
