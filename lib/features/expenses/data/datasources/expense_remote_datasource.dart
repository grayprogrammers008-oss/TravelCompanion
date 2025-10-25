import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/expense_model.dart';

/// Remote datasource for expenses using Supabase
class ExpenseRemoteDataSource {
  final SupabaseClient _client;

  ExpenseRemoteDataSource(this._client);

  /// Get all expenses for a user (both trip and standalone)
  Future<List<ExpenseWithSplits>> getUserExpenses(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Fetching user expenses for userId: $userId');
      }

      // First, get all expenses where user is the payer
      final paidByResponse = await _client
          .from('expenses')
          .select('''
            *,
            expense_splits(
              *,
              user:profiles!expense_splits_user_id_fkey(id, full_name, avatar_url)
            ),
            payer:profiles!expenses_paid_by_fkey(full_name)
          ''')
          .eq('paid_by', userId)
          .order('transaction_date', ascending: false);

      // Then, get all expense_splits where user is a participant
      final splitsResponse = await _client
          .from('expense_splits')
          .select('expense_id')
          .eq('user_id', userId);

      // Get unique expense IDs from splits
      final expenseIdsFromSplits = (splitsResponse as List)
          .map((split) => split['expense_id'] as String)
          .toSet();

      // Fetch expenses for those IDs (excluding ones already fetched)
      List<dynamic> splitExpenses = [];
      if (expenseIdsFromSplits.isNotEmpty) {
        final splitExpensesResponse = await _client
            .from('expenses')
            .select('''
              *,
              expense_splits(
                *,
                user:profiles!expense_splits_user_id_fkey(id, full_name, avatar_url)
              ),
              payer:profiles!expenses_paid_by_fkey(full_name)
            ''')
            .inFilter('id', expenseIdsFromSplits.toList())
            .neq('paid_by', userId);
        splitExpenses = splitExpensesResponse as List;
      }

      // Combine and parse
      final allExpenses = [...(paidByResponse as List), ...splitExpenses];
      if (kDebugMode) {
        debugPrint('📊 Database returned ${allExpenses.length} expenses (${(paidByResponse as List).length} paid by user, ${splitExpenses.length} split with user)');
      }

