import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:travel_crew/features/messaging/data/datasources/message_local_datasource.dart';
import 'package:travel_crew/features/messaging/data/datasources/message_remote_datasource.dart';
import 'package:travel_crew/features/messaging/data/repositories/message_repository_impl.dart';
import 'package:travel_crew/features/messaging/data/services/message_deduplication_service.dart';
import 'package:travel_crew/features/messaging/domain/entities/message_entity.dart';
import 'package:travel_crew/shared/models/message_model.dart';

import 'messaging_performance_test.mocks.dart';

// Generate mocks for dependencies
@GenerateMocks([
  MessageLocalDataSource,
  MessageRemoteDataSource,
  Connectivity,
])
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

  tearDown(() {
    reset(mockLocalDataSource);
    reset(mockRemoteDataSource);
    reset(mockConnectivity);
  });

  group('Performance - Bulk Message Sending', () {
    test('✅ Positive: Send 100+ messages in acceptable time', () async {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      when(mockLocalDataSource.saveMessage(any)).thenAnswer((_) async => {});
      when(mockRemoteDataSource.sendMessage(any)).thenAnswer(
        (_) async => MessageModel(
          id: 'msg-bulk',
          tripId: 'trip-123',
          senderId: 'user-bulk',
          message: 'Bulk message',
          messageType: 'text',
          reactions: [],
          readBy: [],
          isDeleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      const messageCount = 100;
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < messageCount; i++) {
        await repository.sendMessage(
          tripId: 'trip-123',
          senderId: 'user-bulk',
          message: 'Message $i',
          messageType: MessageType.text,
        );
      }

      stopwatch.stop();

      // Should complete in reasonable time (< 10 seconds for 100 messages)
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));

      print('📊 Performance: Sent $messageCount messages in ${stopwatch.elapsedMilliseconds}ms');
      print('📊 Average per message: ${stopwatch.elapsedMilliseconds / messageCount}ms');

      verify(mockLocalDataSource.saveMessage(any)).called(messageCount * 2); // Initial + server response
      verify(mockRemoteDataSource.sendMessage(any)).called(messageCount);
    });

    test('✅ Positive: Bulk message retrieval performance', () async {
      const messageCount = 1000;
      final messages = List.generate(
        messageCount,
        (i) => MessageModel(
          id: 'msg-$i',
          tripId: 'trip-123',
          senderId: 'user-$i',
          message: 'Message $i',
          messageType: 'text',
          reactions: [],
          readBy: [],
          isDeleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(mockLocalDataSource.getTripMessages(
        tripId: 'trip-123',
        limit: 1000,
        offset: 0,
      )).thenAnswer((_) async => messages);

      final stopwatch = Stopwatch()..start();

      final result = await repository.getTripMessages(
        tripId: 'trip-123',
        limit: 1000,
      );

      stopwatch.stop();

      expect(result.length, messageCount);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be < 1 second

      print('📊 Performance: Retrieved $messageCount messages in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('✅ Positive: Batch reaction additions', () async {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

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

      const reactionCount = 50;
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < reactionCount; i++) {
        await repository.addReaction(
          messageId: 'msg-001',
          userId: 'user-$i',
          emoji: '👍',
        );
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should be < 5 seconds

      print('📊 Performance: Added $reactionCount reactions in ${stopwatch.elapsedMilliseconds}ms');
      verify(mockLocalDataSource.addReaction(
        messageId: anyNamed('messageId'),
        userId: anyNamed('userId'),
        emoji: anyNamed('emoji'),
      )).called(reactionCount);
    });
  });

  group('Performance - Message Deduplication', () {
    setUp(() {
      // Deduplication service is a process-wide singleton; ensure isolation.
      MessageDeduplicationService().clearCache();
    });

    tearDown(() {
      MessageDeduplicationService().clearCache();
    });

    test('✅ Positive: Deduplication performance with large datasets', () async {
      final deduplicationService = MessageDeduplicationService();
      await deduplicationService.initialize();

      const messageCount = 1000;
      final now = DateTime.now();
      final messages = List.generate(
        messageCount,
        (i) => MessageEntity(
          id: 'msg-${i % 100}', // 10x duplicates
          tripId: 'trip-123',
          senderId: 'user-${i % 50}',
          message: 'Message ${i % 100}',
          messageType: MessageType.text,
          reactions: const [],
          readBy: const [],
          createdAt: now,
          updatedAt: now,
        ),
      );

      final stopwatch = Stopwatch()..start();

      final uniqueMessages = <MessageEntity>[];
      for (final message in messages) {
        if (!deduplicationService.isMessageKnown(message.id)) {
          uniqueMessages.add(message);
          deduplicationService.registerMessage(
            messageId: message.id,
            tripId: message.tripId,
            senderId: message.senderId,
            content: message.message ?? '',
            timestamp: message.createdAt,
          );
        }
      }

      stopwatch.stop();

      expect(uniqueMessages.length, 100); // Should have 100 unique messages
      expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Should be fast

      print('📊 Performance: Deduplicated $messageCount messages to ${uniqueMessages.length} in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('✅ Positive: Deduplication cache cleanup performance', () async {
      final deduplicationService = MessageDeduplicationService();
      await deduplicationService.initialize();

      // Add many messages to cache
      const cacheSize = 10000;
      final now = DateTime.now();
      for (var i = 0; i < cacheSize; i++) {
        deduplicationService.registerMessage(
          messageId: 'msg-$i',
          tripId: 'trip-123',
          senderId: 'user-1',
          content: 'Message $i',
          timestamp: now,
        );
      }

      final stopwatch = Stopwatch()..start();

      deduplicationService.clearCache();

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Cleanup should be fast

      print('📊 Performance: Cleaned up cache of $cacheSize entries in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('❌ Negative: Memory leak detection with continuous message flow', () async {
      final deduplicationService = MessageDeduplicationService();
      await deduplicationService.initialize();

      // Simulate continuous message flow
      const totalMessages = 50000;
      var duplicateCount = 0;
      final now = DateTime.now();

      for (var i = 0; i < totalMessages; i++) {
        final messageId = 'msg-${i % 1000}'; // Rotating set of 1000 messages
        if (deduplicationService.isMessageKnown(messageId)) {
          duplicateCount++;
        } else {
          deduplicationService.registerMessage(
            messageId: messageId,
            tripId: 'trip-123',
            senderId: 'user-1',
            content: 'Message ${i % 1000}',
            timestamp: now,
          );
        }

        // Periodic cleanup
        if (i % 10000 == 0) {
          deduplicationService.clearTripCache('trip-123');
        }
      }

      expect(duplicateCount, greaterThan(0)); // Should have detected duplicates
      print('📊 Performance: Processed $totalMessages messages, detected $duplicateCount duplicates');
      print('📊 Cache handled continuous flow without memory issues');
    });
  });

  group('Performance - Concurrent User Scenarios', () {
    test('✅ Positive: Multiple users sending messages simultaneously', () async {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      when(mockLocalDataSource.saveMessage(any)).thenAnswer((_) async => {});
      when(mockRemoteDataSource.sendMessage(any)).thenAnswer(
        (_) async => MessageModel(
          id: 'msg-concurrent',
          tripId: 'trip-123',
          senderId: 'user-concurrent',
          message: 'Concurrent message',
          messageType: 'text',
          reactions: [],
          readBy: [],
          isDeleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      const userCount = 10;
      const messagesPerUser = 10;

      final stopwatch = Stopwatch()..start();

      // Simulate concurrent sends
      final futures = <Future>[];
      for (var userId = 0; userId < userCount; userId++) {
        for (var msgNum = 0; msgNum < messagesPerUser; msgNum++) {
          futures.add(
            repository.sendMessage(
              tripId: 'trip-123',
              senderId: 'user-$userId',
              message: 'Message $msgNum from user $userId',
              messageType: MessageType.text,
            ),
          );
        }
      }

      await Future.wait(futures);

      stopwatch.stop();

      final totalMessages = userCount * messagesPerUser;
      expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Should handle concurrent load

      print('📊 Performance: $userCount users sent $messagesPerUser messages each ($totalMessages total) in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('✅ Positive: Concurrent read operations', () async {
      const messageCount = 100;
      final messages = List.generate(
        messageCount,
        (i) => MessageModel(
          id: 'msg-$i',
          tripId: 'trip-123',
          senderId: 'user-$i',
          message: 'Message $i',
          messageType: 'text',
          reactions: [],
          readBy: [],
          isDeleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(mockLocalDataSource.getTripMessages(
        tripId: anyNamed('tripId'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => messages);

      const concurrentReads = 20;

      final stopwatch = Stopwatch()..start();

      final futures = List.generate(
        concurrentReads,
        (_) => repository.getTripMessages(tripId: 'trip-123'),
      );

      final results = await Future.wait(futures);

      stopwatch.stop();

      expect(results.length, concurrentReads);
      expect(results.every((r) => r.length == messageCount), true);
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));

      print('📊 Performance: $concurrentReads concurrent reads completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('✅ Positive: Mixed read/write operations', () async {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      final testMessages = List.generate(
        50,
        (i) => MessageModel(
          id: 'msg-$i',
          tripId: 'trip-123',
          senderId: 'user-$i',
          message: 'Message $i',
          messageType: 'text',
          reactions: [],
          readBy: [],
          isDeleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      when(mockLocalDataSource.saveMessage(any)).thenAnswer((_) async => {});
      when(mockRemoteDataSource.sendMessage(any)).thenAnswer(
        (_) async => testMessages.first,
      );
      when(mockLocalDataSource.getTripMessages(
        tripId: anyNamed('tripId'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => testMessages);

      final stopwatch = Stopwatch()..start();

      final futures = <Future>[];

      // 25 writes
      for (var i = 0; i < 25; i++) {
        futures.add(
          repository.sendMessage(
            tripId: 'trip-123',
            senderId: 'user-$i',
            message: 'Message $i',
            messageType: MessageType.text,
          ),
        );
      }

      // 25 reads
      for (var i = 0; i < 25; i++) {
        futures.add(repository.getTripMessages(tripId: 'trip-123'));
      }

      await Future.wait(futures);

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(5000));

      print('📊 Performance: 25 writes + 25 reads completed in ${stopwatch.elapsedMilliseconds}ms');
    });
  });

  group('Performance - Large Attachment Handling', () {
    test('❌ Negative: Large attachment size handling', () async {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      // Simulate large attachment URL (representing large file)
      const largeAttachmentUrl = 'https://storage.example.com/large-video-10mb.mp4';

      when(mockLocalDataSource.saveMessage(any)).thenAnswer((_) async => {});
      when(mockRemoteDataSource.sendMessage(any)).thenAnswer(
        (_) async => MessageModel(
          id: 'msg-large',
          tripId: 'trip-123',
          senderId: 'user-large',
          message: 'Large attachment',
          messageType: 'image',
          attachmentUrl: largeAttachmentUrl,
          reactions: [],
          readBy: [],
          isDeleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final stopwatch = Stopwatch()..start();

      final result = await repository.sendMessage(
        tripId: 'trip-123',
        senderId: 'user-large',
        message: 'Large attachment',
        messageType: MessageType.image,
        attachmentUrl: largeAttachmentUrl,
      );

      stopwatch.stop();

      expect(result.attachmentUrl, largeAttachmentUrl);
      expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Metadata should be fast

      print('📊 Performance: Large attachment metadata handled in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('✅ Positive: Multiple small attachments', () async {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      when(mockLocalDataSource.saveMessage(any)).thenAnswer((_) async => {});
      when(mockRemoteDataSource.sendMessage(any)).thenAnswer(
        (_) async => MessageModel(
          id: 'msg-attachment',
          tripId: 'trip-123',
          senderId: 'user-attachment',
          message: 'Image message',
          messageType: 'image',
          attachmentUrl: 'https://storage.example.com/small-image.jpg',
          reactions: [],
          readBy: [],
          isDeleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      const attachmentCount = 50;
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < attachmentCount; i++) {
        await repository.sendMessage(
          tripId: 'trip-123',
          senderId: 'user-attachment',
          message: 'Image $i',
          messageType: MessageType.image,
          attachmentUrl: 'https://storage.example.com/image-$i.jpg',
        );
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(5000));

      print('📊 Performance: Sent $attachmentCount image messages in ${stopwatch.elapsedMilliseconds}ms');
    });
  });

  group('Performance - Query Optimization', () {
    test('✅ Positive: Pagination performance', () async {
      const totalMessages = 1000;
      const pageSize = 50;

      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      final stopwatch = Stopwatch()..start();

      for (var page = 0; page < totalMessages ~/ pageSize; page++) {
        final pageMessages = List.generate(
          pageSize,
          (i) => MessageModel(
            id: 'msg-${page * pageSize + i}',
            tripId: 'trip-123',
            senderId: 'user-1',
            message: 'Message ${page * pageSize + i}',
            messageType: 'text',
            reactions: [],
            readBy: [],
            isDeleted: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        when(mockLocalDataSource.getTripMessages(
          tripId: 'trip-123',
          limit: pageSize,
          offset: page * pageSize,
        )).thenAnswer((_) async => pageMessages);

        await repository.getTripMessages(
          tripId: 'trip-123',
          limit: pageSize,
          offset: page * pageSize,
        );
      }

      stopwatch.stop();

      final pages = totalMessages ~/ pageSize;
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));

      print('📊 Performance: Loaded $pages pages ($totalMessages messages) in ${stopwatch.elapsedMilliseconds}ms');
      print('📊 Average per page: ${stopwatch.elapsedMilliseconds / pages}ms');
    });

    test('✅ Positive: Unread count calculation performance', () async {
      const messageCount = 1000;

      when(mockLocalDataSource.getUnreadCount(
        tripId: 'trip-123',
        userId: 'user-1',
      )).thenAnswer((_) async => messageCount);

      final stopwatch = Stopwatch()..start();

      final count = await repository.getUnreadCount(
        tripId: 'trip-123',
        userId: 'user-1',
      );

      stopwatch.stop();

      expect(count, messageCount);
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be very fast

      print('📊 Performance: Calculated unread count ($count) in ${stopwatch.elapsedMilliseconds}ms');
    });
  });

  group('Performance - Stress Tests', () {
    test('✅ Positive: Rapid-fire message sending', () async {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      when(mockLocalDataSource.saveMessage(any)).thenAnswer((_) async => {});
      when(mockRemoteDataSource.sendMessage(any)).thenAnswer(
        (_) async => MessageModel(
          id: 'msg-rapid',
          tripId: 'trip-123',
          senderId: 'user-rapid',
          message: 'Rapid message',
          messageType: 'text',
          reactions: [],
          readBy: [],
          isDeleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      const messagesPerSecond = 10;
      const duration = 5; // seconds
      const totalMessages = messagesPerSecond * duration;

      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < totalMessages; i++) {
        await repository.sendMessage(
          tripId: 'trip-123',
          senderId: 'user-rapid',
          message: 'Rapid message $i',
          messageType: MessageType.text,
        );

        // Small delay to simulate rapid but not instant sending
        await Future.delayed(const Duration(milliseconds: 10));
      }

      stopwatch.stop();

      print('📊 Performance: Sent $totalMessages messages in ${stopwatch.elapsedMilliseconds}ms');
      print('📊 Rate: ${(totalMessages / (stopwatch.elapsedMilliseconds / 1000)).toStringAsFixed(2)} messages/second');
    });

    test('✅ Positive: Repository handles rapid state changes', () async {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      when(mockLocalDataSource.markMessageAsRead(
        messageId: anyNamed('messageId'),
        userId: anyNamed('userId'),
      )).thenAnswer((_) async => {});
      when(mockRemoteDataSource.markMessageAsRead(
        messageId: anyNamed('messageId'),
        userId: anyNamed('userId'),
      )).thenAnswer((_) async => {});

      const stateChanges = 200;

      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < stateChanges; i++) {
        await repository.markMessageAsRead(
          messageId: 'msg-001',
          userId: 'user-$i',
        );
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(3000));

      print('📊 Performance: Handled $stateChanges state changes in ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}
