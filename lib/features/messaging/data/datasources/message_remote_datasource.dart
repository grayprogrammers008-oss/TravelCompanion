import 'package:flutter/foundation.dart';
import '../../../../core/services/supabase_client_wrapper.dart';
import '../../../../shared/models/message_model.dart';

/// Message Remote Data Source
/// Handles all Supabase operations for messaging
class MessageRemoteDataSource {
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

      debugPrint('   Calling Supabase.from("messages").insert()...');
      final response = await SupabaseClientWrapper.client
          .from('messages')
          .insert(json)
          .select()
          .single();

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

      final response = await SupabaseClientWrapper.client
          .from('messages')
          .select('''
            *,
            profiles!messages_sender_id_fkey(
              full_name,
              avatar_url
            )
          ''')
          .eq('trip_id', tripId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      debugPrint('   ✅ Retrieved ${(response as List).length} messages');

      // Map response with joined profile data
      final messages = (response as List).map((json) {
        // Extract profile data if available
        final profileData = json['profiles'] as Map<String, dynamic>?;
        final messageJson = Map<String, dynamic>.from(json);

        // Add sender name and avatar from joined profile
        if (profileData != null) {
          messageJson['sender_name'] = profileData['full_name'];
          messageJson['sender_avatar_url'] = profileData['avatar_url'];
        }

        // Remove the nested profiles object
        messageJson.remove('profiles');

        return MessageModel.fromJson(messageJson);
      }).toList();

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

      final response = await SupabaseClientWrapper.client
          .from('messages')
          .select('''
            *,
            profiles!messages_sender_id_fkey(
              full_name,
              avatar_url
            )
          ''')
          .eq('id', messageId)
          .maybeSingle();

      if (response == null) {
        debugPrint('   ⚠️ Message not found');
        return null;
      }

      // Extract profile data
      final profileData = response['profiles'] as Map<String, dynamic>?;
      final messageJson = Map<String, dynamic>.from(response);

      if (profileData != null) {
        messageJson['sender_name'] = profileData['full_name'];
        messageJson['sender_avatar_url'] = profileData['avatar_url'];
      }

      messageJson.remove('profiles');

      debugPrint('🔵 [RemoteDataSource] getMessageById SUCCESS');
      return MessageModel.fromJson(messageJson);
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

      final response = await SupabaseClientWrapper.client
          .from('messages')
          .select('''
            *,
            profiles!messages_sender_id_fkey(
              full_name,
              avatar_url
            )
          ''')
          .eq('trip_id', tripId)
          .eq('is_deleted', false)
          .gt('created_at', timestamp.toIso8601String())
          .order('created_at', ascending: false);

      final messages = (response as List).map((json) {
        final profileData = json['profiles'] as Map<String, dynamic>?;
        final messageJson = Map<String, dynamic>.from(json);

        if (profileData != null) {
          messageJson['sender_name'] = profileData['full_name'];
          messageJson['sender_avatar_url'] = profileData['avatar_url'];
        }

        messageJson.remove('profiles');

        return MessageModel.fromJson(messageJson);
      }).toList();

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

      final response = await SupabaseClientWrapper.client
          .from('messages')
          .select('''
            *,
            profiles!messages_sender_id_fkey(
              full_name,
              avatar_url
            )
          ''')
          .eq('reply_to_id', messageId)
          .eq('is_deleted', false)
          .order('created_at', ascending: true);

      final messages = (response as List).map((json) {
        final profileData = json['profiles'] as Map<String, dynamic>?;
        final messageJson = Map<String, dynamic>.from(json);

        if (profileData != null) {
          messageJson['sender_name'] = profileData['full_name'];
          messageJson['sender_avatar_url'] = profileData['avatar_url'];
        }

        messageJson.remove('profiles');

        return MessageModel.fromJson(messageJson);
      }).toList();

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

      await SupabaseClientWrapper.client
          .from('messages')
          .update({'is_deleted': true})
          .eq('id', messageId);

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

      // Use PostgreSQL array append operator
      await SupabaseClientWrapper.client.rpc(
        'mark_message_as_read',
        params: {
          'message_id': messageId,
          'user_id': userId,
        },
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

          await SupabaseClientWrapper.client
              .from('messages')
              .update({'read_by': updatedReadBy})
              .eq('id', messageId);

          debugPrint('🔵 [RemoteDataSource] markMessageAsRead SUCCESS (fallback)');
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
          'created_at': DateTime.now().toIso8601String(),
        };

        final updatedReactions = [...message.reactions, newReaction];

        await SupabaseClientWrapper.client
            .from('messages')
            .update({'reactions': updatedReactions})
            .eq('id', messageId);

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

      await SupabaseClientWrapper.client
          .from('messages')
          .update({'reactions': updatedReactions})
          .eq('id', messageId);

      debugPrint('🔵 [RemoteDataSource] removeReaction SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('❌ [RemoteDataSource] removeReaction FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to remove reaction: $e');
    }
  }

  /// Subscribe to new messages for a trip (realtime)
  Stream<MessageModel> subscribeToTripMessages(String tripId) {
    debugPrint('🔵 [RemoteDataSource] subscribeToTripMessages: $tripId');

    return SupabaseClientWrapper.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .map((data) {
          debugPrint('   📡 Received realtime message update');
          return MessageModel.fromJson(data.first);
        });
  }

  /// Subscribe to message updates (reactions, read status, etc.)
  Stream<MessageModel> subscribeToMessageUpdates(String messageId) {
    debugPrint('🔵 [RemoteDataSource] subscribeToMessageUpdates: $messageId');

    return SupabaseClientWrapper.client
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

      await SupabaseClientWrapper.client
          .from('message_queue')
          .insert(queuedMessage.toJson());

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

      final response = await SupabaseClientWrapper.client
          .from('message_queue')
          .select()
          .in_('sync_status', ['pending', 'failed'])
          .order('created_at', ascending: true);

      final messages = (response as List)
          .map((json) => QueuedMessageModel.fromJson(json))
          .toList();

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

      await SupabaseClientWrapper.client
          .from('message_queue')
          .update({
            'sync_status': status,
            'last_attempt_at': DateTime.now().toIso8601String(),
            'error_message': errorMessage,
          })
          .eq('id', queueId);

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

      await SupabaseClientWrapper.client
          .from('message_queue')
          .delete()
          .eq('id', queueId);

      debugPrint('🔵 [RemoteDataSource] removeFromQueue SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('❌ [RemoteDataSource] removeFromQueue FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to remove from queue: $e');
    }
  }
}
