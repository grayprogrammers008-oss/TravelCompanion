import '../repositories/itinerary_repository.dart';

/// Use case for deleting an itinerary item
class DeleteItineraryItemUseCase {
  final ItineraryRepository repository;

  DeleteItineraryItemUseCase(this.repository);

  Future<void> call(String itemId) async {
    if (itemId.trim().isEmpty) {
      throw Exception('Item ID is required');
    }

    return await repository.deleteItineraryItem(itemId);
  }
}
