import 'package:equatable/equatable.dart';

/// Hospital type enumeration
enum HospitalType {
  general,
  specialized,
  emergency,
  traumaCenter,
  urgentCare;

  String get displayName {
    switch (this) {
      case HospitalType.general:
        return 'General Hospital';
      case HospitalType.specialized:
        return 'Specialized Hospital';
      case HospitalType.emergency:
        return 'Emergency Hospital';
      case HospitalType.traumaCenter:
        return 'Trauma Center';
      case HospitalType.urgentCare:
        return 'Urgent Care';
    }
  }

  static HospitalType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'general':
        return HospitalType.general;
      case 'specialized':
        return HospitalType.specialized;
      case 'emergency':
        return HospitalType.emergency;
      case 'trauma_center':
        return HospitalType.traumaCenter;
      case 'urgent_care':
        return HospitalType.urgentCare;
      default:
        return HospitalType.general;
    }
  }

  String toJson() {
    switch (this) {
      case HospitalType.general:
        return 'general';
      case HospitalType.specialized:
        return 'specialized';
      case HospitalType.emergency:
        return 'emergency';
      case HospitalType.traumaCenter:
        return 'trauma_center';
      case HospitalType.urgentCare:
        return 'urgent_care';
    }
  }
}

/// Trauma level enumeration
enum TraumaLevel {
  levelOne, // I - Highest level
  levelTwo, // II
  levelThree, // III
  levelFour, // IV
  levelFive; // V

  String get displayName {
    switch (this) {
      case TraumaLevel.levelOne:
        return 'Level I';
      case TraumaLevel.levelTwo:
        return 'Level II';
      case TraumaLevel.levelThree:
        return 'Level III';
      case TraumaLevel.levelFour:
        return 'Level IV';
      case TraumaLevel.levelFive:
        return 'Level V';
    }
  }

  static TraumaLevel? fromString(String? value) {
    if (value == null) return null;
    switch (value.toUpperCase()) {
      case 'I':
        return TraumaLevel.levelOne;
      case 'II':
        return TraumaLevel.levelTwo;
      case 'III':
        return TraumaLevel.levelThree;
      case 'IV':
        return TraumaLevel.levelFour;
      case 'V':
        return TraumaLevel.levelFive;
      default:
        return null;
    }
  }

  String toJson() {
    switch (this) {
      case TraumaLevel.levelOne:
        return 'I';
      case TraumaLevel.levelTwo:
        return 'II';
      case TraumaLevel.levelThree:
        return 'III';
      case TraumaLevel.levelFour:
        return 'IV';
      case TraumaLevel.levelFive:
        return 'V';
    }
  }
}

/// Represents a hospital for emergency services
class HospitalModel extends Equatable {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String country;
  final String? postalCode;
  final double latitude;
  final double longitude;
  final String? phoneNumber;
  final String? emergencyPhone;
  final String? website;
  final String? email;

  // Hospital Details
  final HospitalType type;
  final int? capacity;
  final bool hasEmergencyRoom;
  final bool hasTraumaCenter;
  final TraumaLevel? traumaLevel;
  final bool acceptsAmbulance;

  // Operating Hours
  final bool is24_7;
  final Map<String, dynamic>? openingHours;

  // Services and Specialties
  final List<String> services;
  final List<String> specialties;

  // Ratings and Status
  final double? rating;
  final int totalReviews;
  final bool isActive;
  final bool isVerified;

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  // Calculated field (not stored in DB)
  final double? distanceKm;

