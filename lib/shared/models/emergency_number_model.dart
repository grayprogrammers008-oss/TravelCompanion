import 'package:equatable/equatable.dart';

/// Emergency service types
enum EmergencyServiceType {
  police,
  fire,
  ambulance,
  emergency,
  disaster,
  helpline,
  other;

  String get displayName {
    switch (this) {
      case EmergencyServiceType.police:
        return 'Police';
      case EmergencyServiceType.fire:
        return 'Fire';
      case EmergencyServiceType.ambulance:
        return 'Ambulance';
      case EmergencyServiceType.emergency:
        return 'Emergency';
      case EmergencyServiceType.disaster:
        return 'Disaster Management';
      case EmergencyServiceType.helpline:
        return 'Helpline';
      case EmergencyServiceType.other:
        return 'Other';
    }
  }
}

/// Represents an emergency service number
class EmergencyNumberModel extends Equatable {
  final String id;
  final String serviceName;
  final EmergencyServiceType serviceType;
  final String phoneNumber;
  final String? alternateNumber;

  // Location Information
  final String country; // ISO country code
  final String? state;
  final String? city;

  // Service Details
  final String? description;
  final bool isTollFree;
  final bool is24x7;
  final List<String> languages;

  // Display Information
  final String? icon;
  final String? color;
  final int displayOrder;
  final bool isActive;

  const EmergencyNumberModel({
    required this.id,
    required this.serviceName,
    required this.serviceType,
    required this.phoneNumber,
    this.alternateNumber,
    required this.country,
    this.state,
    this.city,
    this.description,
    required this.isTollFree,
    required this.is24x7,
    required this.languages,
    this.icon,
    this.color,
    required this.displayOrder,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        id,
        serviceName,
        serviceType,
        phoneNumber,
        alternateNumber,
        country,
        state,
        city,
        description,
        isTollFree,
        is24x7,
        languages,
        icon,
        color,
        displayOrder,
        isActive,
      ];

  EmergencyNumberModel copyWith({
    String? id,
    String? serviceName,
    EmergencyServiceType? serviceType,
    String? phoneNumber,
    String? alternateNumber,
    String? country,
    String? state,
    String? city,
    String? description,
    bool? isTollFree,
    bool? is24x7,
    List<String>? languages,
    String? icon,
    String? color,
    int? displayOrder,
    bool? isActive,
  }) {
    return EmergencyNumberModel(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      serviceType: serviceType ?? this.serviceType,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      alternateNumber: alternateNumber ?? this.alternateNumber,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      description: description ?? this.description,
      isTollFree: isTollFree ?? this.isTollFree,
      is24x7: is24x7 ?? this.is24x7,
      languages: languages ?? this.languages,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_name': serviceName,
      'service_type': serviceType.name,
      'phone_number': phoneNumber,
      'alternate_number': alternateNumber,
      'country': country,
      'state': state,
      'city': city,
      'description': description,
      'is_toll_free': isTollFree,
      'is_24_7': is24x7,
      'languages': languages,
      'icon': icon,
      'color': color,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }

  factory EmergencyNumberModel.fromJson(Map<String, dynamic> json) {
    return EmergencyNumberModel(
      id: json['id'] as String,
      serviceName: json['service_name'] as String,
      serviceType: EmergencyServiceType.values.firstWhere(
        (e) => e.name == json['service_type'],
        orElse: () => EmergencyServiceType.other,
      ),
      phoneNumber: json['phone_number'] as String,
      alternateNumber: json['alternate_number'] as String?,
      country: json['country'] as String,
      state: json['state'] as String?,
      city: json['city'] as String?,
      description: json['description'] as String?,
      isTollFree: json['is_toll_free'] as bool? ?? false,
      is24x7: json['is_24_7'] as bool? ?? true,
      languages: (json['languages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Get the primary display number (phone or alternate)
  String get primaryNumber => phoneNumber;

  /// Check if has alternate number
  bool get hasAlternateNumber => alternateNumber != null && alternateNumber!.isNotEmpty;

  /// Get display icon or default
  String get displayIcon => icon ?? 'phone';

  /// Get display color or default
  String get displayColor => color ?? '#000000';
}
