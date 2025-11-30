/// Admin Configuration Model
/// Represents app-wide configuration settings managed by admins
class AdminConfigModel {
  final String id;
  final String key;
  final String value;
  final String? description;
  final String category;
  final String valueType; // 'string', 'number', 'boolean', 'json'
  final bool isEditable;
  final DateTime? updatedAt;
  final String? updatedBy;

  const AdminConfigModel({
    required this.id,
    required this.key,
    required this.value,
    this.description,
    required this.category,
    required this.valueType,
    this.isEditable = true,
    this.updatedAt,
    this.updatedBy,
  });

  factory AdminConfigModel.fromJson(Map<String, dynamic> json) {
    return AdminConfigModel(
      id: json['id'] as String,
      key: json['key'] as String,
      value: json['value']?.toString() ?? '',
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'general',
      valueType: json['value_type'] as String? ?? 'string',
      isEditable: json['is_editable'] as bool? ?? true,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
      'description': description,
      'category': category,
      'value_type': valueType,
      'is_editable': isEditable,
      'updated_at': updatedAt?.toIso8601String(),
      'updated_by': updatedBy,
    };
  }

  AdminConfigModel copyWith({
    String? id,
    String? key,
    String? value,
    String? description,
    String? category,
    String? valueType,
    bool? isEditable,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return AdminConfigModel(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      description: description ?? this.description,
      category: category ?? this.category,
      valueType: valueType ?? this.valueType,
      isEditable: isEditable ?? this.isEditable,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  /// Get boolean value (for boolean type configs)
  bool get boolValue => value.toLowerCase() == 'true';

  /// Get numeric value (for number type configs)
  double? get numValue => double.tryParse(value);

  /// Get integer value
  int? get intValue => int.tryParse(value);

  /// Display name from key (e.g., 'max_trip_members' -> 'Max Trip Members')
  String get displayName {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}

/// Configuration categories
enum ConfigCategory {
  general('general', 'General'),
  trips('trips', 'Trips'),
  expenses('expenses', 'Expenses'),
  users('users', 'Users'),
  notifications('notifications', 'Notifications'),
  security('security', 'Security'),
  features('features', 'Feature Flags');

  final String value;
  final String displayName;

  const ConfigCategory(this.value, this.displayName);

  static ConfigCategory fromString(String value) {
    return ConfigCategory.values.firstWhere(
      (c) => c.value == value,
      orElse: () => ConfigCategory.general,
    );
  }
}

/// Parameters for filtering configurations
class ConfigListParams {
  final String? category;
  final String? search;

  const ConfigListParams({
    this.category,
    this.search,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConfigListParams &&
        other.category == category &&
        other.search == search;
  }

  @override
  int get hashCode => category.hashCode ^ search.hashCode;
}
