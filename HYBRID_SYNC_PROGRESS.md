# Hybrid Sync Strategy - IN PROGRESS 🚧

**Date Started:** January 24, 2025
**Status:** Core Services Implemented (50% Complete)

## Overview

Implementing a sophisticated hybrid sync strategy that handles message synchronization from multiple sources (Server, BLE, WiFi Direct, Multipeer) with deduplication, priority-based queuing, and automatic conflict resolution.

## Progress Summary

### ✅ Completed (50%)

#### 1. **Message Deduplication Service** ✅
[message_deduplication_service.dart](lib/features/messaging/data/services/message_deduplication_service.dart) - 300+ lines

**Features:**
- Content-based SHA-256 hashing
- LRU cache with 10,000 message capacity
- 24-hour TTL for cache entries
- Automatic cleanup every hour
- Duplicate detection across all sync sources
- Per-trip cache clearing
- Comprehensive statistics tracking

**Key Methods:**
```dart
// Check if message is duplicate
Future<String?> checkDuplicate({
  required String messageId,
  required String tripId,
  required String senderId,
  required String content,
  required DateTime timestamp,
  String? attachmentUrl,
})

// Register message in cache
void registerMessage(...)

// Get statistics
DeduplicationStats getStatistics()
```

**How It Works:**
1. Generates content hash (SHA-256) from: tripId + senderId + content + attachmentUrl
2. Checks if hash exists in cache
3. Returns canonical message ID if duplicate
4. Registers new messages with timestamp
5. Automatically evicts old entries (LRU + TTL)

#### 2. **Priority-Based Sync Queue** ✅
[priority_sync_queue.dart](lib/features/messaging/data/services/priority_sync_queue.dart) - 400+ lines

**Features:**
- Three priority levels (High, Medium, Low)
- Task-based queuing system
- Automatic retry with exponential backoff
- Pause/Resume capability
- Per-trip task clearing
- Event stream for monitoring
- Comprehensive statistics

**Priority Levels:**
- **High:** User-initiated messages, reactions (immediate)
- **Medium:** Automatic sync, background updates
- **Low:** Bulk sync, historical messages

**Key Methods:**
```dart
// Queue a task
Future<void> enqueue(SyncTask task)

// Queue multiple tasks
Future<void> enqueueBatch(List<SyncTask> tasks)

// Register task handler
void registerHandler(
  String taskType,
  Future<bool> Function(SyncTask) handler,
)

// Control queue
void pause()
void resume()
void clearAll()

// Get statistics
SyncQueueStats getStatistics()
```

**Task Processing:**
1. Tasks queued by priority
2. High priority processed first
3. Automatic retry up to 3 attempts
4. 5-second delay between retries
5. Failed tasks tracked separately

#### 3. **Conflict Resolution Engine** ✅
[conflict_resolution_engine.dart](lib/features/messaging/data/services/conflict_resolution_engine.dart) - 450+ lines

**Features:**
- Last-Write-Wins (LWW) strategy
- Source priority (Server > WiFi Direct > BLE > Local)
- Content-based merging for reactions
- Additive merging for read status
- Deletion propagation
- Multiple resolution strategies

**Resolution Strategies:**
1. **MessageConflictStrategy:** Timestamp + Source priority
2. **ReactionConflictStrategy:** Merge all unique reactions
3. **ReadStatusConflictStrategy:** Union of all readers
4. **DeletionConflictStrategy:** Deletion always wins

**Key Methods:**
```dart
// Resolve message conflict
Future<MessageConflictResolution> resolveMessageConflict({
  required MessageEntity localVersion,
  required MessageEntity remoteVersion,
  required String source,
})

// Resolve reaction conflicts
Future<List<MessageReaction>> resolveReactionConflict({
  required List<MessageReaction> localReactions,
  required List<MessageReaction> remoteReactions,
  required String source,
})

// Get statistics
ConflictResolutionStats getStatistics()
```

