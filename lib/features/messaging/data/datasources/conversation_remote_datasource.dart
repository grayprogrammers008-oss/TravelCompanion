import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/conversation_model.dart';
import '../../../../shared/models/message_model.dart';

/// Remote data source for conversation operations using Supabase
class ConversationRemoteDataSource {
  final SupabaseClient _client;

  ConversationRemoteDataSource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ============================================================================
  // CONVERSATION CRUD
  // ============================================================================

  /// Create a new conversation with initial members
  Future<ConversationModel> createConversation({
    required String tripId,
    required String name,
    String? description,
    required List<String> memberUserIds,
    required String createdBy,
    bool isDirectMessage = false,
  }) async {
    try {
      // 1. Create the conversation
      final conversationResponse = await _client
          .from('conversations')
          .insert({
            'trip_id': tripId,
            'name': name,
            'description': description,
            'created_by': createdBy,
            'is_direct_message': isDirectMessage,
          })
          .select()
          .single();

      final conversationId = conversationResponse['id'] as String;

      // 2. Add creator as admin
      await _client.from('conversation_members').insert({
        'conversation_id': conversationId,
        'user_id': createdBy,
        'role': 'admin',
      });

      // 3. Add other members
      final otherMembers = memberUserIds.where((id) => id != createdBy).toList();
      if (otherMembers.isNotEmpty) {
        await _client.from('conversation_members').insert(
          otherMembers
              .map((userId) => {
                    'conversation_id': conversationId,
                    'user_id': userId,
                    'role': 'member',
                  })
              .toList(),
        );
      }

      // 4. Fetch the complete conversation with members
      return await getConversation(conversationId, createdBy);
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      rethrow;
    }
  }

  /// Get all conversations for a trip using the RPC function
  Future<List<ConversationModel>> getTripConversations(
    String tripId,
    String userId,
  ) async {
    try {
      final response = await _client.rpc(
        'get_trip_conversations',
        params: {
          'p_trip_id': tripId,
          'p_user_id': userId,
        },
      );

      final data = response as List<dynamic>;
      return data
          .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting trip conversations: $e');
      rethrow;
    }
  }

  /// Get a single conversation by ID
  Future<ConversationModel> getConversation(
    String conversationId,
    String userId,
  ) async {
    // Guard against empty UUIDs
    if (conversationId.isEmpty || userId.isEmpty) {
      throw Exception('Invalid conversationId or userId: cannot be empty');
    }

    try {
      // Get conversation with details via RPC
      final response = await _client.rpc(
        'get_conversation_with_details',
        params: {
          'p_conversation_id': conversationId,
          'p_user_id': userId,
        },
      );

      final data = response as List<dynamic>;
      if (data.isEmpty) {
        throw Exception('Conversation not found');
      }

      final conversationJson = data.first as Map<String, dynamic>;

      // Get members separately
      final membersResponse = await _client
          .from('conversation_members')
          .select('''
            *,
            profiles:user_id (
              id,
              full_name,
              avatar_url,
              email
            )
          ''')
          .eq('conversation_id', conversationId);

      final members = (membersResponse as List<dynamic>).map((m) {
        final json = m as Map<String, dynamic>;
        final profile = json['profiles'] as Map<String, dynamic>?;
        return ConversationMemberModel.fromJson({
          ...json,
          'user_name': profile?['full_name'],
          'user_avatar_url': profile?['avatar_url'],
          'user_email': profile?['email'],
        });
      }).toList();

      return ConversationModel.fromJson({
        ...conversationJson,
        'members': members.map((m) => m.toJson()).toList(),
      });
    } catch (e) {
      debugPrint('Error getting conversation: $e');
      rethrow;
    }
  }

