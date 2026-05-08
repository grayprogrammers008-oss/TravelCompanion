import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin abstraction over the Supabase PostgREST chain calls used by
/// [TripRemoteDataSourceImpl].
///
/// The Supabase fluent builders (`from(t).select().eq(c, v).order(...)`)
/// are not mockable through Mockito — their generic types are fixed per
/// method and `Mock` cannot intercept the awaited `then()`. Wrapping the
/// chain calls in this interface lets tests substitute a fake while the
/// production [TripQueriesImpl] carries the (untestable) Supabase code.
abstract class TripQueries {
  /// Insert a trip row and return it (selected, single).
  Future<Map<String, dynamic>> insertTrip(Map<String, dynamic> data);

  /// Get all trip IDs where a user is a member.
  /// Returns rows shaped `{trip_id: ...}`.
  Future<List<Map<String, dynamic>>> findTripIdsForUser(String userId);

  /// Fetch trips by IDs joined with members + profiles, newest first.
  Future<List<Map<String, dynamic>>> findTripsWithMembersByIds(
      List<String> tripIds);

  /// Fetch a single trip by id joined with members + profiles, or null.
  Future<Map<String, dynamic>?> findTripWithMembersById(String tripId);

  /// Update a trip by id; returns response (used for debug logging only).
  Future<List<Map<String, dynamic>>> updateTripById(
      String tripId, Map<String, dynamic> updates);

  /// Insert a member into trip_members (with `.select()` to confirm).
  Future<List<Map<String, dynamic>>> insertTripMember(
      Map<String, dynamic> data);

  /// Delete a member from a trip.
  Future<void> deleteTripMember(String tripId, String userId);

  /// Search profiles by email/full_name (or fetch all when search is null).
  Future<List<Map<String, dynamic>>> searchProfiles({
    String? search,
    int limit = 50,
  });

  /// Get all expense splits for a user (for stats sum/count).
  Future<List<Map<String, dynamic>>> findExpenseSplitsForUser(String userId);

  /// Get other users (`!= userId`) who share trips in [tripIds].
  Future<List<Map<String, dynamic>>> findCrewMemberIds(
      List<String> tripIds, String userId);

  /// Fetch the most recent public trips (joined with members + profiles).
  Future<List<Map<String, dynamic>>> findPublicTrips({int limit = 100});

  // ----- RPC wrappers -----
  Future<dynamic> rpcDeleteTrip(String tripId);

  Future<String> rpcCopyTrip({
    required String sourceTripId,
    required String newName,
    required DateTime newStartDate,
    required DateTime newEndDate,
    required bool copyItinerary,
    required bool copyChecklists,
  });

  Future<bool> rpcToggleFavorite(String tripId);

  Future<List<Map<String, dynamic>>> rpcGetFavoriteTripIds();
}

/// Production implementation that talks to Supabase. Each method is a
/// minimal pass-through to the PostgREST chain and is exercised
/// end-to-end by integration / live tests, not unit tests.
class TripQueriesImpl implements TripQueries {
  TripQueriesImpl(this._client);
  final SupabaseClient _client;

  static const String _tripWithMembersSelect = '''
            *,
            trip_members(
              id,
              user_id,
              role,
              joined_at,
              profiles(
                id,
                email,
                full_name,
                avatar_url
              )
            )
          ''';

  @override
  Future<Map<String, dynamic>> insertTrip(Map<String, dynamic> data) async {
    final response =
        await _client.from('trips').insert(data).select().single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> findTripIdsForUser(String userId) async {
    final response = await _client
        .from('trip_members')
        .select('trip_id')
        .eq('user_id', userId);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> findTripsWithMembersByIds(
      List<String> tripIds) async {
    final response = await _client
        .from('trips')
        .select(_tripWithMembersSelect)
        .inFilter('id', tripIds)
        .order('created_at', ascending: false);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> findTripWithMembersById(String tripId) async {
    final response = await _client
        .from('trips')
        .select(_tripWithMembersSelect)
        .eq('id', tripId)
        .maybeSingle();
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> updateTripById(
      String tripId, Map<String, dynamic> updates) async {
    final response = await _client
        .from('trips')
        .update(updates)
        .eq('id', tripId)
        .select();
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> insertTripMember(
      Map<String, dynamic> data) async {
    final response =
        await _client.from('trip_members').insert(data).select();
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<void> deleteTripMember(String tripId, String userId) async {
    await _client
        .from('trip_members')
        .delete()
        .eq('trip_id', tripId)
        .eq('user_id', userId);
  }

  @override
  Future<List<Map<String, dynamic>>> searchProfiles({
    String? search,
    int limit = 50,
  }) async {
    var query = _client
        .from('profiles')
        .select('id, email, full_name, avatar_url');
    if (search != null && search.isNotEmpty) {
      query = query.or('email.ilike.%$search%,full_name.ilike.%$search%');
    }
    final response = await query
        .order('full_name', ascending: true)
        .limit(limit);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> findExpenseSplitsForUser(
      String userId) async {
    final response = await _client
        .from('expense_splits')
        .select('id, amount')
        .eq('user_id', userId);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> findCrewMemberIds(
      List<String> tripIds, String userId) async {
    final response = await _client
        .from('trip_members')
        .select('user_id')
        .inFilter('trip_id', tripIds)
        .neq('user_id', userId);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> findPublicTrips({int limit = 100}) async {
    final response = await _client
        .from('trips')
        .select(_tripWithMembersSelect)
        .eq('is_public', true)
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<dynamic> rpcDeleteTrip(String tripId) async {
    return _client.rpc('admin_delete_trip', params: {'p_trip_id': tripId});
  }

  @override
  Future<String> rpcCopyTrip({
    required String sourceTripId,
    required String newName,
    required DateTime newStartDate,
    required DateTime newEndDate,
    required bool copyItinerary,
    required bool copyChecklists,
  }) async {
    final response = await _client.rpc(
      'copy_trip',
      params: {
        'p_source_trip_id': sourceTripId,
        'p_new_name': newName,
        'p_new_start_date': newStartDate.toIso8601String(),
        'p_new_end_date': newEndDate.toIso8601String(),
        'p_copy_itinerary': copyItinerary,
        'p_copy_checklists': copyChecklists,
      },
    );
    return response as String;
  }

  @override
  Future<bool> rpcToggleFavorite(String tripId) async {
    final response = await _client.rpc(
      'toggle_trip_favorite',
      params: {'p_trip_id': tripId},
    );
    return response as bool;
  }

  @override
  Future<List<Map<String, dynamic>>> rpcGetFavoriteTripIds() async {
    final response = await _client.rpc('get_user_favorite_trip_ids');
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
