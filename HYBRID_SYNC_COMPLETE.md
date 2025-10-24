# Hybrid Sync Strategy - Complete Implementation

## Overview

The Hybrid Sync Strategy provides robust message synchronization across multiple sources (Server, BLE, WiFi Direct, Multipeer) with automatic deduplication, priority-based queuing, and intelligent conflict resolution.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Sync Coordinator                            │
│  (Orchestrates all sync operations)                             │
└───────┬─────────────────┬─────────────────┬─────────────────────┘
        │                 │                 │
        ▼                 ▼                 ▼
┌───────────────┐ ┌─────────────────┐ ┌──────────────────────┐
│ Deduplication │ │  Priority Queue │ │ Conflict Resolution  │
│    Service    │ │                 │ │      Engine          │
└───────────────┘ └─────────────────┘ └──────────────────────┘
        │                 │                 │
        ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Sync Sources                                │
│  • Server API     • BLE P2P     • WiFi Direct    • Multipeer   │
└─────────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Message Deduplication Service

**Purpose:** Prevents duplicate messages from multiple sync sources

**Key Features:**
- Content-based hashing (SHA-256)
- LRU cache with 10,000 message capacity
- 24-hour TTL with automatic cleanup
- Efficient duplicate detection

**Implementation:**
```dart
// Check if a message is a duplicate
final duplicateId = await deduplicationService.checkDuplicate(
  messageId: 'msg-123',
  tripId: 'trip-456',
  senderId: 'user-789',
  content: 'Hello World',
  timestamp: DateTime.now(),
);

if (duplicateId != null) {
  print('Duplicate of message: $duplicateId');
} else {
  print('Unique message');
}
```

**Statistics:**
```dart
final stats = deduplicationService.getStatistics();
print('Total Checks: ${stats.totalChecks}');
print('Duplicates Found: ${stats.duplicatesFound}');
print('Duplicate Rate: ${(stats.duplicateRate * 100).toStringAsFixed(1)}%');
print('Cache Usage: ${(stats.cacheUsage * 100).toStringAsFixed(1)}%');
```

### 2. Priority Sync Queue

**Purpose:** Manages sync operations with priority-based processing

**Priority Levels:**
- **High:** User-initiated actions, time-sensitive messages
- **Medium:** Automatic sync, reactions, read status updates
- **Low:** Bulk sync, historical message fetching

**Key Features:**
- Three-tier priority queue
- Automatic retry (max 3 attempts, 5-second delay)
- Pause/Resume capability
- Task-based architecture

**Implementation:**
```dart
// Enqueue a high-priority task
final task = SyncTask(
  id: 'sync_msg_123',
  type: 'sync_message',
  tripId: 'trip-456',
  priority: SyncPriority.high,
  data: {'message': message, 'source': 'ble'},
);

await priorityQueue.enqueue(task);

// Register a task handler
priorityQueue.registerHandler('sync_message', (task) async {
  final message = task.data['message'] as MessageEntity;
  // Process message sync
  return true; // Success
});
```

**Queue Management:**
```dart
// Pause processing
priorityQueue.pause();

// Resume processing
priorityQueue.resume();

// Clear all tasks
priorityQueue.clearAll();

// Clear trip-specific tasks
priorityQueue.clearTripTasks('trip-456');
```

### 3. Conflict Resolution Engine

**Purpose:** Resolves conflicts when same message arrives from multiple sources

**Resolution Strategies:**

#### Last-Write-Wins (LWW)
```dart
// Timestamp-based resolution
final resolution = await conflictEngine.resolveMessageConflict(
  localVersion: localMessage,
  remoteVersion: remoteMessage,
  source: 'server',
);

print('Winner: ${resolution.winner}'); // remote (newer timestamp)
print('Method: ${resolution.resolutionMethod}'); // timestamp
```

#### Source Priority
Priority order: **Server (3) > WiFi Direct (2) > BLE (1) > Local (0)**

