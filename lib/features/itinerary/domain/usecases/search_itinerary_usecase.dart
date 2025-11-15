import 'package:travel_crew/shared/models/itinerary_model.dart';

/// Use case for searching itinerary items by query text
/// Searches across itinerary item title, description, and location
class SearchItineraryUseCase {
  /// Search itinerary items by query text
  ///
  /// Searches in:
  /// - Itinerary item title (case-insensitive)
  /// - Itinerary item description (case-insensitive)
  /// - Itinerary item location (case-insensitive)
  ///
  /// Returns list of itinerary items that match the query
  /// If query is empty or null, returns all items
  List<ItineraryItemModel> call({
    required List<ItineraryItemModel> items,
    required String? query,
  }) {
    // If query is empty or null, return all items
    if (query == null || query.trim().isEmpty) {
      return items;
    }

    final lowerQuery = query.toLowerCase().trim();

    return items.where((item) {
      // Search in title
      if (item.title.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // Search in description
      if (item.description?.toLowerCase().contains(lowerQuery) ?? false) {
        return true;
      }

      // Search in location
      if (item.location?.toLowerCase().contains(lowerQuery) ?? false) {
        return true;
      }

      return false;
    }).toList();
  }
}
