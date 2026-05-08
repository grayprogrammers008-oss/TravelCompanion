import '../../../../core/network/supabase_client.dart';
import '../../../../shared/models/checklist_model.dart';
import 'checklist_queries.dart';

/// Remote data source for checklists.
///
/// All Supabase PostgREST chain calls live behind [ChecklistQueries] so the
/// datasource itself can be exercised by unit tests. The default constructor
/// wires up the production [ChecklistQueriesImpl]; tests inject a fake.
class ChecklistRemoteDataSource {
  ChecklistRemoteDataSource({
    ChecklistQueries? queries,
    DateTime Function()? clock,
  })  : _queries = queries ?? ChecklistQueriesImpl(SupabaseClientWrapper.client),
        _clock = clock ?? DateTime.now;

  final ChecklistQueries _queries;
  final DateTime Function() _clock;

  /// Get all checklists for a trip
  Future<List<ChecklistModel>> getTripChecklists(String tripId) async {
    try {
      final rows = await _queries.findChecklistsForTrip(tripId);
      return rows.map((json) => ChecklistModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch trip checklists from Supabase: $e');
    }
  }

  /// Get a single checklist
  Future<ChecklistModel?> getChecklist(String checklistId) async {
    try {
      final response = await _queries.findChecklistByIdMaybe(checklistId);
      if (response == null) return null;
      return ChecklistModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch checklist from Supabase: $e');
    }
  }

  /// Get all items for a checklist
  Future<List<ChecklistItemModel>> getChecklistItems(
      String checklistId) async {
    try {
      final rows = await _queries.findItemsForChecklist(checklistId);
      return rows.map((json) => ChecklistItemModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch checklist items from Supabase: $e');
    }
  }

  /// Create or update a checklist
  Future<ChecklistModel> upsertChecklist(ChecklistModel checklist) async {
    try {
      // Use toDatabaseJson() to exclude joined fields (creator_name)
      final json = checklist.toDatabaseJson();
      final response = await _queries.upsertChecklist(json);
      return ChecklistModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to upsert checklist in Supabase: $e');
    }
  }

  /// Create or update a checklist item
  Future<ChecklistItemModel> upsertChecklistItem(
      ChecklistItemModel item) async {
    try {
      // Use toDatabaseJson() to exclude joined fields
      final json = item.toDatabaseJson();
      final response = await _queries.upsertChecklistItem(json);
      return ChecklistItemModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to upsert checklist item in Supabase: $e');
    }
  }

  /// Delete a checklist
  Future<void> deleteChecklist(String checklistId) async {
    try {
      await _queries.deleteChecklistById(checklistId);
    } catch (e) {
      throw Exception('Failed to delete checklist from Supabase: $e');
    }
  }

  /// Delete a checklist item
  Future<void> deleteChecklistItem(String itemId) async {
    try {
      await _queries.deleteChecklistItemById(itemId);
    } catch (e) {
      throw Exception('Failed to delete checklist item from Supabase: $e');
    }
  }

  /// Toggle item completion
  Future<ChecklistItemModel> toggleItemCompletion({
    required String itemId,
    required bool isCompleted,
    required String userId,
  }) async {
    try {
      final now = _clock();
      final Map<String, dynamic> updates = {
        'is_completed': isCompleted,
        'completed_by': isCompleted ? userId : null,
        'completed_at': isCompleted ? now.toIso8601String() : null,
        'updated_at': now.toIso8601String(),
      };

      final response =
          await _queries.updateChecklistItemById(itemId, updates);
      return ChecklistItemModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to toggle item completion in Supabase: $e');
    }
  }
}
