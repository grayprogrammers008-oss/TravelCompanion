import '../models/trip_cost_summary.dart';

/// Budget status for a trip
enum BudgetStatus {
  underBudget,
  onBudget,
  overBudget,
  noBudget,
}

/// Trip budget analysis result
class TripBudgetStatus {
  final String tripId;
  final double? budget;
  final double actualCost;
  final double? remaining;
  final double? percentageUsed;
  final BudgetStatus status;
  final TripCostSummary costSummary;

  const TripBudgetStatus({
    required this.tripId,
    this.budget,
    required this.actualCost,
    this.remaining,
    this.percentageUsed,
    required this.status,
    required this.costSummary,
  });

  /// Check if over budget
  bool get isOverBudget => status == BudgetStatus.overBudget;

  /// Check if under budget
  bool get isUnderBudget => status == BudgetStatus.underBudget;

  /// Check if on budget (within 5% tolerance)
  bool get isOnBudget => status == BudgetStatus.onBudget;

  /// Check if has budget set
  bool get hasBudget => budget != null && budget! > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripBudgetStatus &&
        other.tripId == tripId &&
        other.budget == budget &&
        other.actualCost == actualCost &&
        other.remaining == remaining &&
        other.percentageUsed == percentageUsed &&
        other.status == status &&
        other.costSummary == costSummary;
  }

  @override
  int get hashCode {
    return Object.hash(
      tripId,
      budget,
      actualCost,
      remaining,
      percentageUsed,
      status,
      costSummary,
    );
  }

  @override
  String toString() {
    return 'TripBudgetStatus(tripId: $tripId, budget: $budget, '
        'actualCost: $actualCost, remaining: $remaining, '
        'percentageUsed: $percentageUsed, status: $status)';
  }
}

/// Use case for calculating trip budget status
/// Compares actual costs against budget and determines budget health
class CalculateTripBudgetStatusUseCase {
  /// Calculate budget status for a trip
  ///
  /// Parameters:
  /// - [costSummary]: The cost summary for the trip
  /// - [budget]: The budget amount (optional, if trip has a budget)
  /// - [tolerance]: Percentage tolerance for "on budget" status (default 5%)
  ///
  /// Returns [TripBudgetStatus] with budget analysis
  TripBudgetStatus call({
    required TripCostSummary costSummary,
    double? budget,
    double tolerance = 0.05, // 5% tolerance for "on budget"
  }) {
    // Handle case where no budget is set
    if (budget == null || budget <= 0) {
      return TripBudgetStatus(
        tripId: costSummary.tripId,
        budget: null,
        actualCost: costSummary.totalCost,
        remaining: null,
        percentageUsed: null,
        status: BudgetStatus.noBudget,
        costSummary: costSummary,
      );
    }

    // Calculate remaining budget
    final remaining = budget - costSummary.totalCost;

    // Calculate percentage used
    final percentageUsed = (costSummary.totalCost / budget) * 100;

    // Determine budget status
    BudgetStatus status;
    if (percentageUsed > 100) {
      // Over budget
      status = BudgetStatus.overBudget;
    } else if (percentageUsed >= (100 - (tolerance * 100)) &&
        percentageUsed <= 100) {
      // Within tolerance range (e.g., 95%-100% for 5% tolerance)
      status = BudgetStatus.onBudget;
    } else {
      // Under budget
      status = BudgetStatus.underBudget;
    }

    return TripBudgetStatus(
      tripId: costSummary.tripId,
      budget: budget,
      actualCost: costSummary.totalCost,
      remaining: remaining,
      percentageUsed: percentageUsed,
      status: status,
      costSummary: costSummary,
    );
  }
}
