import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/trip_permissions.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/services/expense_pdf_service.dart';
import '../../../../shared/models/expense_model.dart';
import '../../../../shared/models/trip_model.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/expense_providers.dart';
import '../widgets/payment_options_sheet.dart';
import '../widgets/who_owes_whom_card.dart';

class ExpenseListPage extends ConsumerWidget {
  final String tripId;

  const ExpenseListPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(tripExpensesProvider(tripId));
    final balancesAsync = ref.watch(tripBalancesProvider(tripId));
    final themeData = context.appThemeData;
    final tripAsync = ref.watch(tripProvider(tripId));
    final currentUserId = ref.watch(authStateProvider).value;

    // Check if user can add expenses (all trip members can add)
    final canAddExpenses = tripAsync.whenOrNull(
      data: (tripWithMembers) => TripPermissions.canAddExpenses(
        currentUserId: currentUserId,
        tripWithMembers: tripWithMembers,
      ),
    ) ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/trips/$tripId');
            }
          },
        ),
        title: const Text('Expenses'),
        actions: [
          // Export PDF button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _showExportOptions(context, ref, tripAsync, expensesAsync),
            tooltip: 'Export Report',
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () {
              _showBalancesSheet(context, balancesAsync);
            },
            tooltip: 'View Balances',
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildExpensesList(context, expenses, ref, tripAsync, currentUserId, balancesAsync);
        },
        loading: () => const Center(
          child: AppLoadingIndicator(
            message: 'Loading expenses...',
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: context.errorColor),
              const SizedBox(height: 16),
              Text('Error loading expenses:\n${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(tripExpensesProvider(tripId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      // All trip members can add expenses
      floatingActionButton: canAddExpenses
          ? ScaleAnimation(
              duration: AppAnimations.slow,
              curve: AppAnimations.spring,
              child: AnimatedScaleButton(
                onTap: () => _showAddExpenseOptions(context, tripId),
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
                      icon: Icon(Icons.add, color: context.surfaceColor, size: 24),
                      label: Text(
                        'Add Expense',
                        style: context.titleMedium.copyWith(
                          color: context.surfaceColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _showExportOptions(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<TripWithMembers> tripAsync,
    AsyncValue<List<ExpenseWithSplits>> expensesAsync,
  ) {
    final trip = tripAsync.whenOrNull(data: (data) => data.trip);
    final expenses = expensesAsync.whenOrNull(data: (data) => data);

    if (trip == null || expenses == null || expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No expenses to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.neutral300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Title
                Text(
                  'Export Expense Report',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // Summary
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${expenses.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Text('Expenses', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            expenses.fold<double>(0, (sum, e) => sum + e.expense.amount).toINR(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Text('Total', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Share option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(Icons.share, color: Colors.green),
                  ),
                  title: const Text(
                    'Share PDF',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Send via WhatsApp, Email, etc.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    _exportPdf(context, trip, expenses, share: true);
                  },
                ),

                const SizedBox(height: AppTheme.spacingSm),

                // Print/Preview option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(Icons.print, color: Colors.purple),
                  ),
                  title: const Text(
                    'Preview & Print',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('View PDF and print if needed'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    _exportPdf(context, trip, expenses, share: false);
                  },
                ),

                const SizedBox(height: AppTheme.spacingMd),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportPdf(
    BuildContext context,
    TripModel trip,
    List<ExpenseWithSplits> expensesWithSplits,
    {required bool share}
  ) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Convert ExpenseWithSplits to ExpenseModel list
      final expenses = expensesWithSplits.map((e) => e.expense).toList();

      if (share) {
        await ExpensePdfService.sharePdf(
          trip: trip,
          expenses: expenses,
          budget: trip.cost,
        );
      } else {
        await ExpensePdfService.printPdf(
          trip: trip,
          expenses: expenses,
          budget: trip.cost,
        );
      }

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddExpenseOptions(BuildContext context, String tripId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.neutral300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Title
                Text(
                  'Add Expense',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Manual Entry option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(Icons.edit, color: Colors.blue),
                  ),
                  title: const Text(
                    'Enter Manually',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Type in expense details'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    context.push('/trips/$tripId/expenses/add');
                  },
                ),

                const SizedBox(height: AppTheme.spacingSm),

                // Scan Bill option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(Icons.document_scanner, color: Colors.teal),
                  ),
                  title: const Text(
                    'Scan Bill',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Take a photo of your receipt'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    context.push('/trips/$tripId/expenses/scan');
                  },
                ),

                const SizedBox(height: AppTheme.spacingMd),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 120, color: context.textColor.withValues(alpha: 0.2)),
            const SizedBox(height: 24),
            Text(
              'No expenses yet',
              style: context.headlineSmall.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add expenses to track shared costs and settle up later',
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(color: context.textColor.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/trips/$tripId/expenses/add');
              },
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

  Widget _buildExpensesList(
    BuildContext context,
    List<ExpenseWithSplits> expenses,
    WidgetRef ref,
    AsyncValue<TripWithMembers> tripAsync,
    String? currentUserId,
    AsyncValue<List<BalanceSummary>> balancesAsync,
  ) {
    // Calculate total
    final total = expenses.fold<double>(0, (sum, e) => sum + e.expense.amount);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Who Owes Whom card - ALWAYS VISIBLE at the top
          balancesAsync.when(
            data: (balances) => WhoOwesWhomCard(
              balances: balances,
              currentUserId: currentUserId,
              onSettlePressed: () {
                // Navigate to settlement summary page
                context.push('/trips/$tripId/expenses/settle');
              },
              onPayPressed: (recipientName, amount) async {
                // Prompt for UPI ID and launch payment
                final upiId = await _showUPIInputDialog(context, recipientName);
                if (upiId != null && upiId.isNotEmpty && context.mounted) {
                  PaymentOptionsSheet.show(
                    context,
                    recipientUPIId: upiId,
                    recipientName: recipientName,
                    amount: amount,
                    note: 'Settlement for trip expenses',
                  );
                }
              },
            ),
            loading: () => Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Total summary card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
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

          const SizedBox(height: 16),

          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 20,
                  color: context.textColor.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'All Expenses',
                  style: context.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${expenses.length} items',
                  style: context.bodySmall.copyWith(
                    color: context.textColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Expenses list - inline items
          ...expenses.map((expenseWithSplits) {
            final expense = expenseWithSplits.expense;
            final splits = expenseWithSplits.splits;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    _showExpenseDetails(context, expenseWithSplits, ref, tripAsync, currentUserId);
                  },
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

                        // Paid by and split info
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: context.textColor.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Paid by: ${expense.payerName ?? expense.paidBy}',
                                style: context.bodySmall.copyWith(color: context.textColor.withValues(alpha: 0.7)),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
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
                          ],
                        ),

                        // Date
                        if (expense.transactionDate != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: context.textColor.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                expense.transactionDate!.toFormattedDate(),
                                style: context.bodySmall.copyWith(color: context.textColor.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // Bottom padding for FAB
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showExpenseDetails(
    BuildContext context,
    ExpenseWithSplits expenseWithSplits,
    WidgetRef ref,
    AsyncValue<TripWithMembers> tripAsync,
    String? currentUserId,
  ) {
    final expense = expenseWithSplits.expense;
    final splits = expenseWithSplits.splits;

    // Check if user can edit/delete this expense
    final canEditExpense = tripAsync.whenOrNull(
      data: (tripWithMembers) => TripPermissions.canEditExpense(
        currentUserId: currentUserId,
        expenseCreatedBy: expense.paidBy, // The payer is considered the creator
        tripWithMembers: tripWithMembers,
      ),
    ) ?? false;

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
                      title: Text(split.userName ?? 'Member ${split.userId}'),
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

              // Delete button - only show if user can edit this expense
              if (canEditExpense) ...[
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
                          ref.invalidate(tripExpensesProvider(tripId));
                          ref.invalidate(tripBalancesProvider(tripId));
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
            ],
          ),
        ),
      ),
    );
  }

  void _showBalancesSheet(
    BuildContext context,
    AsyncValue<List<BalanceSummary>> balancesAsync,
  ) {
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
                'Balances',
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

                                              if (upiId != null && upiId.isNotEmpty && context.mounted) {
                                                PaymentOptionsSheet.show(
                                                  context,
                                                  recipientUPIId: upiId,
                                                  recipientName: balance.userName,
                                                  amount: balance.balance.abs(),
                                                  note: 'Settlement for trip expenses',
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
                  loading: () => const Center(
                    child: AppLoadingIndicator(
                      message: 'Loading balances...',
                    ),
                  ),
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
