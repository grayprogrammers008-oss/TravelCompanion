import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/trips/domain/models/trip_cost_summary.dart';
import 'package:travel_crew/features/trips/domain/usecases/calculate_trip_budget_status_usecase.dart';

void main() {
  late CalculateTripBudgetStatusUseCase useCase;

  setUp(() {
    useCase = CalculateTripBudgetStatusUseCase();
  });

  group('CalculateTripBudgetStatusUseCase', () {
    const tripId = 'trip123';

    // Helper to create cost summary
    TripCostSummary createCostSummary({
      required double totalCost,
    }) {
      return TripCostSummary(
        tripId: tripId,
        totalCost: totalCost,
        currency: 'INR',
        expenseCount: 1,
        categoryBreakdown: {},
        userSpending: {},
      );
    }

    group('No budget set', () {
      test('should return noBudget status when budget is null', () {
        // Arrange
        final costSummary = createCostSummary(totalCost: 5000.0);

        // Act
        final result = useCase(costSummary: costSummary, budget: null);

        // Assert
        expect(result.tripId, tripId);
        expect(result.budget, isNull);
        expect(result.actualCost, 5000.0);
        expect(result.remaining, isNull);
        expect(result.percentageUsed, isNull);
        expect(result.status, BudgetStatus.noBudget);
        expect(result.hasBudget, isFalse);
        expect(result.isOverBudget, isFalse);
        expect(result.isUnderBudget, isFalse);
        expect(result.isOnBudget, isFalse);
      });

      test('should return noBudget status when budget is zero', () {
        // Arrange
        final costSummary = createCostSummary(totalCost: 5000.0);

        // Act
        final result = useCase(costSummary: costSummary, budget: 0);

        // Assert
        expect(result.status, BudgetStatus.noBudget);
        expect(result.hasBudget, isFalse);
      });

      test('should return noBudget status when budget is negative', () {
        // Arrange
        final costSummary = createCostSummary(totalCost: 5000.0);

        // Act
        final result = useCase(costSummary: costSummary, budget: -100);

        // Assert
        expect(result.status, BudgetStatus.noBudget);
      });
    });

    group('Under budget', () {
      test('should return underBudget when cost is less than budget', () {
        // Arrange
        final costSummary = createCostSummary(totalCost: 5000.0);

        // Act
        final result = useCase(costSummary: costSummary, budget: 10000.0);

        // Assert
        expect(result.status, BudgetStatus.underBudget);
        expect(result.budget, 10000.0);
        expect(result.actualCost, 5000.0);
        expect(result.remaining, 5000.0);
        expect(result.percentageUsed, 50.0);
        expect(result.isUnderBudget, isTrue);
        expect(result.isOverBudget, isFalse);
        expect(result.isOnBudget, isFalse);
        expect(result.hasBudget, isTrue);
      });

      test('should return underBudget when at 50% of budget', () {
        // Arrange
        final costSummary = createCostSummary(totalCost: 2500.0);

        // Act
        final result = useCase(costSummary: costSummary, budget: 5000.0);

        // Assert
        expect(result.status, BudgetStatus.underBudget);
        expect(result.percentageUsed, 50.0);
        expect(result.remaining, 2500.0);
      });

      test('should return underBudget when at 94% of budget (below tolerance)',
          () {
        // Arrange
        final costSummary = createCostSummary(totalCost: 9400.0);

        // Act
        final result = useCase(costSummary: costSummary, budget: 10000.0);

        // Assert
        expect(result.status, BudgetStatus.underBudget);
        expect(result.percentageUsed, 94.0);
      });

      test('should return underBudget with zero cost', () {
        // Arrange
        final costSummary = createCostSummary(totalCost: 0.0);

        // Act
        final result = useCase(costSummary: costSummary, budget: 10000.0);

        // Assert
        expect(result.status, BudgetStatus.underBudget);
        expect(result.percentageUsed, 0.0);
        expect(result.remaining, 10000.0);
      });
    });

    group('On budget', () {
      test('should return onBudget when at 95% (within default tolerance)',
          () {
        // Arrange
        final costSummary = createCostSummary(totalCost: 9500.0);

        // Act
        final result = useCase(costSummary: costSummary, budget: 10000.0);

        // Assert
        expect(result.status, BudgetStatus.onBudget);
        expect(result.percentageUsed, 95.0);
        expect(result.remaining, 500.0);
        expect(result.isOnBudget, isTrue);
        expect(result.isUnderBudget, isFalse);
        expect(result.isOverBudget, isFalse);
      });

      test('should return onBudget when at 100% of budget', () {
        // Arrange
        final costSummary = createCostSummary(totalCost: 10000.0);

        // Act
        final result = useCase(costSummary: costSummary, budget: 10000.0);

        // Assert
        expect(result.status, BudgetStatus.onBudget);
        expect(result.percentageUsed, 100.0);
        expect(result.remaining, 0.0);
      });

      test('should return onBudget when at 98% (within tolerance)', () {
        // Arrange
        final costSummary = createCostSummary(totalCost: 9800.0);

        // Act
        final result = useCase(costSummary: costSummary, budget: 10000.0);

        // Assert
        expect(result.status, BudgetStatus.onBudget);
        expect(result.percentageUsed, 98.0);
      });

      test('should respect custom tolerance', () {
        // Arrange
        final costSummary = createCostSummary(totalCost: 9000.0);

        // Act with 10% tolerance (90%-100%)
        final result = useCase(
          costSummary: costSummary,
          budget: 10000.0,
          tolerance: 0.10,
        );

        // Assert
        expect(result.status, BudgetStatus.onBudget);
        expect(result.percentageUsed, 90.0);
      });

      test('should return underBudget with 10% tolerance at 89%', () {
        // Arrange
        final costSummary = createCostSummary(totalCost: 8900.0);

        // Act with 10% tolerance
        final result = useCase(
          costSummary: costSummary,
          budget: 10000.0,
          tolerance: 0.10,
        );

        // Assert
        expect(result.status, BudgetStatus.underBudget);
        expect(result.percentageUsed, 89.0);
      });
    });

    group('Over budget', () {
      test('should return overBudget when cost exceeds budget', () {
        // Arrange
        final costSummary = createCostSummary(totalCost: 12000.0);

        // Act
        final result = useCase(costSummary: costSummary, budget: 10000.0);

        // Assert
        expect(result.status, BudgetStatus.overBudget);
        expect(result.budget, 10000.0);
        expect(result.actualCost, 12000.0);
        expect(result.remaining, -2000.0);
        expect(result.percentageUsed, 120.0);
        expect(result.isOverBudget, isTrue);
        expect(result.isUnderBudget, isFalse);
        expect(result.isOnBudget, isFalse);
      });

      test('should return overBudget when at 101% of budget', () {
        // Arrange
        final costSummary = createCostSummary(totalCost: 10100.0);

        // Act
        final result = useCase(costSummary: costSummary, budget: 10000.0);

        // Assert
        expect(result.status, BudgetStatus.overBudget);
        expect(result.percentageUsed, 101.0);
        expect(result.remaining, -100.0);
      });

      test('should return overBudget when cost is double the budget', () {
        // Arrange
        final costSummary = createCostSummary(totalCost: 20000.0);

        // Act
        final result = useCase(costSummary: costSummary, budget: 10000.0);

        // Assert
        expect(result.status, BudgetStatus.overBudget);
        expect(result.percentageUsed, 200.0);
        expect(result.remaining, -10000.0);
      });
    });

    group('Edge cases', () {
      test('should handle very small budget', () {
        // Arrange
        final costSummary = createCostSummary(totalCost: 100.0);

        // Act
        final result = useCase(costSummary: costSummary, budget: 0.01);

        // Assert
        expect(result.status, BudgetStatus.overBudget);
        expect(result.percentageUsed, 1000000.0); // (100 / 0.01) * 100 = 1,000,000%
      });

      test('should handle very large numbers', () {
        // Arrange
        final costSummary = createCostSummary(totalCost: 1000000.0);

        // Act
        final result = useCase(costSummary: costSummary, budget: 2000000.0);

        // Assert
        expect(result.status, BudgetStatus.underBudget);
        expect(result.percentageUsed, 50.0);
        expect(result.remaining, 1000000.0);
      });

      test('should handle fractional amounts', () {
        // Arrange
        final costSummary = createCostSummary(totalCost: 9999.99);

        // Act
        final result = useCase(costSummary: costSummary, budget: 10000.0);

        // Assert
        expect(result.status, BudgetStatus.onBudget);
        expect(result.percentageUsed, closeTo(99.9999, 0.0001));
        expect(result.remaining, closeTo(0.01, 0.01));
      });

      test('should handle zero tolerance', () {
        // Arrange
        final costSummary = createCostSummary(totalCost: 9999.0);

        // Act
        final result = useCase(
          costSummary: costSummary,
          budget: 10000.0,
          tolerance: 0.0,
        );

        // Assert
        // With 0 tolerance, only exactly 100% should be "on budget"
        expect(result.status, BudgetStatus.underBudget);
      });

      test('should include cost summary in result', () {
        // Arrange
        final costSummary = TripCostSummary(
          tripId: tripId,
          totalCost: 5000.0,
          currency: 'USD',
          expenseCount: 5,
          categoryBreakdown: {'Food': 2000.0, 'Transport': 3000.0},
          userSpending: {'user1': 5000.0},
        );

        // Act
        final result = useCase(costSummary: costSummary, budget: 10000.0);

        // Assert
        expect(result.costSummary, costSummary);
        expect(result.costSummary.totalCost, 5000.0);
        expect(result.costSummary.currency, 'USD');
        expect(result.costSummary.expenseCount, 5);
      });
    });

    group('Boundary conditions', () {
      test('should correctly determine boundary at 95% (default tolerance)',
          () {
        // Arrange
        final costSummary1 = createCostSummary(totalCost: 9499.0);
        final costSummary2 = createCostSummary(totalCost: 9500.0);

        // Act
        final result1 = useCase(costSummary: costSummary1, budget: 10000.0);
        final result2 = useCase(costSummary: costSummary2, budget: 10000.0);

        // Assert
        expect(result1.status, BudgetStatus.underBudget);
        expect(result2.status, BudgetStatus.onBudget);
      });

      test('should correctly determine boundary at 100%', () {
        // Arrange
        final costSummary1 = createCostSummary(totalCost: 10000.0);
        final costSummary2 = createCostSummary(totalCost: 10001.0);

        // Act
        final result1 = useCase(costSummary: costSummary1, budget: 10000.0);
        final result2 = useCase(costSummary: costSummary2, budget: 10000.0);

        // Assert
        expect(result1.status, BudgetStatus.onBudget);
        expect(result2.status, BudgetStatus.overBudget);
      });

      test('should handle exact tolerance boundaries', () {
        // Arrange - 10% tolerance means 90%-100% is "on budget"
        final costSummary90 = createCostSummary(totalCost: 9000.0);
        final costSummary89 = createCostSummary(totalCost: 8999.0);

        // Act
        final result90 = useCase(
          costSummary: costSummary90,
          budget: 10000.0,
          tolerance: 0.10,
        );
        final result89 = useCase(
          costSummary: costSummary89,
          budget: 10000.0,
          tolerance: 0.10,
        );

        // Assert
        expect(result90.status, BudgetStatus.onBudget);
        expect(result89.status, BudgetStatus.underBudget);
      });
    });

    group('Different currency scenarios', () {
      test('should work with different currencies in cost summary', () {
        // Arrange
        final costSummary = TripCostSummary(
          tripId: tripId,
          totalCost: 5000.0,
          currency: 'EUR',
          expenseCount: 1,
          categoryBreakdown: {},
          userSpending: {},
        );

        // Act
        final result = useCase(costSummary: costSummary, budget: 10000.0);

        // Assert
        expect(result.status, BudgetStatus.underBudget);
        expect(result.costSummary.currency, 'EUR');
      });
    });
  });
}
