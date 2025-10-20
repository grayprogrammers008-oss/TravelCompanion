import '../entities/checklist_entity.dart';
import '../repositories/checklist_repository.dart';

/// Use case to get all checklists for a trip
class GetTripChecklistsUseCase {
  final ChecklistRepository repository;

  GetTripChecklistsUseCase(this.repository);

  Future<List<ChecklistEntity>> call(String tripId) async {
    if (tripId.isEmpty) {
      throw ArgumentError('Trip ID cannot be empty');
    }

    return await repository.getTripChecklists(tripId);
  }
}

/// Use case to watch checklists in real-time
class WatchTripChecklistsUseCase {
  final ChecklistRepository repository;

  WatchTripChecklistsUseCase(this.repository);

  Stream<List<ChecklistEntity>> call(String tripId) {
    if (tripId.isEmpty) {
      throw ArgumentError('Trip ID cannot be empty');
    }

    return repository.watchTripChecklists(tripId);
  }
}
