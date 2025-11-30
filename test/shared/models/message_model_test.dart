import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/messaging/domain/entities/message_entity.dart';
import 'package:travel_crew/shared/models/message_model.dart';

void main() {
  group('MessageModel', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final testUpdatedDate = DateTime(2024, 1, 15, 11, 30);

    group('constructor', () {
      test('should create instance with required fields', () {
        final message = MessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          messageType: 'text',
          createdAt: testDate,
          updatedAt: testUpdatedDate,
        );

        expect(message.id, 'msg-1');
        expect(message.tripId, 'trip-1');
        expect(message.senderId, 'user-1');
        expect(message.messageType, 'text');
        expect(message.createdAt, testDate);
        expect(message.updatedAt, testUpdatedDate);
        expect(message.message, isNull);
        expect(message.replyToId, isNull);
        expect(message.attachmentUrl, isNull);
        expect(message.reactions, isEmpty);
        expect(message.readBy, isEmpty);
        expect(message.isDeleted, false);
        expect(message.senderName, isNull);
        expect(message.senderAvatarUrl, isNull);
      });

      test('should create instance with all fields', () {
        final reactions = [
          {'emoji': '👍', 'user_id': 'user-2', 'created_at': testDate.toIso8601String()},
        ];
        final readBy = ['user-1', 'user-2'];

        final message = MessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Hello, world!',
          messageType: 'text',
          replyToId: 'msg-0',
          attachmentUrl: 'https://example.com/image.jpg',
          reactions: reactions,
          readBy: readBy,
          isDeleted: false,
          createdAt: testDate,
          updatedAt: testUpdatedDate,
          senderName: 'John Doe',
          senderAvatarUrl: 'https://example.com/avatar.jpg',
        );

        expect(message.message, 'Hello, world!');
        expect(message.replyToId, 'msg-0');
        expect(message.attachmentUrl, 'https://example.com/image.jpg');
        expect(message.reactions.length, 1);
        expect(message.readBy.length, 2);
        expect(message.senderName, 'John Doe');
        expect(message.senderAvatarUrl, 'https://example.com/avatar.jpg');
      });
    });

    group('fromJson', () {
      test('should parse valid JSON with all fields', () {
        final json = {
          'id': 'msg-1',
          'trip_id': 'trip-1',
          'sender_id': 'user-1',
          'message': 'Hello, world!',
          'message_type': 'text',
          'reply_to_id': 'msg-0',
          'attachment_url': 'https://example.com/image.jpg',
          'reactions': [
            {'emoji': '👍', 'user_id': 'user-2', 'created_at': '2024-01-15T10:30:00.000Z'},
          ],
          'read_by': ['user-1', 'user-2'],
          'is_deleted': false,
          'created_at': '2024-01-15T10:30:00.000Z',
          'updated_at': '2024-01-15T11:30:00.000Z',
          'sender_name': 'John Doe',
          'sender_avatar_url': 'https://example.com/avatar.jpg',
        };

        final message = MessageModel.fromJson(json);

        expect(message.id, 'msg-1');
        expect(message.tripId, 'trip-1');
        expect(message.senderId, 'user-1');
        expect(message.message, 'Hello, world!');
        expect(message.messageType, 'text');
        expect(message.replyToId, 'msg-0');
        expect(message.attachmentUrl, 'https://example.com/image.jpg');
        expect(message.reactions.length, 1);
        expect(message.reactions[0]['emoji'], '👍');
        expect(message.readBy.length, 2);
        expect(message.isDeleted, false);
        expect(message.senderName, 'John Doe');
        expect(message.senderAvatarUrl, 'https://example.com/avatar.jpg');
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'msg-1',
          'trip_id': 'trip-1',
          'sender_id': 'user-1',
          'message_type': 'text',
          'created_at': '2024-01-15T10:30:00.000Z',
          'updated_at': '2024-01-15T11:30:00.000Z',
        };

        final message = MessageModel.fromJson(json);

        expect(message.message, isNull);
        expect(message.replyToId, isNull);
        expect(message.attachmentUrl, isNull);
        expect(message.reactions, isEmpty);
        expect(message.readBy, isEmpty);
        expect(message.isDeleted, false);
        expect(message.senderName, isNull);
        expect(message.senderAvatarUrl, isNull);
      });

      test('should handle null reactions and readBy arrays', () {
        final json = {
          'id': 'msg-1',
          'trip_id': 'trip-1',
          'sender_id': 'user-1',
          'message_type': 'text',
          'reactions': null,
          'read_by': null,
          'created_at': '2024-01-15T10:30:00.000Z',
          'updated_at': '2024-01-15T11:30:00.000Z',
        };

        final message = MessageModel.fromJson(json);

        expect(message.reactions, isEmpty);
        expect(message.readBy, isEmpty);
      });

      test('should handle null is_deleted', () {
        final json = {
          'id': 'msg-1',
          'trip_id': 'trip-1',
          'sender_id': 'user-1',
          'message_type': 'text',
          'is_deleted': null,
          'created_at': '2024-01-15T10:30:00.000Z',
          'updated_at': '2024-01-15T11:30:00.000Z',
        };

        final message = MessageModel.fromJson(json);
        expect(message.isDeleted, false);
      });

      test('should parse different message types', () {
        final types = ['text', 'image', 'location', 'expense_link'];

        for (final type in types) {
          final json = {
            'id': 'msg-1',
            'trip_id': 'trip-1',
            'sender_id': 'user-1',
            'message_type': type,
            'created_at': '2024-01-15T10:30:00.000Z',
            'updated_at': '2024-01-15T11:30:00.000Z',
          };

          final message = MessageModel.fromJson(json);
          expect(message.messageType, type);
        }
      });
    });

    group('toJson', () {
      test('should convert to JSON with all fields', () {
        final reactions = [
          {'emoji': '👍', 'user_id': 'user-2', 'created_at': testDate.toIso8601String()},
        ];

        final message = MessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Hello, world!',
          messageType: 'text',
          replyToId: 'msg-0',
          attachmentUrl: 'https://example.com/image.jpg',
          reactions: reactions,
          readBy: ['user-1', 'user-2'],
          isDeleted: false,
          createdAt: DateTime.utc(2024, 1, 15, 10, 30),
          updatedAt: DateTime.utc(2024, 1, 15, 11, 30),
          senderName: 'John Doe',
          senderAvatarUrl: 'https://example.com/avatar.jpg',
        );

        final json = message.toJson();

        expect(json['id'], 'msg-1');
        expect(json['trip_id'], 'trip-1');
        expect(json['sender_id'], 'user-1');
        expect(json['message'], 'Hello, world!');
        expect(json['message_type'], 'text');
        expect(json['reply_to_id'], 'msg-0');
        expect(json['attachment_url'], 'https://example.com/image.jpg');
        expect((json['reactions'] as List).length, 1);
        expect((json['read_by'] as List).length, 2);
        expect(json['is_deleted'], false);
        expect(json['sender_name'], 'John Doe');
        expect(json['sender_avatar_url'], 'https://example.com/avatar.jpg');
      });

      test('should format dates as ISO8601 strings', () {
        final message = MessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          messageType: 'text',
          createdAt: DateTime.utc(2024, 1, 15, 10, 30),
          updatedAt: DateTime.utc(2024, 1, 15, 11, 30),
        );

        final json = message.toJson();

        expect(json['created_at'], '2024-01-15T10:30:00.000Z');
        expect(json['updated_at'], '2024-01-15T11:30:00.000Z');
      });
    });

    group('toDatabaseJson', () {
      test('should exclude joined fields', () {
        final message = MessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          messageType: 'text',
          createdAt: testDate,
          updatedAt: testUpdatedDate,
          senderName: 'John Doe',
          senderAvatarUrl: 'https://example.com/avatar.jpg',
        );

        final json = message.toDatabaseJson();

        expect(json.containsKey('sender_name'), false);
        expect(json.containsKey('sender_avatar_url'), false);
        expect(json['id'], 'msg-1');
        expect(json['trip_id'], 'trip-1');
      });
    });

    group('toEntity', () {
      test('should convert model to entity with all fields', () {
        final reactions = [
          {'emoji': '👍', 'user_id': 'user-2', 'created_at': testDate.toIso8601String()},
        ];

        final model = MessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Hello, world!',
          messageType: 'text',
          replyToId: 'msg-0',
          attachmentUrl: 'https://example.com/image.jpg',
          reactions: reactions,
          readBy: ['user-1', 'user-2'],
          isDeleted: false,
          createdAt: testDate,
          updatedAt: testUpdatedDate,
          senderName: 'John Doe',
          senderAvatarUrl: 'https://example.com/avatar.jpg',
        );

        final entity = model.toEntity();

        expect(entity, isA<MessageEntity>());
        expect(entity.id, model.id);
        expect(entity.tripId, model.tripId);
        expect(entity.senderId, model.senderId);
        expect(entity.message, model.message);
        expect(entity.messageType, MessageType.text);
        expect(entity.replyToId, model.replyToId);
        expect(entity.attachmentUrl, model.attachmentUrl);
        expect(entity.reactions.length, 1);
        expect(entity.readBy.length, 2);
        expect(entity.isDeleted, model.isDeleted);
        expect(entity.senderName, model.senderName);
        expect(entity.senderAvatarUrl, model.senderAvatarUrl);
      });

      test('should convert message types correctly', () {
        final typeMapping = {
          'text': MessageType.text,
          'image': MessageType.image,
          'location': MessageType.location,
          'expense_link': MessageType.expenseLink,
        };

        for (final entry in typeMapping.entries) {
          final model = MessageModel(
            id: 'msg-1',
            tripId: 'trip-1',
            senderId: 'user-1',
            messageType: entry.key,
            createdAt: testDate,
            updatedAt: testUpdatedDate,
          );

          final entity = model.toEntity();
          expect(entity.messageType, entry.value);
        }
      });

      test('should default to text for unknown message type', () {
        final model = MessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          messageType: 'unknown',
          createdAt: testDate,
          updatedAt: testUpdatedDate,
        );

        final entity = model.toEntity();
        expect(entity.messageType, MessageType.text);
      });
    });

    group('fromEntity', () {
      test('should create model from entity with all fields', () {
        final reactions = [
          MessageReaction(
            emoji: '👍',
            userId: 'user-2',
            createdAt: testDate,
          ),
        ];

        final entity = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Hello, world!',
          messageType: MessageType.text,
          replyToId: 'msg-0',
          attachmentUrl: 'https://example.com/image.jpg',
          reactions: reactions,
          readBy: ['user-1', 'user-2'],
          isDeleted: false,
          createdAt: testDate,
          updatedAt: testUpdatedDate,
          senderName: 'John Doe',
          senderAvatarUrl: 'https://example.com/avatar.jpg',
        );

        final model = MessageModel.fromEntity(entity);

        expect(model.id, entity.id);
        expect(model.tripId, entity.tripId);
        expect(model.senderId, entity.senderId);
        expect(model.message, entity.message);
        expect(model.messageType, 'text');
        expect(model.replyToId, entity.replyToId);
        expect(model.attachmentUrl, entity.attachmentUrl);
        expect(model.reactions.length, 1);
        expect(model.readBy.length, 2);
        expect(model.isDeleted, entity.isDeleted);
        expect(model.senderName, entity.senderName);
        expect(model.senderAvatarUrl, entity.senderAvatarUrl);
      });

      test('should convert message types correctly', () {
        final typeMapping = {
          MessageType.text: 'text',
          MessageType.image: 'image',
          MessageType.location: 'location',
          MessageType.expenseLink: 'expense_link',
        };

        for (final entry in typeMapping.entries) {
          final entity = MessageEntity(
            id: 'msg-1',
            tripId: 'trip-1',
            senderId: 'user-1',
            messageType: entry.key,
            createdAt: testDate,
            updatedAt: testUpdatedDate,
          );

          final model = MessageModel.fromEntity(entity);
          expect(model.messageType, entry.value);
        }
      });
    });

    group('round-trip serialization', () {
      test('should preserve all data through JSON round-trip', () {
        final original = MessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Hello, world!',
          messageType: 'text',
          replyToId: 'msg-0',
          attachmentUrl: 'https://example.com/image.jpg',
          reactions: [
            {'emoji': '👍', 'user_id': 'user-2', 'created_at': testDate.toIso8601String()},
          ],
          readBy: ['user-1', 'user-2'],
          isDeleted: false,
          createdAt: DateTime.utc(2024, 1, 15, 10, 30),
          updatedAt: DateTime.utc(2024, 1, 15, 11, 30),
          senderName: 'John Doe',
          senderAvatarUrl: 'https://example.com/avatar.jpg',
        );

        final json = original.toJson();
        final restored = MessageModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.tripId, original.tripId);
        expect(restored.senderId, original.senderId);
        expect(restored.message, original.message);
        expect(restored.messageType, original.messageType);
        expect(restored.replyToId, original.replyToId);
        expect(restored.attachmentUrl, original.attachmentUrl);
        expect(restored.reactions.length, original.reactions.length);
        expect(restored.readBy.length, original.readBy.length);
        expect(restored.isDeleted, original.isDeleted);
        expect(restored.senderName, original.senderName);
        expect(restored.senderAvatarUrl, original.senderAvatarUrl);
      });

      test('should preserve all data through entity round-trip', () {
        final original = MessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Hello, world!',
          messageType: 'text',
          replyToId: 'msg-0',
          attachmentUrl: 'https://example.com/image.jpg',
          reactions: [
            {'emoji': '👍', 'user_id': 'user-2', 'created_at': testDate.toIso8601String()},
          ],
          readBy: ['user-1', 'user-2'],
          isDeleted: false,
          createdAt: testDate,
          updatedAt: testUpdatedDate,
          senderName: 'John Doe',
          senderAvatarUrl: 'https://example.com/avatar.jpg',
        );

        final entity = original.toEntity();
        final restored = MessageModel.fromEntity(entity);

        expect(restored.id, original.id);
        expect(restored.tripId, original.tripId);
        expect(restored.senderId, original.senderId);
        expect(restored.message, original.message);
        expect(restored.messageType, original.messageType);
        expect(restored.replyToId, original.replyToId);
        expect(restored.attachmentUrl, original.attachmentUrl);
        expect(restored.reactions.length, original.reactions.length);
        expect(restored.readBy.length, original.readBy.length);
        expect(restored.isDeleted, original.isDeleted);
        expect(restored.senderName, original.senderName);
        expect(restored.senderAvatarUrl, original.senderAvatarUrl);
      });
    });

    group('edge cases', () {
      test('should handle empty message', () {
        final message = MessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: '',
          messageType: 'text',
          createdAt: testDate,
          updatedAt: testUpdatedDate,
        );

        final json = message.toJson();
        final restored = MessageModel.fromJson(json);

        expect(restored.message, '');
      });

      test('should handle very long message', () {
        final longMessage = 'A' * 10000;

        final message = MessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: longMessage,
          messageType: 'text',
          createdAt: testDate,
          updatedAt: testUpdatedDate,
        );

        final json = message.toJson();
        final restored = MessageModel.fromJson(json);

        expect(restored.message?.length, 10000);
      });

      test('should handle unicode characters in message', () {
        final message = MessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Hello, 世界! 🌍🎉',
          messageType: 'text',
          createdAt: testDate,
          updatedAt: testUpdatedDate,
        );

        final json = message.toJson();
        final restored = MessageModel.fromJson(json);

        expect(restored.message, 'Hello, 世界! 🌍🎉');
      });

      test('should handle multiple reactions', () {
        final reactions = [
          {'emoji': '👍', 'user_id': 'user-1', 'created_at': testDate.toIso8601String()},
          {'emoji': '❤️', 'user_id': 'user-2', 'created_at': testDate.toIso8601String()},
          {'emoji': '😂', 'user_id': 'user-3', 'created_at': testDate.toIso8601String()},
          {'emoji': '👍', 'user_id': 'user-4', 'created_at': testDate.toIso8601String()},
        ];

        final message = MessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          messageType: 'text',
          reactions: reactions,
          createdAt: testDate,
          updatedAt: testUpdatedDate,
        );

        expect(message.reactions.length, 4);

        final entity = message.toEntity();
        expect(entity.reactions.length, 4);
      });

      test('should handle large readBy list', () {
        final readBy = List.generate(100, (i) => 'user-$i');

        final message = MessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          messageType: 'text',
          readBy: readBy,
          createdAt: testDate,
          updatedAt: testUpdatedDate,
        );

        expect(message.readBy.length, 100);
      });
    });
  });

  group('QueuedMessageModel', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);

    group('constructor', () {
      test('should create instance with required fields', () {
        final queued = QueuedMessageModel(
          id: 'queue-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          messageData: {'message': 'Hello'},
          transmissionMethod: 'internet',
          syncStatus: 'pending',
          createdAt: testDate,
        );

        expect(queued.id, 'queue-1');
        expect(queued.tripId, 'trip-1');
        expect(queued.senderId, 'user-1');
        expect(queued.messageData['message'], 'Hello');
        expect(queued.transmissionMethod, 'internet');
        expect(queued.syncStatus, 'pending');
        expect(queued.relayPath, isEmpty);
        expect(queued.retryCount, 0);
        expect(queued.lastAttemptAt, isNull);
        expect(queued.errorMessage, isNull);
      });

      test('should create instance with all fields', () {
        final lastAttempt = DateTime(2024, 1, 15, 10, 45);

        final queued = QueuedMessageModel(
          id: 'queue-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          messageData: {'message': 'Hello'},
          transmissionMethod: 'bluetooth',
          relayPath: ['node-1', 'node-2'],
          syncStatus: 'failed',
          retryCount: 3,
          lastAttemptAt: lastAttempt,
          errorMessage: 'Network error',
          createdAt: testDate,
        );

        expect(queued.relayPath.length, 2);
        expect(queued.retryCount, 3);
        expect(queued.lastAttemptAt, lastAttempt);
        expect(queued.errorMessage, 'Network error');
      });
    });

    group('fromJson', () {
      test('should parse valid JSON', () {
        final json = {
          'id': 'queue-1',
          'trip_id': 'trip-1',
          'sender_id': 'user-1',
          'message_data': {'message': 'Hello'},
          'transmission_method': 'wifi_direct',
          'relay_path': ['node-1', 'node-2'],
          'sync_status': 'syncing',
          'retry_count': 2,
          'last_attempt_at': '2024-01-15T10:45:00.000Z',
          'error_message': 'Timeout',
          'created_at': '2024-01-15T10:30:00.000Z',
        };

        final queued = QueuedMessageModel.fromJson(json);

        expect(queued.id, 'queue-1');
        expect(queued.tripId, 'trip-1');
        expect(queued.senderId, 'user-1');
        expect(queued.messageData['message'], 'Hello');
        expect(queued.transmissionMethod, 'wifi_direct');
        expect(queued.relayPath.length, 2);
        expect(queued.syncStatus, 'syncing');
        expect(queued.retryCount, 2);
        expect(queued.errorMessage, 'Timeout');
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'queue-1',
          'trip_id': 'trip-1',
          'sender_id': 'user-1',
          'message_data': {'message': 'Hello'},
          'transmission_method': 'internet',
          'sync_status': 'pending',
          'created_at': '2024-01-15T10:30:00.000Z',
        };

        final queued = QueuedMessageModel.fromJson(json);

        expect(queued.relayPath, isEmpty);
        expect(queued.retryCount, 0);
        expect(queued.lastAttemptAt, isNull);
        expect(queued.errorMessage, isNull);
      });
    });

    group('toJson', () {
      test('should convert to JSON with all fields', () {
        final lastAttempt = DateTime.utc(2024, 1, 15, 10, 45);

        final queued = QueuedMessageModel(
          id: 'queue-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          messageData: {'message': 'Hello'},
          transmissionMethod: 'bluetooth',
          relayPath: ['node-1', 'node-2'],
          syncStatus: 'failed',
          retryCount: 3,
          lastAttemptAt: lastAttempt,
          errorMessage: 'Network error',
          createdAt: DateTime.utc(2024, 1, 15, 10, 30),
        );

        final json = queued.toJson();

        expect(json['id'], 'queue-1');
        expect(json['trip_id'], 'trip-1');
        expect(json['sender_id'], 'user-1');
        expect(json['message_data']['message'], 'Hello');
        expect(json['transmission_method'], 'bluetooth');
        expect((json['relay_path'] as List).length, 2);
        expect(json['sync_status'], 'failed');
        expect(json['retry_count'], 3);
        expect(json['last_attempt_at'], '2024-01-15T10:45:00.000Z');
        expect(json['error_message'], 'Network error');
      });
    });

    group('toEntity', () {
      test('should convert model to entity', () {
        final model = QueuedMessageModel(
          id: 'queue-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          messageData: {'message': 'Hello'},
          transmissionMethod: 'internet',
          syncStatus: 'pending',
          createdAt: testDate,
        );

        final entity = model.toEntity();

        expect(entity, isA<QueuedMessageEntity>());
        expect(entity.id, model.id);
        expect(entity.tripId, model.tripId);
        expect(entity.senderId, model.senderId);
        expect(entity.transmissionMethod, TransmissionMethod.internet);
        expect(entity.syncStatus, MessageSyncStatus.pending);
      });

      test('should convert transmission methods correctly', () {
        final methodMapping = {
          'internet': TransmissionMethod.internet,
          'bluetooth': TransmissionMethod.bluetooth,
          'wifi_direct': TransmissionMethod.wifiDirect,
          'relay': TransmissionMethod.relay,
        };

        for (final entry in methodMapping.entries) {
          final model = QueuedMessageModel(
            id: 'queue-1',
            tripId: 'trip-1',
            senderId: 'user-1',
            messageData: {},
            transmissionMethod: entry.key,
            syncStatus: 'pending',
            createdAt: testDate,
          );

          final entity = model.toEntity();
          expect(entity.transmissionMethod, entry.value);
        }
      });

      test('should convert sync statuses correctly', () {
        final statusMapping = {
          'pending': MessageSyncStatus.pending,
          'syncing': MessageSyncStatus.syncing,
          'synced': MessageSyncStatus.synced,
          'failed': MessageSyncStatus.failed,
        };

        for (final entry in statusMapping.entries) {
          final model = QueuedMessageModel(
            id: 'queue-1',
            tripId: 'trip-1',
            senderId: 'user-1',
            messageData: {},
            transmissionMethod: 'internet',
            syncStatus: entry.key,
            createdAt: testDate,
          );

          final entity = model.toEntity();
          expect(entity.syncStatus, entry.value);
        }
      });
    });

    group('fromEntity', () {
      test('should create model from entity', () {
        final entity = QueuedMessageEntity(
          id: 'queue-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          messageData: {'message': 'Hello'},
          transmissionMethod: TransmissionMethod.bluetooth,
          syncStatus: MessageSyncStatus.syncing,
          retryCount: 2,
          createdAt: testDate,
        );

        final model = QueuedMessageModel.fromEntity(entity);

        expect(model.id, entity.id);
        expect(model.tripId, entity.tripId);
        expect(model.senderId, entity.senderId);
        expect(model.transmissionMethod, 'bluetooth');
        expect(model.syncStatus, 'syncing');
        expect(model.retryCount, 2);
      });
    });
  });

  group('MessageReaction', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);

    group('constructor', () {
      test('should create instance with required fields', () {
        final reaction = MessageReaction(
          emoji: '👍',
          userId: 'user-1',
          createdAt: testDate,
        );

        expect(reaction.emoji, '👍');
        expect(reaction.userId, 'user-1');
        expect(reaction.createdAt, testDate);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON', () {
        final json = {
          'emoji': '❤️',
          'user_id': 'user-2',
          'created_at': '2024-01-15T10:30:00.000Z',
        };

        final reaction = MessageReaction.fromJson(json);

        expect(reaction.emoji, '❤️');
        expect(reaction.userId, 'user-2');
      });
    });

    group('toJson', () {
      test('should convert to JSON', () {
        final reaction = MessageReaction(
          emoji: '😂',
          userId: 'user-3',
          createdAt: DateTime.utc(2024, 1, 15, 10, 30),
        );

        final json = reaction.toJson();

        expect(json['emoji'], '😂');
        expect(json['user_id'], 'user-3');
        expect(json['created_at'], '2024-01-15T10:30:00.000Z');
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        final reaction1 = MessageReaction(
          emoji: '👍',
          userId: 'user-1',
          createdAt: testDate,
        );

        final reaction2 = MessageReaction(
          emoji: '👍',
          userId: 'user-1',
          createdAt: testDate,
        );

        expect(reaction1, equals(reaction2));
      });

      test('should not be equal when different emoji', () {
        final reaction1 = MessageReaction(
          emoji: '👍',
          userId: 'user-1',
          createdAt: testDate,
        );

        final reaction2 = MessageReaction(
          emoji: '❤️',
          userId: 'user-1',
          createdAt: testDate,
        );

        expect(reaction1, isNot(equals(reaction2)));
      });
    });
  });

  group('MessageEntity', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);

    group('helper methods', () {
      test('isReadBy should return true for user who read', () {
        final entity = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          messageType: MessageType.text,
          readBy: ['user-2', 'user-3'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(entity.isReadBy('user-2'), true);
        expect(entity.isReadBy('user-3'), true);
        expect(entity.isReadBy('user-4'), false);
      });

      test('hasReaction should return true for user with reaction', () {
        final entity = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          messageType: MessageType.text,
          reactions: [
            MessageReaction(emoji: '👍', userId: 'user-2', createdAt: testDate),
            MessageReaction(emoji: '❤️', userId: 'user-2', createdAt: testDate),
          ],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(entity.hasReaction('user-2', '👍'), true);
        expect(entity.hasReaction('user-2', '❤️'), true);
        expect(entity.hasReaction('user-2', '😂'), false);
        expect(entity.hasReaction('user-3', '👍'), false);
      });

      test('getReactionCount should return correct count', () {
        final entity = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          messageType: MessageType.text,
          reactions: [
            MessageReaction(emoji: '👍', userId: 'user-1', createdAt: testDate),
            MessageReaction(emoji: '👍', userId: 'user-2', createdAt: testDate),
            MessageReaction(emoji: '❤️', userId: 'user-3', createdAt: testDate),
          ],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(entity.getReactionCount('👍'), 2);
        expect(entity.getReactionCount('❤️'), 1);
        expect(entity.getReactionCount('😂'), 0);
      });

      test('getUniqueEmojis should return unique set', () {
        final entity = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          messageType: MessageType.text,
          reactions: [
            MessageReaction(emoji: '👍', userId: 'user-1', createdAt: testDate),
            MessageReaction(emoji: '👍', userId: 'user-2', createdAt: testDate),
            MessageReaction(emoji: '❤️', userId: 'user-3', createdAt: testDate),
            MessageReaction(emoji: '😂', userId: 'user-4', createdAt: testDate),
          ],
          createdAt: testDate,
          updatedAt: testDate,
        );

        final emojis = entity.getUniqueEmojis();
        expect(emojis.length, 3);
        expect(emojis.contains('👍'), true);
        expect(emojis.contains('❤️'), true);
        expect(emojis.contains('😂'), true);
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        final original = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Hello',
          messageType: MessageType.text,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final copied = original.copyWith(
          message: 'Updated',
          isDeleted: true,
        );

        expect(copied.id, 'msg-1');
        expect(copied.message, 'Updated');
        expect(copied.isDeleted, true);
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        final entity1 = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          messageType: MessageType.text,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final entity2 = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          messageType: MessageType.text,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(entity1, equals(entity2));
      });
    });
  });
}
