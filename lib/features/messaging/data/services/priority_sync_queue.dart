import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Priority-Based Sync Queue
/// Manages message synchronization with priority levels
/// High priority: User-initiated messages, reactions
/// Medium priority: Automatic sync, background updates
/// Low priority: Bulk sync, historical messages
class PrioritySyncQueue {
  static final PrioritySyncQueue _instance = PrioritySyncQueue._internal();
  factory PrioritySyncQueue() => _instance;
  PrioritySyncQueue._internal();

  // Priority queues
  final Queue<SyncTask> _highPriorityQueue = Queue<SyncTask>();
  final Queue<SyncTask> _mediumPriorityQueue = Queue<SyncTask>();
  final Queue<SyncTask> _lowPriorityQueue = Queue<SyncTask>();

  // Processing state
  bool _isProcessing = false;
  bool _isPaused = false;
  SyncTask? _currentTask;

  // Configuration
  static const int MAX_QUEUE_SIZE = 1000;
  static const int MAX_RETRY_ATTEMPTS = 3;
  static const Duration RETRY_DELAY = Duration(seconds: 5);

  // Task callbacks
  final Map<String, Future<bool> Function(SyncTask)> _taskHandlers = {};

  // Statistics
  int _totalTasksQueued = 0;
  int _totalTasksProcessed = 0;
  int _totalTasksFailed = 0;
  int _totalTasksRetried = 0;

  // Streams
  final StreamController<SyncQueueEvent> _eventController =
      StreamController<SyncQueueEvent>.broadcast();

  Stream<SyncQueueEvent> get eventStream => _eventController.stream;

  bool get isProcessing => _isProcessing;
  bool get isPaused => _isPaused;
  int get queueSize =>
      _highPriorityQueue.length +
      _mediumPriorityQueue.length +
      _lowPriorityQueue.length;

  /// Register a task handler for a specific task type
  void registerHandler(
    String taskType,
    Future<bool> Function(SyncTask) handler,
  ) {
    _taskHandlers[taskType] = handler;
    debugPrint('Registered handler for task type: $taskType');
  }

  /// Add a task to the sync queue
  Future<void> enqueue(SyncTask task) async {
    if (queueSize >= MAX_QUEUE_SIZE) {
      debugPrint('Sync queue full, dropping task: ${task.id}');
      _eventController.add(SyncQueueEvent.taskDropped(task));
      return;
    }

    // Add to appropriate priority queue
    switch (task.priority) {
      case SyncPriority.high:
        _highPriorityQueue.add(task);
        break;
      case SyncPriority.medium:
        _mediumPriorityQueue.add(task);
        break;
      case SyncPriority.low:
        _lowPriorityQueue.add(task);
        break;
    }

    _totalTasksQueued++;
    _eventController.add(SyncQueueEvent.taskQueued(task));

    debugPrint(
      'Task queued: ${task.id} (${task.priority.name}) - Queue size: $queueSize',
    );

    // Start processing if not already running
    if (!_isProcessing && !_isPaused) {
      _startProcessing();
    }
  }

  /// Add multiple tasks in batch
  Future<void> enqueueBatch(List<SyncTask> tasks) async {
    for (final task in tasks) {
      await enqueue(task);
    }
  }

  /// Remove a task from the queue
  bool removeTask(String taskId) {
    bool removed = false;

    // Try to remove from each queue
    removed = _removeFromQueue(_highPriorityQueue, taskId) ||
        _removeFromQueue(_mediumPriorityQueue, taskId) ||
        _removeFromQueue(_lowPriorityQueue, taskId);

    if (removed) {
      debugPrint('Task removed: $taskId');
      _eventController.add(SyncQueueEvent.taskCancelled(taskId));
    }

    return removed;
  }

  /// Clear all tasks for a specific trip
  void clearTripTasks(String tripId) {
    int removed = 0;

    removed += _removeTripTasksFromQueue(_highPriorityQueue, tripId);
    removed += _removeTripTasksFromQueue(_mediumPriorityQueue, tripId);
    removed += _removeTripTasksFromQueue(_lowPriorityQueue, tripId);

    debugPrint('Cleared $removed tasks for trip: $tripId');
  }

  /// Pause queue processing
  void pause() {
    _isPaused = true;
    debugPrint('Sync queue paused');
    if (!_eventController.isClosed) {
      _eventController.add(SyncQueueEvent.queuePaused());
    }
  }

