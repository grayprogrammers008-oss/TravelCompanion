import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/sync_coordinator.dart';
import '../../data/services/message_deduplication_service.dart';
import '../../data/services/priority_sync_queue.dart';
import '../../data/services/conflict_resolution_engine.dart';
import '../../domain/entities/message_entity.dart';

// ============================================================================
// CORE PROVIDERS
// ============================================================================

/// Sync Coordinator singleton provider
final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coordinator = SyncCoordinator();
  ref.onDispose(() => coordinator.dispose());
  return coordinator;
});

/// Deduplication Service singleton provider
final messageDeduplicationServiceProvider = Provider<MessageDeduplicationService>((ref) {
  final service = MessageDeduplicationService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Priority Sync Queue singleton provider
final prioritySyncQueueProvider = Provider<PrioritySyncQueue>((ref) {
  final queue = PrioritySyncQueue();
  ref.onDispose(() => queue.dispose());
  return queue;
});

/// Conflict Resolution Engine singleton provider
final conflictResolutionEngineProvider = Provider<ConflictResolutionEngine>((ref) {
  return ConflictResolutionEngine();
});

// ============================================================================
// STREAM PROVIDERS
// ============================================================================

/// Sync events stream provider
final syncEventStreamProvider = StreamProvider<SyncEvent>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider);
  return coordinator.eventStream;
});

/// Sync progress stream provider
final syncProgressStreamProvider = StreamProvider<SyncProgress>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider);
  return coordinator.progressStream;
});

/// Sync queue events stream provider
final syncQueueEventStreamProvider = StreamProvider<SyncQueueEvent>((ref) {
  final queue = ref.watch(prioritySyncQueueProvider);
  return queue.eventStream;
});

// ============================================================================
// STATE PROVIDERS
// ============================================================================

/// Sync statistics provider
final syncStatisticsProvider = Provider<SyncStatistics>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider);

  // Watch event stream to trigger rebuilds
  ref.watch(syncEventStreamProvider);

  return coordinator.getStatistics();
});

/// Deduplication statistics provider
final deduplicationStatisticsProvider = Provider<DeduplicationStats>((ref) {
  final service = ref.watch(messageDeduplicationServiceProvider);

  // Watch event stream to trigger rebuilds
  ref.watch(syncEventStreamProvider);

  return service.getStatistics();
});

/// Queue statistics provider
final queueStatisticsProvider = Provider<SyncQueueStats>((ref) {
  final queue = ref.watch(prioritySyncQueueProvider);

  // Watch queue events to trigger rebuilds
  ref.watch(syncQueueEventStreamProvider);

  return queue.getStatistics();
});

/// Conflict resolution statistics provider
final conflictStatisticsProvider = Provider<ConflictResolutionStats>((ref) {
  final engine = ref.watch(conflictResolutionEngineProvider);

  // Watch event stream to trigger rebuilds
  ref.watch(syncEventStreamProvider);

  return engine.getStatistics();
});

// ============================================================================
// STATE NOTIFIER
// ============================================================================

/// Sync state
class SyncState {
  final bool isInitialized;
  final bool isSyncing;
  final String? currentTripId;
  final SyncStatus status;
  final String? errorMessage;
  final int activeSourcesCount;
  final DateTime? lastSyncTime;

  const SyncState({
    this.isInitialized = false,
    this.isSyncing = false,
    this.currentTripId,
    this.status = SyncStatus.idle,
    this.errorMessage,
    this.activeSourcesCount = 0,
    this.lastSyncTime,
  });

