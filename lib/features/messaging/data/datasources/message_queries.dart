import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin abstraction over the Supabase PostgREST chain used by
/// [MessageRemoteDataSource].
///
/// The Supabase fluent builders (`from(t).select().eq(c, v).order(...)`)
/// are not mockable through Mockito — their generic types are fixed per
/// method and `Mock` cannot intercept the awaited `then()`. Wrapping the
/// chain calls in this interface lets tests substitute a fake while the
/// production [MessageQueriesImpl] carries the (untestable) Supabase code.
///
/// Note: realtime stream subscription methods on [MessageRemoteDataSource]
/// (e.g. `subscribeToTripMessages`) keep their direct channel/stream usage.
abstract class MessageQueries {
  // ============================== Messages CRUD ==============================

  /// Insert a message row and return it.
  Future<Map<String, dynamic>> insertMessage(Map<String, dynamic> data);

  /// Get all (non-deleted) messages for a trip joined with sender profile.
  Future<List<Map<String, dynamic>>> findTripMessages({
    required String tripId,
    required int limit,
    required int offset,
  });

  /// Get a single message by id (joined with profile), or null if missing.
  Future<Map<String, dynamic>?> findMessageById(String messageId);

  /// Get messages for a trip created strictly after a given timestamp.
  Future<List<Map<String, dynamic>>> findMessagesAfter({
    required String tripId,
    required String createdAtGt,
  });

  /// Get all replies to a particular message (ordered ascending).
  Future<List<Map<String, dynamic>>> findThreadedReplies(String messageId);

  /// Soft-delete a message (sets `is_deleted = true`).
  Future<void> softDeleteMessage(String messageId);

  /// Update an arbitrary field set on a message by id.
  Future<void> updateMessageById(String messageId, Map<String, dynamic> data);

  /// Call the `mark_message_as_read` RPC.
  Future<void> rpcMarkMessageAsRead({
    required String messageId,
    required String userId,
  });

  // ============================== Queue ==============================

  /// Insert a queued message row.
  Future<void> insertQueuedMessage(Map<String, dynamic> data);

  /// Get pending/failed queue rows ordered by created_at ascending.
  Future<List<Map<String, dynamic>>> findPendingQueuedMessages();

  /// Update a queued message row by id.
  Future<void> updateQueuedMessageById(
    String queueId,
    Map<String, dynamic> data,
  );

  /// Delete a queued message row by id.
  Future<void> deleteQueuedMessageById(String queueId);
}

/// Production implementation that talks to Supabase. Each method is a
/// minimal pass-through to the PostgREST chain and is exercised
/// end-to-end by integration / live tests, not unit tests.
class MessageQueriesImpl implements MessageQueries {
  MessageQueriesImpl(this._client);
  final SupabaseClient _client;

  static const String _profileJoin = '''
            *,
            profiles!messages_sender_id_fkey(
              full_name,
              avatar_url
            )
          ''';

  @override
  Future<Map<String, dynamic>> insertMessage(Map<String, dynamic> data) async {
    final response =
        await _client.from('messages').insert(data).select().single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> findTripMessages({
    required String tripId,
    required int limit,
    required int offset,
  }) async {
    final response = await _client
        .from('messages')
        .select(_profileJoin)
        .eq('trip_id', tripId)
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> findMessageById(String messageId) async {
    final response = await _client
        .from('messages')
        .select(_profileJoin)
        .eq('id', messageId)
        .maybeSingle();
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> findMessagesAfter({
    required String tripId,
    required String createdAtGt,
  }) async {
    final response = await _client
        .from('messages')
        .select(_profileJoin)
        .eq('trip_id', tripId)
        .eq('is_deleted', false)
        .gt('created_at', createdAtGt)
        .order('created_at', ascending: false);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> findThreadedReplies(
      String messageId) async {
    final response = await _client
        .from('messages')
        .select(_profileJoin)
        .eq('reply_to_id', messageId)
        .eq('is_deleted', false)
        .order('created_at', ascending: true);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<void> softDeleteMessage(String messageId) async {
    await _client
        .from('messages')
        .update({'is_deleted': true}).eq('id', messageId);
  }

  @override
  Future<void> updateMessageById(
    String messageId,
    Map<String, dynamic> data,
  ) async {
    await _client.from('messages').update(data).eq('id', messageId);
  }

  @override
  Future<void> rpcMarkMessageAsRead({
    required String messageId,
    required String userId,
  }) async {
    await _client.rpc(
      'mark_message_as_read',
      params: {
        'message_id': messageId,
        'user_id': userId,
      },
    );
  }

  @override
  Future<void> insertQueuedMessage(Map<String, dynamic> data) async {
    await _client.from('message_queue').insert(data);
  }

  @override
  Future<List<Map<String, dynamic>>> findPendingQueuedMessages() async {
    final response = await _client
        .from('message_queue')
        .select()
        .inFilter('sync_status', ['pending', 'failed']).order('created_at',
            ascending: true);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<void> updateQueuedMessageById(
    String queueId,
    Map<String, dynamic> data,
  ) async {
    await _client.from('message_queue').update(data).eq('id', queueId);
  }

  @override
  Future<void> deleteQueuedMessageById(String queueId) async {
    await _client.from('message_queue').delete().eq('id', queueId);
  }
}
