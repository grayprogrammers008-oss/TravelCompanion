import '../entities/checklist_entity.dart';
import '../repositories/checklist_repository.dart';

/// Use case to get a checklist with all its items
class GetChecklistWithItemsUseCase {
  final ChecklistRepository repository;

  GetChecklistWithItemsUseCase(this.repository);

  Future<ChecklistWithItemsEntity> call(String checklistId) async {
    if (checklistId.isEmpty) {
      throw ArgumentError('Checklist ID cannot be empty');
    }

    return await repository.getChecklistWithItems(checklistId);
  }
}

/// Use case to watch a checklist with items in real-time
class WatchChecklistWithItemsUseCase {
  final ChecklistRepository repository;

  WatchChecklistWithItemsUseCase(this.repository);

  Stream<ChecklistWithItemsEntity> call(String checklistId) {
    if (checklistId.isEmpty) {
      throw ArgumentError('Checklist ID cannot be empty');
    }

    return repository.watchChecklistWithItems(checklistId);
  }
}
