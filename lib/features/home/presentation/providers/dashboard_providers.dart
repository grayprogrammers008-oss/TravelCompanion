import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/trip_model.dart';
import '../../../trips/presentation/providers/trip_providers.dart';

/// Provider that returns the currently active trip
/// An active trip is either:
/// 1. A trip that has started but not ended (in progress)
/// 2. The next upcoming trip (if no trip is in progress)
///
/// Priority: In-progress trip > Upcoming trip (closest start date)
final activeTripProvider = FutureProvider<TripWithMembers?>((ref) async {
  final tripsAsync = ref.watch(userTripsProvider);

  return tripsAsync.when(
    data: (trips) {
      if (trips.isEmpty) return null;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Find trips that are currently in progress
      final inProgressTrips = trips.where((t) {
        final trip = t.trip;
        if (trip.isCompleted) return false;
        if (trip.startDate == null) return false;

        final startDate = DateTime(
          trip.startDate!.year,
          trip.startDate!.month,
          trip.startDate!.day,
        );

        // Check if trip has started
        if (startDate.isAfter(today)) return false;

        // Check if trip hasn't ended yet (or has no end date)
        if (trip.endDate != null) {
          final endDate = DateTime(
            trip.endDate!.year,
            trip.endDate!.month,
            trip.endDate!.day,
          );
          if (endDate.isBefore(today)) return false;
        }

        return true;
      }).toList();

      // Return first in-progress trip (could sort by start date if needed)
      if (inProgressTrips.isNotEmpty) {
        return inProgressTrips.first;
      }

      // Find upcoming trips (start date in the future)
      final upcomingTrips = trips.where((t) {
        final trip = t.trip;
        if (trip.isCompleted) return false;
        if (trip.startDate == null) return false;

        final startDate = DateTime(
          trip.startDate!.year,
          trip.startDate!.month,
          trip.startDate!.day,
        );

        return startDate.isAfter(today);
      }).toList();

      // Sort by start date and return closest
      if (upcomingTrips.isNotEmpty) {
        upcomingTrips.sort((a, b) =>
          a.trip.startDate!.compareTo(b.trip.startDate!)
        );
        return upcomingTrips.first;
      }

      // No in-progress or upcoming trips, return the most recent non-completed trip
      final activeTrips = trips.where((t) => !t.trip.isCompleted).toList();
      if (activeTrips.isNotEmpty) {
        // Sort by created date, most recent first
        activeTrips.sort((a, b) {
          final aDate = a.trip.createdAt ?? DateTime(1970);
          final bDate = b.trip.createdAt ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });
        return activeTrips.first;
      }

      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider that returns dashboard statistics
class DashboardStats {
  final int totalTrips;
  final int activeTrips;
  final int upcomingTrips;
  final int completedTrips;
  final double totalExpenses;

  DashboardStats({
    required this.totalTrips,
    required this.activeTrips,
    required this.upcomingTrips,
    required this.completedTrips,
    required this.totalExpenses,
  });
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final tripsAsync = ref.watch(userTripsProvider);

  return tripsAsync.when(
    data: (trips) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int activeCount = 0;
      int upcomingCount = 0;
      int completedCount = 0;

      for (final t in trips) {
        final trip = t.trip;

        if (trip.isCompleted) {
          completedCount++;
          continue;
        }

        if (trip.startDate == null) {
          activeCount++; // Trips without dates are considered active
          continue;
        }

        final startDate = DateTime(
          trip.startDate!.year,
          trip.startDate!.month,
          trip.startDate!.day,
        );

        if (startDate.isAfter(today)) {
          upcomingCount++;
        } else {
          activeCount++;
        }
      }

      return DashboardStats(
        totalTrips: trips.length,
        activeTrips: activeCount,
        upcomingTrips: upcomingCount,
        completedTrips: completedCount,
        totalExpenses: 0, // Would need to aggregate from expenses provider
      );
    },
    loading: () => DashboardStats(
      totalTrips: 0,
      activeTrips: 0,
      upcomingTrips: 0,
      completedTrips: 0,
      totalExpenses: 0,
    ),
    error: (_, __) => DashboardStats(
      totalTrips: 0,
      activeTrips: 0,
      upcomingTrips: 0,
      completedTrips: 0,
      totalExpenses: 0,
    ),
  );
});
