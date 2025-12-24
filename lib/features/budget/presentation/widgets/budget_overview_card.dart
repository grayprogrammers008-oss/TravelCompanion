import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/budget_providers.dart';

/// Expense Summary Card - Shows total expenses and category breakdown
/// Simplified from the previous Budget Overview Card (no budget tracking)
class BudgetOverviewCard extends ConsumerWidget {
  final String tripId;
  final VoidCallback? onTap;

  const BudgetOverviewCard({
    super.key,
    required this.tripId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetData = ref.watch(tripBudgetProvider(tripId));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and total
            _buildHeader(context, budgetData),

            // Category breakdown
            if (budgetData.categoryBreakdown.isNotEmpty)
              _buildCategorySection(context, budgetData),

            // No expenses message
            if (budgetData.expenseCount == 0)
              _buildNoExpensesMessage(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TripBudgetData data) {
    final currencySymbol = _getCurrencySymbol(data.currency);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: AppTheme.primaryTeal,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Title and expense count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expenses',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.expenseCount > 0
                      ? '${data.expenseCount} ${data.expenseCount == 1 ? 'expense' : 'expenses'}'
                      : 'No expenses yet',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.neutral500,
                  ),
                ),
              ],
            ),
          ),

          // Total amount
          if (data.totalSpent > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.neutral500,
                  ),
                ),
                Text(
                  '$currencySymbol${_formatAmount(data.totalSpent)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutral900,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, TripBudgetData data) {
    // Show top 4 categories max
    final categories = data.categoryBreakdown.take(4).toList();
    final currencySymbol = _getCurrencySymbol(data.currency);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            'By Category',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral600,
            ),
          ),
          const SizedBox(height: 10),

          // Category bars
          ...categories.map((category) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // Icon
                Icon(
                  _getCategoryIcon(category.category),
                  size: 16,
                  color: AppTheme.neutral500,
                ),
                const SizedBox(width: 8),

                // Category name
                Expanded(
                  flex: 2,
                  child: Text(
                    category.category,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.neutral700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Mini progress bar
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: category.percentage / 100,
                      backgroundColor: AppTheme.neutral200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getCategoryColor(categories.indexOf(category)),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Amount
                Text(
                  '$currencySymbol${_formatAmount(category.amount)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutral700,
                  ),
                ),

                const SizedBox(width: 4),

                // Percentage
                SizedBox(
                  width: 36,
                  child: Text(
                    '${category.percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.neutral500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildNoExpensesMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: AppTheme.neutral400,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Add expenses to track your spending',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.neutral500,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: AppTheme.neutral400,
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      AppTheme.primaryTeal,
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
        return Icons.restaurant;
      case 'transport':
      case 'transportation':
      case 'travel':
        return Icons.directions_car;
      case 'accommodation':
      case 'hotel':
      case 'stay':
      case 'lodging':
        return Icons.hotel;
      case 'activities':
      case 'entertainment':
      case 'sightseeing':
        return Icons.local_activity;
      case 'shopping':
        return Icons.shopping_bag;
      case 'groceries':
        return Icons.local_grocery_store;
      case 'health':
      case 'medical':
        return Icons.medical_services;
      default:
        return Icons.receipt_long;
    }
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

/// Compact expense indicator for use in action tiles
class BudgetIndicatorCompact extends ConsumerWidget {
  final String tripId;

  const BudgetIndicatorCompact({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetData = ref.watch(tripBudgetProvider(tripId));

    if (budgetData.expenseCount == 0) {
      return const SizedBox.shrink();
    }

    final currencySymbol = _getCurrencySymbol(budgetData.currency);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long,
            size: 12,
            color: AppTheme.primaryTeal,
          ),
          const SizedBox(width: 4),
          Text(
            '$currencySymbol${_formatAmount(budgetData.totalSpent)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTeal,
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
