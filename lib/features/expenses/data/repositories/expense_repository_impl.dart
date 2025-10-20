import '../../../../shared/models/expense_model.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_datasource.dart';

/// Implementation of ExpenseRepository using remote datasource (Supabase)
class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource _remoteDataSource;

  ExpenseRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ExpenseWithSplits>> getUserExpenses() async {
    try {
      return await _remoteDataSource.getUserExpenses();
    } catch (e) {
      throw Exception('Failed to get user expenses: $e');
    }
  }

  @override
  Future<List<ExpenseWithSplits>> getTripExpenses(String tripId) async {
    try {
      return await _remoteDataSource.getTripExpenses(tripId);
    } catch (e) {
      throw Exception('Failed to get trip expenses: $e');
    }
  }

  @override
  Future<List<ExpenseWithSplits>> getStandaloneExpenses() async {
    try {
      return await _remoteDataSource.getStandaloneExpenses();
    } catch (e) {
      throw Exception('Failed to get standalone expenses: $e');
    }
  }

  @override
  Future<ExpenseWithSplits> getExpenseById(String expenseId) async {
    try {
      return await _remoteDataSource.getExpenseById(expenseId);
    } catch (e) {
      throw Exception('Failed to get expense: $e');
    }
  }

  @override
  Future<ExpenseModel> createExpense({
    String? tripId, // Optional for standalone
    required String title,
    String? description,
    required double amount,
    String? category,
    required String paidBy,
    required List<String> splitWith,
    String splitType = 'equal',
    DateTime? transactionDate,
  }) async {
    try {
      return await _remoteDataSource.createExpense(
        tripId: tripId,
        title: title,
        description: description,
        amount: amount,
        category: category,
        paidBy: paidBy,
        splitWith: splitWith,
        splitType: splitType,
        transactionDate: transactionDate,
      );
    } catch (e) {
      throw Exception('Failed to create expense: $e');
    }
  }

  @override
  Future<ExpenseModel> updateExpense({
    required String expenseId,
    String? title,
    String? description,
    double? amount,
    String? category,
    DateTime? transactionDate,
  }) async {
    try {
      return await _remoteDataSource.updateExpense(
        expenseId: expenseId,
        title: title,
        description: description,
        amount: amount,
        category: category,
        transactionDate: transactionDate,
      );
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _remoteDataSource.deleteExpense(expenseId);
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  @override
  Future<List<BalanceSummary>> getBalances({
    String? tripId,
    String? userId,
  }) async {
    try {
      return await _remoteDataSource.getBalances(tripId: tripId, userId: userId);
    } catch (e) {
      throw Exception('Failed to get balances: $e');
    }
  }

  @override
  Future<SettlementModel> createSettlement({
    String? tripId, // Optional for standalone
    required String fromUser,
    required String toUser,
    required double amount,
    String? paymentMethod,
  }) async {
    try {
      return await _remoteDataSource.createSettlement(
        tripId: tripId,
        fromUser: fromUser,
        toUser: toUser,
        amount: amount,
        paymentMethod: paymentMethod,
      );
    } catch (e) {
      throw Exception('Failed to create settlement: $e');
    }
  }

  @override
  Future<List<SettlementModel>> getSettlements({
    String? tripId,
    String? userId,
  }) async {
    try {
      return await _remoteDataSource.getSettlements(tripId: tripId, userId: userId);
    } catch (e) {
      throw Exception('Failed to get settlements: $e');
    }
  }

  @override
  Future<SettlementModel> updateSettlementStatus({
    required String settlementId,
    required String status,
    String? paymentProofUrl,
  }) async {
    try {
      return await _remoteDataSource.updateSettlementStatus(
        settlementId: settlementId,
        status: status,
        paymentProofUrl: paymentProofUrl,
      );
    } catch (e) {
      throw Exception('Failed to update settlement: $e');
    }
  }
}
