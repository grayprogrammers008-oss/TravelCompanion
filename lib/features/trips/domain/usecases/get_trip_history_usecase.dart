import '../repositories/trip_repository.dart';
import '../../../../shared/models/trip_model.dart';

/// Use case to get trip history (completed trips only)
///
/// Returns all completed trips for the current user, sorted by completion date (newest first)
/// Each trip includes member information and completion metadata (rating, completedAt)
class GetTripHistoryUseCase {
  final TripRepository repository;

  GetTripHistoryUseCase(this.repository);

  /// Execute the use case to retrieve trip history
  ///
  /// Returns a list of [TripWithMembers] containing only completed trips
  /// Sorted by completion date descending (most recently completed first)
  ///
  /// Throws [Exception] if fetching trips fails
  Future<List<TripWithMembers>> call() async {
    // Get all user trips
    final allTrips = await repository.getUserTrips();

    // Filter for completed trips only
    final completedTrips = allTrips.where((tripWithMembers) {
      return tripWithMembers.trip.isCompleted;
    }).toList();

    // Sort by completion date (newest first)
    completedTrips.sort((a, b) {
      final aDate = a.trip.completedAt;
      final bDate = b.trip.completedAt;

      // Handle null completion dates (shouldn't happen for completed trips, but defensive)
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;  // Trips without completedAt go to end
      if (bDate == null) return -1;

      // Sort newest first
      return bDate.compareTo(aDate);
    });

    return completedTrips;
  }

  /// Get trip history as a stream for real-time updates
  ///
  /// Returns a stream of completed trips list
  /// Updates automatically when trips are completed or trip data changes
  Stream<List<TripWithMembers>> watchHistory() {
    return repository.watchUserTrips().map((allTrips) {
      // Filter for completed trips
      final completedTrips = allTrips.where((tripWithMembers) {
        return tripWithMembers.trip.isCompleted;
      }).toList();

      // Sort by completion date (newest first)
      completedTrips.sort((a, b) {
        final aDate = a.trip.completedAt;
        final bDate = b.trip.completedAt;

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        return bDate.compareTo(aDate);
      });

      return completedTrips;
    });
  }

  /// Get trip history statistics
  ///
  /// Returns statistics about completed trips including:
  /// - Total completed trips count
  /// - Average trip rating
  /// - Total trips with ratings
  /// - Date range of completed trips
  Future<TripHistoryStatistics> getStatistics() async {
    final history = await call();

    if (history.isEmpty) {
      return TripHistoryStatistics.empty();
    }

    // Calculate statistics
    final totalTrips = history.length;

    final tripsWithRatings = history.where((t) => t.trip.rating > 0).toList();
    final totalRatings = tripsWithRatings.length;

    final averageRating = tripsWithRatings.isEmpty
        ? 0.0
        : tripsWithRatings
            .map((t) => t.trip.rating)
            .reduce((a, b) => a + b) / totalRatings;

    // Get earliest and latest completion dates
    final completionDates = history
        .where((t) => t.trip.completedAt != null)
        .map((t) => t.trip.completedAt!)
        .toList();

    final earliestCompletion = completionDates.isEmpty
        ? null
        : completionDates.reduce((a, b) => a.isBefore(b) ? a : b);

    final latestCompletion = completionDates.isEmpty
        ? null
        : completionDates.reduce((a, b) => a.isAfter(b) ? a : b);

    return TripHistoryStatistics(
      totalCompletedTrips: totalTrips,
      averageRating: averageRating,
      totalRatedTrips: totalRatings,
      earliestCompletionDate: earliestCompletion,
      latestCompletionDate: latestCompletion,
    );
  }
}

/// Statistics about trip history
class TripHistoryStatistics {
  final int totalCompletedTrips;
  final double averageRating;
  final int totalRatedTrips;
  final DateTime? earliestCompletionDate;
  final DateTime? latestCompletionDate;

  TripHistoryStatistics({
    required this.totalCompletedTrips,
    required this.averageRating,
    required this.totalRatedTrips,
    this.earliestCompletionDate,
    this.latestCompletionDate,
  });

  factory TripHistoryStatistics.empty() {
    return TripHistoryStatistics(
      totalCompletedTrips: 0,
      averageRating: 0.0,
      totalRatedTrips: 0,
      earliestCompletionDate: null,
      latestCompletionDate: null,
    );
  }

  bool get hasAnyTrips => totalCompletedTrips > 0;
  bool get hasRatedTrips => totalRatedTrips > 0;

  /// Get formatted average rating (e.g., "4.5")
  String get formattedAverageRating => averageRating.toStringAsFixed(1);
}
