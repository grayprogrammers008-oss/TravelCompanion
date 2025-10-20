import 'package:uuid/uuid.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../shared/models/itinerary_model.dart';

/// Remote data source for itinerary operations using Supabase
class ItineraryRemoteDataSource {
  final _uuid = const Uuid();

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
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final itemId = _uuid.v4();

      final data = {
        'id': itemId,
        'trip_id': tripId,
        'title': title,
        'description': description,
        'location': location,
        'start_time': startTime?.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'day_number': dayNumber,
        'order_index': orderIndex,
        'created_by': userId,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await SupabaseClientWrapper.client
          .from('itinerary_items')
          .insert(data)
          .select('*, profiles!created_by(full_name)')
          .single();

      return ItineraryItemModel.fromJson({
        ...response,
        'creator_name': response['profiles']?['full_name'],
      });
    } catch (e) {
      throw Exception('Failed to create itinerary item: $e');
    }
  }

  /// Get all itinerary items for a trip
  Future<List<ItineraryItemModel>> getTripItinerary(String tripId) async {
    try {
      final response = await SupabaseClientWrapper.client
          .from('itinerary_items')
          .select('*, profiles!created_by(full_name)')
          .eq('trip_id', tripId)
          .order('day_number', ascending: true)
          .order('order_index', ascending: true);

      return (response as List).map((json) {
        return ItineraryItemModel.fromJson({
          ...json,
          'creator_name': json['profiles']?['full_name'],
        });
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
      final response = await SupabaseClientWrapper.client
          .from('itinerary_items')
          .select('*, profiles!created_by(full_name)')
          .eq('trip_id', tripId)
          .eq('day_number', dayNumber)
          .order('order_index', ascending: true);

      return (response as List).map((json) {
        return ItineraryItemModel.fromJson({
          ...json,
          'creator_name': json['profiles']?['full_name'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get day itinerary: $e');
    }
  }

  /// Get itinerary grouped by days
  Future<List<ItineraryDay>> getItineraryByDays(String tripId) async {
    try {
      final items = await getTripItinerary(tripId);

      // Group items by day number
      final Map<int, List<ItineraryItemModel>> dayGroups = {};
      for (final item in items) {
        final dayNum = item.dayNumber ?? 0;
        dayGroups.putIfAbsent(dayNum, () => []).add(item);
      }

      // Convert to ItineraryDay list and sort by day number
      final days = dayGroups.entries.map((entry) {
        return ItineraryDay(
          dayNumber: entry.key,
          items: entry.value,
        );
      }).toList();

      days.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
      return days;
    } catch (e) {
      throw Exception('Failed to get itinerary by days: $e');
    }
  }

  /// Get a single itinerary item by ID
  Future<ItineraryItemModel> getItem(String itemId) async {
    try {
      final response = await SupabaseClientWrapper.client
          .from('itinerary_items')
          .select('*, profiles!created_by(full_name)')
          .eq('id', itemId)
          .single();

      return ItineraryItemModel.fromJson({
        ...response,
        'creator_name': response['profiles']?['full_name'],
      });
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
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (location != null) updates['location'] = location;
      if (startTime != null) updates['start_time'] = startTime.toIso8601String();
      if (endTime != null) updates['end_time'] = endTime.toIso8601String();
      if (dayNumber != null) updates['day_number'] = dayNumber;
      if (orderIndex != null) updates['order_index'] = orderIndex;

      final response = await SupabaseClientWrapper.client
          .from('itinerary_items')
          .update(updates)
          .eq('id', itemId)
          .select('*, profiles!created_by(full_name)')
          .single();

      return ItineraryItemModel.fromJson({
        ...response,
        'creator_name': response['profiles']?['full_name'],
      });
    } catch (e) {
      throw Exception('Failed to update itinerary item: $e');
    }
  }

  /// Delete an itinerary item
  Future<void> deleteItem(String itemId) async {
    try {
      await SupabaseClientWrapper.client
          .from('itinerary_items')
          .delete()
          .eq('id', itemId);
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
      // Update order_index for each item
      for (int i = 0; i < itemIds.length; i++) {
        await SupabaseClientWrapper.client
            .from('itinerary_items')
            .update({
              'order_index': i,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', itemIds[i])
            .eq('trip_id', tripId)
            .eq('day_number', dayNumber);
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
      // Get the trip_id first
      final item = await getItem(itemId);

      // Get max order_index for the target day
      final response = await SupabaseClientWrapper.client
          .from('itinerary_items')
          .select('order_index')
          .eq('trip_id', item.tripId)
          .eq('day_number', newDayNumber)
          .order('order_index', ascending: false)
          .limit(1);

      final maxOrder = response.isNotEmpty
          ? (response.first['order_index'] as int? ?? 0)
          : 0;

      // Update the item with new day and order
      await SupabaseClientWrapper.client
          .from('itinerary_items')
          .update({
            'day_number': newDayNumber,
            'order_index': maxOrder + 1,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', itemId);
    } catch (e) {
      throw Exception('Failed to move item to day: $e');
    }
  }
}
