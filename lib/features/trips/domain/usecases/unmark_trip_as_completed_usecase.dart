import '../../../../shared/models/trip_model.dart';
import '../repositories/trip_repository.dart';
import 'mark_trip_as_completed_usecase.dart';

/// Use case for unmarking a trip as completed (reopening a trip)
///
/// This reopens a completed trip, allowing modifications again.
/// Business rules:
/// - Only the trip creator or admins can reopen a trip
/// - Only completed trips can be reopened
class UnmarkTripAsCompletedUseCase {
  final TripRepository _repository;

  UnmarkTripAsCompletedUseCase(this._repository);

  /// Unmark a trip as completed (reopen it)
  ///
  /// Parameters:
  /// - [tripId]: The ID of the trip to reopen
  /// - [userId]: The ID of the user performing the action (for authorization)
  ///
  /// Returns the updated [TripModel]
  ///
  /// Throws:
  /// - [UnauthorizedException] if user is not trip creator/admin
  /// - [TripNotFoundException] if trip doesn't exist
  /// - [TripNotCompletedException] if trip is not completed
  Future<TripModel> call({
    required String tripId,
    required String userId,
  }) async {
    // Get the trip with members to check authorization
    final tripWithMembers = await _repository.getTripById(tripId);
    final trip = tripWithMembers.trip;

    // Check if trip is not completed
    if (!trip.isCompleted) {
      throw TripNotCompletedException(tripId);
    }

    // Check if user is authorized (creator or admin)
    final isCreator = trip.createdBy == userId;
    final isAdmin = tripWithMembers.members
        .any((member) => member.userId == userId && member.role == 'admin');

    if (!isCreator && !isAdmin) {
      throw UnauthorizedException(
        'Only trip creator or admins can reopen trip',
      );
    }

    // Update trip to remove completion status
    return await _repository.updateTrip(
      tripId: tripId,
      isCompleted: false,
      completedAt: null,
    );
  }
}

/// Exception thrown when trying to reopen a trip that is not completed
class TripNotCompletedException implements Exception {
  final String tripId;
  TripNotCompletedException(this.tripId);

  @override
  String toString() =>
      'TripNotCompletedException: Trip with ID $tripId is not completed';
}