  /// Resume queue processing
  void resume() {
    _isPaused = false;
    debugPrint('Sync queue resumed');
    if (!_eventController.isClosed) {
      _eventController.add(SyncQueueEvent.queueResumed());
    }

    if (!_isProcessing && queueSize > 0) {
      _startProcessing();
    }
  }

  /// Clear all tasks in the queue
  void clearAll() {
    _highPriorityQueue.clear();
    _mediumPriorityQueue.clear();
    _lowPriorityQueue.clear();
    debugPrint('All sync tasks cleared');
    if (!_eventController.isClosed) {
      _eventController.add(SyncQueueEvent.queueCleared());
    }
  }

  /// Get queue statistics
  SyncQueueStats getStatistics() {
    return SyncQueueStats(
      totalTasksQueued: _totalTasksQueued,
      totalTasksProcessed: _totalTasksProcessed,
      totalTasksFailed: _totalTasksFailed,
      totalTasksRetried: _totalTasksRetried,
      highPriorityCount: _highPriorityQueue.length,
      mediumPriorityCount: _mediumPriorityQueue.length,
      lowPriorityCount: _lowPriorityQueue.length,
      currentTask: _currentTask,
      isProcessing: _isProcessing,
      isPaused: _isPaused,
    );
  }

  /// Reset statistics
  void resetStatistics() {
    _totalTasksQueued = 0;
    _totalTasksProcessed = 0;
    _totalTasksFailed = 0;
    _totalTasksRetried = 0;
  }

  // Private methods

  void _startProcessing() async {
    if (_isProcessing) return;

    _isProcessing = true;
    _eventController.add(SyncQueueEvent.processingStarted());

    while (queueSize > 0 && !_isPaused) {
      // Get next task based on priority
      final task = _dequeue();
      if (task == null) break;

      _currentTask = task;
      _eventController.add(SyncQueueEvent.taskStarted(task));

      // Process task
      final success = await _processTask(task);

      if (success) {
        _totalTasksProcessed++;
        _eventController.add(SyncQueueEvent.taskCompleted(task));
      } else {
        // Retry logic
        if (task.retryCount < MAX_RETRY_ATTEMPTS) {
          debugPrint('Retrying task: ${task.id} (attempt ${task.retryCount + 1})');
          _totalTasksRetried++;

          // Re-queue with incremented retry count
          final retriedTask = task.copyWith(retryCount: task.retryCount + 1);

          // Wait before retry
          await Future.delayed(RETRY_DELAY);

          await enqueue(retriedTask);
          _eventController.add(SyncQueueEvent.taskRetried(retriedTask));
        } else {
          _totalTasksFailed++;
          _eventController.add(SyncQueueEvent.taskFailed(task));
          debugPrint('Task failed after ${task.retryCount} retries: ${task.id}');
        }
      }

      _currentTask = null;
    }

    _isProcessing = false;
    _eventController.add(SyncQueueEvent.processingCompleted());
    debugPrint('Sync queue processing completed');
  }

  SyncTask? _dequeue() {
    // Priority order: High > Medium > Low
    if (_highPriorityQueue.isNotEmpty) {
      return _highPriorityQueue.removeFirst();
    } else if (_mediumPriorityQueue.isNotEmpty) {
      return _mediumPriorityQueue.removeFirst();
    } else if (_lowPriorityQueue.isNotEmpty) {
      return _lowPriorityQueue.removeFirst();
    }
    return null;
  }

  Future<bool> _processTask(SyncTask task) async {
    try {
      final handler = _taskHandlers[task.type];
      if (handler == null) {
        debugPrint('No handler registered for task type: ${task.type}');
        return false;
      }

      return await handler(task);
    } catch (e) {
      debugPrint('Error processing task ${task.id}: $e');
      return false;
    }
  }

  bool _removeFromQueue(Queue<SyncTask> queue, String taskId) {
    final originalLength = queue.length;
    queue.removeWhere((task) => task.id == taskId);
    return queue.length < originalLength;
  }

  int _removeTripTasksFromQueue(Queue<SyncTask> queue, String tripId) {
    final originalLength = queue.length;
    queue.removeWhere((task) => task.tripId == tripId);
    return originalLength - queue.length;
  }

  /// Dispose resources
  void dispose() {
    _eventController.close();
    _highPriorityQueue.clear();
    _mediumPriorityQueue.clear();
    _lowPriorityQueue.clear();
    _taskHandlers.clear();
  }
}

