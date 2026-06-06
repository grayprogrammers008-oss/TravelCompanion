import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../shared/models/expense_model.dart';
import 'expense_queries.dart';

/// Remote datasource for expenses using Supabase.
///
/// All Supabase PostgREST chain calls live behind [ExpenseQueries] so the
/// datasource itself can be exercised by unit tests. The default constructor
/// wires up the production [ExpenseQueriesImpl]; tests inject a fake.
///
/// NOTE: The realtime stream methods ([watchTripExpenses], [watchUserExpenses])
/// still talk to `_client` directly because the realtime channel/subscribe
/// API is fundamentally callback-driven and is not part of [ExpenseQueries].
/// Those streams are exercised by integration tests, not unit tests.
class ExpenseRemoteDataSource {
  ExpenseRemoteDataSource(
    SupabaseClient client, {
    ExpenseQueries? queries,
    Uuid? uuid,
    DateTime Function()? clock,
  })  : _client = client,
        _queries = queries ?? ExpenseQueriesImpl(client),
        // ignore: unused_field
        _uuid = uuid ?? const Uuid(),
        // ignore: unused_field
        _clock = clock ?? DateTime.now;

  final SupabaseClient _client;
  final ExpenseQueries _queries;
  // Reserved for future use; kept for API symmetry with sibling datasources.
  // ignore: unused_field
  final Uuid _uuid;
  // ignore: unused_field
  final DateTime Function() _clock;

  /// Get all expenses for a user (both trip and standalone)
  Future<List<ExpenseWithSplits>> getUserExpenses(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Fetching user expenses for userId: $userId');
      }

      // First, get all expenses where user is the payer
      final paidByResponse = await _queries.findExpensesPaidBy(userId);

      // Then, get all expense_splits where user is a participant
      final splitsResponse = await _queries.findSplitExpenseIdsForUser(userId);

      // Get unique expense IDs from splits
      final expenseIdsFromSplits = splitsResponse
          .map((split) => split['expense_id'] as String)
          .toSet();

      // Fetch expenses for those IDs (excluding ones already fetched)
      List<Map<String, dynamic>> splitExpenses = const [];
      if (expenseIdsFromSplits.isNotEmpty) {
        splitExpenses = await _queries.findExpensesByIdsNotPaidBy(
          expenseIdsFromSplits.toList(),
          userId,
        );
      }

      // Combine and parse
      final allExpenses = [...paidByResponse, ...splitExpenses];
      if (kDebugMode) {
        debugPrint(
            '📊 Database returned ${allExpenses.length} expenses (${paidByResponse.length} paid by user, ${splitExpenses.length} split with user)');
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
      final response = await _queries.findExpensesForTrip(tripId);
      return response
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

      final paidByResponse =
          await _queries.findStandaloneExpensesPaidBy(userId);

      final splitsResponse = await _queries.findSplitExpenseIdsForUser(userId);

      final expenseIdsFromSplits = splitsResponse
          .map((split) => split['expense_id'] as String)
          .toSet();

      List<Map<String, dynamic>> splitExpenses = const [];
      if (expenseIdsFromSplits.isNotEmpty) {
        splitExpenses = await _queries.findStandaloneExpensesByIdsNotPaidBy(
          expenseIdsFromSplits.toList(),
          userId,
        );
      }

      final allExpenses = [...paidByResponse, ...splitExpenses];
      if (kDebugMode) {
        debugPrint(
            '📊 Standalone expenses: ${allExpenses.length} total (${paidByResponse.length} paid, ${splitExpenses.length} split)');
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
      final response = await _queries.findExpenseById(expenseId);
      return _parseExpenseWithSplits(response);
    } catch (e) {
      throw Exception('Failed to get expense: $e');
    }
  }

