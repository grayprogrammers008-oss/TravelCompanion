import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin abstraction over the Supabase PostgREST chain used by
/// [ExpenseRemoteDataSource].
///
/// The Supabase fluent builders (`from(t).select().eq(c, v).order(...)`)
/// are not mockable through Mockito — their generic types are fixed per
/// method and `Mock` cannot intercept the awaited `then()`. Wrapping the
/// chain calls in this interface lets tests substitute a fake while the
/// production [ExpenseQueriesImpl] carries the (untestable) Supabase code.
abstract class ExpenseQueries {
  /// Expenses (with trip / splits / payer joins) where the given user paid.
  Future<List<Map<String, dynamic>>> findExpensesPaidBy(String userId);

  /// Expense IDs where this user appears as a participant in a split.
  Future<List<Map<String, dynamic>>> findSplitExpenseIdsForUser(String userId);

  /// Expenses (with joins) for a list of IDs that the user did NOT pay for.
  Future<List<Map<String, dynamic>>> findExpensesByIdsNotPaidBy(
    List<String> ids,
    String userId,
  );

  /// Expenses (with joins) for a single trip, ordered by transaction_date desc.
  Future<List<Map<String, dynamic>>> findExpensesForTrip(String tripId);

  /// Standalone (trip_id IS NULL) expenses paid by the user.
  Future<List<Map<String, dynamic>>> findStandaloneExpensesPaidBy(
    String userId,
  );

  /// Standalone expenses for a list of IDs that the user did NOT pay for.
  Future<List<Map<String, dynamic>>> findStandaloneExpensesByIdsNotPaidBy(
    List<String> ids,
    String userId,
  );

  /// Single expense (with joins) by id.
  Future<Map<String, dynamic>> findExpenseById(String expenseId);

  /// Insert a new expenses row, returning the inserted row.
  Future<Map<String, dynamic>> insertExpense(Map<String, dynamic> data);

  /// Insert a list of expense_splits rows.
  Future<void> insertExpenseSplits(List<Map<String, dynamic>> rows);

  /// Update an expenses row by id, returning the updated row.
  Future<Map<String, dynamic>> updateExpenseById(
    String expenseId,
    Map<String, dynamic> data,
  );

  /// Delete an expenses row by id.
  Future<void> deleteExpenseById(String expenseId);

  /// Expenses (with splits + payer joins) used for balance calculation.
  /// Optional [tripId] OR [userId] filter (mutually exclusive in the
  /// caller, but we accept both as nullable for symmetry).
  Future<List<Map<String, dynamic>>> findExpensesForBalances({
    String? tripId,
    String? userId,
  });

  /// Insert a settlement row, returning it.
  Future<Map<String, dynamic>> insertSettlement(Map<String, dynamic> data);

  /// Settlements (with from/to joins) ordered by created_at desc; optional
  /// trip / user filters.
  Future<List<Map<String, dynamic>>> findSettlements({
    String? tripId,
    String? userId,
  });

  /// Update a settlement row by id, returning it.
  Future<Map<String, dynamic>> updateSettlementById(
    String settlementId,
    Map<String, dynamic> data,
  );
}

/// Production implementation that talks to Supabase. Each method is a
/// minimal pass-through to the PostgREST chain and is exercised
/// end-to-end by integration / live tests, not unit tests.
class ExpenseQueriesImpl implements ExpenseQueries {
  ExpenseQueriesImpl(this._client);
  final SupabaseClient _client;

  static const String _expenseJoinSelect = '''
            *,
            trips:trips(name),
            expense_splits(
              *,
              user:profiles!expense_splits_user_id_fkey(id, full_name, avatar_url)
            ),
            payer:profiles!expenses_paid_by_fkey(full_name)
          ''';

  static const String _standaloneJoinSelect = '''
            *,
            expense_splits(
              *,
              user:profiles!expense_splits_user_id_fkey(id, full_name, avatar_url)
            ),
            payer:profiles!expenses_paid_by_fkey(full_name)
          ''';

  static const String _balanceJoinSelect = '''
            *,
            expense_splits(
              *,
              user:profiles!expense_splits_user_id_fkey(id, full_name)
            ),
            payer:profiles!expenses_paid_by_fkey(full_name)
          ''';

  static const String _settlementJoinSelect = '''
            *,
            from:profiles!settlements_from_user_fkey(full_name),
            to:profiles!settlements_to_user_fkey(full_name)
          ''';

  @override
  Future<List<Map<String, dynamic>>> findExpensesPaidBy(String userId) async {
    final response = await _client
        .from('expenses')
        .select(_expenseJoinSelect)
        .eq('paid_by', userId)
        .order('transaction_date', ascending: false);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> findSplitExpenseIdsForUser(
    String userId,
  ) async {
    final response = await _client
        .from('expense_splits')
        .select('expense_id')
        .eq('user_id', userId);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> findExpensesByIdsNotPaidBy(
    List<String> ids,
    String userId,
  ) async {
    final response = await _client
        .from('expenses')
        .select(_expenseJoinSelect)
        .inFilter('id', ids)
        .neq('paid_by', userId);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> findExpensesForTrip(String tripId) async {
    final response = await _client
        .from('expenses')
        .select(_expenseJoinSelect)
        .eq('trip_id', tripId)
        .order('transaction_date', ascending: false);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> findStandaloneExpensesPaidBy(
    String userId,
  ) async {
    final response = await _client
        .from('expenses')
        .select(_standaloneJoinSelect)
        .isFilter('trip_id', null)
        .eq('paid_by', userId)
        .order('transaction_date', ascending: false);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> findStandaloneExpensesByIdsNotPaidBy(
    List<String> ids,
    String userId,
  ) async {
    final response = await _client
        .from('expenses')
        .select(_standaloneJoinSelect)
        .isFilter('trip_id', null)
        .inFilter('id', ids)
        .neq('paid_by', userId);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> findExpenseById(String expenseId) async {
    final response = await _client
        .from('expenses')
        .select(_standaloneJoinSelect)
        .eq('id', expenseId)
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>> insertExpense(
    Map<String, dynamic> data,
  ) async {
    final response =
        await _client.from('expenses').insert(data).select().single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<void> insertExpenseSplits(List<Map<String, dynamic>> rows) async {
    await _client.from('expense_splits').insert(rows);
  }

  @override
  Future<Map<String, dynamic>> updateExpenseById(
    String expenseId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client
        .from('expenses')
        .update(data)
        .eq('id', expenseId)
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<void> deleteExpenseById(String expenseId) async {
    await _client.from('expenses').delete().eq('id', expenseId);
  }

  @override
  Future<List<Map<String, dynamic>>> findExpensesForBalances({
    String? tripId,
    String? userId,
  }) async {
    dynamic query = _client.from('expenses').select(_balanceJoinSelect);
    if (tripId != null) {
      query = query.eq('trip_id', tripId);
    } else if (userId != null) {
      query = query.or(
        'paid_by.eq.$userId,expense_splits.user_id.eq.$userId',
      );
    }
    final response = await query;
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> insertSettlement(
    Map<String, dynamic> data,
  ) async {
    final response =
        await _client.from('settlements').insert(data).select().single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> findSettlements({
    String? tripId,
    String? userId,
  }) async {
    dynamic query = _client.from('settlements').select(_settlementJoinSelect);
    if (tripId != null) {
      query = query.eq('trip_id', tripId);
    } else if (userId != null) {
      query = query.or('from_user.eq.$userId,to_user.eq.$userId');
    }
    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> updateSettlementById(
    String settlementId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client
        .from('settlements')
        .update(data)
        .eq('id', settlementId)
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }
}