```dart
// When timestamps are equal, use source priority
// Server wins over BLE
final resolution = await conflictEngine.resolveMessageConflict(
  localVersion: bleMessage,
  remoteVersion: serverMessage,
  source: 'server',
);
// Winner: remote (higher source priority)
```

#### Content Merging
```dart
// Reactions: Merge all unique reactions
final mergedReactions = await conflictEngine.resolveReactionConflict(
  localReactions: [reaction1, reaction2],
  remoteReactions: [reaction2, reaction3],
  source: 'server',
);
// Result: [reaction1, reaction2, reaction3]

// Read Status: Union of all readers
final mergedReadBy = await conflictEngine.resolveReadStatusConflict(
  localReadBy: ['user1', 'user2'],
  remoteReadBy: ['user2', 'user3'],
);
// Result: ['user1', 'user2', 'user3']
```

#### Deletion Propagation
```dart
// Deletion always wins
final isDeleted = await conflictEngine.resolveDeletionConflict(
  localDeleted: false,
  remoteDeleted: true,
  localDeletedAt: null,
  remoteDeletedAt: DateTime.now(),
);
// Result: true (deletion propagates)
```

### 4. Sync Coordinator

**Purpose:** Orchestrates all sync services and provides unified API

**Key Features:**
- Single entry point for all sync operations
- Manages multiple sync sources
- Event and progress streams
- Comprehensive statistics

**Initialization:**
```dart
final coordinator = SyncCoordinator();
await coordinator.initialize();

// Register sync sources
coordinator.registerSyncSource(SyncSource(
  name: 'server',
  isEnabled: true,
  syncHandler: (message) async {
    // Sync message to server
    return true;
  },
  tripSyncHandler: (tripId) async {
    // Sync entire trip
  },
  fullSyncHandler: () async {
    // Full sync from server
  },
));
```

**Message Sync:**
```dart
// Sync a single message
final result = await coordinator.syncMessage(
  message: message,
  source: 'ble',
  priority: SyncPriority.high,
);

if (result.status == SyncStatus.queued) {
  print('Message queued: ${result.taskId}');
} else if (result.status == SyncStatus.duplicate) {
  print('Duplicate of: ${result.duplicateOf}');
}

// Batch sync
final batchResult = await coordinator.syncBatch(
  messages: messages,
  source: 'server',
  priority: SyncPriority.low,
);

print('Queued: ${batchResult.queued}');
print('Duplicates: ${batchResult.duplicates}');
print('Success Rate: ${(batchResult.successRate * 100).toStringAsFixed(1)}%');
```

**Incoming Message Handling:**
```dart
// Handle incoming message with conflict resolution
final resolvedMessage = await coordinator.handleIncomingMessage(
  remoteMessage: incomingMessage,
  localMessage: existingMessage, // null if doesn't exist
  source: 'wifi_direct',
);

// resolvedMessage is the winning version after conflict resolution
```

**Auto Sync:**
```dart
// Start automatic sync (5-minute interval)
await coordinator.startAutoSync(interval: Duration(minutes: 5));

// Stop auto sync
coordinator.stopAutoSync();

// Manual trip sync
await coordinator.syncTrip('trip-456', priority: SyncPriority.high);
```

## Riverpod Integration

### Providers

```dart
// Core service providers
final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coordinator = SyncCoordinator();
  ref.onDispose(() => coordinator.dispose());
  return coordinator;
});

// Stream providers
final syncEventStreamProvider = StreamProvider<SyncEvent>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider);
  return coordinator.eventStream;
});

final syncProgressStreamProvider = StreamProvider<SyncProgress>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider);
  return coordinator.progressStream;
});

// State notifier
final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider);
  return SyncNotifier(coordinator: coordinator);
});

// Helper providers
final isSyncingProvider = Provider<bool>((ref) {
  return ref.watch(syncNotifierProvider).isSyncing;
});

final queueSizeProvider = Provider<int>((ref) {
  final stats = ref.watch(queueStatisticsProvider);
  return stats.totalQueueSize;
});
```

