import '../../../../shared/models/itinerary_model.dart';
import '../repositories/itinerary_repository.dart';

/// Use case for updating an itinerary item
class UpdateItineraryItemUseCase {
  final ItineraryRepository repository;

  UpdateItineraryItemUseCase(this.repository);

  Future<ItineraryItemModel> call({
    required String itemId,
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int? orderIndex,
  }) async {
    // Validation
    if (title != null && title.trim().isEmpty) {
      throw Exception('Title cannot be empty');
    }

    if (startTime != null && endTime != null) {
      if (startTime.isAfter(endTime) || startTime.isAtSameMomentAs(endTime)) {
        throw Exception('Start time must be before end time');
      }
    }

    if (dayNumber != null && dayNumber <= 0) {
      throw Exception('Day number must be positive');
    }

    if (orderIndex != null && orderIndex < 0) {
      throw Exception('Order index must be non-negative');
    }

    return await repository.updateItineraryItem(
      itemId: itemId,
      title: title?.trim(),
      description: description?.trim(),
      location: location?.trim(),
      startTime: startTime,
      endTime: endTime,
      dayNumber: dayNumber,
      orderIndex: orderIndex,
    );
  }
}
