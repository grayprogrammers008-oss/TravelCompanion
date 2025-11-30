import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/messaging/domain/entities/message_entity.dart';
import 'package:travel_crew/features/messaging/domain/repositories/message_repository.dart';
import 'package:travel_crew/features/messaging/domain/usecases/delete_message_usecase.dart';

import 'delete_message_usecase_test.mocks.dart';

@GenerateMocks([MessageRepository])
void main() {
  late DeleteMessageUseCase useCase;
  late MockMessageRepository mockRepository;

  setUp(() {
    mockRepository = MockMessageRepository();
    useCase = DeleteMessageUseCase(mockRepository);
  });

  final now = DateTime.now();

  final testMessage = MessageEntity(
    id: 'msg-123',
    tripId: 'trip-123',
    senderId: 'user-123',
    message: 'Hello, world!',
    messageType: MessageType.text,
    reactions: const [],
    readBy: const ['user-123'],
    isDeleted: false,
    createdAt: now,
    updatedAt: now,
    senderName: 'John Doe',
  );

  group('DeleteMessageUseCase', () {
    group('Positive Cases', () {
      test('should delete message successfully when user is sender', () async {
        // Arrange
        when(mockRepository.getMessageById('msg-123'))
            .thenAnswer((_) async => testMessage);
        when(mockRepository.deleteMessage('msg-123')).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, true);
        verify(mockRepository.getMessageById('msg-123')).called(1);
        verify(mockRepository.deleteMessage('msg-123')).called(1);
      });

      test('should delete any message type', () async {
        // Arrange
        final imageMessage = MessageEntity(
          id: 'msg-image',
          tripId: 'trip-123',
          senderId: 'user-123',
          message: null,
          messageType: MessageType.image,
          attachmentUrl: 'https://example.com/image.jpg',
          reactions: const [],
          readBy: const [],
          isDeleted: false,
          createdAt: now,
          updatedAt: now,
        );

        when(mockRepository.getMessageById('msg-image'))
            .thenAnswer((_) async => imageMessage);
        when(mockRepository.deleteMessage('msg-image')).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: 'msg-image',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, true);
      });

      test('should delete message with reactions', () async {
        // Arrange
        final messageWithReactions = MessageEntity(
          id: 'msg-reactions',
          tripId: 'trip-123',
          senderId: 'user-123',
          message: 'Message with reactions',
          messageType: MessageType.text,
          reactions: [
            MessageReaction(emoji: '👍', userId: 'user-456', createdAt: now),
          ],
          readBy: const ['user-123', 'user-456'],
          isDeleted: false,
          createdAt: now,
          updatedAt: now,
        );

        when(mockRepository.getMessageById('msg-reactions'))
            .thenAnswer((_) async => messageWithReactions);
        when(mockRepository.deleteMessage('msg-reactions')).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: 'msg-reactions',
          userId: 'user-123',
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
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Message ID cannot be empty'));
        verifyNever(mockRepository.getMessageById(any));
        verifyNever(mockRepository.deleteMessage(any));
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
        verifyNever(mockRepository.getMessageById(any));
      });
    });

    group('Negative Cases - Permission Errors', () {
      test('should return failure when message not found', () async {
        // Arrange
        when(mockRepository.getMessageById('msg-nonexistent'))
            .thenAnswer((_) async => null);

        // Act
        final result = await useCase.execute(
          messageId: 'msg-nonexistent',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Message not found'));
        verifyNever(mockRepository.deleteMessage(any));
      });

      test('should return failure when user is not the sender', () async {
        // Arrange
        when(mockRepository.getMessageById('msg-123'))
            .thenAnswer((_) async => testMessage);

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-456', // Different user
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('You can only delete your own messages'));
        verifyNever(mockRepository.deleteMessage(any));
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should return failure when getMessageById throws exception', () async {
        // Arrange
        when(mockRepository.getMessageById('msg-123'))
            .thenThrow(Exception('Database error'));

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Failed to delete message'));
      });

      test('should return failure when deleteMessage throws exception', () async {
        // Arrange
        when(mockRepository.getMessageById('msg-123'))
            .thenAnswer((_) async => testMessage);
        when(mockRepository.deleteMessage('msg-123'))
            .thenThrow(Exception('Network error'));

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Failed to delete message'));
      });

      test('should handle timeout error', () async {
        // Arrange
        when(mockRepository.getMessageById('msg-123'))
            .thenThrow(Exception('Request timeout'));

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('timeout'));
      });
    });

    group('Edge Cases', () {
      test('should handle UUID format message ID', () async {
        // Arrange
        const uuidMessageId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        final messageWithUuid = testMessage.copyWith(id: uuidMessageId);

        when(mockRepository.getMessageById(uuidMessageId))
            .thenAnswer((_) async => messageWithUuid);
        when(mockRepository.deleteMessage(uuidMessageId)).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: uuidMessageId,
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, true);
      });

      test('should handle already deleted message', () async {
        // Arrange
        final deletedMessage = testMessage.copyWith(isDeleted: true);

        when(mockRepository.getMessageById('msg-123'))
            .thenAnswer((_) async => deletedMessage);
        when(mockRepository.deleteMessage('msg-123')).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: 'msg-123',
          userId: 'user-123',
        );

        // Assert
        // Should still succeed - idempotent operation
        expect(result.isSuccess, true);
      });

      test('should handle reply message deletion', () async {
        // Arrange
        final replyMessage = MessageEntity(
          id: 'msg-reply',
          tripId: 'trip-123',
          senderId: 'user-123',
          message: 'This is a reply',
          messageType: MessageType.text,
          replyToId: 'msg-original',
          reactions: const [],
          readBy: const [],
          isDeleted: false,
          createdAt: now,
          updatedAt: now,
        );

        when(mockRepository.getMessageById('msg-reply'))
            .thenAnswer((_) async => replyMessage);
        when(mockRepository.deleteMessage('msg-reply')).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: 'msg-reply',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, true);
      });

      test('should handle location message deletion', () async {
        // Arrange
        final locationMessage = MessageEntity(
          id: 'msg-location',
          tripId: 'trip-123',
          senderId: 'user-123',
          message: null,
          messageType: MessageType.location,
          attachmentUrl: 'lat:40.7128,lng:-74.0060',
          reactions: const [],
          readBy: const [],
          isDeleted: false,
          createdAt: now,
          updatedAt: now,
        );

        when(mockRepository.getMessageById('msg-location'))
            .thenAnswer((_) async => locationMessage);
        when(mockRepository.deleteMessage('msg-location')).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: 'msg-location',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, true);
      });

      test('should handle expense link message deletion', () async {
        // Arrange
        final expenseLinkMessage = MessageEntity(
          id: 'msg-expense',
          tripId: 'trip-123',
          senderId: 'user-123',
          message: 'expense-id-123',
          messageType: MessageType.expenseLink,
          reactions: const [],
          readBy: const [],
          isDeleted: false,
          createdAt: now,
          updatedAt: now,
        );

        when(mockRepository.getMessageById('msg-expense'))
            .thenAnswer((_) async => expenseLinkMessage);
        when(mockRepository.deleteMessage('msg-expense')).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute(
          messageId: 'msg-expense',
          userId: 'user-123',
        );

        // Assert
        expect(result.isSuccess, true);
      });
    });
  });
}
