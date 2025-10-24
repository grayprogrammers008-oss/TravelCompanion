import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/messaging/domain/repositories/message_repository.dart';
import 'package:travel_crew/features/messaging/domain/usecases/add_reaction_usecase.dart';

import 'add_reaction_usecase_test.mocks.dart';

@GenerateMocks([MessageRepository])
void main() {
  late AddReactionUseCase useCase;
  late MockMessageRepository mockRepository;

  setUp(() {
    mockRepository = MockMessageRepository();
    useCase = AddReactionUseCase(mockRepository);
  });

  const testMessageId = 'msg-123';
  const testUserId = 'user-456';
  const testEmoji = '👍';

  group('AddReactionUseCase', () {
    test('should add reaction successfully', () async {
      // Arrange
      when(mockRepository.addReaction(
        messageId: testMessageId,
        userId: testUserId,
        emoji: testEmoji,
      )).thenAnswer((_) async => {});

      // Act
      final result = await useCase.execute(
        messageId: testMessageId,
        userId: testUserId,
        emoji: testEmoji,
      );

      // Assert
      expect(result.isSuccess, true);
      verify(mockRepository.addReaction(
        messageId: testMessageId,
        userId: testUserId,
        emoji: testEmoji,
      )).called(1);
    });

    test('should fail when messageId is empty', () async {
      // Act
      final result = await useCase.execute(
        messageId: '',
        userId: testUserId,
        emoji: testEmoji,
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.error, 'Message ID cannot be empty');
      verifyNever(mockRepository.addReaction(
        messageId: any,
        userId: any,
        emoji: any,
      ));
    });

    test('should fail when userId is empty', () async {
      // Act
      final result = await useCase.execute(
        messageId: testMessageId,
        userId: '',
        emoji: testEmoji,
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.error, 'User ID cannot be empty');
      verifyNever(mockRepository.addReaction(
        messageId: any,
        userId: any,
        emoji: any,
      ));
    });

    test('should fail when emoji is empty', () async {
      // Act
      final result = await useCase.execute(
        messageId: testMessageId,
        userId: testUserId,
        emoji: '',
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.error, 'Emoji cannot be empty');
      verifyNever(mockRepository.addReaction(
        messageId: any,
        userId: any,
        emoji: any,
      ));
    });

    test('should handle repository exceptions', () async {
      // Arrange
      when(mockRepository.addReaction(
        messageId: testMessageId,
        userId: testUserId,
        emoji: testEmoji,
      )).thenThrow(Exception('Network error'));

      // Act
      final result = await useCase.execute(
        messageId: testMessageId,
        userId: testUserId,
        emoji: testEmoji,
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.error, contains('Failed to add reaction'));
      expect(result.error, contains('Network error'));
    });

    test('should add different emoji reactions', () async {
      // Arrange
      final emojis = ['❤️', '😂', '😮', '🎉', '🔥'];

      for (final emoji in emojis) {
        when(mockRepository.addReaction(
          messageId: testMessageId,
          userId: testUserId,
          emoji: emoji,
        )).thenAnswer((_) async => {});

        // Act
        final result = await useCase.execute(
          messageId: testMessageId,
          userId: testUserId,
          emoji: emoji,
        );

        // Assert
        expect(result.isSuccess, true);
      }

      // Verify all reactions were added
      verify(mockRepository.addReaction(
        messageId: testMessageId,
        userId: testUserId,
        emoji: anyNamed('emoji'),
      )).called(emojis.length);
    });

    test('should allow same user to add different reactions', () async {
      // Arrange
      when(mockRepository.addReaction(
        messageId: testMessageId,
        userId: testUserId,
        emoji: '👍',
      )).thenAnswer((_) async => {});

      when(mockRepository.addReaction(
        messageId: testMessageId,
        userId: testUserId,
        emoji: '❤️',
      )).thenAnswer((_) async => {});

      // Act
      final result1 = await useCase.execute(
        messageId: testMessageId,
        userId: testUserId,
        emoji: '👍',
      );

      final result2 = await useCase.execute(
        messageId: testMessageId,
        userId: testUserId,
        emoji: '❤️',
      );

      // Assert
      expect(result1.isSuccess, true);
      expect(result2.isSuccess, true);
      verify(mockRepository.addReaction(
        messageId: testMessageId,
        userId: testUserId,
        emoji: anyNamed('emoji'),
      )).called(2);
    });
  });
}
