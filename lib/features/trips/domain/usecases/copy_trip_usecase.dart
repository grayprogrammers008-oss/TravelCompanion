import '../repositories/trip_repository.dart';

/// Use case for copying a trip with optional itinerary and checklists
class CopyTripUseCase {
  final TripRepository _repository;

  CopyTripUseCase(this._repository);

  /// Copy a trip and return the new trip ID
  ///
  /// Parameters:
  /// - [sourceTripId]: The ID of the trip to copy
  /// - [newName]: Name for the new trip
  /// - [newStartDate]: Start date for the new trip
  /// - [newEndDate]: End date for the new trip
  /// - [copyItinerary]: Whether to copy itinerary items (default: true)
  /// - [copyChecklists]: Whether to copy checklists and items (default: true)
  ///
  /// Returns the ID of the newly created trip
  Future<String> call({
    required String sourceTripId,
    required String newName,
    required DateTime newStartDate,
    required DateTime newEndDate,
    bool copyItinerary = true,
    bool copyChecklists = true,
  }) async {
    return await _repository.copyTrip(
      sourceTripId: sourceTripId,
      newName: newName,
      newStartDate: newStartDate,
      newEndDate: newEndDate,
      copyItinerary: copyItinerary,
      copyChecklists: copyChecklists,
    );
  }
}
