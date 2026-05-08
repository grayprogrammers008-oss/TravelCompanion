import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin abstraction over the Supabase PostgREST chain used by
/// [InviteRemoteDataSource].
///
/// The Supabase fluent builders (`from(t).select().eq(c, v).order(...)`)
/// are not mockable through Mockito — their generic types are fixed per
/// method and `Mock` cannot intercept the awaited `then()`. Wrapping the
/// chain calls in this interface lets tests substitute a fake while the
/// production [InviteQueriesImpl] carries the (untestable) Supabase code.
abstract class InviteQueries {
  /// Insert an invite row and return it (joined / selected).
  Future<Map<String, dynamic>> insertInvite(Map<String, dynamic> data);

  /// Get trip name/destination/dates by id.
  Future<Map<String, dynamic>> getTripDetailsById(String tripId);

  /// Get profile full_name by id.
  Future<Map<String, dynamic>> getProfileById(String userId);

  /// Find an invite by code, single() — throws if missing.
  Future<Map<String, dynamic>> findInviteByCodeStrict(String code);

  /// Find an invite by code, maybeSingle() — null if missing.
  Future<Map<String, dynamic>?> findInviteByCodeMaybe(String code);

  /// Update an invite by id with arbitrary fields.
  Future<void> updateInviteById(String id, Map<String, dynamic> data);

  /// Update an invite by code with arbitrary fields.
  Future<void> updateInviteByCode(String code, Map<String, dynamic> data);

  /// Update + select + single in one call (used by resendInvite).
  Future<Map<String, dynamic>> updateInviteByIdReturning(
    String id,
    Map<String, dynamic> data,
  );

  /// Insert a trip_members row.
  Future<void> addTripMember(Map<String, dynamic> data);

  /// All invites for a trip; optional gte filter on expires_at.
  Future<List<Map<String, dynamic>>> findInvitesForTrip(
    String tripId, {
    String? expiresAtGte,
  });

  /// Invites sent by a user, newest first.
  Future<List<Map<String, dynamic>>> findInvitesByInviter(String userId);

  /// Pending invites for email, expires_at >= now, newest first.
  Future<List<Map<String, dynamic>>> findPendingInvitesForEmail(
    String email,
    String expiresAtGte,
  );

  /// Delete invites with expires_at < now; optional trip filter.
  Future<void> deleteInvitesExpiredBefore(
    String expiresAtLt, {
    String? tripId,
  });
}

/// Production implementation that talks to Supabase. Each method is a
/// minimal pass-through to the PostgREST chain and is exercised
/// end-to-end by integration / live tests, not unit tests.
class InviteQueriesImpl implements InviteQueries {
  InviteQueriesImpl(this._client);
  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> insertInvite(Map<String, dynamic> data) async {
    final response =
        await _client.from('trip_invites').insert(data).select().single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>> getTripDetailsById(String tripId) async {
    final response = await _client
        .from('trips')
        .select('name, destination, start_date, end_date')
        .eq('id', tripId)
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>> getProfileById(String userId) async {
    final response = await _client
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>> findInviteByCodeStrict(String code) async {
    final response = await _client
        .from('trip_invites')
        .select()
        .eq('invite_code', code)
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>?> findInviteByCodeMaybe(String code) async {
    final response = await _client
        .from('trip_invites')
        .select()
        .eq('invite_code', code)
        .maybeSingle();
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<void> updateInviteById(String id, Map<String, dynamic> data) async {
    await _client.from('trip_invites').update(data).eq('id', id);
  }

  @override
  Future<void> updateInviteByCode(
    String code,
    Map<String, dynamic> data,
  ) async {
    await _client.from('trip_invites').update(data).eq('invite_code', code);
  }

  @override
  Future<Map<String, dynamic>> updateInviteByIdReturning(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client
        .from('trip_invites')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<void> addTripMember(Map<String, dynamic> data) async {
    await _client.from('trip_members').insert(data);
  }

  @override
  Future<List<Map<String, dynamic>>> findInvitesForTrip(
    String tripId, {
    String? expiresAtGte,
  }) async {
    dynamic query =
        _client.from('trip_invites').select().eq('trip_id', tripId);
    if (expiresAtGte != null) {
      query = query.gte('expires_at', expiresAtGte);
    }
    query = query.order('created_at', ascending: false);
    final response = await query;
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> findInvitesByInviter(String userId) async {
    final response = await _client
        .from('trip_invites')
        .select()
        .eq('invited_by', userId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> findPendingInvitesForEmail(
    String email,
    String expiresAtGte,
  ) async {
    final response = await _client
        .from('trip_invites')
        .select()
        .eq('email', email)
        .eq('status', 'pending')
        .gte('expires_at', expiresAtGte)
        .order('created_at', ascending: false);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<void> deleteInvitesExpiredBefore(
    String expiresAtLt, {
    String? tripId,
  }) async {
    var query = _client
        .from('trip_invites')
        .delete()
        .lt('expires_at', expiresAtLt);
    if (tripId != null) {
      query = query.eq('trip_id', tripId);
    }
    await query;
  }
}
