import '../repositories/trip_repository.dart';

/// Use case for joining a public trip
class JoinTripUseCase {
  final TripRepository _repository;

  JoinTripUseCase(this._repository);

  /// Join a trip by its ID
  /// The current user will be added as a member with role 'member'
  ///
  /// Throws:
  /// - Exception if trip ID is invalid
  /// - Exception if trip is not public
  /// - Exception if user is already a member
  /// - Exception if user is not authenticated
  Future<void> call(String tripId) async {
    // Validation
    if (tripId.trim().isEmpty) {
      throw Exception('Trip ID is required');
    }

    try {
      await _repository.joinTrip(tripId);
    } catch (e) {
      throw Exception('Failed to join trip: $e');
    }
  }
}
