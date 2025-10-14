import '../../../../core/network/supabase_client.dart';
import '../../../../shared/models/expense_model.dart';

/// Remote datasource for expenses using Supabase
class ExpenseRemoteDataSource {
  final SupabaseClientWrapper _client;

  ExpenseRemoteDataSource(this._client);

  /// Get all expenses for a user (both trip and standalone)
  Future<List<ExpenseWithSplits>> getUserExpenses(String userId) async {
    try {
      final response = await _client.client
          .from('expenses')
          .select('''
            *,
            expense_splits(
              *,
              user:profiles!expense_splits_user_id_fkey(id, full_name, avatar_url)
            ),
            payer:profiles!expenses_paid_by_fkey(full_name)
          ''')
          .or('paid_by.eq.$userId,expense_splits.user_id.eq.$userId')
          .order('transaction_date', ascending: false);

      return (response as List)
          .map((json) => _parseExpenseWithSplits(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user expenses: $e');
    }
  }

  /// Get all expenses for a trip
  Future<List<ExpenseWithSplits>> getTripExpenses(String tripId) async {
    try {
      final response = await _client.client
          .from('expenses')
          .select('''
            *,
            expense_splits(
              *,
              user:profiles!expense_splits_user_id_fkey(id, full_name, avatar_url)
            ),
            payer:profiles!expenses_paid_by_fkey(full_name)
          ''')
          .eq('trip_id', tripId)
          .order('transaction_date', ascending: false);

      return (response as List)
          .map((json) => _parseExpenseWithSplits(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get trip expenses: $e');
    }
  }

  /// Get standalone expenses (no trip)
  Future<List<ExpenseWithSplits>> getStandaloneExpenses(String userId) async {
    try {
      final response = await _client.client
          .from('expenses')
          .select('''
            *,
            expense_splits(
              *,
              user:profiles!expense_splits_user_id_fkey(id, full_name, avatar_url)
            ),
            payer:profiles!expenses_paid_by_fkey(full_name)
          ''')
          .is_('trip_id', null)
          .or('paid_by.eq.$userId,expense_splits.user_id.eq.$userId')
          .order('transaction_date', ascending: false);

      return (response as List)
          .map((json) => _parseExpenseWithSplits(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get standalone expenses: $e');
    }
  }

  /// Get a single expense by ID
  Future<ExpenseWithSplits> getExpenseById(String expenseId) async {
    try {
      final response = await _client.client
          .from('expenses')
          .select('''
            *,
            expense_splits(
              *,
              user:profiles!expense_splits_user_id_fkey(id, full_name, avatar_url)
            ),
            payer:profiles!expenses_paid_by_fkey(full_name)
          ''')
          .eq('id', expenseId)
          .single();

      return _parseExpenseWithSplits(response);
    } catch (e) {
      throw Exception('Failed to get expense: $e');
    }
  }

  /// Create a new expense with splits
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
    try {
      // Create expense
      final expenseData = {
        'trip_id': tripId,
        'title': title,
        'description': description,
        'amount': amount,
        'category': category,
        'paid_by': paidBy,
        'split_type': splitType,
        'transaction_date': transactionDate?.toIso8601String(),
      };

      final expenseResponse = await _client.client
          .from('expenses')
          .insert(expenseData)
          .select()
          .single();

      final expense = ExpenseModel.fromJson(expenseResponse);

      // Calculate split amounts
      final splitAmount = amount / splitWith.length;

      // Create splits
      final splitsData = splitWith
          .map(
            (userId) => {
              'expense_id': expense.id,
              'user_id': userId,
              'amount': splitAmount,
            },
          )
          .toList();

      await _client.client.from('expense_splits').insert(splitsData);

      return expense;
    } catch (e) {
      throw Exception('Failed to create expense: $e');
    }
  }

  /// Update an expense
  Future<ExpenseModel> updateExpense({
    required String expenseId,
    String? title,
    String? description,
    double? amount,
    String? category,
    DateTime? transactionDate,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (amount != null) updateData['amount'] = amount;
      if (category != null) updateData['category'] = category;
      if (transactionDate != null) {
        updateData['transaction_date'] = transactionDate.toIso8601String();
      }

      final response = await _client.client
          .from('expenses')
          .update(updateData)
          .eq('id', expenseId)
          .select()
          .single();

      return ExpenseModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  /// Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      // Splits will be deleted automatically due to cascade delete
      await _client.client.from('expenses').delete().eq('id', expenseId);
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  /// Get balance summary for all members
  Future<List<BalanceSummary>> getBalances({
    String? tripId,
    String? userId,
  }) async {
    try {
      // Build query
      var query = _client.client.from('expenses').select('''
            *,
            expense_splits(
              *,
              user:profiles!expense_splits_user_id_fkey(id, full_name)
            )
          ''');

      if (tripId != null) {
        query = query.eq('trip_id', tripId);
      } else if (userId != null) {
        query = query.or(
          'paid_by.eq.$userId,expense_splits.user_id.eq.$userId',
        );
      }

      final response = await query;

      // Calculate balances
      final Map<String, BalanceSummary> balances = {};

      for (var expenseJson in response) {
        final expense = ExpenseModel.fromJson(expenseJson);
        final splits = (expenseJson['expense_splits'] as List)
            .map((s) => ExpenseSplitModel.fromJson(s))
            .toList();

        // Track payer
        final payerId = expense.paidBy;
        final payerName = expenseJson['payer']?['full_name'] ?? payerId;

        if (!balances.containsKey(payerId)) {
          balances[payerId] = BalanceSummary(
            userId: payerId,
            userName: payerName,
            totalPaid: 0,
            totalOwed: 0,
            balance: 0,
          );
        }
        balances[payerId] = BalanceSummary(
          userId: payerId,
          userName: payerName,
          totalPaid: balances[payerId]!.totalPaid + expense.amount,
          totalOwed: balances[payerId]!.totalOwed,
          balance: 0, // Will calculate later
        );

        // Track splits
        for (var split in splits) {
          final userName = split.userName ?? split.userId;
          if (!balances.containsKey(split.userId)) {
            balances[split.userId] = BalanceSummary(
              userId: split.userId,
              userName: userName,
              totalPaid: 0,
              totalOwed: 0,
              balance: 0,
            );
          }
          balances[split.userId] = BalanceSummary(
            userId: split.userId,
            userName: userName,
            totalPaid: balances[split.userId]!.totalPaid,
            totalOwed: balances[split.userId]!.totalOwed + split.amount,
            balance: 0, // Will calculate later
          );
        }
      }

      // Calculate final balances
      return balances.values.map((b) {
        return BalanceSummary(
          userId: b.userId,
          userName: b.userName,
          totalPaid: b.totalPaid,
          totalOwed: b.totalOwed,
          balance: b.totalPaid - b.totalOwed,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get balances: $e');
    }
  }

  /// Create a settlement
  Future<SettlementModel> createSettlement({
    String? tripId,
    required String fromUser,
    required String toUser,
    required double amount,
    String? paymentMethod,
  }) async {
    try {
      final settlementData = {
        'trip_id': tripId,
        'from_user': fromUser,
        'to_user': toUser,
        'amount': amount,
        'payment_method': paymentMethod,
        'status': 'pending',
      };

      final response = await _client.client
          .from('settlements')
          .insert(settlementData)
          .select()
          .single();

      return SettlementModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create settlement: $e');
    }
  }

  /// Get settlements
  Future<List<SettlementModel>> getSettlements({
    String? tripId,
    String? userId,
  }) async {
    try {
      var query = _client.client.from('settlements').select('''
            *,
            from:profiles!settlements_from_user_fkey(full_name),
            to:profiles!settlements_to_user_fkey(full_name)
          ''');

      if (tripId != null) {
        query = query.eq('trip_id', tripId);
      } else if (userId != null) {
        query = query.or('from_user.eq.$userId,to_user.eq.$userId');
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List).map((json) {
        final settlement = SettlementModel.fromJson(json);
        return settlement.copyWith(
          fromUserName: json['from']?['full_name'],
          toUserName: json['to']?['full_name'],
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get settlements: $e');
    }
  }

  /// Update settlement status
  Future<SettlementModel> updateSettlementStatus({
    required String settlementId,
    required String status,
    String? paymentProofUrl,
  }) async {
    try {
      final updateData = {
        'status': status,
        if (paymentProofUrl != null) 'payment_proof_url': paymentProofUrl,
      };

      final response = await _client.client
          .from('settlements')
          .update(updateData)
          .eq('id', settlementId)
          .select()
          .single();

      return SettlementModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update settlement: $e');
    }
  }

  /// Helper to parse expense with splits
  ExpenseWithSplits _parseExpenseWithSplits(Map<String, dynamic> json) {
    final expense = ExpenseModel.fromJson(
      json,
    ).copyWith(payerName: json['payer']?['full_name']);

    final splits = (json['expense_splits'] as List).map((splitJson) {
      final user = splitJson['user'];
      return ExpenseSplitModel.fromJson(
        splitJson,
      ).copyWith(userName: user?['full_name'], avatarUrl: user?['avatar_url']);
    }).toList();

    return ExpenseWithSplits(expense: expense, splits: splits);
  }
}
