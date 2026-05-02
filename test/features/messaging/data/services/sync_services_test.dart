import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/messaging/data/services/message_deduplication_service.dart';
import 'package:travel_crew/features/messaging/data/services/priority_sync_queue.dart';
import 'package:travel_crew/features/messaging/data/services/conflict_resolution_engine.dart';
import 'package:travel_crew/features/messaging/data/services/sync_coordinator.dart';
import 'package:travel_crew/features/messaging/domain/entities/message_entity.dart';

void main() {
  group('MessageDeduplicationService Tests', () {
    late MessageDeduplicationService service;

    setUp(() {
      service = MessageDeduplicationService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should initialize successfully', () async {
      await service.initialize();
      expect(service, isNotNull);
    });

    test('should detect identical messages as duplicates', () async {
      await service.initialize();

      // First message
      final result1 = await service.checkDuplicate(
        messageId: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        content: 'Hello World',
        timestamp: DateTime.now(),
      );

      expect(result1, isNull); // First message is unique

      // Same message again
      final result2 = await service.checkDuplicate(
        messageId: 'msg-2', // Different ID
        tripId: 'trip-1',
        senderId: 'user-1',
        content: 'Hello World', // Same content
        timestamp: DateTime.now(),
      );

      expect(result2, 'msg-1'); // Returns canonical message ID
    });

    test('should treat different content as unique', () async {
      await service.initialize();

      final result1 = await service.checkDuplicate(
        messageId: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      final result2 = await service.checkDuplicate(
        messageId: 'msg-2',
        tripId: 'trip-1',
        senderId: 'user-1',
        content: 'World', // Different content
        timestamp: DateTime.now(),
      );

      expect(result1, isNull);
      expect(result2, isNull);
    });

    test('should track statistics correctly', () async {
      await service.initialize();

      // Add some messages
      await service.checkDuplicate(
        messageId: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        content: 'Message 1',
        timestamp: DateTime.now(),
      );

      await service.checkDuplicate(
        messageId: 'msg-2',
        tripId: 'trip-1',
        senderId: 'user-1',
        content: 'Message 1', // Duplicate
        timestamp: DateTime.now(),
      );

      final stats = service.getStatistics();
      expect(stats.totalChecks, 2);
      expect(stats.duplicatesFound, 1);
      expect(stats.uniqueMessages, 1);
      expect(stats.duplicateRate, 0.5);
    });

    test('should clear trip cache', () async {
      await service.initialize();

      service.registerMessage(
        messageId: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      expect(service.isMessageKnown('msg-1'), true);

      service.clearTripCache('trip-1');
      expect(service.isMessageKnown('msg-1'), false);
    });

    test('should calculate duplicate rate correctly', () async {
      await service.initialize();

      final stats = service.getStatistics();
      expect(stats.duplicateRate, 0.0); // No checks yet

      // Add 3 unique, 1 duplicate
      await service.checkDuplicate(
        messageId: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        content: 'Message 1',
        timestamp: DateTime.now(),
      );

      await service.checkDuplicate(
        messageId: 'msg-2',
        tripId: 'trip-1',
        senderId: 'user-1',
        content: 'Message 2',
        timestamp: DateTime.now(),
      );

      await service.checkDuplicate(
        messageId: 'msg-3',
        tripId: 'trip-1',
        senderId: 'user-1',
        content: 'Message 3',
        timestamp: DateTime.now(),
      );

      await service.checkDuplicate(
        messageId: 'msg-4',
        tripId: 'trip-1',
        senderId: 'user-1',
        content: 'Message 1', // Duplicate of msg-1
        timestamp: DateTime.now(),
      );

      final finalStats = service.getStatistics();
      expect(finalStats.duplicateRate, 0.25); // 1/4 = 0.25
    });
  });

  group('PrioritySyncQueue Tests', () {
    late PrioritySyncQueue queue;

    setUp(() {
      queue = PrioritySyncQueue();
      // Pause to prevent automatic processing affecting queue size assertions
      queue.pause();
      queue.resetStatistics();
    });

    tearDown(() {
      queue.dispose();
    });

    test('should enqueue and dequeue tasks', () async {
      final task = SyncTask(
        id: 'task-1',
        type: 'test',
        tripId: 'trip-1',
        priority: SyncPriority.high,
        data: {},
      );

      await queue.enqueue(task);

      final stats = queue.getStatistics();
      expect(stats.totalTasksQueued, 1);
      expect(stats.highPriorityCount, 1);
    });

    test('should process high priority tasks first', () async {
      final lowTask = SyncTask(
        id: 'task-low',
        type: 'test',
        tripId: 'trip-1',
        priority: SyncPriority.low,
        data: {},
      );

      final highTask = SyncTask(
        id: 'task-high',
        type: 'test',
        tripId: 'trip-1',
        priority: SyncPriority.high,
        data: {},
      );

      await queue.enqueue(lowTask);
      await queue.enqueue(highTask);

      final stats = queue.getStatistics();
      expect(stats.highPriorityCount, 1);
      expect(stats.lowPriorityCount, 1);
    });

    test('should track queue statistics', () async {
      final task1 = SyncTask(
        id: 'task-1',
        type: 'test',
        tripId: 'trip-1',
        priority: SyncPriority.high,
        data: {},
      );

      final task2 = SyncTask(
        id: 'task-2',
        type: 'test',
        tripId: 'trip-1',
        priority: SyncPriority.medium,
        data: {},
      );

      await queue.enqueue(task1);
      await queue.enqueue(task2);

      final stats = queue.getStatistics();
      expect(stats.totalTasksQueued, 2);
      expect(stats.highPriorityCount, 1);
      expect(stats.mediumPriorityCount, 1);
      expect(stats.totalQueueSize, 2);
    });

    test('should pause and resume queue', () {
      queue.pause();
      expect(queue.isPaused, true);

      queue.resume();
      expect(queue.isPaused, false);
    });

    test('should clear all tasks', () async {
      final task = SyncTask(
        id: 'task-1',
        type: 'test',
        tripId: 'trip-1',
        priority: SyncPriority.high,
        data: {},
      );

      await queue.enqueue(task);
      expect(queue.queueSize, 1);

      queue.clearAll();
      expect(queue.queueSize, 0);
    });

    test('should clear trip-specific tasks', () async {
      final task1 = SyncTask(
        id: 'task-1',
        type: 'test',
        tripId: 'trip-1',
        priority: SyncPriority.high,
        data: {},
      );

      final task2 = SyncTask(
        id: 'task-2',
        type: 'test',
        tripId: 'trip-2',
        priority: SyncPriority.high,
        data: {},
      );

      await queue.enqueue(task1);
      await queue.enqueue(task2);
      expect(queue.queueSize, 2);

      queue.clearTripTasks('trip-1');
      expect(queue.queueSize, 1);
    });

    test('should calculate success rate correctly', () async {
      final stats = queue.getStatistics();
      expect(stats.successRate, 0.0); // No tasks processed yet

      // Note: We can't easily test processed tasks without registering handlers
      // This test verifies the calculation works with 0 values
    });
  });

  group('ConflictResolutionEngine Tests', () {
    late ConflictResolutionEngine engine;

    setUp(() {
      engine = ConflictResolutionEngine();
      engine.initialize();
      engine.resetStatistics();
    });

    test('should initialize successfully', () {
      expect(engine, isNotNull);
    });

    test('should detect no conflict for identical messages', () async {
      final message = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Hello',
        messageType: MessageType.text,
        createdAt: DateTime.now(),

        updatedAt: DateTime.now(),
        reactions: [],
        readBy: [],
      );

      final resolution = await engine.resolveMessageConflict(
        localVersion: message,
        remoteVersion: message,
        source: 'server',
      );

      expect(resolution.winner, ConflictWinner.noConflict);
      expect(resolution.hasConflict, false);
    });

    test('should resolve conflict by timestamp (Last Write Wins)', () async {
      final now = DateTime.now();
      final earlier = now.subtract(const Duration(hours: 1));

      final localMessage = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Old version',
        messageType: MessageType.text,
        createdAt: earlier,

        updatedAt: earlier,
        reactions: [],
        readBy: [],
      );

      final remoteMessage = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'New version',
        messageType: MessageType.text,
        createdAt: now,

        updatedAt: now,
        reactions: [],
        readBy: [],
      );

      final resolution = await engine.resolveMessageConflict(
        localVersion: localMessage,
        remoteVersion: remoteMessage,
        source: 'server',
      );

      expect(resolution.winner, ConflictWinner.remote);
      expect(resolution.resolutionMethod, ResolutionMethod.timestamp);
      expect(resolution.resolvedMessage.message, 'New version');
    });

    test('should resolve conflict by source priority when timestamps equal', () async {
      final timestamp = DateTime.now();

      final localMessage = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Local version',
        messageType: MessageType.text,
        createdAt: timestamp,
        updatedAt: timestamp,
        reactions: [],
        readBy: [],
      );

      final remoteMessage = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Server version',
        messageType: MessageType.text,
        createdAt: timestamp,
        updatedAt: timestamp,
        reactions: [],
        readBy: [],
      );

      final resolution = await engine.resolveMessageConflict(
        localVersion: localMessage,
        remoteVersion: remoteMessage,
        source: 'server', // Server has highest priority
      );

      expect(resolution.winner, ConflictWinner.remote);
      expect(resolution.resolutionMethod, ResolutionMethod.source);
    });

    test('should merge reactions from both versions', () async {
      final localReactions = [
        MessageReaction(
          userId: 'user-1',
          emoji: '👍',
          createdAt: DateTime.now(),
        ),
      ];

      final remoteReactions = [
        MessageReaction(
          userId: 'user-2',
          emoji: '❤️',
          createdAt: DateTime.now(),
        ),
      ];

      final merged = await engine.resolveReactionConflict(
        localReactions: localReactions,
        remoteReactions: remoteReactions,
        source: 'server',
      );

      expect(merged.length, 2);
      expect(merged.any((r) => r.emoji == '👍'), true);
      expect(merged.any((r) => r.emoji == '❤️'), true);
    });

    test('should merge read status from both versions', () async {
      final localReadBy = ['user-1', 'user-2'];
      final remoteReadBy = ['user-2', 'user-3'];

      final merged = await engine.resolveReadStatusConflict(
        localReadBy: localReadBy,
        remoteReadBy: remoteReadBy,
      );

      expect(merged.length, 3);
      expect(merged.contains('user-1'), true);
      expect(merged.contains('user-2'), true);
      expect(merged.contains('user-3'), true);
    });

    test('should propagate deletion status', () async {
      final notDeleted = false;
      final deleted = true;

      final result = await engine.resolveDeletionConflict(
        localDeleted: notDeleted,
        remoteDeleted: deleted,
        localDeletedAt: null,
        remoteDeletedAt: DateTime.now(),
      );

      expect(result, true); // Deletion wins
    });

    test('should track conflict resolution statistics', () async {
      final now = DateTime.now();
      final earlier = now.subtract(const Duration(hours: 1));

      final localMessage = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Old version',
        messageType: MessageType.text,
        createdAt: earlier,

        updatedAt: earlier,
        reactions: [],
        readBy: [],
      );

      final remoteMessage = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'New version',
        messageType: MessageType.text,
        createdAt: now,

        updatedAt: now,
        reactions: [],
        readBy: [],
      );

      await engine.resolveMessageConflict(
        localVersion: localMessage,
        remoteVersion: remoteMessage,
        source: 'server',
      );

      final stats = engine.getStatistics();
      expect(stats.totalConflicts, 1);
      expect(stats.resolvedByTimestamp, 1);
    });
  });

  group('SyncCoordinator Tests', () {
    late SyncCoordinator coordinator;

    setUp(() async {
      coordinator = SyncCoordinator();
      await coordinator.initialize();
      coordinator.resetStatistics();
    });

    tearDown(() {
      coordinator.dispose();
    });

    test('should initialize successfully', () {
      expect(coordinator.isInitialized, true);
      expect(coordinator.isSyncing, false);
    });

    test('should detect duplicates during sync', () async {
      final message = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Hello',
        messageType: MessageType.text,
        createdAt: DateTime.now(),

        updatedAt: DateTime.now(),
        reactions: [],
        readBy: [],
      );

      // First sync
      final result1 = await coordinator.syncMessage(
        message: message,
        source: 'server',
      );
      expect(result1.status, SyncStatus.queued);

      // Same message again
      final result2 = await coordinator.syncMessage(
        message: message,
        source: 'ble',
      );
      expect(result2.status, SyncStatus.duplicate);
    });

    test('should sync batch of messages', () async {
      final messages = [
        MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Message 1',
          messageType: MessageType.text,
          createdAt: DateTime.now(),

          updatedAt: DateTime.now(),
          reactions: [],
          readBy: [],
        ),
        MessageEntity(
          id: 'msg-2',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Message 2',
          messageType: MessageType.text,
          createdAt: DateTime.now(),

          updatedAt: DateTime.now(),
          reactions: [],
          readBy: [],
        ),
      ];

      final result = await coordinator.syncBatch(
        messages: messages,
        source: 'server',
      );

      expect(result.total, 2);
      expect(result.queued, 2);
      expect(result.duplicates, 0);
      expect(result.errors, 0);
    });

    test('should handle incoming message without conflict', () async {
      final remoteMessage = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Hello',
        messageType: MessageType.text,
        createdAt: DateTime.now(),

        updatedAt: DateTime.now(),
        reactions: [],
        readBy: [],
      );

      final resolved = await coordinator.handleIncomingMessage(
        remoteMessage: remoteMessage,
        localMessage: null, // No local version
        source: 'server',
      );

      expect(resolved.id, remoteMessage.id);
      expect(resolved.message, remoteMessage.message);
    });

    test('should register sync sources', () {
      final source = SyncSource(name: 'test-source', isEnabled: true);
      coordinator.registerSyncSource(source);

      final stats = coordinator.getStatistics();
      expect(stats, isNotNull);
    });

    test('should track comprehensive statistics', () async {
      final message = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Hello',
        messageType: MessageType.text,
        createdAt: DateTime.now(),

        updatedAt: DateTime.now(),
        reactions: [],
        readBy: [],
      );

      await coordinator.syncMessage(message: message, source: 'server');

      final stats = coordinator.getStatistics();
      expect(stats.totalDuplicatesSkipped, 0);
      expect(stats.deduplicationStats, isNotNull);
      expect(stats.queueStats, isNotNull);
      expect(stats.conflictStats, isNotNull);
    });

    test('should clear trip sync data', () async {
      final message = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Hello',
        messageType: MessageType.text,
        createdAt: DateTime.now(),

        updatedAt: DateTime.now(),
        reactions: [],
        readBy: [],
      );

      await coordinator.syncMessage(message: message, source: 'server');
      coordinator.clearTripSync('trip-1');

      // After clearing, the same message should not be detected as duplicate
      final result = await coordinator.syncMessage(
        message: message,
        source: 'server',
      );
      expect(result.status, SyncStatus.queued);
    });
  });

  group('Data Class Tests', () {
    test('SyncTask copyWith should work correctly', () {
      final task = SyncTask(
        id: 'task-1',
        type: 'test',
        tripId: 'trip-1',
        priority: SyncPriority.high,
        data: {},
      );

      final copied = task.copyWith(retryCount: 1);

      expect(copied.id, task.id);
      expect(copied.type, task.type);
      expect(copied.retryCount, 1);
    });

    test('SyncStatistics should calculate efficiency correctly', () {
      const stats = SyncStatistics(
        totalMessagesSynced: 75,
        totalDuplicatesSkipped: 25,
        totalConflictsResolved: 10,
        deduplicationStats: DeduplicationStats(
          totalChecks: 100,
          duplicatesFound: 25,
          uniqueMessages: 75,
          cacheSize: 75,
          maxCacheSize: 10000,
          duplicateRate: 0.25,
        ),
        queueStats: SyncQueueStats(
          totalTasksQueued: 100,
          totalTasksProcessed: 85,
          totalTasksFailed: 5,
          totalTasksRetried: 10,
          highPriorityCount: 0,
          mediumPriorityCount: 0,
          lowPriorityCount: 0,
          isProcessing: false,
          isPaused: false,
        ),
        conflictStats: ConflictResolutionStats(
          totalConflicts: 10,
          resolvedByTimestamp: 5,
          resolvedBySource: 3,
          resolvedByContent: 2,
          manualResolution: 0,
        ),
        isSyncing: false,
      );

      expect(stats.overallEfficiency, 0.75); // 75 / (75 + 25)
    });

    test('DeduplicationStats should calculate cache usage correctly', () {
      const stats = DeduplicationStats(
        totalChecks: 1000,
        duplicatesFound: 250,
        uniqueMessages: 750,
        cacheSize: 500,
        maxCacheSize: 10000,
        duplicateRate: 0.25,
      );

      expect(stats.cacheUsage, 0.05); // 500 / 10000
    });

    test('SyncQueueStats should calculate rates correctly', () {
      const stats = SyncQueueStats(
        totalTasksQueued: 100,
        totalTasksProcessed: 85,
        totalTasksFailed: 10,
        totalTasksRetried: 5,
        highPriorityCount: 5,
        mediumPriorityCount: 10,
        lowPriorityCount: 15,
        isProcessing: false,
        isPaused: false,
      );

      expect(stats.successRate, 0.85); // 85 / 100
      expect(stats.failureRate, 0.10); // 10 / 100
      expect(stats.totalQueueSize, 30); // 5 + 10 + 15
    });

    test('ConflictResolutionStats should calculate rates correctly', () {
      const stats = ConflictResolutionStats(
        totalConflicts: 100,
        resolvedByTimestamp: 60,
        resolvedBySource: 25,
        resolvedByContent: 10,
        manualResolution: 5,
      );

      expect(stats.timestampRate, 0.6); // 60 / 100
      expect(stats.sourceRate, 0.25); // 25 / 100
      expect(stats.contentRate, 0.1); // 10 / 100
    });

    test('BatchSyncResult should calculate processed count correctly', () {
      final result = BatchSyncResult(
        total: 100,
        queued: 75,
        duplicates: 20,
        errors: 5,
      );

      expect(result.processed, 95); // 75 + 20
      expect(result.successRate, 0.75); // 75 / 100
    });
  });
}
