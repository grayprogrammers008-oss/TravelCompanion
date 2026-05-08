import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../shared/models/trip_model.dart';
import '../../domain/usecases/get_user_stats_usecase.dart';
import 'trip_queries.dart';

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

  /// Copy a trip with optional itinerary and checklists
  /// Returns the new trip ID
  Future<String> copyTrip({
    required String sourceTripId,
    required String newName,
    required DateTime newStartDate,
    required DateTime newEndDate,
    bool copyItinerary = true,
    bool copyChecklists = true,
  });

  /// Toggle favorite status for a trip
  /// Returns true if the trip is now a favorite, false otherwise
  Future<bool> toggleFavorite(String tripId);

  /// Get list of favorite trip IDs for the current user
  Future<List<String>> getFavoriteTripIds();
}

/// Default implementation backed by Supabase.
///
/// All PostgREST chain calls go through [TripQueries] so the datasource
/// itself is unit-testable. Realtime subscriptions (`watchUserTrips`,
/// `watchTrip`, `watchTripMembers`, `watchUserStats`) still call
/// `_client.channel(...)` and the [RealtimeService] directly — they are
/// covered by integration / live tests rather than the unit suite.
class TripRemoteDataSourceImpl implements TripRemoteDataSource {
  TripRemoteDataSourceImpl({
    SupabaseClient? supabase,
    TripQueries? queries,
    RealtimeService? realtimeService,
    String? Function()? currentUserId,
  })  : _suppliedClient = supabase,
        _suppliedRealtime = realtimeService,
        _queries = queries ??
            TripQueriesImpl(supabase ?? SupabaseClientWrapper.client),
        _currentUserId =
            currentUserId ?? (() => SupabaseClientWrapper.currentUserId);

  final SupabaseClient? _suppliedClient;
  final RealtimeService? _suppliedRealtime;
  RealtimeService? _cachedRealtime;
  final TripQueries _queries;
  final String? Function() _currentUserId;

  /// Lazy access to the underlying Supabase client.
  ///
  /// Only the realtime stream methods (`watchUserTrips`, `watchUserStats`)
  /// need direct channel access; non-stream methods route everything via
  /// [TripQueries] and never touch this getter, which lets unit tests
  /// inject only a fake [TripQueries] without initializing Supabase.
  SupabaseClient get _client =>
      _suppliedClient ?? SupabaseClientWrapper.client;

  /// Lazy [RealtimeService]. Same rationale as [_client]: only the
  /// realtime stream methods touch it, so unit tests can leave it null.
  RealtimeService get _realtimeService =>
      _suppliedRealtime ?? (_cachedRealtime ??= RealtimeService());

  @override
  Future<TripModel> createTrip(TripModel trip) async {
    try {
      final userId = _currentUserId();
      if (userId == null) throw Exception('User not authenticated');

      final response = await _queries.insertTrip({
        'name': trip.name,
        'description': trip.description,
        'destination': trip.destination,
        'start_date': trip.startDate?.toIso8601String(),
        'end_date': trip.endDate?.toIso8601String(),
        'cover_image_url': trip.coverImageUrl,
        'cost': trip.cost,
        'currency': trip.currency,
        'is_public': trip.isPublic,
        'created_by': userId,
      });

      final createdTrip = TripModel.fromJson(response);
      if (kDebugMode) debugPrint('✅ Trip created: ${createdTrip.id}');
      return createdTrip;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ createTrip failed: $e');
      throw Exception('Failed to create trip: $e');
    }
  }

