import 'package:pathio/features/checklists/domain/entities/checklist_entity.dart';
import 'package:pathio/features/checklists/domain/repositories/checklist_repository.dart';

/// A configurable fake [ChecklistRepository] used by widget tests for
/// the checklists module. All async methods return canned data and
/// record their inputs for assertions.
class FakeChecklistRepository implements ChecklistRepository {
  // Canned responses
  List<ChecklistEntity> tripChecklistsResponse = const [];
  ChecklistWithItemsEntity? checklistWithItemsResponse;
  ChecklistEntity? createChecklistResponse;
  ChecklistEntity? updateChecklistResponse;
  ChecklistItemEntity? addItemResponse;
  ChecklistItemEntity? updateItemResponse;
  ChecklistItemEntity? toggleItemResponse;

  // Throw configurators
  Object? throwOnGetTripChecklists;
  Object? throwOnGetChecklistWithItems;
  Object? throwOnCreateChecklist;
  Object? throwOnUpdateChecklist;
  Object? throwOnDeleteChecklist;
  Object? throwOnAddItem;
  Object? throwOnUpdateItem;
  Object? throwOnToggleItem;
  Object? throwOnDeleteItem;
  Object? throwOnReorderItems;

  // Last-call recordings
  String? lastTripIdRequested;
  String? lastChecklistIdForItems;
  Map<String, dynamic>? lastCreateChecklistArgs;
  Map<String, dynamic>? lastUpdateChecklistArgs;
  String? lastDeleteChecklistId;
  Map<String, dynamic>? lastAddItemArgs;
  Map<String, dynamic>? lastUpdateItemArgs;
  Map<String, dynamic>? lastToggleArgs;
  String? lastDeleteItemId;

  @override
  Future<List<ChecklistEntity>> getTripChecklists(String tripId) async {
    if (throwOnGetTripChecklists != null) throw throwOnGetTripChecklists!;
    lastTripIdRequested = tripId;
    return tripChecklistsResponse;
  }

  @override
  Future<ChecklistWithItemsEntity> getChecklistWithItems(
      String checklistId) async {
    if (throwOnGetChecklistWithItems != null) {
      throw throwOnGetChecklistWithItems!;
    }
    lastChecklistIdForItems = checklistId;
    return checklistWithItemsResponse ??
        ChecklistWithItemsEntity(
          checklist: ChecklistEntity(
            id: checklistId,
            tripId: 'trip-default',
            name: 'Default Checklist',
            createdAt: DateTime(2024, 1, 1),
          ),
          items: const [],
        );
  }

  @override
  Future<ChecklistEntity> createChecklist({
    required String tripId,
    required String name,
    required String createdBy,
  }) async {
    if (throwOnCreateChecklist != null) throw throwOnCreateChecklist!;
    lastCreateChecklistArgs = {
      'tripId': tripId,
      'name': name,
      'createdBy': createdBy,
    };
    return createChecklistResponse ??
        ChecklistEntity(
          id: 'created-1',
          tripId: tripId,
          name: name,
          createdBy: createdBy,
          createdAt: DateTime(2024, 1, 1),
        );
  }

  @override
  Future<ChecklistEntity> updateChecklist({
    required String checklistId,
    required String name,
  }) async {
    if (throwOnUpdateChecklist != null) throw throwOnUpdateChecklist!;
    lastUpdateChecklistArgs = {
      'checklistId': checklistId,
      'name': name,
    };
    return updateChecklistResponse ??
        ChecklistEntity(
          id: checklistId,
          tripId: 'trip-default',
          name: name,
          createdAt: DateTime(2024, 1, 1),
        );
  }

  @override
  Future<void> deleteChecklist(String checklistId) async {
    if (throwOnDeleteChecklist != null) throw throwOnDeleteChecklist!;
    lastDeleteChecklistId = checklistId;
  }

  @override
  Future<ChecklistItemEntity> addChecklistItem({
    required String checklistId,
    required String title,
    String? assignedTo,
    int? orderIndex,
  }) async {
    if (throwOnAddItem != null) throw throwOnAddItem!;
    lastAddItemArgs = {
      'checklistId': checklistId,
      'title': title,
      'assignedTo': assignedTo,
      'orderIndex': orderIndex,
    };
    return addItemResponse ??
        ChecklistItemEntity(
          id: 'added-1',
          checklistId: checklistId,
          title: title,
          assignedTo: assignedTo,
          orderIndex: orderIndex ?? 0,
        );
  }

  @override
  Future<ChecklistItemEntity> updateChecklistItem({
    required String itemId,
    String? title,
    bool? isCompleted,
    String? assignedTo,
    int? orderIndex,
  }) async {
    if (throwOnUpdateItem != null) throw throwOnUpdateItem!;
    lastUpdateItemArgs = {
      'itemId': itemId,
      'title': title,
      'isCompleted': isCompleted,
      'assignedTo': assignedTo,
      'orderIndex': orderIndex,
    };
    return updateItemResponse ??
        ChecklistItemEntity(
          id: itemId,
          checklistId: 'cl-default',
          title: title ?? 'item',
          isCompleted: isCompleted ?? false,
          assignedTo: assignedTo,
          orderIndex: orderIndex ?? 0,
        );
  }

  @override
  Future<ChecklistItemEntity> toggleItemCompletion({
    required String itemId,
    required bool isCompleted,
    required String userId,
  }) async {
    if (throwOnToggleItem != null) throw throwOnToggleItem!;
    lastToggleArgs = {
      'itemId': itemId,
      'isCompleted': isCompleted,
      'userId': userId,
    };
    return toggleItemResponse ??
        ChecklistItemEntity(
          id: itemId,
          checklistId: 'cl-default',
          title: 'item',
          isCompleted: isCompleted,
        );
  }

  @override
  Future<void> deleteChecklistItem(String itemId) async {
    if (throwOnDeleteItem != null) throw throwOnDeleteItem!;
    lastDeleteItemId = itemId;
  }

  @override
  Future<void> reorderItems({
    required String checklistId,
    required List<String> itemIds,
  }) async {
    if (throwOnReorderItems != null) throw throwOnReorderItems!;
  }

  @override
  Stream<List<ChecklistEntity>> watchTripChecklists(String tripId) =>
      Stream.value(tripChecklistsResponse);

  @override
  Stream<ChecklistWithItemsEntity> watchChecklistWithItems(
          String checklistId) =>
      Stream.value(
        checklistWithItemsResponse ??
            ChecklistWithItemsEntity(
              checklist: ChecklistEntity(
                id: checklistId,
                tripId: 'trip-default',
                name: 'Default',
                createdAt: DateTime(2024, 1, 1),
              ),
              items: const [],
            ),
      );
}
