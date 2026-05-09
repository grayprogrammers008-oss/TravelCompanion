import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/trips/domain/models/trip_cost_summary.dart';

void main() {
  TripCostSummary summary({
    String tripId = 't1',
    double totalCost = 100.0,
    String currency = 'INR',
    int expenseCount = 4,
    Map<String, double>? categoryBreakdown,
    Map<String, double>? userSpending,
    DateTime? lastExpenseDate,
  }) =>
      TripCostSummary(
        tripId: tripId,
        totalCost: totalCost,
        currency: currency,
        expenseCount: expenseCount,
        categoryBreakdown: categoryBreakdown ??
            const {'Food': 60, 'Transport': 40},
        userSpending:
            userSpending ?? const {'u-1': 70, 'u-2': 30},
        lastExpenseDate: lastExpenseDate ?? DateTime.utc(2024, 6, 1),
      );

  group('TripCostSummary constructor', () {
    test('stores all fields', () {
      final s = summary();
      expect(s.tripId, 't1');
      expect(s.totalCost, 100.0);
      expect(s.currency, 'INR');
      expect(s.expenseCount, 4);
      expect(s.categoryBreakdown, {'Food': 60.0, 'Transport': 40.0});
      expect(s.userSpending, {'u-1': 70.0, 'u-2': 30.0});
      expect(s.lastExpenseDate, DateTime.utc(2024, 6, 1));
    });

    test('lastExpenseDate is optional and defaults to null', () {
      const s = TripCostSummary(
        tripId: 't',
        totalCost: 0,
        currency: 'USD',
        expenseCount: 0,
        categoryBreakdown: {},
        userSpending: {},
      );
      expect(s.lastExpenseDate, isNull);
    });
  });

  group('TripCostSummary.averageExpenseAmount', () {
    test('returns totalCost / expenseCount when count is positive', () {
      expect(summary(totalCost: 200, expenseCount: 4).averageExpenseAmount,
          50.0);
    });

    test('returns 0.0 when expenseCount is 0', () {
      expect(summary(totalCost: 50, expenseCount: 0).averageExpenseAmount,
          0.0);
    });

    test('returns 0.0 when both totalCost and expenseCount are 0', () {
      expect(summary(totalCost: 0, expenseCount: 0).averageExpenseAmount,
          0.0);
    });
  });

  group('TripCostSummary.getUserSpending', () {
    final s = summary(userSpending: const {'u-1': 100, 'u-2': 50});

    test('returns the amount when user is in the map', () {
      expect(s.getUserSpending('u-1'), 100.0);
      expect(s.getUserSpending('u-2'), 50.0);
    });

    test('returns 0.0 when user is not in the map', () {
      expect(s.getUserSpending('u-99'), 0.0);
    });
  });

  group('TripCostSummary.getCategorySpending', () {
    final s = summary(
      categoryBreakdown: const {'Food': 80, 'Transport': 20},
    );

    test('returns the amount when category is in the map', () {
      expect(s.getCategorySpending('Food'), 80.0);
      expect(s.getCategorySpending('Transport'), 20.0);
    });

    test('returns 0.0 when category is not in the map', () {
      expect(s.getCategorySpending('Shopping'), 0.0);
    });
  });

  group('TripCostSummary.categoriesWithSpending', () {
    test('returns the keys of categoryBreakdown', () {
      final s = summary(
        categoryBreakdown: const {'Food': 1, 'Transport': 2, 'Stay': 3},
      );
      expect(s.categoriesWithSpending, ['Food', 'Transport', 'Stay']);
    });

    test('returns empty list when no categories', () {
      final s = summary(categoryBreakdown: const {});
      expect(s.categoriesWithSpending, isEmpty);
    });
  });

  group('TripCostSummary.usersWithSpending', () {
    test('returns the keys of userSpending', () {
      final s = summary(userSpending: const {'a': 1, 'b': 2});
      expect(s.usersWithSpending, ['a', 'b']);
    });

    test('returns empty list when no spenders', () {
      final s = summary(userSpending: const {});
      expect(s.usersWithSpending, isEmpty);
    });
  });

  group('TripCostSummary.copyWith', () {
    test('preserves all fields when no overrides', () {
      final s = summary();
      expect(s.copyWith(), s);
    });

    test('overrides only specified fields', () {
      final s = summary();
      final c = s.copyWith(totalCost: 999, expenseCount: 9);
      expect(c.totalCost, 999.0);
      expect(c.expenseCount, 9);
      expect(c.tripId, s.tripId);
      expect(c.currency, s.currency);
      expect(c.categoryBreakdown, s.categoryBreakdown);
    });

    test('copies categoryBreakdown when supplied', () {
      final s = summary();
      final c = s.copyWith(categoryBreakdown: const {'X': 1});
      expect(c.categoryBreakdown, {'X': 1.0});
    });
  });

  group('TripCostSummary equality and hashCode', () {
    test('identical instance is equal', () {
      final s = summary();
      expect(s, s);
    });

    test('two equivalent instances are equal and share hashCode', () {
      final a = summary();
      final b = summary();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different tripId → not equal', () {
      expect(summary(tripId: 'a') == summary(tripId: 'b'), isFalse);
    });

    test('different totalCost → not equal', () {
      expect(summary(totalCost: 1) == summary(totalCost: 2), isFalse);
    });

    test('different currency → not equal', () {
      expect(summary(currency: 'INR') == summary(currency: 'USD'), isFalse);
    });

    test('different expenseCount → not equal', () {
      expect(summary(expenseCount: 1) == summary(expenseCount: 2), isFalse);
    });

    test('different categoryBreakdown content → not equal', () {
      expect(
          summary(categoryBreakdown: const {'A': 1}) ==
              summary(categoryBreakdown: const {'A': 2}),
          isFalse);
    });

    test('different categoryBreakdown length → not equal', () {
      expect(
          summary(categoryBreakdown: const {'A': 1}) ==
              summary(categoryBreakdown: const {'A': 1, 'B': 2}),
          isFalse);
    });

    test('different categoryBreakdown keys → not equal', () {
      expect(
          summary(categoryBreakdown: const {'A': 1}) ==
              summary(categoryBreakdown: const {'B': 1}),
          isFalse);
    });

    test('different userSpending → not equal', () {
      expect(
          summary(userSpending: const {'u': 1}) ==
              summary(userSpending: const {'u': 2}),
          isFalse);
    });

    test('different lastExpenseDate → not equal', () {
      expect(
          summary(lastExpenseDate: DateTime.utc(2024, 1, 1)) ==
              summary(lastExpenseDate: DateTime.utc(2024, 2, 1)),
          isFalse);
    });

    test('different runtime type → not equal', () {
      expect(summary() == const Object(), isFalse);
    });
  });

  group('TripCostSummary.toString', () {
    test('contains all field labels', () {
      final s = summary();
      final str = s.toString();
      expect(str, contains('tripId'));
      expect(str, contains('totalCost'));
      expect(str, contains('currency'));
      expect(str, contains('expenseCount'));
      expect(str, contains('categoryBreakdown'));
      expect(str, contains('userSpending'));
      expect(str, contains('lastExpenseDate'));
    });
  });
}
