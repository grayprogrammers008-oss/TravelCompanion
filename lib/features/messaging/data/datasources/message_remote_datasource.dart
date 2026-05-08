import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../../shared/models/message_model.dart';
import 'message_queries.dart';

/// Message Remote Data Source
/// Handles all Supabase operations for messaging.
///
/// All Supabase PostgREST chain calls live behind [MessageQueries] so the
/// datasource itself can be exercised by unit tests. The default constructor
/// wires up the production [MessageQueriesImpl]; tests inject a fake.
///
/// Realtime stream methods ([subscribeToTripMessages], [subscribeToMessageUpdates])
/// keep their direct channel/stream subscription on the [SupabaseClient]
/// because Supabase realtime streams are not modelled by the queries seam.
class MessageRemoteDataSource {
  MessageRemoteDataSource({
    SupabaseClient? supabase,
    MessageQueries? queries,
    DateTime Function()? clock,
  })  : _supabaseOverride = supabase,
        _queriesOverride = queries,
        _clock = clock ?? DateTime.now;

  final SupabaseClient? _supabaseOverride;
  final MessageQueries? _queriesOverride;
  final DateTime Function() _clock;

  /// Lazily resolves the [MessageQueries]. Tests inject one directly.
  /// In production we pass through to the live Supabase client, which
  /// requires [SupabaseClientWrapper.initialize] to have been called.
  MessageQueries? _cachedQueries;
  MessageQueries get _queries =>
      _queriesOverride ?? (_cachedQueries ??= MessageQueriesImpl(_client));

  SupabaseClient get _client =>
      _supabaseOverride ?? SupabaseClientWrapper.client;

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Flatten the joined profile fields onto the message JSON object.
  Map<String, dynamic> _flattenProfile(Map<String, dynamic> json) {
    final profileData = json['profiles'] as Map<String, dynamic>?;
    final messageJson = Map<String, dynamic>.from(json);
    if (profileData != null) {
      messageJson['sender_name'] = profileData['full_name'];
      messageJson['sender_avatar_url'] = profileData['avatar_url'];
    }
    messageJson.remove('profiles');
    return messageJson;
  }

  // ============================================================================
  // CORE MESSAGE OPERATIONS
  // ============================================================================

