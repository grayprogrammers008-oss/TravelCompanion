/// Itinerary item entity for domain layer
/// This is a type alias to the shared model for compatibility with the PDF export service
library;

import '../../../../shared/models/itinerary_model.dart';

/// Type alias for ItineraryItemEntity - uses ItineraryItemModel as the underlying type
/// This maintains clean architecture by having a domain layer entity
/// while avoiding code duplication
typedef ItineraryItemEntity = ItineraryItemModel;

/// Type alias for ItineraryDayEntity
typedef ItineraryDayEntity = ItineraryDay;

/// Extension to add domain-specific properties to ItineraryItemModel
extension ItineraryItemEntityExtension on ItineraryItemEntity {
  /// Get the date for this item (from startTime or use dayNumber)
  DateTime? get date => startTime;

  /// Get the time for this item
  DateTime? get time => startTime;

  /// Check if item is scheduled (has time)
  bool get isScheduled => startTime != null;

  /// Get display time range
  String? get timeRange {
    if (startTime == null) return null;
    if (endTime == null) return _formatTime(startTime!);
    return '${_formatTime(startTime!)} - ${_formatTime(endTime!)}';
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }
}
