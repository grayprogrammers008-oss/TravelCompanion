// Hand-rolled (no mockito codegen) tests for expense Riverpod providers and
// the ExpenseController action notifier.
//
// We override `expenseRepositoryProvider` with a fake that records calls and
// returns canned values, so we can drive the providers without touching
// Supabase. Network-bound providers that pull `SupabaseClientWrapper.currentUserId`
// (i.e. `userBalancesProvider`) are exercised only through the repository
// fake's recorded calls; we don't try to mock the underlying SupabaseClient
// for those — see comments below.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pathio/features/expenses/domain/repositories/expense_repository.dart';
import 'package:pathio/features/expenses/presentation/providers/expense_providers.dart';
import 'package:pathio/shared/models/expense_model.dart';

/// Hand-rolled fake repository — implements every method by recording
/// invocations and returning canned values. Tests don't need every behavior,
/// so unused methods just return harmless defaults.
class _FakeExpenseRepository implements ExpenseRepository {
  // ---- Canned outputs ----
  List<ExpenseWithSplits> userExpenses = const [];
  List<ExpenseWithSplits> tripExpenses = const [];
  List<ExpenseWithSplits> standaloneExpenses = const [];
  ExpenseWithSplits? expenseById;
  List<BalanceSummary> balances = const [];
  List<SettlementModel> settlements = const [];
  ExpenseModel? createExpenseResult;
  ExpenseModel? updateExpenseResult;
  SettlementModel? createSettlementResult;
  SettlementModel? updateSettlementResult;

  // ---- Optional errors ----
  Object? createExpenseError;
  Object? updateExpenseError;
  Object? deleteExpenseError;
  Object? createSettlementError;
  Object? updateSettlementError;

  // ---- Streams ----
  StreamController<List<ExpenseWithSplits>>? userStream;
  StreamController<List<ExpenseWithSplits>>? tripStream;

  // ---- Recorded calls ----
  int getUserExpensesCount = 0;
  int getStandaloneExpensesCount = 0;
  int watchUserExpensesCount = 0;
  final List<String> getTripExpensesCalls = [];
  final List<String> watchTripExpensesCalls = [];
  final List<String> getExpenseByIdCalls = [];
  final List<Map<String, dynamic>> createExpenseCalls = [];
  final List<Map<String, dynamic>> updateExpenseCalls = [];
  final List<String> deleteExpenseCalls = [];
  final List<Map<String, String?>> getBalancesCalls = [];
  final List<Map<String, dynamic>> createSettlementCalls = [];
  final List<Map<String, String?>> getSettlementsCalls = [];
  final List<Map<String, dynamic>> updateSettlementCalls = [];

  @override
  Future<List<ExpenseWithSplits>> getUserExpenses() async {
    getUserExpensesCount++;
    return userExpenses;
  }

  @override
  Future<List<ExpenseWithSplits>> getTripExpenses(String tripId) async {
    getTripExpensesCalls.add(tripId);
    return tripExpenses;
  }

  @override
  Future<List<ExpenseWithSplits>> getStandaloneExpenses() async {
    getStandaloneExpensesCount++;
    return standaloneExpenses;
  }

  @override
  Future<ExpenseWithSplits> getExpenseById(String expenseId) async {
    getExpenseByIdCalls.add(expenseId);
    final r = expenseById;
    if (r == null) throw StateError('expenseById not set on fake');
    return r;
  }

  @override
  Future<ExpenseModel> createExpense({
    String? tripId,
    required String title,
    String? description,
    required double amount,
    String? category,
    required String paidBy,
    required List<String> splitWith,
    String splitType = 'equal',
    DateTime? transactionDate,
  }) async {
    createExpenseCalls.add({
      'tripId': tripId,
      'title': title,
      'description': description,
      'amount': amount,
      'category': category,
      'paidBy': paidBy,
      'splitWith': splitWith,
      'splitType': splitType,
      'transactionDate': transactionDate,
    });
    if (createExpenseError != null) throw createExpenseError!;
    final r = createExpenseResult;
    if (r == null) {
      throw StateError('createExpenseResult not set on fake');
    }
    return r;
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
    updateExpenseCalls.add({
      'expenseId': expenseId,
      'title': title,
      'description': description,
      'amount': amount,
      'category': category,
      'transactionDate': transactionDate,
    });
    if (updateExpenseError != null) throw updateExpenseError!;
    final r = updateExpenseResult;
    if (r == null) {
      throw StateError('updateExpenseResult not set on fake');
    }
    return r;
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    deleteExpenseCalls.add(expenseId);
    if (deleteExpenseError != null) throw deleteExpenseError!;
  }

