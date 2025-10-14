import '../../../../shared/models/trip_model.dart';
import '../repositories/trip_repository.dart';

/// Use case for creating a trip
class CreateTripUseCase {
  final TripRepository _repository;

  CreateTripUseCase(this._repository);

  Future<TripModel> call({
    required String name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
  }) async {
    // Validation
    if (name.trim().isEmpty) {
      throw Exception('Trip name is required');
    }

    if (name.length < 3) {
      throw Exception('Trip name must be at least 3 characters');
    }

    if (startDate != null && endDate != null) {
      if (endDate.isBefore(startDate)) {
        throw Exception('End date must be after start date');
      }
    }

    return await _repository.createTrip(
      name: name.trim(),
      description: description?.trim(),
      destination: destination?.trim(),
      startDate: startDate,
      endDate: endDate,
      coverImageUrl: coverImageUrl,
    );
  }
}
