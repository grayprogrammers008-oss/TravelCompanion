import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../shared/models/trip_model.dart';
import '../../domain/usecases/get_user_stats_usecase.dart';

/// Trip Remote Data Source - Supabase Implementation
///
/// Handles all trip-related operations with Supabase backend.
/// Provides CRUD operations, member management, and real-time subscriptions.
/// Model for system users that can be added to trips
class SystemUserModel {
  final String id;
  final String? email;
  final String? fullName;
  final String? avatarUrl;

  const SystemUserModel({
    required this.id,
    this.email,
    this.fullName,
    this.avatarUrl,
  });

  factory SystemUserModel.fromJson(Map<String, dynamic> json) {
    return SystemUserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  String get displayName => fullName ?? email ?? 'Unknown User';
}

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

  /// Search for system users to add to trip
  /// Excludes users already in the trip
  Future<List<SystemUserModel>> searchSystemUsers({
    String? search,
    List<String>? excludeUserIds,
    int limit = 50,
  });

  /// Watch trips for real-time updates
  Stream<List<TripWithMembers>> watchUserTrips();

  /// Watch a specific trip for real-time updates
  Stream<TripWithMembers> watchTrip(String tripId);

  /// Watch trip member changes
  Stream<List<TripMemberModel>> watchTripMembers(String tripId);

  /// Get user's travel statistics
  Future<UserTravelStats> getUserStats();

  /// Watch user's travel statistics with real-time updates
  Stream<UserTravelStats> watchUserStats();

  /// Get public trips that the current user can join (not already a member)
  Future<List<TripWithMembers>> getDiscoverableTrips();
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
            'budget': trip.budget,
            'currency': trip.currency,
            'is_public': trip.isPublic,
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

      if (kDebugMode) {
        debugPrint('🔍 Fetching trips for user: $userId');
      }

      // First, get all trip IDs where the user is a member
      final userTripsResponse = await _client
          .from('trip_members')
          .select('trip_id')
          .eq('user_id', userId);

      final tripIds = (userTripsResponse as List)
          .map((row) => row['trip_id'] as String)
          .toList();

      if (kDebugMode) {
        debugPrint('🔍 Found ${tripIds.length} trip IDs: $tripIds');
      }

      if (tripIds.isEmpty) {
        return [];
      }

      // Then get all trips with ALL their members
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
          .inFilter('id', tripIds)
          .order('created_at', ascending: false);

      final trips = (response as List)
          .map((tripData) => _parseTripWithMembers(tripData))
          .toList();

      if (kDebugMode) {
        debugPrint('🔍 Returning ${trips.length} trips with members');
        for (final trip in trips) {
          debugPrint('   - ${trip.trip.name}: ${trip.members.length} members, memberCount: ${trip.memberCount}');
        }
      }

