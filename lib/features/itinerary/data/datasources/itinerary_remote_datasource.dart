import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../shared/models/itinerary_model.dart';
import 'itinerary_queries.dart';

/// Remote data source for itinerary operations using Supabase.
///
/// All Supabase PostgREST chain calls live behind [ItineraryQueries] so the
/// datasource itself can be exercised by unit tests. The default constructor
/// wires up the production [ItineraryQueriesImpl]; tests inject a fake.
///
/// Real-time stream methods (`watchTripItinerary`, `watchItineraryByDays`)
/// continue to use `_supabase.channel(...)` directly because realtime
/// subscriptions are not part of the PostgREST query surface and do not
/// fit the chain abstraction.
class ItineraryRemoteDataSource {
  ItineraryRemoteDataSource(
    SupabaseClient? supabase, {
    ItineraryQueries? queries,
    Uuid? uuid,
    DateTime Function()? clock,
  })  : _supabase = supabase ?? SupabaseClientWrapper.client,
        _queries =
            queries ?? ItineraryQueriesImpl(supabase ?? SupabaseClientWrapper.client),
        _uuid = uuid ?? const Uuid(),
        _clock = clock ?? DateTime.now;

  final SupabaseClient _supabase;
  final ItineraryQueries _queries;
  final Uuid _uuid;
  final DateTime Function() _clock;

  /// Create a new itinerary item
  Future<ItineraryItemModel> createItem({
    required String tripId,
    required String title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? placeId,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int orderIndex = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final now = _clock();
      final itemId = _uuid.v4();

      final data = {
        'id': itemId,
        'trip_id': tripId,
        'title': title,
        'description': description,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'place_id': placeId,
        'start_time': startTime?.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'day_number': dayNumber,
        'order_index': orderIndex,
        'created_by': userId,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _queries.insertItem(data);

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
      final rows = await _queries.findItemsForTrip(tripId);

      return rows.map((json) {
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
      final rows = await _queries.findItemsForDay(tripId, dayNumber);

      return rows.map((json) {
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
      final response = await _queries.findItemById(itemId);

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
    double? latitude,
    double? longitude,
    String? placeId,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int? orderIndex,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': _clock().toIso8601String(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (location != null) updates['location'] = location;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (placeId != null) updates['place_id'] = placeId;
      if (startTime != null) updates['start_time'] = startTime.toIso8601String();
      if (endTime != null) updates['end_time'] = endTime.toIso8601String();
      if (dayNumber != null) updates['day_number'] = dayNumber;
      if (orderIndex != null) updates['order_index'] = orderIndex;

      final response = await _queries.updateItemByIdReturning(itemId, updates);

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
      await _queries.deleteItemById(itemId);
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
        await _queries.updateItemScopedToDay(
          itemId: itemIds[i],
          tripId: tripId,
          dayNumber: dayNumber,
          data: {
            'order_index': i,
            'updated_at': _clock().toIso8601String(),
          },
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
      // Get the trip_id first
      final item = await getItem(itemId);

      // Get max order_index for the target day
      final response = await _queries.findMaxOrderIndexForDay(
        item.tripId,
        newDayNumber,
      );

      final maxOrder = response.isNotEmpty
          ? (response.first['order_index'] as int? ?? 0)
          : 0;

      // Update the item with new day and order
      await _queries.updateItemById(itemId, {
        'day_number': newDayNumber,
        'order_index': maxOrder + 1,
        'updated_at': _clock().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to move item to day: $e');
    }
  }

  /// Watch trip itinerary in real-time
  Stream<List<ItineraryItemModel>> watchTripItinerary(String tripId) {
    final controller = StreamController<List<ItineraryItemModel>>.broadcast();

    // Refetch function
    Future<void> refetch(String reason) async {
      if (kDebugMode) {
        debugPrint('🔄 $reason - Refetching itinerary...');
      }
      try {
        final items = await getTripItinerary(tripId);
        if (!controller.isClosed) {
          controller.add(items);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error fetching itinerary: $e');
        }
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    // Subscribe to itinerary_items table changes
    final channel = _supabase.channel('itinerary:$tripId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'itinerary_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'trip_id',
            value: tripId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('🔄 Itinerary item changed: ${payload.eventType}');
            }
            refetch('Itinerary ${payload.eventType}');
          },
        )
        .subscribe((status, error) {
          if (kDebugMode) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint('✅ Successfully subscribed to itinerary for trip:$tripId');
            } else if (status == RealtimeSubscribeStatus.timedOut) {
              debugPrint('❌ Itinerary subscription TIMED OUT for trip:$tripId');
            } else if (status == RealtimeSubscribeStatus.channelError) {
              debugPrint('❌ Itinerary subscription ERROR for trip:$tripId - Error: $error');
            }
          }
        });

    // Initial load
    getTripItinerary(tripId).then((items) {
      if (!controller.isClosed) {
        controller.add(items);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    // Cleanup
    controller.onCancel = () {
      channel.unsubscribe();
    };

    return controller.stream;
  }

  /// Watch itinerary by days in real-time
  Stream<List<ItineraryDay>> watchItineraryByDays(String tripId) {
    final controller = StreamController<List<ItineraryDay>>.broadcast();

    // Refetch function
    Future<void> refetch(String reason) async {
      if (kDebugMode) {
        debugPrint('🔄 $reason - Refetching itinerary by days...');
      }
      try {
        final days = await getItineraryByDays(tripId);
        if (!controller.isClosed) {
          controller.add(days);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error fetching itinerary by days: $e');
        }
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    // Subscribe to itinerary_items table changes
    final channel = _supabase.channel('itinerary_days:$tripId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'itinerary_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'trip_id',
            value: tripId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('🔄 Itinerary item changed: ${payload.eventType}');
            }
            refetch('Itinerary ${payload.eventType}');
          },
        )
        .subscribe((status, error) {
          if (kDebugMode) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint('✅ Successfully subscribed to itinerary by days for trip:$tripId');
            } else if (status == RealtimeSubscribeStatus.timedOut) {
              debugPrint('❌ Itinerary by days subscription TIMED OUT for trip:$tripId');
            } else if (status == RealtimeSubscribeStatus.channelError) {
              debugPrint('❌ Itinerary by days subscription ERROR for trip:$tripId - Error: $error');
            }
          }
        });

    // Initial load
    getItineraryByDays(tripId).then((days) {
      if (!controller.isClosed) {
        controller.add(days);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    // Cleanup
    controller.onCancel = () {
      channel.unsubscribe();
    };

    return controller.stream;
  }
}