  /// Send a new message to Supabase
  Future<MessageModel> sendMessage(MessageModel message) async {
    try {
      debugPrint('🔵 [RemoteDataSource] sendMessage START');
      debugPrint('   Message ID: ${message.id}');
      debugPrint('   Trip ID: ${message.tripId}');
      debugPrint('   Sender ID: ${message.senderId}');

      // Use toDatabaseJson() to exclude joined fields
      final json = message.toDatabaseJson();
      debugPrint('   Database JSON to send: $json');

      final response = await _queries.insertMessage(json);

      debugPrint('   ✅ Supabase response received');
      debugPrint('   Response data: $response');

      final result = MessageModel.fromJson(response);
      debugPrint('   ✅ Successfully converted to MessageModel');
      debugPrint('🔵 [RemoteDataSource] sendMessage SUCCESS');
      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ [RemoteDataSource] sendMessage FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Exception Type: ${e.runtimeType}');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to send message to Supabase: $e');
    }
  }

  /// Get messages for a trip with pagination
  Future<List<MessageModel>> getTripMessages({
    required String tripId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      debugPrint('🔵 [RemoteDataSource] getTripMessages');
      debugPrint('   Trip ID: $tripId');
      debugPrint('   Limit: $limit, Offset: $offset');

      final rows = await _queries.findTripMessages(
        tripId: tripId,
        limit: limit,
        offset: offset,
      );

      debugPrint('   ✅ Retrieved ${rows.length} messages');
      final messages =
          rows.map((j) => MessageModel.fromJson(_flattenProfile(j))).toList();

      debugPrint('🔵 [RemoteDataSource] getTripMessages SUCCESS');
      return messages;
    } catch (e, stackTrace) {
      debugPrint('❌ [RemoteDataSource] getTripMessages FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to get trip messages from Supabase: $e');
    }
  }

  /// Get a single message by ID
  Future<MessageModel?> getMessageById(String messageId) async {
    try {
      debugPrint('🔵 [RemoteDataSource] getMessageById: $messageId');

      final response = await _queries.findMessageById(messageId);
      if (response == null) {
        debugPrint('   ⚠️ Message not found');
        return null;
      }

      debugPrint('🔵 [RemoteDataSource] getMessageById SUCCESS');
      return MessageModel.fromJson(_flattenProfile(response));
    } catch (e, stackTrace) {
      debugPrint('❌ [RemoteDataSource] getMessageById FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to get message by ID from Supabase: $e');
    }
  }

  /// Get messages after a specific timestamp (for incremental sync)
  Future<List<MessageModel>> getMessagesAfter({
    required String tripId,
    required DateTime timestamp,
  }) async {
    try {
      debugPrint('🔵 [RemoteDataSource] getMessagesAfter');
      debugPrint('   Trip ID: $tripId');
      debugPrint('   After: $timestamp');

      final rows = await _queries.findMessagesAfter(
        tripId: tripId,
        createdAtGt: timestamp.toIso8601String(),
      );

      final messages =
          rows.map((j) => MessageModel.fromJson(_flattenProfile(j))).toList();

      debugPrint('   ✅ Retrieved ${messages.length} new messages');
      debugPrint('🔵 [RemoteDataSource] getMessagesAfter SUCCESS');
      return messages;
    } catch (e, stackTrace) {
      debugPrint('❌ [RemoteDataSource] getMessagesAfter FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to get messages after timestamp: $e');
    }
  }

  /// Get threaded replies for a message
  Future<List<MessageModel>> getThreadedReplies(String messageId) async {
    try {
      debugPrint('🔵 [RemoteDataSource] getThreadedReplies: $messageId');

      final rows = await _queries.findThreadedReplies(messageId);
      final messages =
          rows.map((j) => MessageModel.fromJson(_flattenProfile(j))).toList();

      debugPrint('   ✅ Retrieved ${messages.length} replies');
      debugPrint('🔵 [RemoteDataSource] getThreadedReplies SUCCESS');
      return messages;
    } catch (e, stackTrace) {
      debugPrint('❌ [RemoteDataSource] getThreadedReplies FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to get threaded replies: $e');
    }
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    try {
      debugPrint('🔵 [RemoteDataSource] deleteMessage: $messageId');
      await _queries.softDeleteMessage(messageId);
      debugPrint('🔵 [RemoteDataSource] deleteMessage SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('❌ [RemoteDataSource] deleteMessage FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Mark message as read by adding user ID to read_by array
  Future<void> markMessageAsRead({
    required String messageId,
    required String userId,
  }) async {
    try {
      debugPrint('🔵 [RemoteDataSource] markMessageAsRead');
      debugPrint('   Message ID: $messageId');
      debugPrint('   User ID: $userId');

      await _queries.rpcMarkMessageAsRead(
        messageId: messageId,
        userId: userId,
      );

      debugPrint('🔵 [RemoteDataSource] markMessageAsRead SUCCESS');
    } catch (e) {
      // If RPC function doesn't exist, fall back to direct update
      debugPrint('   ⚠️ RPC function not found, using direct update');

      try {
        // Get current message
        final message = await getMessageById(messageId);
        if (message == null) return;

        // Add user to read_by if not already present
        if (!message.readBy.contains(userId)) {
          final updatedReadBy = [...message.readBy, userId];
          await _queries
              .updateMessageById(messageId, {'read_by': updatedReadBy});
          debugPrint(
              '🔵 [RemoteDataSource] markMessageAsRead SUCCESS (fallback)');
        }
      } catch (e2, stackTrace) {
        debugPrint('❌ [RemoteDataSource] markMessageAsRead FAILED');
        debugPrint('   Exception: $e2');
        debugPrint('   Stack Trace: $stackTrace');
        throw Exception('Failed to mark message as read: $e2');
      }
    }
  }

  /// Add reaction to a message
  Future<void> addReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      debugPrint('🔵 [RemoteDataSource] addReaction');
      debugPrint('   Message ID: $messageId');
      debugPrint('   User ID: $userId');
      debugPrint('   Emoji: $emoji');

      // Get current message
      final message = await getMessageById(messageId);
      if (message == null) {
        throw Exception('Message not found');
      }

      // Check if user already reacted with this emoji
      final hasReaction = message.reactions.any(
        (r) => r['user_id'] == userId && r['emoji'] == emoji,
      );

      if (!hasReaction) {
        final newReaction = {
          'emoji': emoji,
          'user_id': userId,
          'created_at': _clock().toIso8601String(),
        };

        final updatedReactions = [...message.reactions, newReaction];
        await _queries
            .updateMessageById(messageId, {'reactions': updatedReactions});

        debugPrint('🔵 [RemoteDataSource] addReaction SUCCESS');
      } else {
        debugPrint('   ⚠️ User already reacted with this emoji');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [RemoteDataSource] addReaction FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to add reaction: $e');
    }
  }

  /// Remove reaction from a message
  Future<void> removeReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      debugPrint('🔵 [RemoteDataSource] removeReaction');
      debugPrint('   Message ID: $messageId');
      debugPrint('   User ID: $userId');
      debugPrint('   Emoji: $emoji');

      // Get current message
      final message = await getMessageById(messageId);
      if (message == null) {
        throw Exception('Message not found');
      }

      // Remove the reaction
      final updatedReactions = message.reactions
          .where((r) => !(r['user_id'] == userId && r['emoji'] == emoji))
          .toList();

      await _queries
          .updateMessageById(messageId, {'reactions': updatedReactions});

      debugPrint('🔵 [RemoteDataSource] removeReaction SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('❌ [RemoteDataSource] removeReaction FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to remove reaction: $e');
    }
  }

  // ============================================================================
  // REALTIME (kept on direct Supabase client - not part of queries seam)
  // ============================================================================

  /// Subscribe to new messages for a trip (realtime).
  /// Kept as a direct stream subscription — Supabase realtime is not
  /// modelled by [MessageQueries].
  Stream<MessageModel> subscribeToTripMessages(String tripId) {
    debugPrint('🔵 [RemoteDataSource] subscribeToTripMessages: $tripId');

    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          debugPrint('   📡 Received realtime message update');
          return data.where((message) =>
            message['trip_id'] == tripId &&
            (message['is_deleted'] == false || message['is_deleted'] == null)
          ).map((message) => MessageModel.fromJson(message));
        })
        .expand((messages) => messages);
  }

  /// Subscribe to message updates (reactions, read status, etc.).
  /// Kept as a direct stream subscription.
  Stream<MessageModel> subscribeToMessageUpdates(String messageId) {
    debugPrint('🔵 [RemoteDataSource] subscribeToMessageUpdates: $messageId');

    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('id', messageId)
        .map((data) {
          debugPrint('   📡 Message updated');
          return MessageModel.fromJson(data.first);
        });
  }

  // ============================================================================
  // OFFLINE QUEUE OPERATIONS
  // ============================================================================

  /// Insert message into queue
  Future<void> queueMessage(QueuedMessageModel queuedMessage) async {
    try {
      debugPrint('🔵 [RemoteDataSource] queueMessage');
      debugPrint('   Queue ID: ${queuedMessage.id}');

      await _queries.insertQueuedMessage(queuedMessage.toJson());

      debugPrint('🔵 [RemoteDataSource] queueMessage SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('❌ [RemoteDataSource] queueMessage FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to queue message: $e');
    }
  }

  /// Get pending messages from queue
  Future<List<QueuedMessageModel>> getPendingMessages() async {
    try {
      debugPrint('🔵 [RemoteDataSource] getPendingMessages');

      final rows = await _queries.findPendingQueuedMessages();
      final messages =
          rows.map((json) => QueuedMessageModel.fromJson(json)).toList();

      debugPrint('   ✅ Retrieved ${messages.length} pending messages');
      debugPrint('🔵 [RemoteDataSource] getPendingMessages SUCCESS');
      return messages;
    } catch (e, stackTrace) {
      debugPrint('❌ [RemoteDataSource] getPendingMessages FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to get pending messages: $e');
    }
  }

  /// Update queue message status
  Future<void> updateQueueStatus({
    required String queueId,
    required String status,
    String? errorMessage,
  }) async {
    try {
      debugPrint('🔵 [RemoteDataSource] updateQueueStatus');
      debugPrint('   Queue ID: $queueId');
      debugPrint('   Status: $status');

      await _queries.updateQueuedMessageById(queueId, {
        'sync_status': status,
        'last_attempt_at': _clock().toIso8601String(),
        'error_message': errorMessage,
      });

      debugPrint('🔵 [RemoteDataSource] updateQueueStatus SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('❌ [RemoteDataSource] updateQueueStatus FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to update queue status: $e');
    }
  }

  /// Remove message from queue
  Future<void> removeFromQueue(String queueId) async {
    try {
      debugPrint('🔵 [RemoteDataSource] removeFromQueue: $queueId');
      await _queries.deleteQueuedMessageById(queueId);
      debugPrint('🔵 [RemoteDataSource] removeFromQueue SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('❌ [RemoteDataSource] removeFromQueue FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to remove from queue: $e');
    }
  }
}
