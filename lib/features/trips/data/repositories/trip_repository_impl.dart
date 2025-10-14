import '../../../../shared/models/trip_model.dart';
import '../../domain/repositories/trip_repository.dart';
// SUPABASE DISABLED - Using SQLite for local development
// import '../datasources/trip_remote_datasource.dart';
import '../datasources/trip_local_datasource.dart';

/// Implementation of trip repository
class TripRepositoryImpl implements TripRepository {
  // Using local datasource instead of remote
  final TripLocalDataSource _localDataSource;

  TripRepositoryImpl(this._localDataSource);

  @override
  Future<TripModel> createTrip({
    required String name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
  }) async {
    return await _localDataSource.createTrip(
      name: name,
      description: description,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      coverImageUrl: coverImageUrl,
    );
  }

  @override
  Future<List<TripWithMembers>> getUserTrips() async {
    return await _localDataSource.getUserTrips();
  }

  @override
  Future<TripWithMembers> getTripById(String tripId) async {
    return await _localDataSource.getTripById(tripId);
  }

  @override
  Future<TripModel> updateTrip({
    required String tripId,
    String? name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
  }) async {
    return await _localDataSource.updateTrip(
      tripId: tripId,
      name: name,
      description: description,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      coverImageUrl: coverImageUrl,
    );
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    await _localDataSource.deleteTrip(tripId);
  }

  @override
  Future<List<TripMemberModel>> getTripMembers(String tripId) async {
    return await _localDataSource.getTripMembers(tripId);
  }

  @override
  Future<TripMemberModel> addMember({
    required String tripId,
    required String userId,
    String role = 'member',
  }) async {
    return await _localDataSource.addMember(
      tripId: tripId,
      userId: userId,
      role: role,
    );
  }

  @override
  Future<void> removeMember({
    required String tripId,
    required String userId,
  }) async {
    await _localDataSource.removeMember(tripId: tripId, userId: userId);
  }

  @override
  Stream<TripWithMembers> watchTrip(String tripId) {
    return _localDataSource.watchTrip(tripId);
  }
}
