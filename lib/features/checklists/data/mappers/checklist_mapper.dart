import '../../domain/entities/checklist_entity.dart';
import '../../../../shared/models/checklist_model.dart';

/// Mapper to convert between ChecklistModel and ChecklistEntity
extension ChecklistMapper on ChecklistModel {
  ChecklistEntity toEntity() {
    return ChecklistEntity(
      id: id,
      tripId: tripId,
      name: name,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      creatorName: creatorName,
    );
  }
}

extension ChecklistEntityMapper on ChecklistEntity {
  ChecklistModel toModel() {
    return ChecklistModel(
      id: id,
      tripId: tripId,
      name: name,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      creatorName: creatorName,
    );
  }
}

/// Mapper for ChecklistItemModel and ChecklistItemEntity
extension ChecklistItemMapper on ChecklistItemModel {
  ChecklistItemEntity toEntity() {
    return ChecklistItemEntity(
      id: id,
      checklistId: checklistId,
      title: title,
      isCompleted: isCompleted,
      assignedTo: assignedTo,
      completedBy: completedBy,
      completedAt: completedAt,
      orderIndex: orderIndex,
      createdAt: createdAt,
      updatedAt: updatedAt,
      assignedToName: assignedToName,
      completedByName: completedByName,
    );
  }
}

extension ChecklistItemEntityMapper on ChecklistItemEntity {
  ChecklistItemModel toModel() {
    return ChecklistItemModel(
      id: id,
      checklistId: checklistId,
      title: title,
      isCompleted: isCompleted,
      assignedTo: assignedTo,
      completedBy: completedBy,
      completedAt: completedAt,
      orderIndex: orderIndex,
      createdAt: createdAt,
      updatedAt: updatedAt,
      assignedToName: assignedToName,
      completedByName: completedByName,
    );
  }
}

/// Mapper for ChecklistWithItems
extension ChecklistWithItemsMapper on ChecklistWithItems {
  ChecklistWithItemsEntity toEntity() {
    return ChecklistWithItemsEntity(
      checklist: checklist.toEntity(),
      items: items.map((item) => item.toEntity()).toList(),
    );
  }
}

extension ChecklistWithItemsEntityMapper on ChecklistWithItemsEntity {
  ChecklistWithItems toModel() {
    return ChecklistWithItems(
      checklist: checklist.toModel(),
      items: items.map((item) => item.toModel()).toList(),
    );
  }
}
