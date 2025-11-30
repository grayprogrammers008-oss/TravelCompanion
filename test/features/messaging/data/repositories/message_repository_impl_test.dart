import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/messaging/data/datasources/message_local_datasource.dart';
import 'package:travel_crew/features/messaging/data/datasources/message_remote_datasource.dart';
import 'package:travel_crew/features/messaging/data/repositories/message_repository_impl.dart';
import 'package:travel_crew/features/messaging/domain/entities/message_entity.dart';
import 'package:travel_crew/shared/models/message_model.dart';

import 'message_repository_impl_test.mocks.dart';

@GenerateMocks([MessageLocalDataSource, MessageRemoteDataSource, Connectivity])
void main() {
  late MessageRepositoryImpl repository;
  late MockMessageLocalDataSource mockLocalDataSource;
  late MockMessageRemoteDataSource mockRemoteDataSource;
  late MockConnectivity mockConnectivity;

  setUp(() {
    mockLocalDataSource = MockMessageLocalDataSource();
    mockRemoteDataSource = MockMessageRemoteDataSource();
    mockConnectivity = MockConnectivity();
    repository = MessageRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      connectivity: mockConnectivity,
    );
  });

  final now = DateTime.now();

  MessageModel createMessageModel({
    required String id,
    required String tripId,
    required String senderId,
    required String message,
    String messageType = 'text',
    String? replyToId,
    String? attachmentUrl,
    List<Map<String, dynamic>>? reactions,
    List<String>? readBy,
    bool isDeleted = false,
  }) {
    return MessageModel(
      id: id,
      tripId: tripId,
      senderId: senderId,
      message: message,
      messageType: messageType,
      replyToId: replyToId,
      attachmentUrl: attachmentUrl,
      reactions: reactions ?? [],
      readBy: readBy ?? [senderId],
      isDeleted: isDeleted,
      createdAt: now,
      updatedAt: now,
    );
  }

  QueuedMessageModel createQueuedMessageModel({
    required String id,
    required String tripId,
    required String senderId,
    String status = 'pending',
  }) {
    return QueuedMessageModel(
      id: id,
      tripId: tripId,
      senderId: senderId,
      messageData: {
        'id': 'msg-$id',
        'trip_id': tripId,
        'sender_id': senderId,
        'message': 'Test message',
        'message_type': 'text',
        'reactions': [],
        'read_by': [senderId],
        'is_deleted': false,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      transmissionMethod: 'internet',
      syncStatus: status,
      createdAt: now,
    );
  }

  void setupConnectivity({bool hasInternet = true}) {
    when(mockConnectivity.checkConnectivity()).thenAnswer((_) async =>
        hasInternet ? [ConnectivityResult.wifi] : [ConnectivityResult.none]);
  }

  group('MessageRepositoryImpl', () {
    group('sendMessage', () {
      test('should send message and sync with server when online', () async {
        // Arrange
        setupConnectivity(hasInternet: true);
        final serverMessage = createMessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Hello!',
        );
        when(mockLocalDataSource.saveMessage(any))
            .thenAnswer((_) async => {});
        when(mockRemoteDataSource.sendMessage(any))
            .thenAnswer((_) async => serverMessage);

        // Act
        final result = await repository.sendMessage(
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Hello!',
          messageType: MessageType.text,
        );

        // Assert
        expect(result.message, 'Hello!');
        verify(mockLocalDataSource.saveMessage(any)).called(2); // Initial + server response
        verify(mockRemoteDataSource.sendMessage(any)).called(1);
      });

      test('should queue message when offline', () async {
        // Arrange
        setupConnectivity(hasInternet: false);
        when(mockLocalDataSource.saveMessage(any))
            .thenAnswer((_) async => {});
        when(mockLocalDataSource.queueMessage(any))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.sendMessage(
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Offline message',
          messageType: MessageType.text,
        );

        // Assert
        expect(result.message, 'Offline message');
        verify(mockLocalDataSource.saveMessage(any)).called(1);
        verify(mockLocalDataSource.queueMessage(any)).called(1);
        verifyNever(mockRemoteDataSource.sendMessage(any));
      });

      test('should queue message when server fails', () async {
        // Arrange
        setupConnectivity(hasInternet: true);
        when(mockLocalDataSource.saveMessage(any))
            .thenAnswer((_) async => {});
        when(mockLocalDataSource.queueMessage(any))
            .thenAnswer((_) async => {});
        when(mockRemoteDataSource.sendMessage(any))
            .thenThrow(Exception('Server error'));

        // Act
        final result = await repository.sendMessage(
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Failed sync message',
          messageType: MessageType.text,
        );

        // Assert
        expect(result.message, 'Failed sync message');
        verify(mockLocalDataSource.queueMessage(any)).called(1);
      });

      test('should send message with reply', () async {
        // Arrange
        setupConnectivity(hasInternet: true);
        final serverMessage = createMessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Reply message',
          replyToId: 'original-msg',
        );
        when(mockLocalDataSource.saveMessage(any))
            .thenAnswer((_) async => {});
        when(mockRemoteDataSource.sendMessage(any))
            .thenAnswer((_) async => serverMessage);

        // Act
        final result = await repository.sendMessage(
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Reply message',
          messageType: MessageType.text,
          replyToId: 'original-msg',
        );

        // Assert
        expect(result.replyToId, 'original-msg');
      });

      test('should send message with attachment', () async {
        // Arrange
        setupConnectivity(hasInternet: true);
        final serverMessage = createMessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Check this out',
          messageType: 'image',
          attachmentUrl: 'https://example.com/image.jpg',
        );
        when(mockLocalDataSource.saveMessage(any))
            .thenAnswer((_) async => {});
        when(mockRemoteDataSource.sendMessage(any))
            .thenAnswer((_) async => serverMessage);

        // Act
        final result = await repository.sendMessage(
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Check this out',
          messageType: MessageType.image,
          attachmentUrl: 'https://example.com/image.jpg',
        );

        // Assert
        expect(result.attachmentUrl, 'https://example.com/image.jpg');
      });

      test('should throw exception when local save fails', () async {
        // Arrange
        when(mockLocalDataSource.saveMessage(any))
            .thenThrow(Exception('Local storage error'));

        // Act & Assert
        expect(
          () => repository.sendMessage(
            tripId: 'trip-1',
            senderId: 'user-1',
            message: 'Test',
            messageType: MessageType.text,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to send message'),
          )),
        );
      });
    });

    group('getTripMessages', () {
      test('should return cached messages immediately', () async {
        // Arrange
        setupConnectivity(hasInternet: true);
        final cachedMessages = [
          createMessageModel(id: '1', tripId: 'trip-1', senderId: 'user-1', message: 'Msg 1'),
          createMessageModel(id: '2', tripId: 'trip-1', senderId: 'user-2', message: 'Msg 2'),
        ];
        when(mockLocalDataSource.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenAnswer((_) async => cachedMessages);
        when(mockRemoteDataSource.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenAnswer((_) async => cachedMessages);
        when(mockLocalDataSource.saveMessages(any))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.getTripMessages(tripId: 'trip-1');

        // Assert
        expect(result.length, 2);
        verify(mockLocalDataSource.getTripMessages(
          tripId: 'trip-1',
          limit: 50,
          offset: 0,
        )).called(1);
      });

      test('should return empty list when no cached messages', () async {
        // Arrange
        setupConnectivity(hasInternet: false);
        when(mockLocalDataSource.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenAnswer((_) async => []);

        // Act
        final result = await repository.getTripMessages(tripId: 'trip-1');

        // Assert
        expect(result, isEmpty);
      });

      test('should use custom limit and offset', () async {
        // Arrange
        setupConnectivity(hasInternet: false);
        when(mockLocalDataSource.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenAnswer((_) async => []);

        // Act
        await repository.getTripMessages(
          tripId: 'trip-1',
          limit: 100,
          offset: 50,
        );

        // Assert
        verify(mockLocalDataSource.getTripMessages(
          tripId: 'trip-1',
          limit: 100,
          offset: 50,
        )).called(1);
      });

      test('should throw exception when cache fails', () async {
        // Arrange
        when(mockLocalDataSource.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenThrow(Exception('Cache error'));

        // Act & Assert
        expect(
          () => repository.getTripMessages(tripId: 'trip-1'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to get trip messages'),
          )),
        );
      });
    });

    group('getMessageById', () {
      test('should return message from cache', () async {
        // Arrange
        final message = createMessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Cached message',
        );
        when(mockLocalDataSource.getMessageById(any))
            .thenAnswer((_) async => message);

        // Act
        final result = await repository.getMessageById('msg-1');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'msg-1');
        verifyNever(mockRemoteDataSource.getMessageById(any));
      });

      test('should fetch from server when not in cache', () async {
        // Arrange
        setupConnectivity(hasInternet: true);
        final serverMessage = createMessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Server message',
        );
        when(mockLocalDataSource.getMessageById(any))
            .thenAnswer((_) async => null);
        when(mockRemoteDataSource.getMessageById(any))
            .thenAnswer((_) async => serverMessage);
        when(mockLocalDataSource.saveMessage(any))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.getMessageById('msg-1');

        // Assert
        expect(result, isNotNull);
        verify(mockRemoteDataSource.getMessageById('msg-1')).called(1);
        verify(mockLocalDataSource.saveMessage(any)).called(1);
      });

      test('should return null when message not found anywhere', () async {
        // Arrange
        setupConnectivity(hasInternet: true);
        when(mockLocalDataSource.getMessageById(any))
            .thenAnswer((_) async => null);
        when(mockRemoteDataSource.getMessageById(any))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getMessageById('nonexistent');

        // Assert
        expect(result, isNull);
      });

      test('should return null when offline and not in cache', () async {
        // Arrange
        setupConnectivity(hasInternet: false);
        when(mockLocalDataSource.getMessageById(any))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getMessageById('msg-1');

        // Assert
        expect(result, isNull);
        verifyNever(mockRemoteDataSource.getMessageById(any));
      });
    });

    group('deleteMessage', () {
      test('should delete from cache and server when online', () async {
        // Arrange
        setupConnectivity(hasInternet: true);
        when(mockLocalDataSource.deleteMessage(any))
            .thenAnswer((_) async => {});
        when(mockRemoteDataSource.deleteMessage(any))
            .thenAnswer((_) async => {});

        // Act
        await repository.deleteMessage('msg-1');

        // Assert
        verify(mockLocalDataSource.deleteMessage('msg-1')).called(1);
        verify(mockRemoteDataSource.deleteMessage('msg-1')).called(1);
      });

      test('should delete from cache only when offline', () async {
        // Arrange
        setupConnectivity(hasInternet: false);
        when(mockLocalDataSource.deleteMessage(any))
            .thenAnswer((_) async => {});

        // Act
        await repository.deleteMessage('msg-1');

        // Assert
        verify(mockLocalDataSource.deleteMessage('msg-1')).called(1);
        verifyNever(mockRemoteDataSource.deleteMessage(any));
      });

      test('should continue if server delete fails', () async {
        // Arrange
        setupConnectivity(hasInternet: true);
        when(mockLocalDataSource.deleteMessage(any))
            .thenAnswer((_) async => {});
        when(mockRemoteDataSource.deleteMessage(any))
            .thenThrow(Exception('Server error'));

        // Act - should not throw
        await repository.deleteMessage('msg-1');

        // Assert
        verify(mockLocalDataSource.deleteMessage('msg-1')).called(1);
      });

      test('should throw exception when cache delete fails', () async {
        // Arrange
        when(mockLocalDataSource.deleteMessage(any))
            .thenThrow(Exception('Cache error'));

        // Act & Assert
        expect(
          () => repository.deleteMessage('msg-1'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to delete message'),
          )),
        );
      });
    });

    group('markMessageAsRead', () {
      test('should update cache and server when online', () async {
        // Arrange
        setupConnectivity(hasInternet: true);
        when(mockLocalDataSource.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => {});
        when(mockRemoteDataSource.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => {});

        // Act
        await repository.markMessageAsRead(
          messageId: 'msg-1',
          userId: 'user-1',
        );

        // Assert
        verify(mockLocalDataSource.markMessageAsRead(
          messageId: 'msg-1',
          userId: 'user-1',
        )).called(1);
        verify(mockRemoteDataSource.markMessageAsRead(
          messageId: 'msg-1',
          userId: 'user-1',
        )).called(1);
      });

      test('should update cache only when offline', () async {
        // Arrange
        setupConnectivity(hasInternet: false);
        when(mockLocalDataSource.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => {});

        // Act
        await repository.markMessageAsRead(
          messageId: 'msg-1',
          userId: 'user-1',
        );

        // Assert
        verify(mockLocalDataSource.markMessageAsRead(
          messageId: 'msg-1',
          userId: 'user-1',
        )).called(1);
        verifyNever(mockRemoteDataSource.markMessageAsRead(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
        ));
      });
    });

    group('getUnreadCount', () {
      test('should return unread count from local', () async {
        // Arrange
        when(mockLocalDataSource.getUnreadCount(
          tripId: anyNamed('tripId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => 5);

        // Act
        final count = await repository.getUnreadCount(
          tripId: 'trip-1',
          userId: 'user-1',
        );

        // Assert
        expect(count, 5);
      });

      test('should return 0 on error', () async {
        // Arrange
        when(mockLocalDataSource.getUnreadCount(
          tripId: anyNamed('tripId'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('Error'));

        // Act
        final count = await repository.getUnreadCount(
          tripId: 'trip-1',
          userId: 'user-1',
        );

        // Assert
        expect(count, 0);
      });
    });

    group('addReaction', () {
      test('should add reaction to cache and server', () async {
        // Arrange
        setupConnectivity(hasInternet: true);
        when(mockLocalDataSource.addReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        )).thenAnswer((_) async => {});
        when(mockRemoteDataSource.addReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        )).thenAnswer((_) async => {});

        // Act
        await repository.addReaction(
          messageId: 'msg-1',
          userId: 'user-1',
          emoji: '👍',
        );

        // Assert
        verify(mockLocalDataSource.addReaction(
          messageId: 'msg-1',
          userId: 'user-1',
          emoji: '👍',
        )).called(1);
        verify(mockRemoteDataSource.addReaction(
          messageId: 'msg-1',
          userId: 'user-1',
          emoji: '👍',
        )).called(1);
      });
    });

    group('removeReaction', () {
      test('should remove reaction from cache and server', () async {
        // Arrange
        setupConnectivity(hasInternet: true);
        when(mockLocalDataSource.removeReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        )).thenAnswer((_) async => {});
        when(mockRemoteDataSource.removeReaction(
          messageId: anyNamed('messageId'),
          userId: anyNamed('userId'),
          emoji: anyNamed('emoji'),
        )).thenAnswer((_) async => {});

        // Act
        await repository.removeReaction(
          messageId: 'msg-1',
          userId: 'user-1',
          emoji: '👍',
        );

        // Assert
        verify(mockLocalDataSource.removeReaction(
          messageId: 'msg-1',
          userId: 'user-1',
          emoji: '👍',
        )).called(1);
      });
    });

    group('getPendingMessages', () {
      test('should return pending messages from local', () async {
        // Arrange
        final pendingMessages = [
          createQueuedMessageModel(id: '1', tripId: 'trip-1', senderId: 'user-1'),
          createQueuedMessageModel(id: '2', tripId: 'trip-1', senderId: 'user-1'),
        ];
        when(mockLocalDataSource.getPendingMessages())
            .thenAnswer((_) async => pendingMessages);

        // Act
        final result = await repository.getPendingMessages();

        // Assert
        expect(result.length, 2);
      });

      test('should return empty list on error', () async {
        // Arrange
        when(mockLocalDataSource.getPendingMessages())
            .thenThrow(Exception('Error'));

        // Act
        final result = await repository.getPendingMessages();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('syncPendingMessages', () {
      test('should sync pending messages when online', () async {
        // Arrange
        setupConnectivity(hasInternet: true);
        final pendingMessages = [
          createQueuedMessageModel(id: '1', tripId: 'trip-1', senderId: 'user-1'),
        ];
        when(mockLocalDataSource.getPendingMessages())
            .thenAnswer((_) async => pendingMessages);
        when(mockLocalDataSource.updateQueueStatus(
          queueId: anyNamed('queueId'),
          status: anyNamed('status'),
          errorMessage: anyNamed('errorMessage'),
        )).thenAnswer((_) async => {});
        when(mockRemoteDataSource.sendMessage(any))
            .thenAnswer((_) async => createMessageModel(
                  id: 'msg-1',
                  tripId: 'trip-1',
                  senderId: 'user-1',
                  message: 'Test',
                ));
        when(mockLocalDataSource.removeFromQueue(any))
            .thenAnswer((_) async => {});

        // Act
        await repository.syncPendingMessages();

        // Assert
        verify(mockLocalDataSource.getPendingMessages()).called(greaterThan(0));
      });

      test('should not sync when offline', () async {
        // Arrange
        setupConnectivity(hasInternet: false);

        // Act
        await repository.syncPendingMessages();

        // Assert
        verifyNever(mockLocalDataSource.getPendingMessages());
      });
    });

    group('clearTripCache', () {
      test('should clear trip cache', () async {
        // Arrange
        when(mockLocalDataSource.clearTripCache(any))
            .thenAnswer((_) async => {});

        // Act
        await repository.clearTripCache('trip-1');

        // Assert
        verify(mockLocalDataSource.clearTripCache('trip-1')).called(1);
      });

      test('should throw exception on error', () async {
        // Arrange
        when(mockLocalDataSource.clearTripCache(any))
            .thenThrow(Exception('Clear failed'));

        // Act & Assert
        expect(
          () => repository.clearTripCache('trip-1'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to clear trip cache'),
          )),
        );
      });
    });

    group('clearAllCache', () {
      test('should clear all cache', () async {
        // Arrange
        when(mockLocalDataSource.clearAllCache())
            .thenAnswer((_) async => {});

        // Act
        await repository.clearAllCache();

        // Assert
        verify(mockLocalDataSource.clearAllCache()).called(1);
      });
    });

    group('getCacheSize', () {
      test('should return cache size', () async {
        // Arrange
        when(mockLocalDataSource.getCacheSize())
            .thenAnswer((_) async => 1024);

        // Act
        final size = await repository.getCacheSize();

        // Assert
        expect(size, 1024);
      });

      test('should return 0 on error', () async {
        // Arrange
        when(mockLocalDataSource.getCacheSize())
            .thenThrow(Exception('Error'));

        // Act
        final size = await repository.getCacheSize();

        // Assert
        expect(size, 0);
      });
    });

    group('Edge Cases', () {
      test('should handle connectivity check failure', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenThrow(Exception('Connectivity error'));
        when(mockLocalDataSource.saveMessage(any))
            .thenAnswer((_) async => {});
        when(mockLocalDataSource.queueMessage(any))
            .thenAnswer((_) async => {});

        // Act - should treat as offline
        final result = await repository.sendMessage(
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Test',
          messageType: MessageType.text,
        );

        // Assert - should queue message
        expect(result, isNotNull);
        verify(mockLocalDataSource.queueMessage(any)).called(1);
      });

      test('should handle large message content', () async {
        // Arrange
        setupConnectivity(hasInternet: true);
        final longMessage = 'A' * 10000;
        final serverMessage = createMessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: longMessage,
        );
        when(mockLocalDataSource.saveMessage(any))
            .thenAnswer((_) async => {});
        when(mockRemoteDataSource.sendMessage(any))
            .thenAnswer((_) async => serverMessage);

        // Act
        final result = await repository.sendMessage(
          tripId: 'trip-1',
          senderId: 'user-1',
          message: longMessage,
          messageType: MessageType.text,
        );

        // Assert
        expect(result.message?.length, 10000);
      });

      test('should handle message with emojis', () async {
        // Arrange
        setupConnectivity(hasInternet: true);
        final emojiMessage = '👋 Hello! 🎉 How are you? 😊';
        final serverMessage = createMessageModel(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: emojiMessage,
        );
        when(mockLocalDataSource.saveMessage(any))
            .thenAnswer((_) async => {});
        when(mockRemoteDataSource.sendMessage(any))
            .thenAnswer((_) async => serverMessage);

        // Act
        final result = await repository.sendMessage(
          tripId: 'trip-1',
          senderId: 'user-1',
          message: emojiMessage,
          messageType: MessageType.text,
        );

        // Assert
        expect(result.message, emojiMessage);
      });

      test('should handle multiple message types', () async {
        // Arrange
        setupConnectivity(hasInternet: true);
        when(mockLocalDataSource.saveMessage(any))
            .thenAnswer((_) async => {});

        for (final type in [MessageType.text, MessageType.image, MessageType.location, MessageType.expenseLink]) {
          final serverMessage = createMessageModel(
            id: 'msg-${type.name}',
            tripId: 'trip-1',
            senderId: 'user-1',
            message: 'Test',
            messageType: type.name,
          );
          when(mockRemoteDataSource.sendMessage(any))
              .thenAnswer((_) async => serverMessage);

          // Act
          final result = await repository.sendMessage(
            tripId: 'trip-1',
            senderId: 'user-1',
            message: 'Test',
            messageType: type,
          );

          // Assert
          expect(result, isNotNull);
        }
      });
    });
  });
}
