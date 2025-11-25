import 'package:equatable/equatable.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_action_type.dart';

/// Admin Activity Log Entity
/// Represents an action performed by an admin user
class AdminActivityLog extends Equatable {
  final String id;
  final String adminId;
  final AdminActionType actionType;
  final String? targetUserId;
  final String description;
  final Map<String, dynamic> metadata;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  const AdminActivityLog({
    required this.id,
    required this.adminId,
    required this.actionType,
    this.targetUserId,
    required this.description,
    required this.metadata,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  /// Get formatted date string
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Get metadata value by key
  T? getMetadata<T>(String key) {
    return metadata[key] as T?;
  }

  /// Copy with method
  AdminActivityLog copyWith({
    String? id,
    String? adminId,
    AdminActionType? actionType,
    String? targetUserId,
    String? description,
    Map<String, dynamic>? metadata,
    String? ipAddress,
    String? userAgent,
    DateTime? createdAt,
  }) {
    return AdminActivityLog(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      actionType: actionType ?? this.actionType,
      targetUserId: targetUserId ?? this.targetUserId,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        adminId,
        actionType,
        targetUserId,
        description,
        metadata,
        ipAddress,
        userAgent,
        createdAt,
      ];
}
