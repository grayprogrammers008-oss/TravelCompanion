import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../shared/models/trip_model.dart';

/// Local data source for trip operations using SQLite
/// This replaces Supabase during local development
class TripLocalDataSource {
  // Singleton pattern to preserve state
  static final TripLocalDataSource _instance = TripLocalDataSource._internal();
  factory TripLocalDataSource() => _instance;
  TripLocalDataSource._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  // Store current user ID (passed from auth)
  String? _currentUserId;

  void setCurrentUserId(String? userId) {
    print('DEBUG TripLocalDataSource: setCurrentUserId called with: $userId');
    _currentUserId = userId;
  }

  /// Create a new trip
  Future<TripModel> createTrip({
    required String name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
  }) async {
    try {
      print('DEBUG createTrip: _currentUserId = $_currentUserId');

      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final db = await _dbHelper.database;
      final tripId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      print('DEBUG createTrip: Creating trip with ID: $tripId');

      // Create trip
      await db.insert('trips', {
        'id': tripId,
        'name': name,
        'description': description,
        'destination': destination,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'cover_image_url': coverImageUrl,
        'created_by': _currentUserId,
        'created_at': now,
        'updated_at': now,
      });

      print('DEBUG createTrip: Trip inserted into database');

      // Add creator as organizer member
      await db.insert('trip_members', {
        'id': _uuid.v4(),
        'trip_id': tripId,
        'user_id': _currentUserId,
        'role': 'organizer',
        'joined_at': now,
      });

      print('DEBUG createTrip: Member added to trip');

      // Return trip
      final trips = await db.query(
        'trips',
        where: 'id = ?',
        whereArgs: [tripId],
      );

      print('DEBUG createTrip: Trip retrieved from database');
      print('DEBUG createTrip: Trip data = ${trips.first}');

      // Safely convert to Map<String, dynamic>
      final tripData = Map<String, dynamic>.from(trips.first);
      return TripModel.fromJson(tripData);
    } catch (e) {
      print('DEBUG createTrip: ERROR - $e');
      throw Exception('Failed to create trip: $e');
    }
  }

  /// Get all trips for current user
  Future<List<TripWithMembers>> getUserTrips() async {
    try {
      print('DEBUG getUserTrips: _currentUserId = $_currentUserId');

      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final db = await _dbHelper.database;

      // Get trip IDs where user is a member
      final membershipRows = await db.query(
        'trip_members',
        where: 'user_id = ?',
        whereArgs: [_currentUserId],
      );

      print('DEBUG getUserTrips: Found ${membershipRows.length} memberships');

      if (membershipRows.isEmpty) {
        return [];
      }

      final tripIds = membershipRows
          .map((row) => row['trip_id'] as String)
          .toList();
      print('DEBUG getUserTrips: Trip IDs = $tripIds');

      // Get trips
      final trips = await db.query(
        'trips',
        where: 'id IN (${tripIds.map((_) => '?').join(',')})',
        whereArgs: tripIds,
        orderBy: 'created_at DESC',
      );

      // Get all trips with their members
      final List<TripWithMembers> result = [];

      print('DEBUG getUserTrips: Processing ${trips.length} trips');

      for (final tripData in trips) {
        try {
          // Safely convert to Map<String, dynamic>
          final tripMap = Map<String, dynamic>.from(tripData);
          print('DEBUG getUserTrips: Processing trip: ${tripMap['id']}');

          final trip = TripModel.fromJson(tripMap);
          final members = await _getTripMembers(tripData['id'] as String);

          result.add(
            TripWithMembers(
              trip: trip,
              members: members,
              memberCount: members.length,
            ),
          );
        } catch (e) {
          print('DEBUG getUserTrips: Error processing trip: $e');
          // Skip this trip and continue
        }
      }

      print('DEBUG getUserTrips: Returning ${result.length} trips');
      return result;
    } catch (e) {
      throw Exception('Failed to get trips: $e');
    }
  }

  /// Get trip by ID with members
  Future<TripWithMembers> getTripById(String tripId) async {
    try {
      final db = await _dbHelper.database;

      final trips = await db.query(
        'trips',
        where: 'id = ?',
        whereArgs: [tripId],
      );

      if (trips.isEmpty) {
        throw Exception('Trip not found');
      }

      final trip = TripModel.fromJson(trips.first);
      final members = await _getTripMembers(tripId);

      return TripWithMembers(
        trip: trip,
        members: members,
        memberCount: members.length,
      );
    } catch (e) {
      throw Exception('Failed to get trip: $e');
    }
  }

