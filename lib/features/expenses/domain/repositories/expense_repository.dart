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

  /// Create a new expense with splits (supports standalone).
  /// [ghostSplitWith] adds non-member ("ghost") participants — see
  /// [createGhostParticipant]. Their share folds into their creator's balance.
  Future<ExpenseModel> createExpense({
    String? tripId, // Optional for standalone expenses
    required String title,
    String? description,
    required double amount,
    String? category,
    required String paidBy,
    required List<String> splitWith, // Real-member user IDs
    List<String> ghostSplitWith = const [], // Ghost participant IDs
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

  /// Watch trip expenses in real-time
  Stream<List<ExpenseWithSplits>> watchTripExpenses(String tripId);

  /// Watch user expenses in real-time
  Stream<List<ExpenseWithSplits>> watchUserExpenses();

  // ---- Ghost participants -----------------------------------------------

  /// Add a non-member ("ghost") participant to a trip. [guardianUserId]
  /// is the trip member who pays for the ghost's expenses (defaults to
  /// [createdBy] when omitted).
  Future<GhostParticipantModel> createGhostParticipant({
    required String tripId,
    required String name,
    required String createdBy,
    String? guardianUserId,
  });

  /// All ghost participants for a trip.
  Future<List<GhostParticipantModel>> getGhostParticipants(String tripId);

  /// Rename a ghost participant.
  Future<GhostParticipantModel> renameGhostParticipant({
    required String ghostId,
    required String name,
  });

  /// Remove a ghost participant. Splits referencing them cascade-delete.
  Future<void> deleteGhostParticipant(String ghostId);
}
