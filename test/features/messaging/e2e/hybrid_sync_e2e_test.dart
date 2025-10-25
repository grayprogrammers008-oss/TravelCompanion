import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/messaging/data/services/sync_coordinator.dart';
import 'package:travel_crew/features/messaging/data/services/priority_sync_queue.dart';
import 'package:travel_crew/features/messaging/domain/entities/message_entity.dart';

/// End-to-End tests for Hybrid Sync Strategy
/// Tests complete workflows from start to finish
void main() {
  group('Hybrid Sync E2E Tests', () {
    late SyncCoordinator coordinator;

    setUp(() async {
      coordinator = SyncCoordinator();
      await coordinator.initialize();
    });

    tearDown(() {
      coordinator.dispose();
    });

    group('Complete Sync Workflow', () {
      testWidgets('E2E: User sends message that syncs across all sources',
          (tester) async {
        // Step 1: User creates a message locally
        final userMessage = MessageEntity(
          id: 'msg-user-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Hello everyone!',
          messageType: MessageType.text,
          createdAt: DateTime.now(),

          updatedAt: DateTime.now(),
          reactions: [],
          readBy: ['user-1'],
        );

        // Step 2: Sync to server (high priority - user action)
        final serverSyncResult = await coordinator.syncMessage(
          message: userMessage,
          source: 'local',
          priority: SyncPriority.high,
        );

        expect(serverSyncResult.status, SyncStatus.queued);
        expect(serverSyncResult.taskId, isNotNull);

        // Step 3: Message gets broadcasted via BLE
        final bleResult = await coordinator.syncMessage(
          message: userMessage,
          source: 'ble',
          priority: SyncPriority.medium,
        );

        // Should detect as duplicate
        expect(bleResult.status, SyncStatus.duplicate);

        // Step 4: Message arrives back from server with read status
        final serverMessage = userMessage.copyWith(
          readBy: ['user-1', 'user-2'], // User 2 read it
        );

        final resolvedMessage = await coordinator.handleIncomingMessage(
          remoteMessage: serverMessage,
          localMessage: userMessage,
          source: 'server',
        );

        // Should merge read status
        expect(resolvedMessage.readBy.length, 2);
        expect(resolvedMessage.readBy.contains('user-2'), true);

        // Step 5: Another user adds reaction via WiFi Direct
        final wifiMessage = resolvedMessage.copyWith(
          reactions: [
            MessageReaction(
              userId: 'user-3',
              emoji: '👍',
              createdAt: DateTime.now(),
            ),
          ],
        );

        final finalMessage = await coordinator.handleIncomingMessage(
          remoteMessage: wifiMessage,
          localMessage: resolvedMessage,
          source: 'wifi_direct',
        );

        // Should have reaction
        expect(finalMessage.reactions.length, 1);
        expect(finalMessage.reactions[0].userId, 'user-3');

        // Verify statistics
        final stats = coordinator.getStatistics();
        expect(stats.deduplicationStats.uniqueMessages, 1);
        expect(stats.deduplicationStats.duplicatesFound, 1);
        expect(stats.conflictStats.totalConflicts, greaterThanOrEqualTo(2));
      });

      testWidgets('E2E: Offline message sync when back online',
          (tester) async {
        // Scenario: User sends messages while offline, then syncs when online

        // Step 1: Create multiple offline messages
        final offlineMessages = List.generate(
          5,
          (i) => MessageEntity(
            id: 'offline-msg-$i',
            tripId: 'trip-1',
            senderId: 'user-1',
            message: 'Offline message $i',
            messageType: MessageType.text,
            createdAt: DateTime.now().add(Duration(seconds: i)),

            updatedAt: DateTime.now().add(Duration(seconds: i)),
            reactions: [],
            readBy: ['user-1'],
          ),
        );

        // Step 2: Queue all messages for sync (low priority - background)
        final batchResult = await coordinator.syncBatch(
          messages: offlineMessages,
          source: 'local',
          priority: SyncPriority.low,
        );

        expect(batchResult.total, 5);
        expect(batchResult.queued, 5);
        expect(batchResult.duplicates, 0);
        expect(batchResult.successRate, 1.0);

        // Step 3: Simulate coming back online - messages sync to server
        // (In real implementation, sync handlers would execute)

        // Verify all messages are queued
        final queueStats = coordinator.getStatistics().queueStats;
        expect(queueStats.totalTasksQueued, 5);
      });

      testWidgets('E2E: Multiple users editing same message (conflict)',
          (tester) async {
        // Scenario: Two users react to same message simultaneously

        final originalMessage = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Original message',
          messageType: MessageType.text,
          createdAt: DateTime.now(),

          updatedAt: DateTime.now(),
          reactions: [],
          readBy: [],
        );

        // Initial sync
        await coordinator.syncMessage(
          message: originalMessage,
          source: 'server',
          priority: SyncPriority.high,
        );

        // User 2 adds reaction (arrives via BLE)
        final user2Version = originalMessage.copyWith(
          reactions: [
            MessageReaction(
              userId: 'user-2',
              emoji: '❤️',
              createdAt: DateTime.now(),
            ),
          ],
        );

        final resolved1 = await coordinator.handleIncomingMessage(
          remoteMessage: user2Version,
          localMessage: originalMessage,
          source: 'ble',
        );

        expect(resolved1.reactions.length, 1);

        // User 3 adds reaction (arrives via WiFi)
        final user3Version = originalMessage.copyWith(
          reactions: [
            MessageReaction(
              userId: 'user-3',
              emoji: '👍',
              createdAt: DateTime.now(),
            ),
          ],
        );

        final resolved2 = await coordinator.handleIncomingMessage(
          remoteMessage: user3Version,
          localMessage: resolved1,
          source: 'wifi_direct',
        );

        // Should merge both reactions
        expect(resolved2.reactions.length, 2);
        expect(
            resolved2.reactions.any((r) => r.userId == 'user-2' && r.emoji == '❤️'),
            true);
        expect(
            resolved2.reactions.any((r) => r.userId == 'user-3' && r.emoji == '👍'),
            true);

        // Verify conflict resolution stats
        final stats = coordinator.getStatistics();
        expect(stats.conflictStats.totalConflicts, greaterThan(0));
      });
    });

    group('Real-World Scenarios', () {
      testWidgets('E2E: Group chat with 4 users on different networks',
          (tester) async {
        // Scenario: 4 users in a trip, each on different connection type

        // User 1: Connected via Server only
        final user1Message = MessageEntity(
          id: 'msg-u1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Hello from server',
          messageType: MessageType.text,
          createdAt: DateTime.now(),

          updatedAt: DateTime.now(),
          reactions: [],
          readBy: ['user-1'],
        );

        await coordinator.syncMessage(
          message: user1Message,
          source: 'server',
          priority: SyncPriority.high,
        );

        // User 2: Connected via BLE
        final user2Message = MessageEntity(
          id: 'msg-u2',
          tripId: 'trip-1',
          senderId: 'user-2',
          message: 'Hello from BLE',
          messageType: MessageType.text,
          createdAt: DateTime.now(),

          updatedAt: DateTime.now(),
          reactions: [],
          readBy: ['user-2'],
        );

        await coordinator.syncMessage(
          message: user2Message,
          source: 'ble',
          priority: SyncPriority.medium,
        );

        // User 3: Connected via WiFi Direct
        final user3Message = MessageEntity(
          id: 'msg-u3',
          tripId: 'trip-1',
          senderId: 'user-3',
          message: 'Hello from WiFi',
          messageType: MessageType.text,
          createdAt: DateTime.now(),

          updatedAt: DateTime.now(),
          reactions: [],
          readBy: ['user-3'],
        );

        await coordinator.syncMessage(
          message: user3Message,
          source: 'wifi_direct',
          priority: SyncPriority.medium,
        );

        // User 4: Connected via Multipeer (iOS)
        final user4Message = MessageEntity(
          id: 'msg-u4',
          tripId: 'trip-1',
          senderId: 'user-4',
          message: 'Hello from Multipeer',
          messageType: MessageType.text,
          createdAt: DateTime.now(),

          updatedAt: DateTime.now(),
          reactions: [],
          readBy: ['user-4'],
        );

        await coordinator.syncMessage(
          message: user4Message,
          source: 'multipeer',
          priority: SyncPriority.low,
        );

        // All messages should be unique
        final stats = coordinator.getStatistics();
        expect(stats.deduplicationStats.uniqueMessages, 4);

        // Messages from all sources should be queued
        expect(stats.queueStats.totalTasksQueued, 4);
      });

      testWidgets('E2E: Network switching during active conversation',
          (tester) async {
        // Scenario: User switches from WiFi to Cellular mid-conversation

        final message1 = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Message via WiFi',
          messageType: MessageType.text,
          createdAt: DateTime.now(),

          updatedAt: DateTime.now(),
          reactions: [],
          readBy: [],
        );

        // Send via WiFi Direct
        await coordinator.syncMessage(
          message: message1,
          source: 'wifi_direct',
          priority: SyncPriority.high,
        );

        // Network switches to cellular (server only)
        final message2 = MessageEntity(
          id: 'msg-2',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Message via Cellular',
          messageType: MessageType.text,
          createdAt: DateTime.now(),

          updatedAt: DateTime.now(),
          reactions: [],
          readBy: [],
        );

        await coordinator.syncMessage(
          message: message2,
          source: 'server',
          priority: SyncPriority.high,
        );

        // Both messages should be synced successfully
        final stats = coordinator.getStatistics();
        expect(stats.deduplicationStats.uniqueMessages, 2);
      });

      testWidgets('E2E: High-volume message burst handling', (tester) async {
        // Scenario: 50 messages arrive simultaneously from different sources

        final messages = <MessageEntity>[];
        for (int i = 0; i < 50; i++) {
          messages.add(MessageEntity(
            id: 'msg-$i',
            tripId: 'trip-1',
            senderId: 'user-${i % 4 + 1}', // 4 different users
            message: 'Message $i',
            messageType: MessageType.text,
            createdAt: DateTime.now().add(Duration(milliseconds: i)),

            updatedAt: DateTime.now().add(Duration(milliseconds: i)),
            reactions: [],
            readBy: [],
          ));
        }

        // Sync in batches from different sources
        final batch1 = messages.sublist(0, 20);
        final batch2 = messages.sublist(20, 40);
        final batch3 = messages.sublist(40, 50);

        final result1 = await coordinator.syncBatch(
          messages: batch1,
          source: 'server',
          priority: SyncPriority.high,
        );

        final result2 = await coordinator.syncBatch(
          messages: batch2,
          source: 'ble',
          priority: SyncPriority.medium,
        );

        final result3 = await coordinator.syncBatch(
          messages: batch3,
          source: 'wifi_direct',
          priority: SyncPriority.low,
        );

        // All batches should succeed
        expect(result1.queued, 20);
        expect(result2.queued, 20);
        expect(result3.queued, 10);

        // Total of 50 unique messages
        final stats = coordinator.getStatistics();
        expect(stats.deduplicationStats.uniqueMessages, 50);
        expect(stats.queueStats.totalTasksQueued, 50);
      });
    });

    group('Edge Cases', () {
      testWidgets('E2E: Message with attachment sync', (tester) async {
        final messageWithAttachment = MessageEntity(
          id: 'msg-attachment',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Check out this photo!',
          messageType: MessageType.image,
          createdAt: DateTime.now(),

          updatedAt: DateTime.now(),
          reactions: [],
          readBy: [],
          attachmentUrl: 'https://example.com/photo.jpg',
        );

        final result = await coordinator.syncMessage(
          message: messageWithAttachment,
          source: 'server',
          priority: SyncPriority.high,
        );

        expect(result.status, SyncStatus.queued);

        // Same message with attachment should be detected as duplicate
        final duplicateResult = await coordinator.syncMessage(
          message: messageWithAttachment,
          source: 'ble',
          priority: SyncPriority.medium,
        );

        expect(duplicateResult.status, SyncStatus.duplicate);
      });

      testWidgets('E2E: Deleted message propagation', (tester) async {
        final message = MessageEntity(
          id: 'msg-delete',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'To be deleted',
          messageType: MessageType.text,
          createdAt: DateTime.now(),

          updatedAt: DateTime.now(),
          reactions: [],
          readBy: [],
        );

        // Initial sync
        await coordinator.syncMessage(
          message: message,
          source: 'server',
          priority: SyncPriority.high,
        );

        // Message gets deleted
        final deletedMessage = message.copyWith(
          isDeleted: true,
        );

        final resolved = await coordinator.handleIncomingMessage(
          remoteMessage: deletedMessage,
          localMessage: message,
          source: 'server',
        );

        // Deletion should propagate
        expect(resolved.isDeleted, true);
      });

      testWidgets('E2E: Trip cleanup after deletion', (tester) async {
        // Add messages for a trip
        final messages = List.generate(
          10,
          (i) => MessageEntity(
            id: 'trip1-msg-$i',
            tripId: 'trip-to-delete',
            senderId: 'user-1',
            message: 'Message $i',
            messageType: MessageType.text,
            createdAt: DateTime.now(),

            updatedAt: DateTime.now(),
            reactions: [],
            readBy: [],
          ),
        );

        await coordinator.syncBatch(
          messages: messages,
          source: 'server',
          priority: SyncPriority.low,
        );

        expect(coordinator.getStatistics().deduplicationStats.uniqueMessages,
            10);

        // Trip gets deleted - cleanup
        coordinator.clearTripSync('trip-to-delete');

        // Messages should no longer be in deduplication cache
        final newMessage = MessageEntity(
          id: 'trip1-msg-0', // Same ID as before
          tripId: 'trip-to-delete',
          senderId: 'user-1',
          message: 'Message 0', // Same content
          messageType: MessageType.text,
          createdAt: DateTime.now(),

          updatedAt: DateTime.now(),
          reactions: [],
          readBy: [],
        );

        final result = await coordinator.syncMessage(
          message: newMessage,
          source: 'server',
          priority: SyncPriority.high,
        );

        // Should not be detected as duplicate since cache was cleared
        expect(result.status, SyncStatus.queued);
      });

      testWidgets('E2E: Empty message batch handling', (tester) async {
        final result = await coordinator.syncBatch(
          messages: [],
          source: 'server',
          priority: SyncPriority.low,
        );

        expect(result.total, 0);
        expect(result.queued, 0);
        expect(result.successRate, 0.0);
      });

      testWidgets('E2E: Null local message handling', (tester) async {
        // New message arrives with no local version
        final incomingMessage = MessageEntity(
          id: 'new-msg',
          tripId: 'trip-1',
          senderId: 'user-2',
          message: 'New message from another user',
          messageType: MessageType.text,
          createdAt: DateTime.now(),

          updatedAt: DateTime.now(),
          reactions: [],
          readBy: ['user-2'],
        );

        final resolved = await coordinator.handleIncomingMessage(
          remoteMessage: incomingMessage,
          localMessage: null, // No local version
          source: 'server',
        );

        // Should use remote message as-is
        expect(resolved.id, incomingMessage.id);
        expect(resolved.message, incomingMessage.message);
      });
    });

    group('Performance Tests', () {
      testWidgets('E2E: Rapid message sequence (stress test)', (tester) async {
        // Send 100 messages rapidly
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 100; i++) {
          final message = MessageEntity(
            id: 'rapid-msg-$i',
            tripId: 'trip-1',
            senderId: 'user-1',
            message: 'Rapid message $i',
            messageType: MessageType.text,
            createdAt: DateTime.now().add(Duration(milliseconds: i)),

            updatedAt: DateTime.now().add(Duration(milliseconds: i)),
            reactions: [],
            readBy: [],
          );

          await coordinator.syncMessage(
            message: message,
            source: 'server',
            priority: SyncPriority.high,
          );
        }

        stopwatch.stop();

        // Should handle 100 messages in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Under 5 seconds

        final stats = coordinator.getStatistics();
        expect(stats.deduplicationStats.uniqueMessages, 100);
        expect(stats.queueStats.totalTasksQueued, 100);
      });

      testWidgets('E2E: Concurrent operations from multiple sources',
          (tester) async {
        // Simulate concurrent message arrivals
        final futures = <Future>[];

        for (int i = 0; i < 20; i++) {
          final message = MessageEntity(
            id: 'concurrent-msg-$i',
            tripId: 'trip-1',
            senderId: 'user-${i % 4 + 1}',
            message: 'Concurrent message $i',
            messageType: MessageType.text,
            createdAt: DateTime.now(),

            updatedAt: DateTime.now(),
            reactions: [],
            readBy: [],
          );

          final source = ['server', 'ble', 'wifi_direct', 'multipeer'][i % 4];

          futures.add(coordinator.syncMessage(
            message: message,
            source: source,
            priority: SyncPriority.medium,
          ));
        }

        // Wait for all to complete
        final results = await Future.wait(futures);

        // All should complete successfully
        expect(results.length, 20);
        expect(results.every((r) => r.status == SyncStatus.queued), true);
      });
    });

    group('Event Stream Tests', () {
      testWidgets('E2E: Monitor sync events throughout workflow',
          (tester) async {
        final events = <SyncEvent>[];
        final subscription = coordinator.eventStream.listen((event) {
          events.add(event);
        });

        // Perform various operations
        final message = MessageEntity(
          id: 'event-msg',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Test message',
          messageType: MessageType.text,
          createdAt: DateTime.now(),

          updatedAt: DateTime.now(),
          reactions: [],
          readBy: [],
        );

        await coordinator.syncMessage(
          message: message,
          source: 'server',
          priority: SyncPriority.high,
        );

        // Duplicate
        await coordinator.syncMessage(
          message: message,
          source: 'ble',
          priority: SyncPriority.medium,
        );

        // Conflict
        final now = DateTime.now();
        final earlier = now.subtract(const Duration(hours: 1));

        final localMsg = message.copyWith(createdAt: earlier, updatedAt: earlier);
        final remoteMsg = message.copyWith(createdAt: now, updatedAt: now);

        await coordinator.handleIncomingMessage(
          remoteMessage: remoteMsg,
          localMessage: localMsg,
          source: 'server',
        );

        // Wait for events to propagate
        await tester.pumpAndSettle();

        await subscription.cancel();

        // Should have received multiple events
        expect(events.length, greaterThan(0));
      });
    });
  });
}
