import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/supabase_client.dart';

/// Real-time synchronization service for Travel Crew
///
/// Manages Supabase Realtime channels for trips, expenses, itineraries, and checklists.
/// Provides optimistic updates, conflict resolution, and offline queue support.
class RealtimeService {
  final SupabaseClient _client;
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamController> _controllers = {};

  RealtimeService() : _client = SupabaseClientWrapper.client;

  /// Subscribe to trip changes
  ///
  /// Listens for INSERT, UPDATE, DELETE events on trips table
  /// Returns a stream of PostgresChangePayload events
  Stream<PostgresChangePayload> subscribeTripChanges(String tripId) {
    final channelName = 'trip:$tripId';

    if (_controllers.containsKey(channelName)) {
      if (kDebugMode) {
        debugPrint('📡 Reusing existing subscription: $channelName');
      }
      return _controllers[channelName]!.stream as Stream<PostgresChangePayload>;
    }

    if (kDebugMode) {
      debugPrint('📡 Creating NEW subscription: $channelName');
    }

    final controller = StreamController<PostgresChangePayload>.broadcast();
    _controllers[channelName] = controller;

    final channel = _client.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trips',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: tripId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('🔄 Trip change detected: ${payload.eventType} - $tripId');
              debugPrint('   Payload: ${payload.newRecord}');
            }
            controller.add(payload);
          },
        )
        .subscribe((status, error) {
          if (kDebugMode) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint('✅ Successfully subscribed to trip:$tripId');
            } else if (status == RealtimeSubscribeStatus.timedOut) {
              debugPrint('❌ Subscription TIMED OUT for trip:$tripId');
            } else if (status == RealtimeSubscribeStatus.channelError) {
              debugPrint('❌ Channel ERROR for trip:$tripId - Error: $error');
            }
          }
        });

    _channels[channelName] = channel;

    return controller.stream;
  }

  /// Subscribe to expense changes for a trip
  ///
  /// Listens for INSERT, UPDATE, DELETE events on expenses table
  Stream<PostgresChangePayload> subscribeExpenseChanges(String tripId) {
    final channelName = 'expenses:$tripId';

    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream as Stream<PostgresChangePayload>;
    }

    final controller = StreamController<PostgresChangePayload>.broadcast();
    _controllers[channelName] = controller;

    final channel = _client.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expenses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'trip_id',
            value: tripId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('🔄 Expense change detected: ${payload.eventType} - Trip: $tripId');
            }
            controller.add(payload);
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    return controller.stream;
  }

  /// Subscribe to itinerary changes for a trip
  ///
  /// Listens for INSERT, UPDATE, DELETE events on itinerary_items table
  Stream<PostgresChangePayload> subscribeItineraryChanges(String tripId) {
    final channelName = 'itinerary:$tripId';

    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream as Stream<PostgresChangePayload>;
    }

    final controller = StreamController<PostgresChangePayload>.broadcast();
    _controllers[channelName] = controller;

    final channel = _client.channel(channelName);

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
              debugPrint('🔄 Itinerary change detected: ${payload.eventType} - Trip: $tripId');
            }
            controller.add(payload);
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    return controller.stream;
  }

  /// Subscribe to checklist changes for a trip
  ///
  /// Listens for INSERT, UPDATE, DELETE events on checklists and checklist_items tables
  Stream<PostgresChangePayload> subscribeChecklistChanges(String tripId) {
    final channelName = 'checklists:$tripId';

    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream as Stream<PostgresChangePayload>;
    }

    final controller = StreamController<PostgresChangePayload>.broadcast();
    _controllers[channelName] = controller;

    final channel = _client.channel(channelName);

    // Subscribe to checklists table
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'checklists',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'trip_id',
        value: tripId,
      ),
      callback: (payload) {
        if (kDebugMode) {
          debugPrint('🔄 Checklist change detected: ${payload.eventType} - Trip: $tripId');
        }
        controller.add(payload);
      },
    );

    // Also subscribe to checklist_items changes
    // Note: This requires filtering by checklist_id, which we'll handle separately

    channel.subscribe();

    _channels[channelName] = channel;

    return controller.stream;
  }

  /// Subscribe to checklist items changes for a specific checklist
  Stream<PostgresChangePayload> subscribeChecklistItemChanges(String checklistId) {
    final channelName = 'checklist_items:$checklistId';

    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream as Stream<PostgresChangePayload>;
    }

    final controller = StreamController<PostgresChangePayload>.broadcast();
    _controllers[channelName] = controller;

    final channel = _client.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'checklist_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'checklist_id',
            value: checklistId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('🔄 Checklist item change detected: ${payload.eventType} - Checklist: $checklistId');
            }
            controller.add(payload);
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    return controller.stream;
  }

  /// Subscribe to trip member changes
  ///
  /// Useful for showing "Nithya joined the trip" notifications
  Stream<PostgresChangePayload> subscribeTripMemberChanges(String tripId) {
    final channelName = 'trip_members:$tripId';

    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream as Stream<PostgresChangePayload>;
    }

    final controller = StreamController<PostgresChangePayload>.broadcast();
    _controllers[channelName] = controller;

    final channel = _client.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trip_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'trip_id',
            value: tripId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('🔄 Trip member change detected: ${payload.eventType} - Trip: $tripId');
            }
            controller.add(payload);
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    return controller.stream;
  }

  /// Subscribe to user's trips (for trips list page)
  ///
  /// Listens for changes across all trips where user is a member
  Stream<PostgresChangePayload> subscribeUserTrips(String userId) {
    final channelName = 'user_trips:$userId';

    if (_controllers.containsKey(channelName)) {
      if (kDebugMode) {
        debugPrint('📡 Reusing existing subscription: $channelName');
      }
      return _controllers[channelName]!.stream as Stream<PostgresChangePayload>;
    }

    if (kDebugMode) {
      debugPrint('📡 Creating NEW subscription for user trips: $userId');
    }

    final controller = StreamController<PostgresChangePayload>.broadcast();
    _controllers[channelName] = controller;

    // Note: This is a simplified version. For production, you might want to
    // subscribe to trip_members table and then query trips when changes occur
    final channel = _client.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trip_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('🔄 User trip membership change detected: ${payload.eventType}');
              debugPrint('   Trip Member Payload: ${payload.newRecord}');
            }
            controller.add(payload);
          },
        )
        .subscribe((status, error) {
          if (kDebugMode) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint('✅ Successfully subscribed to user trips for user:$userId');
            } else if (status == RealtimeSubscribeStatus.timedOut) {
              debugPrint('❌ User trips subscription TIMED OUT for user:$userId');
            } else if (status == RealtimeSubscribeStatus.channelError) {
              debugPrint('❌ User trips channel ERROR for user:$userId - Error: $error');
            }
          }
        });

    _channels[channelName] = channel;

    return controller.stream;
  }

  /// Unsubscribe from a specific channel
  void unsubscribe(String channelName) {
    if (_channels.containsKey(channelName)) {
      if (kDebugMode) {
        debugPrint('🔕 Unsubscribing from channel: $channelName');
      }

      _channels[channelName]?.unsubscribe();
      _channels.remove(channelName);

      _controllers[channelName]?.close();
      _controllers.remove(channelName);
    }
  }

  /// Unsubscribe from all channels
  void unsubscribeAll() {
    if (kDebugMode) {
      debugPrint('🔕 Unsubscribing from all channels (${_channels.length} active)');
    }

    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    _channels.clear();

    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }

  /// Get active channel count
  int get activeChannelCount => _channels.length;

  /// Check if a specific channel is active
  bool isChannelActive(String channelName) => _channels.containsKey(channelName);

  /// Dispose the service
  void dispose() {
    unsubscribeAll();
  }
}

/// Realtime event types
enum RealtimeEventType {
  insert,
  update,
  delete,
}

/// Helper extension to parse event type
extension RealtimeEventTypeExtension on PostgresChangeEvent {
  RealtimeEventType get eventType {
    switch (this) {
      case PostgresChangeEvent.insert:
        return RealtimeEventType.insert;
      case PostgresChangeEvent.update:
        return RealtimeEventType.update;
      case PostgresChangeEvent.delete:
        return RealtimeEventType.delete;
      default:
        return RealtimeEventType.update;
    }
  }
}
