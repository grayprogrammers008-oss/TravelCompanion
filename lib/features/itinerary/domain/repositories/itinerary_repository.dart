import '../../../../shared/models/itinerary_model.dart';

/// Abstract repository for itinerary operations
abstract class ItineraryRepository {
  /// Create a new itinerary item
  Future<ItineraryItemModel> createItineraryItem({
    required String tripId,
    required String title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? placeId,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int orderIndex = 0,
  });

  /// Get all itinerary items for a trip
  Future<List<ItineraryItemModel>> getTripItinerary(String tripId);

  /// Get itinerary items for a specific day
  Future<List<ItineraryItemModel>> getDayItinerary({
    required String tripId,
    required int dayNumber,
  });

  /// Get itinerary grouped by days
  Future<List<ItineraryDay>> getItineraryByDays(String tripId);

  /// Get a single itinerary item by ID
  Future<ItineraryItemModel> getItineraryItem(String itemId);

  /// Update an itinerary item
  Future<ItineraryItemModel> updateItineraryItem({
    required String itemId,
    String? title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? placeId,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int? orderIndex,
  });

  /// Delete an itinerary item
  Future<void> deleteItineraryItem(String itemId);

  /// Reorder items within a day
  Future<void> reorderItems({
    required String tripId,
    required int dayNumber,
    required List<String> itemIds,
  });

  /// Move item to different day
  Future<void> moveItemToDay({
    required String itemId,
    required int newDayNumber,
  });

  /// Watch trip itinerary in real-time
  Stream<List<ItineraryItemModel>> watchTripItinerary(String tripId);

  /// Watch itinerary by days in real-time
  Stream<List<ItineraryDay>> watchItineraryByDays(String tripId);
}