  @override
  Future<List<BalanceSummary>> getBalances({
    String? tripId,
    String? userId,
  }) async {
    getBalancesCalls.add({'tripId': tripId, 'userId': userId});
    return balances;
  }

  @override
  Future<SettlementModel> createSettlement({
    String? tripId,
    required String fromUser,
    required String toUser,
    required double amount,
    String? paymentMethod,
  }) async {
    createSettlementCalls.add({
      'tripId': tripId,
      'fromUser': fromUser,
      'toUser': toUser,
      'amount': amount,
      'paymentMethod': paymentMethod,
    });
    if (createSettlementError != null) throw createSettlementError!;
    final r = createSettlementResult;
    if (r == null) {
      throw StateError('createSettlementResult not set on fake');
    }
    return r;
  }

  @override
  Future<List<SettlementModel>> getSettlements({
    String? tripId,
    String? userId,
  }) async {
    getSettlementsCalls.add({'tripId': tripId, 'userId': userId});
    return settlements;
  }

  @override
  Future<SettlementModel> updateSettlementStatus({
    required String settlementId,
    required String status,
    String? paymentProofUrl,
  }) async {
    updateSettlementCalls.add({
      'settlementId': settlementId,
      'status': status,
      'paymentProofUrl': paymentProofUrl,
    });
    if (updateSettlementError != null) throw updateSettlementError!;
    final r = updateSettlementResult;
    if (r == null) {
      throw StateError('updateSettlementResult not set on fake');
    }
    return r;
  }

  @override
  Stream<List<ExpenseWithSplits>> watchTripExpenses(String tripId) {
    watchTripExpensesCalls.add(tripId);
    final c = tripStream ??
        StreamController<List<ExpenseWithSplits>>.broadcast();
    tripStream = c;
    return c.stream;
  }

  @override
  Stream<List<ExpenseWithSplits>> watchUserExpenses() {
    watchUserExpensesCount++;
    final c = userStream ??
        StreamController<List<ExpenseWithSplits>>.broadcast();
    userStream = c;
    return c.stream;
  }
}

ExpenseModel _expense({
  String id = 'e1',
  String? tripId,
  String title = 'Lunch',
  double amount = 100,
  String? category,
  String paidBy = 'user-1',
  String splitType = 'equal',
  DateTime? transactionDate,
  DateTime? createdAt,
}) {
  return ExpenseModel(
    id: id,
    tripId: tripId,
    title: title,
    amount: amount,
    category: category,
    paidBy: paidBy,
    splitType: splitType,
    transactionDate: transactionDate,
    createdAt: createdAt,
  );
}

ExpenseSplitModel _split({
  String id = 's1',
  String expenseId = 'e1',
  String userId = 'user-2',
  double amount = 50,
}) {
  return ExpenseSplitModel(
    id: id,
    expenseId: expenseId,
    userId: userId,
    amount: amount,
  );
}

ProviderContainer _container(_FakeExpenseRepository fake) {
  return ProviderContainer(
    overrides: [
      expenseRepositoryProvider.overrideWithValue(fake),
    ],
  );
}

