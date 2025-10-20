import '../entities/checklist_entity.dart';

/// Repository interface for checklist operations
abstract class ChecklistRepository {
  /// Get all checklists for a trip
  Future<List<ChecklistEntity>> getTripChecklists(String tripId);

  /// Get a specific checklist with its items
  Future<ChecklistWithItemsEntity> getChecklistWithItems(String checklistId);

  /// Create a new checklist
  Future<ChecklistEntity> createChecklist({
    required String tripId,
    required String name,
    required String createdBy,
  });

  /// Update checklist details
  Future<ChecklistEntity> updateChecklist({
    required String checklistId,
    required String name,
  });

  /// Delete a checklist
  Future<void> deleteChecklist(String checklistId);

  /// Add item to checklist
  Future<ChecklistItemEntity> addChecklistItem({
    required String checklistId,
    required String title,
    String? assignedTo,
    int? orderIndex,
  });

  /// Update checklist item
  Future<ChecklistItemEntity> updateChecklistItem({
    required String itemId,
    String? title,
    bool? isCompleted,
    String? assignedTo,
    int? orderIndex,
  });

  /// Toggle item completion status
  Future<ChecklistItemEntity> toggleItemCompletion({
    required String itemId,
    required bool isCompleted,
    required String userId,
  });

  /// Delete checklist item
  Future<void> deleteChecklistItem(String itemId);

  /// Reorder checklist items
  Future<void> reorderItems({
    required String checklistId,
    required List<String> itemIds,
  });

  /// Watch checklist changes (real-time)
  Stream<List<ChecklistEntity>> watchTripChecklists(String tripId);

  /// Watch specific checklist with items (real-time)
  Stream<ChecklistWithItemsEntity> watchChecklistWithItems(String checklistId);
}