**Conflict Resolution Flow:**
1. Compare timestamps (newer wins)
2. If equal, check source priority
3. If still tied, prefer local version
4. For reactions/read status: merge both
5. For deletions: propagate deletion state

### 🚧 Remaining Work (50%)

#### 4. **Sync Coordinator** (Not Started)
Orchestrates all sync operations:
- Coordinates deduplication, queue, and conflict resolution
- Manages sync from multiple sources
- Handles sync lifecycle
- Provides unified sync API

#### 5. **Sync State Management** (Not Started)
Riverpod providers for:
- Sync coordinator provider
- Deduplication stats provider
- Queue stats provider
- Conflict stats provider
- Sync status streams

#### 6. **Sync Status UI** (Not Started)
UI components:
- Sync progress indicator
- Queue status display
- Conflict resolution log
- Statistics dashboard
- Manual sync controls

#### 7. **Integration** (Not Started)
- Integrate with message repository
- Update send/receive flows
- Add sync hooks to P2P services
- Update chat screen with sync status

#### 8. **Testing** (Not Started)
- Deduplication tests
- Priority queue tests
- Conflict resolution tests
- Integration tests
- End-to-end sync tests

#### 9. **Documentation** (Not Started)
- Complete implementation guide
- Architecture diagrams
- Usage examples
- Troubleshooting guide

## Architecture

```
┌─────────────────────────────────────────────────────┐
│              Sync Coordinator (TODO)                │
├─────────────────────────────────────────────────────┤
│  • Orchestrates all sync operations                │
│  • Manages sync lifecycle                          │
│  • Provides unified API                            │
└─────────────────────────────────────────────────────┘
           │              │              │
    ┌──────▼──────┐ ┌────▼─────┐ ┌─────▼──────┐
    │Deduplication│ │ Priority  │ │  Conflict  │
    │   Service   │ │   Queue   │ │ Resolution │
    ├─────────────┤ ├───────────┤ ├────────────┤
    │• SHA-256    │ │• 3 levels │ │• LWW       │
    │• LRU cache  │ │• Retry    │ │• Source    │
    │• TTL 24h    │ │• Pause    │ │• Merge     │
    └─────────────┘ └───────────┘ └────────────┘
           │              │              │
           └──────────────┴──────────────┘
                         │
                ┌────────▼─────────┐
                │  Message Sources │
                ├──────────────────┤
                │ • Server (Supabase)
                │ • BLE P2P        │
                │ • WiFi Direct    │
                │ • Multipeer      │
                └──────────────────┘
```

## Technical Details

### Message Deduplication

**Algorithm:**
```
1. Generate content hash: SHA-256(tripId + senderId + content + attachment)
2. Check cache for hash
3. If found: Return canonical message ID (duplicate)
4. If not found: Add to cache, return null (unique)
5. Periodic cleanup: Remove entries > 24h old
6. LRU eviction: When cache > 10,000 entries
```

**Cache Structure:**
```dart
Map<String, DeduplicationEntry> _messageCache  // Message ID -> Entry
Map<String, String> _contentHashToId          // Hash -> Message ID
LinkedHashMap<String, DateTime> _accessOrder  // LRU tracking
```

### Priority-Based Sync

**Queue Priority:**
```
High Priority Queue (processed first)
├─ User-initiated sends
├─ Reaction additions/removals
└─ Real-time updates

Medium Priority Queue (normal processing)
├─ Automatic sync
├─ Background updates
└─ Read status updates

Low Priority Queue (background processing)
├─ Bulk historical sync
├─ Attachment downloads
└─ Cleanup operations
```

**Retry Strategy:**
```
Attempt 1: Immediate
Attempt 2: 5 seconds delay
Attempt 3: 5 seconds delay
After 3 failures: Mark as failed, stop retrying
```

### Conflict Resolution