### Usage in Widgets

```dart
class ChatScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSyncing = ref.watch(isSyncingProvider);
    final queueSize = ref.watch(queueSizeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        actions: [
          // Sync button with queue badge
          Stack(
            children: [
              IconButton(
                icon: Icon(isSyncing ? Icons.sync : Icons.sync_alt),
                onPressed: () => SyncStatusSheet.show(context),
              ),
              if (queueSize > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Badge(label: Text('$queueSize')),
                ),
            ],
          ),
        ],
      ),
      body: MessageList(),
    );
  }
}
```

## UI Components

### Sync Status Sheet

Comprehensive dashboard for monitoring sync operations:

```dart
// Show sync status
SyncStatusSheet.show(context);
```

**Features:**
- **Overview Tab:** Sync controls, status summary, quick stats
- **Queue Tab:** Priority queue status, current task, performance metrics
- **Statistics Tab:** Deduplication stats, conflict resolution stats, reset controls

**Controls:**
- Initialize/Start/Stop auto sync
- Pause/Resume queue
- Reset statistics
- View real-time progress

## Event System

### Sync Events

```dart
// Listen to sync events
ref.listen(syncEventStreamProvider, (previous, next) {
  next.whenData((event) {
    switch (event.type) {
      case SyncEventType.initialized:
        print('Sync initialized');
        break;
      case SyncEventType.syncStarted:
        print('Auto sync started');
        break;
      case SyncEventType.messageSynced:
        print('Message synced: ${event.messageId}');
        break;
      case SyncEventType.conflictResolved:
        print('Conflict resolved: ${event.resolutionMethod}');
        break;
      case SyncEventType.syncFailed:
        print('Sync failed: ${event.error}');
        break;
    }
  });
});
```

### Progress Tracking

```dart
// Monitor sync progress
ref.listen(syncProgressStreamProvider, (previous, next) {
  next.whenData((progress) {
    print('Current Task: ${progress.currentTask}');
    print('Queue Size: ${progress.queueSize}');
    print('Is Processing: ${progress.isProcessing}');
  });
});
```

## Statistics & Monitoring

### Comprehensive Statistics

```dart
final syncStats = coordinator.getStatistics();

// Overall metrics
print('Messages Synced: ${syncStats.totalMessagesSynced}');
print('Duplicates Skipped: ${syncStats.totalDuplicatesSkipped}');
print('Conflicts Resolved: ${syncStats.totalConflictsResolved}');
print('Overall Efficiency: ${(syncStats.overallEfficiency * 100).toStringAsFixed(1)}%');

// Deduplication metrics
final dedupStats = syncStats.deduplicationStats;
print('Duplicate Rate: ${(dedupStats.duplicateRate * 100).toStringAsFixed(1)}%');
print('Cache Usage: ${(dedupStats.cacheUsage * 100).toStringAsFixed(1)}%');

// Queue metrics
final queueStats = syncStats.queueStats;
print('Queue Size: ${queueStats.totalQueueSize}');
print('Success Rate: ${(queueStats.successRate * 100).toStringAsFixed(1)}%');
print('Failure Rate: ${(queueStats.failureRate * 100).toStringAsFixed(1)}%');

// Conflict metrics
final conflictStats = syncStats.conflictStats;
print('Timestamp Resolutions: ${conflictStats.resolvedByTimestamp}');
print('Source Resolutions: ${conflictStats.resolvedBySource}');
print('Content Merges: ${conflictStats.resolvedByContent}');
```

## Performance Characteristics

### Deduplication Service
- **Hash Algorithm:** SHA-256
- **Cache Capacity:** 10,000 messages
- **Cache TTL:** 24 hours
- **Cleanup Interval:** 1 hour
- **Eviction Policy:** LRU (Least Recently Used)