// ============================================================================
// DATA CLASSES
// ============================================================================

/// Sync task priority levels
enum SyncPriority {
  high, // User-initiated, time-sensitive
  medium, // Automatic sync, reactions
  low, // Bulk sync, historical data
}

/// Sync task
class SyncTask {
  final String id;
  final String type; // 'send_message', 'sync_reactions', 'bulk_sync', etc.
  final String tripId;
  final SyncPriority priority;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;

  SyncTask({
    required this.id,
    required this.type,
    required this.tripId,
    required this.priority,
    required this.data,
    DateTime? createdAt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  SyncTask copyWith({
    String? id,
    String? type,
    String? tripId,
    SyncPriority? priority,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
  }) {
    return SyncTask(
      id: id ?? this.id,
      type: type ?? this.type,
      tripId: tripId ?? this.tripId,
      priority: priority ?? this.priority,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// Sync queue event
class SyncQueueEvent {
  final SyncQueueEventType type;
  final SyncTask? task;
  final String? taskId;

  SyncQueueEvent({
    required this.type,
    this.task,
    this.taskId,
  });

  factory SyncQueueEvent.taskQueued(SyncTask task) =>
      SyncQueueEvent(type: SyncQueueEventType.taskQueued, task: task);

  factory SyncQueueEvent.taskStarted(SyncTask task) =>
      SyncQueueEvent(type: SyncQueueEventType.taskStarted, task: task);

  factory SyncQueueEvent.taskCompleted(SyncTask task) =>
      SyncQueueEvent(type: SyncQueueEventType.taskCompleted, task: task);

  factory SyncQueueEvent.taskFailed(SyncTask task) =>
      SyncQueueEvent(type: SyncQueueEventType.taskFailed, task: task);

  factory SyncQueueEvent.taskRetried(SyncTask task) =>
      SyncQueueEvent(type: SyncQueueEventType.taskRetried, task: task);

  factory SyncQueueEvent.taskCancelled(String taskId) =>
      SyncQueueEvent(type: SyncQueueEventType.taskCancelled, taskId: taskId);

  factory SyncQueueEvent.taskDropped(SyncTask task) =>
      SyncQueueEvent(type: SyncQueueEventType.taskDropped, task: task);

  factory SyncQueueEvent.processingStarted() =>
      SyncQueueEvent(type: SyncQueueEventType.processingStarted);

  factory SyncQueueEvent.processingCompleted() =>
      SyncQueueEvent(type: SyncQueueEventType.processingCompleted);

  factory SyncQueueEvent.queuePaused() =>
      SyncQueueEvent(type: SyncQueueEventType.queuePaused);

  factory SyncQueueEvent.queueResumed() =>
      SyncQueueEvent(type: SyncQueueEventType.queueResumed);

  factory SyncQueueEvent.queueCleared() =>
      SyncQueueEvent(type: SyncQueueEventType.queueCleared);
}

enum SyncQueueEventType {
  taskQueued,
  taskStarted,
  taskCompleted,
  taskFailed,
  taskRetried,
  taskCancelled,
  taskDropped,
  processingStarted,
  processingCompleted,
  queuePaused,
  queueResumed,
  queueCleared,
}

/// Sync queue statistics
class SyncQueueStats {
  final int totalTasksQueued;
  final int totalTasksProcessed;
  final int totalTasksFailed;
  final int totalTasksRetried;
  final int highPriorityCount;
  final int mediumPriorityCount;
  final int lowPriorityCount;
  final SyncTask? currentTask;
  final bool isProcessing;
  final bool isPaused;

  const SyncQueueStats({
    required this.totalTasksQueued,
    required this.totalTasksProcessed,
    required this.totalTasksFailed,
    required this.totalTasksRetried,
    required this.highPriorityCount,
    required this.mediumPriorityCount,
    required this.lowPriorityCount,
    this.currentTask,
    required this.isProcessing,
    required this.isPaused,
  });

  int get totalQueueSize =>
      highPriorityCount + mediumPriorityCount + lowPriorityCount;

  double get successRate => totalTasksQueued > 0
      ? totalTasksProcessed / totalTasksQueued
      : 0.0;

  double get failureRate => totalTasksQueued > 0
      ? totalTasksFailed / totalTasksQueued
      : 0.0;
}
