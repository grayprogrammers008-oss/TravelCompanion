import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../shared/models/message_model.dart';

/// Message Local Data Source
/// Handles all local Hive operations for offline-first messaging
class MessageLocalDataSource {
  static const String _messagesBox = 'messages';
  static const String _queueBox = 'message_queue';
  static const String _metadataBox = 'message_metadata';

  /// Initialize Hive boxes for messages
  Future<void> initialize() async {
    try {
      debugPrint('🔵 [LocalDataSource] Initializing Hive boxes');

      if (!Hive.isBoxOpen(_messagesBox)) {
        await Hive.openBox<Map>(_messagesBox);
      }
      if (!Hive.isBoxOpen(_queueBox)) {
        await Hive.openBox<Map>(_queueBox);
      }
      if (!Hive.isBoxOpen(_metadataBox)) {
        await Hive.openBox<Map>(_metadataBox);
      }

      debugPrint('✅ [LocalDataSource] Hive boxes initialized');
    } catch (e) {
      debugPrint('❌ [LocalDataSource] Failed to initialize: $e');
      rethrow;
    }
  }

  /// Get messages box
  Box<Map> get _messages => Hive.box<Map>(_messagesBox);

  /// Get queue box
  Box<Map> get _queue => Hive.box<Map>(_queueBox);

  /// Get metadata box
  Box<Map> get _metadata => Hive.box<Map>(_metadataBox);

  // ============================================================================
  // MESSAGE CRUD OPERATIONS
  // ============================================================================

  /// Save message to local cache
  Future<void> saveMessage(MessageModel message) async {
    try {
      debugPrint('🔵 [LocalDataSource] saveMessage: ${message.id}');

      await _messages.put(message.id, message.toJson());

      // Update trip metadata (last message timestamp)
      await _updateTripMetadata(message.tripId, message.createdAt);

      debugPrint('✅ [LocalDataSource] Message saved');
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalDataSource] saveMessage FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// Save multiple messages (batch operation)
  Future<void> saveMessages(List<MessageModel> messages) async {
    try {
      debugPrint('🔵 [LocalDataSource] saveMessages: ${messages.length} messages');

      final batch = <String, Map<String, dynamic>>{};
      for (final message in messages) {
        batch[message.id] = message.toJson();
      }

      await _messages.putAll(batch);

      // Update metadata for each trip
      final tripIds = messages.map((m) => m.tripId).toSet();
      for (final tripId in tripIds) {
        final tripMessages = messages.where((m) => m.tripId == tripId);
        if (tripMessages.isNotEmpty) {
          final latest = tripMessages.reduce(
            (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
          );
          await _updateTripMetadata(tripId, latest.createdAt);
        }
      }

      debugPrint('✅ [LocalDataSource] Batch save complete');
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalDataSource] saveMessages FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// Get messages for a trip from local cache
  Future<List<MessageModel>> getTripMessages({
    required String tripId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      debugPrint('🔵 [LocalDataSource] getTripMessages: $tripId');
      debugPrint('   Limit: $limit, Offset: $offset');

      // Get all messages from cache
      final allMessages = _messages.values
          .map((json) => MessageModel.fromJson(Map<String, dynamic>.from(json)))
          .where((m) => m.tripId == tripId && !m.isDeleted)
          .toList();

      // Sort by created_at descending
      allMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Apply pagination
      final start = offset;
      final end = (offset + limit).clamp(0, allMessages.length);
      final paginatedMessages = allMessages.sublist(
        start.clamp(0, allMessages.length),
        end,
      );

      debugPrint('   ✅ Retrieved ${paginatedMessages.length} messages from cache');
      return paginatedMessages;
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalDataSource] getTripMessages FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return [];
    }
  }

  /// Get a single message by ID
  Future<MessageModel?> getMessageById(String messageId) async {
    try {
      debugPrint('🔵 [LocalDataSource] getMessageById: $messageId');

      final json = _messages.get(messageId);
      if (json == null) {
        debugPrint('   ⚠️ Message not found in cache');
        return null;
      }

      final message = MessageModel.fromJson(Map<String, dynamic>.from(json));
      debugPrint('✅ [LocalDataSource] Message found in cache');
      return message;
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalDataSource] getMessageById FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return null;
    }
  }

  /// Get messages created after a specific timestamp
  Future<List<MessageModel>> getMessagesAfter({
    required String tripId,
    required DateTime timestamp,
  }) async {
    try {
      debugPrint('🔵 [LocalDataSource] getMessagesAfter');
      debugPrint('   Trip ID: $tripId, After: $timestamp');

      final messages = _messages.values
          .map((json) => MessageModel.fromJson(Map<String, dynamic>.from(json)))
          .where((m) =>
              m.tripId == tripId &&
              !m.isDeleted &&
              m.createdAt.isAfter(timestamp))
          .toList();

      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('   ✅ Found ${messages.length} messages after timestamp');
      return messages;
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalDataSource] getMessagesAfter FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return [];
    }
  }

