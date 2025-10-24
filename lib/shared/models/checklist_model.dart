/// Checklist model - Plain Dart class (Freezed removed)
class ChecklistModel {
  final String id;
  final String tripId;
  final String name;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Joined data
  final String? creatorName;

  const ChecklistModel({
    required this.id,
    required this.tripId,
    required this.name,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.creatorName,
  });

  ChecklistModel copyWith({
    String? id,
    String? tripId,
    String? name,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? creatorName,
  }) {
    return ChecklistModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      creatorName: creatorName ?? this.creatorName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'name': name,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'creator_name': creatorName,
    };
  }

  /// Convert to JSON for database operations (excludes joined fields)
  Map<String, dynamic> toDatabaseJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'name': name,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // Exclude 'creator_name' - it's a joined field, not a table column
    };
  }

  factory ChecklistModel.fromJson(Map<String, dynamic> json) {
    return ChecklistModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      name: json['name'] as String,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      creatorName: json['creator_name'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChecklistModel &&
        other.id == id &&
        other.tripId == tripId &&
        other.name == name &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.creatorName == creatorName;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      tripId,
      name,
      createdBy,
      createdAt,
      updatedAt,
      creatorName,
    );
  }

  @override
  String toString() {
    return 'ChecklistModel(id: $id, tripId: $tripId, name: $name, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt, creatorName: $creatorName)';
  }
}

/// Checklist item model
class ChecklistItemModel {
  final String id;
  final String checklistId;
  final String title;
  final bool isCompleted;
  final String? assignedTo;
  final String? completedBy;
  final DateTime? completedAt;
  final int orderIndex;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Joined data
  final String? assignedToName;
  final String? completedByName;

  const ChecklistItemModel({
    required this.id,
    required this.checklistId,
    required this.title,
    this.isCompleted = false,
    this.assignedTo,
    this.completedBy,
    this.completedAt,
    this.orderIndex = 0,
    this.createdAt,
    this.updatedAt,
    this.assignedToName,
    this.completedByName,
  });

  ChecklistItemModel copyWith({
    String? id,
    String? checklistId,
    String? title,
    bool? isCompleted,
    String? assignedTo,
    String? completedBy,
    DateTime? completedAt,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedToName,
    String? completedByName,
  }) {
    return ChecklistItemModel(
      id: id ?? this.id,
      checklistId: checklistId ?? this.checklistId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      assignedTo: assignedTo ?? this.assignedTo,
      completedBy: completedBy ?? this.completedBy,
      completedAt: completedAt ?? this.completedAt,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedToName: assignedToName ?? this.assignedToName,
      completedByName: completedByName ?? this.completedByName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'checklist_id': checklistId,
      'title': title,
      'is_completed': isCompleted,
      'assigned_to': assignedTo,
      'completed_by': completedBy,
      'completed_at': completedAt?.toIso8601String(),
      'order_index': orderIndex,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'assigned_to_name': assignedToName,
      'completed_by_name': completedByName,
    };
  }

  /// Convert to JSON for database operations (excludes joined fields)
  Map<String, dynamic> toDatabaseJson() {
    return {
      'id': id,
      'checklist_id': checklistId,
      'title': title,
      'is_completed': isCompleted,
      'assigned_to': assignedTo,
      'completed_by': completedBy,
      'completed_at': completedAt?.toIso8601String(),
      'order_index': orderIndex,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // Exclude 'assigned_to_name' and 'completed_by_name' - they're joined fields
    };
  }

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) {
    // Convert SQLite int (0 or 1) to bool
    final isCompletedValue = json['is_completed'];
    final isCompleted = isCompletedValue is int
        ? isCompletedValue == 1
        : (isCompletedValue as bool? ?? false);

    return ChecklistItemModel(
      id: json['id'] as String,
      checklistId: json['checklist_id'] as String,
      title: json['title'] as String,
      isCompleted: isCompleted,
      assignedTo: json['assigned_to'] as String?,
      completedBy: json['completed_by'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      orderIndex: json['order_index'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      assignedToName: json['assigned_to_name'] as String?,
      completedByName: json['completed_by_name'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChecklistItemModel &&
        other.id == id &&
        other.checklistId == checklistId &&
        other.title == title &&
        other.isCompleted == isCompleted &&
        other.assignedTo == assignedTo &&
        other.completedBy == completedBy &&
        other.completedAt == completedAt &&
        other.orderIndex == orderIndex &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.assignedToName == assignedToName &&
        other.completedByName == completedByName;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      checklistId,
      title,
      isCompleted,
      assignedTo,
      completedBy,
      completedAt,
      orderIndex,
      createdAt,
      updatedAt,
      assignedToName,
      completedByName,
    );
  }

  @override
  String toString() {
    return 'ChecklistItemModel(id: $id, checklistId: $checklistId, title: $title, isCompleted: $isCompleted, assignedTo: $assignedTo, completedBy: $completedBy, completedAt: $completedAt, orderIndex: $orderIndex, createdAt: $createdAt, updatedAt: $updatedAt, assignedToName: $assignedToName, completedByName: $completedByName)';
  }
}

/// Checklist with items
class ChecklistWithItems {
  final ChecklistModel checklist;
  final List<ChecklistItemModel> items;

  const ChecklistWithItems({
    required this.checklist,
    required this.items,
  });

  ChecklistWithItems copyWith({
    ChecklistModel? checklist,
    List<ChecklistItemModel>? items,
  }) {
    return ChecklistWithItems(
      checklist: checklist ?? this.checklist,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checklist': checklist.toJson(),
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  factory ChecklistWithItems.fromJson(Map<String, dynamic> json) {
    return ChecklistWithItems(
      checklist: ChecklistModel.fromJson(json['checklist'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>)
          .map((i) => ChecklistItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChecklistWithItems &&
        other.checklist == checklist &&
        _listEquals(other.items, items);
  }

  @override
  int get hashCode {
    return Object.hash(
      checklist,
      Object.hashAll(items),
    );
  }

  @override
  String toString() {
    return 'ChecklistWithItems(checklist: $checklist, items: $items)';
  }
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
