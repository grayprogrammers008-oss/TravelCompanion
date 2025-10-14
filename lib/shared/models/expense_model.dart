/// Expense model - Plain Dart class (Freezed removed)
class ExpenseModel {
  final String id;
  final String? tripId; // Optional for standalone expenses
  final String title;
  final String? description;
  final double amount;
  final String currency;
  final String? category;
  final String paidBy;
  final String splitType;
  final String? receiptUrl;
  final DateTime? transactionDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Joined data
  final String? payerName;

  const ExpenseModel({
    required this.id,
    this.tripId,
    required this.title,
    this.description,
    required this.amount,
    this.currency = 'INR',
    this.category,
    required this.paidBy,
    this.splitType = 'equal',
    this.receiptUrl,
    this.transactionDate,
    this.createdAt,
    this.updatedAt,
    this.payerName,
  });

  ExpenseModel copyWith({
    String? id,
    String? tripId,
    String? title,
    String? description,
    double? amount,
    String? currency,
    String? category,
    String? paidBy,
    String? splitType,
    String? receiptUrl,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? payerName,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      paidBy: paidBy ?? this.paidBy,
      splitType: splitType ?? this.splitType,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      payerName: payerName ?? this.payerName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'title': title,
      'description': description,
      'amount': amount,
      'currency': currency,
      'category': category,
      'paid_by': paidBy,
      'split_type': splitType,
      'receipt_url': receiptUrl,
      'transaction_date': transactionDate?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'payer_name': payerName,
    };
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      category: json['category'] as String?,
      paidBy: json['paid_by'] as String,
      splitType: json['split_type'] as String? ?? 'equal',
      receiptUrl: json['receipt_url'] as String?,
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      payerName: json['payer_name'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseModel &&
        other.id == id &&
        other.tripId == tripId &&
        other.title == title &&
        other.description == description &&
        other.amount == amount &&
        other.currency == currency &&
        other.category == category &&
        other.paidBy == paidBy &&
        other.splitType == splitType &&
        other.receiptUrl == receiptUrl &&
        other.transactionDate == transactionDate &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.payerName == payerName;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      tripId,
      title,
      description,
      amount,
      currency,
      category,
      paidBy,
      splitType,
      receiptUrl,
      transactionDate,
      createdAt,
      updatedAt,
      payerName,
    );
  }

  @override
  String toString() {
    return 'ExpenseModel(id: $id, tripId: $tripId, title: $title, description: $description, amount: $amount, currency: $currency, category: $category, paidBy: $paidBy, splitType: $splitType, receiptUrl: $receiptUrl, transactionDate: $transactionDate, createdAt: $createdAt, updatedAt: $updatedAt, payerName: $payerName)';
  }
}

/// Expense split model
class ExpenseSplitModel {
  final String id;
  final String expenseId;
  final String userId;
  final double amount;
  final bool isSettled;
  final DateTime? settledAt;
  final DateTime? createdAt;
  // Joined data
  final String? userName;
  final String? avatarUrl;

  const ExpenseSplitModel({
    required this.id,
    required this.expenseId,
    required this.userId,
    required this.amount,
    this.isSettled = false,
    this.settledAt,
    this.createdAt,
    this.userName,
    this.avatarUrl,
  });

  ExpenseSplitModel copyWith({
    String? id,
    String? expenseId,
    String? userId,
    double? amount,
    bool? isSettled,
    DateTime? settledAt,
    DateTime? createdAt,
    String? userName,
    String? avatarUrl,
  }) {
    return ExpenseSplitModel(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      isSettled: isSettled ?? this.isSettled,
      settledAt: settledAt ?? this.settledAt,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'user_id': userId,
      'amount': amount,
      'is_settled': isSettled,
      'settled_at': settledAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'user_name': userName,
      'avatar_url': avatarUrl,
    };
  }

