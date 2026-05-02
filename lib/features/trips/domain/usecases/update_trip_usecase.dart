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
    double? cost,
    String? currency,
    bool? isPublic,
  }) async {
    // Validation
    if (tripId.trim().isEmpty) {
      throw Exception('Trip ID is required');
    }

    final trimmedName = name?.trim();

    // Validate trip name if provided
    if (trimmedName != null && trimmedName.isEmpty) {
      throw Exception('Trip name cannot be empty');
    }

    // Validate date range if both dates are provided
    if (startDate != null && endDate != null) {
      if (endDate.isBefore(startDate)) {
        throw Exception('End date must be after or equal to start date');
      }
    }

    // Cost validation
    if (cost != null && cost < 0) {
      throw Exception('Cost must be a positive number');
    }

    return await _repository.updateTrip(
      tripId: tripId,
      name: trimmedName,
      description: description,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      coverImageUrl: coverImageUrl,
      cost: cost,
      currency: currency,
      isPublic: isPublic,
    );
  }
}
