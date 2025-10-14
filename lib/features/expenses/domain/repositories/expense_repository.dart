import '../../../../shared/models/expense_model.dart';

/// Expense repository interface
abstract class ExpenseRepository {
  /// Get all expenses for current user (trip and standalone)
  Future<List<ExpenseWithSplits>> getUserExpenses();

  /// Get all expenses for a trip
  Future<List<ExpenseWithSplits>> getTripExpenses(String tripId);

  /// Get standalone expenses (no trip)
  Future<List<ExpenseWithSplits>> getStandaloneExpenses();

  /// Get a single expense by ID
  Future<ExpenseWithSplits> getExpenseById(String expenseId);

  /// Create a new expense with splits (supports standalone)
  Future<ExpenseModel> createExpense({
    String? tripId, // Optional for standalone expenses
    required String title,
    String? description,
    required double amount,
    String? category,
    required String paidBy,
    required List<String> splitWith, // User IDs to split with
    String splitType = 'equal',
    DateTime? transactionDate,
  });

  /// Update an expense
  Future<ExpenseModel> updateExpense({
    required String expenseId,
    String? title,
    String? description,
    double? amount,
    String? category,
    DateTime? transactionDate,
  });

  /// Delete an expense
  Future<void> deleteExpense(String expenseId);

  /// Get balance summary (trip or user standalone expenses)
  Future<List<BalanceSummary>> getBalances({String? tripId, String? userId});

  /// Create a settlement (supports standalone)
  Future<SettlementModel> createSettlement({
    String? tripId, // Optional for standalone
    required String fromUser,
    required String toUser,
    required double amount,
    String? paymentMethod,
  });

  /// Get settlements (trip or user)
  Future<List<SettlementModel>> getSettlements({
    String? tripId,
    String? userId,
  });

  /// Update settlement status
  Future<SettlementModel> updateSettlementStatus({
    required String settlementId,
    required String status,
    String? paymentProofUrl,
  });
}