  SyncState copyWith({
    bool? isInitialized,
    bool? isSyncing,
    String? currentTripId,
    SyncStatus? status,
    String? errorMessage,
    int? activeSourcesCount,
    DateTime? lastSyncTime,
  }) {
    return SyncState(
      isInitialized: isInitialized ?? this.isInitialized,
      isSyncing: isSyncing ?? this.isSyncing,
      currentTripId: currentTripId ?? this.currentTripId,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      activeSourcesCount: activeSourcesCount ?? this.activeSourcesCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

enum SyncStatus {
  idle,
  initializing,
  ready,
  syncing,
  paused,
  error,
}

/// Sync state notifier
class SyncNotifier extends StateNotifier<SyncState> {
  final SyncCoordinator _coordinator;
  StreamSubscription<SyncEvent>? _eventSubscription;

  SyncNotifier({required SyncCoordinator coordinator})
      : _coordinator = coordinator,
        super(const SyncState()) {
    _listenToSyncEvents();
  }

  /// Initialize sync coordinator
  Future<void> initialize() async {
    try {
      state = state.copyWith(status: SyncStatus.initializing);

      await _coordinator.initialize();

      state = state.copyWith(
        isInitialized: true,
        status: SyncStatus.ready,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Register a sync source
  void registerSyncSource(SyncSource source) {
    _coordinator.registerSyncSource(source);
    state = state.copyWith(
      activeSourcesCount: state.activeSourcesCount + 1,
    );
  }

  /// Sync a single message
  Future<SyncResult> syncMessage({
    required MessageEntity message,
    required String source,
    SyncPriority priority = SyncPriority.medium,
  }) async {
    return await _coordinator.syncMessage(
      message: message,
      source: source,
      priority: priority,
    );
  }

  /// Sync multiple messages in batch
  Future<BatchSyncResult> syncBatch({
    required List<MessageEntity> messages,
    required String source,
    SyncPriority priority = SyncPriority.low,
  }) async {
    return await _coordinator.syncBatch(
      messages: messages,
      source: source,
      priority: priority,
    );
  }

  /// Handle incoming message with conflict resolution
  Future<MessageEntity> handleIncomingMessage({
    required MessageEntity remoteMessage,
    required MessageEntity? localMessage,
    required String source,
  }) async {
    return await _coordinator.handleIncomingMessage(
      remoteMessage: remoteMessage,
      localMessage: localMessage,
      source: source,
    );
  }

  /// Start automatic sync
  Future<void> startAutoSync({Duration interval = const Duration(minutes: 5)}) async {
    state = state.copyWith(
      isSyncing: true,
      status: SyncStatus.syncing,
    );

    await _coordinator.startAutoSync(interval: interval);
  }

  /// Stop automatic sync
  void stopAutoSync() {
    _coordinator.stopAutoSync();

    state = state.copyWith(
      isSyncing: false,
      status: SyncStatus.ready,
    );
  }

  /// Manually sync a specific trip
  Future<void> syncTrip(String tripId, {SyncPriority priority = SyncPriority.high}) async {
    state = state.copyWith(currentTripId: tripId);

    await _coordinator.syncTrip(tripId, priority: priority);

    state = state.copyWith(
      lastSyncTime: DateTime.now(),
      currentTripId: null,
    );
  }

  /// Clear sync data for a trip
  void clearTripSync(String tripId) {
    _coordinator.clearTripSync(tripId);
  }

  /// Reset all statistics
  void resetStatistics() {
    _coordinator.resetStatistics();
  }

  void _listenToSyncEvents() {
    _eventSubscription = _coordinator.eventStream.listen((event) {
      switch (event.type) {
        case SyncEventType.initialized:
          state = state.copyWith(
            isInitialized: true,
            status: SyncStatus.ready,
          );
          break;
        case SyncEventType.syncStarted:
          state = state.copyWith(
            isSyncing: true,
            status: SyncStatus.syncing,
          );
          break;
        case SyncEventType.syncStopped:
          state = state.copyWith(
            isSyncing: false,
            status: SyncStatus.ready,
          );
          break;
        case SyncEventType.syncFailed:
          state = state.copyWith(
            status: SyncStatus.error,
            errorMessage: event.error,
          );
          break;
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}

/// Sync state notifier provider
final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider);
  return SyncNotifier(coordinator: coordinator);
});

// ============================================================================
// HELPER PROVIDERS
// ============================================================================

/// Check if sync is initialized
final isSyncInitializedProvider = Provider<bool>((ref) {
  return ref.watch(syncNotifierProvider).isInitialized;
});

/// Check if currently syncing
final isSyncingProvider = Provider<bool>((ref) {
  return ref.watch(syncNotifierProvider).isSyncing;
});

/// Get sync error message
final syncErrorProvider = Provider<String?>((ref) {
  return ref.watch(syncNotifierProvider).errorMessage;
});

/// Get active sources count
final activeSourcesCountProvider = Provider<int>((ref) {
  return ref.watch(syncNotifierProvider).activeSourcesCount;
});

/// Get last sync time
final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  return ref.watch(syncNotifierProvider).lastSyncTime;
});

// ============================================================================
// QUEUE MANAGEMENT PROVIDERS
// ============================================================================

/// Queue size provider
final queueSizeProvider = Provider<int>((ref) {
  final stats = ref.watch(queueStatisticsProvider);
  return stats.totalQueueSize;
});

/// Queue is processing provider
final queueIsProcessingProvider = Provider<bool>((ref) {
  final stats = ref.watch(queueStatisticsProvider);
  return stats.isProcessing;
});

/// Queue is paused provider
final queueIsPausedProvider = Provider<bool>((ref) {
  final stats = ref.watch(queueStatisticsProvider);
  return stats.isPaused;
});

/// Current task provider
final currentTaskProvider = Provider<SyncTask?>((ref) {
  final stats = ref.watch(queueStatisticsProvider);
  return stats.currentTask;
});

// ============================================================================
// STATISTICS AGGREGATION PROVIDERS
// ============================================================================

/// Overall sync efficiency provider
final syncEfficiencyProvider = Provider<double>((ref) {
  final stats = ref.watch(syncStatisticsProvider);
  return stats.overallEfficiency;
});

/// Duplicate rate provider
final duplicateRateProvider = Provider<double>((ref) {
  final stats = ref.watch(deduplicationStatisticsProvider);
  return stats.duplicateRate;
});

/// Queue success rate provider
final queueSuccessRateProvider = Provider<double>((ref) {
  final stats = ref.watch(queueStatisticsProvider);
  return stats.successRate;
});

/// Queue failure rate provider
final queueFailureRateProvider = Provider<double>((ref) {
  final stats = ref.watch(queueStatisticsProvider);
  return stats.failureRate;
});

/// Conflict resolution by timestamp rate provider
final conflictTimestampRateProvider = Provider<double>((ref) {
  final stats = ref.watch(conflictStatisticsProvider);
  return stats.timestampRate;
});

/// Conflict resolution by source rate provider
final conflictSourceRateProvider = Provider<double>((ref) {
  final stats = ref.watch(conflictStatisticsProvider);
  return stats.sourceRate;
});

/// Conflict resolution by content rate provider
final conflictContentRateProvider = Provider<double>((ref) {
  final stats = ref.watch(conflictStatisticsProvider);
  return stats.contentRate;
});