      return trips;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error in getUserTrips: $e');
      }
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
  Future<List<SystemUserModel>> searchSystemUsers({
    String? search,
    List<String>? excludeUserIds,
    int limit = 50,
  }) async {
    try {
      // Build query to fetch users from profiles
      var query = _client
          .from('profiles')
          .select('id, email, full_name, avatar_url');

      // Apply search filter if provided
      if (search != null && search.isNotEmpty) {
        query = query.or('email.ilike.%$search%,full_name.ilike.%$search%');
      }

      // Execute query with ordering and limit
      final response = await query
          .order('full_name', ascending: true)
          .limit(limit);

      // Parse response
      var users = (response as List)
          .map((json) => SystemUserModel.fromJson(json))
          .toList();

      // Filter out excluded users (existing members)
      if (excludeUserIds != null && excludeUserIds.isNotEmpty) {
        users = users.where((user) => !excludeUserIds.contains(user.id)).toList();
      }

      if (kDebugMode) {
        debugPrint('🔍 Found ${users.length} system users for search: "$search"');
      }

      return users;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching system users: $e');
      }
      throw Exception('Failed to search users: $e');
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

    // Function to refetch and emit trips
    Future<void> refetchTrips(String reason) async {
      if (kDebugMode) {
        debugPrint('🔄 $reason - Refetching trips...');
      }
      try {
        final trips = await getUserTrips();
        if (!controller.isClosed) {
          controller.add(trips);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error fetching trips after realtime update: $e');
        }
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    // Subscribe to trip_members changes (when user joins/leaves trips)
    final memberSubscription = _realtimeService.subscribeUserTrips(userId).listen(
      (payload) => refetchTrips('Trip membership changed: ${payload.eventType}'),
      onError: (error) {
        if (kDebugMode) {
          debugPrint('❌ Trip members subscription error: $error');
        }
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    // Also subscribe to ALL trips table changes (for updates to trip details)
    // We'll subscribe to the trips table directly and refetch when any trip changes
    final tripUpdatesChannel = _client.channel('all_trips_updates:$userId');

    tripUpdatesChannel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trips',
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('🔄 Trip table changed: ${payload.eventType}');
            }
            // Refetch trips when any trip is created, updated, or deleted
            refetchTrips('Trip ${payload.eventType}');
          },
        )
        .subscribe((status, error) {
          if (kDebugMode) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint('✅ Successfully subscribed to trips table updates');
            } else if (status == RealtimeSubscribeStatus.timedOut) {
              debugPrint('❌ Trips table subscription TIMED OUT');
            } else if (status == RealtimeSubscribeStatus.channelError) {
              debugPrint('❌ Trips table subscription ERROR: $error');
            }
          }
        });

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
      memberSubscription.cancel();
      tripUpdatesChannel.unsubscribe();
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

    // Get member count from data or use members list length
    final memberCount = data['member_count'] as int? ?? members.length;

    return TripWithMembers(
      trip: trip,
      members: members,
      memberCount: memberCount,
    );
  }

  /// Convert camelCase to snake_case
  String _toSnakeCase(String camelCase) {
    return camelCase.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  @override
  Future<UserTravelStats> getUserStats() async {
    try {
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Query 1: Count total trips where user is a member
      final tripsResponse = await _client
          .from('trip_members')
          .select('trip_id')
          .eq('user_id', userId);

      final totalTrips = (tripsResponse as List).length;

      // Query 2 & 3: Get all expense splits for user (count and sum)
      final expenseSplitsResponse = await _client
          .from('expense_splits')
          .select('id, amount')
          .eq('user_id', userId);

      final expenseSplitsList = expenseSplitsResponse as List;
      final totalExpenses = expenseSplitsList.length;

      double totalSpent = 0.0;
      for (final split in expenseSplitsList) {
        totalSpent += (split['amount'] as num?)?.toDouble() ?? 0.0;
      }

      // Query 4: Count unique crew members (other users in same trips)
      final userTripsResponse = await _client
          .from('trip_members')
          .select('trip_id')
          .eq('user_id', userId);

      final userTripIds = (userTripsResponse as List)
          .map((m) => m['trip_id'] as String)
          .toList();

      int uniqueCrewMembers = 0;
      if (userTripIds.isNotEmpty) {
        final crewMembersResponse = await _client
            .from('trip_members')
            .select('user_id')
            .inFilter('trip_id', userTripIds)
            .neq('user_id', userId);

        // Get unique user IDs
        final uniqueUserIds = (crewMembersResponse as List)
            .map((m) => m['user_id'] as String)
            .toSet();

        uniqueCrewMembers = uniqueUserIds.length;
      }

      return UserTravelStats(
        totalTrips: totalTrips,
        totalExpenses: totalExpenses,
        totalSpent: totalSpent,
        uniqueCrewMembers: uniqueCrewMembers,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching user stats: $e');
      }
      throw Exception('Failed to get user stats: $e');
    }
  }

  @override
  Stream<UserTravelStats> watchUserStats() {
    final userId = SupabaseClientWrapper.currentUserId;
    if (userId == null) {
      return Stream.error(Exception('User not authenticated'));
    }

    final controller = StreamController<UserTravelStats>.broadcast();

    // Function to refetch and emit stats
    Future<void> refetchStats(String reason) async {
      if (kDebugMode) {
        debugPrint('🔄 $reason - Refetching user stats...');
      }
      try {
        final stats = await getUserStats();
        if (!controller.isClosed) {
          controller.add(stats);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error fetching stats after realtime update: $e');
        }
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    // Subscribe to trip_members changes
    final tripMembersChannel = _client.channel('user_stats_trip_members:$userId');
    tripMembersChannel
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
              debugPrint('🔄 Trip members changed: ${payload.eventType}');
            }
            refetchStats('Trip membership ${payload.eventType}');
          },
        )
        .subscribe();

    // Subscribe to expense_splits changes
    final expenseSplitsChannel = _client.channel('user_stats_expense_splits:$userId');
    expenseSplitsChannel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expense_splits',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('🔄 Expense splits changed: ${payload.eventType}');
            }
            refetchStats('Expense splits ${payload.eventType}');
          },
        )
        .subscribe();

    // Initial load
    getUserStats().then((stats) {
      if (!controller.isClosed) {
        controller.add(stats);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    // Cleanup on close
    controller.onCancel = () {
      tripMembersChannel.unsubscribe();
      expenseSplitsChannel.unsubscribe();
    };

    return controller.stream;
  }

  @override
  Future<List<TripWithMembers>> getDiscoverableTrips() async {
    try {
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        debugPrint('🔍 Fetching discoverable public trips for user: $userId');
      }

      // First, get all trip IDs where the user is already a member
      final userTripsResponse = await _client
          .from('trip_members')
          .select('trip_id')
          .eq('user_id', userId);

      final userTripIds = (userTripsResponse as List)
          .map((row) => row['trip_id'] as String)
          .toList();

      if (kDebugMode) {
        debugPrint('🔍 User is already member of ${userTripIds.length} trips');
      }

      // Query for all public trips
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
          .eq('is_public', true) // Only public trips
          .order('created_at', ascending: false)
          .limit(100); // Limit to 100 most recent public trips

      // Parse all public trips and filter out trips where user is already a member
      final allPublicTrips = (response as List)
          .map((tripData) => _parseTripWithMembers(tripData))
          .toList();

      // Filter out trips where the current user is already a member
      final trips = allPublicTrips
          .where((trip) => !userTripIds.contains(trip.trip.id))
          .take(50) // Limit to 50 trips
          .toList();

      if (kDebugMode) {
        debugPrint('🔍 Found ${trips.length} discoverable public trips');
      }

      return trips;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching discoverable trips: $e');
      }
      throw Exception('Failed to get discoverable trips: $e');
    }
  }
}
