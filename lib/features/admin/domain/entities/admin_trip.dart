/// Admin Trip Model
/// Extended trip model with additional admin-specific data
class AdminTripModel {
  final String id;
  final String name;
  final String? description;
  final String? destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? coverImageUrl;
  final String createdBy;
  final String creatorName;
  final String creatorEmail;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isCompleted;
  final DateTime? completedAt;
  final double rating;
  final double? budget;
  final String currency;
  final int memberCount;
  final double? totalExpenses;

  const AdminTripModel({
    required this.id,
    required this.name,
    this.description,
    this.destination,
    this.startDate,
    this.endDate,
    this.coverImageUrl,
    required this.createdBy,
    required this.creatorName,
    required this.creatorEmail,
    this.createdAt,
    this.updatedAt,
    this.isCompleted = false,
    this.completedAt,
    this.rating = 0.0,
    this.budget,
    this.currency = 'INR',
    this.memberCount = 0,
    this.totalExpenses,
  });

  factory AdminTripModel.fromJson(Map<String, dynamic> json) {
    return AdminTripModel(
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
      creatorName: json['creator_name'] as String,
      creatorEmail: json['creator_email'] as String,
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
      budget: (json['budget'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      totalExpenses: (json['total_expenses'] as num?)?.toDouble(),
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
      'creator_name': creatorName,
      'creator_email': creatorEmail,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'rating': rating,
      'budget': budget,
      'currency': currency,
      'member_count': memberCount,
      'total_expenses': totalExpenses,
    };
  }

  AdminTripModel copyWith({
    String? id,
    String? name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
    String? createdBy,
    String? creatorName,
    String? creatorEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
    DateTime? completedAt,
    double? rating,
    double? budget,
    String? currency,
    int? memberCount,
    double? totalExpenses,
  }) {
    return AdminTripModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      creatorEmail: creatorEmail ?? this.creatorEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      rating: rating ?? this.rating,
      budget: budget ?? this.budget,
      currency: currency ?? this.currency,
      memberCount: memberCount ?? this.memberCount,
      totalExpenses: totalExpenses ?? this.totalExpenses,
    );
  }
}

/// Trip list query parameters
class TripListParams {
  final int limit;
  final int offset;
  final String? search;
  final String? status;

  const TripListParams({
    this.limit = 50,
    this.offset = 0,
    this.search,
    this.status,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripListParams &&
        other.limit == limit &&
        other.offset == offset &&
        other.search == search &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(limit, offset, search, status);
  }
}
