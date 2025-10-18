import '../../../../shared/models/itinerary_model.dart';
import '../repositories/itinerary_repository.dart';

/// Use case for getting itinerary items grouped by days
class GetItineraryByDaysUseCase {
  final ItineraryRepository repository;

  GetItineraryByDaysUseCase(this.repository);

  Future<List<ItineraryDay>> call(String tripId) async {
    // Validate trip ID
    if (tripId.trim().isEmpty) {
      throw Exception('Trip ID is required');
    }

    try {
      return await repository.getItineraryByDays(tripId);
    } catch (e) {
      throw Exception('Failed to get itinerary by days: $e');
    }
  }
}
