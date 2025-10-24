import '../entities/message_entity.dart';

/// Message Repository Interface
/// Defines the contract for message data operations
/// Implements offline-first architecture with automatic sync
abstract class MessageRepository {
  // ============================================================================
  // MESSAGE CRUD OPERATIONS
  // ============================================================================

  /// Send a new message
  /// Saves to local DB immediately, then syncs to Supabase
  /// Returns the created message with server-assigned timestamps
  Future<MessageEntity> sendMessage({
    required String tripId,
    required String senderId,
    required String message,
    required MessageType messageType,
    String? replyToId,
    String? attachmentUrl,
  });

  /// Get all messages for a trip
  /// Returns cached messages immediately, then fetches from server
  /// [limit] - Maximum number of messages to fetch (default: 50)
  /// [offset] - Number of messages to skip (for pagination)
  Future<List<MessageEntity>> getTripMessages({
    required String tripId,
    int limit = 50,
    int offset = 0,
  });

  /// Get a single message by ID
  Future<MessageEntity?> getMessageById(String messageId);

  /// Get messages after a specific timestamp (for incremental updates)
  Future<List<MessageEntity>> getMessagesAfter({
    required String tripId,
    required DateTime timestamp,
  });

  /// Get threaded replies for a message
  Future<List<MessageEntity>> getThreadedReplies(String messageId);

  /// Delete a message (soft delete)
  /// Only the sender can delete their own messages
  Future<void> deleteMessage(String messageId);

  // ============================================================================
  // READ RECEIPTS
  // ============================================================================

  /// Mark a message as read by the current user
  /// Updates both local cache and server
  Future<void> markMessageAsRead({
    required String messageId,
    required String userId,
  });

  /// Mark all messages in a trip as read
  Future<void> markAllMessagesAsRead({
    required String tripId,
    required String userId,
  });

  /// Get unread message count for a trip
  Future<int> getUnreadCount({
    required String tripId,
    required String userId,
  });

  // ============================================================================
  // REACTIONS
  // ============================================================================

  /// Add a reaction to a message
  Future<void> addReaction({
    required String messageId,
    required String userId,
    required String emoji,
  });

  /// Remove a reaction from a message
  Future<void> removeReaction({
    required String messageId,
    required String userId,
    required String emoji,
  });

  // ============================================================================
  // OFFLINE QUEUE OPERATIONS
  // ============================================================================

  /// Get all pending messages in the queue
  /// Used for displaying "sending..." status and retry logic
  Future<List<QueuedMessageEntity>> getPendingMessages();

  /// Get pending messages for a specific trip
  Future<List<QueuedMessageEntity>> getPendingMessagesByTrip(String tripId);

  /// Retry sending a failed message
  Future<void> retryMessage(String queuedMessageId);

  /// Remove a message from the queue (after successful sync or manual deletion)
  Future<void> removeFromQueue(String queuedMessageId);

  /// Sync all pending messages to server
  /// Called when internet connection is restored
  Future<void> syncPendingMessages();

  // ============================================================================
  // REAL-TIME SUBSCRIPTIONS
  // ============================================================================

  /// Subscribe to new messages for a trip
  /// Returns a stream of messages that updates in real-time
  Stream<List<MessageEntity>> subscribeToTripMessages(String tripId);

  /// Subscribe to message updates (reactions, read status, etc.)
  /// Returns a stream that emits whenever a message is updated
  Stream<MessageEntity> subscribeToMessageUpdates(String messageId);

  // ============================================================================
  // CACHE MANAGEMENT
  // ============================================================================

  /// Clear local message cache for a trip
  /// Useful for freeing up storage
  Future<void> clearTripCache(String tripId);

  /// Clear all message cache
  Future<void> clearAllCache();

  /// Get cache size in bytes
  Future<int> getCacheSize();
}
