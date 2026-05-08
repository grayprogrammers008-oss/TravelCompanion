import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin abstraction over the Supabase PostgREST chain used by
/// [ConversationRemoteDataSource].
///
/// The Supabase fluent builders (`from(t).select().eq(c, v).order(...)`)
/// are not mockable through Mockito — their generic types are fixed per
/// method and `Mock` cannot intercept the awaited `then()`. Wrapping the
/// chain calls in this interface lets tests substitute a fake while the
/// production [ConversationQueriesImpl] carries the (untestable) Supabase
/// code.
///
/// Note: realtime stream subscription methods on
/// [ConversationRemoteDataSource] (e.g. `subscribeToConversation`,
/// `subscribeToTripMessages`) keep their direct channel/stream
/// subscription on the [SupabaseClient] because Supabase realtime is not
/// modelled by the queries seam.
abstract class ConversationQueries {
  // ============================== Conversations ==============================

  /// Insert a new conversation row, return inserted (id, ...).
  Future<Map<String, dynamic>> insertConversation(Map<String, dynamic> data);

  /// Update fields on a conversation by id.
  Future<void> updateConversationById(
    String conversationId,
    Map<String, dynamic> data,
  );

  /// Hard delete a conversation by id.
  Future<void> deleteConversationById(String conversationId);

  /// Find the default group's id for a trip via direct query, or null.
  Future<String?> findDefaultGroupIdForTrip(String tripId);

  /// Find all DM conversations for a trip with their member ids
  /// (returns list of {id, conversation_members: [{user_id}]}).
  Future<List<Map<String, dynamic>>> findDirectMessagesForTrip(String tripId);

  // ============================== RPCs ==============================

  /// `get_trip_conversations` RPC.
  Future<List<dynamic>> rpcGetTripConversations({
    required String tripId,
    required String userId,
  });

  /// `get_conversation_with_details` RPC.
  Future<List<dynamic>> rpcGetConversationWithDetails({
    required String conversationId,
    required String userId,
  });

  /// `mark_conversation_as_read` RPC.
  Future<void> rpcMarkConversationAsRead({
    required String conversationId,
    required String userId,
  });

  /// `find_existing_dm` RPC. May return null.
  Future<String?> rpcFindExistingDm({
    required String tripId,
    required String user1Id,
    required String user2Id,
  });

  /// `ensure_user_in_default_group` RPC. Returns conversation id (or null).
  Future<String?> rpcEnsureUserInDefaultGroup({
    required String tripId,
    required String userId,
  });

  /// `ensure_trip_default_group` RPC. Returns conversation id (or null).
  Future<String?> rpcEnsureTripDefaultGroup(String tripId);

  // ============================== Members ==============================

  /// Insert one or more conversation_members rows.
  Future<void> insertConversationMembers(List<Map<String, dynamic>> rows);

  /// Delete conversation_members rows by composite (conversation_id, user_id).
  Future<void> deleteConversationMember({
    required String conversationId,
    required String userId,
  });

  /// Update conversation_members rows by composite (conversation_id, user_id).
  Future<void> updateConversationMember({
    required String conversationId,
    required String userId,
    required Map<String, dynamic> data,
  });

  /// Find conversation_members for a conversation, joined with profile.
  Future<List<Map<String, dynamic>>> findConversationMembers(
    String conversationId, {
    bool ordered = false,
  });

  // ============================== Messages ==============================

  /// Get messages for a conversation joined with sender profile.
  Future<List<Map<String, dynamic>>> findConversationMessages({
    required String conversationId,
    required int limit,
    required int offset,
  });

  /// Insert a message; return the inserted row joined with sender profile.
  Future<Map<String, dynamic>> insertMessage(Map<String, dynamic> data);

  /// Soft delete a single message by id, only if sender matches.
  Future<void> softDeleteMessageBySender({
    required String messageId,
    required String senderId,
  });
}

/// Production implementation that talks to Supabase.
class ConversationQueriesImpl implements ConversationQueries {
  ConversationQueriesImpl(this._client);
  final SupabaseClient _client;

  static const String _memberProfileJoin = '''
            *,
            profiles:user_id (
              id,
              full_name,
              avatar_url,
              email
            )
          ''';

  static const String _senderJoin = '''
            *,
            sender:sender_id (
              id,
              full_name,
              avatar_url
            )
          ''';