### Priority Queue
- **Max Queue Size:** 1,000 tasks
- **Max Retry Attempts:** 3
- **Retry Delay:** 5 seconds
- **Processing:** Sequential by priority (High → Medium → Low)

### Conflict Resolution
- **Primary Strategy:** Last-Write-Wins (timestamp comparison)
- **Tie-Breaker:** Source priority (Server > WiFi Direct > BLE > Local)
- **Merge Strategies:** Reactions (union), Read Status (union), Deletion (propagation)

## Testing

### Unit Tests

Run comprehensive test suite:
```bash
flutter test test/features/messaging/data/services/sync_services_test.dart
```

**Test Coverage:**
- Deduplication Service: 15+ tests
- Priority Queue: 10+ tests
- Conflict Resolution Engine: 10+ tests
- Sync Coordinator: 10+ tests
- Data Classes: 5+ tests

**Total: 50+ unit tests**

### Example Tests

```dart
test('should detect duplicates', () async {
  final result1 = await service.checkDuplicate(...); // null (unique)
  final result2 = await service.checkDuplicate(...); // 'msg-1' (duplicate)
});

test('should resolve by timestamp', () async {
  final resolution = await engine.resolveMessageConflict(...);
  expect(resolution.winner, ConflictWinner.remote);
  expect(resolution.resolutionMethod, ResolutionMethod.timestamp);
});

test('should process high priority first', () async {
  await queue.enqueue(lowPriorityTask);
  await queue.enqueue(highPriorityTask);
  // High priority task processes first
});
```

## Integration Guide

### Step 1: Initialize Sync Coordinator

```dart
// In your app initialization
final coordinator = ref.read(syncCoordinatorProvider);
await ref.read(syncNotifierProvider.notifier).initialize();
```

### Step 2: Register Sync Sources

```dart
// Register server sync
coordinator.registerSyncSource(SyncSource(
  name: 'server',
  isEnabled: true,
  syncHandler: (message) async {
    await messageRepository.syncToServer(message);
    return true;
  },
));

// Register BLE P2P sync
coordinator.registerSyncSource(SyncSource(
  name: 'ble',
  isEnabled: true,
  syncHandler: (message) async {
    await bleService.broadcastMessage(message);
    return true;
  },
));
```

### Step 3: Use in Message Repository

```dart
class MessageRepositoryImpl implements MessageRepository {
  final SyncCoordinator _syncCoordinator;

  @override
  Future<void> sendMessage(MessageEntity message) async {
    // Save locally first
    await localDataSource.saveMessage(message);

    // Sync via coordinator (handles deduplication, queuing, retries)
    final result = await _syncCoordinator.syncMessage(
      message: message,
      source: 'local',
      priority: SyncPriority.high,
    );

    if (result.status == SyncStatus.duplicate) {
      // Already synced from another source
      return;
    }
  }

  @override
  Future<void> receiveMessage(MessageEntity incomingMessage, String source) async {
    // Get existing local version
    final localMessage = await localDataSource.getMessage(incomingMessage.id);

    // Resolve conflicts
    final resolvedMessage = await _syncCoordinator.handleIncomingMessage(
      remoteMessage: incomingMessage,
      localMessage: localMessage,
      source: source,
    );

    // Save resolved version
    await localDataSource.saveMessage(resolvedMessage);
  }
}
```

### Step 4: Monitor in UI

```dart
// Show sync indicator
Consumer(
  builder: (context, ref, child) {
    final isSyncing = ref.watch(isSyncingProvider);
    return Icon(isSyncing ? Icons.sync : Icons.sync_disabled);
  },
)

// Show queue badge
Consumer(
  builder: (context, ref, child) {
    final queueSize = ref.watch(queueSizeProvider);
    if (queueSize == 0) return SizedBox();
    return Badge(label: Text('$queueSize'));
  },
)
```

## Best Practices

### 1. Priority Assignment

