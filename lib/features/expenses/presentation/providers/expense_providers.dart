import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/expense_model.dart';
import '../../data/datasources/expense_local_datasource.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

// Data Source Provider
final expenseLocalDataSourceProvider = Provider<ExpenseLocalDataSource>((ref) {
  final dataSource = ExpenseLocalDataSource();
  final authDataSource = ref.watch(authLocalDataSourceProvider);
  dataSource.setCurrentUserId(authDataSource.currentUserId);
  return dataSource;
});

// Repository Provider
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final dataSource = ref.watch(expenseLocalDataSourceProvider);
  return ExpenseRepositoryImpl(dataSource);
});

// User Expenses Provider (all expenses for current user)
final userExpensesProvider = FutureProvider<List<ExpenseWithSplits>>((
  ref,
) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return await repository.getUserExpenses();
});

// Standalone Expenses Provider
final standaloneExpensesProvider = FutureProvider<List<ExpenseWithSplits>>((
  ref,
) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return await repository.getStandaloneExpenses();
});

// Trip Expenses Provider
final tripExpensesProvider =
    FutureProvider.family<List<ExpenseWithSplits>, String>((ref, tripId) async {
      final repository = ref.watch(expenseRepositoryProvider);
      return await repository.getTripExpenses(tripId);
    });

// Single Expense Provider
final expenseProvider = FutureProvider.family<ExpenseWithSplits, String>((
  ref,
  expenseId,
) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return await repository.getExpenseById(expenseId);
});

// Balances Provider (trip or user)
final balancesProvider =
    FutureProvider.family<
      List<BalanceSummary>,
      ({String? tripId, String? userId})
    >((ref, params) async {
      final repository = ref.watch(expenseRepositoryProvider);
      return await repository.getBalances(
        tripId: params.tripId,
        userId: params.userId,
      );
    });

// Trip Balances Provider (convenience)
final tripBalancesProvider =
    FutureProvider.family<List<BalanceSummary>, String>((ref, tripId) async {
      final repository = ref.watch(expenseRepositoryProvider);
      return await repository.getBalances(tripId: tripId);
    });

// User Balances Provider (standalone expenses)
final userBalancesProvider = FutureProvider<List<BalanceSummary>>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final authDataSource = ref.watch(authLocalDataSourceProvider);
  return await repository.getBalances(userId: authDataSource.currentUserId);
});

// Settlements Provider (trip or user)
final settlementsProvider =
    FutureProvider.family<
      List<SettlementModel>,
      ({String? tripId, String? userId})
    >((ref, params) async {
      final repository = ref.watch(expenseRepositoryProvider);
      return await repository.getSettlements(
        tripId: params.tripId,
        userId: params.userId,
      );
    });

// Trip Settlements Provider (convenience)
final tripSettlementsProvider =
    FutureProvider.family<List<SettlementModel>, String>((ref, tripId) async {
      final repository = ref.watch(expenseRepositoryProvider);
      return await repository.getSettlements(tripId: tripId);
    });

// Expense Controller State
class ExpenseState {
  final bool isLoading;
  final String? error;

  ExpenseState({this.isLoading = false, this.error});

  ExpenseState copyWith({bool? isLoading, String? error}) {
    return ExpenseState(isLoading: isLoading ?? this.isLoading, error: error);
  }
}

// Expense Controller
class ExpenseController extends Notifier<ExpenseState> {
  late final ExpenseRepository _repository;

  @override
  ExpenseState build() {
    _repository = ref.read(expenseRepositoryProvider);
    return ExpenseState();
  }

  /// Create expense (supports standalone)
  Future<ExpenseModel> createExpense({
    String? tripId, // Optional for standalone
    required String title,
    String? description,
    required double amount,
    String? category,
    required String paidBy,
    required List<String> splitWith,
    DateTime? transactionDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final expense = await _repository.createExpense(
        tripId: tripId,
        title: title,
        description: description,
        amount: amount,
        category: category,
        paidBy: paidBy,
        splitWith: splitWith,
        transactionDate: transactionDate,
      );
      state = state.copyWith(isLoading: false);
      return expense;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Update expense
  Future<ExpenseModel> updateExpense({
    required String expenseId,
    String? title,
    String? description,
    double? amount,
    String? category,
    DateTime? transactionDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final expense = await _repository.updateExpense(
        expenseId: expenseId,
        title: title,
        description: description,
        amount: amount,
        category: category,
        transactionDate: transactionDate,
      );
      state = state.copyWith(isLoading: false);
      return expense;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Delete expense
  Future<void> deleteExpense(String expenseId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteExpense(expenseId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Create settlement (supports standalone)
  Future<SettlementModel> createSettlement({
    String? tripId, // Optional for standalone
    required String fromUser,
    required String toUser,
    required double amount,
    String? paymentMethod,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final settlement = await _repository.createSettlement(
        tripId: tripId,
        fromUser: fromUser,
        toUser: toUser,
        amount: amount,
        paymentMethod: paymentMethod,
      );
      state = state.copyWith(isLoading: false);
      return settlement;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Update settlement status
  Future<SettlementModel> updateSettlementStatus({
    required String settlementId,
    required String status,
    String? paymentProofUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final settlement = await _repository.updateSettlementStatus(
        settlementId: settlementId,
        status: status,
        paymentProofUrl: paymentProofUrl,
      );
      state = state.copyWith(isLoading: false);
      return settlement;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

// Expense Controller Provider
final expenseControllerProvider =
    NotifierProvider<ExpenseController, ExpenseState>(() {
      return ExpenseController();
    });
