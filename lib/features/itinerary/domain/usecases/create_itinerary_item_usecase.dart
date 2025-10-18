import '../../../../shared/models/itinerary_model.dart';
import '../repositories/itinerary_repository.dart';

/// Use case for creating an itinerary item
class CreateItineraryItemUseCase {
  final ItineraryRepository repository;

  CreateItineraryItemUseCase(this.repository);

  Future<ItineraryItemModel> call({
    required String tripId,
    required String title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int? orderIndex,
  }) async {
    // Validation
    if (title.trim().isEmpty) {
      throw Exception('Title is required');
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

    return await repository.createItineraryItem(
      tripId: tripId,
      title: title.trim(),
      description: description?.trim(),
      location: location?.trim(),
      startTime: startTime,
      endTime: endTime,
      dayNumber: dayNumber,
      orderIndex: orderIndex ?? 0,
    );
  }
}
