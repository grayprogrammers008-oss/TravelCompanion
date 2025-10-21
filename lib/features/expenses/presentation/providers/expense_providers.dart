import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../shared/models/expense_model.dart';
import '../../data/datasources/expense_remote_datasource.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/repositories/expense_repository.dart';

// Remote Data Source Provider
final expenseRemoteDataSourceProvider = Provider<ExpenseRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ExpenseRemoteDataSource(supabaseClient);
});

// Repository Provider
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final remoteDataSource = ref.watch(expenseRemoteDataSourceProvider);
  return ExpenseRepositoryImpl(remoteDataSource);
});

// User Expenses Provider (all expenses for current user)
final userExpensesProvider = FutureProvider<List<ExpenseWithSplits>>((
  ref,
) async {
  try {
    final repository = ref.watch(expenseRepositoryProvider);
    final expenses = await repository.getUserExpenses().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('⏱️ userExpensesProvider timeout - returning empty list');
        return <ExpenseWithSplits>[];
      },
    );
    print('✅ userExpensesProvider fetched ${expenses.length} expenses');
    return expenses;
  } catch (e) {
    // Log the error for debugging
    print('❌ userExpensesProvider error: $e');
    // Return empty list instead of throwing to show empty state
    // This allows the UI to show the empty state instead of hanging
    return <ExpenseWithSplits>[];
  }
});

// Standalone Expenses Provider
final standaloneExpensesProvider = FutureProvider<List<ExpenseWithSplits>>((
  ref,
) async {
  try {
    final repository = ref.watch(expenseRepositoryProvider);
    final expenses = await repository.getStandaloneExpenses().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('⏱️ standaloneExpensesProvider timeout - returning empty list');
        return <ExpenseWithSplits>[];
      },
    );
    print('✅ standaloneExpensesProvider fetched ${expenses.length} expenses');
    return expenses;
  } catch (e) {
    print('❌ standaloneExpensesProvider error: $e');
    // Return empty list instead of throwing to show empty state
    return <ExpenseWithSplits>[];
  }
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
  final currentUserId = SupabaseClientWrapper.currentUserId;
  return await repository.getBalances(userId: currentUserId);
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
