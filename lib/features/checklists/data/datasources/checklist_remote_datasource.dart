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
      print('🔵 [RemoteDataSource] upsertChecklist START');
      print('   Checklist ID: ${checklist.id}');
      print('   Checklist Name: ${checklist.name}');
      print('   Trip ID: ${checklist.tripId}');
      print('   Created By: ${checklist.createdBy}');

      // Use toDatabaseJson() to exclude joined fields (creator_name)
      final json = checklist.toDatabaseJson();
      print('   Database JSON to send: $json');

      print('   Calling Supabase.from("checklists").upsert()...');
      final response = await SupabaseClientWrapper.client
          .from('checklists')
          .upsert(json)
          .select()
          .single();

      print('   ✅ Supabase response received');
      print('   Response type: ${response.runtimeType}');
      print('   Response data: $response');

      final result = ChecklistModel.fromJson(response);
      print('   ✅ Successfully converted to ChecklistModel');
      print('🔵 [RemoteDataSource] upsertChecklist SUCCESS');

      return result;
    } catch (e, stackTrace) {
      print('❌ [RemoteDataSource] upsertChecklist FAILED');
      print('   Exception: $e');
      print('   Exception Type: ${e.runtimeType}');
      print('   Stack Trace: $stackTrace');
      throw Exception('Failed to upsert checklist in Supabase: $e');
    }
  }

  /// Create or update a checklist item
  Future<ChecklistItemModel> upsertChecklistItem(ChecklistItemModel item) async {
    try {
      print('🔵 [RemoteDataSource] upsertChecklistItem START');
      print('   Item ID: ${item.id}');
      print('   Item Title: ${item.title}');
      print('   Checklist ID: ${item.checklistId}');

      // Use toDatabaseJson() to exclude joined fields (assigned_to_name, completed_by_name)
      final json = item.toDatabaseJson();
      print('   Database JSON to send: $json');

      print('   Calling Supabase.from("checklist_items").upsert()...');
      final response = await SupabaseClientWrapper.client
          .from('checklist_items')
          .upsert(json)
          .select()
          .single();

      print('   ✅ Supabase response received');
      print('   Response data: $response');

      final result = ChecklistItemModel.fromJson(response);
      print('   ✅ Successfully converted to ChecklistItemModel');
      print('🔵 [RemoteDataSource] upsertChecklistItem SUCCESS');

      return result;
    } catch (e, stackTrace) {
      print('❌ [RemoteDataSource] upsertChecklistItem FAILED');
      print('   Exception: $e');
      print('   Exception Type: ${e.runtimeType}');
      print('   Stack Trace: $stackTrace');
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