  /// Update trip
  Future<TripModel> updateTrip({
    required String tripId,
    String? name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
  }) async {
    try {
      final db = await _dbHelper.database;

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (destination != null) updates['destination'] = destination;
      if (startDate != null) {
        updates['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) updates['end_date'] = endDate.toIso8601String();
      if (coverImageUrl != null) updates['cover_image_url'] = coverImageUrl;

      await db.update('trips', updates, where: 'id = ?', whereArgs: [tripId]);

      final trips = await db.query(
        'trips',
        where: 'id = ?',
        whereArgs: [tripId],
      );

      return TripModel.fromJson(trips.first);
    } catch (e) {
      throw Exception('Failed to update trip: $e');
    }
  }

  /// Delete trip
  Future<void> deleteTrip(String tripId) async {
    try {
      final db = await _dbHelper.database;
      await db.delete('trips', where: 'id = ?', whereArgs: [tripId]);
    } catch (e) {
      throw Exception('Failed to delete trip: $e');
    }
  }

  /// Get trip members (private helper)
  Future<List<TripMemberModel>> _getTripMembers(String tripId) async {
    final db = await _dbHelper.database;

    final memberRows = await db.rawQuery(
      '''
      SELECT
        tm.id,
        tm.trip_id,
        tm.user_id,
        tm.role,
        tm.joined_at,
        p.full_name,
        p.avatar_url,
        p.email
      FROM trip_members tm
      INNER JOIN profiles p ON tm.user_id = p.id
      WHERE tm.trip_id = ?
    ''',
      [tripId],
    );

    return memberRows.map<TripMemberModel>((row) {
      return TripMemberModel(
        id: row['id'] as String,
        tripId: row['trip_id'] as String,
        userId: row['user_id'] as String,
        role: row['role'] as String,
        joinedAt: row['joined_at'] != null
            ? DateTime.parse(row['joined_at'] as String)
            : null,
        fullName: row['full_name'] as String?,
        avatarUrl: row['avatar_url'] as String?,
        email: row['email'] as String?,
      );
    }).toList();
  }

  /// Get trip members
  Future<List<TripMemberModel>> getTripMembers(String tripId) async {
    try {
      return await _getTripMembers(tripId);
    } catch (e) {
      throw Exception('Failed to get trip members: $e');
    }
  }

  /// Add member to trip
  Future<TripMemberModel> addMember({
    required String tripId,
    required String userId,
    String role = 'member',
  }) async {
    try {
      final db = await _dbHelper.database;
      final memberId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      await db.insert('trip_members', {
        'id': memberId,
        'trip_id': tripId,
        'user_id': userId,
        'role': role,
        'joined_at': now,
      });

      // Get member with profile data
      final memberRows = await db.rawQuery(
        '''
        SELECT
          tm.id,
          tm.trip_id,
          tm.user_id,
          tm.role,
          tm.joined_at,
          p.full_name,
          p.avatar_url,
          p.email
        FROM trip_members tm
        INNER JOIN profiles p ON tm.user_id = p.id
        WHERE tm.id = ?
      ''',
        [memberId],
      );

      if (memberRows.isEmpty) {
        throw Exception('Failed to fetch added member');
      }

      final row = memberRows.first;
      return TripMemberModel(
        id: row['id'] as String,
        tripId: row['trip_id'] as String,
        userId: row['user_id'] as String,
        role: row['role'] as String,
        joinedAt: row['joined_at'] != null
            ? DateTime.parse(row['joined_at'] as String)
            : null,
        fullName: row['full_name'] as String?,
        avatarUrl: row['avatar_url'] as String?,
        email: row['email'] as String?,
      );
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  /// Remove member from trip
  Future<void> removeMember({
    required String tripId,
    required String userId,
  }) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        'trip_members',
        where: 'trip_id = ? AND user_id = ?',
        whereArgs: [tripId, userId],
      );
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  /// Stream of trip updates (simplified for SQLite)
  /// Note: SQLite doesn't support real-time streams like Supabase
  /// This returns a stream that emits the trip periodically
  Stream<TripWithMembers> watchTrip(String tripId) {
    return Stream.periodic(
      const Duration(seconds: 2),
    ).asyncMap((_) => getTripById(tripId));
  }
}
