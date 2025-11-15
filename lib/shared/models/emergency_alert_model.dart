import 'package:equatable/equatable.dart';

/// Type of emergency alert
enum EmergencyAlertType {
  sos, // Critical SOS alert
  safety, // Safety check-in
  help, // General help needed
  medical, // Medical emergency
  custom, // Custom alert
}

/// Status of emergency alert
enum EmergencyAlertStatus {
  active, // Alert is active
  acknowledged, // Someone acknowledged
  resolved, // Emergency resolved
  cancelled, // User cancelled
}

/// Represents an emergency alert/SOS
class EmergencyAlertModel extends Equatable {
  final String id;
  final String userId;
  final String? tripId;
  final EmergencyAlertType type;
  final EmergencyAlertStatus status;
  final String? message;
  final double? latitude;
  final double? longitude;
  final String? locationName; // Geocoded location name
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final String? acknowledgedBy; // Contact ID who acknowledged
  final List<String> notifiedContactIds; // Who was notified
  final Map<String, dynamic>? metadata; // Additional emergency info

  const EmergencyAlertModel({
    required this.id,
    required this.userId,
    this.tripId,
    required this.type,
    required this.status,
    this.message,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.createdAt,
    this.acknowledgedAt,
    this.resolvedAt,
    this.acknowledgedBy,
    required this.notifiedContactIds,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        tripId,
        type,
        status,
        message,
        latitude,
        longitude,
        locationName,
        createdAt,
        acknowledgedAt,
        resolvedAt,
        acknowledgedBy,
        notifiedContactIds,
        metadata,
      ];

  EmergencyAlertModel copyWith({
    String? id,
    String? userId,
    String? tripId,
    EmergencyAlertType? type,
    EmergencyAlertStatus? status,
    String? message,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? createdAt,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    String? acknowledgedBy,
    List<String>? notifiedContactIds,
    Map<String, dynamic>? metadata,
  }) {
    return EmergencyAlertModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tripId: tripId ?? this.tripId,
      type: type ?? this.type,
      status: status ?? this.status,
      message: message ?? this.message,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      createdAt: createdAt ?? this.createdAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      notifiedContactIds: notifiedContactIds ?? this.notifiedContactIds,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'trip_id': tripId,
      'type': type.name,
      'status': status.name,
      'message': message,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'created_at': createdAt.toIso8601String(),
      'acknowledged_at': acknowledgedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'acknowledged_by': acknowledgedBy,
      'notified_contact_ids': notifiedContactIds,
      'metadata': metadata,
    };
  }

  factory EmergencyAlertModel.fromJson(Map<String, dynamic> json) {
    return EmergencyAlertModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      tripId: json['trip_id'] as String?,
      type: EmergencyAlertType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EmergencyAlertType.custom,
      ),
      status: EmergencyAlertStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => EmergencyAlertStatus.active,
      ),
      message: json['message'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      locationName: json['location_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'] as String)
          : null,
      resolvedAt:
          json['resolved_at'] != null ? DateTime.parse(json['resolved_at'] as String) : null,
      acknowledgedBy: json['acknowledged_by'] as String?,
      notifiedContactIds: (json['notified_contact_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Check if alert is currently active
  bool get isActive => status == EmergencyAlertStatus.active;

  /// Get duration since alert was created
  Duration get durationSinceCreated => DateTime.now().difference(createdAt);

  /// Check if alert has location data
  bool get hasLocation => latitude != null && longitude != null;
}