  factory ExpenseSplitModel.fromJson(Map<String, dynamic> json) {
    return ExpenseSplitModel(
      id: json['id'] as String,
      expenseId: json['expense_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      isSettled: (json['is_settled'] is int)
          ? (json['is_settled'] as int) == 1
          : (json['is_settled'] as bool? ?? false),
      settledAt: json['settled_at'] != null
          ? DateTime.parse(json['settled_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      userName: json['user_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseSplitModel &&
        other.id == id &&
        other.expenseId == expenseId &&
        other.userId == userId &&
        other.amount == amount &&
        other.isSettled == isSettled &&
        other.settledAt == settledAt &&
        other.createdAt == createdAt &&
        other.userName == userName &&
        other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      expenseId,
      userId,
      amount,
      isSettled,
      settledAt,
      createdAt,
      userName,
      avatarUrl,
    );
  }

  @override
  String toString() {
    return 'ExpenseSplitModel(id: $id, expenseId: $expenseId, userId: $userId, amount: $amount, isSettled: $isSettled, settledAt: $settledAt, createdAt: $createdAt, userName: $userName, avatarUrl: $avatarUrl)';
  }
}

/// Expense with splits
class ExpenseWithSplits {
  final ExpenseModel expense;
  final List<ExpenseSplitModel> splits;

  const ExpenseWithSplits({
    required this.expense,
    required this.splits,
  });

  ExpenseWithSplits copyWith({
    ExpenseModel? expense,
    List<ExpenseSplitModel>? splits,
  }) {
    return ExpenseWithSplits(
      expense: expense ?? this.expense,
      splits: splits ?? this.splits,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expense': expense.toJson(),
      'splits': splits.map((s) => s.toJson()).toList(),
    };
  }

  factory ExpenseWithSplits.fromJson(Map<String, dynamic> json) {
    return ExpenseWithSplits(
      expense: ExpenseModel.fromJson(json['expense'] as Map<String, dynamic>),
      splits: (json['splits'] as List<dynamic>)
          .map((s) => ExpenseSplitModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseWithSplits &&
        other.expense == expense &&
        _listEquals(other.splits, splits);
  }

  @override
  int get hashCode {
    return Object.hash(
      expense,
      Object.hashAll(splits),
    );
  }

  @override
  String toString() {
    return 'ExpenseWithSplits(expense: $expense, splits: $splits)';
  }
}

/// Settlement model
class SettlementModel {
  final String id;
  final String? tripId; // Optional for standalone expenses
  final String fromUser;
  final String toUser;
  final double amount;
  final String currency;
  final String? paymentMethod;
  final String? paymentProofUrl;
  final String status;
  final DateTime? transactionDate;
  final DateTime? createdAt;
  // Joined data
  final String? fromUserName;
  final String? toUserName;

  const SettlementModel({
    required this.id,
    this.tripId,
    required this.fromUser,
    required this.toUser,
    required this.amount,
    this.currency = 'INR',
    this.paymentMethod,
    this.paymentProofUrl,
    this.status = 'pending',
    this.transactionDate,
    this.createdAt,
    this.fromUserName,
    this.toUserName,
  });

  SettlementModel copyWith({
    String? id,
    String? tripId,
    String? fromUser,
    String? toUser,
    double? amount,
    String? currency,
    String? paymentMethod,
    String? paymentProofUrl,
    String? status,
    DateTime? transactionDate,
    DateTime? createdAt,
    String? fromUserName,
    String? toUserName,
  }) {
    return SettlementModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      fromUser: fromUser ?? this.fromUser,
      toUser: toUser ?? this.toUser,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      status: status ?? this.status,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserName: toUserName ?? this.toUserName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'from_user': fromUser,
      'to_user': toUser,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      'payment_proof_url': paymentProofUrl,
      'status': status,
      'transaction_date': transactionDate?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'from_user_name': fromUserName,
      'to_user_name': toUserName,
    };
  }

  factory SettlementModel.fromJson(Map<String, dynamic> json) {
    return SettlementModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String?,
      fromUser: json['from_user'] as String,
      toUser: json['to_user'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      paymentMethod: json['payment_method'] as String?,
      paymentProofUrl: json['payment_proof_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      fromUserName: json['from_user_name'] as String?,
      toUserName: json['to_user_name'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettlementModel &&
        other.id == id &&
        other.tripId == tripId &&
        other.fromUser == fromUser &&
        other.toUser == toUser &&
        other.amount == amount &&
        other.currency == currency &&
        other.paymentMethod == paymentMethod &&
        other.paymentProofUrl == paymentProofUrl &&
        other.status == status &&
        other.transactionDate == transactionDate &&
        other.createdAt == createdAt &&
        other.fromUserName == fromUserName &&
        other.toUserName == toUserName;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      tripId,
      fromUser,
      toUser,
      amount,
      currency,
      paymentMethod,
      paymentProofUrl,
      status,
      transactionDate,
      createdAt,
      fromUserName,
      toUserName,
    );
  }

  @override
  String toString() {
    return 'SettlementModel(id: $id, tripId: $tripId, fromUser: $fromUser, toUser: $toUser, amount: $amount, currency: $currency, paymentMethod: $paymentMethod, paymentProofUrl: $paymentProofUrl, status: $status, transactionDate: $transactionDate, createdAt: $createdAt, fromUserName: $fromUserName, toUserName: $toUserName)';
  }
}

/// Balance summary for a user in a trip
class BalanceSummary {
  final String userId;
  final String userName;
  final double totalPaid;
  final double totalOwed;
  final double balance; // positive = owed to them, negative = they owe

  BalanceSummary({
    required this.userId,
    required this.userName,
    required this.totalPaid,
    required this.totalOwed,
    required this.balance,
  });
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
