import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';

/// Travel statistics data class
class TravelStatistics {
  // Trip statistics
  final int totalTrips;
  final int activeTrips;
  final int upcomingTrips;
  final int completedTrips;
  final int totalDaysTraveled;
  final int uniqueDestinations;
  final int uniqueCrewMembers;

  // Expense statistics
  final double totalExpenses;
  final int expenseCount;
  final int tripsWithExpenses;
  final double averageExpensePerTrip;
  final String primaryCurrency;

  // Rating statistics
  final double averageRating;
  final int ratedTrips;

  // Activity statistics
  final int checklistItemsCompleted;
  final int itineraryItemsPlanned;

  const TravelStatistics({
    this.totalTrips = 0,
    this.activeTrips = 0,
    this.upcomingTrips = 0,
    this.completedTrips = 0,
    this.totalDaysTraveled = 0,
    this.uniqueDestinations = 0,
    this.uniqueCrewMembers = 0,
    this.totalExpenses = 0.0,
    this.expenseCount = 0,
    this.tripsWithExpenses = 0,
    this.averageExpensePerTrip = 0.0,
    this.primaryCurrency = 'INR',
    this.averageRating = 0.0,
    this.ratedTrips = 0,
    this.checklistItemsCompleted = 0,
    this.itineraryItemsPlanned = 0,
  });

  /// Check if user has any rated trips
  bool get hasRatedTrips => ratedTrips > 0;

  /// Check if user has any trips
  bool get hasTrips => totalTrips > 0;

  /// Check if user has any expenses
  bool get hasExpenses => expenseCount > 0;

  TravelStatistics copyWith({
    int? totalTrips,
    int? activeTrips,
    int? upcomingTrips,
    int? completedTrips,
    int? totalDaysTraveled,
    int? uniqueDestinations,
    int? uniqueCrewMembers,
    double? totalExpenses,
    int? expenseCount,
    int? tripsWithExpenses,
    double? averageExpensePerTrip,
    String? primaryCurrency,
    double? averageRating,
    int? ratedTrips,
    int? checklistItemsCompleted,
    int? itineraryItemsPlanned,
  }) {
    return TravelStatistics(
      totalTrips: totalTrips ?? this.totalTrips,
      activeTrips: activeTrips ?? this.activeTrips,
      upcomingTrips: upcomingTrips ?? this.upcomingTrips,
      completedTrips: completedTrips ?? this.completedTrips,
      totalDaysTraveled: totalDaysTraveled ?? this.totalDaysTraveled,
      uniqueDestinations: uniqueDestinations ?? this.uniqueDestinations,
      uniqueCrewMembers: uniqueCrewMembers ?? this.uniqueCrewMembers,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      expenseCount: expenseCount ?? this.expenseCount,
      tripsWithExpenses: tripsWithExpenses ?? this.tripsWithExpenses,
      averageExpensePerTrip: averageExpensePerTrip ?? this.averageExpensePerTrip,
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
      averageRating: averageRating ?? this.averageRating,
      ratedTrips: ratedTrips ?? this.ratedTrips,
      checklistItemsCompleted: checklistItemsCompleted ?? this.checklistItemsCompleted,
      itineraryItemsPlanned: itineraryItemsPlanned ?? this.itineraryItemsPlanned,
    );
  }
}

/// Provider for travel statistics
/// Aggregates data from trips, expenses, and other sources
final travelStatisticsProvider = StreamProvider<TravelStatistics>((ref) async* {
  // Watch trips stream
  final tripsAsync = ref.watch(userTripsProvider);

  // Process trips data when available
  await for (final _ in Stream.periodic(const Duration(milliseconds: 100))) {
    if (tripsAsync.hasValue) {
      final trips = tripsAsync.value!;

      // Calculate trip statistics
      final now = DateTime.now();
      int activeTrips = 0;
      int upcomingTrips = 0;
      int completedTrips = 0;
      int totalDays = 0;
      final destinations = <String>{};
      final crewMembers = <String>{};
      double totalRating = 0;
      int ratedCount = 0;

      for (final tripWithMembers in trips) {
        final trip = tripWithMembers.trip;

        // Count trip status
        if (trip.isCompleted) {
          completedTrips++;
        } else if (trip.startDate != null && trip.endDate != null) {
          if (now.isAfter(trip.startDate!) && now.isBefore(trip.endDate!)) {
            activeTrips++;
          } else if (now.isBefore(trip.startDate!)) {
            upcomingTrips++;
          } else {
            activeTrips++; // Past but not completed
          }
        } else {
          activeTrips++;
        }

        // Calculate days traveled
        if (trip.startDate != null && trip.endDate != null) {
          totalDays += trip.endDate!.difference(trip.startDate!).inDays + 1;
        }

        // Track unique destinations
        if (trip.destination != null && trip.destination!.isNotEmpty) {
          destinations.add(trip.destination!.toLowerCase().trim());
        }

        // Track unique crew members
        for (final member in tripWithMembers.members) {
          crewMembers.add(member.userId);
        }

        // Track ratings
        if (trip.rating > 0) {
          totalRating += trip.rating;
          ratedCount++;
        }
      }

      // Calculate average rating
      final avgRating = ratedCount > 0 ? totalRating / ratedCount : 0.0;

      // Get expense statistics
      double totalExpenses = 0.0;
      int expenseCount = 0;
      final tripsWithExpenseIds = <String>{};

      try {
        final expensesAsync = ref.read(userExpensesProvider);
        if (expensesAsync.hasValue) {
          final expenses = expensesAsync.value!;
          for (final expense in expenses) {
            totalExpenses += expense.expense.amount;
            expenseCount++;
            if (expense.expense.tripId != null) {
              tripsWithExpenseIds.add(expense.expense.tripId!);
            }
          }
        }
      } catch (e) {
        // Expenses not available, use defaults
      }

      // Calculate average expense per trip
      final avgExpensePerTrip = tripsWithExpenseIds.isNotEmpty
          ? totalExpenses / tripsWithExpenseIds.length
          : 0.0;

      yield TravelStatistics(
        totalTrips: trips.length,
        activeTrips: activeTrips,
        upcomingTrips: upcomingTrips,
        completedTrips: completedTrips,
        totalDaysTraveled: totalDays,
        uniqueDestinations: destinations.length,
        uniqueCrewMembers: crewMembers.length,
        totalExpenses: totalExpenses,
        expenseCount: expenseCount,
        tripsWithExpenses: tripsWithExpenseIds.length,
        averageExpensePerTrip: avgExpensePerTrip,
        primaryCurrency: 'INR',
        averageRating: avgRating,
        ratedTrips: ratedCount,
        checklistItemsCompleted: 0, // TODO: Add checklist stats
        itineraryItemsPlanned: 0, // TODO: Add itinerary stats
      );

      // Only emit once, then exit
      return;
    }
  }
});

/// Provider for simplified user stats (for quick access)
final quickStatsProvider = Provider<TravelStatistics>((ref) {
  final statsAsync = ref.watch(travelStatisticsProvider);
  return statsAsync.value ?? const TravelStatistics();
});
