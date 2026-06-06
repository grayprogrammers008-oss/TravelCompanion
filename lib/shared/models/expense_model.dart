/// Expense model - Plain Dart class (Freezed removed)
class ExpenseModel {
  final String id;
  final String? tripId; // Optional for standalone expenses
  final String? tripName; // Joined trip name for display
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
    this.tripName,
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
    String? tripName,
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
      tripName: tripName ?? this.tripName,
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
      'trip_name': tripName,
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
      tripName: json['trip_name'] as String? ?? json['trips']?['name'] as String?,
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

/// Expense split model.
///
/// A split row points at exactly one of a real user ([userId]) or a ghost
/// participant ([ghostId]) — the DB enforces the XOR. Ghost-backed splits
/// are folded into [ghostCreatedBy]'s balance at calc time; the ghost
/// itself never owes or is owed.
class ExpenseSplitModel {
  final String id;
  final String expenseId;
  final String? userId; // nullable when this split is for a ghost
  final String? ghostId;
  final double amount;
  final bool isSettled;
  final DateTime? settledAt;
  final DateTime? createdAt;
  // Joined data
  final String? userName;
  final String? avatarUrl;
  final String? ghostName;
  final String? ghostCreatedBy;
  /// Trip member who is financially responsible for the ghost (the
  /// "guardian"). Joined from `trip_ghost_participants.guardian_user_id`.
  /// Falls back to [ghostCreatedBy] for older rows that pre-date the
  /// guardian split.
  final String? ghostGuardianId;

  const ExpenseSplitModel({
    required this.id,
    required this.expenseId,
    this.userId,
    this.ghostId,
    required this.amount,
    this.isSettled = false,
    this.settledAt,
    this.createdAt,
    this.userName,
    this.avatarUrl,
    this.ghostName,
    this.ghostCreatedBy,
    this.ghostGuardianId,
  });

  /// True when this split row represents a ghost participant.
  bool get isGhost => ghostId != null;

  /// The real user whose balance this split affects. For real-user splits
  /// it's [userId]; for ghost splits it's the ghost's guardian (the
  /// member who's financially responsible), falling back to creator for
  /// pre-guardian rows.
  String? get effectiveUserId =>
      isGhost ? (ghostGuardianId ?? ghostCreatedBy) : userId;

  /// Display name — falls back through joined user / ghost / 'Unknown'.
  String get displayName => userName ?? ghostName ?? 'Unknown';

  ExpenseSplitModel copyWith({
    String? id,
    String? expenseId,
    String? userId,
    String? ghostId,
    double? amount,
    bool? isSettled,
    DateTime? settledAt,
    DateTime? createdAt,
    String? userName,
    String? avatarUrl,
    String? ghostName,
    String? ghostCreatedBy,
    String? ghostGuardianId,
  }) {
    return ExpenseSplitModel(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      userId: userId ?? this.userId,
      ghostId: ghostId ?? this.ghostId,
      amount: amount ?? this.amount,
      isSettled: isSettled ?? this.isSettled,
      settledAt: settledAt ?? this.settledAt,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      ghostName: ghostName ?? this.ghostName,
      ghostCreatedBy: ghostCreatedBy ?? this.ghostCreatedBy,
      ghostGuardianId: ghostGuardianId ?? this.ghostGuardianId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'user_id': userId,
      'ghost_id': ghostId,
      'amount': amount,
      'is_settled': isSettled,
      'settled_at': settledAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'user_name': userName,
      'avatar_url': avatarUrl,
      'ghost_name': ghostName,
      'ghost_created_by': ghostCreatedBy,
    };
  }

