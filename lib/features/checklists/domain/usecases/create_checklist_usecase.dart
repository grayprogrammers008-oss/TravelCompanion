import '../entities/checklist_entity.dart';
import '../repositories/checklist_repository.dart';

/// Input parameters for creating a checklist
class CreateChecklistParams {
  final String tripId;
  final String name;
  final String createdBy;

  const CreateChecklistParams({
    required this.tripId,
    required this.name,
    required this.createdBy,
  });
}

/// Use case to create a new checklist
class CreateChecklistUseCase {
  final ChecklistRepository repository;

  CreateChecklistUseCase(this.repository);

  Future<ChecklistEntity> call(CreateChecklistParams params) async {
    // Validation
    if (params.tripId.isEmpty) {
      throw ArgumentError('Trip ID cannot be empty');
    }

    if (params.name.trim().isEmpty) {
      throw ArgumentError('Checklist name cannot be empty');
    }

    if (params.name.length > 100) {
      throw ArgumentError('Checklist name cannot exceed 100 characters');
    }

    if (params.createdBy.isEmpty) {
      throw ArgumentError('Creator ID cannot be empty');
    }

    return await repository.createChecklist(
      tripId: params.tripId,
      name: params.name.trim(),
      createdBy: params.createdBy,
    );
  }
}
