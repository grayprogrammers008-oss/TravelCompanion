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
    // Validate item ID
    if (itemId.trim().isEmpty) {
      throw Exception('Item ID is required');
    }

    // Validate title (if provided)
    String? trimmedTitle;
    if (title != null) {
      trimmedTitle = title.trim();
      if (trimmedTitle.isEmpty) {
        throw Exception('Title cannot be empty');
      }
      if (trimmedTitle.length < 3) {
        throw Exception('Title must be at least 3 characters');
      }
    }

    // Validate times (if both provided)
    if (startTime != null && endTime != null) {
      if (endTime.isBefore(startTime) || endTime.isAtSameMomentAs(startTime)) {
        throw Exception('End time must be after start time');
      }
    }

    // Validate day number (if provided)
    if (dayNumber != null && dayNumber <= 0) {
      throw Exception('Day number must be positive');
    }

    // Validate order index (if provided)
    if (orderIndex != null && orderIndex < 0) {
      throw Exception('Order index cannot be negative');
    }

    // Trim description and location if provided
    final trimmedDescription = description?.trim();
    final trimmedLocation = location?.trim();

    try {
      return await repository.updateItineraryItem(
        itemId: itemId,
        title: trimmedTitle,
        description: trimmedDescription,
        location: trimmedLocation,
        startTime: startTime,
        endTime: endTime,
        dayNumber: dayNumber,
        orderIndex: orderIndex,
      );
    } catch (e) {
      throw Exception('Failed to update itinerary item: $e');
    }
  }
}
