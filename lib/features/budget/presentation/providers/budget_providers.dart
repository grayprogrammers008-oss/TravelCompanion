import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/trip_model.dart';
import '../../../../shared/models/expense_model.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../trips/presentation/providers/trip_providers.dart';

/// Budget status levels
enum BudgetStatus {
  /// Under 50% - safe zone
  healthy,
  /// 50-75% - moderate spending
  moderate,
  /// 75-90% - approaching limit
  warning,
  /// 90-100% - critical
  critical,
  /// Over 100% - exceeded
  exceeded,
  /// No budget set
  noBudget,
}

/// Category breakdown for expenses
class CategoryBreakdown {
  final String category;
  final double amount;
  final double percentage;
  final int count;

  const CategoryBreakdown({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.count,
  });
}

/// Budget tracking data for a trip
class TripBudgetData {
  /// Trip budget amount (null if not set)
  final double? budget;

  /// Currency code
  final String currency;

  /// Total spent so far
  final double totalSpent;

  /// Remaining budget (can be negative if exceeded)
  final double remaining;

  /// Percentage of budget used (0-100+)
  final double percentageUsed;

  /// Budget status
  final BudgetStatus status;

  /// Category breakdown
  final List<CategoryBreakdown> categoryBreakdown;

  /// Number of expenses
  final int expenseCount;

  /// Trip start date
  final DateTime? tripStartDate;

  /// Trip end date
  final DateTime? tripEndDate;

  /// Days elapsed since trip start
  final int daysElapsed;

  /// Total trip days
  final int totalTripDays;

  /// Average daily spending
  final double averageDailySpending;

  /// Projected total spending at current pace
  final double projectedTotal;

  /// Projected overspend/underspend amount
  final double projectedDifference;

  /// Is trip currently active (between start and end dates)
  final bool isTripActive;

  const TripBudgetData({
    this.budget,
    required this.currency,
    required this.totalSpent,
    required this.remaining,
    required this.percentageUsed,
    required this.status,
    required this.categoryBreakdown,
    required this.expenseCount,
    this.tripStartDate,
    this.tripEndDate,
    required this.daysElapsed,
    required this.totalTripDays,
    required this.averageDailySpending,
    required this.projectedTotal,
    required this.projectedDifference,
    required this.isTripActive,
  });

  /// Check if budget is set
  bool get hasBudget => budget != null && budget! > 0;

  /// Check if over budget
  bool get isOverBudget => hasBudget && totalSpent > budget!;

  /// Get status color name for UI
  String get statusColorName {
    switch (status) {
      case BudgetStatus.healthy:
        return 'green';
      case BudgetStatus.moderate:
        return 'blue';
      case BudgetStatus.warning:
        return 'orange';
      case BudgetStatus.critical:
        return 'red';
      case BudgetStatus.exceeded:
        return 'darkRed';
      case BudgetStatus.noBudget:
        return 'gray';
    }
  }

  /// Get status message
  String get statusMessage {
    if (!hasBudget) return 'No budget set';

    switch (status) {
      case BudgetStatus.healthy:
        return 'On track! Keep it up.';
      case BudgetStatus.moderate:
        return 'Spending is moderate.';
      case BudgetStatus.warning:
        return 'Approaching budget limit!';
      case BudgetStatus.critical:
        return 'Almost at budget limit!';
      case BudgetStatus.exceeded:
        return 'Budget exceeded!';
      case BudgetStatus.noBudget:
        return 'No budget set';
    }
  }

  /// Get pace message
  String get paceMessage {
    if (!hasBudget || totalTripDays == 0 || daysElapsed == 0) return '';

    if (projectedDifference > 0) {
      return 'At this pace, you\'ll exceed budget by ${_formatCurrency(projectedDifference.abs(), currency)}';
    } else if (projectedDifference < 0) {
      return 'At this pace, you\'ll save ${_formatCurrency(projectedDifference.abs(), currency)}';
    }
    return 'On track to meet budget exactly';
  }

