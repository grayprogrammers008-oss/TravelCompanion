import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/messaging/domain/repositories/message_repository.dart';
import 'package:travel_crew/features/messaging/domain/usecases/remove_reaction_usecase.dart';

import 'remove_reaction_usecase_test.mocks.dart';

@GenerateMocks([MessageRepository])
void main() {
  late RemoveReactionUseCase useCase;
  late MockMessageRepository mockRepository;

  setUp(() {
    mockRepository = MockMessageRepository();
    useCase = RemoveReactionUseCase(mockRepository);
  });

  group('RemoveReactionUseCase', () {
    group('Positive Cases', () {
      test('should remove reaction successfully', () async {
        // Arrange
        when(mockRepository.removeReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
          emoji: '👍',
        );

        // Assert
        expect(result.isSuccess, true);
        verify(mockRepository.removeReaction(
          messageId: 'msg-123',
          userId: 'user-123',
          emoji: '👍',
        )).called(1);
      });

      test('should remove different emoji reactions', () async {
        // Arrange
        when(mockRepository.removeReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        )).thenAnswer((_) async {
          return;
        });

        // Act & Assert
        final emojis = ['❤️', '😂', '😢', '🎉', '👏', '🔥', '💯'];
        for (final emoji in emojis) {
          final result = await useCase.execute(
            messageId: 'msg-123',
            userId: 'user-123',
            emoji: emoji,
          );
          expect(result.isSuccess, true);
        }
      });

      test('should remove reaction from different messages', () async {
        // Arrange
        when(mockRepository.removeReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        final result1 = await useCase.execute(
          messageId: 'msg-1',
          userId: 'user-123',
          emoji: '👍',
        );
        final result2 = await useCase.execute(
          messageId: 'msg-2',
          userId: 'user-123',
          emoji: '❤️',
        );

        // Assert
        expect(result1.isSuccess, true);
        expect(result2.isSuccess, true);
      });

      test('should handle removing reaction that does not exist (idempotent)', () async {
        // Arrange
        when(mockRepository.removeReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
          emoji: '👍',
        );

        // Assert
        expect(result.isSuccess, true);
      });
    });

    group('Negative Cases - Validation', () {
      test('should return failure for empty message ID', () async {
        // Act
        final result = await useCase.execute(
          messageId: '',
          userId: 'user-123',
          emoji: '👍',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Message ID cannot be empty'));
        verifyNever(mockRepository.removeReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        ));
      });

      test('should return failure for empty user ID', () async {
        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: '',
          emoji: '👍',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('User ID cannot be empty'));
        verifyNever(mockRepository.removeReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        ));
      });

      test('should return failure for empty emoji', () async {
        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
          emoji: '',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Emoji cannot be empty'));
        verifyNever(mockRepository.removeReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        ));
      });

      test('should return failure when all parameters are empty', () async {
        // Act
        final result = await useCase.execute(
          messageId: '',
          userId: '',
          emoji: '',
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
        when(mockRepository.removeReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        )).thenThrow(Exception('Network error'));

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
          emoji: '👍',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Failed to remove reaction'));
      });

      test('should handle database error', () async {
        // Arrange
        when(mockRepository.removeReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        )).thenThrow(Exception('Database unavailable'));

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
          emoji: '👍',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Database unavailable'));
      });

      test('should handle message not found error', () async {
        // Arrange
        when(mockRepository.removeReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        )).thenThrow(Exception('Message not found'));

        // Act
        final result = await useCase.execute(
          messageId: 'nonexistent-msg',
          userId: 'user-123',
          emoji: '👍',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Message not found'));
      });
    });

    group('Edge Cases', () {
      test('should handle UUID format message ID', () async {
        // Arrange
        const uuidMessageId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        when(mockRepository.removeReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: uuidMessageId,
          userId: 'user-123',
          emoji: '👍',
        );

        // Assert
        expect(result.isSuccess, true);
      });

      test('should handle complex emoji (skin tone modifier)', () async {
        // Arrange
        when(mockRepository.removeReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
          emoji: '👍🏽',
        );

        // Assert
        expect(result.isSuccess, true);
        verify(mockRepository.removeReaction(
          messageId: 'msg-123',
          userId: 'user-123',
          emoji: '👍🏽',
        )).called(1);
      });

      test('should handle compound emoji (family)', () async {
        // Arrange
        when(mockRepository.removeReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
          emoji: '👨‍👩‍👧‍👦',
        );

        // Assert
        expect(result.isSuccess, true);
      });

      test('should handle flag emoji', () async {
        // Arrange
        when(mockRepository.removeReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
          emoji: '🇺🇸',
        );

        // Assert
        expect(result.isSuccess, true);
      });

      test('should handle single character emoji', () async {
        // Arrange
        when(mockRepository.removeReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
          emoji: '😀',
        );

        // Assert
        expect(result.isSuccess, true);
      });

      test('should handle removing multiple reactions from same user', () async {
        // Arrange
        when(mockRepository.removeReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        )).thenAnswer((_) async {
          return;
        });

        // Act
        final result1 = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
          emoji: '👍',
        );
        final result2 = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
          emoji: '❤️',
        );

        // Assert
        expect(result1.isSuccess, true);
        expect(result2.isSuccess, true);
        verify(mockRepository.removeReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        )).called(2);
      });
    });
  });
}
