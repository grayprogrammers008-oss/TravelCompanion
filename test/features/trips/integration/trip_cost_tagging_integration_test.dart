import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/expenses/domain/repositories/expense_repository.dart';
import 'package:travel_crew/features/trips/domain/usecases/calculate_trip_budget_status_usecase.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_trip_cost_usecase.dart';
import 'package:travel_crew/shared/models/expense_model.dart';

import 'trip_cost_tagging_integration_test.mocks.dart';

@GenerateMocks([ExpenseRepository])
void main() {
  late GetTripCostUseCase getTripCostUseCase;
  late CalculateTripBudgetStatusUseCase calculateBudgetStatusUseCase;
  late MockExpenseRepository mockExpenseRepository;

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    getTripCostUseCase = GetTripCostUseCase(mockExpenseRepository);
    calculateBudgetStatusUseCase = CalculateTripBudgetStatusUseCase();
  });

  group('Trip Cost Tagging Integration Tests', () {
    const tripId = 'integration_trip';

    // Helper to create expenses
    List<ExpenseWithSplits> createTestExpenses() {
      return [
        ExpenseWithSplits(
          expense: ExpenseModel(
            id: 'exp1',
            tripId: tripId,
            title: 'Hotel Booking',
            description: '3 nights at Grand Hotel',
            amount: 15000.0,
            currency: 'INR',
            category: 'Accommodation',
            paidBy: 'user1',
            transactionDate: DateTime(2024, 1, 15),
          ),
          splits: [],
        ),
        ExpenseWithSplits(
          expense: ExpenseModel(
            id: 'exp2',
            tripId: tripId,
            title: 'Flight Tickets',
            description: 'Round trip tickets',
            amount: 25000.0,
            currency: 'INR',
            category: 'Transport',
            paidBy: 'user2',
            transactionDate: DateTime(2024, 1, 10),
          ),
          splits: [],
        ),
        ExpenseWithSplits(
          expense: ExpenseModel(
            id: 'exp3',
            tripId: tripId,
            title: 'Dinner at Restaurant',
            description: 'Italian cuisine',
            amount: 3500.0,
            currency: 'INR',
            category: 'Food',
            paidBy: 'user1',
            transactionDate: DateTime(2024, 1, 16),
          ),
          splits: [],
        ),
        ExpenseWithSplits(
          expense: ExpenseModel(
            id: 'exp4',
            tripId: tripId,
            title: 'Taxi',
            description: 'Airport to hotel',
            amount: 800.0,
            currency: 'INR',
            category: 'Transport',
            paidBy: 'user3',
            transactionDate: DateTime(2024, 1, 15),
          ),
          splits: [],
        ),
        ExpenseWithSplits(
          expense: ExpenseModel(
            id: 'exp5',
            tripId: tripId,
            title: 'Breakfast',
            description: 'Hotel breakfast',
            amount: 1200.0,
            currency: 'INR',
            category: 'Food',
            paidBy: 'user2',
            transactionDate: DateTime(2024, 1, 17),
          ),
          splits: [],
        ),
      ];
    }

    group('Complete Flow: Get Cost then Calculate Budget', () {
      test('should get trip cost and calculate underBudget status', () async {
        // Arrange
        final expenses = createTestExpenses();
        when(mockExpenseRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act - Get trip cost
        final costSummary = await getTripCostUseCase(tripId);

        // Assert cost summary
        expect(costSummary.totalCost, 45500.0);
        expect(costSummary.expenseCount, 5);
        expect(costSummary.categoryBreakdown['Accommodation'], 15000.0);
        expect(costSummary.categoryBreakdown['Transport'], 25800.0);
        expect(costSummary.categoryBreakdown['Food'], 4700.0);

        // Act - Calculate budget status with 60000 budget
        final budgetStatus = calculateBudgetStatusUseCase(
          costSummary: costSummary,
          budget: 60000.0,
        );

        // Assert budget status
        expect(budgetStatus.status, BudgetStatus.underBudget);
        expect(budgetStatus.percentageUsed, closeTo(75.83, 0.01));
        expect(budgetStatus.remaining, 14500.0);
        expect(budgetStatus.isUnderBudget, isTrue);
      });

      test('should get trip cost and calculate onBudget status', () async {
        // Arrange
        final expenses = createTestExpenses();
        when(mockExpenseRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final costSummary = await getTripCostUseCase(tripId);
        final budgetStatus = calculateBudgetStatusUseCase(
          costSummary: costSummary,
          budget: 47500.0, // ~95.8% usage
        );

        // Assert
        expect(budgetStatus.status, BudgetStatus.onBudget);
        expect(budgetStatus.percentageUsed, closeTo(95.79, 0.01));
        expect(budgetStatus.remaining, 2000.0);
        expect(budgetStatus.isOnBudget, isTrue);
      });

      test('should get trip cost and calculate overBudget status', () async {
        // Arrange
        final expenses = createTestExpenses();
        when(mockExpenseRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final costSummary = await getTripCostUseCase(tripId);
        final budgetStatus = calculateBudgetStatusUseCase(
          costSummary: costSummary,
          budget: 40000.0,
        );

        // Assert
        expect(budgetStatus.status, BudgetStatus.overBudget);
        expect(budgetStatus.percentageUsed, 113.75);
        expect(budgetStatus.remaining, -5500.0);
        expect(budgetStatus.isOverBudget, isTrue);
      });
    });

    group('Real-world scenarios', () {
      test('should handle trip with no expenses', () async {
        // Arrange
        when(mockExpenseRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => []);

        // Act
        final costSummary = await getTripCostUseCase(tripId);
        final budgetStatus = calculateBudgetStatusUseCase(
          costSummary: costSummary,
          budget: 50000.0,
        );

        // Assert
        expect(costSummary.totalCost, 0.0);
        expect(budgetStatus.status, BudgetStatus.underBudget);
        expect(budgetStatus.percentageUsed, 0.0);
        expect(budgetStatus.remaining, 50000.0);
      });

      test('should track user spending contributions', () async {
        // Arrange
        final expenses = createTestExpenses();
        when(mockExpenseRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final costSummary = await getTripCostUseCase(tripId);

        // Assert - Check who paid what
        expect(costSummary.getUserSpending('user1'), 18500.0); // Hotel + Dinner
        expect(costSummary.getUserSpending('user2'), 26200.0); // Flight + Breakfast
        expect(costSummary.getUserSpending('user3'), 800.0); // Taxi
        expect(costSummary.usersWithSpending.length, 3);
      });

      test('should track category breakdown accurately', () async {
        // Arrange
        final expenses = createTestExpenses();
        when(mockExpenseRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final costSummary = await getTripCostUseCase(tripId);

        // Assert
        expect(costSummary.categoriesWithSpending.length, 3);
        expect(costSummary.getCategorySpending('Accommodation'), 15000.0);
        expect(costSummary.getCategorySpending('Transport'), 25800.0);
        expect(costSummary.getCategorySpending('Food'), 4700.0);
        expect(costSummary.getCategorySpending('Entertainment'), 0.0);
      });

      test('should identify last expense date correctly', () async {
        // Arrange
        final expenses = createTestExpenses();
        when(mockExpenseRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final costSummary = await getTripCostUseCase(tripId);

        // Assert - Last expense was breakfast on Jan 17
        expect(costSummary.lastExpenseDate, DateTime(2024, 1, 17));
      });
    });

    group('Budget monitoring scenarios', () {
      test('should detect when approaching budget limit', () async {
        // Arrange
        final expenses = createTestExpenses();
        when(mockExpenseRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final costSummary = await getTripCostUseCase(tripId);
        final budgetStatus = calculateBudgetStatusUseCase(
          costSummary: costSummary,
          budget: 48000.0,
        );

        // Assert - 94.79% used, within tolerance for "on budget"
        expect(budgetStatus.status, BudgetStatus.underBudget);
        expect(budgetStatus.percentageUsed, closeTo(94.79, 0.01));
        expect(budgetStatus.remaining, closeTo(2500.0, 1.0));
      });

      test('should warn when exceeding budget by different amounts', () async {
        // Arrange
        final expenses = createTestExpenses();
        when(mockExpenseRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        final costSummary = await getTripCostUseCase(tripId);

        // Test slightly over budget
        final slightlyOver = calculateBudgetStatusUseCase(
          costSummary: costSummary,
          budget: 45000.0,
        );
        expect(slightlyOver.status, BudgetStatus.overBudget);
        expect(slightlyOver.percentageUsed, closeTo(101.11, 0.01));

        // Test significantly over budget
        final significantlyOver = calculateBudgetStatusUseCase(
          costSummary: costSummary,
          budget: 30000.0,
        );
        expect(significantlyOver.status, BudgetStatus.overBudget);
        expect(significantlyOver.percentageUsed, closeTo(151.67, 0.01));
      });

      test('should handle trip without budget set', () async {
        // Arrange
        final expenses = createTestExpenses();
        when(mockExpenseRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final costSummary = await getTripCostUseCase(tripId);
        final budgetStatus = calculateBudgetStatusUseCase(
          costSummary: costSummary,
          budget: null,
        );

        // Assert
        expect(budgetStatus.status, BudgetStatus.noBudget);
        expect(budgetStatus.hasBudget, isFalse);
        expect(budgetStatus.percentageUsed, isNull);
        expect(budgetStatus.remaining, isNull);
        expect(costSummary.totalCost, 45500.0); // Still tracks cost
      });
    });

    group('Statistics and analytics', () {
      test('should calculate average expense correctly', () async {
        // Arrange
        final expenses = createTestExpenses();
        when(mockExpenseRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final costSummary = await getTripCostUseCase(tripId);

        // Assert
        expect(costSummary.averageExpenseAmount, 9100.0); // 45500 / 5
      });

      test('should provide comprehensive trip spending insights', () async {
        // Arrange
        final expenses = createTestExpenses();
        when(mockExpenseRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final costSummary = await getTripCostUseCase(tripId);
        final budgetStatus = calculateBudgetStatusUseCase(
          costSummary: costSummary,
          budget: 50000.0,
        );

        // Assert - Complete spending picture
        expect(costSummary.totalCost, 45500.0);
        expect(costSummary.expenseCount, 5);
        expect(costSummary.averageExpenseAmount, 9100.0);
        expect(costSummary.categoriesWithSpending.length, 3);
        expect(costSummary.usersWithSpending.length, 3);
        expect(budgetStatus.percentageUsed, 91.0);
        expect(budgetStatus.remaining, 4500.0);
        expect(budgetStatus.isUnderBudget, isTrue);
      });
    });

    group('Error handling', () {
      test('should propagate repository errors', () async {
        // Arrange
        when(mockExpenseRepository.getTripExpenses(tripId))
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(() => getTripCostUseCase(tripId), throwsException);
      });
    });
  });
}
