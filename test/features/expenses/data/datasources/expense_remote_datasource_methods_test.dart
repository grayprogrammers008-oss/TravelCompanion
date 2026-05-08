import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:travel_crew/features/expenses/data/datasources/expense_queries.dart';
import 'package:travel_crew/features/expenses/data/datasources/expense_remote_datasource.dart';

/// Comprehensive unit tests for [ExpenseRemoteDataSource].
///
/// All Supabase chain calls go through [ExpenseQueries] which is faked here.
/// We exercise every public method on the happy path AND the error path,
/// asserting the args passed to the queries layer and the model returned.
///
/// The realtime stream methods (`watchTripExpenses` / `watchUserExpenses`)
/// hit `_client.channel(...)` directly — they are intentionally NOT covered
/// here.

class _FakeQueries implements ExpenseQueries {
  // ---- recorded args ----
  String? lastFindPaidByUserId;
  String? lastFindSplitIdsUserId;
  List<String>? lastFindByIdsIds;
  String? lastFindByIdsUserId;
  String? lastFindForTripTripId;
  String? lastFindStandalonePaidByUserId;
  List<String>? lastFindStandaloneByIdsIds;
  String? lastFindStandaloneByIdsUserId;
  String? lastFindExpenseByIdId;
  Map<String, dynamic>? lastInsertExpenseData;
  List<Map<String, dynamic>>? lastInsertSplitsRows;
  String? lastUpdateExpenseId;
  Map<String, dynamic>? lastUpdateExpenseData;
  String? lastDeleteExpenseId;
  String? lastBalancesTripId;
  String? lastBalancesUserId;
  Map<String, dynamic>? lastInsertSettlementData;
  String? lastFindSettlementsTripId;
  String? lastFindSettlementsUserId;
  String? lastUpdateSettlementId;
  Map<String, dynamic>? lastUpdateSettlementData;

  // ---- canned responses ----
  List<Map<String, dynamic>> findPaidByResponse = const [];
  List<Map<String, dynamic>> findSplitIdsResponse = const [];
  List<Map<String, dynamic>> findByIdsResponse = const [];
  List<Map<String, dynamic>> findForTripResponse = const [];
  List<Map<String, dynamic>> findStandalonePaidByResponse = const [];
  List<Map<String, dynamic>> findStandaloneByIdsResponse = const [];
  Map<String, dynamic>? findExpenseByIdResponse;
  Map<String, dynamic>? insertExpenseResponse;
  Map<String, dynamic>? updateExpenseResponse;
  List<Map<String, dynamic>> findBalancesResponse = const [];
  Map<String, dynamic>? insertSettlementResponse;
  List<Map<String, dynamic>> findSettlementsResponse = const [];
  Map<String, dynamic>? updateSettlementResponse;

  // ---- error injection ----
  Object? throwOnFindPaidBy;
  Object? throwOnFindSplitIds;
  Object? throwOnFindByIds;
  Object? throwOnFindForTrip;
  Object? throwOnFindStandalonePaidBy;
  Object? throwOnFindStandaloneByIds;
  Object? throwOnFindExpenseById;
  Object? throwOnInsertExpense;
  Object? throwOnInsertSplits;
  Object? throwOnUpdateExpense;
  Object? throwOnDeleteExpense;
  Object? throwOnFindBalances;
  Object? throwOnInsertSettlement;
  Object? throwOnFindSettlements;
  Object? throwOnUpdateSettlement;

