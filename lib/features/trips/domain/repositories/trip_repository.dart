import '../../../../shared/models/trip_model.dart';

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

  /// Stream of trip updates
  Stream<TripWithMembers> watchTrip(String tripId);
}
