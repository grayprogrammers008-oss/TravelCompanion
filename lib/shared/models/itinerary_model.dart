/// Itinerary item model - Plain Dart class (Freezed removed)
class ItineraryItemModel {
  final String id;
  final String tripId;
  final String title;
  final String? description;
  final String? location;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? dayNumber;
  final int orderIndex;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Joined data
  final String? creatorName;

  const ItineraryItemModel({
    required this.id,
    required this.tripId,
    required this.title,
    this.description,
    this.location,
    this.startTime,
    this.endTime,
    this.dayNumber,
    this.orderIndex = 0,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.creatorName,
  });

  ItineraryItemModel copyWith({
    String? id,
    String? tripId,
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int? orderIndex,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? creatorName,
  }) {
    return ItineraryItemModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      dayNumber: dayNumber ?? this.dayNumber,
      orderIndex: orderIndex ?? this.orderIndex,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      creatorName: creatorName ?? this.creatorName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'title': title,
      'description': description,
      'location': location,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'day_number': dayNumber,
      'order_index': orderIndex,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'creator_name': creatorName,
    };
  }

  factory ItineraryItemModel.fromJson(Map<String, dynamic> json) {
    return ItineraryItemModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      dayNumber: json['day_number'] as int?,
      orderIndex: json['order_index'] as int? ?? 0,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      creatorName: json['creator_name'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItineraryItemModel &&
        other.id == id &&
        other.tripId == tripId &&
        other.title == title &&
        other.description == description &&
        other.location == location &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.dayNumber == dayNumber &&
        other.orderIndex == orderIndex &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.creatorName == creatorName;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      tripId,
      title,
      description,
      location,
      startTime,
      endTime,
      dayNumber,
      orderIndex,
      createdBy,
      createdAt,
      updatedAt,
      creatorName,
    );
  }

  @override
  String toString() {
    return 'ItineraryItemModel(id: $id, tripId: $tripId, title: $title, description: $description, location: $location, startTime: $startTime, endTime: $endTime, dayNumber: $dayNumber, orderIndex: $orderIndex, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt, creatorName: $creatorName)';
  }
}

/// Itinerary day summary
class ItineraryDay {
  final int dayNumber;
  final DateTime? date;
  final List<ItineraryItemModel> items;

  ItineraryDay({
    required this.dayNumber,
    this.date,
    required this.items,
  });

  int get itemCount => items.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItineraryDay &&
        other.dayNumber == dayNumber &&
        other.date == date &&
        _listEquals(other.items, items);
  }

  @override
  int get hashCode {
    return Object.hash(
      dayNumber,
      date,
      Object.hashAll(items),
    );
  }

  @override
  String toString() {
    return 'ItineraryDay(dayNumber: $dayNumber, date: $date, items: $items)';
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
