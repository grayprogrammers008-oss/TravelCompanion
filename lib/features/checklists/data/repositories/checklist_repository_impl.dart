import 'package:uuid/uuid.dart';
import '../../domain/entities/checklist_entity.dart';
import '../../domain/repositories/checklist_repository.dart';
import '../datasources/checklist_local_datasource.dart';
import '../mappers/checklist_mapper.dart';
import '../../../../shared/models/checklist_model.dart';

/// Implementation of ChecklistRepository using local SQLite storage
class ChecklistRepositoryImpl implements ChecklistRepository {
  final ChecklistLocalDataSource localDataSource;
  final Uuid _uuid = const Uuid();

  ChecklistRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<List<ChecklistEntity>> getTripChecklists(String tripId) async {
    try {
      final models = await localDataSource.getTripChecklists(tripId);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get trip checklists: $e');
    }
  }

  @override
  Future<ChecklistWithItemsEntity> getChecklistWithItems(String checklistId) async {
    try {
      final checklist = await localDataSource.getChecklist(checklistId);
      if (checklist == null) {
        throw Exception('Checklist not found');
      }

      final items = await localDataSource.getChecklistItems(checklistId);

      final checklistWithItems = ChecklistWithItems(
        checklist: checklist,
        items: items,
      );

      return checklistWithItems.toEntity();
    } catch (e) {
      throw Exception('Failed to get checklist with items: $e');
    }
  }

  @override
  Future<ChecklistEntity> createChecklist({
    required String tripId,
    required String name,
    required String createdBy,
  }) async {
    try {
      final now = DateTime.now();
      final model = ChecklistModel(
        id: _uuid.v4(),
        tripId: tripId,
        name: name,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );

      await localDataSource.upsertChecklist(model);
      return model.toEntity();
    } catch (e) {
      throw Exception('Failed to create checklist: $e');
    }
  }

  @override
  Future<ChecklistEntity> updateChecklist({
    required String checklistId,
    required String name,
  }) async {
    try {
      final existing = await localDataSource.getChecklist(checklistId);
      if (existing == null) {
        throw Exception('Checklist not found');
      }

      final updated = existing.copyWith(
        name: name,
        updatedAt: DateTime.now(),
      );

      await localDataSource.upsertChecklist(updated);
      return updated.toEntity();
    } catch (e) {
      throw Exception('Failed to update checklist: $e');
    }
  }

  @override
  Future<void> deleteChecklist(String checklistId) async {
    try {
      await localDataSource.deleteChecklist(checklistId);
    } catch (e) {
      throw Exception('Failed to delete checklist: $e');
    }
  }

  @override
  Future<ChecklistItemEntity> addChecklistItem({
    required String checklistId,
    required String title,
    String? assignedTo,
    int? orderIndex,
  }) async {
    try {
      // Get existing items to determine order index if not provided
      final existingItems = await localDataSource.getChecklistItems(checklistId);
      final defaultOrderIndex = existingItems.length;

      final now = DateTime.now();
      final model = ChecklistItemModel(
        id: _uuid.v4(),
        checklistId: checklistId,
        title: title,
        assignedTo: assignedTo,
        orderIndex: orderIndex ?? defaultOrderIndex,
        createdAt: now,
        updatedAt: now,
      );

      await localDataSource.upsertChecklistItem(model);
      return model.toEntity();
    } catch (e) {
      throw Exception('Failed to add checklist item: $e');
    }
  }

  @override
  Future<ChecklistItemEntity> updateChecklistItem({
    required String itemId,
    String? title,
    bool? isCompleted,
    String? assignedTo,
    int? orderIndex,
  }) async {
    try {
      // Get existing item by ID
      final existing = await localDataSource.getChecklistItem(itemId);

      if (existing == null) {
        throw Exception('Checklist item not found');
      }

      final updated = existing.copyWith(
        title: title,
        isCompleted: isCompleted,
        assignedTo: assignedTo,
        orderIndex: orderIndex,
        updatedAt: DateTime.now(),
      );

      await localDataSource.upsertChecklistItem(updated);
      return updated.toEntity();
    } catch (e) {
      throw Exception('Failed to update checklist item: $e');
    }
  }

  @override
  Future<ChecklistItemEntity> toggleItemCompletion({
    required String itemId,
    required bool isCompleted,
    required String userId,
  }) async {
    try {
      // Get existing item by ID
      final existing = await localDataSource.getChecklistItem(itemId);

      if (existing == null) {
        throw Exception('Checklist item not found');
      }

      final now = DateTime.now();
      final updated = existing.copyWith(
        isCompleted: isCompleted,
        completedBy: isCompleted ? userId : null,
        completedAt: isCompleted ? now : null,
        updatedAt: now,
      );

      await localDataSource.upsertChecklistItem(updated);
      return updated.toEntity();
    } catch (e) {
      throw Exception('Failed to toggle item completion: $e');
    }
  }

  @override
  Future<void> deleteChecklistItem(String itemId) async {
    try {
      await localDataSource.deleteChecklistItem(itemId);
    } catch (e) {
      throw Exception('Failed to delete checklist item: $e');
    }
  }

  @override
  Future<void> reorderItems({
    required String checklistId,
    required List<String> itemIds,
  }) async {
    try {
      final items = await localDataSource.getChecklistItems(checklistId);

      // Update order index for each item
      for (int i = 0; i < itemIds.length; i++) {
        final item = items.firstWhere((item) => item.id == itemIds[i]);
        final updated = item.copyWith(
          orderIndex: i,
          updatedAt: DateTime.now(),
        );
        await localDataSource.upsertChecklistItem(updated);
      }
    } catch (e) {
      throw Exception('Failed to reorder items: $e');
    }
  }

  @override
  Stream<List<ChecklistEntity>> watchTripChecklists(String tripId) {
    // For local-only implementation, we'll use polling
    // In a real app with Supabase, this would use real-time subscriptions
    return Stream.periodic(const Duration(seconds: 2))
        .asyncMap((_) => getTripChecklists(tripId));
  }

  @override
  Stream<ChecklistWithItemsEntity> watchChecklistWithItems(String checklistId) {
    // For local-only implementation, we'll use polling
    // In a real app with Supabase, this would use real-time subscriptions
    return Stream.periodic(const Duration(seconds: 2))
        .asyncMap((_) => getChecklistWithItems(checklistId));
  }
}