  @override
  Future<List<Map<String, dynamic>>> findExpensesPaidBy(String userId) async {
    if (throwOnFindPaidBy != null) throw throwOnFindPaidBy!;
    lastFindPaidByUserId = userId;
    return findPaidByResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findSplitExpenseIdsForUser(
      String userId) async {
    if (throwOnFindSplitIds != null) throw throwOnFindSplitIds!;
    lastFindSplitIdsUserId = userId;
    return findSplitIdsResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findExpensesByIdsNotPaidBy(
      List<String> ids, String userId) async {
    if (throwOnFindByIds != null) throw throwOnFindByIds!;
    lastFindByIdsIds = ids;
    lastFindByIdsUserId = userId;
    return findByIdsResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findExpensesForTrip(String tripId) async {
    if (throwOnFindForTrip != null) throw throwOnFindForTrip!;
    lastFindForTripTripId = tripId;
    return findForTripResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findStandaloneExpensesPaidBy(
      String userId) async {
    if (throwOnFindStandalonePaidBy != null) throw throwOnFindStandalonePaidBy!;
    lastFindStandalonePaidByUserId = userId;
    return findStandalonePaidByResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findStandaloneExpensesByIdsNotPaidBy(
      List<String> ids, String userId) async {
    if (throwOnFindStandaloneByIds != null) throw throwOnFindStandaloneByIds!;
    lastFindStandaloneByIdsIds = ids;
    lastFindStandaloneByIdsUserId = userId;
    return findStandaloneByIdsResponse;
  }

  @override
  Future<Map<String, dynamic>> findExpenseById(String expenseId) async {
    if (throwOnFindExpenseById != null) throw throwOnFindExpenseById!;
    lastFindExpenseByIdId = expenseId;
    return findExpenseByIdResponse ?? const {};
  }

  @override
  Future<Map<String, dynamic>> insertExpense(Map<String, dynamic> data) async {
    if (throwOnInsertExpense != null) throw throwOnInsertExpense!;
    lastInsertExpenseData = data;
    return insertExpenseResponse ?? data;
  }

  @override
  Future<void> insertExpenseSplits(List<Map<String, dynamic>> rows) async {
    if (throwOnInsertSplits != null) throw throwOnInsertSplits!;
    lastInsertSplitsRows = rows;
  }

  @override
  Future<Map<String, dynamic>> updateExpenseById(
      String expenseId, Map<String, dynamic> data) async {
    if (throwOnUpdateExpense != null) throw throwOnUpdateExpense!;
    lastUpdateExpenseId = expenseId;
    lastUpdateExpenseData = data;
    return updateExpenseResponse ?? const {};
  }

  @override
  Future<void> deleteExpenseById(String expenseId) async {
    if (throwOnDeleteExpense != null) throw throwOnDeleteExpense!;
    lastDeleteExpenseId = expenseId;
  }

  @override
  Future<List<Map<String, dynamic>>> findExpensesForBalances({
    String? tripId,
    String? userId,
  }) async {
    if (throwOnFindBalances != null) throw throwOnFindBalances!;
    lastBalancesTripId = tripId;
    lastBalancesUserId = userId;
    return findBalancesResponse;
  }

  @override
  Future<Map<String, dynamic>> insertSettlement(
      Map<String, dynamic> data) async {
    if (throwOnInsertSettlement != null) throw throwOnInsertSettlement!;
    lastInsertSettlementData = data;
    return insertSettlementResponse ?? data;
  }

  @override
  Future<List<Map<String, dynamic>>> findSettlements({
    String? tripId,
    String? userId,
  }) async {
    if (throwOnFindSettlements != null) throw throwOnFindSettlements!;
    lastFindSettlementsTripId = tripId;
    lastFindSettlementsUserId = userId;
    return findSettlementsResponse;
  }

  @override
  Future<Map<String, dynamic>> updateSettlementById(
      String settlementId, Map<String, dynamic> data) async {
    if (throwOnUpdateSettlement != null) throw throwOnUpdateSettlement!;
    lastUpdateSettlementId = settlementId;
    lastUpdateSettlementData = data;
    return updateSettlementResponse ?? const {};
  }
}

class _FakeSupabase extends Mock implements SupabaseClient {}

void main() {
  late _FakeQueries queries;
  late _FakeSupabase supabase;
  late ExpenseRemoteDataSource ds;
  final fixedClock = DateTime.utc(2024, 6, 1, 12, 0, 0);

  // Helpers --------------------------------------------------------------
  Map<String, dynamic> baseExpenseRow({
    String id = 'e-1',
    String? tripId,
    String paidBy = 'u-1',
    double amount = 100.0,
    String title = 'Lunch',
    Map<String, dynamic>? payer,
    List<Map<String, dynamic>>? splits,
    Map<String, dynamic>? trips,
  }) {
    return {
      'id': id,
      'trip_id': tripId,
      'title': title,
      'amount': amount,
      'paid_by': paidBy,
      'split_type': 'equal',
      'currency': 'INR',
      'transaction_date': fixedClock.toIso8601String(),
      'created_at': fixedClock.toIso8601String(),
      'updated_at': fixedClock.toIso8601String(),
      'expense_splits': splits ?? const <Map<String, dynamic>>[],
      'payer': payer,
      'trips': trips,
    };
  }

  Map<String, dynamic> baseSplitRow({
    String id = 's-1',
    String expenseId = 'e-1',
    String userId = 'u-2',
    double amount = 50.0,
    String? userName,
    String? avatarUrl,
  }) {
    return {
      'id': id,
      'expense_id': expenseId,
      'user_id': userId,
      'amount': amount,
      'is_settled': false,
      'created_at': fixedClock.toIso8601String(),
      'user': userName == null && avatarUrl == null
          ? null
          : {
              'id': userId,
              'full_name': userName,
              'avatar_url': avatarUrl,
            },
    };
  }

  Map<String, dynamic> baseSettlementRow({
    String id = 'st-1',
    String? tripId,
    String fromUser = 'u-1',
    String toUser = 'u-2',
    double amount = 25.0,
    String status = 'pending',
    Map<String, dynamic>? from,
    Map<String, dynamic>? to,
  }) {
    return {
      'id': id,
      'trip_id': tripId,
      'from_user': fromUser,
      'to_user': toUser,
      'amount': amount,
      'currency': 'INR',
      'status': status,
      'created_at': fixedClock.toIso8601String(),
      'from': from,
      'to': to,
    };
  }

  setUp(() {
    queries = _FakeQueries();
    supabase = _FakeSupabase();
    ds = ExpenseRemoteDataSource(
      supabase,
      queries: queries,
      clock: () => fixedClock,
    );
  });

  // -----------------------------------------------------------------
  group('getUserExpenses', () {
    test('returns only paid-by expenses when no splits found', () async {
      queries.findPaidByResponse = [
        baseExpenseRow(id: 'e-1', paidBy: 'u-1'),
      ];
      queries.findSplitIdsResponse = const [];

      final result = await ds.getUserExpenses('u-1');

      expect(queries.lastFindPaidByUserId, 'u-1');
      expect(queries.lastFindSplitIdsUserId, 'u-1');
      // No second-fetch when ids empty
      expect(queries.lastFindByIdsIds, isNull);
      expect(result, hasLength(1));
      expect(result.single.expense.id, 'e-1');
    });

    test('combines paid-by + split expenses when split ids present', () async {
      queries.findPaidByResponse = [
        baseExpenseRow(id: 'e-1', paidBy: 'u-1'),
      ];
      queries.findSplitIdsResponse = [
        {'expense_id': 'e-2'},
        {'expense_id': 'e-3'},
        {'expense_id': 'e-2'}, // duplicate to exercise toSet()
      ];
      queries.findByIdsResponse = [
        baseExpenseRow(id: 'e-2', paidBy: 'u-9'),
        baseExpenseRow(id: 'e-3', paidBy: 'u-9'),
      ];

      final result = await ds.getUserExpenses('u-1');

      expect(queries.lastFindByIdsIds, isNotNull);
      expect(queries.lastFindByIdsIds!.toSet(), {'e-2', 'e-3'});
      expect(queries.lastFindByIdsUserId, 'u-1');
      expect(result.map((r) => r.expense.id).toList(), ['e-1', 'e-2', 'e-3']);
    });

    test('parses payer name and split user info', () async {
      queries.findPaidByResponse = [
        baseExpenseRow(
          id: 'e-1',
          payer: {'full_name': 'Alice'},
          splits: [
            baseSplitRow(userName: 'Bob', avatarUrl: 'http://a/b.png'),
          ],
        ),
      ];

      final result = await ds.getUserExpenses('u-1');

      expect(result.single.expense.payerName, 'Alice');
      expect(result.single.splits.single.userName, 'Bob');
      expect(result.single.splits.single.avatarUrl, 'http://a/b.png');
    });

    test('wraps query errors with "Failed to get user expenses"', () async {
      queries.throwOnFindPaidBy = Exception('boom');
      await expectLater(
        ds.getUserExpenses('u-1'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to get user expenses'))),
      );
    });

    test('wraps split-fetch errors as well', () async {
      queries.findPaidByResponse = const [];
      queries.findSplitIdsResponse = [
        {'expense_id': 'e-2'},
      ];
      queries.throwOnFindByIds = Exception('boom');
      await expectLater(
        ds.getUserExpenses('u-1'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to get user expenses'))),
      );
    });
  });

  // -----------------------------------------------------------------
  group('getTripExpenses', () {
    test('passes trip id and maps results', () async {
      queries.findForTripResponse = [
        baseExpenseRow(id: 'e-1', tripId: 't-1'),
      ];
      final result = await ds.getTripExpenses('t-1');
      expect(queries.lastFindForTripTripId, 't-1');
      expect(result.single.expense.id, 'e-1');
    });

    test('wraps errors', () async {
      queries.throwOnFindForTrip = Exception('boom');
      await expectLater(
        ds.getTripExpenses('t-1'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to get trip expenses'))),
      );
    });
  });

  // -----------------------------------------------------------------
  group('getStandaloneExpenses', () {
    test('returns only paid-by when no splits', () async {
      queries.findStandalonePaidByResponse = [
        baseExpenseRow(id: 'e-1', paidBy: 'u-1'),
      ];
      queries.findSplitIdsResponse = const [];

      final result = await ds.getStandaloneExpenses('u-1');

      expect(queries.lastFindStandalonePaidByUserId, 'u-1');
      expect(queries.lastFindStandaloneByIdsIds, isNull);
      expect(result, hasLength(1));
    });

    test('combines paid + split standalone', () async {
      queries.findStandalonePaidByResponse = [
        baseExpenseRow(id: 'e-1', paidBy: 'u-1'),
      ];
      queries.findSplitIdsResponse = [
        {'expense_id': 'e-2'},
      ];
      queries.findStandaloneByIdsResponse = [
        baseExpenseRow(id: 'e-2', paidBy: 'u-9'),
      ];

      final result = await ds.getStandaloneExpenses('u-1');
      expect(queries.lastFindStandaloneByIdsIds, ['e-2']);
      expect(queries.lastFindStandaloneByIdsUserId, 'u-1');
      expect(result.map((r) => r.expense.id), ['e-1', 'e-2']);
    });

    test('wraps errors', () async {
      queries.throwOnFindStandalonePaidBy = Exception('boom');
      await expectLater(
        ds.getStandaloneExpenses('u-1'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to get standalone expenses'))),
      );
    });
  });

  // -----------------------------------------------------------------
  group('getExpenseById', () {
    test('returns parsed model', () async {
      queries.findExpenseByIdResponse = baseExpenseRow(
        id: 'e-1',
        payer: {'full_name': 'Alice'},
        splits: [baseSplitRow(userName: 'Bob')],
      );
      final result = await ds.getExpenseById('e-1');
      expect(queries.lastFindExpenseByIdId, 'e-1');
      expect(result.expense.id, 'e-1');
      expect(result.expense.payerName, 'Alice');
      expect(result.splits.single.userName, 'Bob');
    });

    test('wraps errors', () async {
      queries.throwOnFindExpenseById = Exception('boom');
      await expectLater(
        ds.getExpenseById('e-1'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to get expense'))),
      );
    });
  });

  // -----------------------------------------------------------------
  group('createExpense', () {
    test('inserts expense + splits with equal-split amount', () async {
      queries.insertExpenseResponse = baseExpenseRow(
        id: 'e-new',
        tripId: 't-1',
        paidBy: 'u-1',
        amount: 90.0,
      );

      final result = await ds.createExpense(
        tripId: 't-1',
        title: 'Dinner',
        description: 'desc',
        amount: 90.0,
        category: 'food',
        paidBy: 'u-1',
        splitWith: ['u-1', 'u-2', 'u-3'],
        transactionDate: fixedClock,
      );

      expect(queries.lastInsertExpenseData!['trip_id'], 't-1');
      expect(queries.lastInsertExpenseData!['title'], 'Dinner');
      expect(queries.lastInsertExpenseData!['amount'], 90.0);
      expect(queries.lastInsertExpenseData!['paid_by'], 'u-1');
      expect(queries.lastInsertExpenseData!['split_type'], 'equal');
      expect(queries.lastInsertExpenseData!['transaction_date'],
          fixedClock.toIso8601String());

      expect(queries.lastInsertSplitsRows, hasLength(3));
      for (final row in queries.lastInsertSplitsRows!) {
        expect(row['expense_id'], 'e-new');
        expect(row['amount'], 30.0);
      }
      expect(
        queries.lastInsertSplitsRows!.map((r) => r['user_id']).toList(),
        ['u-1', 'u-2', 'u-3'],
      );
      expect(result.id, 'e-new');
    });

    test('passes null transaction_date when not provided', () async {
      queries.insertExpenseResponse = baseExpenseRow(id: 'e-new');
      await ds.createExpense(
        title: 'X',
        amount: 10.0,
        paidBy: 'u-1',
        splitWith: ['u-1'],
      );
      expect(queries.lastInsertExpenseData!['transaction_date'], isNull);
      expect(queries.lastInsertExpenseData!['trip_id'], isNull);
      expect(queries.lastInsertExpenseData!['split_type'], 'equal');
    });

    test('honours custom splitType', () async {
      queries.insertExpenseResponse = baseExpenseRow(id: 'e-new');
      await ds.createExpense(
        title: 'X',
        amount: 10.0,
        paidBy: 'u-1',
        splitWith: ['u-1'],
        splitType: 'percentage',
      );
      expect(queries.lastInsertExpenseData!['split_type'], 'percentage');
    });

    test('wraps insert errors', () async {
      queries.throwOnInsertExpense = Exception('boom');
      await expectLater(
        ds.createExpense(
          title: 'X',
          amount: 10.0,
          paidBy: 'u-1',
          splitWith: ['u-1'],
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to create expense'))),
      );
    });

    test('wraps split-insert errors', () async {
      queries.insertExpenseResponse = baseExpenseRow(id: 'e-new');
      queries.throwOnInsertSplits = Exception('boom');
      await expectLater(
        ds.createExpense(
          title: 'X',
          amount: 10.0,
          paidBy: 'u-1',
          splitWith: ['u-1'],
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to create expense'))),
      );
    });
  });

  // -----------------------------------------------------------------
  group('updateExpense', () {
    test('only sends provided fields', () async {
      queries.updateExpenseResponse = baseExpenseRow(id: 'e-1');
      await ds.updateExpense(
        expenseId: 'e-1',
        title: 'New title',
        amount: 200.0,
      );

      expect(queries.lastUpdateExpenseId, 'e-1');
      expect(queries.lastUpdateExpenseData,
          {'title': 'New title', 'amount': 200.0});
    });

    test('serializes transactionDate as ISO', () async {
      queries.updateExpenseResponse = baseExpenseRow(id: 'e-1');
      await ds.updateExpense(
        expenseId: 'e-1',
        transactionDate: fixedClock,
      );
      expect(queries.lastUpdateExpenseData!['transaction_date'],
          fixedClock.toIso8601String());
    });

    test('returns the updated model', () async {
      queries.updateExpenseResponse =
          baseExpenseRow(id: 'e-1', title: 'After');
      final result = await ds.updateExpense(expenseId: 'e-1', title: 'After');
      expect(result.title, 'After');
    });

    test('wraps errors', () async {
      queries.throwOnUpdateExpense = Exception('boom');
      await expectLater(
        ds.updateExpense(expenseId: 'e-1', title: 'X'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to update expense'))),
      );
    });

    test('with no fields produces empty update payload', () async {
      queries.updateExpenseResponse = baseExpenseRow(id: 'e-1');
      await ds.updateExpense(expenseId: 'e-1');
      expect(queries.lastUpdateExpenseData, isEmpty);
    });
  });

  // -----------------------------------------------------------------
  group('deleteExpense', () {
    test('forwards id', () async {
      await ds.deleteExpense('e-1');
      expect(queries.lastDeleteExpenseId, 'e-1');
    });

    test('wraps errors', () async {
      queries.throwOnDeleteExpense = Exception('boom');
      await expectLater(
        ds.deleteExpense('e-1'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to delete expense'))),
      );
    });
  });

  // -----------------------------------------------------------------
  group('getBalances', () {
    test('passes tripId filter through and ignores userId when both null',
        () async {
      queries.findBalancesResponse = const [];
      await ds.getBalances(tripId: 't-1');
      expect(queries.lastBalancesTripId, 't-1');
      expect(queries.lastBalancesUserId, isNull);
    });

    test('passes userId filter when no tripId', () async {
      queries.findBalancesResponse = const [];
      await ds.getBalances(userId: 'u-1');
      expect(queries.lastBalancesTripId, isNull);
      expect(queries.lastBalancesUserId, 'u-1');
    });

    test('aggregates totalPaid / totalOwed and computes balance', () async {
      // Alice paid $100, split equally with Bob (50/50).
      queries.findBalancesResponse = [
        baseExpenseRow(
          id: 'e-1',
          paidBy: 'alice',
          amount: 100.0,
          payer: {'full_name': 'Alice'},
          splits: [
            baseSplitRow(
              id: 's-1',
              expenseId: 'e-1',
              userId: 'alice',
              amount: 50.0,
              userName: 'Alice',
            ),
            baseSplitRow(
              id: 's-2',
              expenseId: 'e-1',
              userId: 'bob',
              amount: 50.0,
              userName: 'Bob',
            ),
          ],
        ),
      ];

      final balances = await ds.getBalances(tripId: 't-1');
      final byId = {for (final b in balances) b.userId: b};
      expect(byId['alice']!.totalPaid, 100.0);
      expect(byId['alice']!.totalOwed, 50.0);
      expect(byId['alice']!.balance, 50.0);
      expect(byId['alice']!.userName, 'Alice');
      expect(byId['bob']!.totalPaid, 0.0);
      expect(byId['bob']!.totalOwed, 50.0);
      expect(byId['bob']!.balance, -50.0);
      expect(byId['bob']!.userName, 'Bob');
    });

    test('falls back to user id when full_name is missing (UUID-like)',
        () async {
      // Use a UUID-shaped paidBy so the proper-name check rejects the fallback.
      const uuid = '12345678-1234-1234-1234-123456789012';
      queries.findBalancesResponse = [
        baseExpenseRow(
          id: 'e-1',
          paidBy: uuid,
          amount: 30.0,
          payer: null, // no payer info
          splits: [
            baseSplitRow(
              id: 's-1',
              expenseId: 'e-1',
              userId: uuid,
              amount: 30.0,
              userName: null,
            ),
          ],
        ),
      ];
      final balances = await ds.getBalances(tripId: 't-1');
      // userName falls back to the UUID itself; _isProperName returns false.
      expect(balances.single.userId, uuid);
      expect(balances.single.userName, uuid);
    });

    test('preserves a previously-seen proper name across rows', () async {
      // First row gives Alice a real name; second row drops to UUID fallback.
      queries.findBalancesResponse = [
        baseExpenseRow(
          id: 'e-1',
          paidBy: 'alice',
          amount: 50.0,
          payer: {'full_name': 'Alice'},
          splits: const [],
        ),
        baseExpenseRow(
          id: 'e-2',
          paidBy: 'alice',
          amount: 30.0,
          payer: null,
          splits: const [],
        ),
      ];
      final balances = await ds.getBalances(tripId: 't-1');
      expect(balances.single.userName, 'Alice');
      expect(balances.single.totalPaid, 80.0);
    });

    test('wraps errors', () async {
      queries.throwOnFindBalances = Exception('boom');
      await expectLater(
        ds.getBalances(tripId: 't-1'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to get balances'))),
      );
    });
  });

  // -----------------------------------------------------------------
  group('createSettlement', () {
    test('inserts with provided fields and pending status', () async {
      queries.insertSettlementResponse = baseSettlementRow(
        id: 'st-new',
        tripId: 't-1',
        fromUser: 'u-1',
        toUser: 'u-2',
        amount: 75.0,
      );

      final result = await ds.createSettlement(
        tripId: 't-1',
        fromUser: 'u-1',
        toUser: 'u-2',
        amount: 75.0,
        paymentMethod: 'upi',
      );

      expect(queries.lastInsertSettlementData, {
        'trip_id': 't-1',
        'from_user': 'u-1',
        'to_user': 'u-2',
        'amount': 75.0,
        'payment_method': 'upi',
        'status': 'pending',
      });
      expect(result.id, 'st-new');
      expect(result.status, 'pending');
    });

    test('allows null tripId / paymentMethod (standalone settlement)',
        () async {
      queries.insertSettlementResponse = baseSettlementRow(id: 'st-new');
      await ds.createSettlement(
        fromUser: 'u-1',
        toUser: 'u-2',
        amount: 10.0,
      );
      expect(queries.lastInsertSettlementData!['trip_id'], isNull);
      expect(queries.lastInsertSettlementData!['payment_method'], isNull);
    });

    test('wraps errors', () async {
      queries.throwOnInsertSettlement = Exception('boom');
      await expectLater(
        ds.createSettlement(
          fromUser: 'u-1',
          toUser: 'u-2',
          amount: 1.0,
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to create settlement'))),
      );
    });
  });

  // -----------------------------------------------------------------
  group('getSettlements', () {
    test('passes through tripId filter', () async {
      queries.findSettlementsResponse = const [];
      await ds.getSettlements(tripId: 't-1');
      expect(queries.lastFindSettlementsTripId, 't-1');
      expect(queries.lastFindSettlementsUserId, isNull);
    });

    test('passes through userId filter when no tripId', () async {
      queries.findSettlementsResponse = const [];
      await ds.getSettlements(userId: 'u-1');
      expect(queries.lastFindSettlementsUserId, 'u-1');
    });

    test('decorates rows with from/to display names', () async {
      queries.findSettlementsResponse = [
        baseSettlementRow(
          id: 'st-1',
          from: {'full_name': 'Alice'},
          to: {'full_name': 'Bob'},
        ),
      ];
      final result = await ds.getSettlements(tripId: 't-1');
      expect(result.single.fromUserName, 'Alice');
      expect(result.single.toUserName, 'Bob');
    });

    test('handles missing nested join objects gracefully', () async {
      queries.findSettlementsResponse = [
        baseSettlementRow(id: 'st-1', from: null, to: null),
      ];
      final result = await ds.getSettlements();
      expect(result.single.fromUserName, isNull);
      expect(result.single.toUserName, isNull);
    });

    test('wraps errors', () async {
      queries.throwOnFindSettlements = Exception('boom');
      await expectLater(
        ds.getSettlements(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to get settlements'))),
      );
    });
  });

  // -----------------------------------------------------------------
  group('updateSettlementStatus', () {
    test('sends status only when no proof url', () async {
      queries.updateSettlementResponse =
          baseSettlementRow(id: 'st-1', status: 'completed');
      await ds.updateSettlementStatus(
        settlementId: 'st-1',
        status: 'completed',
      );
      expect(queries.lastUpdateSettlementId, 'st-1');
      expect(queries.lastUpdateSettlementData, {'status': 'completed'});
    });

    test('includes proof url when provided', () async {
      queries.updateSettlementResponse = baseSettlementRow(id: 'st-1');
      await ds.updateSettlementStatus(
        settlementId: 'st-1',
        status: 'completed',
        paymentProofUrl: 'http://x/y.jpg',
      );
      expect(queries.lastUpdateSettlementData, {
        'status': 'completed',
        'payment_proof_url': 'http://x/y.jpg',
      });
    });

    test('returns parsed settlement model', () async {
      queries.updateSettlementResponse =
          baseSettlementRow(id: 'st-1', status: 'completed');
      final result = await ds.updateSettlementStatus(
        settlementId: 'st-1',
        status: 'completed',
      );
      expect(result.id, 'st-1');
      expect(result.status, 'completed');
    });

    test('wraps errors', () async {
      queries.throwOnUpdateSettlement = Exception('boom');
      await expectLater(
        ds.updateSettlementStatus(settlementId: 'st-1', status: 'x'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to update settlement'))),
      );
    });
  });
}
