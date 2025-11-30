import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/messaging/domain/repositories/message_repository.dart';
import 'package:travel_crew/features/messaging/domain/usecases/mark_message_as_read_usecase.dart';

import 'mark_message_as_read_usecase_test.mocks.dart';

@GenerateMocks([MessageRepository])
void main() {
  late MarkMessageAsReadUseCase useCase;
  late MockMessageRepository mockRepository;

  setUp(() {
    mockRepository = MockMessageRepository();
    useCase = MarkMessageAsReadUseCase(mockRepository);
  });

  group('MarkMessageAsReadUseCase', () {
    group('Positive Cases', () {
      test('should mark message as read successfully', () async {
        // Arrange
        when(mockRepository.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, true);
        verify(mockRepository.markMessageAsRead(
          messageId: 'msg-123',
          userId: 'user-123',
        )).called(1);
      });

      test('should mark multiple messages as read sequentially', () async {
        // Arrange
        when(mockRepository.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        final result1 = await useCase.execute(
          messageId: 'msg-1',
          userId: 'user-123',
        );
        final result2 = await useCase.execute(
          messageId: 'msg-2',
          userId: 'user-123',
        );
        final result3 = await useCase.execute(
          messageId: 'msg-3',
          userId: 'user-123',
        );

        // Assert
        expect(result1.isSuccess, true);
        expect(result2.isSuccess, true);
        expect(result3.isSuccess, true);
        verify(mockRepository.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).called(3);
      });

      test('should work with different user IDs', () async {
        // Arrange
        when(mockRepository.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'different-user',
        );

        // Assert
        expect(result.isSuccess, true);
        verify(mockRepository.markMessageAsRead(
          messageId: 'msg-123',
          userId: 'different-user',
        )).called(1);
      });

      test('should handle marking same message as read twice (idempotent)', () async {
        // Arrange
        when(mockRepository.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        final result1 = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
        );
        final result2 = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
        );

        // Assert
        expect(result1.isSuccess, true);
        expect(result2.isSuccess, true);
      });
    });

    group('Negative Cases - Validation', () {
      test('should return failure for empty message ID', () async {
        // Act
        final result = await useCase.execute(
          messageId: '',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Message ID cannot be empty'));
        verifyNever(mockRepository.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        ));
      });

      test('should return failure for empty user ID', () async {
        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: '',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('User ID cannot be empty'));
        verifyNever(mockRepository.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        ));
      });

      test('should return failure for both empty IDs', () async {
        // Act
        final result = await useCase.execute(
          messageId: '',
          userId: '',
        );

        // Assert
        expect(result.isSuccess, false);
        // Should fail on first validation
        expect(result.error, contains('Message ID cannot be empty'));
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should return failure when repository throws exception', () async {
        // Arrange
        when(mockRepository.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('Network error'));

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Failed to mark message as read'));
      });

      test('should handle database error', () async {
        // Arrange
        when(mockRepository.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('Database unavailable'));

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Database unavailable'));
      });

      test('should handle message not found error', () async {
        // Arrange
        when(mockRepository.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('Message not found'));

        // Act
        final result = await useCase.execute(
          messageId: 'nonexistent-msg',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Message not found'));
      });

      test('should handle permission error', () async {
        // Arrange
        when(mockRepository.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('User not authorized'));

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'unauthorized-user',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('User not authorized'));
      });
    });

    group('Edge Cases', () {
      test('should handle UUID format message ID', () async {
        // Arrange
        const uuidMessageId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        when(mockRepository.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: uuidMessageId,
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, true);
        verify(mockRepository.markMessageAsRead(
          messageId: uuidMessageId,
          userId: 'user-123',
        )).called(1);
      });

      test('should handle UUID format user ID', () async {
        // Arrange
        const uuidUserId = 'b2c3d4e5-f6a7-8901-bcde-f12345678901';
        when(mockRepository.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: uuidUserId,
        );

        // Assert
        expect(result.isSuccess, true);
        verify(mockRepository.markMessageAsRead(
          messageId: 'msg-123',
          userId: uuidUserId,
        )).called(1);
      });

      test('should handle special characters in message ID', () async {
        // Arrange
        when(mockRepository.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: 'msg_123_special',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, true);
      });

      test('should handle long message ID', () async {
        // Arrange
        const longMessageId = 'msg-123456789012345678901234567890123456789012345678901234567890';
        when(mockRepository.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: longMessageId,
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, true);
      });
    });
  });
}
