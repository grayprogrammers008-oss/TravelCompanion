import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/statistics/presentation/providers/statistics_providers.dart';

void main() {
  group('TravelStatistics', () {
    test('should create with default values', () {
      const stats = TravelStatistics();

      expect(stats.totalTrips, 0);
      expect(stats.activeTrips, 0);
      expect(stats.upcomingTrips, 0);
      expect(stats.completedTrips, 0);
      expect(stats.totalDaysTraveled, 0);
      expect(stats.uniqueDestinations, 0);
      expect(stats.uniqueCrewMembers, 0);
      expect(stats.totalExpenses, 0.0);
      expect(stats.expenseCount, 0);
      expect(stats.tripsWithExpenses, 0);
      expect(stats.averageExpensePerTrip, 0.0);
      expect(stats.primaryCurrency, 'INR');
      expect(stats.averageRating, 0.0);
      expect(stats.ratedTrips, 0);
      expect(stats.checklistItemsCompleted, 0);
      expect(stats.itineraryItemsPlanned, 0);
    });

    test('should create with custom values', () {
      const stats = TravelStatistics(
        totalTrips: 10,
        activeTrips: 2,
        upcomingTrips: 3,
        completedTrips: 5,
        totalDaysTraveled: 45,
        uniqueDestinations: 8,
        uniqueCrewMembers: 15,
        totalExpenses: 50000.0,
        expenseCount: 100,
        tripsWithExpenses: 7,
        averageExpensePerTrip: 7142.86,
        primaryCurrency: 'USD',
        averageRating: 4.5,
        ratedTrips: 4,
        checklistItemsCompleted: 50,
        itineraryItemsPlanned: 30,
      );

      expect(stats.totalTrips, 10);
      expect(stats.activeTrips, 2);
      expect(stats.upcomingTrips, 3);
      expect(stats.completedTrips, 5);
      expect(stats.totalDaysTraveled, 45);
      expect(stats.uniqueDestinations, 8);
      expect(stats.uniqueCrewMembers, 15);
      expect(stats.totalExpenses, 50000.0);
      expect(stats.expenseCount, 100);
      expect(stats.tripsWithExpenses, 7);
      expect(stats.averageExpensePerTrip, 7142.86);
      expect(stats.primaryCurrency, 'USD');
      expect(stats.averageRating, 4.5);
      expect(stats.ratedTrips, 4);
      expect(stats.checklistItemsCompleted, 50);
      expect(stats.itineraryItemsPlanned, 30);
    });

    group('computed properties', () {
      test('hasRatedTrips should return true when ratedTrips > 0', () {
        const stats = TravelStatistics(ratedTrips: 5);
        expect(stats.hasRatedTrips, true);
      });

      test('hasRatedTrips should return false when ratedTrips is 0', () {
        const stats = TravelStatistics(ratedTrips: 0);
        expect(stats.hasRatedTrips, false);
      });

      test('hasTrips should return true when totalTrips > 0', () {
        const stats = TravelStatistics(totalTrips: 3);
        expect(stats.hasTrips, true);
      });

      test('hasTrips should return false when totalTrips is 0', () {
        const stats = TravelStatistics(totalTrips: 0);
        expect(stats.hasTrips, false);
      });

      test('hasExpenses should return true when expenseCount > 0', () {
        const stats = TravelStatistics(expenseCount: 10);
        expect(stats.hasExpenses, true);
      });

      test('hasExpenses should return false when expenseCount is 0', () {
        const stats = TravelStatistics(expenseCount: 0);
        expect(stats.hasExpenses, false);
      });
    });

    group('copyWith', () {
      test('should copy with new totalTrips', () {
        const original = TravelStatistics(totalTrips: 5);
        final copied = original.copyWith(totalTrips: 10);

        expect(copied.totalTrips, 10);
        expect(original.totalTrips, 5); // Original unchanged
      });

      test('should copy with new totalExpenses', () {
        const original = TravelStatistics(totalExpenses: 1000.0);
        final copied = original.copyWith(totalExpenses: 5000.0);

        expect(copied.totalExpenses, 5000.0);
        expect(original.totalExpenses, 1000.0);
      });

      test('should copy with new averageRating', () {
        const original = TravelStatistics(averageRating: 3.5);
        final copied = original.copyWith(averageRating: 4.8);

        expect(copied.averageRating, 4.8);
        expect(original.averageRating, 3.5);
      });

      test('should preserve other values when copying single field', () {
        const original = TravelStatistics(
          totalTrips: 10,
          activeTrips: 2,
          completedTrips: 8,
          totalExpenses: 50000.0,
        );

        final copied = original.copyWith(totalTrips: 15);

        expect(copied.totalTrips, 15);
        expect(copied.activeTrips, 2);
        expect(copied.completedTrips, 8);
        expect(copied.totalExpenses, 50000.0);
      });

      test('should copy with multiple values at once', () {
        const original = TravelStatistics();
        final copied = original.copyWith(
          totalTrips: 20,
          activeTrips: 5,
          upcomingTrips: 3,
          completedTrips: 12,
          primaryCurrency: 'EUR',
        );

        expect(copied.totalTrips, 20);
        expect(copied.activeTrips, 5);
        expect(copied.upcomingTrips, 3);
        expect(copied.completedTrips, 12);
        expect(copied.primaryCurrency, 'EUR');
      });
    });

    group('edge cases', () {
      test('should handle zero values correctly', () {
        const stats = TravelStatistics(
          totalTrips: 0,
          totalExpenses: 0.0,
          averageRating: 0.0,
        );

        expect(stats.hasTrips, false);
        expect(stats.hasExpenses, false);
        expect(stats.hasRatedTrips, false);
      });

      test('should handle large values', () {
        const stats = TravelStatistics(
          totalTrips: 1000,
          totalExpenses: 10000000.0,
          totalDaysTraveled: 5000,
          uniqueDestinations: 200,
        );

        expect(stats.totalTrips, 1000);
        expect(stats.totalExpenses, 10000000.0);
        expect(stats.totalDaysTraveled, 5000);
        expect(stats.uniqueDestinations, 200);
      });

      test('should handle decimal expense values', () {
        const stats = TravelStatistics(
          totalExpenses: 12345.67,
          averageExpensePerTrip: 1234.567,
        );

        expect(stats.totalExpenses, 12345.67);
        expect(stats.averageExpensePerTrip, 1234.567);
      });

      test('should handle different currency codes', () {
        const inrStats = TravelStatistics(primaryCurrency: 'INR');
        const usdStats = TravelStatistics(primaryCurrency: 'USD');
        const eurStats = TravelStatistics(primaryCurrency: 'EUR');

        expect(inrStats.primaryCurrency, 'INR');
        expect(usdStats.primaryCurrency, 'USD');
        expect(eurStats.primaryCurrency, 'EUR');
      });
    });
  });
}