  @override
  Future<Map<String, dynamic>> insertConversation(
      Map<String, dynamic> data) async {
    final response = await _client
        .from('conversations')
        .insert(data)
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<void> updateConversationById(
    String conversationId,
    Map<String, dynamic> data,
  ) async {
    await _client
        .from('conversations')
        .update(data)
        .eq('id', conversationId);
  }

  @override
  Future<void> deleteConversationById(String conversationId) async {
    await _client.from('conversations').delete().eq('id', conversationId);
  }

  @override
  Future<String?> findDefaultGroupIdForTrip(String tripId) async {
    final response = await _client
        .from('conversations')
        .select('id')
        .eq('trip_id', tripId)
        .eq('is_default_group', true)
        .limit(1)
        .maybeSingle();
    if (response == null) return null;
    return response['id'] as String?;
  }

  @override
  Future<List<Map<String, dynamic>>> findDirectMessagesForTrip(
      String tripId) async {
    final response = await _client
        .from('conversations')
        .select('id, conversation_members!inner(user_id)')
        .eq('trip_id', tripId)
        .eq('is_direct_message', true);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<List<dynamic>> rpcGetTripConversations({
    required String tripId,
    required String userId,
  }) async {
    final response = await _client.rpc('get_trip_conversations', params: {
      'p_trip_id': tripId,
      'p_user_id': userId,
    });
    return response as List<dynamic>;
  }

  @override
  Future<List<dynamic>> rpcGetConversationWithDetails({
    required String conversationId,
    required String userId,
  }) async {
    final response =
        await _client.rpc('get_conversation_with_details', params: {
      'p_conversation_id': conversationId,
      'p_user_id': userId,
    });
    return response as List<dynamic>;
  }

  @override
  Future<void> rpcMarkConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    await _client.rpc('mark_conversation_as_read', params: {
      'p_conversation_id': conversationId,
      'p_user_id': userId,
    });
  }

  @override
  Future<String?> rpcFindExistingDm({
    required String tripId,
    required String user1Id,
    required String user2Id,
  }) async {
    final result = await _client.rpc('find_existing_dm', params: {
      'p_trip_id': tripId,
      'p_user1_id': user1Id,
      'p_user2_id': user2Id,
    });
    return result as String?;
  }

  @override
  Future<String?> rpcEnsureUserInDefaultGroup({
    required String tripId,
    required String userId,
  }) async {
    final result = await _client.rpc('ensure_user_in_default_group', params: {
      'p_trip_id': tripId,
      'p_user_id': userId,
    });
    return result as String?;
  }

  @override
  Future<String?> rpcEnsureTripDefaultGroup(String tripId) async {
    final result = await _client
        .rpc('ensure_trip_default_group', params: {'p_trip_id': tripId});
    return result as String?;
  }

  @override
  Future<void> insertConversationMembers(
      List<Map<String, dynamic>> rows) async {
    await _client.from('conversation_members').insert(rows);
  }

  @override
  Future<void> deleteConversationMember({
    required String conversationId,
    required String userId,
  }) async {
    await _client
        .from('conversation_members')
        .delete()
        .eq('conversation_id', conversationId)
        .eq('user_id', userId);
  }

  @override
  Future<void> updateConversationMember({
    required String conversationId,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _client
        .from('conversation_members')
        .update(data)
        .eq('conversation_id', conversationId)
        .eq('user_id', userId);
  }

  @override
  Future<List<Map<String, dynamic>>> findConversationMembers(
    String conversationId, {
    bool ordered = false,
  }) async {
    dynamic query = _client
        .from('conversation_members')
        .select(_memberProfileJoin)
        .eq('conversation_id', conversationId);
    if (ordered) {
      query = query.order('joined_at');
    }
    final response = await query;
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> findConversationMessages({
    required String conversationId,
    required int limit,
    required int offset,
  }) async {
    final response = await _client
        .from('messages')
        .select(_senderJoin)
        .eq('conversation_id', conversationId)
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> insertMessage(Map<String, dynamic> data) async {
    final response = await _client
        .from('messages')
        .insert(data)
        .select(_senderJoin)
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<void> softDeleteMessageBySender({
    required String messageId,
    required String senderId,
  }) async {
    await _client
        .from('messages')
        .update({'is_deleted': true})
        .eq('id', messageId)
        .eq('sender_id', senderId);
  }
}
