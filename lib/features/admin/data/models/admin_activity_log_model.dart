import 'package:travel_crew/features/admin/domain/entities/admin_activity_log.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_action_type.dart';

/// Admin Activity Log Model
/// Maps database JSON to domain entity
class AdminActivityLogModel extends AdminActivityLog {
  const AdminActivityLogModel({
    required super.id,
    required super.adminId,
    required super.actionType,
    super.targetUserId,
    required super.description,
    required super.metadata,
    super.ipAddress,
    super.userAgent,
    required super.createdAt,
  });

  /// Create from JSON (Supabase response)
  factory AdminActivityLogModel.fromJson(Map<String, dynamic> json) {
    return AdminActivityLogModel(
      id: json['id'] as String,
      adminId: json['admin_id'] as String,
      actionType: AdminActionType.fromString(json['action_type'] as String),
      targetUserId: json['target_user_id'] as String?,
      description: json['description'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_id': adminId,
      'action_type': actionType.value,
      'target_user_id': targetUserId,
      'description': description,
      'metadata': metadata,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to domain entity
  AdminActivityLog toEntity() {
    return AdminActivityLog(
      id: id,
      adminId: adminId,
      actionType: actionType,
      targetUserId: targetUserId,
      description: description,
      metadata: metadata,
      ipAddress: ipAddress,
      userAgent: userAgent,
      createdAt: createdAt,
    );
  }

  /// Create from domain entity
  factory AdminActivityLogModel.fromEntity(AdminActivityLog log) {
    return AdminActivityLogModel(
      id: log.id,
      adminId: log.adminId,
      actionType: log.actionType,
      targetUserId: log.targetUserId,
      description: log.description,
      metadata: log.metadata,
      ipAddress: log.ipAddress,
      userAgent: log.userAgent,
      createdAt: log.createdAt,
    );
  }
}
