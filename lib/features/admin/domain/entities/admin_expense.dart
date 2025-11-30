import 'package:equatable/equatable.dart';

/// Admin Expense Model
/// Extended expense model with admin-specific data including
/// trip info, payer details, and split statistics
class AdminExpenseModel extends Equatable {
  final String id;
  final String? tripId;
  final String? tripName;
  final String? tripDestination;
  final String title;
  final String? description;
  final double amount;
  final String currency;
  final String? category;
  final String paidBy;
  final String? payerName;
  final String? payerEmail;
  final String splitType;
  final String? receiptUrl;
  final DateTime? transactionDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int splitCount;
  final int settledCount;
  final double pendingAmount;

  const AdminExpenseModel({
    required this.id,
    this.tripId,
    this.tripName,
    this.tripDestination,
    required this.title,
    this.description,
    required this.amount,
    required this.currency,
    this.category,
    required this.paidBy,
    this.payerName,
    this.payerEmail,
    required this.splitType,
    this.receiptUrl,
    this.transactionDate,
    required this.createdAt,
    this.updatedAt,
    required this.splitCount,
    required this.settledCount,
    required this.pendingAmount,
  });

  /// Whether this is a standalone expense (not associated with a trip)
  bool get isStandalone => tripId == null;

  /// Whether all splits have been settled
  bool get isFullySettled => splitCount > 0 && settledCount == splitCount;

  /// Whether there are pending splits
  bool get hasPendingSplits => splitCount > 0 && settledCount < splitCount;

  /// Whether this expense has no splits
  bool get hasNoSplits => splitCount == 0;

  /// Settlement percentage (0-100)
  double get settlementPercentage {
    if (splitCount == 0) return 0;
    return (settledCount / splitCount) * 100;
  }

  /// Pending split count
  int get pendingSplitCount => splitCount - settledCount;

  /// Whether the expense has a receipt
  bool get hasReceipt => receiptUrl != null && receiptUrl!.isNotEmpty;

  /// Display name for the payer
  String get payerDisplayName => payerName ?? payerEmail ?? 'Unknown';

  /// Display name for category
  String get categoryDisplayName {
    if (category == null) return 'Uncategorized';
    switch (category) {
      case 'food':
        return 'Food & Dining';
      case 'transport':
        return 'Transportation';
      case 'accommodation':
        return 'Accommodation';
      case 'activities':
        return 'Activities';
      case 'shopping':
        return 'Shopping';
      case 'other':
        return 'Other';
      default:
        return category!;
    }
  }

  factory AdminExpenseModel.fromJson(Map<String, dynamic> json) {
    return AdminExpenseModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String?,
      tripName: json['trip_name'] as String?,
      tripDestination: json['trip_destination'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      category: json['category'] as String?,
      paidBy: json['paid_by'] as String,
      payerName: json['payer_name'] as String?,
      payerEmail: json['payer_email'] as String?,
      splitType: json['split_type'] as String? ?? 'equal',
      receiptUrl: json['receipt_url'] as String?,
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      splitCount: (json['split_count'] as num?)?.toInt() ?? 0,
      settledCount: (json['settled_count'] as num?)?.toInt() ?? 0,
      pendingAmount: (json['pending_amount'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'trip_name': tripName,
      'trip_destination': tripDestination,
      'title': title,
      'description': description,
      'amount': amount,
      'currency': currency,
      'category': category,
      'paid_by': paidBy,
      'payer_name': payerName,
      'payer_email': payerEmail,
      'split_type': splitType,
      'receipt_url': receiptUrl,
      'transaction_date': transactionDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'split_count': splitCount,
      'settled_count': settledCount,
      'pending_amount': pendingAmount,
    };
  }

  @override
  List<Object?> get props => [
        id,
        tripId,
        tripName,
        tripDestination,
        title,
        description,
        amount,
        currency,
        category,
        paidBy,
        payerName,
        payerEmail,
        splitType,
        receiptUrl,
        transactionDate,
        createdAt,
        updatedAt,
        splitCount,
        settledCount,
        pendingAmount,
      ];
}

/// Parameters for expense list queries
class ExpenseListParams extends Equatable {
  final int limit;
  final int offset;
  final String? search;
  final String? category;
  final String? tripId;

  const ExpenseListParams({
    this.limit = 50,
    this.offset = 0,
    this.search,
    this.category,
    this.tripId,
  });

  ExpenseListParams copyWith({
    int? limit,
    int? offset,
    String? search,
    String? category,
    String? tripId,
  }) {
    return ExpenseListParams(
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      search: search ?? this.search,
      category: category ?? this.category,
      tripId: tripId ?? this.tripId,
    );
  }

  @override
  List<Object?> get props => [limit, offset, search, category, tripId];
}

/// Admin expense statistics model
class AdminExpenseStatsModel extends Equatable {
  final int totalExpenses;
  final double totalAmount;
  final double totalSettled;
  final double totalPending;
  final double settlementRate;
  final int expensesWithReceipts;
  final int standaloneExpenses;
  final int tripExpenses;
  final Map<String, int> categoryBreakdown;

  const AdminExpenseStatsModel({
    required this.totalExpenses,
    required this.totalAmount,
    required this.totalSettled,
    required this.totalPending,
    required this.settlementRate,
    required this.expensesWithReceipts,
    required this.standaloneExpenses,
    required this.tripExpenses,
    required this.categoryBreakdown,
  });

  factory AdminExpenseStatsModel.fromJson(Map<String, dynamic> json) {
    // Parse category breakdown from JSONB
    Map<String, int> categories = {};
    if (json['category_breakdown'] != null) {
      final breakdown = json['category_breakdown'];
      if (breakdown is Map) {
        breakdown.forEach((key, value) {
          categories[key.toString()] = (value as num).toInt();
        });
      }
    }

    return AdminExpenseStatsModel(
      totalExpenses: (json['total_expenses'] as num?)?.toInt() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      totalSettled: (json['total_settled'] as num?)?.toDouble() ?? 0,
      totalPending: (json['total_pending'] as num?)?.toDouble() ?? 0,
      settlementRate: (json['settlement_rate'] as num?)?.toDouble() ?? 0,
      expensesWithReceipts:
          (json['expenses_with_receipts'] as num?)?.toInt() ?? 0,
      standaloneExpenses: (json['standalone_expenses'] as num?)?.toInt() ?? 0,
      tripExpenses: (json['trip_expenses'] as num?)?.toInt() ?? 0,
      categoryBreakdown: categories,
    );
  }

  @override
  List<Object?> get props => [
        totalExpenses,
        totalAmount,
        totalSettled,
        totalPending,
        settlementRate,
        expensesWithReceipts,
        standaloneExpenses,
        tripExpenses,
        categoryBreakdown,
      ];
}
