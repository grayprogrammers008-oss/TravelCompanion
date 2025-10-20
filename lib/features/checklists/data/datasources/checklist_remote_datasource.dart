import '../../../../core/network/supabase_client.dart';
import '../../../../shared/models/checklist_model.dart';

/// Remote data source for checklists using Supabase
class ChecklistRemoteDataSource {
  ChecklistRemoteDataSource();

  /// Get all checklists for a trip
  Future<List<ChecklistModel>> getTripChecklists(String tripId) async {
    try {
      final response = await SupabaseClientWrapper.client
          .from('checklists')
          .select()
          .eq('trip_id', tripId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ChecklistModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch trip checklists from Supabase: $e');
    }
  }

  /// Get a single checklist
  Future<ChecklistModel?> getChecklist(String checklistId) async {
    try {
      final response = await SupabaseClientWrapper.client
          .from('checklists')
          .select()
          .eq('id', checklistId)
          .maybeSingle();

      if (response == null) return null;
      return ChecklistModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch checklist from Supabase: $e');
    }
  }

  /// Get all items for a checklist
  Future<List<ChecklistItemModel>> getChecklistItems(String checklistId) async {
    try {
      final response = await SupabaseClientWrapper.client
          .from('checklist_items')
          .select()
          .eq('checklist_id', checklistId)
          .order('order_index', ascending: true);

      return (response as List)
          .map((json) => ChecklistItemModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch checklist items from Supabase: $e');
    }
  }

  /// Create or update a checklist
  Future<ChecklistModel> upsertChecklist(ChecklistModel checklist) async {
    try {
      final response = await SupabaseClientWrapper.client
          .from('checklists')
          .upsert(checklist.toJson())
          .select()
          .single();

      return ChecklistModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to upsert checklist in Supabase: $e');
    }
  }

  /// Create or update a checklist item
  Future<ChecklistItemModel> upsertChecklistItem(ChecklistItemModel item) async {
    try {
      final response = await SupabaseClientWrapper.client
          .from('checklist_items')
          .upsert(item.toJson())
          .select()
          .single();

      return ChecklistItemModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to upsert checklist item in Supabase: $e');
    }
  }

  /// Delete a checklist
  Future<void> deleteChecklist(String checklistId) async {
    try {
      await SupabaseClientWrapper.client
          .from('checklists')
          .delete()
          .eq('id', checklistId);
    } catch (e) {
      throw Exception('Failed to delete checklist from Supabase: $e');
    }
  }

  /// Delete a checklist item
  Future<void> deleteChecklistItem(String itemId) async {
    try {
      await SupabaseClientWrapper.client
          .from('checklist_items')
          .delete()
          .eq('id', itemId);
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
      final Map<String, dynamic> updates = {
        'is_completed': isCompleted,
        'completed_by': isCompleted ? userId : null,
        'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await SupabaseClientWrapper.client
          .from('checklist_items')
          .update(updates)
          .eq('id', itemId)
          .select()
          .single();

      return ChecklistItemModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to toggle item completion in Supabase: $e');
    }
  }
}