void main() {
  group('userExpensesProvider (StreamProvider)', () {
    test('emits values from repository.watchUserExpenses', () async {
      final fake = _FakeExpenseRepository();
      final c = _container(fake);
      addTearDown(c.dispose);

      // Subscribe so the StreamProvider becomes active.
      final sub = c.listen(userExpensesProvider, (_, __) {});
      addTearDown(sub.close);

      // Now the controller exists and is hooked up.
      expect(fake.watchUserExpensesCount, 1);
      // Start emitting to the stream.
      final exp = ExpenseWithSplits(
        expense: _expense(),
        splits: const [],
      );
      fake.userStream!.add([exp]);
      final result = await c.read(userExpensesProvider.future);
      expect(result, hasLength(1));
      expect(result.first.expense.id, 'e1');
    });
  });

  group('tripExpensesProvider (family StreamProvider)', () {
    test('forwards trip id and emits stream values', () async {
      final fake = _FakeExpenseRepository();
      final c = _container(fake);
      addTearDown(c.dispose);

      final sub = c.listen(tripExpensesProvider('trip-1'), (_, __) {});
      addTearDown(sub.close);

      expect(fake.watchTripExpensesCalls, ['trip-1']);

      fake.tripStream!.add([
        ExpenseWithSplits(expense: _expense(tripId: 'trip-1'), splits: const []),
      ]);
      final result = await c.read(tripExpensesProvider('trip-1').future);
      expect(result, hasLength(1));
      expect(result.first.expense.tripId, 'trip-1');
    });
  });

  group('standaloneExpensesProvider', () {
    test('returns empty list when repository throws (catches and recovers)',
        () async {
      final fake = _FakeExpenseRepository();
      // Force the repository call to throw via a future that already failed.
      fake.standaloneExpenses = const [];
      final c = ProviderContainer(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(_ThrowingRepo()),
        ],
      );
      addTearDown(c.dispose);

      final result = await c.read(standaloneExpensesProvider.future);
      expect(result, isEmpty);
    });

    test('returns standalone expenses from repository', () async {
      final fake = _FakeExpenseRepository()
        ..standaloneExpenses = [
          ExpenseWithSplits(expense: _expense(id: 'a'), splits: const []),
        ];
      final c = _container(fake);
      addTearDown(c.dispose);

      final result = await c.read(standaloneExpensesProvider.future);
      expect(result, hasLength(1));
      expect(result.first.expense.id, 'a');
      expect(fake.getStandaloneExpensesCount, 1);
    });
  });

  group('expenseProvider (family by id)', () {
    test('forwards id and returns expense from repository', () async {
      final fake = _FakeExpenseRepository()
        ..expenseById = ExpenseWithSplits(
          expense: _expense(id: 'x'),
          splits: const [],
        );
      final c = _container(fake);
      addTearDown(c.dispose);

      final r = await c.read(expenseProvider('x').future);
      expect(r.expense.id, 'x');
      expect(fake.getExpenseByIdCalls, ['x']);
    });
  });

  group('balancesProvider (family on (tripId, userId))', () {
    test('forwards tripId only', () async {
      final fake = _FakeExpenseRepository()
        ..balances = [
          BalanceSummary(
            userId: 'u1',
            userName: 'U1',
            totalPaid: 100,
            totalOwed: 50,
            balance: 50,
          ),
        ];
      final c = _container(fake);
      addTearDown(c.dispose);

      final r = await c.read(
        balancesProvider((tripId: 't1', userId: null)).future,
      );
      expect(r, hasLength(1));
      expect(fake.getBalancesCalls, [
        {'tripId': 't1', 'userId': null},
      ]);
    });

    test('forwards userId only', () async {
      final fake = _FakeExpenseRepository();
      final c = _container(fake);
      addTearDown(c.dispose);

      await c.read(
        balancesProvider((tripId: null, userId: 'u1')).future,
      );
      expect(fake.getBalancesCalls, [
        {'tripId': null, 'userId': 'u1'},
      ]);
    });
  });

  group('tripBalancesProvider', () {
    test('forwards tripId only (userId always null)', () async {
      final fake = _FakeExpenseRepository();
      final c = _container(fake);
      addTearDown(c.dispose);

      await c.read(tripBalancesProvider('trip-42').future);
      expect(fake.getBalancesCalls, [
        {'tripId': 'trip-42', 'userId': null},
      ]);
    });
  });

  group('settlementsProvider (family on (tripId, userId))', () {
    test('forwards both null and a tripId', () async {
      final fake = _FakeExpenseRepository();
      final c = _container(fake);
      addTearDown(c.dispose);

      await c.read(
        settlementsProvider((tripId: 't1', userId: null)).future,
      );
      await c.read(
        settlementsProvider((tripId: null, userId: 'u1')).future,
      );
      expect(fake.getSettlementsCalls, [
        {'tripId': 't1', 'userId': null},
        {'tripId': null, 'userId': 'u1'},
      ]);
    });
  });

  group('tripSettlementsProvider', () {
    test('forwards trip id', () async {
      final fake = _FakeExpenseRepository();
      final c = _container(fake);
      addTearDown(c.dispose);

      await c.read(tripSettlementsProvider('trip-1').future);
      expect(fake.getSettlementsCalls.first['tripId'], 'trip-1');
    });
  });

  group('memberFrequencyProvider', () {
    test('counts split occurrences per user across trip expenses', () async {
      final fake = _FakeExpenseRepository();
      final c = _container(fake);
      addTearDown(c.dispose);

      // Wire up the trip stream and emit expenses. We need a listener so the
      // stream is activated.
      final sub = c.listen(tripExpensesProvider('t1'), (_, __) {});
      addTearDown(sub.close);

      final expense1 = ExpenseWithSplits(
        expense: _expense(id: 'e1', tripId: 't1'),
        splits: [
          _split(id: 's1', userId: 'u1'),
          _split(id: 's2', userId: 'u2'),
        ],
      );
      final expense2 = ExpenseWithSplits(
        expense: _expense(id: 'e2', tripId: 't1'),
        splits: [
          _split(id: 's3', userId: 'u1'),
          _split(id: 's4', userId: 'u3'),
        ],
      );
      fake.tripStream!.add([expense1, expense2]);
      // Wait for the stream value to propagate.
      await c.read(tripExpensesProvider('t1').future);

      final freq = await c.read(memberFrequencyProvider('t1').future);
      expect(freq, {'u1': 2, 'u2': 1, 'u3': 1});
    });

    test('returns empty map when no expenses', () async {
      final fake = _FakeExpenseRepository();
      final c = _container(fake);
      addTearDown(c.dispose);

      final sub = c.listen(tripExpensesProvider('t1'), (_, __) {});
      addTearDown(sub.close);
      fake.tripStream!.add(const []);
      await c.read(tripExpensesProvider('t1').future);

      final freq = await c.read(memberFrequencyProvider('t1').future);
      expect(freq, isEmpty);
    });
  });

  group('expenseSummaryProvider', () {
    test('aggregates personal vs trip totals and category breakdown',
        () async {
      final fake = _FakeExpenseRepository();
      final c = _container(fake);
      addTearDown(c.dispose);

      // Activate the user expenses stream.
      final sub = c.listen(userExpensesProvider, (_, __) {});
      addTearDown(sub.close);

      final now = DateTime.now();
      final personal = ExpenseWithSplits(
        expense: _expense(
          id: 'p1',
          tripId: null,
          amount: 100,
          category: 'food',
          createdAt: now,
        ),
        splits: const [],
      );
      final trip = ExpenseWithSplits(
        expense: _expense(
          id: 't1',
          tripId: 'trip-1',
          amount: 200,
          category: 'travel',
          createdAt: now,
        ),
        splits: const [],
      );
      fake.userStream!.add([personal, trip]);
      await c.read(userExpensesProvider.future);

      final summary = await c.read(expenseSummaryProvider.future);
      expect(summary.totalPersonal, 100);
      expect(summary.totalTrip, 200);
      expect(summary.totalAll, 300);
      expect(summary.personalCount, 1);
      expect(summary.tripCount, 1);
      expect(summary.categoryBreakdown, {'food': 100, 'travel': 200});
    });

    test('uses "other" category when expense category is null', () async {
      final fake = _FakeExpenseRepository();
      final c = _container(fake);
      addTearDown(c.dispose);

      final sub = c.listen(userExpensesProvider, (_, __) {});
      addTearDown(sub.close);

      fake.userStream!.add([
        ExpenseWithSplits(
          expense: _expense(amount: 50, category: null, createdAt: DateTime.now()),
          splits: const [],
        ),
      ]);
      await c.read(userExpensesProvider.future);

      final summary = await c.read(expenseSummaryProvider.future);
      expect(summary.categoryBreakdown, {'other': 50});
      expect(summary.topCategory, 'other');
    });

    // SKIPPED: `expenseSummaryProvider`'s catch-all fallback path is difficult
    // to drive deterministically because the provider awaits the upstream
    // `userExpensesProvider.future`, and Riverpod's stream-to-future
    // resolution doesn't surface a controller-level `addError(...)` to the
    // future in a way that completes synchronously enough for a test to
    // rendezvous on. Verifying this would either require restructuring the
    // provider to take an injected error path, or using fake_async — neither
    // worth the complexity for one branch.

    test('topCategory is null when categoryBreakdown is empty', () {
      final s = ExpenseSummary(
        totalPersonal: 0,
        totalTrip: 0,
        totalAll: 0,
        personalCount: 0,
        tripCount: 0,
        categoryBreakdown: const {},
        thisMonthSpending: 0,
        lastMonthSpending: 0,
      );
      expect(s.topCategory, isNull);
    });

    test('topCategory returns the highest-spend category', () {
      final s = ExpenseSummary(
        totalPersonal: 0,
        totalTrip: 0,
        totalAll: 0,
        personalCount: 0,
        tripCount: 0,
        categoryBreakdown: const {'food': 100, 'travel': 250, 'misc': 50},
        thisMonthSpending: 0,
        lastMonthSpending: 0,
      );
      expect(s.topCategory, 'travel');
    });

    test('monthlyChange returns 100 when last month is zero and this >0', () {
      final s = ExpenseSummary(
        totalPersonal: 0,
        totalTrip: 0,
        totalAll: 0,
        personalCount: 0,
        tripCount: 0,
        categoryBreakdown: const {},
        thisMonthSpending: 100,
        lastMonthSpending: 0,
      );
      expect(s.monthlyChange, 100);
    });

    test('monthlyChange returns 0 when both months are zero', () {
      final s = ExpenseSummary(
        totalPersonal: 0,
        totalTrip: 0,
        totalAll: 0,
        personalCount: 0,
        tripCount: 0,
        categoryBreakdown: const {},
        thisMonthSpending: 0,
        lastMonthSpending: 0,
      );
      expect(s.monthlyChange, 0);
    });

    test('monthlyChange computes percentage delta when both > 0', () {
      final s = ExpenseSummary(
        totalPersonal: 0,
        totalTrip: 0,
        totalAll: 0,
        personalCount: 0,
        tripCount: 0,
        categoryBreakdown: const {},
        thisMonthSpending: 150,
        lastMonthSpending: 100,
      );
      expect(s.monthlyChange, 50.0);
    });
  });

  group('ExpenseController', () {
    test('createExpense sets loading then clears on success', () async {
      final fake = _FakeExpenseRepository()
        ..createExpenseResult = _expense(id: 'new');
      final c = _container(fake);
      addTearDown(c.dispose);

      final ctrl = c.read(expenseControllerProvider.notifier);
      final result = await ctrl.createExpense(
        title: 'New',
        amount: 100,
        paidBy: 'user-1',
        splitWith: const ['user-1', 'user-2'],
      );
      expect(result.id, 'new');
      expect(fake.createExpenseCalls, hasLength(1));
      // Note: `splitType` is not part of the controller's parameters; the
      // controller forwards via the named-defaulted `splitType` of the repo.
      final state = c.read(expenseControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('createExpense surfaces error and rethrows on failure', () async {
      final fake = _FakeExpenseRepository()
        ..createExpenseError = Exception('oops');
      final c = _container(fake);
      addTearDown(c.dispose);

      final ctrl = c.read(expenseControllerProvider.notifier);
      await expectLater(
        () => ctrl.createExpense(
          title: 'X',
          amount: 10,
          paidBy: 'u1',
          splitWith: const ['u1'],
        ),
        throwsA(isA<Exception>()),
      );
      final state = c.read(expenseControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, contains('oops'));
    });

    test('updateExpense forwards args and clears state on success', () async {
      final fake = _FakeExpenseRepository()
        ..updateExpenseResult = _expense(title: 'updated');
      final c = _container(fake);
      addTearDown(c.dispose);

      final ctrl = c.read(expenseControllerProvider.notifier);
      final r = await ctrl.updateExpense(
        expenseId: 'e1',
        title: 'updated',
        amount: 200,
      );
      expect(r.title, 'updated');
      expect(fake.updateExpenseCalls.first['expenseId'], 'e1');
      expect(fake.updateExpenseCalls.first['title'], 'updated');
      expect(fake.updateExpenseCalls.first['amount'], 200);
      expect(c.read(expenseControllerProvider).error, isNull);
    });

    test('updateExpense surfaces error on failure', () async {
      final fake = _FakeExpenseRepository()
        ..updateExpenseError = Exception('bad-update');
      final c = _container(fake);
      addTearDown(c.dispose);

      final ctrl = c.read(expenseControllerProvider.notifier);
      await expectLater(
        () => ctrl.updateExpense(expenseId: 'e1', title: 'x'),
        throwsA(isA<Exception>()),
      );
      expect(c.read(expenseControllerProvider).error, contains('bad-update'));
    });

    test('deleteExpense forwards id and clears state on success', () async {
      final fake = _FakeExpenseRepository();
      final c = _container(fake);
      addTearDown(c.dispose);

      final ctrl = c.read(expenseControllerProvider.notifier);
      await ctrl.deleteExpense('e1');
      expect(fake.deleteExpenseCalls, ['e1']);
      expect(c.read(expenseControllerProvider).error, isNull);
    });

    test('deleteExpense surfaces error on failure', () async {
      final fake = _FakeExpenseRepository()
        ..deleteExpenseError = Exception('cannot-delete');
      final c = _container(fake);
      addTearDown(c.dispose);

      final ctrl = c.read(expenseControllerProvider.notifier);
      await expectLater(
        () => ctrl.deleteExpense('e1'),
        throwsA(isA<Exception>()),
      );
      expect(c.read(expenseControllerProvider).error, contains('cannot-delete'));
    });

    test('createSettlement forwards args and clears state on success',
        () async {
      final fake = _FakeExpenseRepository()
        ..createSettlementResult = SettlementModel(
          id: 's1',
          fromUser: 'a',
          toUser: 'b',
          amount: 50,
        );
      final c = _container(fake);
      addTearDown(c.dispose);

      final ctrl = c.read(expenseControllerProvider.notifier);
      final r = await ctrl.createSettlement(
        fromUser: 'a',
        toUser: 'b',
        amount: 50,
        paymentMethod: 'cash',
      );
      expect(r.id, 's1');
      expect(fake.createSettlementCalls.first['fromUser'], 'a');
      expect(fake.createSettlementCalls.first['toUser'], 'b');
      expect(fake.createSettlementCalls.first['amount'], 50);
      expect(fake.createSettlementCalls.first['paymentMethod'], 'cash');
      expect(c.read(expenseControllerProvider).error, isNull);
    });

    test('createSettlement surfaces error on failure', () async {
      final fake = _FakeExpenseRepository()
        ..createSettlementError = Exception('settle-fail');
      final c = _container(fake);
      addTearDown(c.dispose);

      final ctrl = c.read(expenseControllerProvider.notifier);
      await expectLater(
        () => ctrl.createSettlement(
          fromUser: 'a',
          toUser: 'b',
          amount: 10,
        ),
        throwsA(isA<Exception>()),
      );
      expect(c.read(expenseControllerProvider).error, contains('settle-fail'));
    });

    test('updateSettlementStatus forwards args and clears state', () async {
      final fake = _FakeExpenseRepository()
        ..updateSettlementResult = SettlementModel(
          id: 's1',
          fromUser: 'a',
          toUser: 'b',
          amount: 10,
          status: 'confirmed',
        );
      final c = _container(fake);
      addTearDown(c.dispose);

      final ctrl = c.read(expenseControllerProvider.notifier);
      final r = await ctrl.updateSettlementStatus(
        settlementId: 's1',
        status: 'confirmed',
        paymentProofUrl: 'http://proof',
      );
      expect(r.status, 'confirmed');
      expect(fake.updateSettlementCalls.first['settlementId'], 's1');
      expect(fake.updateSettlementCalls.first['status'], 'confirmed');
      expect(
        fake.updateSettlementCalls.first['paymentProofUrl'],
        'http://proof',
      );
    });

    test('updateSettlementStatus surfaces error on failure', () async {
      final fake = _FakeExpenseRepository()
        ..updateSettlementError = Exception('update-fail');
      final c = _container(fake);
      addTearDown(c.dispose);

      final ctrl = c.read(expenseControllerProvider.notifier);
      await expectLater(
        () => ctrl.updateSettlementStatus(
          settlementId: 's1',
          status: 'cancelled',
        ),
        throwsA(isA<Exception>()),
      );
      expect(c.read(expenseControllerProvider).error, contains('update-fail'));
    });
  });

  // NOTE: `userBalancesProvider` reads `SupabaseClientWrapper.currentUserId`
  // directly (a static singleton). Without initializing Supabase, accessing
  // this getter would throw. We deliberately do NOT test it here — it would
  // require initializing Supabase or substantially refactoring the prod code
  // to pass the user id through Riverpod.
}

/// Repository whose every method throws — used to verify recovery behavior in
/// `standaloneExpensesProvider`.
class _ThrowingRepo implements ExpenseRepository {
  @override
  Future<ExpenseModel> createExpense({
    String? tripId,
    required String title,
    String? description,
    required double amount,
    String? category,
    required String paidBy,
    required List<String> splitWith,
    String splitType = 'equal',
    DateTime? transactionDate,
  }) async {
    throw Exception('boom');
  }

  @override
  Future<SettlementModel> createSettlement({
    String? tripId,
    required String fromUser,
    required String toUser,
    required double amount,
    String? paymentMethod,
  }) async => throw Exception('boom');

  @override
  Future<void> deleteExpense(String expenseId) async => throw Exception('boom');

  @override
  Future<List<BalanceSummary>> getBalances({
    String? tripId,
    String? userId,
  }) async => throw Exception('boom');

  @override
  Future<ExpenseWithSplits> getExpenseById(String expenseId) async =>
      throw Exception('boom');

  @override
  Future<List<SettlementModel>> getSettlements({
    String? tripId,
    String? userId,
  }) async => throw Exception('boom');

  @override
  Future<List<ExpenseWithSplits>> getStandaloneExpenses() async =>
      throw Exception('boom');

  @override
  Future<List<ExpenseWithSplits>> getTripExpenses(String tripId) async =>
      throw Exception('boom');

  @override
  Future<List<ExpenseWithSplits>> getUserExpenses() async =>
      throw Exception('boom');

  @override
  Future<ExpenseModel> updateExpense({
    required String expenseId,
    String? title,
    String? description,
    double? amount,
    String? category,
    DateTime? transactionDate,
  }) async => throw Exception('boom');

  @override
  Future<SettlementModel> updateSettlementStatus({
    required String settlementId,
    required String status,
    String? paymentProofUrl,
  }) async => throw Exception('boom');

  @override
  Stream<List<ExpenseWithSplits>> watchTripExpenses(String tripId) =>
      Stream<List<ExpenseWithSplits>>.error(Exception('boom'));

  @override
  Stream<List<ExpenseWithSplits>> watchUserExpenses() =>
      Stream<List<ExpenseWithSplits>>.error(Exception('boom'));
}

