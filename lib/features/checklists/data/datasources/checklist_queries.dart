import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin abstraction over the Supabase PostgREST chain used by
/// [ChecklistRemoteDataSource].
///
/// The Supabase fluent builders (`from(t).select().eq(c, v).order(...)`)
/// are not mockable through Mockito — their generic types are fixed per
/// method and `Mock` cannot intercept the awaited `then()`. Wrapping the
/// chain calls in this interface lets tests substitute a fake while the
/// production [ChecklistQueriesImpl] carries the (untestable) Supabase code.
abstract class ChecklistQueries {
  /// Get all checklists for a trip ordered by created_at desc.
  Future<List<Map<String, dynamic>>> findChecklistsForTrip(String tripId);

  /// Get a single checklist by id (maybeSingle — returns null if missing).
  Future<Map<String, dynamic>?> findChecklistByIdMaybe(String checklistId);

  /// Get all items for a checklist ordered by order_index asc.
  Future<List<Map<String, dynamic>>> findItemsForChecklist(String checklistId);

  /// Upsert a checklist row, returning the persisted shape.
  Future<Map<String, dynamic>> upsertChecklist(Map<String, dynamic> data);

  /// Upsert a checklist item, returning the persisted shape.
  Future<Map<String, dynamic>> upsertChecklistItem(Map<String, dynamic> data);

  /// Delete a checklist by id.
  Future<void> deleteChecklistById(String checklistId);

  /// Delete a checklist item by id.
  Future<void> deleteChecklistItemById(String itemId);

  /// Update an item with the given updates and return the persisted row.
  Future<Map<String, dynamic>> updateChecklistItemById(
    String itemId,
    Map<String, dynamic> updates,
  );
}

/// Production implementation that talks to Supabase. Each method is a
/// minimal pass-through to the PostgREST chain and is exercised by
/// integration tests, not unit tests.
class ChecklistQueriesImpl implements ChecklistQueries {
  ChecklistQueriesImpl(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> findChecklistsForTrip(
      String tripId) async {
    final response = await _client
        .from('checklists')
        .select()
        .eq('trip_id', tripId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> findChecklistByIdMaybe(
      String checklistId) async {
    final response = await _client
        .from('checklists')
        .select()
        .eq('id', checklistId)
        .maybeSingle();
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> findItemsForChecklist(
      String checklistId) async {
    final response = await _client
        .from('checklist_items')
        .select()
        .eq('checklist_id', checklistId)
        .order('order_index', ascending: true);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> upsertChecklist(
      Map<String, dynamic> data) async {
    final response =
        await _client.from('checklists').upsert(data).select().single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>> upsertChecklistItem(
      Map<String, dynamic> data) async {
    final response =
        await _client.from('checklist_items').upsert(data).select().single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<void> deleteChecklistById(String checklistId) async {
    await _client.from('checklists').delete().eq('id', checklistId);
  }

  @override
  Future<void> deleteChecklistItemById(String itemId) async {
    await _client.from('checklist_items').delete().eq('id', itemId);
  }

  @override
  Future<Map<String, dynamic>> updateChecklistItemById(
    String itemId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _client
        .from('checklist_items')
        .update(updates)
        .eq('id', itemId)
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }
}
