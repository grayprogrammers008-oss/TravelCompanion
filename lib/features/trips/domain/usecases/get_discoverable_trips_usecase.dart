import '../../../../shared/models/trip_model.dart';
import '../repositories/trip_repository.dart';

/// Use case for getting public trips that the user can discover and join
class GetDiscoverableTripsUseCase {
  final TripRepository _repository;

  GetDiscoverableTripsUseCase(this._repository);

  /// Get list of public trips that the current user can join
  /// Returns trips that are:
  /// - Public (is_public = true)
  /// - Not already joined by the current user
  Future<List<TripWithMembers>> call() async {
    try {
      return await _repository.getDiscoverableTrips();
    } catch (e) {
      throw Exception('Failed to get discoverable trips: $e');
    }
  }
}