  /// Get threaded replies for a message
  Future<List<MessageModel>> getThreadedReplies(String messageId) async {
    try {
      debugPrint('🔵 [LocalDataSource] getThreadedReplies: $messageId');

      final replies = _messages.values
          .map((json) => MessageModel.fromJson(Map<String, dynamic>.from(json)))
          .where((m) => m.replyToId == messageId && !m.isDeleted)
          .toList();

      replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      debugPrint('   ✅ Found ${replies.length} replies');
      return replies;
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalDataSource] getThreadedReplies FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return [];
    }
  }

  /// Delete a message from cache (soft delete)
  Future<void> deleteMessage(String messageId) async {
    try {
      debugPrint('🔵 [LocalDataSource] deleteMessage: $messageId');

      final json = _messages.get(messageId);
      if (json != null) {
        final message = MessageModel.fromJson(Map<String, dynamic>.from(json));
        final updated = MessageModel(
          id: message.id,
          tripId: message.tripId,
          senderId: message.senderId,
          message: message.message,
          messageType: message.messageType,
          replyToId: message.replyToId,
          attachmentUrl: message.attachmentUrl,
          reactions: message.reactions,
          readBy: message.readBy,
          isDeleted: true, // Soft delete
          createdAt: message.createdAt,
          updatedAt: DateTime.now(),
          senderName: message.senderName,
          senderAvatarUrl: message.senderAvatarUrl,
        );

        await _messages.put(messageId, updated.toJson());
        debugPrint('✅ [LocalDataSource] Message soft-deleted');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalDataSource] deleteMessage FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  // ============================================================================
  // READ RECEIPTS
  // ============================================================================

  /// Mark message as read by adding user ID to read_by array
  Future<void> markMessageAsRead({
    required String messageId,
    required String userId,
  }) async {
    try {
      debugPrint('🔵 [LocalDataSource] markMessageAsRead');
      debugPrint('   Message ID: $messageId, User ID: $userId');

      final json = _messages.get(messageId);
      if (json != null) {
        final message = MessageModel.fromJson(Map<String, dynamic>.from(json));

        if (!message.readBy.contains(userId)) {
          final updatedReadBy = [...message.readBy, userId];
          final updated = MessageModel(
            id: message.id,
            tripId: message.tripId,
            senderId: message.senderId,
            message: message.message,
            messageType: message.messageType,
            replyToId: message.replyToId,
            attachmentUrl: message.attachmentUrl,
            reactions: message.reactions,
            readBy: updatedReadBy,
            isDeleted: message.isDeleted,
            createdAt: message.createdAt,
            updatedAt: DateTime.now(),
            senderName: message.senderName,
            senderAvatarUrl: message.senderAvatarUrl,
          );

          await _messages.put(messageId, updated.toJson());
          debugPrint('✅ [LocalDataSource] Message marked as read');
        } else {
          debugPrint('   ℹ️ User already read this message');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalDataSource] markMessageAsRead FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// Get unread message count for a trip
  Future<int> getUnreadCount({
    required String tripId,
    required String userId,
  }) async {
    try {
      debugPrint('🔵 [LocalDataSource] getUnreadCount');
      debugPrint('   Trip ID: $tripId, User ID: $userId');

      final unreadMessages = _messages.values
          .map((json) => MessageModel.fromJson(Map<String, dynamic>.from(json)))
          .where((m) =>
              m.tripId == tripId &&
              !m.isDeleted &&
              m.senderId != userId && // Don't count own messages
              !m.readBy.contains(userId))
          .length;

      debugPrint('   ✅ Unread count: $unreadMessages');
      return unreadMessages;
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalDataSource] getUnreadCount FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return 0;
    }
  }

  // ============================================================================
  // REACTIONS
  // ============================================================================

  /// Add reaction to a message
  Future<void> addReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      debugPrint('🔵 [LocalDataSource] addReaction');
      debugPrint('   Message ID: $messageId, User ID: $userId, Emoji: $emoji');

      final json = _messages.get(messageId);
      if (json != null) {
        final message = MessageModel.fromJson(Map<String, dynamic>.from(json));

        // Check if reaction already exists
        final hasReaction = message.reactions.any(
          (r) => r['user_id'] == userId && r['emoji'] == emoji,
        );

        if (!hasReaction) {
          final newReaction = {
            'emoji': emoji,
            'user_id': userId,
            'created_at': DateTime.now().toIso8601String(),
          };

          final updatedReactions = [...message.reactions, newReaction];
          final updated = MessageModel(
            id: message.id,
            tripId: message.tripId,
            senderId: message.senderId,
            message: message.message,
            messageType: message.messageType,
            replyToId: message.replyToId,
            attachmentUrl: message.attachmentUrl,
            reactions: updatedReactions,
            readBy: message.readBy,
            isDeleted: message.isDeleted,
            createdAt: message.createdAt,
            updatedAt: DateTime.now(),
            senderName: message.senderName,
            senderAvatarUrl: message.senderAvatarUrl,
          );

          await _messages.put(messageId, updated.toJson());
          debugPrint('✅ [LocalDataSource] Reaction added');
        } else {
          debugPrint('   ℹ️ Reaction already exists');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalDataSource] addReaction FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// Remove reaction from a message
  Future<void> removeReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      debugPrint('🔵 [LocalDataSource] removeReaction');
      debugPrint('   Message ID: $messageId, User ID: $userId, Emoji: $emoji');

      final json = _messages.get(messageId);
      if (json != null) {
        final message = MessageModel.fromJson(Map<String, dynamic>.from(json));

        final updatedReactions = message.reactions
            .where((r) => !(r['user_id'] == userId && r['emoji'] == emoji))
            .toList();

        final updated = MessageModel(
          id: message.id,
          tripId: message.tripId,
          senderId: message.senderId,
          message: message.message,
          messageType: message.messageType,
          replyToId: message.replyToId,
          attachmentUrl: message.attachmentUrl,
          reactions: updatedReactions,
          readBy: message.readBy,
          isDeleted: message.isDeleted,
          createdAt: message.createdAt,
          updatedAt: DateTime.now(),
          senderName: message.senderName,
          senderAvatarUrl: message.senderAvatarUrl,
        );

        await _messages.put(messageId, updated.toJson());
        debugPrint('✅ [LocalDataSource] Reaction removed');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalDataSource] removeReaction FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  // ============================================================================
  // OFFLINE QUEUE OPERATIONS
  // ============================================================================

  /// Add message to offline queue
  Future<void> queueMessage(QueuedMessageModel queuedMessage) async {
    try {
      debugPrint('🔵 [LocalDataSource] queueMessage: ${queuedMessage.id}');

      await _queue.put(queuedMessage.id, queuedMessage.toJson());

      debugPrint('✅ [LocalDataSource] Message queued');
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalDataSource] queueMessage FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// Get all pending messages from queue
  Future<List<QueuedMessageModel>> getPendingMessages() async {
    try {
      debugPrint('🔵 [LocalDataSource] getPendingMessages');

      final messages = _queue.values
          .map((json) =>
              QueuedMessageModel.fromJson(Map<String, dynamic>.from(json)))
          .where((m) => m.syncStatus == 'pending' || m.syncStatus == 'failed')
          .toList();

      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      debugPrint('   ✅ Retrieved ${messages.length} pending messages');
      return messages;
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalDataSource] getPendingMessages FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return [];
    }
  }

  /// Get pending messages for a specific trip
  Future<List<QueuedMessageModel>> getPendingMessagesByTrip(
      String tripId) async {
    try {
      debugPrint('🔵 [LocalDataSource] getPendingMessagesByTrip: $tripId');

      final messages = _queue.values
          .map((json) =>
              QueuedMessageModel.fromJson(Map<String, dynamic>.from(json)))
          .where((m) =>
              m.tripId == tripId &&
              (m.syncStatus == 'pending' || m.syncStatus == 'failed'))
          .toList();

      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      debugPrint('   ✅ Retrieved ${messages.length} pending messages for trip');
      return messages;
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalDataSource] getPendingMessagesByTrip FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return [];
    }
  }

  /// Update queue message status
  Future<void> updateQueueStatus({
    required String queueId,
    required String status,
    String? errorMessage,
  }) async {
    try {
      debugPrint('🔵 [LocalDataSource] updateQueueStatus');
      debugPrint('   Queue ID: $queueId, Status: $status');

      final json = _queue.get(queueId);
      if (json != null) {
        final queued =
            QueuedMessageModel.fromJson(Map<String, dynamic>.from(json));

        final updated = QueuedMessageModel(
          id: queued.id,
          tripId: queued.tripId,
          senderId: queued.senderId,
          messageData: queued.messageData,
          transmissionMethod: queued.transmissionMethod,
          relayPath: queued.relayPath,
          syncStatus: status,
          retryCount: status == 'failed' ? queued.retryCount + 1 : queued.retryCount,
          lastAttemptAt: DateTime.now(),
          errorMessage: errorMessage ?? queued.errorMessage,
          createdAt: queued.createdAt,
        );

        await _queue.put(queueId, updated.toJson());
        debugPrint('✅ [LocalDataSource] Queue status updated');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalDataSource] updateQueueStatus FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// Remove message from queue
  Future<void> removeFromQueue(String queueId) async {
    try {
      debugPrint('🔵 [LocalDataSource] removeFromQueue: $queueId');

      await _queue.delete(queueId);

      debugPrint('✅ [LocalDataSource] Message removed from queue');
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalDataSource] removeFromQueue FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  // ============================================================================
  // CACHE MANAGEMENT
  // ============================================================================

  /// Clear all messages for a trip from cache
  Future<void> clearTripCache(String tripId) async {
    try {
      debugPrint('🔵 [LocalDataSource] clearTripCache: $tripId');

      final keysToDelete = <String>[];
      for (final entry in _messages.toMap().entries) {
        final json = Map<String, dynamic>.from(entry.value);
        if (json['trip_id'] == tripId) {
          keysToDelete.add(entry.key);
        }
      }

      await _messages.deleteAll(keysToDelete);
      await _metadata.delete('trip_$tripId');

      debugPrint('   ✅ Cleared ${keysToDelete.length} messages from cache');
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalDataSource] clearTripCache FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// Clear all message cache
  Future<void> clearAllCache() async {
    try {
      debugPrint('🔵 [LocalDataSource] clearAllCache');

      await _messages.clear();
      await _metadata.clear();

      debugPrint('✅ [LocalDataSource] All cache cleared');
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalDataSource] clearAllCache FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// Get cache size in bytes (approximate)
  Future<int> getCacheSize() async {
    try {
      debugPrint('🔵 [LocalDataSource] getCacheSize');

      int totalSize = 0;

      // Estimate size based on JSON string length
      for (final json in _messages.values) {
        final jsonStr = json.toString();
        totalSize += jsonStr.length;
      }

      for (final json in _queue.values) {
        final jsonStr = json.toString();
        totalSize += jsonStr.length;
      }

      debugPrint('   ✅ Cache size: $totalSize bytes');
      return totalSize;
    } catch (e, stackTrace) {
      debugPrint('❌ [LocalDataSource] getCacheSize FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return 0;
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Update trip metadata (last message timestamp)
  Future<void> _updateTripMetadata(String tripId, DateTime timestamp) async {
    try {
      final key = 'trip_$tripId';
      final existing = _metadata.get(key);

      final metadata = existing != null
          ? Map<String, dynamic>.from(existing)
          : <String, dynamic>{};

      metadata['last_message_at'] = timestamp.toIso8601String();
      metadata['updated_at'] = DateTime.now().toIso8601String();

      await _metadata.put(key, metadata);
    } catch (e) {
      debugPrint('⚠️ [LocalDataSource] Failed to update trip metadata: $e');
      // Don't rethrow - metadata update is not critical
    }
  }

  /// Get last message timestamp for a trip
  Future<DateTime?> getLastMessageTimestamp(String tripId) async {
    try {
      final key = 'trip_$tripId';
      final metadata = _metadata.get(key);

      if (metadata != null) {
        final timestampStr = metadata['last_message_at'] as String?;
        if (timestampStr != null) {
          return DateTime.parse(timestampStr);
        }
      }

      return null;
    } catch (e) {
      debugPrint('⚠️ [LocalDataSource] Failed to get last message timestamp: $e');
      return null;
    }
  }

  /// Close all Hive boxes
  Future<void> close() async {
    try {
      debugPrint('🔵 [LocalDataSource] Closing Hive boxes');

      await _messages.close();
      await _queue.close();
      await _metadata.close();

      debugPrint('✅ [LocalDataSource] Hive boxes closed');
    } catch (e) {
      debugPrint('❌ [LocalDataSource] Failed to close boxes: $e');
    }
  }
}
