import '../../../../core/database/database_helper.dart';
import '../../../../shared/models/expense_model.dart';
import 'package:uuid/uuid.dart';

/// Local datasource for expense management (SQLite)
class ExpenseLocalDataSource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _uuid = const Uuid();
  String? _currentUserId;

  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

  String get currentUserId => _currentUserId ?? '';

  /// Get all expenses for current user (trip and standalone)
  Future<List<ExpenseWithSplits>> getUserExpenses() async {
    final db = await _dbHelper.database;

    // Get all expenses where user is payer or has a split
    final expenses = await db.rawQuery(
      '''
      SELECT DISTINCT e.* FROM expenses e
      LEFT JOIN expense_splits es ON e.id = es.expense_id
      WHERE e.paid_by = ? OR es.user_id = ?
      ORDER BY e.created_at DESC
    ''',
      [currentUserId, currentUserId],
    );

    // Get splits for each expense
    final result = <ExpenseWithSplits>[];
    for (final expenseMap in expenses) {
      final expense = ExpenseModel.fromJson(expenseMap);

      final splitsData = await db.query(
        'expense_splits',
        where: 'expense_id = ?',
        whereArgs: [expense.id],
      );

      final splits = splitsData
          .map((s) => ExpenseSplitModel.fromJson(s))
          .toList();

      result.add(ExpenseWithSplits(expense: expense, splits: splits));
    }

    return result;
  }

  /// Get all expenses for a trip with splits
  Future<List<ExpenseWithSplits>> getTripExpenses(String tripId) async {
    final db = await _dbHelper.database;

    // Get all expenses for trip
    final expenses = await db.query(
      'expenses',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'created_at DESC',
    );

    // Get splits for each expense
    final result = <ExpenseWithSplits>[];
    for (final expenseMap in expenses) {
      final expense = ExpenseModel.fromJson(expenseMap);

      final splitsData = await db.query(
        'expense_splits',
        where: 'expense_id = ?',
        whereArgs: [expense.id],
      );

      final splits = splitsData
          .map((s) => ExpenseSplitModel.fromJson(s))
          .toList();

      result.add(ExpenseWithSplits(expense: expense, splits: splits));
    }

    return result;
  }

  /// Get standalone expenses (no trip)
  Future<List<ExpenseWithSplits>> getStandaloneExpenses() async {
    final db = await _dbHelper.database;

    // Get expenses with no trip_id where user is involved
    final expenses = await db.rawQuery(
      '''
      SELECT DISTINCT e.* FROM expenses e
      LEFT JOIN expense_splits es ON e.id = es.expense_id
      WHERE e.trip_id IS NULL AND (e.paid_by = ? OR es.user_id = ?)
      ORDER BY e.created_at DESC
    ''',
      [currentUserId, currentUserId],
    );

    // Get splits for each expense
    final result = <ExpenseWithSplits>[];
    for (final expenseMap in expenses) {
      final expense = ExpenseModel.fromJson(expenseMap);

      final splitsData = await db.query(
        'expense_splits',
        where: 'expense_id = ?',
        whereArgs: [expense.id],
      );

      final splits = splitsData
          .map((s) => ExpenseSplitModel.fromJson(s))
          .toList();

      result.add(ExpenseWithSplits(expense: expense, splits: splits));
    }

    return result;
  }

  /// Get a single expense with splits
  Future<ExpenseWithSplits> getExpenseById(String expenseId) async {
    final db = await _dbHelper.database;

    final expenseData = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [expenseId],
      limit: 1,
    );

    if (expenseData.isEmpty) {
      throw Exception('Expense not found');
    }

    final expense = ExpenseModel.fromJson(expenseData.first);

    final splitsData = await db.query(
      'expense_splits',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );

    final splits = splitsData
        .map((s) => ExpenseSplitModel.fromJson(s))
        .toList();

    return ExpenseWithSplits(expense: expense, splits: splits);
  }

  /// Create expense with equal splits (supports standalone)
  Future<ExpenseModel> createExpense({
    String? tripId, // Optional for standalone expenses
    required String title,
    String? description,
    required double amount,
    String? category,
    required String paidBy,
    required List<String> splitWith,
    String splitType = 'equal',
    DateTime? transactionDate,
  }) async {
    final db = await _dbHelper.database;
    final expenseId = _uuid.v4();
    final now = DateTime.now();

    // Create expense
    final expense = ExpenseModel(
      id: expenseId,
      tripId: tripId, // Can be null for standalone
      title: title,
      description: description,
      amount: amount,
      currency: 'INR',
      category: category,
      paidBy: paidBy,
      splitType: splitType,
      transactionDate: transactionDate ?? now,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('expenses', {
      'id': expense.id,
      'trip_id': expense.tripId,
      'title': expense.title,
      'description': expense.description,
      'amount': expense.amount,
      'currency': expense.currency,
      'category': expense.category,
      'paid_by': expense.paidBy,
      'split_type': expense.splitType,
      'receipt_url': expense.receiptUrl,
      'transaction_date': expense.transactionDate?.toIso8601String(),
      'created_at': expense.createdAt?.toIso8601String(),
      'updated_at': expense.updatedAt?.toIso8601String(),
    });

    // Create splits (equal split)
    final splitAmount = amount / splitWith.length;
    for (final userId in splitWith) {
      final splitId = _uuid.v4();
      await db.insert('expense_splits', {
        'id': splitId,
        'expense_id': expenseId,
        'user_id': userId,
        'amount': splitAmount,
        'is_settled': false,
        'created_at': now.toIso8601String(),
      });
    }

    return expense;
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
    final db = await _dbHelper.database;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (amount != null) updates['amount'] = amount;
    if (category != null) updates['category'] = category;
    if (transactionDate != null) {
      updates['transaction_date'] = transactionDate.toIso8601String();
    }

    await db.update(
      'expenses',
      updates,
      where: 'id = ?',
      whereArgs: [expenseId],
    );

    // Get updated expense
    final result = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [expenseId],
      limit: 1,
    );

    return ExpenseModel.fromJson(result.first);
  }

  /// Delete expense (cascades to splits)
  Future<void> deleteExpense(String expenseId) async {
    final db = await _dbHelper.database;

    // Delete splits first
    await db.delete(
      'expense_splits',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );

    // Delete expense
    await db.delete('expenses', where: 'id = ?', whereArgs: [expenseId]);
  }

  /// Calculate balances for trip or user
  Future<List<BalanceSummary>> getBalances({
    String? tripId,
    String? userId,
  }) async {
    final db = await _dbHelper.database;

    final balances = <String, BalanceSummary>{};

    // Build query based on parameters
    List<Map<String, Object?>> expenses;
    if (tripId != null) {
      // Get all trip members first
      final membersData = await db.query(
        'trip_members',
        where: 'trip_id = ?',
        whereArgs: [tripId],
      );

      // Initialize balances for trip members
      for (final member in membersData) {
        final memberId = member['user_id'] as String;
        balances[memberId] = BalanceSummary(
          userId: memberId,
          userName: 'Member $memberId',
          totalPaid: 0,
          totalOwed: 0,
          balance: 0,
        );
      }

      // Get all expenses for trip
      expenses = await db.query(
        'expenses',
        where: 'trip_id = ?',
        whereArgs: [tripId],
      );
    } else if (userId != null) {
      // Get user's standalone expenses
      expenses = await db.rawQuery(
        '''
        SELECT DISTINCT e.* FROM expenses e
        LEFT JOIN expense_splits es ON e.id = es.expense_id
        WHERE e.trip_id IS NULL AND (e.paid_by = ? OR es.user_id = ?)
      ''',
        [userId, userId],
      );
    } else {
      return [];
    }

    for (final expenseMap in expenses) {
      final expenseId = expenseMap['id'] as String;
      final paidBy = expenseMap['paid_by'] as String;
      final amount = expenseMap['amount'] as double;

      // Initialize if not exists (for standalone expenses)
      if (!balances.containsKey(paidBy)) {
        balances[paidBy] = BalanceSummary(
          userId: paidBy,
          userName: 'User $paidBy',
          totalPaid: 0,
          totalOwed: 0,
          balance: 0,
        );
      }

      // Add to totalPaid
      balances[paidBy] = BalanceSummary(
        userId: balances[paidBy]!.userId,
        userName: balances[paidBy]!.userName,
        totalPaid: balances[paidBy]!.totalPaid + amount,
        totalOwed: balances[paidBy]!.totalOwed,
        balance: 0,
      );

      // Get splits for this expense
      final splits = await db.query(
        'expense_splits',
        where: 'expense_id = ? AND is_settled = ?',
        whereArgs: [expenseId, 0],
      );

      for (final split in splits) {
        final splitUserId = split['user_id'] as String;
        final splitAmount = split['amount'] as double;

        // Initialize if not exists (for standalone expenses)
        if (!balances.containsKey(splitUserId)) {
          balances[splitUserId] = BalanceSummary(
            userId: splitUserId,
            userName: 'User $splitUserId',
            totalPaid: 0,
            totalOwed: 0,
            balance: 0,
          );
        }

        balances[splitUserId] = BalanceSummary(
          userId: balances[splitUserId]!.userId,
          userName: balances[splitUserId]!.userName,
          totalPaid: balances[splitUserId]!.totalPaid,
          totalOwed: balances[splitUserId]!.totalOwed + splitAmount,
          balance: 0,
        );
      }
    }

    // Calculate final balances
    final result = <BalanceSummary>[];
    balances.forEach((userId, summary) {
      final balance = summary.totalPaid - summary.totalOwed;
      result.add(
        BalanceSummary(
          userId: userId,
          userName: summary.userName,
          totalPaid: summary.totalPaid,
          totalOwed: summary.totalOwed,
          balance: balance,
        ),
      );
    });

    return result;
  }

  /// Create settlement (supports standalone)
  Future<SettlementModel> createSettlement({
    String? tripId, // Optional for standalone
    required String fromUser,
    required String toUser,
    required double amount,
    String? paymentMethod,
  }) async {
    final db = await _dbHelper.database;
    final settlementId = _uuid.v4();
    final now = DateTime.now();

    final settlement = SettlementModel(
      id: settlementId,
      tripId: tripId, // Can be null
      fromUser: fromUser,
      toUser: toUser,
      amount: amount,
      currency: 'INR',
      paymentMethod: paymentMethod,
      status: 'pending',
      transactionDate: now,
      createdAt: now,
    );

    await db.insert('settlements', {
      'id': settlement.id,
      'trip_id': settlement.tripId,
      'from_user': settlement.fromUser,
      'to_user': settlement.toUser,
      'amount': settlement.amount,
      'currency': settlement.currency,
      'payment_method': settlement.paymentMethod,
      'payment_proof_url': settlement.paymentProofUrl,
      'status': settlement.status,
      'transaction_date': settlement.transactionDate?.toIso8601String(),
      'created_at': settlement.createdAt?.toIso8601String(),
    });

    return settlement;
  }

  /// Get settlements (trip or user)
  Future<List<SettlementModel>> getSettlements({
    String? tripId,
    String? userId,
  }) async {
    final db = await _dbHelper.database;

    List<Map<String, Object?>> data;

    if (tripId != null) {
      data = await db.query(
        'settlements',
        where: 'trip_id = ?',
        whereArgs: [tripId],
        orderBy: 'created_at DESC',
      );
    } else if (userId != null) {
      data = await db.rawQuery(
        '''
        SELECT * FROM settlements
        WHERE trip_id IS NULL AND (from_user = ? OR to_user = ?)
        ORDER BY created_at DESC
      ''',
        [userId, userId],
      );
    } else {
      data = [];
    }

    return data.map((s) => SettlementModel.fromJson(s)).toList();
  }

  /// Update settlement status
  Future<SettlementModel> updateSettlementStatus({
    required String settlementId,
    required String status,
    String? paymentProofUrl,
  }) async {
    final db = await _dbHelper.database;

    await db.update(
      'settlements',
      {
        'status': status,
        if (paymentProofUrl != null) 'payment_proof_url': paymentProofUrl,
      },
      where: 'id = ?',
      whereArgs: [settlementId],
    );

    final result = await db.query(
      'settlements',
      where: 'id = ?',
      whereArgs: [settlementId],
      limit: 1,
    );

    return SettlementModel.fromJson(result.first);
  }
}
