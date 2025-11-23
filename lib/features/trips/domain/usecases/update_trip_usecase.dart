import '../../../../shared/models/trip_model.dart';
import '../repositories/trip_repository.dart';

/// Update an existing trip
class UpdateTripUseCase {
  final TripRepository _repository;

  UpdateTripUseCase(this._repository);

  Future<TripModel> call({
    required String tripId,
    String? name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
    double? budget,
    String? currency,
  }) async {
    // Validation
    if (tripId.trim().isEmpty) {
      throw Exception('Trip ID is required');
    }

    // Validate trip name if provided
    if (name != null && name.trim().isEmpty) {
      throw Exception('Trip name cannot be empty');
    }

    // Validate date range if both dates are provided
    if (startDate != null && endDate != null) {
      if (endDate.isBefore(startDate)) {
        throw Exception('End date must be after or equal to start date');
      }
    }

    // Budget validation
    if (budget != null && budget < 0) {
      throw Exception('Budget must be a positive number');
    }

    return await _repository.updateTrip(
      tripId: tripId,
      name: name,
      description: description,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      coverImageUrl: coverImageUrl,
      budget: budget,
      currency: currency,
    );
  }
}
