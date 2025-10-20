import 'package:equatable/equatable.dart';

/// Checklist entity representing a collaborative task list
class ChecklistEntity extends Equatable {
  final String id;
  final String tripId;
  final String name;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? creatorName;

  const ChecklistEntity({
    required this.id,
    required this.tripId,
    required this.name,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.creatorName,
  });

  @override
  List<Object?> get props => [
        id,
        tripId,
        name,
        createdBy,
        createdAt,
        updatedAt,
        creatorName,
      ];
}

/// Checklist item entity with assignment and completion tracking
class ChecklistItemEntity extends Equatable {
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
  final String? assignedToName;
  final String? completedByName;

  const ChecklistItemEntity({
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

  @override
  List<Object?> get props => [
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
      ];
}

/// Checklist with its items
class ChecklistWithItemsEntity extends Equatable {
  final ChecklistEntity checklist;
  final List<ChecklistItemEntity> items;

  const ChecklistWithItemsEntity({
    required this.checklist,
    required this.items,
  });

  /// Get completion progress
  double get progress {
    if (items.isEmpty) return 0.0;
    final completedCount = items.where((item) => item.isCompleted).length;
    return completedCount / items.length;
  }

  /// Get number of completed items
  int get completedCount => items.where((item) => item.isCompleted).length;

  /// Get number of pending items
  int get pendingCount => items.where((item) => !item.isCompleted).length;

  @override
  List<Object?> get props => [checklist, items];
}
