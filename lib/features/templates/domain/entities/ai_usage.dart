// AI Usage Entity
//
// Tracks user's AI itinerary generation usage for freemium model.

/// User AI Usage Model
class UserAiUsage {
  final String id;
  final String userId;
  final int aiGenerationsUsed;
  final int aiGenerationsLimit;
  final bool isPremium;
  final String? premiumPlan;
  final DateTime? premiumStartedAt;
  final DateTime? premiumExpiresAt;
  final int lifetimeGenerations;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserAiUsage({
    required this.id,
    required this.userId,
    this.aiGenerationsUsed = 0,
    this.aiGenerationsLimit = 5,
    this.isPremium = false,
    this.premiumPlan,
    this.premiumStartedAt,
    this.premiumExpiresAt,
    this.lifetimeGenerations = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if user can generate more AI itineraries
  bool get canGenerate {
    if (isPremium && premiumExpiresAt != null && premiumExpiresAt!.isAfter(DateTime.now())) {
      return true;
    }
    return aiGenerationsUsed < aiGenerationsLimit;
  }

  /// Get remaining generations (-1 for unlimited)
  int get remainingGenerations {
    if (isPremium && premiumExpiresAt != null && premiumExpiresAt!.isAfter(DateTime.now())) {
      return -1; // Unlimited
    }
    return (aiGenerationsLimit - aiGenerationsUsed).clamp(0, aiGenerationsLimit);
  }

  /// Check if premium subscription is active
  bool get isPremiumActive {
    return isPremium && premiumExpiresAt != null && premiumExpiresAt!.isAfter(DateTime.now());
  }

  /// Days until premium expires
  int? get daysUntilExpiry {
    if (!isPremiumActive) return null;
    return premiumExpiresAt!.difference(DateTime.now()).inDays;
  }

  factory UserAiUsage.fromJson(Map<String, dynamic> json) {
    return UserAiUsage(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      aiGenerationsUsed: json['ai_generations_used'] as int? ?? 0,
      aiGenerationsLimit: json['ai_generations_limit'] as int? ?? 5,
      isPremium: json['is_premium'] as bool? ?? false,
      premiumPlan: json['premium_plan'] as String?,
      premiumStartedAt: json['premium_started_at'] != null
          ? DateTime.parse(json['premium_started_at'] as String)
          : null,
      premiumExpiresAt: json['premium_expires_at'] != null
          ? DateTime.parse(json['premium_expires_at'] as String)
          : null,
      lifetimeGenerations: json['lifetime_generations'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'ai_generations_used': aiGenerationsUsed,
      'ai_generations_limit': aiGenerationsLimit,
      'is_premium': isPremium,
      'premium_plan': premiumPlan,
      'premium_started_at': premiumStartedAt?.toIso8601String(),
      'premium_expires_at': premiumExpiresAt?.toIso8601String(),
      'lifetime_generations': lifetimeGenerations,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a default usage record for new users
  factory UserAiUsage.newUser(String userId) {
    final now = DateTime.now();
    return UserAiUsage(
      id: '',
      userId: userId,
      aiGenerationsUsed: 0,
      aiGenerationsLimit: 5,
      isPremium: false,
      lifetimeGenerations: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  UserAiUsage copyWith({
    String? id,
    String? userId,
    int? aiGenerationsUsed,
    int? aiGenerationsLimit,
    bool? isPremium,
    String? premiumPlan,
    DateTime? premiumStartedAt,
    DateTime? premiumExpiresAt,
    int? lifetimeGenerations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAiUsage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      aiGenerationsUsed: aiGenerationsUsed ?? this.aiGenerationsUsed,
      aiGenerationsLimit: aiGenerationsLimit ?? this.aiGenerationsLimit,
      isPremium: isPremium ?? this.isPremium,
      premiumPlan: premiumPlan ?? this.premiumPlan,
      premiumStartedAt: premiumStartedAt ?? this.premiumStartedAt,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      lifetimeGenerations: lifetimeGenerations ?? this.lifetimeGenerations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// AI Generation Log for analytics
class AiGenerationLog {
  final String id;
  final String userId;
  final String destination;
  final int durationDays;
  final double? budget;
  final List<String> interests;
  final String? tripId;
  final int? generationTimeMs;
  final bool wasSuccessful;
  final String? errorMessage;
  final DateTime createdAt;

  const AiGenerationLog({
    required this.id,
    required this.userId,
    required this.destination,
    required this.durationDays,
    this.budget,
    this.interests = const [],
    this.tripId,
    this.generationTimeMs,
    this.wasSuccessful = true,
    this.errorMessage,
    required this.createdAt,
  });

  factory AiGenerationLog.fromJson(Map<String, dynamic> json) {
    return AiGenerationLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      destination: json['destination'] as String,
      durationDays: json['duration_days'] as int,
      budget: json['budget'] != null
          ? (json['budget'] as num).toDouble()
          : null,
      interests: json['interests'] != null
          ? List<String>.from(json['interests'] as List)
          : const [],
      tripId: json['trip_id'] as String?,
      generationTimeMs: json['generation_time_ms'] as int?,
      wasSuccessful: json['was_successful'] as bool? ?? true,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'destination': destination,
      'duration_days': durationDays,
      'budget': budget,
      'interests': interests,
      'trip_id': tripId,
      'generation_time_ms': generationTimeMs,
      'was_successful': wasSuccessful,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
