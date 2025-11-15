import 'package:travel_crew/shared/models/trip_model.dart';

/// Filter criteria for trips
enum TripFilterType {
  all,         // Show all trips
  upcoming,    // Trips that haven't started yet
  ongoing,     // Trips that are currently happening
  past,        // Trips that have ended
  withDates,   // Trips that have both start and end dates
  withoutDates, // Trips without dates
}

/// Sorting options for trips
enum TripSortBy {
  nameAsc,      // Sort by name A-Z
  nameDesc,     // Sort by name Z-A
  dateNewest,   // Newest trips first (by start date)
  dateOldest,   // Oldest trips first (by start date)
  createdNewest, // Recently created first
  createdOldest, // Oldest created first
}

/// Parameters for filtering and sorting trips
class TripFilterParams {
  final TripFilterType filterType;
  final TripSortBy sortBy;
  final DateTime? customStartDate; // Optional: filter trips starting after this date
  final DateTime? customEndDate;   // Optional: filter trips ending before this date

  const TripFilterParams({
    this.filterType = TripFilterType.all,
    this.sortBy = TripSortBy.dateNewest,
    this.customStartDate,
    this.customEndDate,
  });

  TripFilterParams copyWith({
    TripFilterType? filterType,
    TripSortBy? sortBy,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    return TripFilterParams(
      filterType: filterType ?? this.filterType,
      sortBy: sortBy ?? this.sortBy,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
    );
  }
}

/// Use case for filtering and sorting trips
class FilterTripsUseCase {
  /// Filter and sort trips based on provided parameters
  List<TripWithMembers> call({
    required List<TripWithMembers> trips,
    required TripFilterParams params,
  }) {
    // Step 1: Apply filter
    var filteredTrips = _applyFilter(trips, params);

    // Step 2: Apply sorting
    filteredTrips = _applySort(filteredTrips, params.sortBy);

    return filteredTrips;
  }

  List<TripWithMembers> _applyFilter(
    List<TripWithMembers> trips,
    TripFilterParams params,
  ) {
    final now = DateTime.now();

    // Apply type filter
    var filtered = trips.where((tripWithMembers) {
      final trip = tripWithMembers.trip;

      switch (params.filterType) {
        case TripFilterType.all:
          return true;

        case TripFilterType.upcoming:
          // Trips that haven't started yet
          if (trip.startDate == null) return false;
          return trip.startDate!.isAfter(now);

        case TripFilterType.ongoing:
          // Trips currently happening
          if (trip.startDate == null || trip.endDate == null) return false;
          return trip.startDate!.isBefore(now) && trip.endDate!.isAfter(now);

        case TripFilterType.past:
          // Trips that have ended
          if (trip.endDate == null) return false;
          return trip.endDate!.isBefore(now);

        case TripFilterType.withDates:
          // Trips with both start and end dates
          return trip.startDate != null && trip.endDate != null;

        case TripFilterType.withoutDates:
          // Trips missing dates
          return trip.startDate == null || trip.endDate == null;
      }
    }).toList();

    // Apply custom date range filter
    if (params.customStartDate != null) {
      filtered = filtered.where((tripWithMembers) {
        final trip = tripWithMembers.trip;
        if (trip.startDate == null) return false;
        return trip.startDate!.isAfter(params.customStartDate!) ||
            trip.startDate!.isAtSameMomentAs(params.customStartDate!);
      }).toList();
    }

    if (params.customEndDate != null) {
      filtered = filtered.where((tripWithMembers) {
        final trip = tripWithMembers.trip;
        if (trip.endDate == null) return false;
        return trip.endDate!.isBefore(params.customEndDate!) ||
            trip.endDate!.isAtSameMomentAs(params.customEndDate!);
      }).toList();
    }

    return filtered;
  }

  List<TripWithMembers> _applySort(
    List<TripWithMembers> trips,
    TripSortBy sortBy,
  ) {
    final sortedTrips = List<TripWithMembers>.from(trips);

    switch (sortBy) {
      case TripSortBy.nameAsc:
        sortedTrips.sort((a, b) => a.trip.name.compareTo(b.trip.name));
        break;

      case TripSortBy.nameDesc:
        sortedTrips.sort((a, b) => b.trip.name.compareTo(a.trip.name));
        break;

      case TripSortBy.dateNewest:
        sortedTrips.sort((a, b) {
          // Trips without dates go to the end
          if (a.trip.startDate == null && b.trip.startDate == null) return 0;
          if (a.trip.startDate == null) return 1;
          if (b.trip.startDate == null) return -1;
          return b.trip.startDate!.compareTo(a.trip.startDate!);
        });
        break;

      case TripSortBy.dateOldest:
        sortedTrips.sort((a, b) {
          // Trips without dates go to the end
          if (a.trip.startDate == null && b.trip.startDate == null) return 0;
          if (a.trip.startDate == null) return 1;
          if (b.trip.startDate == null) return -1;
          return a.trip.startDate!.compareTo(b.trip.startDate!);
        });
        break;

      case TripSortBy.createdNewest:
        sortedTrips.sort((a, b) {
          if (a.trip.createdAt == null && b.trip.createdAt == null) return 0;
          if (a.trip.createdAt == null) return 1;
          if (b.trip.createdAt == null) return -1;
          return b.trip.createdAt!.compareTo(a.trip.createdAt!);
        });
        break;

      case TripSortBy.createdOldest:
        sortedTrips.sort((a, b) {
          if (a.trip.createdAt == null && b.trip.createdAt == null) return 0;
          if (a.trip.createdAt == null) return 1;
          if (b.trip.createdAt == null) return -1;
          return a.trip.createdAt!.compareTo(b.trip.createdAt!);
        });
        break;
    }

    return sortedTrips;
  }
}
