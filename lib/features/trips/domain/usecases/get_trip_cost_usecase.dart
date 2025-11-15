import '../../../../features/expenses/domain/repositories/expense_repository.dart';
import '../models/trip_cost_summary.dart';

/// Use case for getting trip cost summary
/// Aggregates all expenses for a trip and calculates totals, breakdowns, and statistics
class GetTripCostUseCase {
  final ExpenseRepository _expenseRepository;

  GetTripCostUseCase(this._expenseRepository);

  /// Get cost summary for a trip
  ///
  /// Parameters:
  /// - [tripId]: The ID of the trip
  ///
  /// Returns [TripCostSummary] with aggregated expense data
  /// Throws exception if repository fails
  Future<TripCostSummary> call(String tripId) async {
    // Fetch all expenses for the trip
    final expensesWithSplits = await _expenseRepository.getTripExpenses(tripId);

    // Handle empty expenses
    if (expensesWithSplits.isEmpty) {
      return TripCostSummary(
        tripId: tripId,
        totalCost: 0.0,
        currency: 'INR', // Default currency
        expenseCount: 0,
        categoryBreakdown: {},
        userSpending: {},
        lastExpenseDate: null,
      );
    }

    // Initialize aggregation variables
    double totalCost = 0.0;
    String currency = expensesWithSplits.first.expense.currency;
    final Map<String, double> categoryBreakdown = {};
    final Map<String, double> userSpending = {};
    DateTime? lastExpenseDate;

    // Aggregate expense data
    for (final expenseWithSplits in expensesWithSplits) {
      final expense = expenseWithSplits.expense;

      // Add to total cost
      totalCost += expense.amount;

      // Update category breakdown
      final category = expense.category ?? 'Uncategorized';
      categoryBreakdown[category] =
          (categoryBreakdown[category] ?? 0.0) + expense.amount;

      // Update user spending (paid by)
      userSpending[expense.paidBy] =
          (userSpending[expense.paidBy] ?? 0.0) + expense.amount;

      // Update last expense date
      if (expense.transactionDate != null) {
        if (lastExpenseDate == null ||
            expense.transactionDate!.isAfter(lastExpenseDate)) {
          lastExpenseDate = expense.transactionDate;
        }
      } else if (expense.createdAt != null) {
        if (lastExpenseDate == null ||
            expense.createdAt!.isAfter(lastExpenseDate)) {
          lastExpenseDate = expense.createdAt;
        }
      }
    }

    return TripCostSummary(
      tripId: tripId,
      totalCost: totalCost,
      currency: currency,
      expenseCount: expensesWithSplits.length,
      categoryBreakdown: categoryBreakdown,
      userSpending: userSpending,
      lastExpenseDate: lastExpenseDate,
    );
  }
}
