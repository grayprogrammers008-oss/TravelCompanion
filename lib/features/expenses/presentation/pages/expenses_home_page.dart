import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../shared/models/expense_model.dart';
import '../providers/expense_providers.dart';
import '../widgets/payment_options_sheet.dart';

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
    final themeData = context.appThemeData;

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
      floatingActionButton: ScaleAnimation(
        duration: AppAnimations.slow,
        curve: AppAnimations.spring,
        child: AnimatedScaleButton(
          onTap: () => context.push('/expenses/add'),
          child: Container(
            decoration: BoxDecoration(
              gradient: themeData.glossyGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: themeData.glossyShadow,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: FloatingActionButton.extended(
                onPressed: null, // Handled by AnimatedScaleButton
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.add, color: Colors.white, size: 24),
                label: const Text(
                  'Add Expense',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
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
      loading: () => const Center(child: AppLoadingIndicator(message: 'Loading expenses...')),
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
            Icon(icon, size: 120, color: context.textColor.withValues(alpha: 0.2)),
            const SizedBox(height: 24),
            Text(
              'No Expenses',
              style: context.headlineSmall.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(color: context.textColor.withValues(alpha: 0.6)),
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
                context.primaryColor,
                context.primaryColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Total Expenses',
                style: context.titleMedium.copyWith(color: context.surfaceColor),
              ),
              const SizedBox(height: 8),
              Text(
                total.toINR(),
                style: context.headlineMedium.copyWith(
                  color: context.surfaceColor,
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
                                ).withValues(alpha: 0.1),
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
                                    style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (expense.category != null)
                                    Text(
                                      expense.category!,
                                      style: context.bodySmall.copyWith(color: context.textColor.withValues(alpha: 0.6)),
                                    ),
                                ],
                              ),
                            ),

                            // Amount
                            Text(
                              expense.amount.toINR(),
                              style: context.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.primaryColor,
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
                                color: context.textColor.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Trip',
                                style: context.bodySmall.copyWith(color: context.textColor.withValues(alpha: 0.7)),
                              ),
                              const SizedBox(width: 12),
                            ],

                            // Split info
                            Icon(
                              Icons.group_outlined,
                              size: 16,
                              color: context.textColor.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Split ${splits.length} ways',
                              style: context.bodySmall.copyWith(color: context.textColor.withValues(alpha: 0.7)),
                            ),

                            const Spacer(),

                            // Date
                            if (expense.transactionDate != null)
                              Text(
                                expense.transactionDate!.toFormattedDate(),
                                style: context.bodySmall.copyWith(color: context.textColor.withValues(alpha: 0.6)),
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
            Icon(Icons.error_outline, size: 64, color: context.errorColor),
            const SizedBox(height: 16),
            Text(
              'Error loading expenses',
              style: context.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: context.bodySmall,
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
                    color: context.textColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                expense.title,
                style: context.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Trip badge
              if (expense.tripId != null)
                Chip(
                  avatar: const Icon(Icons.flight, size: 16),
                  label: const Text('Trip Expense'),
                  backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                ),
              const SizedBox(height: 16),

              // Amount
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Amount',
                      style: context.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense.amount.toINR(),
                      style: context.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.primaryColor,
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
                  style: context.titleMedium.copyWith(
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
                style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
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
                        style: context.titleMedium,
                      ),
                      subtitle: split.isSettled
                          ? Text(
                              'Settled',
                              style: TextStyle(color: context.successColor),
                            )
                          : Text(
                              'Not settled',
                              style: TextStyle(color: context.textColor.withValues(alpha: 0.7)),
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
                              foregroundColor: context.errorColor,
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
                            SnackBar(
                              content: const Text('Expense deleted successfully'),
                              backgroundColor: context.successColor,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: context.errorColor,
                            ),
                          );
                        }
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.errorColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete, color: context.errorColor),
                      const SizedBox(width: 8),
                      Text(
                        'Delete Expense',
                        style: TextStyle(color: context.errorColor),
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
                    color: context.textColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'Your Balances',
                style: context.headlineSmall.copyWith(
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
                                        style: context.titleMedium,
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
                                          style: context.bodySmall,
                                        ),
                                        Text(
                                          balance.totalPaid.toINR(),
                                          style: context.titleSmall,
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Owes',
                                          style: context.bodySmall,
                                        ),
                                        Text(
                                          balance.totalOwed.toINR(),
                                          style: context.titleSmall,
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Balance',
                                          style: context.bodySmall,
                                        ),
                                        Text(
                                          balance.balance.abs().toINR(),
                                          style: context.titleMedium.copyWith(
                                            color: isZero
                                                ? context.textColor.withValues(alpha: 0.5)
                                                : isPositive
                                                ? context.successColor
                                                : context.errorColor,
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
                                    style: context.bodySmall.copyWith(
                                      color: isPositive
                                          ? context.successColor
                                          : context.errorColor,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Payment action buttons
                                  Row(
                                    children: [
                                      // Pay Now button (shown when user owes money)
                                      if (!isPositive)
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              // Prompt for UPI ID
                                              final upiId = await _showUPIInputDialog(
                                                context,
                                                balance.userName,
                                              );

                                              if (upiId != null && upiId.isNotEmpty && mounted && context.mounted) {
                                                PaymentOptionsSheet.show(
                                                  context,
                                                  recipientUPIId: upiId,
                                                  recipientName: balance.userName,
                                                  amount: balance.balance.abs(),
                                                  note: 'Settlement for shared expenses',
                                                );
                                              }
                                            },
                                            icon: const Icon(Icons.payment, size: 18),
                                            label: const Text('Pay Now'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: context.successColor,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 10,
                                              ),
                                            ),
                                          ),
                                        ),
                                      // Request Payment button (shown when user gets money back)
                                      if (isPositive)
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              // TODO: Implement request payment notification
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Payment request sent to ${balance.userName}'),
                                                  backgroundColor: context.successColor,
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.request_page, size: 18),
                                            label: const Text('Request Payment'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: context.primaryColor,
                                              side: BorderSide(color: context.primaryColor),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 10,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
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
                      const Center(child: AppLoadingIndicator(message: 'Loading balances...')),
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

  Future<String?> _showUPIInputDialog(BuildContext context, String userName) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter UPI ID for $userName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please enter the UPI ID to send payment',
              style: context.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'UPI ID',
                hintText: 'name@upi',
                prefixIcon: Icon(Icons.account_balance),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 8),
            Text(
              'Example: username@paytm, username@ybl',
              style: context.bodySmall.copyWith(
                color: context.textColor.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final upiId = controller.text.trim();
              if (upiId.isNotEmpty) {
                Navigator.pop(context, upiId);
              }
            },
            child: const Text('Continue'),
          ),
        ],
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
