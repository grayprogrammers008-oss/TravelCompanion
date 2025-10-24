import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/messaging/domain/entities/message_entity.dart';

void main() {
  group('MessageEntity', () {
    final testDate = DateTime(2025, 1, 24, 10, 30);

    final testMessage = MessageEntity(
      id: 'msg-123',
      tripId: 'trip-456',
      senderId: 'user-789',
      message: 'Hello World',
      messageType: MessageType.text,
      reactions: const [],
      readBy: const ['user-789'],
      createdAt: testDate,
      updatedAt: testDate,
    );

    test('should create message entity with required fields', () {
      expect(testMessage.id, 'msg-123');
      expect(testMessage.tripId, 'trip-456');
      expect(testMessage.senderId, 'user-789');
      expect(testMessage.message, 'Hello World');
      expect(testMessage.messageType, MessageType.text);
      expect(testMessage.reactions, isEmpty);
      expect(testMessage.readBy, ['user-789']);
      expect(testMessage.isDeleted, false);
    });

    test('should support all message types', () {
      expect(MessageType.text, isNotNull);
      expect(MessageType.image, isNotNull);
      expect(MessageType.location, isNotNull);
      expect(MessageType.expenseLink, isNotNull);
    });

    test('isReadBy should return true for user in readBy list', () {
      expect(testMessage.isReadBy('user-789'), true);
    });

    test('isReadBy should return false for user not in readBy list', () {
      expect(testMessage.isReadBy('user-999'), false);
    });

    group('Reactions', () {
      final reaction1 = MessageReaction(
        emoji: '👍',
        userId: 'user-1',
        createdAt: testDate,
      );

      final reaction2 = MessageReaction(
        emoji: '❤️',
        userId: 'user-2',
        createdAt: testDate,
      );

      final reaction3 = MessageReaction(
        emoji: '👍',
        userId: 'user-3',
        createdAt: testDate,
      );

      final messageWithReactions = MessageEntity(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-789',
        message: 'Hello',
        messageType: MessageType.text,
        reactions: [reaction1, reaction2, reaction3],
        readBy: const [],
        createdAt: testDate,
        updatedAt: testDate,
      );

      test('hasReaction should return true when user has reacted with emoji', () {
        expect(messageWithReactions.hasReaction('user-1', '👍'), true);
      });

      test('hasReaction should return false when user has not reacted with emoji', () {
        expect(messageWithReactions.hasReaction('user-1', '❤️'), false);
      });

      test('hasReaction should return false when user has not reacted at all', () {
        expect(messageWithReactions.hasReaction('user-999', '👍'), false);
      });

      test('getReactionCount should return correct count for emoji', () {
        expect(messageWithReactions.getReactionCount('👍'), 2);
        expect(messageWithReactions.getReactionCount('❤️'), 1);
        expect(messageWithReactions.getReactionCount('😂'), 0);
      });

      test('getUniqueEmojis should return set of unique emojis', () {
        final uniqueEmojis = messageWithReactions.getUniqueEmojis();
        expect(uniqueEmojis, {'👍', '❤️'});
        expect(uniqueEmojis.length, 2);
      });
    });

    group('copyWith', () {
      test('should copy with new message', () {
        final copied = testMessage.copyWith(message: 'New message');
        expect(copied.message, 'New message');
        expect(copied.id, testMessage.id);
        expect(copied.tripId, testMessage.tripId);
      });

      test('should copy with new reactions', () {
        final reaction = MessageReaction(
          emoji: '👍',
          userId: 'user-1',
          createdAt: testDate,
        );
        final copied = testMessage.copyWith(reactions: [reaction]);
        expect(copied.reactions.length, 1);
        expect(copied.reactions.first.emoji, '👍');
      });

      test('should copy with new readBy list', () {
        final copied = testMessage.copyWith(readBy: ['user-789', 'user-999']);
        expect(copied.readBy.length, 2);
        expect(copied.readBy, contains('user-999'));
      });

      test('should copy with isDeleted flag', () {
        final copied = testMessage.copyWith(isDeleted: true);
        expect(copied.isDeleted, true);
        expect(testMessage.isDeleted, false); // Original unchanged
      });
    });

    group('Equatable', () {
      test('should be equal when all properties are the same', () {
        final message1 = MessageEntity(
          id: 'msg-123',
          tripId: 'trip-456',
          senderId: 'user-789',
          message: 'Hello',
          messageType: MessageType.text,
          reactions: const [],
          readBy: const [],
          createdAt: testDate,
          updatedAt: testDate,
        );

        final message2 = MessageEntity(
          id: 'msg-123',
          tripId: 'trip-456',
          senderId: 'user-789',
          message: 'Hello',
          messageType: MessageType.text,
          reactions: const [],
          readBy: const [],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(message1, equals(message2));
      });

      test('should not be equal when id is different', () {
        final message2 = testMessage.copyWith(id: 'msg-999');
        expect(testMessage, isNot(equals(message2)));
      });

      test('should not be equal when message content is different', () {
        final message2 = testMessage.copyWith(message: 'Different');
        expect(testMessage, isNot(equals(message2)));
      });
    });
  });

  group('MessageReaction', () {
    final testDate = DateTime(2025, 1, 24, 10, 30);

    final reaction = MessageReaction(
      emoji: '👍',
      userId: 'user-123',
      createdAt: testDate,
    );

    test('should create reaction with all fields', () {
      expect(reaction.emoji, '👍');
      expect(reaction.userId, 'user-123');
      expect(reaction.createdAt, testDate);
    });

    test('toJson should serialize correctly', () {
      final json = reaction.toJson();
      expect(json['emoji'], '👍');
      expect(json['user_id'], 'user-123');
      expect(json['created_at'], testDate.toIso8601String());
    });

    test('fromJson should deserialize correctly', () {
      final json = {
        'emoji': '❤️',
        'user_id': 'user-456',
        'created_at': testDate.toIso8601String(),
      };

      final reaction = MessageReaction.fromJson(json);
      expect(reaction.emoji, '❤️');
      expect(reaction.userId, 'user-456');
      expect(reaction.createdAt, testDate);
    });

    test('should be equal when all properties are the same', () {
      final reaction1 = MessageReaction(
        emoji: '👍',
        userId: 'user-123',
        createdAt: testDate,
      );

      final reaction2 = MessageReaction(
        emoji: '👍',
        userId: 'user-123',
        createdAt: testDate,
      );

      expect(reaction1, equals(reaction2));
    });

    test('should not be equal when emoji is different', () {
      final reaction2 = MessageReaction(
        emoji: '❤️',
        userId: 'user-123',
        createdAt: testDate,
      );

      expect(reaction, isNot(equals(reaction2)));
    });
  });

  group('QueuedMessageEntity', () {
    final testDate = DateTime(2025, 1, 24, 10, 30);

    final queuedMessage = QueuedMessageEntity(
      id: 'queue-123',
      tripId: 'trip-456',
      senderId: 'user-789',
      messageData: {'message': 'Hello', 'type': 'text'},
      transmissionMethod: TransmissionMethod.internet,
      syncStatus: MessageSyncStatus.pending,
      createdAt: testDate,
    );

    test('should create queued message with required fields', () {
      expect(queuedMessage.id, 'queue-123');
      expect(queuedMessage.tripId, 'trip-456');
      expect(queuedMessage.senderId, 'user-789');
      expect(queuedMessage.messageData, {'message': 'Hello', 'type': 'text'});
      expect(queuedMessage.transmissionMethod, TransmissionMethod.internet);
      expect(queuedMessage.syncStatus, MessageSyncStatus.pending);
      expect(queuedMessage.retryCount, 0);
      expect(queuedMessage.relayPath, isEmpty);
    });

    test('should support all sync statuses', () {
      expect(MessageSyncStatus.pending, isNotNull);
      expect(MessageSyncStatus.syncing, isNotNull);
      expect(MessageSyncStatus.synced, isNotNull);
      expect(MessageSyncStatus.failed, isNotNull);
    });

    test('should support all transmission methods', () {
      expect(TransmissionMethod.internet, isNotNull);
      expect(TransmissionMethod.bluetooth, isNotNull);
      expect(TransmissionMethod.wifiDirect, isNotNull);
      expect(TransmissionMethod.relay, isNotNull);
    });

    test('copyWith should update sync status', () {
      final updated = queuedMessage.copyWith(
        syncStatus: MessageSyncStatus.syncing,
      );
      expect(updated.syncStatus, MessageSyncStatus.syncing);
      expect(queuedMessage.syncStatus, MessageSyncStatus.pending);
    });

    test('copyWith should update retry count', () {
      final updated = queuedMessage.copyWith(retryCount: 3);
      expect(updated.retryCount, 3);
      expect(queuedMessage.retryCount, 0);
    });

    test('copyWith should update error message', () {
      final updated = queuedMessage.copyWith(
        errorMessage: 'Network error',
      );
      expect(updated.errorMessage, 'Network error');
      expect(queuedMessage.errorMessage, isNull);
    });

    test('should support relay path for mesh networking', () {
      final relayMessage = queuedMessage.copyWith(
        transmissionMethod: TransmissionMethod.relay,
        relayPath: ['user-1', 'user-2', 'user-3'],
      );
      expect(relayMessage.transmissionMethod, TransmissionMethod.relay);
      expect(relayMessage.relayPath, ['user-1', 'user-2', 'user-3']);
    });
  });
}