  @override
  Future<List<TripWithMembers>> getUserTrips() async {
    try {
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        debugPrint('🔍 Fetching trips for user: $userId');
      }

      // Get trip IDs where user is a member
      final memberRows = await _queries.findTripIdsForUser(userId);

      final tripIds =
          memberRows.map((row) => row['trip_id'] as String).toList();

      if (kDebugMode) {
        debugPrint('🔍 Found ${tripIds.length} trip IDs: $tripIds');
      }

      if (tripIds.isEmpty) {
        return [];
      }

      // Fetch favorite trip IDs for the current user
      final favoriteIds = await getFavoriteTripIds();
      final favoriteSet = favoriteIds.toSet();

      if (kDebugMode) {
        debugPrint('⭐ User has ${favoriteIds.length} favorite trips');
      }

      // Fetch trips with all their members
      final response = await _queries.findTripsWithMembersByIds(tripIds);

      final trips = response
          .map((tripData) {
            final trip = _parseTripWithMembers(tripData);
            // Set isFavorite based on whether trip ID is in favorites
            return trip.copyWith(isFavorite: favoriteSet.contains(trip.trip.id));
          })
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
      final response = await _queries.findTripWithMembersById(tripId);

      if (response == null) return null;

      final trip = _parseTripWithMembers(response);

      // Check if this trip is a favorite
      final favoriteIds = await getFavoriteTripIds();
      final isFavorite = favoriteIds.contains(tripId);

      return trip.copyWith(isFavorite: isFavorite);
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

      final response = await _queries.updateTripById(tripId, filteredUpdates);

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
      // Use the admin_delete_trip RPC function to properly cascade delete all related data
      // This function handles: trip_members, expenses, checklists, itinerary_items, then the trip
      final result = await _queries.rpcDeleteTrip(tripId);

      if (result == false) {
        throw Exception('Trip not found or you do not have permission to delete it');
      }

      if (kDebugMode) {
        debugPrint('🗑️ Trip deleted successfully: $tripId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to delete trip: $e');
      }
      throw Exception('Failed to delete trip: $e');
    }
  }

  @override
  Future<void> addMember(String tripId, String userId, {String role = 'member'}) async {
    try {
      // Use .select() to confirm the INSERT is committed before returning
      final result = await _queries.insertTripMember({
        'trip_id': tripId,
        'user_id': userId,
        'role': role,
      });
      if (kDebugMode) {
        debugPrint('✅ Member added to trip $tripId: ${result.length} row(s) inserted');
      }
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  @override
  Future<void> removeMember(String tripId, String userId) async {
    try {
      await _queries.deleteTripMember(tripId, userId);
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
      final response = await _queries.searchProfiles(
        search: search,
        limit: limit,
      );

      var users = response.map((json) => SystemUserModel.fromJson(json)).toList();

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
    final userId = _currentUserId();
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
              // Attempt to refresh session on timeout
              _client.auth.refreshSession();
            } else if (status == RealtimeSubscribeStatus.channelError) {
              debugPrint('❌ Trips table subscription ERROR: $error');
              // Check if JWT error and attempt refresh
              final errorStr = error.toString();
              if (errorStr.contains('InvalidJWTToken') || errorStr.contains('Token has expired')) {
                debugPrint('🔄 JWT error detected, refreshing session...');
                _client.auth.refreshSession();
              }
            }
          }
        });

    // Cleanup on cancel
    controller.onCancel = () {
      memberSubscription.cancel();
      tripUpdatesChannel.unsubscribe();
    };

    // Initial load — delayed to next event loop so the async* subscriber
    // is registered before the first value is emitted on the broadcast stream
    Future.delayed(Duration.zero, () async {
      if (controller.isClosed) return;
      try {
        final trips = await getUserTrips();
        if (!controller.isClosed) controller.add(trips);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    });

    return controller.stream;
  }

  @override
  Stream<TripWithMembers> watchTrip(String tripId) {
    final controller = StreamController<TripWithMembers>.broadcast();

    // Helper to refetch trip data
    Future<void> refetchTrip(String reason) async {
      if (kDebugMode) {
        debugPrint('🔄 Refetching trip $tripId: $reason');
      }
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
    }

    // Subscribe to trip changes (for trip data updates)
    final tripSubscription = _realtimeService.subscribeTripChanges(tripId).listen(
      (payload) => refetchTrip('Trip changed: ${payload.eventType}'),
      onError: (error) {
        if (kDebugMode) {
          debugPrint('❌ Realtime subscription error for trip $tripId: $error');
        }
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    // Subscribe to trip member changes (for member join/leave updates)
    final memberSubscription = _realtimeService.subscribeTripMemberChanges(tripId).listen(
      (payload) => refetchTrip('Member changed: ${payload.eventType}'),
      onError: (error) {
        if (kDebugMode) {
          debugPrint('❌ Realtime member subscription error for trip $tripId: $error');
        }
        // Don't add error to controller for member subscription failures
        // as the main trip subscription is still active
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
      tripSubscription.cancel();
      memberSubscription.cancel();
      _realtimeService.unsubscribe('trip:$tripId');
      _realtimeService.unsubscribe('trip_members:$tripId');
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
      // Supabase may return profiles as a Map (1-to-1 FK) or List (1-to-many)
      final rawProfile = memberData['profiles'];
      final profileData = rawProfile is List
          ? (rawProfile.isNotEmpty ? rawProfile.first as Map<String, dynamic>? : null)
          : rawProfile as Map<String, dynamic>?;
      if (kDebugMode) {
        debugPrint('👤 Member ${memberData['user_id']}: profile=$profileData');
      }
      return TripMemberModel(
        id: memberData['id'],
        tripId: trip.id,
        userId: memberData['user_id'],
        role: memberData['role'],
        joinedAt: DateTime.parse(memberData['joined_at']),
        email: profileData?['email'] as String?,
        fullName: profileData?['full_name'] as String?,
        avatarUrl: profileData?['avatar_url'] as String?,
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
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Query 1: Count total trips where user is a member
      final tripsResponse = await _queries.findTripIdsForUser(userId);
      final totalTrips = tripsResponse.length;

      // Query 2 & 3: Get all expense splits for user (count and sum)
      final expenseSplitsList =
          await _queries.findExpenseSplitsForUser(userId);
      final totalExpenses = expenseSplitsList.length;

      double totalSpent = 0.0;
      for (final split in expenseSplitsList) {
        totalSpent += (split['amount'] as num?)?.toDouble() ?? 0.0;
      }

      // Query 4: Count unique crew members (other users in same trips)
      final userTripsResponse = await _queries.findTripIdsForUser(userId);

      final userTripIds = userTripsResponse
          .map((m) => m['trip_id'] as String)
          .toList();

      int uniqueCrewMembers = 0;
      if (userTripIds.isNotEmpty) {
        final crewMembersResponse =
            await _queries.findCrewMemberIds(userTripIds, userId);

        // Get unique user IDs
        final uniqueUserIds = crewMembersResponse
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
    final userId = _currentUserId();
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
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        debugPrint('🔍 Fetching discoverable public trips for user: $userId');
      }

      // First, get all trip IDs where the user is already a member
      final userTripsResponse = await _queries.findTripIdsForUser(userId);

      final userTripIds = userTripsResponse
          .map((row) => row['trip_id'] as String)
          .toList();

      if (kDebugMode) {
        debugPrint('🔍 User is already member of ${userTripIds.length} trips');
      }

      // Query for all public trips
      final response = await _queries.findPublicTrips(limit: 100);

      // Parse all public trips and filter out trips where user is already a member
      final allPublicTrips = response
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

  @override
  Future<String> copyTrip({
    required String sourceTripId,
    required String newName,
    required DateTime newStartDate,
    required DateTime newEndDate,
    bool copyItinerary = true,
    bool copyChecklists = true,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📋 Copying trip: $sourceTripId');
        debugPrint('   New name: $newName');
        debugPrint('   New dates: $newStartDate - $newEndDate');
        debugPrint('   Copy itinerary: $copyItinerary');
        debugPrint('   Copy checklists: $copyChecklists');
      }

      final newTripId = await _queries.rpcCopyTrip(
        sourceTripId: sourceTripId,
        newName: newName,
        newStartDate: newStartDate,
        newEndDate: newEndDate,
        copyItinerary: copyItinerary,
        copyChecklists: copyChecklists,
      );

      if (kDebugMode) {
        debugPrint('✅ Trip copied successfully! New trip ID: $newTripId');
      }

      return newTripId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to copy trip: $e');
      }
      throw Exception('Failed to copy trip: $e');
    }
  }

  @override
  Future<bool> toggleFavorite(String tripId) async {
    try {
      if (kDebugMode) {
        debugPrint('⭐ Toggling favorite for trip: $tripId');
      }

      final isFavorite = await _queries.rpcToggleFavorite(tripId);

      if (kDebugMode) {
        debugPrint('⭐ Trip $tripId is now ${isFavorite ? 'favorited' : 'unfavorited'}');
      }

      return isFavorite;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to toggle favorite: $e');
      }
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  @override
  Future<List<String>> getFavoriteTripIds() async {
    try {
      if (kDebugMode) {
        debugPrint('⭐ Fetching favorite trip IDs');
      }

      final response = await _queries.rpcGetFavoriteTripIds();

      final tripIds =
          response.map((row) => row['trip_id'] as String).toList();

      if (kDebugMode) {
        debugPrint('⭐ Found ${tripIds.length} favorite trips');
      }

      return tripIds;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get favorite trip IDs: $e');
      }
      throw Exception('Failed to get favorite trip IDs: $e');
    }
  }
}
