import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/network/supabase_client.dart';
import '../providers/expense_providers.dart';

/// Manual test page for expense CRUD operations
/// This page allows manual testing of all expense operations
class ExpenseTestPage extends ConsumerStatefulWidget {
  const ExpenseTestPage({super.key});

  @override
  ConsumerState<ExpenseTestPage> createState() => _ExpenseTestPageState();
}

class _ExpenseTestPageState extends ConsumerState<ExpenseTestPage> {
  final List<String> _testResults = [];
  bool _isRunning = false;
  String? _lastCreatedExpenseId;

  void _log(String message) {
    setState(() {
      _testResults.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
  }

  Future<void> _runAllTests() async {
    setState(() {
      _testResults.clear();
      _isRunning = true;
    });

    try {
      _log('🚀 Starting expense CRUD tests...');

      await _testCreate();
      await Future.delayed(const Duration(milliseconds: 500));

      await _testRead();
      await Future.delayed(const Duration(milliseconds: 500));

      await _testUpdate();
      await Future.delayed(const Duration(milliseconds: 500));

      await _testDelete();

      _log('✅ All tests completed successfully!');
    } catch (e) {
      _log('❌ Test failed: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  Future<void> _testCreate() async {
    _log('\n📝 TEST 1: CREATE Expense');

    try {
      // Get current user ID from Supabase (online-only mode)
      final currentUserId = SupabaseClientWrapper.currentUserId;

      if (currentUserId == null || currentUserId.isEmpty) {
        throw Exception('User not logged in');
      }

      _log('Creating standalone expense...');

      final controller = ref.read(expenseControllerProvider.notifier);
      final expense = await controller.createExpense(
        tripId: null, // Standalone
        title: 'Test Expense ${DateTime.now().millisecond}',
        description: 'This is a test expense',
        amount: 1000.0,
        category: 'food',
        paidBy: currentUserId,
        splitWith: [currentUserId],
        transactionDate: DateTime.now(),
      );

      _lastCreatedExpenseId = expense.id;

      _log('✅ Expense created!');
      _log('   ID: ${expense.id}');
      _log('   Title: ${expense.title}');
      _log('   Amount: ₹${expense.amount}');
      _log('   Paid by: ${expense.paidBy}');
    } catch (e) {
      _log('❌ CREATE failed: $e');
      rethrow;
    }
  }

  Future<void> _testRead() async {
    _log('\n📖 TEST 2: READ Expenses');

    try {
      _log('Fetching all user expenses...');

      // Invalidate to force refresh
      ref.invalidate(userExpensesProvider);

      await Future.delayed(const Duration(milliseconds: 300));

      final expensesAsync = ref.read(userExpensesProvider);

      expensesAsync.when(
        data: (expenses) {
          _log('✅ Found ${expenses.length} expenses');
          if (expenses.isNotEmpty) {
            _log('   Latest: ${expenses.first.expense.title} - ₹${expenses.first.expense.amount}');
          }

          // Verify our created expense exists
          if (_lastCreatedExpenseId != null) {
            final found = expenses.any((e) => e.expense.id == _lastCreatedExpenseId);
            if (found) {
              _log('✅ Verified: Created expense found in list');
            } else {
              throw Exception('Created expense not found in list!');
            }
          }
        },
        loading: () {
          _log('⏳ Loading...');
        },
        error: (error, stack) {
          throw error;
        },
      );

      // Test reading single expense
      if (_lastCreatedExpenseId != null) {
        _log('Fetching single expense by ID...');
        ref.invalidate(expenseProvider(_lastCreatedExpenseId!));

        await Future.delayed(const Duration(milliseconds: 300));

        final expenseAsync = ref.read(expenseProvider(_lastCreatedExpenseId!));
        expenseAsync.when(
          data: (expenseWithSplits) {
            _log('✅ Fetched single expense: ${expenseWithSplits.expense.title}');
            _log('   Splits: ${expenseWithSplits.splits.length}');
          },
          loading: () => _log('⏳ Loading single expense...'),
          error: (error, stack) => throw error,
        );
      }
    } catch (e) {
      _log('❌ READ failed: $e');
      rethrow;
    }
  }

  Future<void> _testUpdate() async {
    _log('\n📝 TEST 3: UPDATE Expense');

    if (_lastCreatedExpenseId == null) {
      _log('⚠️  Skipping UPDATE: No expense to update');
      return;
    }

    try {
      _log('Updating expense...');

      final controller = ref.read(expenseControllerProvider.notifier);
      final updatedExpense = await controller.updateExpense(
        expenseId: _lastCreatedExpenseId!,
        title: 'Updated Test Expense',
        description: 'This expense was updated',
        amount: 1500.0,
        category: 'transport',
      );

      _log('✅ Expense updated!');
      _log('   New title: ${updatedExpense.title}');
      _log('   New amount: ₹${updatedExpense.amount}');
      _log('   New category: ${updatedExpense.category}');

      // Verify update by reading again
      ref.invalidate(expenseProvider(_lastCreatedExpenseId!));
      await Future.delayed(const Duration(milliseconds: 300));

      final expenseAsync = ref.read(expenseProvider(_lastCreatedExpenseId!));
      expenseAsync.when(
        data: (expenseWithSplits) {
          if (expenseWithSplits.expense.title == 'Updated Test Expense' &&
              expenseWithSplits.expense.amount == 1500.0) {
            _log('✅ Verified: Update persisted in database');
          } else {
            throw Exception('Update not persisted correctly!');
          }
        },
        loading: () {},
        error: (error, stack) => throw error,
      );
    } catch (e) {
      _log('❌ UPDATE failed: $e');
      rethrow;
    }
  }

  Future<void> _testDelete() async {
    _log('\n🗑️  TEST 4: DELETE Expense');

    if (_lastCreatedExpenseId == null) {
      _log('⚠️  Skipping DELETE: No expense to delete');
      return;
    }

    try {
      _log('Deleting expense...');

      final controller = ref.read(expenseControllerProvider.notifier);
      await controller.deleteExpense(_lastCreatedExpenseId!);

      _log('✅ Expense deleted!');

      // Verify deletion
      ref.invalidate(userExpensesProvider);
      await Future.delayed(const Duration(milliseconds: 300));

      final expensesAsync = ref.read(userExpensesProvider);
      expensesAsync.when(
        data: (expenses) {
          final found = expenses.any((e) => e.expense.id == _lastCreatedExpenseId);
          if (!found) {
            _log('✅ Verified: Expense removed from database');
          } else {
            throw Exception('Expense still exists after deletion!');
          }
        },
        loading: () {},
        error: (error, stack) => throw error,
      );

      _lastCreatedExpenseId = null;
    } catch (e) {
      _log('❌ DELETE failed: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense CRUD Tests'),
        backgroundColor: context.primaryColor,
        foregroundColor: context.surfaceColor,
      ),
      body: Column(
        children: [
          // Test Controls
          Container(
            padding: const EdgeInsets.all(16),
            color: context.backgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _runAllTests,
                  icon: Icon(_isRunning ? Icons.hourglass_empty : Icons.play_arrow),
                  label: Text(_isRunning ? 'Running Tests...' : 'Run All Tests'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: context.primaryColor,
                    foregroundColor: context.surfaceColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isRunning ? null : _testCreate,
                        icon: const Icon(Icons.add),
                        label: const Text('Test CREATE'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isRunning ? null : _testRead,
                        icon: const Icon(Icons.search),
                        label: const Text('Test READ'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isRunning ? null : _testUpdate,
                        icon: const Icon(Icons.edit),
                        label: const Text('Test UPDATE'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isRunning ? null : _testDelete,
                        icon: const Icon(Icons.delete),
                        label: const Text('Test DELETE'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _testResults.clear());
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Results'),
                ),
              ],
            ),
          ),

          // Test Results
          Expanded(
            child: Container(
              color: context.textColor.withValues(alpha: 0.9),
              padding: const EdgeInsets.all(16),
              child: _testResults.isEmpty
                  ? Center(
                      child: Text(
                        'No tests run yet.\nTap "Run All Tests" to start.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.surfaceColor.withValues(alpha: 0.5)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _testResults.length,
                      itemBuilder: (context, index) {
                        final result = _testResults[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            result,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: result.contains('❌')
                                  ? context.errorColor.withValues(alpha: 0.8)
                                  : result.contains('✅')
                                      ? context.successColor.withValues(alpha: 0.8)
                                      : result.contains('⚠️')
                                          ? context.textColor.withValues(alpha: 0.7)
                                          : context.surfaceColor,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
