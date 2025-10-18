import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../shared/models/itinerary_model.dart';

/// Local data source for itinerary operations using SQLite
class ItineraryLocalDataSource {
  // Singleton pattern to preserve state
  static final ItineraryLocalDataSource _instance = ItineraryLocalDataSource._internal();
  factory ItineraryLocalDataSource() => _instance;
  ItineraryLocalDataSource._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  // Store current user ID (passed from auth)
  String? _currentUserId;

  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

  /// Create a new itinerary item
  Future<ItineraryItemModel> createItem({
    required String tripId,
    required String title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int orderIndex = 0,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final db = await _dbHelper.database;
      final itemId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      // If no day number provided, determine next day
      int? finalDayNumber = dayNumber;
      if (finalDayNumber == null) {
        final result = await db.rawQuery(
          'SELECT MAX(day_number) as max_day FROM itinerary_items WHERE trip_id = ?',
          [tripId],
        );
        final maxDay = result.first['max_day'] as int?;
        finalDayNumber = (maxDay ?? 0) + 1;
      }

      // If no order index provided, add to end of day
      int finalOrderIndex = orderIndex;
      if (orderIndex == 0) {
        final result = await db.rawQuery(
          'SELECT MAX(order_index) as max_order FROM itinerary_items WHERE trip_id = ? AND day_number = ?',
          [tripId, finalDayNumber],
        );
        final maxOrder = result.first['max_order'] as int?;
        finalOrderIndex = (maxOrder ?? -1) + 1;
      }

      await db.insert('itinerary_items', {
        'id': itemId,
        'trip_id': tripId,
        'title': title,
        'description': description,
        'location': location,
        'start_time': startTime?.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'day_number': finalDayNumber,
        'order_index': finalOrderIndex,
        'created_by': _currentUserId,
        'created_at': now,
        'updated_at': now,
      });

      // Fetch and return the created item
      final items = await db.query(
        'itinerary_items',
        where: 'id = ?',
        whereArgs: [itemId],
      );

      final itemData = Map<String, dynamic>.from(items.first);
      return ItineraryItemModel.fromJson(itemData);
    } catch (e) {
      throw Exception('Failed to create itinerary item: $e');
    }
  }

  /// Get all itinerary items for a trip
  Future<List<ItineraryItemModel>> getTripItinerary(String tripId) async {
    try {
      final db = await _dbHelper.database;

      final items = await db.query(
        'itinerary_items',
        where: 'trip_id = ?',
        whereArgs: [tripId],
        orderBy: 'day_number ASC, order_index ASC, start_time ASC',
      );

      return items.map((item) {
        final itemData = Map<String, dynamic>.from(item);
        return ItineraryItemModel.fromJson(itemData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get trip itinerary: $e');
    }
  }

  /// Get itinerary items for a specific day
  Future<List<ItineraryItemModel>> getDayItinerary({
    required String tripId,
    required int dayNumber,
  }) async {
    try {
      final db = await _dbHelper.database;

      final items = await db.query(
        'itinerary_items',
        where: 'trip_id = ? AND day_number = ?',
        whereArgs: [tripId, dayNumber],
        orderBy: 'order_index ASC, start_time ASC',
      );

      return items.map((item) {
        final itemData = Map<String, dynamic>.from(item);
        return ItineraryItemModel.fromJson(itemData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get day itinerary: $e');
    }
  }

  /// Get itinerary grouped by days
  Future<List<ItineraryDay>> getItineraryByDays(String tripId) async {
    try {
      final items = await getTripItinerary(tripId);

      // Group items by day
      final Map<int, List<ItineraryItemModel>> dayGroups = {};
      for (final item in items) {
        final day = item.dayNumber ?? 1;
        if (!dayGroups.containsKey(day)) {
          dayGroups[day] = [];
        }
        dayGroups[day]!.add(item);
      }

      // Convert to ItineraryDay list
      final days = dayGroups.entries.map((entry) {
        return ItineraryDay(
          dayNumber: entry.key,
          items: entry.value,
        );
      }).toList();

      // Sort by day number
      days.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

      return days;
    } catch (e) {
      throw Exception('Failed to get itinerary by days: $e');
    }
  }

  /// Get a single itinerary item by ID
  Future<ItineraryItemModel> getItem(String itemId) async {
    try {
      final db = await _dbHelper.database;

      final items = await db.query(
        'itinerary_items',
        where: 'id = ?',
        whereArgs: [itemId],
      );

      if (items.isEmpty) {
        throw Exception('Itinerary item not found');
      }

      final itemData = Map<String, dynamic>.from(items.first);
      return ItineraryItemModel.fromJson(itemData);
    } catch (e) {
      throw Exception('Failed to get itinerary item: $e');
    }
  }

  /// Update an itinerary item
  Future<ItineraryItemModel> updateItem({
    required String itemId,
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int? orderIndex,
  }) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().toIso8601String();

      // Build update map with only non-null values
      final Map<String, dynamic> updates = {'updated_at': now};

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (location != null) updates['location'] = location;
      if (startTime != null) updates['start_time'] = startTime.toIso8601String();
      if (endTime != null) updates['end_time'] = endTime.toIso8601String();
      if (dayNumber != null) updates['day_number'] = dayNumber;
      if (orderIndex != null) updates['order_index'] = orderIndex;

      await db.update(
        'itinerary_items',
        updates,
        where: 'id = ?',
        whereArgs: [itemId],
      );

      // Fetch and return the updated item
      return await getItem(itemId);
    } catch (e) {
      throw Exception('Failed to update itinerary item: $e');
    }
  }

  /// Delete an itinerary item
  Future<void> deleteItem(String itemId) async {
    try {
      final db = await _dbHelper.database;

      await db.delete(
        'itinerary_items',
        where: 'id = ?',
        whereArgs: [itemId],
      );
    } catch (e) {
      throw Exception('Failed to delete itinerary item: $e');
    }
  }

  /// Reorder items within a day
  Future<void> reorderItems({
    required String tripId,
    required int dayNumber,
    required List<String> itemIds,
  }) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().toIso8601String();

      // Update order_index for each item
      for (int i = 0; i < itemIds.length; i++) {
        await db.update(
          'itinerary_items',
          {
            'order_index': i,
            'updated_at': now,
          },
          where: 'id = ? AND trip_id = ? AND day_number = ?',
          whereArgs: [itemIds[i], tripId, dayNumber],
        );
      }
    } catch (e) {
      throw Exception('Failed to reorder items: $e');
    }
  }

  /// Move item to different day
  Future<void> moveItemToDay({
    required String itemId,
    required int newDayNumber,
  }) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().toIso8601String();

      // Get the item to find its trip_id
      final item = await getItem(itemId);

      // Find the max order index in the new day
      final result = await db.rawQuery(
        'SELECT MAX(order_index) as max_order FROM itinerary_items WHERE trip_id = ? AND day_number = ?',
        [item.tripId, newDayNumber],
      );
      final maxOrder = result.first['max_order'] as int?;
      final newOrderIndex = (maxOrder ?? -1) + 1;

      await db.update(
        'itinerary_items',
        {
          'day_number': newDayNumber,
          'order_index': newOrderIndex,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [itemId],
      );
    } catch (e) {
      throw Exception('Failed to move item to day: $e');
    }
  }
}
