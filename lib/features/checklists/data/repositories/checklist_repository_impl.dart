import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/checklist_entity.dart';
import '../../domain/repositories/checklist_repository.dart';
import '../datasources/checklist_remote_datasource.dart';
import '../mappers/checklist_mapper.dart';
import '../../../../shared/models/checklist_model.dart';

/// Implementation of ChecklistRepository using Supabase (online-only mode)
class ChecklistRepositoryImpl implements ChecklistRepository {
  final ChecklistRemoteDataSource remoteDataSource;
  final Uuid _uuid = const Uuid();

  ChecklistRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<ChecklistEntity>> getTripChecklists(String tripId) async {
    try {
      final models = await remoteDataSource.getTripChecklists(tripId);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get trip checklists: $e');
    }
  }

  @override
  Future<ChecklistWithItemsEntity> getChecklistWithItems(String checklistId) async {
    try {
      final checklist = await remoteDataSource.getChecklist(checklistId);
      if (checklist == null) {
        throw Exception('Checklist not found');
      }

      final items = await remoteDataSource.getChecklistItems(checklistId);

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
      debugPrint('🟢 [Repository] createChecklist START');
      debugPrint('   Trip ID: $tripId');
      debugPrint('   Name: $name');
      debugPrint('   Created By: $createdBy');

      final now = DateTime.now();
      final id = _uuid.v4();
      debugPrint('   Generated UUID: $id');

      final model = ChecklistModel(
        id: id,
        tripId: tripId,
        name: name,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );

      debugPrint('   Created ChecklistModel: $model');
      debugPrint('   Calling remoteDataSource.upsertChecklist()...');

      final created = await remoteDataSource.upsertChecklist(model);

      debugPrint('   ✅ Remote datasource returned successfully');
      debugPrint('   Converting to entity...');

      final entity = created.toEntity();

      debugPrint('   ✅ Converted to entity successfully');
      debugPrint('🟢 [Repository] createChecklist SUCCESS');

      return entity;
    } catch (e, stackTrace) {
      debugPrint('❌ [Repository] createChecklist FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      throw Exception('Failed to create checklist: $e');
    }
  }

  @override
  Future<ChecklistEntity> updateChecklist({
    required String checklistId,
    required String name,
  }) async {
    try {
      final existing = await remoteDataSource.getChecklist(checklistId);
      if (existing == null) {
        throw Exception('Checklist not found');
      }

      final updated = existing.copyWith(
        name: name,
        updatedAt: DateTime.now(),
      );

      final result = await remoteDataSource.upsertChecklist(updated);
      return result.toEntity();
    } catch (e) {
      throw Exception('Failed to update checklist: $e');
    }
  }

  @override
  Future<void> deleteChecklist(String checklistId) async {
    try {
      await remoteDataSource.deleteChecklist(checklistId);
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
      final existingItems = await remoteDataSource.getChecklistItems(checklistId);
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

      final created = await remoteDataSource.upsertChecklistItem(model);
      return created.toEntity();
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
      // Note: Remote datasource doesn't have getChecklistItem by ID
      // We'll need to fetch all items and find the one we need
      throw UnimplementedError('updateChecklistItem not fully implemented for remote datasource');
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
      final updated = await remoteDataSource.toggleItemCompletion(
        itemId: itemId,
        isCompleted: isCompleted,
        userId: userId,
      );
      return updated.toEntity();
    } catch (e) {
      throw Exception('Failed to toggle item completion: $e');
    }
  }

  @override
  Future<void> deleteChecklistItem(String itemId) async {
    try {
      await remoteDataSource.deleteChecklistItem(itemId);
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
      final items = await remoteDataSource.getChecklistItems(checklistId);

      // Update order index for each item
      for (int i = 0; i < itemIds.length; i++) {
        final item = items.firstWhere((item) => item.id == itemIds[i]);
        final updated = item.copyWith(
          orderIndex: i,
          updatedAt: DateTime.now(),
        );
        await remoteDataSource.upsertChecklistItem(updated);
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