  factory ExpenseSplitModel.fromJson(Map<String, dynamic> json) {
    // Joined ghost row may arrive under either alias depending on the
    // PostgREST select string used by the caller.
    final ghostJoin = (json['ghost'] ?? json['trip_ghost_participants'])
        as Map<String, dynamic>?;
    return ExpenseSplitModel(
      id: json['id'] as String,
      expenseId: json['expense_id'] as String,
      userId: json['user_id'] as String?,
      ghostId: json['ghost_id'] as String?,
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
      ghostName: (json['ghost_name'] as String?) ??
          (ghostJoin?['name'] as String?),
      ghostCreatedBy: (json['ghost_created_by'] as String?) ??
          (ghostJoin?['created_by'] as String?),
      ghostGuardianId: (json['ghost_guardian_id'] as String?) ??
          (ghostJoin?['guardian_user_id'] as String?),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseSplitModel &&
        other.id == id &&
        other.expenseId == expenseId &&
        other.userId == userId &&
        other.ghostId == ghostId &&
        other.amount == amount &&
        other.isSettled == isSettled &&
        other.settledAt == settledAt &&
        other.createdAt == createdAt &&
        other.userName == userName &&
        other.avatarUrl == avatarUrl &&
        other.ghostName == ghostName &&
        other.ghostCreatedBy == ghostCreatedBy;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      expenseId,
      userId,
      ghostId,
      amount,
      isSettled,
      settledAt,
      createdAt,
      userName,
      avatarUrl,
      ghostName,
      ghostCreatedBy,
    );
  }

  @override
  String toString() {
    return 'ExpenseSplitModel(id: $id, expenseId: $expenseId, userId: $userId, ghostId: $ghostId, amount: $amount, isSettled: $isSettled, displayName: $displayName)';
  }
}

/// A trip-scoped ghost participant — someone who is part of the trip's
/// expense math but doesn't have an app account (kids, elderly relatives,
/// guests). The [createdBy] user owns the ghost's debts.
class GhostParticipantModel {
  final String id;
  final String tripId;
  final String name;
  final String createdBy;
  /// Trip member whose balance this ghost's debts fold into. Defaults to
  /// [createdBy] but may be set to any other trip member.
  final String guardianUserId;
  final DateTime? createdAt;
  final String? creatorName; // joined display name (who inserted the row)
  final String? guardianName; // joined display name (who pays for the ghost)

  const GhostParticipantModel({
    required this.id,
    required this.tripId,
    required this.name,
    required this.createdBy,
    required this.guardianUserId,
    this.createdAt,
    this.creatorName,
    this.guardianName,
  });

  GhostParticipantModel copyWith({
    String? id,
    String? tripId,
    String? name,
    String? createdBy,
    String? guardianUserId,
    DateTime? createdAt,
    String? creatorName,
    String? guardianName,
  }) {
    return GhostParticipantModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      guardianUserId: guardianUserId ?? this.guardianUserId,
      createdAt: createdAt ?? this.createdAt,
      creatorName: creatorName ?? this.creatorName,
      guardianName: guardianName ?? this.guardianName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'name': name,
      'created_by': createdBy,
      'guardian_user_id': guardianUserId,
      'created_at': createdAt?.toIso8601String(),
      'creator_name': creatorName,
      'guardian_name': guardianName,
    };
  }

  factory GhostParticipantModel.fromJson(Map<String, dynamic> json) {
    final creatorJoin = json['creator'] as Map<String, dynamic>?;
    final guardianJoin = json['guardian'] as Map<String, dynamic>?;
    final createdBy = json['created_by'] as String;
    return GhostParticipantModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      name: json['name'] as String,
      createdBy: createdBy,
      // Fall back to created_by for rows still in flight before the
      // migration backfills guardian_user_id.
      guardianUserId:
          (json['guardian_user_id'] as String?) ?? createdBy,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      creatorName: (json['creator_name'] as String?) ??
          (creatorJoin?['full_name'] as String?),
      guardianName: (json['guardian_name'] as String?) ??
          (guardianJoin?['full_name'] as String?),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GhostParticipantModel &&
        other.id == id &&
        other.tripId == tripId &&
        other.name == name &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, tripId, name, createdBy, createdAt);

  @override
  String toString() =>
      'GhostParticipantModel(id: $id, tripId: $tripId, name: $name, createdBy: $createdBy)';
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
  final String? avatarUrl;
  final double totalPaid;
  final double totalOwed;
  final double balance; // positive = owed to them, negative = they owe
  /// Names of guests this member is financially responsible for. Empty
  /// when the member has no guests folded into their balance.
  final List<String> guestNames;

  BalanceSummary({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.totalPaid,
    required this.totalOwed,
    required this.balance,
    this.guestNames = const [],
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