  /// Create a new expense with splits.
  ///
  /// [splitWith] is the list of real-member user ids and [ghostSplitWith] is
  /// the list of ghost participant ids that should each take an equal share.
  /// The amount is divided evenly across (members + ghosts).
  Future<ExpenseModel> createExpense({
    String? tripId,
    required String title,
    String? description,
    required double amount,
    String? category,
    required String paidBy,
    required List<String> splitWith,
    List<String> ghostSplitWith = const [],
    String splitType = 'equal',
    DateTime? transactionDate,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '💰 Creating expense: $title, amount: $amount, category: $category, tripId: $tripId, members: ${splitWith.length}, ghosts: ${ghostSplitWith.length}');
      }

      final totalParticipants = splitWith.length + ghostSplitWith.length;
      if (totalParticipants == 0) {
        throw Exception('Expense must have at least one participant');
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

      final expenseResponse = await _queries.insertExpense(expenseData);

      final expense = ExpenseModel.fromJson(expenseResponse);
      if (kDebugMode) {
        debugPrint('✅ Expense created with ID: ${expense.id}');
      }

      // Even split across every participant (members + ghosts count alike).
      final splitAmount = amount / totalParticipants;

      final splitsData = <Map<String, dynamic>>[
        for (final userId in splitWith)
          {
            'expense_id': expense.id,
            'user_id': userId,
            'amount': splitAmount,
          },
        for (final ghostId in ghostSplitWith)
          {
            'expense_id': expense.id,
            'ghost_id': ghostId,
            'amount': splitAmount,
          },
      ];

      await _queries.insertExpenseSplits(splitsData);
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

      final response =
          await _queries.updateExpenseById(expenseId, updateData);
      return ExpenseModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  /// Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      // Splits will be deleted automatically due to cascade delete
      await _queries.deleteExpenseById(expenseId);
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
      final response = await _queries.findExpensesForBalances(
        tripId: tripId,
        userId: userId,
      );

      // Calculate balances
      final Map<String, BalanceSummary> balances = {};
      // Track distinct ghost names per real-user balance owner so the
      // settlement summary can show "includes guests: X, Y" inline.
      final Map<String, Set<String>> guestsPerOwner = {};

      for (var expenseJson in response) {
        final expense = ExpenseModel.fromJson(expenseJson);
        // Parse splits with user names from nested 'user' object
        final splits =
            (expenseJson['expense_splits'] as List).map((splitJson) {
          final user = splitJson['user'];
          return ExpenseSplitModel.fromJson(splitJson).copyWith(
            userName: user?['full_name'],
          );
        }).toList();

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
        // Preserve existing proper name (not a UUID) if we have one
        final existingPayerName = balances[payerId]!.userName;
        final bestPayerName =
            _isProperName(existingPayerName) ? existingPayerName : payerName;
        balances[payerId] = BalanceSummary(
          userId: payerId,
          userName: bestPayerName,
          totalPaid: balances[payerId]!.totalPaid + expense.amount,
          totalOwed: balances[payerId]!.totalOwed,
          balance: 0, // Will calculate later
        );

        // Track splits. Ghost shares fold into their creator's balance
        // (split.effectiveUserId returns ghostCreatedBy for ghost rows).
        for (var split in splits) {
          final ownerId = split.effectiveUserId;
          if (ownerId == null) continue; // unattributable; skip defensively
          // Record the ghost's name against its guardian so the UI can list
          // "incl. guests: X, Y" under the responsible member.
          if (split.isGhost && split.ghostName != null) {
            (guestsPerOwner[ownerId] ??= <String>{}).add(split.ghostName!);
          }
          final splitOwnerName = split.isGhost
              ? (split.userName ?? ownerId) // ghost: use guardian's joined name if present
              : (split.userName ?? ownerId);
          if (!balances.containsKey(ownerId)) {
            balances[ownerId] = BalanceSummary(
              userId: ownerId,
              userName: splitOwnerName,
              totalPaid: 0,
              totalOwed: 0,
              balance: 0,
            );
          }
          // Preserve existing proper name (not a UUID) if we have one
          final existingSplitName = balances[ownerId]!.userName;
          final bestSplitName = _isProperName(existingSplitName)
              ? existingSplitName
              : splitOwnerName;
          balances[ownerId] = BalanceSummary(
            userId: ownerId,
            userName: bestSplitName,
            totalPaid: balances[ownerId]!.totalPaid,
            totalOwed: balances[ownerId]!.totalOwed + split.amount,
            balance: 0, // Will calculate later
          );
        }
      }

      // Calculate final balances
      final result = balances.values.map((b) {
        final guests = guestsPerOwner[b.userId];
        return BalanceSummary(
          userId: b.userId,
          userName: b.userName,
          totalPaid: b.totalPaid,
          totalOwed: b.totalOwed,
          balance: b.totalPaid - b.totalOwed,
          guestNames:
              guests == null ? const [] : (guests.toList()..sort()),
        );
      }).toList();
      if (kDebugMode) {
        debugPrint('💰 [balances] tripId=$tripId rows=${result.length}, '
            'guestsPerOwner=${guestsPerOwner.map((k, v) => MapEntry(k.substring(0, 8), v.toList()))}');
        for (final b in result) {
          debugPrint(
              '💰 [balances]   ${b.userName} (${b.userId.substring(0, 8)}): '
              'paid=${b.totalPaid} owed=${b.totalOwed} '
              'guests=${b.guestNames}');
        }
      }
      return result;
    } catch (e) {
      throw Exception('Failed to get balances: $e');
    }
  }

  /// Check if a name is a proper name (not a UUID)
  bool _isProperName(String name) {
    // UUIDs are typically 36 chars with dashes: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    // A proper name should not match this pattern
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return !uuidPattern.hasMatch(name);
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

      final response = await _queries.insertSettlement(settlementData);
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
      final response = await _queries.findSettlements(
        tripId: tripId,
        userId: userId,
      );

      return response.map((json) {
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

      final response =
          await _queries.updateSettlementById(settlementId, updateData);
      return SettlementModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update settlement: $e');
    }
  }

  // ---- Ghost participants -------------------------------------------------

  /// Add a non-member participant to a trip. Returns the inserted row.
  /// [guardianUserId] is the trip member whose balance picks up the
  /// ghost's debts. Defaults to [createdBy] when omitted.
  Future<GhostParticipantModel> createGhost({
    required String tripId,
    required String name,
    required String createdBy,
    String? guardianUserId,
  }) async {
    try {
      final response = await _queries.insertGhost({
        'trip_id': tripId,
        'name': name.trim(),
        'created_by': createdBy,
        'guardian_user_id': guardianUserId ?? createdBy,
      });
      return GhostParticipantModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add guest: $e');
    }
  }

  /// All ghost participants for a trip.
  Future<List<GhostParticipantModel>> getGhostsForTrip(String tripId) async {
    try {
      final rows = await _queries.findGhostsForTrip(tripId);
      return rows.map(GhostParticipantModel.fromJson).toList();
    } catch (e) {
      throw Exception('Failed to load guests: $e');
    }
  }

  /// Rename a ghost participant.
  Future<GhostParticipantModel> renameGhost({
    required String ghostId,
    required String name,
  }) async {
    try {
      final response =
          await _queries.updateGhostById(ghostId, {'name': name.trim()});
      return GhostParticipantModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to rename guest: $e');
    }
  }

  /// Remove a ghost participant. Existing splits referencing them are
  /// removed by the DB cascade defined in the migration.
  Future<void> deleteGhost(String ghostId) async {
    try {
      await _queries.deleteGhostById(ghostId);
    } catch (e) {
      throw Exception('Failed to remove guest: $e');
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

  /// Watch trip expenses in real-time.
  ///
  /// NOTE: This method uses [_client] directly for the realtime channel
  /// subscription because realtime is callback-driven and falls outside the
  /// [ExpenseQueries] interface. The actual data fetches inside the refetch
  /// callback go through [getTripExpenses] and therefore through the queries
  /// abstraction.
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

  /// Watch user expenses in real-time.
  ///
  /// NOTE: Uses [_client] directly for the realtime subscription (see
  /// [watchTripExpenses] for the rationale). The actual data fetches go
  /// through [getUserExpenses] and therefore through [ExpenseQueries].
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
