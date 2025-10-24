import 'package:flutter_test/flutter_test.dart';
import 'package:travel_companion/features/messaging/data/services/message_deduplication_service.dart';
import 'package:travel_companion/features/messaging/data/services/priority_sync_queue.dart';
import 'package:travel_companion/features/messaging/data/services/conflict_resolution_engine.dart';
import 'package:travel_companion/features/messaging/data/services/sync_coordinator.dart';
import 'package:travel_companion/features/messaging/domain/entities/message_entity.dart';

/// Integration tests for Hybrid Sync Strategy
/// Tests the interaction between all sync components
void main() {
  group('Hybrid Sync Integration Tests', () {
    late SyncCoordinator coordinator;
    late MessageDeduplicationService deduplicationService;
    late PrioritySyncQueue syncQueue;
    late ConflictResolutionEngine conflictEngine;

    setUp(() async {
      deduplicationService = MessageDeduplicationService();
      syncQueue = PrioritySyncQueue();
      conflictEngine = ConflictResolutionEngine();
      coordinator = SyncCoordinator();

      await deduplicationService.initialize();
      await conflictEngine.initialize();
      await coordinator.initialize();
    });

    tearDown(() {
      deduplicationService.dispose();
      syncQueue.dispose();
      coordinator.dispose();
    });

    group('Message Flow Integration', () {
      test('should handle complete message sync flow from multiple sources',
          () async {
        // Simulate message from server
        final serverMessage = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Hello from server',
          messageType: MessageType.text,
          timestamp: DateTime.now(),
          reactions: [],
          readBy: [],
        );

        // Sync from server
        final serverResult = await coordinator.syncMessage(
          message: serverMessage,
          source: 'server',
          priority: SyncPriority.high,
        );

        expect(serverResult.status, SyncStatus.queued);
        expect(serverResult.taskId, isNotNull);

        // Same message arrives from BLE (should be detected as duplicate)
        final bleResult = await coordinator.syncMessage(
          message: serverMessage,
          source: 'ble',
          priority: SyncPriority.medium,
        );

        expect(bleResult.status, SyncStatus.duplicate);
        expect(bleResult.duplicateOf, 'msg-1');

        // Verify deduplication stats
        final dedupStats = coordinator.getStatistics().deduplicationStats;
        expect(dedupStats.uniqueMessages, 1);
        expect(dedupStats.duplicatesFound, 1);
      });

      test('should sync batch of messages and detect duplicates', () async {
        final messages = [
          MessageEntity(
            id: 'msg-1',
            tripId: 'trip-1',
            senderId: 'user-1',
            message: 'Message 1',
            messageType: MessageType.text,
            timestamp: DateTime.now(),
            reactions: [],
            readBy: [],
          ),
          MessageEntity(
            id: 'msg-2',
            tripId: 'trip-1',
            senderId: 'user-1',
            message: 'Message 2',
            messageType: MessageType.text,
            timestamp: DateTime.now(),
            reactions: [],
            readBy: [],
          ),
          MessageEntity(
            id: 'msg-3',
            tripId: 'trip-1',
            senderId: 'user-1',
            message: 'Message 1', // Duplicate content
            messageType: MessageType.text,
            timestamp: DateTime.now(),
            reactions: [],
            readBy: [],
          ),
        ];

        final result = await coordinator.syncBatch(
          messages: messages,
          source: 'server',
          priority: SyncPriority.low,
        );

        expect(result.total, 3);
        expect(result.queued, 2); // msg-1 and msg-2
        expect(result.duplicates, 1); // msg-3 is duplicate of msg-1
        expect(result.errors, 0);
        expect(result.successRate, greaterThan(0.5));
      });
    });

    group('Conflict Resolution Integration', () {
      test('should resolve conflict using timestamp (LWW)', () async {
        final now = DateTime.now();
        final earlier = now.subtract(const Duration(hours: 1));

        // Local version (older)
        final localMessage = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Old version',
          messageType: MessageType.text,
          timestamp: earlier,
          reactions: [],
          readBy: ['user-1'],
        );

        // Remote version (newer)
        final remoteMessage = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'New version',
          messageType: MessageType.text,
          timestamp: now,
          reactions: [
            MessageReaction(
              userId: 'user-2',
              emoji: '👍',
              createdAt: now,
            ),
          ],
          readBy: ['user-1', 'user-2'],
        );

        final resolved = await coordinator.handleIncomingMessage(
          remoteMessage: remoteMessage,
          localMessage: localMessage,
          source: 'server',
        );

        // Should pick remote version (newer)
        expect(resolved.message, 'New version');
        expect(resolved.timestamp, now);

        // But should merge reactions and readBy
        expect(resolved.reactions.length, 1);
        expect(resolved.readBy.length, 2);
      });

      test('should resolve conflict using source priority', () async {
        final timestamp = DateTime.now();

        // BLE message
        final bleMessage = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'BLE version',
          messageType: MessageType.text,
          timestamp: timestamp,
          reactions: [],
          readBy: [],
        );

        // Server message (same timestamp)
        final serverMessage = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Server version',
          messageType: MessageType.text,
          timestamp: timestamp,
          reactions: [],
          readBy: [],
        );

        final resolved = await coordinator.handleIncomingMessage(
          remoteMessage: serverMessage,
          localMessage: bleMessage,
          source: 'server', // Server has higher priority
        );

        // Should pick server version due to source priority
        expect(resolved.message, 'Server version');
      });

      test('should merge reactions from multiple sources', () async {
        final timestamp = DateTime.now();

        final localMessage = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Hello',
          messageType: MessageType.text,
          timestamp: timestamp,
          reactions: [
            MessageReaction(
              userId: 'user-1',
              emoji: '👍',
              createdAt: timestamp,
            ),
            MessageReaction(
              userId: 'user-2',
              emoji: '❤️',
              createdAt: timestamp,
            ),
          ],
          readBy: [],
        );

        final remoteMessage = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Hello',
          messageType: MessageType.text,
          timestamp: timestamp,
          reactions: [
            MessageReaction(
              userId: 'user-2',
              emoji: '❤️',
              createdAt: timestamp,
            ),
            MessageReaction(
              userId: 'user-3',
              emoji: '😂',
              createdAt: timestamp,
            ),
          ],
          readBy: [],
        );

        final resolved = await coordinator.handleIncomingMessage(
          remoteMessage: remoteMessage,
          localMessage: localMessage,
          source: 'server',
        );

        // Should have all unique reactions merged
        expect(resolved.reactions.length, 3);
        expect(
            resolved.reactions.any((r) => r.userId == 'user-1' && r.emoji == '👍'),
            true);
        expect(
            resolved.reactions.any((r) => r.userId == 'user-2' && r.emoji == '❤️'),
            true);
        expect(
            resolved.reactions.any((r) => r.userId == 'user-3' && r.emoji == '😂'),
            true);
      });
    });

    group('Multi-Source Sync Integration', () {
      test('should handle messages from all sources (Server, BLE, WiFi, Multipeer)',
          () async {
        final timestamp = DateTime.now();

        // Register all sync sources
        coordinator.registerSyncSource(SyncSource(
          name: 'server',
          isEnabled: true,
        ));
        coordinator.registerSyncSource(SyncSource(
          name: 'ble',
          isEnabled: true,
        ));
        coordinator.registerSyncSource(SyncSource(
          name: 'wifi_direct',
          isEnabled: true,
        ));
        coordinator.registerSyncSource(SyncSource(
          name: 'multipeer',
          isEnabled: true,
        ));

        // Create messages from different sources
        final messages = [
          MessageEntity(
            id: 'msg-server',
            tripId: 'trip-1',
            senderId: 'user-1',
            message: 'From server',
            messageType: MessageType.text,
            timestamp: timestamp,
            reactions: [],
            readBy: [],
          ),
          MessageEntity(
            id: 'msg-ble',
            tripId: 'trip-1',
            senderId: 'user-2',
            message: 'From BLE',
            messageType: MessageType.text,
            timestamp: timestamp,
            reactions: [],
            readBy: [],
          ),
          MessageEntity(
            id: 'msg-wifi',
            tripId: 'trip-1',
            senderId: 'user-3',
            message: 'From WiFi Direct',
            messageType: MessageType.text,
            timestamp: timestamp,
            reactions: [],
            readBy: [],
          ),
          MessageEntity(
            id: 'msg-multipeer',
            tripId: 'trip-1',
            senderId: 'user-4',
            message: 'From Multipeer',
            messageType: MessageType.text,
            timestamp: timestamp,
            reactions: [],
            readBy: [],
          ),
        ];

        // Sync from different sources
        await coordinator.syncMessage(
            message: messages[0], source: 'server', priority: SyncPriority.high);
        await coordinator.syncMessage(
            message: messages[1], source: 'ble', priority: SyncPriority.medium);
        await coordinator.syncMessage(
            message: messages[2], source: 'wifi_direct', priority: SyncPriority.medium);
        await coordinator.syncMessage(
            message: messages[3], source: 'multipeer', priority: SyncPriority.low);

        final stats = coordinator.getStatistics();
        expect(stats.deduplicationStats.uniqueMessages, 4);
        expect(stats.queueStats.totalTasksQueued, 4);
      });

      test('should handle same message arriving from multiple sources', () async {
        final message = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Broadcasted message',
          messageType: MessageType.text,
          timestamp: DateTime.now(),
          reactions: [],
          readBy: [],
        );

        // Message arrives from BLE first
        final bleResult = await coordinator.syncMessage(
          message: message,
          source: 'ble',
          priority: SyncPriority.high,
        );
        expect(bleResult.status, SyncStatus.queued);

        // Same message arrives from WiFi Direct
        final wifiResult = await coordinator.syncMessage(
          message: message,
          source: 'wifi_direct',
          priority: SyncPriority.high,
        );
        expect(wifiResult.status, SyncStatus.duplicate);

        // Same message arrives from Server
        final serverResult = await coordinator.syncMessage(
          message: message,
          source: 'server',
          priority: SyncPriority.high,
        );
        expect(serverResult.status, SyncStatus.duplicate);

        // Verify only one unique message
        final stats = coordinator.getStatistics();
        expect(stats.deduplicationStats.uniqueMessages, 1);
        expect(stats.deduplicationStats.duplicatesFound, 2);
      });
    });

    group('Priority Queue Integration', () {
      test('should process high priority messages before low priority', () async {
        final lowPriorityMessage = MessageEntity(
          id: 'msg-low',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Low priority',
          messageType: MessageType.text,
          timestamp: DateTime.now(),
          reactions: [],
          readBy: [],
        );

        final highPriorityMessage = MessageEntity(
          id: 'msg-high',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'High priority',
          messageType: MessageType.text,
          timestamp: DateTime.now(),
          reactions: [],
          readBy: [],
        );

        // Queue low priority first
        await coordinator.syncMessage(
          message: lowPriorityMessage,
          source: 'server',
          priority: SyncPriority.low,
        );

        // Queue high priority second
        await coordinator.syncMessage(
          message: highPriorityMessage,
          source: 'server',
          priority: SyncPriority.high,
        );

        final queueStats = coordinator.getStatistics().queueStats;
        expect(queueStats.highPriorityCount, 1);
        expect(queueStats.lowPriorityCount, 1);
        expect(queueStats.totalQueueSize, 2);
      });

      test('should handle queue pause and resume', () async {
        final message = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Test message',
          messageType: MessageType.text,
          timestamp: DateTime.now(),
          reactions: [],
          readBy: [],
        );

        await coordinator.syncMessage(
          message: message,
          source: 'server',
          priority: SyncPriority.medium,
        );

        // Pause queue
        syncQueue.pause();
        expect(syncQueue.isPaused, true);

        // Resume queue
        syncQueue.resume();
        expect(syncQueue.isPaused, false);
      });
    });

    group('Statistics Tracking Integration', () {
      test('should track comprehensive statistics across all operations',
          () async {
        // Sync some messages
        final message1 = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Message 1',
          messageType: MessageType.text,
          timestamp: DateTime.now(),
          reactions: [],
          readBy: [],
        );

        final message2 = MessageEntity(
          id: 'msg-2',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Message 1', // Duplicate
          messageType: MessageType.text,
          timestamp: DateTime.now(),
          reactions: [],
          readBy: [],
        );

        await coordinator.syncMessage(
            message: message1, source: 'server', priority: SyncPriority.high);
        await coordinator.syncMessage(
            message: message2, source: 'ble', priority: SyncPriority.high);

        // Create a conflict
        final now = DateTime.now();
        final earlier = now.subtract(const Duration(hours: 1));

        final localMessage = MessageEntity(
          id: 'msg-3',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Old',
          messageType: MessageType.text,
          timestamp: earlier,
          reactions: [],
          readBy: [],
        );

        final remoteMessage = MessageEntity(
          id: 'msg-3',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'New',
          messageType: MessageType.text,
          timestamp: now,
          reactions: [],
          readBy: [],
        );

        await coordinator.handleIncomingMessage(
          remoteMessage: remoteMessage,
          localMessage: localMessage,
          source: 'server',
        );

        // Check comprehensive stats
        final stats = coordinator.getStatistics();

        // Deduplication stats
        expect(stats.deduplicationStats.totalChecks, greaterThan(0));
        expect(stats.deduplicationStats.uniqueMessages, greaterThan(0));
        expect(stats.deduplicationStats.duplicatesFound, greaterThan(0));

        // Queue stats
        expect(stats.queueStats.totalTasksQueued, greaterThan(0));

        // Conflict stats
        expect(stats.conflictStats.totalConflicts, greaterThan(0));
        expect(stats.conflictStats.resolvedByTimestamp, greaterThan(0));
      });

      test('should calculate efficiency correctly', () async {
        final messages = List.generate(
          10,
          (i) => MessageEntity(
            id: 'msg-$i',
            tripId: 'trip-1',
            senderId: 'user-1',
            message: 'Message $i',
            messageType: MessageType.text,
            timestamp: DateTime.now(),
            reactions: [],
            readBy: [],
          ),
        );

        // Sync all messages
        for (final message in messages) {
          await coordinator.syncMessage(
            message: message,
            source: 'server',
            priority: SyncPriority.medium,
          );
        }

        final stats = coordinator.getStatistics();
        expect(stats.overallEfficiency, greaterThan(0.0));
        expect(stats.overallEfficiency, lessThanOrEqualTo(1.0));
      });
    });

    group('Error Handling Integration', () {
      test('should handle sync errors gracefully', () async {
        final message = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Test',
          messageType: MessageType.text,
          timestamp: DateTime.now(),
          reactions: [],
          readBy: [],
        );

        // Register a failing sync source
        coordinator.registerSyncSource(SyncSource(
          name: 'failing_source',
          isEnabled: true,
          syncHandler: (msg) async {
            throw Exception('Sync failed');
          },
        ));

        // Should not throw, should handle error gracefully
        final result = await coordinator.syncMessage(
          message: message,
          source: 'failing_source',
          priority: SyncPriority.high,
        );

        expect(result, isNotNull);
      });
    });

    group('Cleanup Integration', () {
      test('should clear trip sync data', () async {
        final message1 = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Trip 1 message',
          messageType: MessageType.text,
          timestamp: DateTime.now(),
          reactions: [],
          readBy: [],
        );

        final message2 = MessageEntity(
          id: 'msg-2',
          tripId: 'trip-2',
          senderId: 'user-1',
          message: 'Trip 2 message',
          messageType: MessageType.text,
          timestamp: DateTime.now(),
          reactions: [],
          readBy: [],
        );

        await coordinator.syncMessage(
            message: message1, source: 'server', priority: SyncPriority.high);
        await coordinator.syncMessage(
            message: message2, source: 'server', priority: SyncPriority.high);

        // Clear trip 1
        coordinator.clearTripSync('trip-1');

        // Message 1 should now be treated as new
        final result = await coordinator.syncMessage(
          message: message1,
          source: 'server',
          priority: SyncPriority.high,
        );

        expect(result.status, SyncStatus.queued); // Not duplicate anymore
      });

      test('should reset all statistics', () async {
        final message = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Test',
          messageType: MessageType.text,
          timestamp: DateTime.now(),
          reactions: [],
          readBy: [],
        );

        await coordinator.syncMessage(
            message: message, source: 'server', priority: SyncPriority.high);

        coordinator.resetStatistics();

        final stats = coordinator.getStatistics();
        expect(stats.deduplicationStats.totalChecks, 0);
        expect(stats.deduplicationStats.uniqueMessages, 0);
        expect(stats.queueStats.totalTasksQueued, 0);
      });
    });
  });
}
