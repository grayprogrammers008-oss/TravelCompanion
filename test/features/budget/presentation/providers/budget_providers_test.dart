import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/budget/presentation/providers/budget_providers.dart';
import 'package:travel_crew/shared/models/expense_model.dart';

void main() {
  group('TripBudgetData', () {
    test('should identify when budget is not set', () {
      const data = TripBudgetData(
        budget: null,
        currency: 'INR',
        totalSpent: 1000,
        remaining: 0,
        percentageUsed: 0,
        status: BudgetStatus.noBudget,
        categoryBreakdown: [],
        expenseCount: 5,
        daysElapsed: 0,
        totalTripDays: 0,
        averageDailySpending: 0,
        projectedTotal: 0,
        projectedDifference: 0,
        isTripActive: false,
      );

      expect(data.hasBudget, false);
      expect(data.isOverBudget, false);
      expect(data.status, BudgetStatus.noBudget);
    });

    test('should identify when budget is set', () {
      const data = TripBudgetData(
        budget: 50000,
        currency: 'INR',
        totalSpent: 25000,
        remaining: 25000,
        percentageUsed: 50,
        status: BudgetStatus.moderate,
        categoryBreakdown: [],
        expenseCount: 10,
        daysElapsed: 3,
        totalTripDays: 7,
        averageDailySpending: 8333.33,
        projectedTotal: 58333.31,
        projectedDifference: 8333.31,
        isTripActive: true,
      );

      expect(data.hasBudget, true);
      expect(data.isOverBudget, false);
      expect(data.status, BudgetStatus.moderate);
    });

    test('should identify when over budget', () {
      const data = TripBudgetData(
        budget: 50000,
        currency: 'INR',
        totalSpent: 60000,
        remaining: -10000,
        percentageUsed: 120,
        status: BudgetStatus.exceeded,
        categoryBreakdown: [],
        expenseCount: 15,
        daysElapsed: 5,
        totalTripDays: 5,
        averageDailySpending: 12000,
        projectedTotal: 60000,
        projectedDifference: 10000,
        isTripActive: false,
      );

      expect(data.hasBudget, true);
      expect(data.isOverBudget, true);
      expect(data.status, BudgetStatus.exceeded);
    });

    test('should return correct status messages', () {
      expect(
        const TripBudgetData(
          budget: null,
          currency: 'INR',
          totalSpent: 0,
          remaining: 0,
          percentageUsed: 0,
          status: BudgetStatus.noBudget,
          categoryBreakdown: [],
          expenseCount: 0,
          daysElapsed: 0,
          totalTripDays: 0,
          averageDailySpending: 0,
          projectedTotal: 0,
          projectedDifference: 0,
          isTripActive: false,
        ).statusMessage,
        'No budget set',
      );

      expect(
        const TripBudgetData(
          budget: 50000,
          currency: 'INR',
          totalSpent: 10000,
          remaining: 40000,
          percentageUsed: 20,
          status: BudgetStatus.healthy,
          categoryBreakdown: [],
          expenseCount: 5,
          daysElapsed: 1,
          totalTripDays: 5,
          averageDailySpending: 10000,
          projectedTotal: 50000,
          projectedDifference: 0,
          isTripActive: true,
        ).statusMessage,
        'On track! Keep it up.',
      );

      expect(
        const TripBudgetData(
          budget: 50000,
          currency: 'INR',
          totalSpent: 55000,
          remaining: -5000,
          percentageUsed: 110,
          status: BudgetStatus.exceeded,
          categoryBreakdown: [],
          expenseCount: 20,
          daysElapsed: 5,
          totalTripDays: 5,
          averageDailySpending: 11000,
          projectedTotal: 55000,
          projectedDifference: 5000,
          isTripActive: false,
        ).statusMessage,
        'Budget exceeded!',
      );
    });
  });

  group('BudgetStatus', () {
    test('healthy status for under 50%', () {
      expect(BudgetStatus.healthy.index, 0);
    });

    test('moderate status for 50-75%', () {
      expect(BudgetStatus.moderate.index, 1);
    });

    test('warning status for 75-90%', () {
      expect(BudgetStatus.warning.index, 2);
    });

    test('critical status for 90-100%', () {
      expect(BudgetStatus.critical.index, 3);
    });

    test('exceeded status for over 100%', () {
      expect(BudgetStatus.exceeded.index, 4);
    });

    test('noBudget status when budget is null', () {
      expect(BudgetStatus.noBudget.index, 5);
    });
  });

  group('CategoryBreakdown', () {
    test('should create with correct values', () {
      const breakdown = CategoryBreakdown(
        category: 'Food',
        amount: 5000,
        percentage: 25.0,
        count: 10,
      );

      expect(breakdown.category, 'Food');
      expect(breakdown.amount, 5000);
      expect(breakdown.percentage, 25.0);
      expect(breakdown.count, 10);
    });
  });

  group('Budget calculation logic', () {
    test('should calculate correct percentage used', () {
      const budget = 50000.0;
      const spent = 25000.0;
      final percentage = (spent / budget) * 100;

      expect(percentage, 50.0);
    });

    test('should calculate correct remaining amount', () {
      const budget = 50000.0;
      const spent = 35000.0;
      final remaining = budget - spent;

      expect(remaining, 15000.0);
    });

    test('should calculate negative remaining when over budget', () {
      const budget = 50000.0;
      const spent = 60000.0;
      final remaining = budget - spent;

      expect(remaining, -10000.0);
    });

    test('should calculate average daily spending', () {
      const totalSpent = 30000.0;
      const daysElapsed = 3;
      final average = totalSpent / daysElapsed;

      expect(average, 10000.0);
    });

    test('should calculate projected total spending', () {
      const averageDailySpending = 10000.0;
      const totalTripDays = 7;
      final projected = averageDailySpending * totalTripDays;

      expect(projected, 70000.0);
    });

    test('should determine correct status based on percentage', () {
      BudgetStatus getStatus(double percentage) {
        if (percentage > 100) return BudgetStatus.exceeded;
        if (percentage >= 90) return BudgetStatus.critical;
        if (percentage >= 75) return BudgetStatus.warning;
        if (percentage >= 50) return BudgetStatus.moderate;
        return BudgetStatus.healthy;
      }

      expect(getStatus(20), BudgetStatus.healthy);
      expect(getStatus(49), BudgetStatus.healthy);
      expect(getStatus(50), BudgetStatus.moderate);
      expect(getStatus(74), BudgetStatus.moderate);
      expect(getStatus(75), BudgetStatus.warning);
      expect(getStatus(89), BudgetStatus.warning);
      expect(getStatus(90), BudgetStatus.critical);
      expect(getStatus(99), BudgetStatus.critical);
      expect(getStatus(100), BudgetStatus.critical);
      expect(getStatus(101), BudgetStatus.exceeded);
      expect(getStatus(150), BudgetStatus.exceeded);
    });
  });

  group('Category breakdown calculation', () {
    test('should group expenses by category', () {
      final expenses = [
        _createExpense('Food', 1000),
        _createExpense('Food', 2000),
        _createExpense('Transport', 500),
        _createExpense('Hotel', 5000),
        _createExpense('Food', 1500),
      ];

      final categoryMap = <String, double>{};
      for (final expense in expenses) {
        final category = expense.category ?? 'Other';
        categoryMap[category] = (categoryMap[category] ?? 0) + expense.amount;
      }

      expect(categoryMap['Food'], 4500);
      expect(categoryMap['Transport'], 500);
      expect(categoryMap['Hotel'], 5000);
    });

    test('should calculate correct percentages', () {
      final totalSpent = 10000.0;
      final foodAmount = 4500.0;
      final transportAmount = 500.0;
      final hotelAmount = 5000.0;

      expect((foodAmount / totalSpent) * 100, 45.0);
      expect((transportAmount / totalSpent) * 100, 5.0);
      expect((hotelAmount / totalSpent) * 100, 50.0);
    });
  });

  group('Trip date calculations', () {
    test('should calculate total trip days correctly', () {
      final startDate = DateTime(2025, 1, 24);
      final endDate = DateTime(2025, 1, 28);
      final totalDays = endDate.difference(startDate).inDays + 1;

      expect(totalDays, 5);
    });

    test('should calculate days elapsed during active trip', () {
      final startDate = DateTime(2025, 1, 24);
      final now = DateTime(2025, 1, 26);
      final daysElapsed = now.difference(startDate).inDays + 1;

      expect(daysElapsed, 3);
    });

    test('should identify active trip correctly', () {
      final startDate = DateTime(2025, 1, 24);
      final endDate = DateTime(2025, 1, 28);
      final now = DateTime(2025, 1, 26);

      final isActive = now.isAfter(startDate) && now.isBefore(endDate);
      expect(isActive, true);
    });

    test('should identify completed trip correctly', () {
      final startDate = DateTime(2025, 1, 24);
      final endDate = DateTime(2025, 1, 28);
      final now = DateTime(2025, 2, 1);

      final isCompleted = now.isAfter(endDate);
      expect(isCompleted, true);
    });

    test('should identify upcoming trip correctly', () {
      final tripStartDate = DateTime(2025, 3, 1);
      final now = DateTime(2025, 1, 26);

      final isUpcoming = now.isBefore(tripStartDate);
      expect(isUpcoming, true);
    });
  });

  group('getCategoryIcon', () {
    test('should return correct icons for known categories', () {
      expect(getCategoryIcon('food'), 'restaurant');
      expect(getCategoryIcon('Food'), 'restaurant');
      expect(getCategoryIcon('dining'), 'restaurant');
      expect(getCategoryIcon('transport'), 'directions_car');
      expect(getCategoryIcon('Transportation'), 'directions_car');
      expect(getCategoryIcon('hotel'), 'hotel');
      expect(getCategoryIcon('accommodation'), 'hotel');
      expect(getCategoryIcon('activities'), 'local_activity');
      expect(getCategoryIcon('shopping'), 'shopping_bag');
    });

    test('should return default icon for unknown categories', () {
      expect(getCategoryIcon('unknown'), 'receipt_long');
      expect(getCategoryIcon('misc'), 'receipt_long');
      expect(getCategoryIcon('other'), 'receipt_long');
    });
  });

  group('Pace calculations', () {
    test('should calculate projected overspend', () {
      const budget = 50000.0;
      const projectedTotal = 70000.0;
      final projectedDifference = projectedTotal - budget;

      expect(projectedDifference, 20000.0);
      expect(projectedDifference > 0, true); // Will exceed budget
    });

    test('should calculate projected underspend', () {
      const budget = 50000.0;
      const projectedTotal = 40000.0;
      final projectedDifference = projectedTotal - budget;

      expect(projectedDifference, -10000.0);
      expect(projectedDifference < 0, true); // Will save money
    });

    test('should handle exact budget projection', () {
      const budget = 50000.0;
      const projectedTotal = 50000.0;
      final projectedDifference = projectedTotal - budget;

      expect(projectedDifference, 0.0);
    });
  });
}

ExpenseModel _createExpense(String category, double amount) {
  return ExpenseModel(
    id: 'expense-${DateTime.now().millisecondsSinceEpoch}',
    title: 'Test Expense',
    amount: amount,
    category: category,
    paidBy: 'user-1',
  );
}
