import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../shared/models/trip_model.dart';

/// Trip Remote Data Source - Supabase Implementation
///
/// Handles all trip-related operations with Supabase backend.
/// Provides CRUD operations, member management, and real-time subscriptions.
abstract class TripRemoteDataSource {
  /// Create a new trip
  Future<TripModel> createTrip(TripModel trip);

  /// Get all trips for the current user
  Future<List<TripWithMembers>> getUserTrips();

  /// Get a single trip by ID (with members)
  Future<TripWithMembers?> getTripById(String tripId);

  /// Update a trip
  Future<void> updateTrip(String tripId, Map<String, dynamic> updates);

  /// Delete a trip
  Future<void> deleteTrip(String tripId);

  /// Add a member to a trip
  Future<void> addMember(String tripId, String userId, {String role = 'member'});

  /// Remove a member from a trip
  Future<void> removeMember(String tripId, String userId);

  /// Watch trips for real-time updates
  Stream<List<TripWithMembers>> watchUserTrips();

  /// Watch a specific trip for real-time updates
  Stream<TripWithMembers> watchTrip(String tripId);

  /// Watch trip member changes
  Stream<List<TripMemberModel>> watchTripMembers(String tripId);
}

class TripRemoteDataSourceImpl implements TripRemoteDataSource {
  final SupabaseClient _client;
  final RealtimeService _realtimeService;

  TripRemoteDataSourceImpl()
      : _client = SupabaseClientWrapper.client,
        _realtimeService = RealtimeService();

  @override
  Future<TripModel> createTrip(TripModel trip) async {
    try {
      // Create trip in Supabase
      final response = await _client
          .from('trips')
          .insert({
            'name': trip.name,
            'description': trip.description,
            'destination': trip.destination,
            'start_date': trip.startDate?.toIso8601String(),
            'end_date': trip.endDate?.toIso8601String(),
            'cover_image_url': trip.coverImageUrl,
            'created_by': SupabaseClientWrapper.currentUserId,
          })
          .select()
          .single();

      return TripModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create trip: $e');
    }
  }

  @override
  Future<List<TripWithMembers>> getUserTrips() async {
    try {
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get trips where user is a member
      final response = await _client
          .from('trips')
          .select('''
            *,
            trip_members!inner(
              id,
              user_id,
              role,
              joined_at,
              profiles!inner(
                id,
                email,
                full_name,
                avatar_url
              )
            )
          ''')
          .eq('trip_members.user_id', userId)
          .order('created_at', ascending: false);

      final trips = (response as List)
          .map((tripData) => _parseTripWithMembers(tripData))
          .toList();

      return trips;
    } catch (e) {
      throw Exception('Failed to get user trips: $e');
    }
  }

  @override
  Future<TripWithMembers?> getTripById(String tripId) async {
    try {
      final response = await _client
          .from('trips')
          .select('''
            *,
            trip_members(
              id,
              user_id,
              role,
              joined_at,
              profiles(
                id,
                email,
                full_name,
                avatar_url
              )
            )
          ''')
          .eq('id', tripId)
          .maybeSingle();

      if (response == null) return null;

      return _parseTripWithMembers(response);
    } catch (e) {
      throw Exception('Failed to get trip: $e');
    }
  }

  @override
  Future<void> updateTrip(String tripId, Map<String, dynamic> updates) async {
    try {
      if (kDebugMode) {
        debugPrint('DEBUG: ========== DATASOURCE UPDATE ==========');
        debugPrint('DEBUG: Trip ID: $tripId');
        debugPrint('DEBUG: Raw Updates Map: $updates');
      }

      // Filter out null values and format dates
      final filteredUpdates = <String, dynamic>{};

      updates.forEach((key, value) {
        if (value != null) {
          if (key == 'startDate' || key == 'endDate') {
            filteredUpdates[_toSnakeCase(key)] =
                (value as DateTime).toIso8601String();
          } else {
            filteredUpdates[_toSnakeCase(key)] = value;
          }
        }
      });

      if (kDebugMode) {
        debugPrint('DEBUG: Filtered Updates (after removing nulls): $filteredUpdates');
      }

      final response = await _client
          .from('trips')
          .update(filteredUpdates)
          .eq('id', tripId)
          .select();

      if (kDebugMode) {
        debugPrint('DEBUG: Supabase Update Response: $response');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG: ========== DATASOURCE UPDATE ERROR ==========');
        debugPrint('DEBUG: Error: $e');
      }
      throw Exception('Failed to update trip: $e');
    }
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    try {
      await _client
          .from('trips')
          .delete()
          .eq('id', tripId);
    } catch (e) {
      throw Exception('Failed to delete trip: $e');
    }
  }

