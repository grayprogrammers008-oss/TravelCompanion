import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/message_entity.dart';
import 'message_deduplication_service.dart';
import 'priority_sync_queue.dart';
import 'conflict_resolution_engine.dart';

/// Sync Coordinator
/// Orchestrates message synchronization across multiple sources with
/// deduplication, priority queuing, and automatic conflict resolution
class SyncCoordinator {
  static final SyncCoordinator _instance = SyncCoordinator._internal();
  factory SyncCoordinator() => _instance;
  SyncCoordinator._internal();

  // Core services
  final MessageDeduplicationService _deduplicationService = MessageDeduplicationService();
  final PrioritySyncQueue _syncQueue = PrioritySyncQueue();
  final ConflictResolutionEngine _conflictEngine = ConflictResolutionEngine();

  // State
  bool _isInitialized = false;
  bool _isSyncing = false;

  // Sync sources
  final Map<String, SyncSource> _syncSources = {};

  // Statistics
  int _totalMessagesSynced = 0;
  int _totalDuplicatesSkipped = 0;
  int _totalConflictsResolved = 0;

  // Streams
  final StreamController<SyncEvent> _eventController =
      StreamController<SyncEvent>.broadcast();
  final StreamController<SyncProgress> _progressController =
      StreamController<SyncProgress>.broadcast();

  Stream<SyncEvent> get eventStream => _eventController.stream;
  Stream<SyncProgress> get progressStream => _progressController.stream;

  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;

  /// Initialize the sync coordinator
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize services
    await _deduplicationService.initialize();
    _conflictEngine.initialize();

    // Register task handlers
    _registerTaskHandlers();

