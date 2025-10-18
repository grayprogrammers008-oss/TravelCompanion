import '../repositories/itinerary_repository.dart';

/// Use case for reordering itinerary items within a day
class ReorderItemsUseCase {
  final ItineraryRepository repository;

  ReorderItemsUseCase(this.repository);

  Future<void> call({
    required String tripId,
    required int dayNumber,
    required List<String> itemIds,
  }) async {
    if (tripId.trim().isEmpty) {
      throw Exception('Trip ID is required');
    }

    if (dayNumber <= 0) {
      throw Exception('Day number must be positive');
    }

    if (itemIds.isEmpty) {
      throw Exception('Item IDs cannot be empty');
    }

    return await repository.reorderItems(
      tripId: tripId,
      dayNumber: dayNumber,
      itemIds: itemIds,
    );
  }
}
