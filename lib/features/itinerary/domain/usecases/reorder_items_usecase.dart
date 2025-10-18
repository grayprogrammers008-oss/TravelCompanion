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
    // Validate trip ID
    if (tripId.trim().isEmpty) {
      throw Exception('Trip ID is required');
    }

    // Validate day number
    if (dayNumber <= 0) {
      throw Exception('Day number must be positive');
    }

    // Validate item IDs
    if (itemIds.isEmpty) {
      throw Exception('Item IDs cannot be empty');
    }

    // Validate all item IDs are not empty
    for (final id in itemIds) {
      if (id.trim().isEmpty) {
        throw Exception('Item ID cannot be empty');
      }
    }

    try {
      return await repository.reorderItems(
        tripId: tripId,
        dayNumber: dayNumber,
        itemIds: itemIds,
      );
    } catch (e) {
      throw Exception('Failed to reorder items: $e');
    }
  }
}