  /// Update conversation details
  Future<void> updateConversation({
    required String conversationId,
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isNotEmpty) {
        await _client
            .from('conversations')
            .update(updates)
            .eq('id', conversationId);
      }
    } catch (e) {
      debugPrint('Error updating conversation: $e');
      rethrow;
    }
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _client.from('conversations').delete().eq('id', conversationId);
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
      rethrow;
    }
  }

  // ============================================================================
  // MEMBER MANAGEMENT
  // ============================================================================

  /// Add members to a conversation
  Future<void> addMembers({
    required String conversationId,
    required List<String> userIds,
  }) async {
    try {
      await _client.from('conversation_members').insert(
        userIds
            .map((userId) => {
                  'conversation_id': conversationId,
                  'user_id': userId,
                  'role': 'member',
                })
            .toList(),
      );
    } catch (e) {
      debugPrint('Error adding members: $e');
      rethrow;
    }
  }

  /// Remove a member from a conversation
  Future<void> removeMember({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _client
          .from('conversation_members')
          .delete()
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error removing member: $e');
      rethrow;
    }
  }

  /// Update member role
  Future<void> updateMemberRole({
    required String conversationId,
    required String userId,
    required String role,
  }) async {
    try {
      await _client
          .from('conversation_members')
          .update({'role': role})
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error updating member role: $e');
      rethrow;
    }
  }

  /// Set muted status for a member
  Future<void> setMuted({
    required String conversationId,
    required String userId,
    required bool muted,
  }) async {
    try {
      await _client
          .from('conversation_members')
          .update({'is_muted': muted})
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error setting muted status: $e');
      rethrow;
    }
  }

  /// Update last read timestamp
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _client
          .from('conversation_members')
          .update({'last_read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error marking as read: $e');
      rethrow;
    }
  }

  /// Get conversation members with profile info
  Future<List<ConversationMemberModel>> getConversationMembers(
    String conversationId,
  ) async {
    try {
      final response = await _client
          .from('conversation_members')
          .select('''
            *,
            profiles:user_id (
              id,
              full_name,
              avatar_url,
              email
            )
          ''')
          .eq('conversation_id', conversationId)
          .order('joined_at');

      return (response as List<dynamic>).map((m) {
        final json = m as Map<String, dynamic>;
        final profile = json['profiles'] as Map<String, dynamic>?;
        return ConversationMemberModel.fromJson({
          ...json,
          'user_name': profile?['full_name'],
          'user_avatar_url': profile?['avatar_url'],
          'user_email': profile?['email'],
        });
      }).toList();
    } catch (e) {
      debugPrint('Error getting conversation members: $e');
      rethrow;
    }
  }

  // ============================================================================
  // MESSAGES
  // ============================================================================

  /// Get messages for a conversation
  Future<List<MessageModel>> getConversationMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .select('''
            *,
            sender:sender_id (
              id,
              full_name,
              avatar_url
            )
          ''')
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List<dynamic>).map((m) {
        final json = m as Map<String, dynamic>;
        final sender = json['sender'] as Map<String, dynamic>?;
        return MessageModel.fromJson({
          ...json,
          'sender_name': sender?['full_name'],
          'sender_avatar_url': sender?['avatar_url'],
        });
      }).toList();
    } catch (e) {
      debugPrint('Error getting conversation messages: $e');
      rethrow;
    }
  }

  /// Delete a single message (soft delete - sets is_deleted to true)
  /// Only the sender can delete their own message
  Future<void> deleteMessage({
    required String messageId,
    required String senderId,
  }) async {
    try {
      await _client
          .from('messages')
          .update({'is_deleted': true})
          .eq('id', messageId)
          .eq('sender_id', senderId);
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  /// Delete multiple messages (soft delete - sets is_deleted to true)
  /// Only the sender can delete their own messages
  Future<void> deleteMessages({
    required List<String> messageIds,
    required String senderId,
  }) async {
    try {
      debugPrint('Deleting messages: $messageIds for sender: $senderId');

      // Delete messages one by one to ensure proper error handling
      for (final messageId in messageIds) {
        await _client
            .from('messages')
            .update({'is_deleted': true})
            .eq('id', messageId)
            .eq('sender_id', senderId);
        debugPrint('Deleted message: $messageId');
      }

      debugPrint('Successfully deleted ${messageIds.length} messages');
    } catch (e) {
      debugPrint('Error deleting messages: $e');
      rethrow;
    }
  }

  /// Send a message to a conversation
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String tripId,
    required String senderId,
    required String message,
    String messageType = 'text',
    String? replyToId,
    String? attachmentUrl,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'trip_id': tripId,
            'sender_id': senderId,
            'message': message,
            'message_type': messageType,
            'reply_to_id': replyToId,
            'attachment_url': attachmentUrl,
          })
          .select('''
            *,
            sender:sender_id (
              id,
              full_name,
              avatar_url
            )
          ''')
          .single();

      final sender = response['sender'] as Map<String, dynamic>?;
      return MessageModel.fromJson({
        ...response,
        'sender_name': sender?['full_name'],
        'sender_avatar_url': sender?['avatar_url'],
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // ============================================================================
  // REAL-TIME STREAMS
  // ============================================================================

  /// Subscribe to conversation updates
  Stream<ConversationModel> subscribeToConversation(
    String conversationId,
    String userId,
  ) {
    return _client
        .from('conversations')
        .stream(primaryKey: ['id'])
        .eq('id', conversationId)
        .asyncMap((data) async {
          if (data.isEmpty) {
            throw Exception('Conversation not found');
          }
          return getConversation(conversationId, userId);
        });
  }

  /// Subscribe to messages for a conversation
  /// Enriches messages with sender profile data for real-time display
  Stream<List<MessageModel>> subscribeToConversationMessages(
    String conversationId,
  ) {
    // Cache for sender profiles to avoid repeated lookups
    final senderCache = <String, Map<String, dynamic>>{};

    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          final messages = data.where((m) => m['is_deleted'] != true).toList();

          // Get unique sender IDs that need profile data
          final senderIds = messages
              .map((m) => m['sender_id'] as String)
              .toSet()
              .where((id) => !senderCache.containsKey(id))
              .toList();

          // Fetch missing sender profiles
          if (senderIds.isNotEmpty) {
            try {
              final profiles = await _client
                  .from('profiles')
                  .select('id, full_name, avatar_url')
                  .inFilter('id', senderIds);

              for (final profile in profiles as List<dynamic>) {
                final id = profile['id'] as String;
                senderCache[id] = {
                  'full_name': profile['full_name'],
                  'avatar_url': profile['avatar_url'],
                };
              }
            } catch (e) {
              debugPrint('Error fetching sender profiles: $e');
            }
          }

          // Enrich messages with sender data
          return messages.map((m) {
            final senderId = m['sender_id'] as String;
            final senderInfo = senderCache[senderId];
            return MessageModel.fromJson({
              ...m,
              'sender_name': senderInfo?['full_name'],
              'sender_avatar_url': senderInfo?['avatar_url'],
            });
          }).toList();
        });
  }

  /// Subscribe to all messages in a trip to detect new activity
  /// Returns a stream that emits whenever any message changes in the trip
  Stream<void> subscribeToTripMessages(String tripId) {
    debugPrint('🔔 subscribeToTripMessages: Setting up realtime subscription for tripId=$tripId');
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .map((data) {
          debugPrint('🔔 subscribeToTripMessages: Received ${data.length} messages event for tripId=$tripId');
          return; // We only care about the trigger, not the data
        });
  }

  // ============================================================================
  // UTILITY
  // ============================================================================

  /// Find existing DM conversation or create new one
  Future<ConversationModel> findOrCreateDirectMessage({
    required String tripId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      // Try to use efficient database function to find existing DM
      String? existingId;
      try {
        final result = await _client.rpc(
          'find_existing_dm',
          params: {
            'p_trip_id': tripId,
            'p_user1_id': currentUserId,
            'p_user2_id': otherUserId,
          },
        );
        existingId = result as String?;
        debugPrint('find_existing_dm result: $existingId');
      } catch (rpcError) {
        // Function might not exist yet, fall back to manual search
        debugPrint('find_existing_dm RPC failed (function may not exist): $rpcError');
        existingId = await _findExistingDmManually(tripId, currentUserId, otherUserId);
      }

      if (existingId != null && existingId.isNotEmpty) {
        // Found existing DM
        debugPrint('Found existing DM: $existingId');
        return getConversation(existingId, currentUserId);
      }

      // Create new DM
      debugPrint('Creating new DM between $currentUserId and $otherUserId');
      return createConversation(
        tripId: tripId,
        name: 'Direct Message',
        memberUserIds: [currentUserId, otherUserId],
        createdBy: currentUserId,
        isDirectMessage: true,
      );
    } catch (e) {
      debugPrint('Error finding/creating DM: $e');
      rethrow;
    }
  }

  /// Ensure user is a member of the default group and return the group ID
  /// This calls the RPC function that adds the user if they're not already a member
  Future<String?> ensureUserInDefaultGroup({
    required String tripId,
    required String userId,
  }) async {
    try {
      debugPrint('🔐 ensureUserInDefaultGroup: tripId=$tripId, userId=$userId');

      // Call the RPC function that ensures user is in default group
      final result = await _client.rpc(
        'ensure_user_in_default_group',
        params: {
          'p_trip_id': tripId,
          'p_user_id': userId,
        },
      );

      final conversationId = result as String?;
      if (conversationId != null && conversationId.isNotEmpty) {
        debugPrint('🔐 ensureUserInDefaultGroup: User is now in default group: $conversationId');
        return conversationId;
      }

      debugPrint('🔐 ensureUserInDefaultGroup: No default group returned (user may not be trip member)');
      return null;
    } catch (e) {
      debugPrint('🔐 ensureUserInDefaultGroup: Error - $e');
      // Fall back to the old method if the new RPC doesn't exist
      return getDefaultGroupId(tripId: tripId);
    }
  }

  /// Get or ensure the default "All Members" group for a trip (FAST - just returns ID)
  /// Uses a simple query to find the default group quickly
  Future<String?> getDefaultGroupId({
    required String tripId,
  }) async {
    try {
      // Fast query to just get the ID of the default group
      final response = await _client
          .from('conversations')
          .select('id')
          .eq('trip_id', tripId)
          .eq('is_default_group', true)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        debugPrint('Found default group ID: ${response['id']}');
        return response['id'] as String;
      }

      // Try to ensure default group exists via RPC
      try {
        final result = await _client.rpc(
          'ensure_trip_default_group',
          params: {'p_trip_id': tripId},
        );

        final conversationId = result as String?;
        if (conversationId != null && conversationId.isNotEmpty) {
          debugPrint('Created default group: $conversationId');
          return conversationId;
        }
      } catch (rpcError) {
        debugPrint('ensure_trip_default_group RPC failed: $rpcError');
      }

      return null;
    } catch (e) {
      debugPrint('Error getting default group ID: $e');
      rethrow;
    }
  }

  /// Get or ensure the default "All Members" group for a trip (FULL - returns model)
  /// Uses the database function to get or create the default group
  Future<ConversationModel> getDefaultGroup({
    required String tripId,
    required String userId,
  }) async {
    try {
      // First try fast ID lookup
      final defaultGroupId = await getDefaultGroupId(tripId: tripId);

      if (defaultGroupId != null) {
        return getConversation(defaultGroupId, userId);
      }

      throw Exception('No default group found for this trip');
    } catch (e) {
      debugPrint('Error getting default group: $e');
      rethrow;
    }
  }

  /// Manual fallback to find existing DM when RPC function doesn't exist
  Future<String?> _findExistingDmManually(
    String tripId,
    String user1Id,
    String user2Id,
  ) async {
    try {
      // Find DM conversations in this trip where both users are members
      final response = await _client
          .from('conversations')
          .select('id, conversation_members!inner(user_id)')
          .eq('trip_id', tripId)
          .eq('is_direct_message', true);

      for (final conv in response as List<dynamic>) {
        final members = (conv['conversation_members'] as List<dynamic>)
            .map((m) => m['user_id'] as String)
            .toList();

        if (members.length == 2 &&
            members.contains(user1Id) &&
            members.contains(user2Id)) {
          return conv['id'] as String;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Manual DM search failed: $e');
      return null;
    }
  }
}