  const HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    this.country = 'USA',
    this.postalCode,
    required this.latitude,
    required this.longitude,
    this.phoneNumber,
    this.emergencyPhone,
    this.website,
    this.email,
    required this.type,
    this.capacity,
    this.hasEmergencyRoom = true,
    this.hasTraumaCenter = false,
    this.traumaLevel,
    this.acceptsAmbulance = true,
    this.is24_7 = true,
    this.openingHours,
    this.services = const [],
    this.specialties = const [],
    this.rating,
    this.totalReviews = 0,
    this.isActive = true,
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
    this.distanceKm,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        city,
        state,
        country,
        postalCode,
        latitude,
        longitude,
        phoneNumber,
        emergencyPhone,
        website,
        email,
        type,
        capacity,
        hasEmergencyRoom,
        hasTraumaCenter,
        traumaLevel,
        acceptsAmbulance,
        is24_7,
        openingHours,
        services,
        specialties,
        rating,
        totalReviews,
        isActive,
        isVerified,
        createdAt,
        updatedAt,
        metadata,
        distanceKm,
      ];

  HospitalModel copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? phoneNumber,
    String? emergencyPhone,
    String? website,
    String? email,
    HospitalType? type,
    int? capacity,
    bool? hasEmergencyRoom,
    bool? hasTraumaCenter,
    TraumaLevel? traumaLevel,
    bool? acceptsAmbulance,
    bool? is24_7,
    Map<String, dynamic>? openingHours,
    List<String>? services,
    List<String>? specialties,
    double? rating,
    int? totalReviews,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    double? distanceKm,
  }) {
    return HospitalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      website: website ?? this.website,
      email: email ?? this.email,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      hasEmergencyRoom: hasEmergencyRoom ?? this.hasEmergencyRoom,
      hasTraumaCenter: hasTraumaCenter ?? this.hasTraumaCenter,
      traumaLevel: traumaLevel ?? this.traumaLevel,
      acceptsAmbulance: acceptsAmbulance ?? this.acceptsAmbulance,
      is24_7: is24_7 ?? this.is24_7,
      openingHours: openingHours ?? this.openingHours,
      services: services ?? this.services,
      specialties: specialties ?? this.specialties,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'phone_number': phoneNumber,
      'emergency_phone': emergencyPhone,
      'website': website,
      'email': email,
      'type': type.toJson(),
      'capacity': capacity,
      'has_emergency_room': hasEmergencyRoom,
      'has_trauma_center': hasTraumaCenter,
      'trauma_level': traumaLevel?.toJson(),
      'accepts_ambulance': acceptsAmbulance,
      'is_24_7': is24_7,
      'opening_hours': openingHours,
      'services': services,
      'specialties': specialties,
      'rating': rating,
      'total_reviews': totalReviews,
      'is_active': isActive,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
      if (distanceKm != null) 'distance_km': distanceKm,
    };
  }

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      country: json['country'] as String? ?? 'USA',
      postalCode: json['postal_code'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phoneNumber: json['phone_number'] as String?,
      emergencyPhone: json['emergency_phone'] as String?,
      website: json['website'] as String?,
      email: json['email'] as String?,
      type: HospitalType.fromString(json['type'] as String),
      capacity: json['capacity'] as int?,
      hasEmergencyRoom: json['has_emergency_room'] as bool? ?? true,
      hasTraumaCenter: json['has_trauma_center'] as bool? ?? false,
      traumaLevel: TraumaLevel.fromString(json['trauma_level'] as String?),
      acceptsAmbulance: json['accepts_ambulance'] as bool? ?? true,
      is24_7: json['is_24_7'] as bool? ?? true,
      openingHours: json['opening_hours'] as Map<String, dynamic>?,
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      specialties: (json['specialties'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      totalReviews: json['total_reviews'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      distanceKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : null,
    );
  }

  // Helper getters
  String get distanceText {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  bool get isSuitableForEmergency {
    return isActive && hasEmergencyRoom && (is24_7 || acceptsAmbulance);
  }

  double get emergencyPriorityScore {
    double score = 0.0;

    // Distance is the primary factor (closer is better)
    if (distanceKm != null) {
      score += (50 - distanceKm!.clamp(0, 50)) * 2; // Max 100 points
    }

    // Trauma center gets bonus points
    if (hasTraumaCenter) {
      score += 30;
      if (traumaLevel == TraumaLevel.levelOne) {
        score += 20;
      } else if (traumaLevel == TraumaLevel.levelTwo) {
        score += 10;
      }
    }

    // 24/7 availability
    if (is24_7) {
      score += 20;
    }

    // Rating bonus
    if (rating != null) {
      score += rating! * 4; // Max 20 points
    }

    // Verification bonus
    if (isVerified) {
      score += 10;
    }

    return score;
  }

  String get fullAddress {
    final parts = [address, city, state, postalCode, country];
    return parts.where((p) => p != null && p.isNotEmpty).join(', ');
  }
}
