import '../../../../shared/models/trip_model.dart';
import '../repositories/trip_repository.dart';

/// Use case for getting a specific trip
class GetTripUseCase {
  final TripRepository _repository;

  GetTripUseCase(this._repository);

  Future<TripWithMembers> call(String tripId) async {
    if (tripId.isEmpty) {
      throw Exception('Trip ID is required');
    }

    return await _repository.getTripById(tripId);
  }
}
