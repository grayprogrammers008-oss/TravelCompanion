import 'package:travel_crew/shared/models/trip_model.dart';

/// Use case for searching trips by query text
/// Searches across trip name, description, and destination
class SearchTripsUseCase {
  /// Search trips by query text
  ///
  /// Searches in:
  /// - Trip name (case-insensitive)
  /// - Trip description (case-insensitive)
  /// - Trip destination (case-insensitive)
  ///
  /// Returns list of trips that match the query
  /// If query is empty or null, returns all trips
  List<TripWithMembers> call({
    required List<TripWithMembers> trips,
    required String? query,
  }) {
    // If query is empty or null, return all trips
    if (query == null || query.trim().isEmpty) {
      return trips;
    }

    final lowerQuery = query.toLowerCase().trim();

    return trips.where((tripWithMembers) {
      final trip = tripWithMembers.trip;

      // Search in trip name
      if (trip.name.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // Search in trip description
      if (trip.description?.toLowerCase().contains(lowerQuery) ?? false) {
        return true;
      }

      // Search in trip destination
      if (trip.destination?.toLowerCase().contains(lowerQuery) ?? false) {
        return true;
      }

      return false;
    }).toList();
  }
}
