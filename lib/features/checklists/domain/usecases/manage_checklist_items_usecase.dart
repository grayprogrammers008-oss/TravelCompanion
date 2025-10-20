import '../entities/checklist_entity.dart';
import '../repositories/checklist_repository.dart';

/// Input parameters for adding a checklist item
class AddChecklistItemParams {
  final String checklistId;
  final String title;
  final String? assignedTo;
  final int? orderIndex;

  const AddChecklistItemParams({
    required this.checklistId,
    required this.title,
    this.assignedTo,
    this.orderIndex,
  });
}

/// Use case to add a new item to a checklist
class AddChecklistItemUseCase {
  final ChecklistRepository repository;

  AddChecklistItemUseCase(this.repository);

  Future<ChecklistItemEntity> call(AddChecklistItemParams params) async {
    // Validation
    if (params.checklistId.isEmpty) {
      throw ArgumentError('Checklist ID cannot be empty');
    }

    if (params.title.trim().isEmpty) {
      throw ArgumentError('Item title cannot be empty');
    }

    if (params.title.length > 200) {
      throw ArgumentError('Item title cannot exceed 200 characters');
    }

    return await repository.addChecklistItem(
      checklistId: params.checklistId,
      title: params.title.trim(),
      assignedTo: params.assignedTo,
      orderIndex: params.orderIndex,
    );
  }
}

/// Input parameters for updating a checklist item
class UpdateChecklistItemParams {
  final String itemId;
  final String? title;
  final bool? isCompleted;
  final String? assignedTo;
  final int? orderIndex;

  const UpdateChecklistItemParams({
    required this.itemId,
    this.title,
    this.isCompleted,
    this.assignedTo,
    this.orderIndex,
  });
}

/// Use case to update a checklist item
class UpdateChecklistItemUseCase {
  final ChecklistRepository repository;

  UpdateChecklistItemUseCase(this.repository);

  Future<ChecklistItemEntity> call(UpdateChecklistItemParams params) async {
    // Validation
    if (params.itemId.isEmpty) {
      throw ArgumentError('Item ID cannot be empty');
    }

    if (params.title != null && params.title!.trim().isEmpty) {
      throw ArgumentError('Item title cannot be empty');
    }

    if (params.title != null && params.title!.length > 200) {
      throw ArgumentError('Item title cannot exceed 200 characters');
    }

    return await repository.updateChecklistItem(
      itemId: params.itemId,
      title: params.title?.trim(),
      isCompleted: params.isCompleted,
      assignedTo: params.assignedTo,
      orderIndex: params.orderIndex,
    );
  }
}

/// Input parameters for toggling item completion
class ToggleItemCompletionParams {
  final String itemId;
  final bool isCompleted;
  final String userId;

  const ToggleItemCompletionParams({
    required this.itemId,
    required this.isCompleted,
    required this.userId,
  });
}

/// Use case to toggle checklist item completion
class ToggleItemCompletionUseCase {
  final ChecklistRepository repository;

  ToggleItemCompletionUseCase(this.repository);

  Future<ChecklistItemEntity> call(ToggleItemCompletionParams params) async {
    // Validation
    if (params.itemId.isEmpty) {
      throw ArgumentError('Item ID cannot be empty');
    }

    if (params.userId.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }

    return await repository.toggleItemCompletion(
      itemId: params.itemId,
      isCompleted: params.isCompleted,
      userId: params.userId,
    );
  }
}

/// Use case to delete a checklist item
class DeleteChecklistItemUseCase {
  final ChecklistRepository repository;

  DeleteChecklistItemUseCase(this.repository);

  Future<void> call(String itemId) async {
    if (itemId.isEmpty) {
      throw ArgumentError('Item ID cannot be empty');
    }

    return await repository.deleteChecklistItem(itemId);
  }
}
