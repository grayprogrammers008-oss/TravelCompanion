import '../repositories/itinerary_repository.dart';

/// Use case for deleting an itinerary item
class DeleteItineraryItemUseCase {
  final ItineraryRepository repository;

  DeleteItineraryItemUseCase(this.repository);

  Future<void> call(String itemId) async {
    // Validate item ID
    if (itemId.trim().isEmpty) {
      throw Exception('Item ID is required');
    }

    try {
      return await repository.deleteItineraryItem(itemId);
    } catch (e) {
      throw Exception('Failed to delete itinerary item: $e');
    }
  }
}