**Decision Tree:**
```
1. Compare Timestamps
   ├─ Remote newer → Use remote
   ├─ Local newer → Use local
   └─ Equal → Go to 2

2. Compare Source Priority
   ├─ Server (priority 3) → Use source with higher priority
   ├─ WiFi Direct/Multipeer (priority 2)
   ├─ BLE (priority 1)
   └─ Local (priority 0)

3. Content-Specific Rules
   ├─ Reactions → Merge both (union)
   ├─ Read Status → Merge both (union)
   ├─ Deletion → Propagate deletion
   └─ Message → Use local as fallback
```

**Source Priority Rationale:**
- **Server (Highest):** Authoritative source, persisted
- **WiFi Direct/Multipeer:** High bandwidth, reliable
- **BLE:** Lower bandwidth, may have delays
- **Local (Lowest):** Not yet synced, may be stale

## Use Cases

### 1. Duplicate Prevention
**Scenario:** User sends message, syncs via BLE and WiFi Direct simultaneously

**Flow:**
```
1. Message sent via Server → Saved with hash A
2. Same message arrives via BLE → Hash A detected → Ignored
3. Same message arrives via WiFi Direct → Hash A detected → Ignored
Result: Only one message stored
```

### 2. Priority Sync
**Scenario:** User sends message while bulk sync is running

**Flow:**
```
1. Bulk sync queued → Low priority queue (1000 messages)
2. User sends message → High priority queue (1 message)
3. High priority processed first → User's message syncs immediately
4. Low priority continues in background
Result: User experience not affected by bulk sync
```

### 3. Conflict Resolution
**Scenario:** User adds reaction offline, then receives older update from server

**Flow:**
```
1. Local: Message with reaction A (timestamp: T+10s)
2. Server: Same message with reaction B (timestamp: T+5s)
3. Conflict detected → Local version newer → Keep local
4. Merge reactions → Final: reactions A + B
Result: Both reactions preserved, no data loss
```

## Statistics Tracking

### Deduplication Stats
```dart
- totalChecks: Total deduplication checks
- duplicatesFound: Number of duplicates detected
- uniqueMessages: Number of unique messages
- cacheSize: Current cache size
- duplicateRate: duplicatesFound / totalChecks
```

### Queue Stats
```dart
- totalTasksQueued: Total tasks added
- totalTasksProcessed: Successfully completed
- totalTasksFailed: Failed after retries
- totalTasksRetried: Retry attempts
- queueSize: Current queue size (by priority)
- successRate: processed / queued
```

### Conflict Stats
```dart
- totalConflicts: Total conflicts detected
- resolvedByTimestamp: Resolved using timestamps
- resolvedBySource: Resolved using source priority
- resolvedByContent: Resolved by merging content
- timestampRate: % resolved by timestamp
```

## Performance Considerations

### Memory Usage
- Deduplication cache: ~10,000 messages × 200 bytes = ~2 MB
- Sync queue: ~1,000 tasks × 500 bytes = ~500 KB
- Total estimated: ~3-5 MB

### CPU Usage
- SHA-256 hashing: ~1ms per message
- Queue processing: Minimal (async)
- Conflict resolution: ~0.5ms per conflict

### Cleanup Operations
- Deduplication: Every 1 hour
- Queue: Continuous processing
- Conflicts: On-demand resolution

## Next Steps

1. **Implement Sync Coordinator** (2-3 hours)
   - Integrate all three services
   - Create unified sync API
   - Add lifecycle management

2. **Create Riverpod Providers** (1-2 hours)
   - Service providers
   - Statistics providers
   - Stream providers

3. **Build UI Components** (2-3 hours)
   - Sync status indicator
   - Statistics dashboard
   - Manual controls

4. **Integration & Testing** (3-4 hours)
   - Integrate with repository
   - Update P2P services
   - Comprehensive testing

5. **Documentation** (1-2 hours)
   - Complete guide
   - Examples
   - Troubleshooting

**Estimated Completion:** 9-14 hours remaining

---

**Status:** Core services complete, ready for integration
**Next Session:** Implement Sync Coordinator and complete remaining 50%
