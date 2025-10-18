import '../../../../shared/models/itinerary_model.dart';
import '../repositories/itinerary_repository.dart';

/// Use case for getting all itinerary items for a trip
class GetTripItineraryUseCase {
  final ItineraryRepository repository;

  GetTripItineraryUseCase(this.repository);

  Future<List<ItineraryItemModel>> call(String tripId) async {
    if (tripId.trim().isEmpty) {
      throw Exception('Trip ID is required');
    }

    return await repository.getTripItinerary(tripId);
  }
}