    _isInitialized = true;
    debugPrint('Sync Coordinator initialized');
    _eventController.add(SyncEvent.initialized());
  }

  /// Register a sync source
  void registerSyncSource(SyncSource source) {
    _syncSources[source.name] = source;
    debugPrint('Registered sync source: ${source.name}');
  }

  /// Sync a message from a specific source
  Future<SyncResult> syncMessage({
    required MessageEntity message,
    required String source,
    SyncPriority priority = SyncPriority.medium,
  }) async {
    if (!_isInitialized) {
      return SyncResult.error('Sync coordinator not initialized');
    }

    try {
      // Step 1: Check for duplicates
      final duplicateId = await _deduplicationService.checkDuplicate(
        messageId: message.id,
        tripId: message.tripId,
        senderId: message.senderId,
        content: message.message ?? '',
        timestamp: message.createdAt,
        attachmentUrl: message.attachmentUrl,
      );

      if (duplicateId != null) {
        _totalDuplicatesSkipped++;
        debugPrint('Duplicate message skipped: ${message.id} -> $duplicateId');
        return SyncResult.duplicate(duplicateId);
      }

      // Step 2: Queue for sync
      final task = SyncTask(
        id: 'sync_${message.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: 'sync_message',
        tripId: message.tripId ?? '',
        priority: priority,
        data: {
          'message': message,
          'source': source,
        },
      );

      await _syncQueue.enqueue(task);

      return SyncResult.queued(task.id);
    } catch (e) {
      debugPrint('Error syncing message: $e');
      return SyncResult.error(e.toString());
    }
  }

  /// Sync multiple messages in batch
  Future<BatchSyncResult> syncBatch({
    required List<MessageEntity> messages,
    required String source,
    SyncPriority priority = SyncPriority.low,
  }) async {
    int queued = 0;
    int duplicates = 0;
    int errors = 0;

    for (final message in messages) {
      final result = await syncMessage(
        message: message,
        source: source,
        priority: priority,
      );

      switch (result.status) {
        case SyncStatus.queued:
          queued++;
          break;
        case SyncStatus.duplicate:
          duplicates++;
          break;
        case SyncStatus.error:
          errors++;
          break;
        default:
          break;
      }
    }

    return BatchSyncResult(
      total: messages.length,
      queued: queued,
      duplicates: duplicates,
      errors: errors,
    );
  }

  /// Handle incoming message with conflict resolution
  Future<MessageEntity> handleIncomingMessage({
    required MessageEntity remoteMessage,
    required MessageEntity? localMessage,
    required String source,
  }) async {
    // No conflict if no local version
    if (localMessage == null) {
      _deduplicationService.registerMessage(
        messageId: remoteMessage.id,
        tripId: remoteMessage.tripId,
        senderId: remoteMessage.senderId,
        content: remoteMessage.message ?? '',
        timestamp: remoteMessage.createdAt,
        attachmentUrl: remoteMessage.attachmentUrl,
      );
      return remoteMessage;
    }

    // Resolve conflict
    final resolution = await _conflictEngine.resolveMessageConflict(
      localVersion: localMessage,
      remoteVersion: remoteMessage,
      source: source,
    );

    _totalConflictsResolved++;

    _eventController.add(SyncEvent.conflictResolved(
      messageId: remoteMessage.id,
      method: resolution.resolutionMethod,
      winner: resolution.winner,
    ));

    return resolution.resolvedMessage;
  }

  /// Start automatic sync from all sources
  Future<void> startAutoSync({Duration interval = const Duration(minutes: 5)}) async {
    if (_isSyncing) return;

    _isSyncing = true;
    _eventController.add(SyncEvent.syncStarted());

    // Trigger sync from all sources
    for (final source in _syncSources.values) {
      if (source.isEnabled) {
        _triggerSourceSync(source);
      }
    }
  }

  /// Stop automatic sync
  void stopAutoSync() {
    _isSyncing = false;
    _syncQueue.pause();
    _eventController.add(SyncEvent.syncStopped());
    debugPrint('Auto sync stopped');
  }

  /// Manually trigger sync for a specific trip
  Future<void> syncTrip(String tripId, {SyncPriority priority = SyncPriority.high}) async {
    final task = SyncTask(
      id: 'sync_trip_${tripId}_${DateTime.now().millisecondsSinceEpoch}',
      type: 'sync_trip',
      tripId: tripId,
      priority: priority,
      data: {'tripId': tripId},
    );

    await _syncQueue.enqueue(task);
    _eventController.add(SyncEvent.tripSyncQueued(tripId));
  }

  /// Clear sync data for a trip
  void clearTripSync(String tripId) {
    _deduplicationService.clearTripCache(tripId);
    _syncQueue.clearTripTasks(tripId);
    debugPrint('Cleared sync data for trip: $tripId');
  }

  /// Get comprehensive sync statistics
  SyncStatistics getStatistics() {
    return SyncStatistics(
      totalMessagesSynced: _totalMessagesSynced,
      totalDuplicatesSkipped: _totalDuplicatesSkipped,
      totalConflictsResolved: _totalConflictsResolved,
      deduplicationStats: _deduplicationService.getStatistics(),
      queueStats: _syncQueue.getStatistics(),
      conflictStats: _conflictEngine.getStatistics(),
      isSyncing: _isSyncing,
    );
  }

  /// Reset all statistics
  void resetStatistics() {
    _totalMessagesSynced = 0;
    _totalDuplicatesSkipped = 0;
    _totalConflictsResolved = 0;
    _deduplicationService.resetStatistics();
    _syncQueue.resetStatistics();
    _conflictEngine.resetStatistics();
  }

  // Private methods

  void _registerTaskHandlers() {
    // Handle message sync task
    _syncQueue.registerHandler('sync_message', (task) async {
      final message = task.data['message'] as MessageEntity;
      final source = task.data['source'] as String;

      try {
        // Process message sync
        final syncSource = _syncSources[source];
        if (syncSource != null && syncSource.syncHandler != null) {
          final success = await syncSource.syncHandler!(message);
          if (success) {
            _totalMessagesSynced++;
            _eventController.add(SyncEvent.messageSynced(message.id));
          }
          return success;
        }
        return false;
      } catch (e) {
        debugPrint('Error in sync_message handler: $e');
        return false;
      }
    });

    // Handle trip sync task
    _syncQueue.registerHandler('sync_trip', (task) async {
      final tripId = task.data['tripId'] as String;

      try {
        // Trigger sync from all enabled sources
        for (final source in _syncSources.values) {
          if (source.isEnabled && source.tripSyncHandler != null) {
            await source.tripSyncHandler!(tripId);
          }
        }
        return true;
      } catch (e) {
        debugPrint('Error in sync_trip handler: $e');
        return false;
      }
    });

    // Listen to queue events
    _syncQueue.eventStream.listen((event) {
      _handleQueueEvent(event);
    });
  }

  void _triggerSourceSync(SyncSource source) async {
    try {
      if (source.fullSyncHandler != null) {
        await source.fullSyncHandler!();
      }
    } catch (e) {
      debugPrint('Error syncing from ${source.name}: $e');
    }
  }

  void _handleQueueEvent(SyncQueueEvent event) {
    switch (event.type) {
      case SyncQueueEventType.taskCompleted:
        if (event.task != null) {
          _progressController.add(SyncProgress(
            currentTask: event.task!.id,
            queueSize: _syncQueue.queueSize,
            isProcessing: _syncQueue.isProcessing,
          ));
        }
        break;
      case SyncQueueEventType.taskFailed:
        if (event.task != null) {
          _eventController.add(SyncEvent.syncFailed(
            taskId: event.task!.id,
            error: 'Task failed after retries',
          ));
        }
        break;
      default:
        break;
    }
  }

  /// Dispose resources
  void dispose() {
    stopAutoSync();
    _deduplicationService.dispose();
    _syncQueue.dispose();
    _eventController.close();
    _progressController.close();
    _syncSources.clear();
  }
}