  @override
  Future<void> addMember(String tripId, String userId, {String role = 'member'}) async {
    try {
      await _client
          .from('trip_members')
          .insert({
            'trip_id': tripId,
            'user_id': userId,
            'role': role,
          });
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  @override
  Future<void> removeMember(String tripId, String userId) async {
    try {
      await _client
          .from('trip_members')
          .delete()
          .eq('trip_id', tripId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  @override
  Stream<List<TripWithMembers>> watchUserTrips() {
    final userId = SupabaseClientWrapper.currentUserId;
    if (userId == null) {
      return Stream.error(Exception('User not authenticated'));
    }

    // Use enhanced realtime service to watch trip changes
    final controller = StreamController<List<TripWithMembers>>.broadcast();

    // Subscribe to user's trip membership changes
    final subscription = _realtimeService.subscribeUserTrips(userId).listen(
      (payload) async {
        if (kDebugMode) {
          debugPrint('🔄 User trips changed: ${payload.eventType}');
        }
        // Refetch trips when changes occur
        try {
          final trips = await getUserTrips();
          controller.add(trips);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Error fetching trips after realtime update: $e');
          }
          controller.addError(e);
        }
      },
      onError: (error) {
        if (kDebugMode) {
          debugPrint('❌ Realtime subscription error: $error');
        }
        controller.addError(error);
      },
    );

    // Initial load
    getUserTrips().then((trips) {
      if (!controller.isClosed) {
        controller.add(trips);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    // Cleanup on close
    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  @override
  Stream<TripWithMembers> watchTrip(String tripId) {
    final controller = StreamController<TripWithMembers>.broadcast();

    // Subscribe to trip changes
    final subscription = _realtimeService.subscribeTripChanges(tripId).listen(
      (payload) async {
        if (kDebugMode) {
          debugPrint('🔄 Trip $tripId changed: ${payload.eventType}');
        }

        // Refetch trip when changes occur
        try {
          final trip = await getTripById(tripId);
          if (trip != null && !controller.isClosed) {
            controller.add(trip);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Error fetching trip after realtime update: $e');
          }
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
      },
      onError: (error) {
        if (kDebugMode) {
          debugPrint('❌ Realtime subscription error for trip $tripId: $error');
        }
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    // Initial load
    getTripById(tripId).then((trip) {
      if (trip != null && !controller.isClosed) {
        controller.add(trip);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    // Cleanup on close
    controller.onCancel = () {
      subscription.cancel();
      _realtimeService.unsubscribe('trip:$tripId');
    };

    return controller.stream;
  }

  @override
  Stream<List<TripMemberModel>> watchTripMembers(String tripId) {
    final controller = StreamController<List<TripMemberModel>>.broadcast();

    // Subscribe to trip member changes
    final subscription = _realtimeService.subscribeTripMemberChanges(tripId).listen(
      (payload) async {
        if (kDebugMode) {
          debugPrint('🔄 Trip $tripId members changed: ${payload.eventType}');
        }

        // Refetch trip to get updated members
        try {
          final trip = await getTripById(tripId);
          if (trip != null && !controller.isClosed) {
            controller.add(trip.members);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Error fetching members after realtime update: $e');
          }
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
      },
      onError: (error) {
        if (kDebugMode) {
          debugPrint('❌ Realtime subscription error for trip members: $error');
        }
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    // Initial load
    getTripById(tripId).then((trip) {
      if (trip != null && !controller.isClosed) {
        controller.add(trip.members);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    // Cleanup on close
    controller.onCancel = () {
      subscription.cancel();
      _realtimeService.unsubscribe('trip_members:$tripId');
    };

    return controller.stream;
  }

  /// Parse trip data with members from Supabase response
  TripWithMembers _parseTripWithMembers(Map<String, dynamic> data) {
    // Parse base trip
    final trip = TripModel.fromJson(data);

    // Parse members
    final membersData = data['trip_members'] as List?;
    final members = membersData?.map((memberData) {
      final profileData = memberData['profiles'];
      return TripMemberModel(
        id: memberData['id'],
        tripId: trip.id,
        userId: memberData['user_id'],
        role: memberData['role'],
        joinedAt: DateTime.parse(memberData['joined_at']),
        email: profileData?['email'],
        fullName: profileData?['full_name'],
        avatarUrl: profileData?['avatar_url'],
      );
    }).toList() ?? [];

    return TripWithMembers(trip: trip, members: members);
  }

  /// Convert camelCase to snake_case
  String _toSnakeCase(String camelCase) {
    return camelCase.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }
}