  static String _formatCurrency(double amount, String currency) {
    final symbol = _getCurrencySymbol(currency);
    if (amount >= 100000) {
      return '$symbol${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
  }

  static String _getCurrencySymbol(String currency) {
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
}

/// Provider for trip budget data
final tripBudgetProvider = Provider.family<TripBudgetData, String>((ref, tripId) {
  final tripAsync = ref.watch(tripProvider(tripId));
  final expensesAsync = ref.watch(tripExpensesProvider(tripId));

  // Default data when loading or error
  final defaultData = TripBudgetData(
    budget: null,
    currency: 'INR',
    totalSpent: 0,
    remaining: 0,
    percentageUsed: 0,
    status: BudgetStatus.noBudget,
    categoryBreakdown: [],
    expenseCount: 0,
    daysElapsed: 0,
    totalTripDays: 0,
    averageDailySpending: 0,
    projectedTotal: 0,
    projectedDifference: 0,
    isTripActive: false,
  );

  // Get trip data
  final trip = tripAsync.value;
  if (trip == null) return defaultData;

  // Get expenses
  final expenses = expensesAsync.value ?? [];

  return _calculateBudgetData(trip.trip, expenses);
});

/// Async provider for trip budget data (for loading states)
final tripBudgetAsyncProvider = FutureProvider.family<TripBudgetData, String>((ref, tripId) async {
  final trip = await ref.watch(tripProvider(tripId).future);
  final expenses = await ref.watch(tripExpensesProvider(tripId).future);

  return _calculateBudgetData(trip.trip, expenses);
});

/// Calculate budget data from trip and expenses
TripBudgetData _calculateBudgetData(TripModel trip, List<ExpenseWithSplits> expenses) {
  final budget = trip.cost;
  final currency = trip.currency;

  // Calculate total spent
  final totalSpent = expenses.fold<double>(0, (sum, e) => sum + e.expense.amount);

  // Calculate category breakdown
  final categoryMap = <String, ({double amount, int count})>{};
  for (final expenseWithSplits in expenses) {
    final expense = expenseWithSplits.expense;
    final category = expense.category ?? 'Other';
    final existing = categoryMap[category];
    if (existing != null) {
      categoryMap[category] = (amount: existing.amount + expense.amount, count: existing.count + 1);
    } else {
      categoryMap[category] = (amount: expense.amount, count: 1);
    }
  }

  final categoryBreakdown = categoryMap.entries.map((entry) {
    return CategoryBreakdown(
      category: entry.key,
      amount: entry.value.amount,
      percentage: totalSpent > 0 ? (entry.value.amount / totalSpent) * 100 : 0,
      count: entry.value.count,
    );
  }).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount)); // Sort by amount descending

  // Calculate date-based metrics
  final now = DateTime.now();
  final startDate = trip.startDate;
  final endDate = trip.endDate;

  int daysElapsed = 0;
  int totalTripDays = 0;
  bool isTripActive = false;

  if (startDate != null && endDate != null) {
    totalTripDays = endDate.difference(startDate).inDays + 1;

    if (now.isAfter(startDate) || now.isAtSameMomentAs(startDate)) {
      if (now.isBefore(endDate) || now.isAtSameMomentAs(endDate)) {
        // Trip is currently active
        daysElapsed = now.difference(startDate).inDays + 1;
        isTripActive = true;
      } else {
        // Trip has ended
        daysElapsed = totalTripDays;
        isTripActive = false;
      }
    }
  }

  // Calculate pace metrics
  final averageDailySpending = daysElapsed > 0 ? totalSpent / daysElapsed : 0.0;
  final projectedTotal = totalTripDays > 0 && daysElapsed > 0
      ? averageDailySpending * totalTripDays
      : totalSpent;

  // Calculate remaining and percentage
  final remaining = budget != null ? budget - totalSpent : 0.0;
  final percentageUsed = budget != null && budget > 0
      ? (totalSpent / budget) * 100
      : 0.0;

  // Determine status
  BudgetStatus status;
  if (budget == null || budget <= 0) {
    status = BudgetStatus.noBudget;
  } else if (percentageUsed > 100) {
    status = BudgetStatus.exceeded;
  } else if (percentageUsed >= 90) {
    status = BudgetStatus.critical;
  } else if (percentageUsed >= 75) {
    status = BudgetStatus.warning;
  } else if (percentageUsed >= 50) {
    status = BudgetStatus.moderate;
  } else {
    status = BudgetStatus.healthy;
  }

  // Calculate projected difference
  final projectedDifference = budget != null ? projectedTotal - budget : 0.0;

  return TripBudgetData(
    budget: budget,
    currency: currency,
    totalSpent: totalSpent,
    remaining: remaining,
    percentageUsed: percentageUsed,
    status: status,
    categoryBreakdown: categoryBreakdown,
    expenseCount: expenses.length,
    tripStartDate: startDate,
    tripEndDate: endDate,
    daysElapsed: daysElapsed,
    totalTripDays: totalTripDays,
    averageDailySpending: averageDailySpending,
    projectedTotal: projectedTotal,
    projectedDifference: projectedDifference,
    isTripActive: isTripActive,
  );
}

/// Get category icon name
String getCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'food':
    case 'dining':
    case 'restaurant':
      return 'restaurant';
    case 'transport':
    case 'transportation':
    case 'travel':
      return 'directions_car';
    case 'accommodation':
    case 'hotel':
    case 'stay':
    case 'lodging':
      return 'hotel';
    case 'activities':
    case 'entertainment':
    case 'sightseeing':
      return 'local_activity';
    case 'shopping':
      return 'shopping_bag';
    case 'groceries':
      return 'local_grocery_store';
    case 'health':
    case 'medical':
      return 'medical_services';
    case 'communication':
    case 'phone':
      return 'phone';
    default:
      return 'receipt_long';
  }
}