// ============================================================================
// DATA CLASSES
// ============================================================================

/// Sync source definition
class SyncSource {
  final String name;
  final bool isEnabled;
  final Future<bool> Function(MessageEntity)? syncHandler;
  final Future<void> Function(String tripId)? tripSyncHandler;
  final Future<void> Function()? fullSyncHandler;

  SyncSource({
    required this.name,
    this.isEnabled = true,
    this.syncHandler,
    this.tripSyncHandler,
    this.fullSyncHandler,
  });
}

/// Sync result
class SyncResult {
  final SyncStatus status;
  final String? taskId;
  final String? duplicateOf;
  final String? error;

  SyncResult({
    required this.status,
    this.taskId,
    this.duplicateOf,
    this.error,
  });

  factory SyncResult.queued(String taskId) =>
      SyncResult(status: SyncStatus.queued, taskId: taskId);

  factory SyncResult.duplicate(String duplicateOf) =>
      SyncResult(status: SyncStatus.duplicate, duplicateOf: duplicateOf);

  factory SyncResult.error(String error) =>
      SyncResult(status: SyncStatus.error, error: error);

  factory SyncResult.success() =>
      SyncResult(status: SyncStatus.success);
}

enum SyncStatus {
  queued,
  processing,
  success,
  duplicate,
  conflict,
  error,
}

/// Batch sync result
class BatchSyncResult {
  final int total;
  final int queued;
  final int duplicates;
  final int errors;

  BatchSyncResult({
    required this.total,
    required this.queued,
    required this.duplicates,
    required this.errors,
  });

  int get processed => queued + duplicates;
  double get successRate => total > 0 ? queued / total : 0.0;
}

/// Sync event
class SyncEvent {
  final SyncEventType type;
  final String? messageId;
  final String? taskId;
  final String? tripId;
  final String? error;
  final ResolutionMethod? resolutionMethod;
  final ConflictWinner? conflictWinner;

  SyncEvent({
    required this.type,
    this.messageId,
    this.taskId,
    this.tripId,
    this.error,
    this.resolutionMethod,
    this.conflictWinner,
  });

  factory SyncEvent.initialized() =>
      SyncEvent(type: SyncEventType.initialized);

  factory SyncEvent.syncStarted() =>
      SyncEvent(type: SyncEventType.syncStarted);

  factory SyncEvent.syncStopped() =>
      SyncEvent(type: SyncEventType.syncStopped);

  factory SyncEvent.messageSynced(String messageId) =>
      SyncEvent(type: SyncEventType.messageSynced, messageId: messageId);

  factory SyncEvent.conflictResolved({
    required String messageId,
    required ResolutionMethod method,
    required ConflictWinner winner,
  }) =>
      SyncEvent(
        type: SyncEventType.conflictResolved,
        messageId: messageId,
        resolutionMethod: method,
        conflictWinner: winner,
      );

  factory SyncEvent.tripSyncQueued(String tripId) =>
      SyncEvent(type: SyncEventType.tripSyncQueued, tripId: tripId);

  factory SyncEvent.syncFailed({required String taskId, required String error}) =>
      SyncEvent(type: SyncEventType.syncFailed, taskId: taskId, error: error);
}

enum SyncEventType {
  initialized,
  syncStarted,
  syncStopped,
  messageSynced,
  conflictResolved,
  tripSyncQueued,
  syncFailed,
}

/// Sync progress
class SyncProgress {
  final String currentTask;
  final int queueSize;
  final bool isProcessing;

  SyncProgress({
    required this.currentTask,
    required this.queueSize,
    required this.isProcessing,
  });
}

/// Comprehensive sync statistics
class SyncStatistics {
  final int totalMessagesSynced;
  final int totalDuplicatesSkipped;
  final int totalConflictsResolved;
  final DeduplicationStats deduplicationStats;
  final SyncQueueStats queueStats;
  final ConflictResolutionStats conflictStats;
  final bool isSyncing;

  const SyncStatistics({
    required this.totalMessagesSynced,
    required this.totalDuplicatesSkipped,
    required this.totalConflictsResolved,
    required this.deduplicationStats,
    required this.queueStats,
    required this.conflictStats,
    required this.isSyncing,
  });

  double get overallEfficiency {
    final total = totalMessagesSynced + totalDuplicatesSkipped;
    return total > 0 ? totalMessagesSynced / total : 0.0;
  }
}