      return allExpenses
          .map((json) => _parseExpenseWithSplits(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching user expenses: $e');
      }
      throw Exception('Failed to get user expenses: $e');
    }
  }

  /// Get all expenses for a trip
  Future<List<ExpenseWithSplits>> getTripExpenses(String tripId) async {
    try {
      final response = await _client
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
      if (kDebugMode) {
        debugPrint('🔍 Fetching standalone expenses for userId: $userId');
      }

      // Get standalone expenses where user is the payer
      final paidByResponse = await _client
          .from('expenses')
          .select('''
            *,
            expense_splits(
              *,
              user:profiles!expense_splits_user_id_fkey(id, full_name, avatar_url)
            ),
            payer:profiles!expenses_paid_by_fkey(full_name)
          ''')
          .isFilter('trip_id', null)
          .eq('paid_by', userId)
          .order('transaction_date', ascending: false);

      // Get all expense_splits where user is a participant (for standalone only)
      final splitsResponse = await _client
          .from('expense_splits')
          .select('expense_id')
          .eq('user_id', userId);

      final expenseIdsFromSplits = (splitsResponse as List)
          .map((split) => split['expense_id'] as String)
          .toSet();

      // Fetch standalone expenses for those IDs (excluding ones already fetched)
      List<dynamic> splitExpenses = [];
      if (expenseIdsFromSplits.isNotEmpty) {
        final splitExpensesResponse = await _client
            .from('expenses')
            .select('''
              *,
              expense_splits(
                *,
                user:profiles!expense_splits_user_id_fkey(id, full_name, avatar_url)
              ),
              payer:profiles!expenses_paid_by_fkey(full_name)
            ''')
            .isFilter('trip_id', null)
            .inFilter('id', expenseIdsFromSplits.toList())
            .neq('paid_by', userId);
        splitExpenses = splitExpensesResponse as List;
      }

      final allExpenses = [...(paidByResponse as List), ...splitExpenses];
      if (kDebugMode) {
        debugPrint('📊 Standalone expenses: ${allExpenses.length} total (${(paidByResponse as List).length} paid, ${splitExpenses.length} split)');
      }

      return allExpenses
          .map((json) => _parseExpenseWithSplits(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching standalone expenses: $e');
      }
      throw Exception('Failed to get standalone expenses: $e');
    }
  }

  /// Get a single expense by ID
  Future<ExpenseWithSplits> getExpenseById(String expenseId) async {
    try {
      final response = await _client
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
      if (kDebugMode) {
        debugPrint('💰 Creating expense: $title, amount: $amount, category: $category, tripId: $tripId');
      }

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

      final expenseResponse = await _client
          .from('expenses')
          .insert(expenseData)
          .select()
          .single();

      final expense = ExpenseModel.fromJson(expenseResponse);
      if (kDebugMode) {
        debugPrint('✅ Expense created with ID: ${expense.id}');
      }

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

      await _client.from('expense_splits').insert(splitsData);
      if (kDebugMode) {
        debugPrint('✅ Created ${splitsData.length} expense splits');
      }

      return expense;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating expense: $e');
      }
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

      final response = await _client
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
      await _client.from('expenses').delete().eq('id', expenseId);
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
      var query = _client.from('expenses').select('''
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

      final response = await _client
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
      var query = _client.from('settlements').select('''
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

      final response = await _client
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

  /// Watch trip expenses in real-time
  Stream<List<ExpenseWithSplits>> watchTripExpenses(String tripId) {
    final controller = StreamController<List<ExpenseWithSplits>>.broadcast();

    // Refetch function
    Future<void> refetchExpenses(String reason) async {
      if (kDebugMode) {
        debugPrint('🔄 $reason - Refetching trip expenses...');
      }
      try {
        final expenses = await getTripExpenses(tripId);
        if (!controller.isClosed) {
          controller.add(expenses);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error fetching expenses: $e');
        }
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    // Subscribe to expenses table changes
    final expensesChannel = _client.channel('expenses:$tripId');

    expensesChannel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expenses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'trip_id',
            value: tripId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('🔄 Expense changed: ${payload.eventType}');
            }
            refetchExpenses('Expense ${payload.eventType}');
          },
        )
        .subscribe((status, error) {
          if (kDebugMode) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint('✅ Successfully subscribed to expenses for trip:$tripId');
            } else if (status == RealtimeSubscribeStatus.timedOut) {
              debugPrint('❌ Expenses subscription TIMED OUT for trip:$tripId');
            } else if (status == RealtimeSubscribeStatus.channelError) {
              debugPrint('❌ Expenses subscription ERROR for trip:$tripId - Error: $error');
            }
          }
        });

    // Also subscribe to expense_splits changes
    final splitsChannel = _client.channel('expense_splits:$tripId');

    splitsChannel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expense_splits',
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('🔄 Expense split changed: ${payload.eventType}');
            }
            refetchExpenses('Expense split ${payload.eventType}');
          },
        )
        .subscribe((status, error) {
          if (kDebugMode) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint('✅ Successfully subscribed to expense splits for trip:$tripId');
            }
          }
        });

    // Initial load
    getTripExpenses(tripId).then((expenses) {
      if (!controller.isClosed) {
        controller.add(expenses);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    // Cleanup
    controller.onCancel = () {
      expensesChannel.unsubscribe();
      splitsChannel.unsubscribe();
    };

    return controller.stream;
  }

  /// Watch user expenses in real-time
  Stream<List<ExpenseWithSplits>> watchUserExpenses() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return Stream.error(Exception('User not authenticated'));
    }

    final controller = StreamController<List<ExpenseWithSplits>>.broadcast();

    // Refetch function
    Future<void> refetchExpenses(String reason) async {
      if (kDebugMode) {
        debugPrint('🔄 $reason - Refetching user expenses...');
      }
      try {
        final expenses = await getUserExpenses(userId);
        if (!controller.isClosed) {
          controller.add(expenses);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error fetching user expenses: $e');
        }
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    // Subscribe to ALL expenses table changes (will filter on refetch)
    final expensesChannel = _client.channel('all_expenses:$userId');

    expensesChannel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expenses',
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('🔄 Expense changed: ${payload.eventType}');
            }
            refetchExpenses('Expense ${payload.eventType}');
          },
        )
        .subscribe((status, error) {
          if (kDebugMode) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint('✅ Successfully subscribed to all expenses');
            } else if (status == RealtimeSubscribeStatus.timedOut) {
              debugPrint('❌ All expenses subscription TIMED OUT');
            } else if (status == RealtimeSubscribeStatus.channelError) {
              debugPrint('❌ All expenses subscription ERROR: $error');
            }
          }
        });

    // Subscribe to expense_splits changes
    final splitsChannel = _client.channel('all_splits:$userId');

    splitsChannel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expense_splits',
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('🔄 Expense split changed: ${payload.eventType}');
            }
            refetchExpenses('Expense split ${payload.eventType}');
          },
        )
        .subscribe((status, error) {
          if (kDebugMode) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint('✅ Successfully subscribed to all expense splits');
            }
          }
        });

    // Initial load
    getUserExpenses(userId).then((expenses) {
      if (!controller.isClosed) {
        controller.add(expenses);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    // Cleanup
    controller.onCancel = () {
      expensesChannel.unsubscribe();
      splitsChannel.unsubscribe();
    };

    return controller.stream;
  }
}
