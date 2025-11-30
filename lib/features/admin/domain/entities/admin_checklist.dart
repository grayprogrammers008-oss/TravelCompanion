/// Admin Checklist Model
/// Extended checklist model with additional admin-specific data
class AdminChecklistModel {
  final String id;
  final String tripId;
  final String tripName;
  final String? tripDestination;
  final String name;
  final String? createdBy;
  final String? creatorName;
  final String? creatorEmail;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int itemCount;
  final int completedCount;
  final int pendingCount;

  const AdminChecklistModel({
    required this.id,
    required this.tripId,
    required this.tripName,
    this.tripDestination,
    required this.name,
    this.createdBy,
    this.creatorName,
    this.creatorEmail,
    this.createdAt,
    this.updatedAt,
    this.itemCount = 0,
    this.completedCount = 0,
    this.pendingCount = 0,
  });

  /// Completion percentage (0.0 - 100.0)
  double get completionPercentage {
    if (itemCount == 0) return 0.0;
    return (completedCount / itemCount) * 100.0;
  }

  /// Check if all items are completed
  bool get isFullyCompleted => itemCount > 0 && completedCount == itemCount;

  /// Check if checklist has no items
  bool get isEmpty => itemCount == 0;

  /// Check if checklist has pending items
  bool get hasPendingItems => pendingCount > 0;

  factory AdminChecklistModel.fromJson(Map<String, dynamic> json) {
    return AdminChecklistModel(
      id: json['id']?.toString() ?? '',
      tripId: json['trip_id']?.toString() ?? '',
      tripName: json['trip_name']?.toString() ?? 'Unknown Trip',
      tripDestination: json['trip_destination']?.toString(),
      name: json['name']?.toString() ?? 'Unnamed Checklist',
      createdBy: json['created_by']?.toString(),
      creatorName: json['creator_name']?.toString(),
      creatorEmail: json['creator_email']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'trip_name': tripName,
      'trip_destination': tripDestination,
      'name': name,
      'created_by': createdBy,
      'creator_name': creatorName,
      'creator_email': creatorEmail,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'item_count': itemCount,
      'completed_count': completedCount,
      'pending_count': pendingCount,
    };
  }

  AdminChecklistModel copyWith({
    String? id,
    String? tripId,
    String? tripName,
    String? tripDestination,
    String? name,
    String? createdBy,
    String? creatorName,
    String? creatorEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? itemCount,
    int? completedCount,
    int? pendingCount,
  }) {
    return AdminChecklistModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      tripName: tripName ?? this.tripName,
      tripDestination: tripDestination ?? this.tripDestination,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      creatorEmail: creatorEmail ?? this.creatorEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemCount: itemCount ?? this.itemCount,
      completedCount: completedCount ?? this.completedCount,
      pendingCount: pendingCount ?? this.pendingCount,
    );
  }
}

/// Checklist list query parameters
class ChecklistListParams {
  final int limit;
  final int offset;
  final String? search;
  final String? status; // 'completed', 'pending', 'empty'
  final String? tripId;

  const ChecklistListParams({
    this.limit = 50,
    this.offset = 0,
    this.search,
    this.status,
    this.tripId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChecklistListParams &&
        other.limit == limit &&
        other.offset == offset &&
        other.search == search &&
        other.status == status &&
        other.tripId == tripId;
  }

  @override
  int get hashCode {
    return Object.hash(limit, offset, search, status, tripId);
  }
}

/// Admin Checklist Statistics Model
class AdminChecklistStatsModel {
  final int totalChecklists;
  final int totalItems;
  final int completedItems;
  final int pendingItems;
  final double completionRate;
  final int checklistsWithAllCompleted;
  final int emptyChecklists;

  const AdminChecklistStatsModel({
    this.totalChecklists = 0,
    this.totalItems = 0,
    this.completedItems = 0,
    this.pendingItems = 0,
    this.completionRate = 0.0,
    this.checklistsWithAllCompleted = 0,
    this.emptyChecklists = 0,
  });

  factory AdminChecklistStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminChecklistStatsModel(
      totalChecklists: (json['total_checklists'] as num?)?.toInt() ?? 0,
      totalItems: (json['total_items'] as num?)?.toInt() ?? 0,
      completedItems: (json['completed_items'] as num?)?.toInt() ?? 0,
      pendingItems: (json['pending_items'] as num?)?.toInt() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      checklistsWithAllCompleted:
          (json['checklists_with_all_completed'] as num?)?.toInt() ?? 0,
      emptyChecklists: (json['empty_checklists'] as num?)?.toInt() ?? 0,
    );
  }
}
