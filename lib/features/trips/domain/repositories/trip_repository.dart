import '../../../../shared/models/trip_model.dart';
import '../usecases/get_user_stats_usecase.dart';

/// Abstract trip repository
abstract class TripRepository {
  /// Create a new trip
  Future<TripModel> createTrip({
    required String name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
    double? cost,
    String? currency,
    bool isPublic = true,
  });

  /// Get all trips for current user
  Future<List<TripWithMembers>> getUserTrips();

  /// Get trip by ID with members
  Future<TripWithMembers> getTripById(String tripId);

  /// Update trip
  Future<TripModel> updateTrip({
    required String tripId,
    String? name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
    bool? isCompleted,
    DateTime? completedAt,
    double? rating,
    double? cost,
    String? currency,
    bool? isPublic,
  });

  /// Delete trip
  Future<void> deleteTrip(String tripId);

  /// Get trip members
  Future<List<TripMemberModel>> getTripMembers(String tripId);

  /// Add member to trip
  Future<TripMemberModel> addMember({
    required String tripId,
    required String userId,
    String role,
  });

  /// Remove member from trip
  Future<void> removeMember({required String tripId, required String userId});

  /// Stream of all user trips with real-time updates
  Stream<List<TripWithMembers>> watchUserTrips();

  /// Stream of trip updates
  Stream<TripWithMembers> watchTrip(String tripId);

  /// Get user's travel statistics
  Future<UserTravelStats> getUserStats();

  /// Watch user's travel statistics with real-time updates
  Stream<UserTravelStats> watchUserStats();

  /// Get public trips that the current user can discover and join
  Future<List<TripWithMembers>> getDiscoverableTrips();

  /// Join a public trip
  Future<void> joinTrip(String tripId);

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
}
