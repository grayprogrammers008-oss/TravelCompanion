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
  Stream<List<MessageModel>> subscribeToConversationMessages(
    String conversationId,
  ) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .map((data) {
          return data
              .where((m) => m['is_deleted'] != true)
              .map((m) => MessageModel.fromJson(m))
              .toList();
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
      // Use efficient database function to find existing DM
      final existingId = await _client.rpc(
        'find_existing_dm',
        params: {
          'p_trip_id': tripId,
          'p_user1_id': currentUserId,
          'p_user2_id': otherUserId,
        },
      );

      if (existingId != null) {
        // Found existing DM
        return getConversation(existingId as String, currentUserId);
      }

      // Create new DM
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
}
