import '../../../../shared/models/trip_model.dart';
import '../repositories/trip_repository.dart';

/// Use case for updating a trip
class UpdateTripUseCase {
  final TripRepository repository;

  UpdateTripUseCase(this.repository);

  /// Update a trip with validation
  ///
  /// Validates:
  /// - Trip name is not empty
  /// - Start date is before end date (if both provided)
  /// - Trip ID exists
  ///
  /// Returns the updated [TripModel]
  /// Throws [Exception] if validation fails or update fails
  Future<TripModel> call({
    required String tripId,
    String? name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
  }) async {
    // Validation: Trip ID is required
    if (tripId.trim().isEmpty) {
      throw Exception('Trip ID is required');
    }

    // Validation: Name should not be empty if provided
    if (name != null && name.trim().isEmpty) {
      throw Exception('Trip name cannot be empty');
    }

    // Validation: Start date must be before end date
    if (startDate != null && endDate != null) {
      if (startDate.isAfter(endDate)) {
        throw Exception('Start date must be before end date');
      }
    }

    try {
      return await repository.updateTrip(
        tripId: tripId,
        name: name,
        description: description,
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        coverImageUrl: coverImageUrl,
      );
    } catch (e) {
      throw Exception('Failed to update trip: $e');
    }
  }
}
