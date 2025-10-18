import '../../../../shared/models/itinerary_model.dart';
import '../repositories/itinerary_repository.dart';

/// Use case for getting itinerary items grouped by days
class GetItineraryByDaysUseCase {
  final ItineraryRepository repository;

  GetItineraryByDaysUseCase(this.repository);

  Future<List<ItineraryDay>> call(String tripId) async {
    if (tripId.trim().isEmpty) {
      throw Exception('Trip ID is required');
    }

    return await repository.getItineraryByDays(tripId);
  }
}
