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
    // Validate trip ID
    if (tripId.trim().isEmpty) {
      throw Exception('Trip ID is required');
    }

    // Validate title
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw Exception('Title is required');
    }
    if (trimmedTitle.length < 3) {
      throw Exception('Title must be at least 3 characters');
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

    // Validate order index
    if (orderIndex != null && orderIndex < 0) {
      throw Exception('Order index cannot be negative');
    }

    // Trim description and location if provided
    final trimmedDescription = description?.trim();
    final trimmedLocation = location?.trim();

    try {
      return await repository.createItineraryItem(
        tripId: tripId,
        title: trimmedTitle,
        description: trimmedDescription,
        location: trimmedLocation,
        startTime: startTime,
        endTime: endTime,
        dayNumber: dayNumber,
        orderIndex: orderIndex ?? 0,
      );
    } catch (e) {
      throw Exception('Failed to create itinerary item: $e');
    }
  }
}
