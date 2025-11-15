import 'package:equatable/equatable.dart';

/// Status of location sharing session
enum LocationShareStatus {
  active,
  paused,
  stopped,
  expired,
}

/// Represents a location sharing session
class LocationShareModel extends Equatable {
  final String id;
  final String userId; // User who is sharing their location
  final String? tripId; // Optional trip association
  final double latitude;
  final double longitude;
  final double? accuracy; // Accuracy in meters
  final double? altitude;
  final double? speed; // Speed in m/s
  final double? heading; // Direction in degrees
  final LocationShareStatus status;
  final DateTime startedAt;
  final DateTime? expiresAt; // When sharing will auto-stop
  final DateTime lastUpdatedAt;
  final List<String> sharedWithContactIds; // IDs of emergency contacts who can see location
  final String? message; // Optional message like "I'm safe" or "Help needed"

  const LocationShareModel({
    required this.id,
    required this.userId,
    this.tripId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    required this.status,
    required this.startedAt,
    this.expiresAt,
    required this.lastUpdatedAt,
    required this.sharedWithContactIds,
    this.message,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        tripId,
        latitude,
        longitude,
        accuracy,
        altitude,
        speed,
        heading,
        status,
        startedAt,
        expiresAt,
        lastUpdatedAt,
        sharedWithContactIds,
        message,
      ];

  LocationShareModel copyWith({
    String? id,
    String? userId,
    String? tripId,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    LocationShareStatus? status,
    DateTime? startedAt,
    DateTime? expiresAt,
    DateTime? lastUpdatedAt,
    List<String>? sharedWithContactIds,
    String? message,
  }) {
    return LocationShareModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tripId: tripId ?? this.tripId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      sharedWithContactIds: sharedWithContactIds ?? this.sharedWithContactIds,
      message: message ?? this.message,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'trip_id': tripId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'status': status.name,
      'started_at': startedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'last_updated_at': lastUpdatedAt.toIso8601String(),
      'shared_with_contact_ids': sharedWithContactIds,
      'message': message,
    };
  }

  factory LocationShareModel.fromJson(Map<String, dynamic> json) {
    return LocationShareModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      tripId: json['trip_id'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      altitude: json['altitude'] != null ? (json['altitude'] as num).toDouble() : null,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      heading: json['heading'] != null ? (json['heading'] as num).toDouble() : null,
      status: LocationShareStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LocationShareStatus.stopped,
      ),
      startedAt: DateTime.parse(json['started_at'] as String),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      lastUpdatedAt: DateTime.parse(json['last_updated_at'] as String),
      sharedWithContactIds: (json['shared_with_contact_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      message: json['message'] as String?,
    );
  }

  /// Check if location sharing is currently active
  bool get isActive => status == LocationShareStatus.active;

  /// Check if location sharing has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Get duration since location was last updated
  Duration get timeSinceLastUpdate => DateTime.now().difference(lastUpdatedAt);
}
