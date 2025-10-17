import '../../domain/entities/invite_entity.dart';

/// Data model for trip invitations - Plain Dart class
///
/// Maps to the trip_invites table in SQLite
class InviteModel {
  final String id;
  final String tripId;
  final String invitedBy;
  final String email;
  final String? phoneNumber;
  final String status;
  final String inviteCode;
  final DateTime createdAt;
  final DateTime expiresAt;

  // Extended fields from joins
  final String? inviterName;
  final String? inviterEmail;
  final String? tripName;
  final String? tripDestination;

  const InviteModel({
    required this.id,
    required this.tripId,
    required this.invitedBy,
    required this.email,
    this.phoneNumber,
    required this.status,
    required this.inviteCode,
    required this.createdAt,
    required this.expiresAt,
    this.inviterName,
    this.inviterEmail,
    this.tripName,
    this.tripDestination,
  });

  /// Create from JSON (for database deserialization if needed)
  factory InviteModel.fromJson(Map<String, dynamic> json) {
    return InviteModel(
      id: json['id'] as String,
      tripId: json['tripId'] as String? ?? json['trip_id'] as String,
      invitedBy: json['invitedBy'] as String? ?? json['invited_by'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String? ?? json['phone_number'] as String?,
      status: json['status'] as String,
      inviteCode: json['inviteCode'] as String? ?? json['invite_code'] as String,
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt'] as DateTime
          : DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
      expiresAt: json['expiresAt'] is DateTime
          ? json['expiresAt'] as DateTime
          : DateTime.parse(json['expiresAt'] as String? ?? json['expires_at'] as String),
      inviterName: json['inviterName'] as String? ?? json['inviter_name'] as String?,
      inviterEmail: json['inviterEmail'] as String? ?? json['inviter_email'] as String?,
      tripName: json['tripName'] as String? ?? json['trip_name'] as String?,
      tripDestination: json['tripDestination'] as String? ?? json['trip_destination'] as String?,
    );
  }

  /// Convert to JSON (for database serialization if needed)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'invited_by': invitedBy,
      'email': email,
      'phone_number': phoneNumber,
      'status': status,
      'invite_code': inviteCode,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'inviter_name': inviterName,
      'inviter_email': inviterEmail,
      'trip_name': tripName,
      'trip_destination': tripDestination,
    };
  }

  /// Convert to entity
  InviteEntity toEntity() {
    return InviteEntity(
      id: id,
      tripId: tripId,
      invitedBy: invitedBy,
      email: email,
      phoneNumber: phoneNumber,
      status: status,
      inviteCode: inviteCode,
      createdAt: createdAt,
      expiresAt: expiresAt,
      inviterName: inviterName,
      inviterEmail: inviterEmail,
      tripName: tripName,
      tripDestination: tripDestination,
    );
  }

  /// Create from entity
  factory InviteModel.fromEntity(InviteEntity entity) {
    return InviteModel(
      id: entity.id,
      tripId: entity.tripId,
      invitedBy: entity.invitedBy,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      status: entity.status,
      inviteCode: entity.inviteCode,
      createdAt: entity.createdAt,
      expiresAt: entity.expiresAt,
      inviterName: entity.inviterName,
      inviterEmail: entity.inviterEmail,
      tripName: entity.tripName,
      tripDestination: entity.tripDestination,
    );
  }

  InviteModel copyWith({
    String? id,
    String? tripId,
    String? invitedBy,
    String? email,
    String? phoneNumber,
    String? status,
    String? inviteCode,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? inviterName,
    String? inviterEmail,
    String? tripName,
    String? tripDestination,
  }) {
    return InviteModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      invitedBy: invitedBy ?? this.invitedBy,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      inviterName: inviterName ?? this.inviterName,
      inviterEmail: inviterEmail ?? this.inviterEmail,
      tripName: tripName ?? this.tripName,
      tripDestination: tripDestination ?? this.tripDestination,
    );
  }
}
