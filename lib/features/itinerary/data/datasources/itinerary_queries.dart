import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin abstraction over the Supabase PostgREST chain used by
/// [ItineraryRemoteDataSource].
///
/// The Supabase fluent builders (`from(t).select().eq(c, v).order(...)`)
/// are not mockable through Mockito — their generic types are fixed per
/// method and `Mock` cannot intercept the awaited `then()`. Wrapping the
/// chain calls in this interface lets tests substitute a fake while the
/// production [ItineraryQueriesImpl] carries the (untestable) Supabase code.
///
/// Note: real-time channel subscriptions used in `watchTripItinerary` /
/// `watchItineraryByDays` are NOT routed through this interface; those
/// streams call `_supabase.channel(...)` directly and remain outside the
/// unit-test surface.
abstract class ItineraryQueries {
  /// Insert an itinerary item and return the joined row
  /// (`*, profiles!created_by(full_name)`).
  Future<Map<String, dynamic>> insertItem(Map<String, dynamic> data);

  /// All items for a trip joined with creator profile, ordered by
  /// (day_number asc, order_index asc).
  Future<List<Map<String, dynamic>>> findItemsForTrip(String tripId);

  /// Items for a specific day of a trip, ordered by order_index asc,
  /// joined with creator profile.
  Future<List<Map<String, dynamic>>> findItemsForDay(
    String tripId,
    int dayNumber,
  );

  /// Get a single item by id, joined with creator profile.
  Future<Map<String, dynamic>> findItemById(String itemId);

  /// Update an item by id and return the joined row.
  Future<Map<String, dynamic>> updateItemByIdReturning(
    String itemId,
    Map<String, dynamic> data,
  );

  /// Delete an item by id.
  Future<void> deleteItemById(String itemId);

  /// Update a single item scoped to (id, trip_id, day_number) — used while
  /// reordering items within a day.
  Future<void> updateItemScopedToDay({
    required String itemId,
    required String tripId,
    required int dayNumber,
    required Map<String, dynamic> data,
  });

  /// Get the highest `order_index` currently used on a target day. Returns
  /// the row(s) with order_index desc, limit 1 (so a list of 0 or 1).
  Future<List<Map<String, dynamic>>> findMaxOrderIndexForDay(
    String tripId,
    int dayNumber,
  );

  /// Update an item by id only (used by moveItemToDay to set the new day +
  /// order_index after the max-order lookup).
  Future<void> updateItemById(String itemId, Map<String, dynamic> data);
}

/// Production implementation that talks to Supabase. Each method is a
/// minimal pass-through to the PostgREST chain and is exercised
/// end-to-end by integration / live tests, not unit tests.
class ItineraryQueriesImpl implements ItineraryQueries {
  ItineraryQueriesImpl(this._client);
  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> insertItem(Map<String, dynamic> data) async {
    final response = await _client
        .from('itinerary_items')
        .insert(data)
        .select('*, profiles!created_by(full_name)')
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> findItemsForTrip(String tripId) async {
    final response = await _client
        .from('itinerary_items')
        .select('*, profiles!created_by(full_name)')
        .eq('trip_id', tripId)
        .order('day_number', ascending: true)
        .order('order_index', ascending: true);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> findItemsForDay(
    String tripId,
    int dayNumber,
  ) async {
    final response = await _client
        .from('itinerary_items')
        .select('*, profiles!created_by(full_name)')
        .eq('trip_id', tripId)
        .eq('day_number', dayNumber)
        .order('order_index', ascending: true);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> findItemById(String itemId) async {
    final response = await _client
        .from('itinerary_items')
        .select('*, profiles!created_by(full_name)')
        .eq('id', itemId)
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>> updateItemByIdReturning(
    String itemId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client
        .from('itinerary_items')
        .update(data)
        .eq('id', itemId)
        .select('*, profiles!created_by(full_name)')
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<void> deleteItemById(String itemId) async {
    await _client.from('itinerary_items').delete().eq('id', itemId);
  }

  @override
  Future<void> updateItemScopedToDay({
    required String itemId,
    required String tripId,
    required int dayNumber,
    required Map<String, dynamic> data,
  }) async {
    await _client
        .from('itinerary_items')
        .update(data)
        .eq('id', itemId)
        .eq('trip_id', tripId)
        .eq('day_number', dayNumber);
  }

  @override
  Future<List<Map<String, dynamic>>> findMaxOrderIndexForDay(
    String tripId,
    int dayNumber,
  ) async {
    final response = await _client
        .from('itinerary_items')
        .select('order_index')
        .eq('trip_id', tripId)
        .eq('day_number', dayNumber)
        .order('order_index', ascending: false)
        .limit(1);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<void> updateItemById(
    String itemId,
    Map<String, dynamic> data,
  ) async {
    await _client.from('itinerary_items').update(data).eq('id', itemId);
  }
}
