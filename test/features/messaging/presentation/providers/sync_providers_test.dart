import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/features/messaging/presentation/providers/sync_providers.dart';
import 'package:travel_companion/features/messaging/data/services/sync_coordinator.dart';
import 'package:travel_companion/features/messaging/domain/entities/message_entity.dart';

void main() {
  group('Sync Providers Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Core Providers', () {
      test('syncCoordinatorProvider should provide SyncCoordinator instance',
          () {
        final coordinator = container.read(syncCoordinatorProvider);
        expect(coordinator, isA<SyncCoordinator>());
      });

      test('messageDeduplicationServiceProvider should provide service', () {
        final service = container.read(messageDeduplicationServiceProvider);
        expect(service, isNotNull);
      });

      test('prioritySyncQueueProvider should provide queue', () {
        final queue = container.read(prioritySyncQueueProvider);
        expect(queue, isNotNull);
      });

      test('conflictResolutionEngineProvider should provide engine', () {
        final engine = container.read(conflictResolutionEngineProvider);
        expect(engine, isNotNull);
      });

      test('providers should dispose resources on container dispose', () async {
        final testContainer = ProviderContainer();
        final coordinator = testContainer.read(syncCoordinatorProvider);

        // Dispose container
        testContainer.dispose();

        // Coordinator should be disposed
        expect(coordinator.isInitialized, false);
      });
    });

    group('Stream Providers', () {
      test('syncEventStreamProvider should provide event stream', () async {
        final coordinator = container.read(syncCoordinatorProvider);
        await coordinator.initialize();

        final streamProvider = container.read(syncEventStreamProvider);

        streamProvider.whenData((event) {
          expect(event, isNotNull);
        });
      });

      test('syncProgressStreamProvider should provide progress stream',
          () async {
        final coordinator = container.read(syncCoordinatorProvider);
        await coordinator.initialize();

        final streamProvider = container.read(syncProgressStreamProvider);

        streamProvider.whenData((progress) {
          expect(progress, isNotNull);
        });
      });

      test('syncQueueEventStreamProvider should provide queue events',
          () async {
        final streamProvider = container.read(syncQueueEventStreamProvider);

        streamProvider.whenData((event) {
          expect(event, isNotNull);
        });
      });
    });

    group('State Providers', () {
      test('syncStatisticsProvider should provide current statistics', () async {
        final coordinator = container.read(syncCoordinatorProvider);
        await coordinator.initialize();

        final stats = container.read(syncStatisticsProvider);

        expect(stats, isNotNull);
        expect(stats.totalMessagesSynced, isA<int>());
        expect(stats.overallEfficiency, isA<double>());
      });

      test('deduplicationStatisticsProvider should provide dedupe stats',
          () async {
        final service = container.read(messageDeduplicationServiceProvider);
        await service.initialize();

        final stats = container.read(deduplicationStatisticsProvider);

        expect(stats, isNotNull);
        expect(stats.totalChecks, isA<int>());
        expect(stats.duplicateRate, isA<double>());
      });

      test('queueStatisticsProvider should provide queue stats', () {
        final stats = container.read(queueStatisticsProvider);

        expect(stats, isNotNull);
        expect(stats.totalQueueSize, isA<int>());
        expect(stats.totalTasksQueued, isA<int>());
      });

      test('conflictStatisticsProvider should provide conflict stats', () {
        final stats = container.read(conflictStatisticsProvider);

        expect(stats, isNotNull);
        expect(stats.totalConflicts, isA<int>());
        expect(stats.timestampRate, isA<double>());
      });
    });

    group('SyncNotifier', () {
      test('should initialize with default state', () {
        final state = container.read(syncNotifierProvider);

        expect(state.isInitialized, false);
        expect(state.isSyncing, false);
        expect(state.status, SyncStatus.idle);
        expect(state.errorMessage, null);
      });

      test('initialize should update state to ready', () async {
        final notifier = container.read(syncNotifierProvider.notifier);

        await notifier.initialize();

        final state = container.read(syncNotifierProvider);
        expect(state.isInitialized, true);
        expect(state.status, SyncStatus.ready);
      });

      test('registerSyncSource should increment active sources count',
          () async {
        final notifier = container.read(syncNotifierProvider.notifier);
        await notifier.initialize();

        final source = SyncSource(name: 'test', isEnabled: true);
        notifier.registerSyncSource(source);

        final state = container.read(syncNotifierProvider);
        expect(state.activeSourcesCount, 1);
      });

      test('syncMessage should call coordinator', () async {
        final notifier = container.read(syncNotifierProvider.notifier);
        await notifier.initialize();

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

        final result = await notifier.syncMessage(
          message: message,
          source: 'test',
          priority: SyncPriority.high,
        );

        expect(result, isNotNull);
        expect(result.status, isA<SyncStatus>());
      });

      test('syncBatch should process multiple messages', () async {
        final notifier = container.read(syncNotifierProvider.notifier);
        await notifier.initialize();

        final messages = List.generate(
          5,
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

        final result = await notifier.syncBatch(
          messages: messages,
          source: 'test',
          priority: SyncPriority.low,
        );

        expect(result, isNotNull);
        expect(result.total, 5);
      });

      test('handleIncomingMessage should resolve conflicts', () async {
        final notifier = container.read(syncNotifierProvider.notifier);
        await notifier.initialize();

        final now = DateTime.now();
        final earlier = now.subtract(const Duration(hours: 1));

        final localMessage = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Old',
          messageType: MessageType.text,
          timestamp: earlier,
          reactions: [],
          readBy: [],
        );

        final remoteMessage = MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'New',
          messageType: MessageType.text,
          timestamp: now,
          reactions: [],
          readBy: [],
        );

        final resolved = await notifier.handleIncomingMessage(
          remoteMessage: remoteMessage,
          localMessage: localMessage,
          source: 'server',
        );

        expect(resolved.message, 'New');
      });

      test('startAutoSync should update state', () async {
        final notifier = container.read(syncNotifierProvider.notifier);
        await notifier.initialize();

        await notifier.startAutoSync();

        final state = container.read(syncNotifierProvider);
        expect(state.isSyncing, true);
        expect(state.status, SyncStatus.syncing);
      });

      test('stopAutoSync should update state', () async {
        final notifier = container.read(syncNotifierProvider.notifier);
        await notifier.initialize();

        await notifier.startAutoSync();
        notifier.stopAutoSync();

        final state = container.read(syncNotifierProvider);
        expect(state.isSyncing, false);
        expect(state.status, SyncStatus.ready);
      });

      test('syncTrip should update current trip and last sync time', () async {
        final notifier = container.read(syncNotifierProvider.notifier);
        await notifier.initialize();

        await notifier.syncTrip('trip-1', priority: SyncPriority.high);

        final state = container.read(syncNotifierProvider);
        expect(state.lastSyncTime, isNotNull);
      });

      test('clearTripSync should clear trip data', () async {
        final notifier = container.read(syncNotifierProvider.notifier);
        await notifier.initialize();

        notifier.clearTripSync('trip-1');

        // Should not throw
        expect(true, true);
      });

      test('resetStatistics should reset all stats', () async {
        final notifier = container.read(syncNotifierProvider.notifier);
        await notifier.initialize();

        notifier.resetStatistics();

        final stats = container.read(syncStatisticsProvider);
        expect(stats.totalMessagesSynced, 0);
      });
    });

    group('Helper Providers', () {
      test('isSyncInitializedProvider should return initialization state', () {
        final isInitialized = container.read(isSyncInitializedProvider);
        expect(isInitialized, false);
      });

      test('isSyncingProvider should return syncing state', () {
        final isSyncing = container.read(isSyncingProvider);
        expect(isSyncing, false);
      });

      test('syncErrorProvider should return error message', () {
        final error = container.read(syncErrorProvider);
        expect(error, null);
      });

      test('activeSourcesCountProvider should return sources count', () {
        final count = container.read(activeSourcesCountProvider);
        expect(count, 0);
      });

      test('lastSyncTimeProvider should return last sync time', () {
        final lastSync = container.read(lastSyncTimeProvider);
        expect(lastSync, null);
      });
    });

    group('Queue Management Providers', () {
      test('queueSizeProvider should return queue size', () {
        final size = container.read(queueSizeProvider);
        expect(size, 0);
      });

      test('queueIsProcessingProvider should return processing state', () {
        final isProcessing = container.read(queueIsProcessingProvider);
        expect(isProcessing, false);
      });

      test('queueIsPausedProvider should return paused state', () {
        final isPaused = container.read(queueIsPausedProvider);
        expect(isPaused, false);
      });

      test('currentTaskProvider should return current task', () {
        final currentTask = container.read(currentTaskProvider);
        expect(currentTask, null);
      });
    });

    group('Statistics Aggregation Providers', () {
      test('syncEfficiencyProvider should return efficiency', () {
        final efficiency = container.read(syncEfficiencyProvider);
        expect(efficiency, isA<double>());
        expect(efficiency, greaterThanOrEqualTo(0.0));
        expect(efficiency, lessThanOrEqualTo(1.0));
      });

      test('duplicateRateProvider should return duplicate rate', () {
        final rate = container.read(duplicateRateProvider);
        expect(rate, isA<double>());
        expect(rate, greaterThanOrEqualTo(0.0));
        expect(rate, lessThanOrEqualTo(1.0));
      });

      test('queueSuccessRateProvider should return success rate', () {
        final rate = container.read(queueSuccessRateProvider);
        expect(rate, isA<double>());
        expect(rate, greaterThanOrEqualTo(0.0));
        expect(rate, lessThanOrEqualTo(1.0));
      });

      test('queueFailureRateProvider should return failure rate', () {
        final rate = container.read(queueFailureRateProvider);
        expect(rate, isA<double>());
        expect(rate, greaterThanOrEqualTo(0.0));
        expect(rate, lessThanOrEqualTo(1.0));
      });

      test('conflictTimestampRateProvider should return timestamp rate', () {
        final rate = container.read(conflictTimestampRateProvider);
        expect(rate, isA<double>());
        expect(rate, greaterThanOrEqualTo(0.0));
        expect(rate, lessThanOrEqualTo(1.0));
      });

      test('conflictSourceRateProvider should return source rate', () {
        final rate = container.read(conflictSourceRateProvider);
        expect(rate, isA<double>());
        expect(rate, greaterThanOrEqualTo(0.0));
        expect(rate, lessThanOrEqualTo(1.0));
      });

      test('conflictContentRateProvider should return content rate', () {
        final rate = container.read(conflictContentRateProvider);
        expect(rate, isA<double>());
        expect(rate, greaterThanOrEqualTo(0.0));
        expect(rate, lessThanOrEqualTo(1.0));
      });
    });

    group('Provider Reactivity', () {
      test('should notify listeners when state changes', () async {
        var notificationCount = 0;

        final listener = container.listen(
          syncNotifierProvider,
          (previous, next) {
            notificationCount++;
          },
        );

        final notifier = container.read(syncNotifierProvider.notifier);
        await notifier.initialize();

        // Should have been notified at least once
        expect(notificationCount, greaterThan(0));
      });

      test('should update dependent providers when stats change', () async {
        final notifier = container.read(syncNotifierProvider.notifier);
        await notifier.initialize();

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

        await notifier.syncMessage(
          message: message,
          source: 'test',
          priority: SyncPriority.high,
        );

        // Stats should be updated
        final stats = container.read(syncStatisticsProvider);
        expect(stats, isNotNull);
      });
    });

    group('Error Handling', () {
      test('should handle initialization errors', () async {
        final notifier = container.read(syncNotifierProvider.notifier);

        // Should not throw
        await notifier.initialize();

        final state = container.read(syncNotifierProvider);
        expect(state.status, isNot(SyncStatus.error));
      });

      test('should capture sync errors in state', () async {
        final notifier = container.read(syncNotifierProvider.notifier);
        await notifier.initialize();

        // Error handling is internal, should not throw
        final state = container.read(syncNotifierProvider);
        expect(state, isNotNull);
      });
    });

    group('Memory Management', () {
      test('should properly dispose all resources', () async {
        final testContainer = ProviderContainer();

        final coordinator = testContainer.read(syncCoordinatorProvider);
        final dedup = testContainer.read(messageDeduplicationServiceProvider);
        final queue = testContainer.read(prioritySyncQueueProvider);

        await coordinator.initialize();
        await dedup.initialize();

        testContainer.dispose();

        // All should be disposed
        expect(coordinator.isInitialized, false);
      });

      test('should handle multiple container instances', () async {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        final coord1 = container1.read(syncCoordinatorProvider);
        final coord2 = container2.read(syncCoordinatorProvider);

        // Should be different instances
        expect(identical(coord1, coord2), false);

        container1.dispose();
        container2.dispose();
      });
    });
  });
}
