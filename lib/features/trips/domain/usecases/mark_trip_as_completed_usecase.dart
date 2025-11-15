import '../../../../shared/models/trip_model.dart';
import '../repositories/trip_repository.dart';

/// Use case for marking a trip as completed
///
/// This marks a trip as completed when the trip is over.
/// Business rules:
/// - Only the trip creator or admins can mark a trip as completed
/// - A trip can be marked as completed even if the end date hasn't passed
/// - Completed trips can be reopened using UnmarkTripAsCompletedUseCase
class MarkTripAsCompletedUseCase {
  final TripRepository _repository;

  MarkTripAsCompletedUseCase(this._repository);

  /// Mark a trip as completed
  ///
  /// Parameters:
  /// - [tripId]: The ID of the trip to mark as completed
  /// - [userId]: The ID of the user performing the action (for authorization)
  ///
  /// Returns the updated [TripModel]
  ///
  /// Throws:
  /// - [UnauthorizedException] if user is not trip creator/admin
  /// - [TripNotFoundException] if trip doesn't exist
  /// - [TripAlreadyCompletedException] if trip is already completed
  Future<TripModel> call({
    required String tripId,
    required String userId,
  }) async {
    // Get the trip with members to check authorization
    final tripWithMembers = await _repository.getTripById(tripId);
    final trip = tripWithMembers.trip;

    // Check if trip is already completed
    if (trip.isCompleted) {
      throw TripAlreadyCompletedException(tripId);
    }

    // Check if user is authorized (creator or admin)
    final isCreator = trip.createdBy == userId;
    final isAdmin = tripWithMembers.members
        .any((member) => member.userId == userId && member.role == 'admin');

    if (!isCreator && !isAdmin) {
      throw UnauthorizedException(
        'Only trip creator or admins can mark trip as completed',
      );
    }

    // Update trip with completion status
    return await _repository.updateTrip(
      tripId: tripId,
      isCompleted: true,
      completedAt: DateTime.now(),
    );
  }
}

/// Exception thrown when user is not authorized to mark trip as completed
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Exception thrown when trip is not found
class TripNotFoundException implements Exception {
  final String tripId;
  TripNotFoundException(this.tripId);

  @override
  String toString() => 'TripNotFoundException: Trip with ID $tripId not found';
}

/// Exception thrown when trying to mark an already completed trip
class TripAlreadyCompletedException implements Exception {
  final String tripId;
  TripAlreadyCompletedException(this.tripId);

  @override
  String toString() =>
      'TripAlreadyCompletedException: Trip with ID $tripId is already completed';
}