```dart
// User-initiated actions: HIGH
await coordinator.syncMessage(
  message: userMessage,
  source: 'local',
  priority: SyncPriority.high,
);

// Background sync: MEDIUM
await coordinator.syncMessage(
  message: autoMessage,
  source: 'ble',
  priority: SyncPriority.medium,
);

// Bulk historical sync: LOW
await coordinator.syncBatch(
  messages: historicalMessages,
  source: 'server',
  priority: SyncPriority.low,
);
```

### 2. Error Handling

```dart
final result = await coordinator.syncMessage(...);

switch (result.status) {
  case SyncStatus.queued:
    // Success - message queued for sync
    break;
  case SyncStatus.duplicate:
    // Already synced - no action needed
    break;
  case SyncStatus.error:
    // Handle error
    showError(result.error);
    break;
}
```

### 3. Resource Management

```dart
// Clear trip data when trip is deleted
coordinator.clearTripSync(tripId);

// Reset statistics periodically
coordinator.resetStatistics();

// Dispose when done
coordinator.dispose();
```

### 4. Event Monitoring

```dart
// Log important events
ref.listen(syncEventStreamProvider, (previous, next) {
  next.whenData((event) {
    if (event.type == SyncEventType.conflictResolved) {
      analytics.log('conflict_resolved', {
        'method': event.resolutionMethod,
        'winner': event.winner,
      });
    }
  });
});
```

## Troubleshooting

### High Duplicate Rate

```dart
final stats = deduplicationService.getStatistics();
if (stats.duplicateRate > 0.3) {
  // More than 30% duplicates - check:
  // 1. Multiple sync sources sending same messages
  // 2. Retry logic creating duplicates
  // 3. Cache size too small
}
```

### Queue Backing Up

```dart
final queueStats = priorityQueue.getStatistics();
if (queueStats.totalQueueSize > 500) {
  // Queue is backing up - check:
  // 1. Network connectivity
  // 2. Sync handler failures
  // 3. Processing speed

  // Consider pausing low-priority sync
  priorityQueue.pause();
}
```

### Many Conflicts

```dart
final conflictStats = conflictEngine.getStatistics();
if (conflictStats.totalConflicts > 100) {
  // Many conflicts - check:
  // 1. Time synchronization across devices
  // 2. Network delays causing out-of-order messages
  // 3. Source priority configuration
}
```

## Migration Guide

### From Simple Sync to Hybrid Sync

```dart
// Before: Direct server sync
await messageRepository.syncToServer(message);

// After: Coordinated sync with deduplication
await coordinator.syncMessage(
  message: message,
  source: 'local',
  priority: SyncPriority.high,
);
```

### Handling Conflicts

```dart
// Before: Last write wins (no conflict resolution)
await localDataSource.saveMessage(incomingMessage);

// After: Intelligent conflict resolution
final resolved = await coordinator.handleIncomingMessage(
  remoteMessage: incomingMessage,
  localMessage: existingMessage,
  source: 'ble',
);
await localDataSource.saveMessage(resolved);
```

## Future Enhancements

### Planned Features

1. **Custom Conflict Strategies**
   - Allow apps to register custom resolution logic
   - Per-message-type strategies

2. **Selective Sync**
   - Sync only specific message types
   - Priority-based field syncing

3. **Bandwidth Optimization**
   - Delta sync (only changed fields)
   - Compression for batch sync

4. **Advanced Analytics**
   - Sync performance metrics
   - Source reliability scoring
   - Predictive queue sizing

## Conclusion

The Hybrid Sync Strategy provides a robust, efficient, and scalable solution for multi-source message synchronization. Key benefits:

- **Automatic deduplication** - No duplicate messages from multiple sources
- **Priority-based queuing** - User actions processed first
- **Intelligent conflict resolution** - Data consistency across devices
- **Comprehensive monitoring** - Full visibility into sync operations
- **High performance** - Optimized for speed and reliability

## Support

For issues or questions:
- Check test cases for usage examples
- Review code documentation
- File issues on project repository
