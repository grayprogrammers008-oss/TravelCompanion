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
import '../../../../core/widgets/destination_image.dart';
import '../../../../shared/models/expense_model.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../providers/expense_providers.dart';
import '../widgets/payment_options_sheet.dart';

enum ExpenseFilter { all, trip, standalone }

/// Available expense categories for filtering
enum ExpenseCategory { all, food, transport, accommodation, activities, shopping, other }

class ExpensesHomePage extends ConsumerStatefulWidget {
  const ExpensesHomePage({super.key});

  @override
  ConsumerState<ExpensesHomePage> createState() => _ExpensesHomePageState();
}

class _ExpensesHomePageState extends ConsumerState<ExpensesHomePage> {
  ExpenseFilter _selectedFilter = ExpenseFilter.all;
  ExpenseCategory _selectedCategory = ExpenseCategory.all;

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        backgroundColor: themeData.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        titleSpacing: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: themeData.primaryGradient,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            const Text(
              'Expenses',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
            onPressed: () => _showBalancesSheet(context, ref),
            tooltip: 'View Balances',
          ),
          PopupMenuButton<ExpenseFilter>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
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
          onTap: () => _showAddExpenseOptions(context, ref),
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
              onPressed: () => _showAddExpenseOptions(context, ref),
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
    // Apply category filter
    final filteredExpenses = _selectedCategory == ExpenseCategory.all
        ? expenses
        : expenses.where((e) {
            final category = e.expense.category?.toLowerCase();
            return category == _selectedCategory.name;
          }).toList();

    // Calculate total from filtered expenses
    final total = filteredExpenses.fold<double>(0, (sum, e) => sum + e.expense.amount);

