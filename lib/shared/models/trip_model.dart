/// Trip model - Plain Dart class (Freezed removed)
class TripModel {
  final String id;
  final String name;
  final String? description;
  final String? destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? coverImageUrl;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isCompleted;
  final DateTime? completedAt;
  final double rating; // Trip rating 0.0 to 5.0 stars
  final double? cost; // Trip cost per person (set by organizer/creator)
  final String currency; // Currency code (e.g., 'INR', 'USD')
  final bool isPublic; // Trip visibility: true = public, false = private

  const TripModel({
    required this.id,
    required this.name,
    this.description,
    this.destination,
    this.startDate,
    this.endDate,
    this.coverImageUrl,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.isCompleted = false,
    this.completedAt,
    this.rating = 0.0,
    this.cost,
    this.currency = 'INR',
    this.isPublic = true, // Default to public for backward compatibility
  });

  TripModel copyWith({
    String? id,
    String? name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
    DateTime? completedAt,
    double? rating,
    double? cost,
    String? currency,
    bool? isPublic,
  }) {
    return TripModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      rating: rating ?? this.rating,
      cost: cost ?? this.cost,
      currency: currency ?? this.currency,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'destination': destination,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'cover_image_url': coverImageUrl,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'rating': rating,
      'cost': cost,
      'currency': currency,
      'is_public': isPublic,
    };
  }

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      destination: json['destination'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      coverImageUrl: json['cover_image_url'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      cost: (json['cost'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      isPublic: json['is_public'] as bool? ?? true, // Default to public for backward compatibility
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripModel &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.destination == destination &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.coverImageUrl == coverImageUrl &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isCompleted == isCompleted &&
        other.completedAt == completedAt &&
        other.rating == rating &&
        other.cost == cost &&
        other.currency == currency &&
        other.isPublic == isPublic;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      destination,
      startDate,
      endDate,
      coverImageUrl,
      createdBy,
      createdAt,
      updatedAt,
      isCompleted,
      completedAt,
      rating,
      cost,
      currency,
      isPublic,
    );
  }

  @override
  String toString() {
    return 'TripModel(id: $id, name: $name, description: $description, destination: $destination, startDate: $startDate, endDate: $endDate, coverImageUrl: $coverImageUrl, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt, isCompleted: $isCompleted, completedAt: $completedAt, rating: $rating, cost: $cost, currency: $currency, isPublic: $isPublic)';
  }
}

/// Trip member model
class TripMemberModel {
  final String id;
  final String tripId;
  final String userId;
  final String role; // 'admin' or 'member'
  final DateTime? joinedAt;
  // User profile data (joined from profiles table)
  final String? fullName;
  final String? avatarUrl;
  final String? email;

  const TripMemberModel({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.role,
    this.joinedAt,
    this.fullName,
    this.avatarUrl,
    this.email,
  });

  TripMemberModel copyWith({
    String? id,
    String? tripId,
    String? userId,
    String? role,
    DateTime? joinedAt,
    String? fullName,
    String? avatarUrl,
    String? email,
  }) {
    return TripMemberModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt?.toIso8601String(),
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'email': email,
    };
  }

  factory TripMemberModel.fromJson(Map<String, dynamic> json) {
    return TripMemberModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripMemberModel &&
        other.id == id &&
        other.tripId == tripId &&
        other.userId == userId &&
        other.role == role &&
        other.joinedAt == joinedAt &&
        other.fullName == fullName &&
        other.avatarUrl == avatarUrl &&
        other.email == email;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      tripId,
      userId,
      role,
      joinedAt,
      fullName,
      avatarUrl,
      email,
    );
  }

  @override
  String toString() {
    return 'TripMemberModel(id: $id, tripId: $tripId, userId: $userId, role: $role, joinedAt: $joinedAt, fullName: $fullName, avatarUrl: $avatarUrl, email: $email)';
  }
}

/// Trip with members (extended model)
class TripWithMembers {
  final TripModel trip;
  final List<TripMemberModel> members;
  final int? memberCount;

  const TripWithMembers({
    required this.trip,
    required this.members,
    this.memberCount,
  });

  TripWithMembers copyWith({
    TripModel? trip,
    List<TripMemberModel>? members,
    int? memberCount,
  }) {
    return TripWithMembers(
      trip: trip ?? this.trip,
      members: members ?? this.members,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip': trip.toJson(),
      'members': members.map((m) => m.toJson()).toList(),
      'member_count': memberCount,
    };
  }

  factory TripWithMembers.fromJson(Map<String, dynamic> json) {
    return TripWithMembers(
      trip: TripModel.fromJson(json['trip'] as Map<String, dynamic>),
      members: (json['members'] as List<dynamic>)
          .map((m) => TripMemberModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      memberCount: json['member_count'] as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripWithMembers &&
        other.trip == trip &&
        _listEquals(other.members, members) &&
        other.memberCount == memberCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      trip,
      Object.hashAll(members),
      memberCount,
    );
  }

  @override
  String toString() {
    return 'TripWithMembers(trip: $trip, members: $members, memberCount: $memberCount)';
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
