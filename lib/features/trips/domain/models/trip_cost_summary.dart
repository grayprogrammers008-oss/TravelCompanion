/// Trip cost summary model
/// Aggregates all expense data for a trip
class TripCostSummary {
  final String tripId;
  final double totalCost;
  final String currency;
  final int expenseCount;
  final Map<String, double> categoryBreakdown;
  final Map<String, double> userSpending; // userId -> amount spent
  final DateTime? lastExpenseDate;

  const TripCostSummary({
    required this.tripId,
    required this.totalCost,
    required this.currency,
    required this.expenseCount,
    required this.categoryBreakdown,
    required this.userSpending,
    this.lastExpenseDate,
  });

  TripCostSummary copyWith({
    String? tripId,
    double? totalCost,
    String? currency,
    int? expenseCount,
    Map<String, double>? categoryBreakdown,
    Map<String, double>? userSpending,
    DateTime? lastExpenseDate,
  }) {
    return TripCostSummary(
      tripId: tripId ?? this.tripId,
      totalCost: totalCost ?? this.totalCost,
      currency: currency ?? this.currency,
      expenseCount: expenseCount ?? this.expenseCount,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      userSpending: userSpending ?? this.userSpending,
      lastExpenseDate: lastExpenseDate ?? this.lastExpenseDate,
    );
  }

  /// Calculate average expense amount
  double get averageExpenseAmount =>
      expenseCount > 0 ? totalCost / expenseCount : 0.0;

  /// Get spending for a specific user
  double getUserSpending(String userId) => userSpending[userId] ?? 0.0;

  /// Get spending for a specific category
  double getCategorySpending(String category) =>
      categoryBreakdown[category] ?? 0.0;

  /// Get list of categories with spending
  List<String> get categoriesWithSpending => categoryBreakdown.keys.toList();

  /// Get list of users who have spent money
  List<String> get usersWithSpending => userSpending.keys.toList();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripCostSummary &&
        other.tripId == tripId &&
        other.totalCost == totalCost &&
        other.currency == currency &&
        other.expenseCount == expenseCount &&
        _mapEquals(other.categoryBreakdown, categoryBreakdown) &&
        _mapEquals(other.userSpending, userSpending) &&
        other.lastExpenseDate == lastExpenseDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      tripId,
      totalCost,
      currency,
      expenseCount,
      categoryBreakdown,
      userSpending,
      lastExpenseDate,
    );
  }

  bool _mapEquals(Map<String, double> map1, Map<String, double> map2) {
    if (map1.length != map2.length) return false;
    for (var key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() {
    return 'TripCostSummary(tripId: $tripId, totalCost: $totalCost, '
        'currency: $currency, expenseCount: $expenseCount, '
        'categoryBreakdown: $categoryBreakdown, userSpending: $userSpending, '
        'lastExpenseDate: $lastExpenseDate)';
  }
}
