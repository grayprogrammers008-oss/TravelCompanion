import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../shared/models/message_model.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_local_datasource.dart';
import '../datasources/message_remote_datasource.dart';

/// Message Repository Implementation
/// Implements offline-first architecture with automatic sync
/// Coordinates between local Hive cache and remote Supabase
class MessageRepositoryImpl implements MessageRepository {
  final MessageLocalDataSource localDataSource;
  final MessageRemoteDataSource remoteDataSource;
  final Connectivity connectivity;

  MessageRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivity,
  });

  /// Check if device has internet connectivity
  Future<bool> _hasConnectivity() async {
    try {
      final results = await connectivity.checkConnectivity();
      return !results.contains(ConnectivityResult.none) && results.isNotEmpty;
    } catch (e) {
      debugPrint('⚠️ [Repository] Connectivity check failed: $e');
      return false;
    }
  }

  // ============================================================================
  // MESSAGE CRUD OPERATIONS
  // ============================================================================

  @override
  Future<MessageEntity> sendMessage({
    required String tripId,
    required String senderId,
    required String message,
    required MessageType messageType,
    String? replyToId,
    String? attachmentUrl,
  }) async {
    try {
      debugPrint('🔵 [Repository] sendMessage START');
      debugPrint('   Trip ID: $tripId');
      debugPrint('   Sender ID: $senderId');
      debugPrint('   Message Type: $messageType');

      // Create message model
      final now = DateTime.now();
      final messageModel = MessageModel(
        id: const Uuid().v4(),
        tripId: tripId,
        senderId: senderId,
        message: message,
        messageType: _messageTypeToString(messageType),
        replyToId: replyToId,
        attachmentUrl: attachmentUrl,
        reactions: [],
        readBy: [senderId], // Sender has read their own message
        isDeleted: false,
        createdAt: now,
        updatedAt: now,
      );

      // 1. Save to local cache immediately (offline-first)
      await localDataSource.saveMessage(messageModel);
      debugPrint('   ✅ Saved to local cache');

      // 2. Check connectivity
      final hasInternet = await _hasConnectivity();

      if (hasInternet) {
        try {
          // 3. Try to send to server
          debugPrint('   📡 Attempting to send to server...');
          final serverMessage = await remoteDataSource.sendMessage(messageModel);

          // 4. Update local cache with server response (has timestamps, etc.)
          await localDataSource.saveMessage(serverMessage);
          debugPrint('   ✅ Synced with server');

          debugPrint('🔵 [Repository] sendMessage SUCCESS (synced)');
          return serverMessage.toEntity();
        } catch (e) {
          debugPrint('   ⚠️ Server send failed: $e');
          // Queue for retry
          await _queueMessageForRetry(messageModel);
          debugPrint('   📤 Queued for retry');
        }
      } else {
        debugPrint('   📴 No internet - queuing message');
        await _queueMessageForRetry(messageModel);
      }

      debugPrint('🔵 [Repository] sendMessage SUCCESS (queued)');
      return messageModel.toEntity();
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] sendMessage FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to send message: $e');
    }
  }

  @override
  Future<List<MessageEntity>> getTripMessages({
    required String tripId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      debugPrint('🔵 [Repository] getTripMessages: $tripId');
      debugPrint('   Limit: $limit, Offset: $offset');

      // 1. Get cached messages immediately
      final cachedMessages = await localDataSource.getTripMessages(
        tripId: tripId,
        limit: limit,
        offset: offset,
      );
      debugPrint('   ℹ️ Retrieved ${cachedMessages.length} messages from cache');

      // 2. Check connectivity for background sync
      final hasInternet = await _hasConnectivity();

      if (hasInternet) {
        // 3. Fetch from server in background (don't await)
        _syncMessagesInBackground(tripId, limit, offset);
      }

      // 4. Return cached messages immediately (offline-first)
      debugPrint('🔵 [Repository] getTripMessages SUCCESS (from cache)');
      return cachedMessages.map((m) => m.toEntity()).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] getTripMessages FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to get trip messages: $e');
    }
  }

  @override
  Future<MessageEntity?> getMessageById(String messageId) async {
    try {
      debugPrint('🔵 [Repository] getMessageById: $messageId');

      // 1. Try local cache first
      final cachedMessage = await localDataSource.getMessageById(messageId);
      if (cachedMessage != null) {
        debugPrint('   ✅ Found in cache');
        return cachedMessage.toEntity();
      }

      // 2. Try server if not in cache
      final hasInternet = await _hasConnectivity();
      if (hasInternet) {
        debugPrint('   📡 Fetching from server...');
        final serverMessage = await remoteDataSource.getMessageById(messageId);
        if (serverMessage != null) {
          // Cache it for next time
          await localDataSource.saveMessage(serverMessage);
          debugPrint('   ✅ Found on server and cached');
          return serverMessage.toEntity();
        }
      }

      debugPrint('   ⚠️ Message not found');
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] getMessageById FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return null;
    }
  }

  @override
  Future<List<MessageEntity>> getMessagesAfter({
    required String tripId,
    required DateTime timestamp,
  }) async {
    try {
      debugPrint('🔵 [Repository] getMessagesAfter');
      debugPrint('   Trip ID: $tripId, After: $timestamp');

      // Check connectivity
      final hasInternet = await _hasConnectivity();

      if (hasInternet) {
        // Fetch new messages from server
        final serverMessages = await remoteDataSource.getMessagesAfter(
          tripId: tripId,
          timestamp: timestamp,
        );

        // Save to cache
        if (serverMessages.isNotEmpty) {
          await localDataSource.saveMessages(serverMessages);
        }

        debugPrint('   ✅ Retrieved ${serverMessages.length} new messages from server');
        return serverMessages.map((m) => m.toEntity()).toList();
      } else {
        // Fall back to cache
        final cachedMessages = await localDataSource.getMessagesAfter(
          tripId: tripId,
          timestamp: timestamp,
        );

        debugPrint('   ✅ Retrieved ${cachedMessages.length} messages from cache');
        return cachedMessages.map((m) => m.toEntity()).toList();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] getMessagesAfter FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to get messages after timestamp: $e');
    }
  }

  @override
  Future<List<MessageEntity>> getThreadedReplies(String messageId) async {
    try {
      debugPrint('🔵 [Repository] getThreadedReplies: $messageId');

      // 1. Get from cache
      final cachedReplies =
          await localDataSource.getThreadedReplies(messageId);

      // 2. Sync from server in background if online
      final hasInternet = await _hasConnectivity();
      if (hasInternet) {
        _syncRepliesInBackground(messageId);
      }

      debugPrint('   ✅ Retrieved ${cachedReplies.length} replies');
      return cachedReplies.map((m) => m.toEntity()).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] getThreadedReplies FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to get threaded replies: $e');
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      debugPrint('🔵 [Repository] deleteMessage: $messageId');

      // 1. Delete from local cache
      await localDataSource.deleteMessage(messageId);
      debugPrint('   ✅ Deleted from cache');

      // 2. Delete from server if online
      final hasInternet = await _hasConnectivity();
      if (hasInternet) {
        try {
          await remoteDataSource.deleteMessage(messageId);
          debugPrint('   ✅ Deleted from server');
        } catch (e) {
          debugPrint('   ⚠️ Server delete failed: $e');
          // Queue for retry (could implement later)
        }
      }

      debugPrint('🔵 [Repository] deleteMessage SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] deleteMessage FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to delete message: $e');
    }
  }

  // ============================================================================
  // READ RECEIPTS
  // ============================================================================

  @override
  Future<void> markMessageAsRead({
    required String messageId,
    required String userId,
  }) async {
    try {
      debugPrint('🔵 [Repository] markMessageAsRead');
      debugPrint('   Message ID: $messageId, User ID: $userId');

      // 1. Update local cache immediately
      await localDataSource.markMessageAsRead(
        messageId: messageId,
        userId: userId,
      );
      debugPrint('   ✅ Updated cache');

      // 2. Update server if online
      final hasInternet = await _hasConnectivity();
      if (hasInternet) {
        try {
          await remoteDataSource.markMessageAsRead(
            messageId: messageId,
            userId: userId,
          );
          debugPrint('   ✅ Updated server');
        } catch (e) {
          debugPrint('   ⚠️ Server update failed: $e');
          // Don't rethrow - read status updated locally
        }
      }

      debugPrint('🔵 [Repository] markMessageAsRead SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] markMessageAsRead FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to mark message as read: $e');
    }
  }

  @override
  Future<void> markAllMessagesAsRead({
    required String tripId,
    required String userId,
  }) async {
    try {
      debugPrint('🔵 [Repository] markAllMessagesAsRead');
      debugPrint('   Trip ID: $tripId, User ID: $userId');

      // Get all unread messages
      final messages = await localDataSource.getTripMessages(tripId: tripId);

      for (final message in messages) {
        if (!message.readBy.contains(userId) && message.senderId != userId) {
          await markMessageAsRead(messageId: message.id, userId: userId);
        }
      }

      debugPrint('🔵 [Repository] markAllMessagesAsRead SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] markAllMessagesAsRead FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to mark all messages as read: $e');
    }
  }

  @override
  Future<int> getUnreadCount({
    required String tripId,
    required String userId,
  }) async {
    try {
      debugPrint('🔵 [Repository] getUnreadCount');
      debugPrint('   Trip ID: $tripId, User ID: $userId');

      final count = await localDataSource.getUnreadCount(
        tripId: tripId,
        userId: userId,
      );

      debugPrint('   ✅ Unread count: $count');
      return count;
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] getUnreadCount FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return 0;
    }
  }

  // ============================================================================
  // REACTIONS
  // ============================================================================

  @override
  Future<void> addReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      debugPrint('🔵 [Repository] addReaction');
      debugPrint('   Message ID: $messageId, User ID: $userId, Emoji: $emoji');

      // 1. Update local cache immediately
      await localDataSource.addReaction(
        messageId: messageId,
        userId: userId,
        emoji: emoji,
      );
      debugPrint('   ✅ Updated cache');

      // 2. Update server if online
      final hasInternet = await _hasConnectivity();
      if (hasInternet) {
        try {
          await remoteDataSource.addReaction(
            messageId: messageId,
            userId: userId,
            emoji: emoji,
          );
          debugPrint('   ✅ Updated server');
        } catch (e) {
          debugPrint('   ⚠️ Server update failed: $e');
        }
      }

      debugPrint('🔵 [Repository] addReaction SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] addReaction FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to add reaction: $e');
    }
  }

  @override
  Future<void> removeReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      debugPrint('🔵 [Repository] removeReaction');
      debugPrint('   Message ID: $messageId, User ID: $userId, Emoji: $emoji');

      // 1. Update local cache immediately
      await localDataSource.removeReaction(
        messageId: messageId,
        userId: userId,
        emoji: emoji,
      );
      debugPrint('   ✅ Updated cache');

      // 2. Update server if online
      final hasInternet = await _hasConnectivity();
      if (hasInternet) {
        try {
          await remoteDataSource.removeReaction(
            messageId: messageId,
            userId: userId,
            emoji: emoji,
          );
          debugPrint('   ✅ Updated server');
        } catch (e) {
          debugPrint('   ⚠️ Server update failed: $e');
        }
      }

      debugPrint('🔵 [Repository] removeReaction SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] removeReaction FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to remove reaction: $e');
    }
  }

  // ============================================================================
  // OFFLINE QUEUE OPERATIONS
  // ============================================================================

  @override
  Future<List<QueuedMessageEntity>> getPendingMessages() async {
    try {
      debugPrint('🔵 [Repository] getPendingMessages');

      final messages = await localDataSource.getPendingMessages();

      debugPrint('   ✅ Retrieved ${messages.length} pending messages');
      return messages.map((m) => m.toEntity()).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] getPendingMessages FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return [];
    }
  }

  @override
  Future<List<QueuedMessageEntity>> getPendingMessagesByTrip(
      String tripId) async {
    try {
      debugPrint('🔵 [Repository] getPendingMessagesByTrip: $tripId');

      final messages =
          await localDataSource.getPendingMessagesByTrip(tripId);

      debugPrint('   ✅ Retrieved ${messages.length} pending messages');
      return messages.map((m) => m.toEntity()).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] getPendingMessagesByTrip FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return [];
    }
  }

  @override
  Future<void> retryMessage(String queuedMessageId) async {
    try {
      debugPrint('🔵 [Repository] retryMessage: $queuedMessageId');

      // Get queued message
      final queuedMessages = await localDataSource.getPendingMessages();
      final queuedMessage = queuedMessages.firstWhere(
        (m) => m.id == queuedMessageId,
        orElse: () => throw Exception('Queued message not found'),
      );

      // Check connectivity
      final hasInternet = await _hasConnectivity();
      if (!hasInternet) {
        throw Exception('No internet connectivity');
      }

      // Update status to syncing
      await localDataSource.updateQueueStatus(
        queueId: queuedMessageId,
        status: 'syncing',
      );

      // Attempt to send
      final messageModel = MessageModel.fromJson(queuedMessage.messageData);
      await remoteDataSource.sendMessage(messageModel);

      // Remove from queue on success
      await localDataSource.removeFromQueue(queuedMessageId);

      debugPrint('🔵 [Repository] retryMessage SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] retryMessage FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');

      // Update status to failed
      await localDataSource.updateQueueStatus(
        queueId: queuedMessageId,
        status: 'failed',
        errorMessage: e.toString(),
      );

      throw Exception('Failed to retry message: $e');
    }
  }

  @override
  Future<void> removeFromQueue(String queuedMessageId) async {
    try {
      debugPrint('🔵 [Repository] removeFromQueue: $queuedMessageId');

      await localDataSource.removeFromQueue(queuedMessageId);

      debugPrint('🔵 [Repository] removeFromQueue SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] removeFromQueue FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to remove from queue: $e');
    }
  }

  @override
  Future<void> syncPendingMessages() async {
    try {
      debugPrint('🔵 [Repository] syncPendingMessages START');

      // Check connectivity
      final hasInternet = await _hasConnectivity();
      if (!hasInternet) {
        debugPrint('   ⚠️ No internet connectivity');
        return;
      }

      // Get pending messages
      final pendingMessages = await localDataSource.getPendingMessages();
      debugPrint('   ℹ️ Found ${pendingMessages.length} pending messages');

      for (final queuedMessage in pendingMessages) {
        try {
          await retryMessage(queuedMessage.id);
          debugPrint('   ✅ Synced message: ${queuedMessage.id}');
        } catch (e) {
          debugPrint('   ⚠️ Failed to sync message ${queuedMessage.id}: $e');
          // Continue with next message
        }
      }

      debugPrint('🔵 [Repository] syncPendingMessages COMPLETE');
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] syncPendingMessages FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
    }
  }

  // ============================================================================
  // REAL-TIME SUBSCRIPTIONS
  // ============================================================================

  @override
  Stream<List<MessageEntity>> subscribeToTripMessages(String tripId) {
    debugPrint('🔵 [Repository] subscribeToTripMessages: $tripId');

    // Return stream from remote data source
    // Map to entities
    return remoteDataSource.subscribeToTripMessages(tripId).asyncMap((message) async {
      // Save to cache
      await localDataSource.saveMessage(message);

      // Return all messages for the trip
      final messages = await localDataSource.getTripMessages(tripId: tripId);
      return messages.map((m) => m.toEntity()).toList();
    }).handleError((error) {
      debugPrint('❌ [Repository] subscribeToTripMessages ERROR: $error');
      // Return empty list on error
      return <MessageEntity>[];
    });
  }

  @override
  Stream<MessageEntity> subscribeToMessageUpdates(String messageId) {
    debugPrint('🔵 [Repository] subscribeToMessageUpdates: $messageId');

    // Return stream from remote data source
    return remoteDataSource.subscribeToMessageUpdates(messageId).asyncMap((message) async {
      // Save to cache
      await localDataSource.saveMessage(message);

      return message.toEntity();
    }).handleError((error) {
      debugPrint('❌ [Repository] subscribeToMessageUpdates ERROR: $error');
      throw Exception('Failed to subscribe to message updates: $error');
    });
  }

  // ============================================================================
  // CACHE MANAGEMENT
  // ============================================================================

  @override
  Future<void> clearTripCache(String tripId) async {
    try {
      debugPrint('🔵 [Repository] clearTripCache: $tripId');

      await localDataSource.clearTripCache(tripId);

      debugPrint('🔵 [Repository] clearTripCache SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] clearTripCache FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to clear trip cache: $e');
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      debugPrint('🔵 [Repository] clearAllCache');

      await localDataSource.clearAllCache();

      debugPrint('🔵 [Repository] clearAllCache SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] clearAllCache FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to clear all cache: $e');
    }
  }

  @override
  Future<int> getCacheSize() async {
    try {
      debugPrint('🔵 [Repository] getCacheSize');

      final size = await localDataSource.getCacheSize();

      debugPrint('   ✅ Cache size: $size bytes');
      return size;
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] getCacheSize FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return 0;
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Queue a message for retry when offline or server fails
  Future<void> _queueMessageForRetry(MessageModel message) async {
    try {
      final queuedMessage = QueuedMessageModel(
        id: const Uuid().v4(),
        tripId: message.tripId,
        senderId: message.senderId,
        messageData: message.toJson(),
        transmissionMethod: 'internet',
        syncStatus: 'pending',
        createdAt: DateTime.now(),
      );

      await localDataSource.queueMessage(queuedMessage);
    } catch (e) {
      debugPrint('⚠️ [Repository] Failed to queue message: $e');
    }
  }

  /// Sync messages from server in background
  Future<void> _syncMessagesInBackground(
    String tripId,
    int limit,
    int offset,
  ) async {
    try {
      debugPrint('   📡 Background sync: Fetching from server...');

      final serverMessages = await remoteDataSource.getTripMessages(
        tripId: tripId,
        limit: limit,
        offset: offset,
      );

      // Update cache
      if (serverMessages.isNotEmpty) {
        await localDataSource.saveMessages(serverMessages);
        debugPrint('   ✅ Background sync: Cached ${serverMessages.length} messages');
      }
    } catch (e) {
      debugPrint('   ⚠️ Background sync failed: $e');
      // Don't rethrow - background sync failure is not critical
    }
  }

  /// Sync replies from server in background
  Future<void> _syncRepliesInBackground(String messageId) async {
    try {
      debugPrint('   📡 Background sync: Fetching replies...');

      final serverReplies =
          await remoteDataSource.getThreadedReplies(messageId);

      // Update cache
      if (serverReplies.isNotEmpty) {
        await localDataSource.saveMessages(serverReplies);
        debugPrint('   ✅ Background sync: Cached ${serverReplies.length} replies');
      }
    } catch (e) {
      debugPrint('   ⚠️ Background sync failed: $e');
      // Don't rethrow - background sync failure is not critical
    }
  }

  /// Convert message type to string (helper method)
  String _messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.location:
        return 'location';
      case MessageType.expenseLink:
        return 'expense_link';
    }
  }
}