    return Column(
      children: [
        // Category filter chips
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              _buildCategoryChip(ExpenseCategory.all, 'All', Icons.all_inclusive, Colors.grey),
              _buildCategoryChip(ExpenseCategory.food, 'Food', Icons.restaurant, Colors.orange),
              _buildCategoryChip(ExpenseCategory.transport, 'Transport', Icons.directions_car, Colors.blue),
              _buildCategoryChip(ExpenseCategory.accommodation, 'Stay', Icons.hotel, Colors.purple),
              _buildCategoryChip(ExpenseCategory.activities, 'Activities', Icons.local_activity, Colors.green),
              _buildCategoryChip(ExpenseCategory.shopping, 'Shopping', Icons.shopping_bag, Colors.pink),
              _buildCategoryChip(ExpenseCategory.other, 'Other', Icons.receipt, Colors.grey),
            ],
          ),
        ),

        // Filter indicator chip (for trip/standalone filter)
        if (_selectedFilter != ExpenseFilter.all)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            alignment: Alignment.centerLeft,
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

        // Total summary card with breakdown
        _buildSpendingBreakdownCard(context, expenses, total),

        // Expenses list
        Expanded(
          child: filteredExpenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_list_off,
                        size: 48,
                        color: context.textColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No ${_selectedCategory.name} expenses',
                        style: context.titleMedium.copyWith(
                          color: context.textColor.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _selectedCategory = ExpenseCategory.all),
                        child: const Text('Clear filter'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredExpenses.length,
            itemBuilder: (context, index) {
              final expenseWithSplits = filteredExpenses[index];
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
                            // Trip indicator with name
                            if (expense.tripId != null) ...[
                              Flexible(
                                flex: 0,
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 140),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: context.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.flight,
                                        size: 12,
                                        color: context.primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          expense.tripName ?? 'Trip',
                                          style: context.bodySmall.copyWith(
                                            color: context.primaryColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],

                            // Split info
                            Icon(
                              Icons.group_outlined,
                              size: 14,
                              color: context.textColor.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${splits.length} ways',
                              style: context.bodySmall.copyWith(
                                color: context.textColor.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),

                            const Spacer(),

                            // Date
                            if (expense.transactionDate != null)
                              Text(
                                expense.transactionDate!.toFormattedDate(),
                                style: context.bodySmall.copyWith(
                                  color: context.textColor.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
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

  /// Build a category filter chip
  Widget _buildCategoryChip(ExpenseCategory category, String label, IconData icon, Color color) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : color,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
        backgroundColor: color.withValues(alpha: 0.1),
        selectedColor: color,
        side: BorderSide(
          color: isSelected ? color : color.withValues(alpha: 0.3),
          width: isSelected ? 0 : 1,
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
      ),
    );
  }

  /// Build spending breakdown card with Personal vs Trip visualization
  Widget _buildSpendingBreakdownCard(BuildContext context, List<ExpenseWithSplits> allExpenses, double filteredTotal) {
    // Calculate Personal vs Trip breakdown from all expenses (not filtered)
    double personalTotal = 0;
    double tripTotal = 0;
    int personalCount = 0;
    int tripCount = 0;

    for (final e in allExpenses) {
      if (e.expense.tripId == null) {
        personalTotal += e.expense.amount;
        personalCount++;
      } else {
        tripTotal += e.expense.amount;
        tripCount++;
      }
    }

    final total = personalTotal + tripTotal;
    final personalPercent = total > 0 ? (personalTotal / total * 100) : 0.0;
    final tripPercent = total > 0 ? (tripTotal / total * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primaryColor,
                  context.primaryColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
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

          // Breakdown section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Visual bar chart
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: [
                        // Personal portion (orange)
                        if (personalPercent > 0)
                          Expanded(
                            flex: personalPercent.round(),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade400,
                                    Colors.orange.shade600,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Trip portion (blue)
                        if (tripPercent > 0)
                          Expanded(
                            flex: tripPercent.round(),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    context.primaryColor.withValues(alpha: 0.7),
                                    context.primaryColor,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Empty state
                        if (total == 0)
                          Expanded(
                            child: Container(
                              color: AppTheme.neutral200,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Legend and amounts
                Row(
                  children: [
                    // Personal
                    Expanded(
                      child: _buildBreakdownItem(
                        icon: Icons.person,
                        label: 'Personal',
                        amount: personalTotal,
                        count: personalCount,
                        percentage: personalPercent,
                        color: Colors.orange,
                      ),
                    ),
                    // Divider
                    Container(
                      height: 50,
                      width: 1,
                      color: AppTheme.neutral200,
                    ),
                    // Trip
                    Expanded(
                      child: _buildBreakdownItem(
                        icon: Icons.flight,
                        label: 'Trip',
                        amount: tripTotal,
                        count: tripCount,
                        percentage: tripPercent,
                        color: context.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem({
    required IconData icon,
    required String label,
    required double amount,
    required int count,
    required double percentage,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.neutral600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          amount.toINR(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$count expense${count == 1 ? '' : 's'} • ${percentage.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.neutral500,
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

  /// Show trip picker dialog when adding expense
  void _showAddExpenseOptions(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(userTripsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusXl),
            topRight: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: AppTheme.spacingMd),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingSm),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(
                        Icons.add_card,
                        color: context.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Text(
                      'Add Expense To...',
                      style: context.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Personal expense option
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                child: Card(
                  elevation: 0,
                  color: AppTheme.neutral100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    side: BorderSide(color: AppTheme.neutral200),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingSm),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.orange,
                      ),
                    ),
                    title: const Text(
                      'Personal Expense',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Track your own spending'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      context.push('/expenses/add');
                    },
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingSm),

              // Divider with "OR" text
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                  vertical: AppTheme.spacingSm,
                ),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                      child: Text(
                        'SELECT A TRIP',
                        style: context.bodySmall.copyWith(
                          color: AppTheme.neutral500,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),

              // Trip list
              Expanded(
                child: tripsAsync.when(
                  data: (trips) {
                    // Filter to only show active (non-completed) trips
                    final activeTrips = trips.where((t) => !t.trip.isCompleted).toList();

                    if (activeTrips.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingLg),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.flight_takeoff,
                                size: 48,
                                color: AppTheme.neutral400,
                              ),
                              const SizedBox(height: AppTheme.spacingMd),
                              Text(
                                'No active trips',
                                style: context.titleMedium.copyWith(
                                  color: AppTheme.neutral600,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingXs),
                              Text(
                                'Create a trip first to add shared expenses',
                                style: context.bodySmall.copyWith(
                                  color: AppTheme.neutral500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppTheme.spacingLg),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(bottomSheetContext);
                                  context.push('/trips/create');
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Create Trip'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                      itemCount: activeTrips.length,
                      itemBuilder: (context, index) {
                        final tripWithMembers = activeTrips[index];
                        final trip = tripWithMembers.trip;

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            side: BorderSide(color: AppTheme.neutral200),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMd,
                              vertical: AppTheme.spacingXs,
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: DestinationImage(
                                  tripName: trip.destination ?? trip.name,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            title: Text(
                              trip.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: AppTheme.neutral500,
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    trip.destination ?? 'No destination',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.neutral600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.people,
                                  size: 12,
                                  color: AppTheme.neutral500,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${tripWithMembers.members.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.neutral600,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingSm,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: context.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: 14,
                                    color: context.primaryColor,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: context.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(bottomSheetContext);
                              context.push('/trips/${trip.id}/expenses/add');
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: AppLoadingIndicator(message: 'Loading trips...'),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: context.errorColor),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text('Error loading trips', style: context.titleMedium),
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(error.toString(), style: context.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom padding
              const SizedBox(height: AppTheme.spacingMd),
            ],
          ),
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
                      leading: UserAvatarWidget(
                        imageUrl: split.avatarUrl,
                        userName: split.userName ?? split.userId,
                        size: 40,
                      ),
                      title: Text(split.userName ?? 'User ${split.userId}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            split.amount.toINR(),
                            style: context.titleMedium,
                          ),
                          // Settlement status badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: split.isSettled
                                  ? context.successColor.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              split.isSettled ? 'Settled' : 'Pending',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: split.isSettled ? context.successColor : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Edit and Delete buttons
              const SizedBox(height: 16),
              Row(
                children: [
                  // Edit button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditExpenseDialog(context, ref, expense);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Delete button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Expense'),
                            content: const Text(
                              'Are you sure you want to delete this expense?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
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
                      icon: Icon(Icons.delete, color: context.errorColor),
                      label: Text('Delete', style: TextStyle(color: context.errorColor)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.errorColor),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show edit expense dialog
  void _showEditExpenseDialog(BuildContext context, WidgetRef ref, ExpenseModel expense) {
    final titleController = TextEditingController(text: expense.title);
    final amountController = TextEditingController(text: expense.amount.toString());
    final descriptionController = TextEditingController(text: expense.description ?? '');
    String? selectedCategory = expense.category;
    DateTime? transactionDate = expense.transactionDate;
    bool isLoading = false;

    final categories = ['Food', 'Transport', 'Accommodation', 'Activities', 'Shopping', 'Other'];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit, color: context.primaryColor),
              ),
              const SizedBox(width: 12),
              const Text('Edit Expense'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),

                // Amount
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),

                // Category
                DropdownButtonFormField<String>(
                  value: selectedCategory != null
                      ? categories.firstWhere(
                          (c) => c.toLowerCase() == selectedCategory!.toLowerCase(),
                          orElse: () => categories.last,
                        )
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: isLoading ? null : (value) {
                    setDialogState(() => selectedCategory = value?.toLowerCase());
                  },
                ),
                const SizedBox(height: 16),

                // Date
                InkWell(
                  onTap: isLoading ? null : () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: transactionDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setDialogState(() => transactionDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      transactionDate != null
                          ? '${transactionDate!.day}/${transactionDate!.month}/${transactionDate!.year}'
                          : 'Select date',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  enabled: !isLoading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                // Validate
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a title')),
                  );
                  return;
                }
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }

                setDialogState(() => isLoading = true);

                try {
                  await ref.read(expenseControllerProvider.notifier).updateExpense(
                    expenseId: expense.id,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    amount: amount,
                    category: selectedCategory,
                    transactionDate: transactionDate,
                  );

                  ref.invalidate(userExpensesProvider);
                  ref.invalidate(standaloneExpensesProvider);
                  if (expense.tripId != null) {
                    ref.invalidate(tripExpensesProvider(expense.tripId!));
                  }

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Expense updated successfully'),
                        backgroundColor: context.successColor,
                      ),
                    );
                  }
                } catch (e) {
                  setDialogState(() => isLoading = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: context.errorColor,
                      ),
                    );
                  }
                }
              },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ],
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
                                    UserAvatarWidget(
                                      imageUrl: balance.avatarUrl,
                                      userName: balance.userName,
                                      size: 40,
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
