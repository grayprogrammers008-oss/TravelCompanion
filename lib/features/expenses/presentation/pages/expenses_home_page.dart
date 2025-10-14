import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/models/expense_model.dart';
import '../providers/expense_providers.dart';

enum ExpenseFilter { all, trip, standalone }

class ExpensesHomePage extends ConsumerStatefulWidget {
  const ExpensesHomePage({super.key});

  @override
  ConsumerState<ExpensesHomePage> createState() => _ExpensesHomePageState();
}

class _ExpensesHomePageState extends ConsumerState<ExpensesHomePage> {
  ExpenseFilter _selectedFilter = ExpenseFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () => _showBalancesSheet(context, ref),
            tooltip: 'View Balances',
          ),
          PopupMenuButton<ExpenseFilter>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) {
              setState(() {
                _selectedFilter = filter;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ExpenseFilter.all,
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive),
                    SizedBox(width: 12),
                    Text('All Expenses'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ExpenseFilter.trip,
                child: Row(
                  children: [
                    Icon(Icons.flight),
                    SizedBox(width: 12),
                    Text('Trip Expenses'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ExpenseFilter.standalone,
                child: Row(
                  children: [
                    Icon(Icons.receipt),
                    SizedBox(width: 12),
                    Text('Personal Expenses'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildExpenseList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/expenses/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildExpenseList() {
    late final AsyncValue<List<ExpenseWithSplits>> expensesAsync;

    switch (_selectedFilter) {
      case ExpenseFilter.all:
        expensesAsync = ref.watch(userExpensesProvider);
        break;
      case ExpenseFilter.trip:
        // Filter trip expenses from all expenses
        final allExpenses = ref.watch(userExpensesProvider);
        expensesAsync = allExpenses.whenData(
          (expenses) =>
              expenses.where((e) => e.expense.tripId != null).toList(),
        );
        break;
      case ExpenseFilter.standalone:
        expensesAsync = ref.watch(standaloneExpensesProvider);
        break;
    }

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return _buildEmptyState();
        }
        return _buildExpensesList(expenses);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_selectedFilter) {
      case ExpenseFilter.all:
        message = 'No expenses yet. Add your first expense to get started!';
        icon = Icons.receipt_long;
        break;
      case ExpenseFilter.trip:
        message = 'No trip expenses found';
        icon = Icons.flight;
        break;
      case ExpenseFilter.standalone:
        message = 'No personal expenses found';
        icon = Icons.account_balance_wallet;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 120, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'No Expenses',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/expenses/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList(List<ExpenseWithSplits> expenses) {
    // Calculate total
    final total = expenses.fold<double>(0, (sum, e) => sum + e.expense.amount);

    return Column(
      children: [
        // Filter indicator chip
        if (_selectedFilter != ExpenseFilter.all)
          Container(
            padding: const EdgeInsets.all(8),
            child: Chip(
              avatar: Icon(
                _selectedFilter == ExpenseFilter.trip
                    ? Icons.flight
                    : Icons.account_balance_wallet,
                size: 18,
              ),
              label: Text(
                _selectedFilter == ExpenseFilter.trip
                    ? 'Trip Expenses'
                    : 'Personal Expenses',
              ),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _selectedFilter = ExpenseFilter.all;
                });
              },
            ),
          ),

        // Total summary card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Total Expenses',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                total.toINR(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Expenses list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expenseWithSplits = expenses[index];
              final expense = expenseWithSplits.expense;
              final splits = expenseWithSplits.splits;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _showExpenseDetails(context, expenseWithSplits),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Category icon
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(
                                  expense.category,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getCategoryIcon(expense.category),
                                color: _getCategoryColor(expense.category),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Title and amount
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expense.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (expense.category != null)
                                    Text(
                                      expense.category!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                            ),

                            // Amount
                            Text(
                              expense.amount.toINR(),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Metadata row
                        Row(
                          children: [
                            // Trip indicator
                            if (expense.tripId != null) ...[
                              Icon(
                                Icons.flight,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Trip',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[700]),
                              ),
                              const SizedBox(width: 12),
                            ],

                            // Split info
                            Icon(
                              Icons.group_outlined,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Split ${splits.length} ways',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[700]),
                            ),

                            const Spacer(),

                            // Date
                            if (expense.transactionDate != null)
                              Text(
                                expense.transactionDate!.toFormattedDate(),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading expenses',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(userExpensesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseDetails(
    BuildContext context,
    ExpenseWithSplits expenseWithSplits,
  ) {
    final expense = expenseWithSplits.expense;
    final splits = expenseWithSplits.splits;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                expense.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Trip badge
              if (expense.tripId != null)
                Chip(
                  avatar: const Icon(Icons.flight, size: 16),
                  label: const Text('Trip Expense'),
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.1),
                ),
              const SizedBox(height: 16),

              // Amount
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Amount',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense.amount.toINR(),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Description
              if (expense.description != null) ...[
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(expense.description!),
                const SizedBox(height: 16),
              ],

              // Splits
              Text(
                'Split Details',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: splits.length,
                  itemBuilder: (context, index) {
                    final split = splits[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          (split.userName ?? split.userId)
                              .substring(0, 1)
                              .toUpperCase(),
                        ),
                      ),
                      title: Text(split.userName ?? 'User ${split.userId}'),
                      trailing: Text(
                        split.amount.toINR(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: split.isSettled
                          ? const Text(
                              'Settled',
                              style: TextStyle(color: Colors.green),
                            )
                          : const Text(
                              'Not settled',
                              style: TextStyle(color: Colors.orange),
                            ),
                    );
                  },
                ),
              ),

              // Delete button
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Expense'),
                        content: const Text(
                          'Are you sure you want to delete this expense?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      try {
                        await ref
                            .read(expenseControllerProvider.notifier)
                            .deleteExpense(expense.id);
                        ref.invalidate(userExpensesProvider);
                        ref.invalidate(standaloneExpensesProvider);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Expense deleted successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Delete Expense',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBalancesSheet(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(userBalancesProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'Your Balances',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: balancesAsync.when(
                  data: (balances) {
                    if (balances.isEmpty) {
                      return const Center(
                        child: Text('No balance information available'),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: balances.length,
                      itemBuilder: (context, index) {
                        final balance = balances[index];
                        final isPositive = balance.balance > 0;
                        final isZero = balance.balance == 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      child: Text(
                                        balance.userName
                                            .substring(0, 1)
                                            .toUpperCase(),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        balance.userName,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Paid',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        Text(
                                          balance.totalPaid.toINR(),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Owes',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        Text(
                                          balance.totalOwed.toINR(),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Balance',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        Text(
                                          balance.balance.abs().toINR(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: isZero
                                                    ? Colors.grey
                                                    : isPositive
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (!isZero) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    isPositive
                                        ? 'Gets back ${balance.balance.toINR()}'
                                        : 'Owes ${balance.balance.abs().toINR()}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: isPositive
                                              ? Colors.green
                                              : Colors.red,
                                          fontStyle: FontStyle.italic,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      Center(child: Text('Error: ${error.toString()}')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'accommodation':
        return Icons.hotel;
      case 'activities':
        return Icons.local_activity;
      case 'shopping':
        return Icons.shopping_bag;
      default:
        return Icons.receipt;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'accommodation':
        return Colors.purple;
      case 'activities':
        return Colors.green;
      case 'shopping':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
