import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/messaging/domain/entities/message_entity.dart';
import 'package:travel_crew/features/messaging/domain/repositories/message_repository.dart';
import 'package:travel_crew/features/messaging/domain/usecases/send_message_usecase.dart';
import 'package:travel_crew/features/messaging/domain/usecases/add_reaction_usecase.dart';
import 'package:travel_crew/features/messaging/domain/usecases/remove_reaction_usecase.dart';
import 'package:travel_crew/features/messaging/domain/usecases/delete_message_usecase.dart';

import 'messaging_flow_integration_test.mocks.dart';

@GenerateMocks([MessageRepository])
void main() {
  group('Messaging Flow Integration Tests', () {
    late MockMessageRepository mockRepository;
    late SendMessageUseCase sendMessageUseCase;
    late AddReactionUseCase addReactionUseCase;
    late RemoveReactionUseCase removeReactionUseCase;
    late DeleteMessageUseCase deleteMessageUseCase;

    setUp(() {
      mockRepository = MockMessageRepository();
      sendMessageUseCase = SendMessageUseCase(mockRepository);
      addReactionUseCase = AddReactionUseCase(mockRepository);
      removeReactionUseCase = RemoveReactionUseCase(mockRepository);
      deleteMessageUseCase = DeleteMessageUseCase(mockRepository);
    });

    final testDate = DateTime(2025, 1, 24, 10, 30);

    test('Complete messaging flow: send, react, reply, delete', () async {
      // ==========================================
      // STEP 1: Send initial message
      // ==========================================
      const tripId = 'trip-123';
      const senderId = 'user-alice';
      const messageText = 'Hello everyone!';

      final sentMessage = MessageEntity(
        id: 'msg-001',
        tripId: tripId,
        senderId: senderId,
        message: messageText,
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [senderId],
        createdAt: testDate,
        updatedAt: testDate,
      );

      when(mockRepository.sendMessage(
        tripId: tripId,
        senderId: senderId,
        message: messageText,
        messageType: MessageType.text,
        replyToId: null,
        attachmentUrl: null,
      )).thenAnswer((_) async => sentMessage);

      final sendResult = await sendMessageUseCase.execute(
        tripId: tripId,
        senderId: senderId,
        message: messageText,
        messageType: MessageType.text,
      );

      expect(sendResult.isSuccess, true);
      expect(sendResult.data?.message, messageText);
      expect(sendResult.data?.reactions, isEmpty);

      // ==========================================
      // STEP 2: Add reaction to message
      // ==========================================
      const reactorId = 'user-bob';
      const emoji = '👍';

      when(mockRepository.addReaction(
        messageId: 'msg-001',
        userId: reactorId,
        emoji: emoji,
      )).thenAnswer((_) async => {});

      final addReactionResult = await addReactionUseCase.execute(
        messageId: 'msg-001',
        userId: reactorId,
        emoji: emoji,
      );

      expect(addReactionResult.isSuccess, true);
      verify(mockRepository.addReaction(
        messageId: 'msg-001',
        userId: reactorId,
        emoji: emoji,
      )).called(1);

      // ==========================================
      // STEP 3: Reply to the message
      // ==========================================
      const replyText = 'Thanks for the message!';
      final replyMessage = MessageEntity(
        id: 'msg-002',
        tripId: tripId,
        senderId: reactorId,
        message: replyText,
        messageType: MessageType.text,
        replyToId: 'msg-001',
        reactions: const [],
        readBy: const [reactorId],
        createdAt: testDate.add(const Duration(minutes: 1)),
        updatedAt: testDate.add(const Duration(minutes: 1)),
      );

      when(mockRepository.sendMessage(
        tripId: tripId,
        senderId: reactorId,
        message: replyText,
        messageType: MessageType.text,
        replyToId: 'msg-001',
        attachmentUrl: null,
      )).thenAnswer((_) async => replyMessage);

      final replyResult = await sendMessageUseCase.execute(
        tripId: tripId,
        senderId: reactorId,
        message: replyText,
        messageType: MessageType.text,
        replyToId: 'msg-001',
      );

      expect(replyResult.isSuccess, true);
      expect(replyResult.data?.replyToId, 'msg-001');
      expect(replyResult.data?.message, replyText);

      // ==========================================
      // STEP 4: Remove reaction
      // ==========================================
      when(mockRepository.removeReaction(
        messageId: 'msg-001',
        userId: reactorId,
        emoji: emoji,
      )).thenAnswer((_) async => {});

      final removeReactionResult = await removeReactionUseCase.execute(
        messageId: 'msg-001',
        userId: reactorId,
        emoji: emoji,
      );

      expect(removeReactionResult.isSuccess, true);
      verify(mockRepository.removeReaction(
        messageId: 'msg-001',
        userId: reactorId,
        emoji: emoji,
      )).called(1);

      // ==========================================
      // STEP 5: Delete message
      // ==========================================
      when(mockRepository.deleteMessage(
        messageId: 'msg-001',
        userId: senderId,
      )).thenAnswer((_) async => {});

      final deleteResult = await deleteMessageUseCase.execute(
        messageId: 'msg-001',
        userId: senderId,
      );

      expect(deleteResult.isSuccess, true);
      verify(mockRepository.deleteMessage(
        messageId: 'msg-001',
        userId: senderId,
      )).called(1);

      // ==========================================
      // Verify all interactions
      // ==========================================
      verifyInOrder([
        mockRepository.sendMessage(
          tripId: tripId,
          senderId: senderId,
          message: messageText,
          messageType: MessageType.text,
          replyToId: null,
          attachmentUrl: null,
        ),
        mockRepository.addReaction(
          messageId: 'msg-001',
          userId: reactorId,
          emoji: emoji,
        ),
        mockRepository.sendMessage(
          tripId: tripId,
          senderId: reactorId,
          message: replyText,
          messageType: MessageType.text,
          replyToId: 'msg-001',
          attachmentUrl: null,
        ),
        mockRepository.removeReaction(
          messageId: 'msg-001',
          userId: reactorId,
          emoji: emoji,
        ),
        mockRepository.deleteMessage(
          messageId: 'msg-001',
          userId: senderId,
        ),
      ]);
    });

    test('Image message flow: send image, react, view', () async {
      // ==========================================
      // Send image message
      // ==========================================
      const tripId = 'trip-123';
      const senderId = 'user-alice';
      const imageUrl = 'https://example.com/image.jpg';
      const caption = 'Check out this photo!';

      final imageMessage = MessageEntity(
        id: 'msg-003',
        tripId: tripId,
        senderId: senderId,
        message: caption,
        messageType: MessageType.image,
        attachmentUrl: imageUrl,
        reactions: const [],
        readBy: const [senderId],
        createdAt: testDate,
        updatedAt: testDate,
      );

      when(mockRepository.sendMessage(
        tripId: tripId,
        senderId: senderId,
        message: caption,
        messageType: MessageType.image,
        replyToId: null,
        attachmentUrl: imageUrl,
      )).thenAnswer((_) async => imageMessage);

      final result = await sendMessageUseCase.execute(
        tripId: tripId,
        senderId: senderId,
        message: caption,
        messageType: MessageType.image,
        attachmentUrl: imageUrl,
      );

      expect(result.isSuccess, true);
      expect(result.data?.messageType, MessageType.image);
      expect(result.data?.attachmentUrl, imageUrl);
      expect(result.data?.message, caption);

      // ==========================================
      // Add multiple reactions
      // ==========================================
      final reactions = ['😍', '🔥', '👏'];
      const reactorId = 'user-bob';

      for (final emoji in reactions) {
        when(mockRepository.addReaction(
          messageId: 'msg-003',
          userId: reactorId,
          emoji: emoji,
        )).thenAnswer((_) async => {});

        final reactionResult = await addReactionUseCase.execute(
          messageId: 'msg-003',
          userId: reactorId,
          emoji: emoji,
        );

        expect(reactionResult.isSuccess, true);
      }

      verify(mockRepository.addReaction(
        messageId: 'msg-003',
        userId: reactorId,
        emoji: anyNamed('emoji'),
      )).called(reactions.length);
    });

    test('Error handling flow: network failures and validation', () async {
      // ==========================================
      // Test validation errors
      // ==========================================
      final emptyTripResult = await sendMessageUseCase.execute(
        tripId: '',
        senderId: 'user-123',
        message: 'Test',
        messageType: MessageType.text,
      );
      expect(emptyTripResult.isSuccess, false);
      expect(emptyTripResult.error, contains('Trip ID'));

      final emptyMessageResult = await sendMessageUseCase.execute(
        tripId: 'trip-123',
        senderId: 'user-123',
        message: '',
        messageType: MessageType.text,
      );
      expect(emptyMessageResult.isSuccess, false);
      expect(emptyMessageResult.error, contains('Message text'));

      // ==========================================
      // Test network errors
      // ==========================================
      when(mockRepository.sendMessage(
        tripId: any,
        senderId: any,
        message: any,
        messageType: any,
      )).thenThrow(Exception('Network timeout'));

      final networkErrorResult = await sendMessageUseCase.execute(
        tripId: 'trip-123',
        senderId: 'user-123',
        message: 'Test',
        messageType: MessageType.text,
      );

      expect(networkErrorResult.isSuccess, false);
      expect(networkErrorResult.error, contains('Failed to send message'));
      expect(networkErrorResult.error, contains('Network timeout'));

      // ==========================================
      // Test reaction errors
      // ==========================================
      when(mockRepository.addReaction(
        messageId: any,
        userId: any,
        emoji: any,
      )).thenThrow(Exception('Message not found'));

      final reactionErrorResult = await addReactionUseCase.execute(
        messageId: 'msg-999',
        userId: 'user-123',
        emoji: '👍',
      );

      expect(reactionErrorResult.isSuccess, false);
      expect(reactionErrorResult.error, contains('Failed to add reaction'));
    });

    test('Multi-user conversation flow', () async {
      const tripId = 'trip-123';
      const user1 = 'user-alice';
      const user2 = 'user-bob';
      const user3 = 'user-charlie';

      // User 1 sends message
      when(mockRepository.sendMessage(
        tripId: tripId,
        senderId: user1,
        message: any,
        messageType: MessageType.text,
      )).thenAnswer((_) async => MessageEntity(
            id: 'msg-001',
            tripId: tripId,
            senderId: user1,
            message: 'Hello team!',
            messageType: MessageType.text,
            reactions: const [],
            readBy: const [user1],
            createdAt: testDate,
            updatedAt: testDate,
          ));

      await sendMessageUseCase.execute(
        tripId: tripId,
        senderId: user1,
        message: 'Hello team!',
        messageType: MessageType.text,
      );

      // User 2 reacts
      when(mockRepository.addReaction(
        messageId: 'msg-001',
        userId: user2,
        emoji: '👋',
      )).thenAnswer((_) async => {});

      await addReactionUseCase.execute(
        messageId: 'msg-001',
        userId: user2,
        emoji: '👋',
      );

      // User 3 also reacts
      when(mockRepository.addReaction(
        messageId: 'msg-001',
        userId: user3,
        emoji: '👋',
      )).thenAnswer((_) async => {});

      await addReactionUseCase.execute(
        messageId: 'msg-001',
        userId: user3,
        emoji: '👋',
      );

      // User 2 replies
      when(mockRepository.sendMessage(
        tripId: tripId,
        senderId: user2,
        message: 'Hey! Ready for the trip?',
        messageType: MessageType.text,
        replyToId: 'msg-001',
        attachmentUrl: null,
      )).thenAnswer((_) async => MessageEntity(
            id: 'msg-002',
            tripId: tripId,
            senderId: user2,
            message: 'Hey! Ready for the trip?',
            messageType: MessageType.text,
            replyToId: 'msg-001',
            reactions: const [],
            readBy: const [user2],
            createdAt: testDate.add(const Duration(minutes: 1)),
            updatedAt: testDate.add(const Duration(minutes: 1)),
          ));

      await sendMessageUseCase.execute(
        tripId: tripId,
        senderId: user2,
        message: 'Hey! Ready for the trip?',
        messageType: MessageType.text,
        replyToId: 'msg-001',
      );

      // Verify all actions occurred
      verify(mockRepository.sendMessage(
        tripId: tripId,
        senderId: user1,
        message: 'Hello team!',
        messageType: MessageType.text,
      )).called(1);

      verify(mockRepository.addReaction(
        messageId: 'msg-001',
        userId: anyNamed('userId'),
        emoji: '👋',
      )).called(2);

      verify(mockRepository.sendMessage(
        tripId: tripId,
        senderId: user2,
        message: 'Hey! Ready for the trip?',
        messageType: MessageType.text,
        replyToId: 'msg-001',
        attachmentUrl: null,
      )).called(1);
    });
  });
}
