import '../../../../shared/models/trip_model.dart';
import '../repositories/trip_repository.dart';

/// Use case for getting user trips
class GetUserTripsUseCase {
  final TripRepository _repository;

  GetUserTripsUseCase(this._repository);

  Future<List<TripWithMembers>> call() async {
    return await _repository.getUserTrips();
  }
}
