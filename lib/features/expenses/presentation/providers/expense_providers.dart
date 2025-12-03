import 'package:flutter/foundation.dart';
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

// User Expenses Provider (all expenses for current user) - REAL-TIME
final userExpensesProvider = StreamProvider<List<ExpenseWithSplits>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.watchUserExpenses();
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
        if (kDebugMode) {
          debugPrint('⏱️ standaloneExpensesProvider timeout - returning empty list');
        }
        return <ExpenseWithSplits>[];
      },
    );
    if (kDebugMode) {
      debugPrint('✅ standaloneExpensesProvider fetched ${expenses.length} expenses');
    }
    return expenses;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ standaloneExpensesProvider error: $e');
    }
    // Return empty list instead of throwing to show empty state
    return <ExpenseWithSplits>[];
  }
});

// Trip Expenses Provider - REAL-TIME
final tripExpensesProvider = StreamProvider.family<List<ExpenseWithSplits>, String>(
  (ref, tripId) {
    final repository = ref.watch(expenseRepositoryProvider);
    return repository.watchTripExpenses(tripId);
  },
);

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

/// Provider to calculate member frequency based on expense splits for a trip
/// Returns a Map<String, int> where key is userId and value is the count of expenses they were split with
final memberFrequencyProvider = FutureProvider.family<Map<String, int>, String>((ref, tripId) async {
  try {
    final expensesAsync = await ref.watch(tripExpensesProvider(tripId).future);

    // Count how many times each member appears in expense splits
    final frequencyMap = <String, int>{};

    for (final expenseWithSplits in expensesAsync) {
      for (final split in expenseWithSplits.splits) {
        frequencyMap[split.userId] = (frequencyMap[split.userId] ?? 0) + 1;
      }
    }

    return frequencyMap;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ memberFrequencyProvider error: $e');
    }
    return <String, int>{};
  }
});

/// Expense Summary Model for dashboard display
class ExpenseSummary {
  final double totalPersonal;
  final double totalTrip;
  final double totalAll;
  final int personalCount;
  final int tripCount;
  final Map<String, double> categoryBreakdown;
  final double thisMonthSpending;
  final double lastMonthSpending;

  ExpenseSummary({
    required this.totalPersonal,
    required this.totalTrip,
    required this.totalAll,
    required this.personalCount,
    required this.tripCount,
    required this.categoryBreakdown,
    required this.thisMonthSpending,
    required this.lastMonthSpending,
  });

  /// Get percentage change from last month
  double get monthlyChange {
    if (lastMonthSpending == 0) return thisMonthSpending > 0 ? 100 : 0;
    return ((thisMonthSpending - lastMonthSpending) / lastMonthSpending) * 100;
  }

  /// Get the top spending category
  String? get topCategory {
    if (categoryBreakdown.isEmpty) return null;
    return categoryBreakdown.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}

/// Provider for expense summary (dashboard stats)
final expenseSummaryProvider = FutureProvider<ExpenseSummary>((ref) async {
  try {
    final expenses = await ref.watch(userExpensesProvider.future);

    double totalPersonal = 0;
    double totalTrip = 0;
    int personalCount = 0;
    int tripCount = 0;
    final categoryBreakdown = <String, double>{};
    double thisMonthSpending = 0;
    double lastMonthSpending = 0;

    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = thisMonthStart.subtract(const Duration(days: 1));

    for (final expenseWithSplits in expenses) {
      final expense = expenseWithSplits.expense;
      final amount = expense.amount;

      // Personal vs Trip
      if (expense.tripId == null) {
        totalPersonal += amount;
        personalCount++;
      } else {
        totalTrip += amount;
        tripCount++;
      }

      // Category breakdown
      final category = expense.category ?? 'other';
      categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + amount;

      // Monthly comparison
      final transactionDate = expense.transactionDate ?? expense.createdAt;
      if (transactionDate != null) {
        if (transactionDate.isAfter(thisMonthStart) ||
            transactionDate.isAtSameMomentAs(thisMonthStart)) {
          thisMonthSpending += amount;
        } else if (transactionDate.isAfter(lastMonthStart) &&
                   transactionDate.isBefore(lastMonthEnd.add(const Duration(days: 1)))) {
          lastMonthSpending += amount;
        }
      }
    }

    return ExpenseSummary(
      totalPersonal: totalPersonal,
      totalTrip: totalTrip,
      totalAll: totalPersonal + totalTrip,
      personalCount: personalCount,
      tripCount: tripCount,
      categoryBreakdown: categoryBreakdown,
      thisMonthSpending: thisMonthSpending,
      lastMonthSpending: lastMonthSpending,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ expenseSummaryProvider error: $e');
    }
    return ExpenseSummary(
      totalPersonal: 0,
      totalTrip: 0,
      totalAll: 0,
      personalCount: 0,
      tripCount: 0,
      categoryBreakdown: {},
      thisMonthSpending: 0,
      lastMonthSpending: 0,
    );
  }
});
