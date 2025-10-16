import 'package:uuid/uuid.dart';
import 'dart:math';
import '../../../../core/database/database_helper.dart';
import '../models/invite_model.dart';

/// Local data source for trip invites using SQLite
class InviteLocalDataSource {
  // Singleton pattern
  static final InviteLocalDataSource _instance = InviteLocalDataSource._internal();
  factory InviteLocalDataSource() => _instance;
  InviteLocalDataSource._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  // Store current user ID (passed from auth)
  String? _currentUserId;

  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

  /// Generate a unique invite code
  ///
  /// Format: 6 characters (uppercase letters and numbers)
  /// Example: ABC123, XYZ789
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Create a new invite
  Future<InviteModel> createInvite({
    required String tripId,
    required String email,
    String? phoneNumber,
    int expiresInDays = 7,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final db = await _dbHelper.database;

      // Generate unique invite code (retry if collision)
      String inviteCode;
      bool isUnique = false;
      int attempts = 0;

      do {
        inviteCode = _generateInviteCode();

        // Check if code already exists
        final existing = await db.query(
          'trip_invites',
          where: 'invite_code = ?',
          whereArgs: [inviteCode],
          limit: 1,
        );

        isUnique = existing.isEmpty;
        attempts++;

        if (attempts > 10) {
          throw Exception('Failed to generate unique invite code after 10 attempts');
        }
      } while (!isUnique);

      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: expiresInDays));
      final inviteId = _uuid.v4();

      final inviteData = {
        'id': inviteId,
        'trip_id': tripId,
        'invited_by': _currentUserId!,
        'email': email,
        'phone_number': phoneNumber,
        'status': 'pending',
        'invite_code': inviteCode,
        'created_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      };

      await db.insert('trip_invites', inviteData);

      print('✅ Invite created: $inviteCode');

      // Return the created invite
      return InviteModel.fromJson({
        ...inviteData,
        'invitedBy': _currentUserId!,
        'tripId': tripId,
        'phoneNumber': phoneNumber,
        'inviteCode': inviteCode,
        'createdAt': now,
        'expiresAt': expiresAt,
      });
    } catch (e) {
      print('❌ Error creating invite: $e');
      rethrow;
    }
  }

  /// Get invite by code with trip and inviter details
  Future<InviteModel?> getInviteByCode(String inviteCode) async {
    try {
      final db = await _dbHelper.database;

      final results = await db.rawQuery('''
        SELECT
          i.*,
          t.name as trip_name,
          t.destination as trip_destination,
          t.start_date,
          t.end_date,
          p.full_name as inviter_name,
          p.email as inviter_email
        FROM trip_invites i
        INNER JOIN trips t ON i.trip_id = t.id
        INNER JOIN profiles p ON i.invited_by = p.id
        WHERE i.invite_code = ?
      ''', [inviteCode]);

      if (results.isEmpty) return null;

      final data = results.first;

      return InviteModel(
        id: data['id'] as String,
        tripId: data['trip_id'] as String,
        invitedBy: data['invited_by'] as String,
        email: data['email'] as String,
        phoneNumber: data['phone_number'] as String?,
        status: data['status'] as String,
        inviteCode: data['invite_code'] as String,
        createdAt: DateTime.parse(data['created_at'] as String),
        expiresAt: DateTime.parse(data['expires_at'] as String),
        tripName: data['trip_name'] as String?,
        tripDestination: data['trip_destination'] as String?,
        inviterName: data['inviter_name'] as String?,
        inviterEmail: data['inviter_email'] as String?,
      );
    } catch (e) {
      print('❌ Error fetching invite by code: $e');
      rethrow;
    }
  }

  /// Get all invites for a trip
  Future<List<InviteModel>> getTripInvites({
    required String tripId,
    bool includeExpired = false,
  }) async {
    try {
      final db = await _dbHelper.database;

      String whereClause = 'i.trip_id = ?';
      final whereArgs = <Object>[tripId];

      if (!includeExpired) {
        whereClause += ' AND i.expires_at >= ?';
        whereArgs.add(DateTime.now().toIso8601String());
      }

      final results = await db.rawQuery('''
        SELECT
          i.*,
          p.full_name as inviter_name,
          p.email as inviter_email
        FROM trip_invites i
        INNER JOIN profiles p ON i.invited_by = p.id
        WHERE $whereClause
        ORDER BY i.created_at DESC
      ''', whereArgs);

      return results.map((data) => InviteModel(
        id: data['id'] as String,
        tripId: data['trip_id'] as String,
        invitedBy: data['invited_by'] as String,
        email: data['email'] as String,
        phoneNumber: data['phone_number'] as String?,
        status: data['status'] as String,
        inviteCode: data['invite_code'] as String,
        createdAt: DateTime.parse(data['created_at'] as String),
        expiresAt: DateTime.parse(data['expires_at'] as String),
        inviterName: data['inviter_name'] as String?,
        inviterEmail: data['inviter_email'] as String?,
      )).toList();
    } catch (e) {
      print('❌ Error fetching trip invites: $e');
      rethrow;
    }
  }

  /// Get pending invites for an email
  Future<List<InviteModel>> getPendingInvitesForEmail(String email) async {
    try {
      final db = await _dbHelper.database;

      final results = await db.rawQuery('''
        SELECT
          i.*,
          t.name as trip_name,
          t.destination as trip_destination,
          t.start_date,
          t.end_date,
          p.full_name as inviter_name,
          p.email as inviter_email
        FROM trip_invites i
        INNER JOIN trips t ON i.trip_id = t.id
        INNER JOIN profiles p ON i.invited_by = p.id
        WHERE i.email = ?
          AND i.status = 'pending'
          AND i.expires_at >= ?
        ORDER BY i.created_at DESC
      ''', [email, DateTime.now().toIso8601String()]);

      return results.map((data) => InviteModel(
        id: data['id'] as String,
        tripId: data['trip_id'] as String,
        invitedBy: data['invited_by'] as String,
        email: data['email'] as String,
        phoneNumber: data['phone_number'] as String?,
        status: data['status'] as String,
        inviteCode: data['invite_code'] as String,
        createdAt: DateTime.parse(data['created_at'] as String),
        expiresAt: DateTime.parse(data['expires_at'] as String),
        tripName: data['trip_name'] as String?,
        tripDestination: data['trip_destination'] as String?,
        inviterName: data['inviter_name'] as String?,
        inviterEmail: data['inviter_email'] as String?,
      )).toList();
    } catch (e) {
      print('❌ Error fetching pending invites: $e');
      rethrow;
    }
  }

  /// Update invite status
  Future<InviteModel> updateInviteStatus({
    required String inviteId,
    required String status,
  }) async {
    try {
      final db = await _dbHelper.database;

      await db.update(
        'trip_invites',
        {'status': status},
        where: 'id = ?',
        whereArgs: [inviteId],
      );

      print('✅ Invite status updated: $status');

      // Fetch and return updated invite
      final results = await db.query(
        'trip_invites',
        where: 'id = ?',
        whereArgs: [inviteId],
      );

      if (results.isEmpty) {
        throw Exception('Invite not found after update');
      }

      final data = results.first;
      return InviteModel(
        id: data['id'] as String,
        tripId: data['trip_id'] as String,
        invitedBy: data['invited_by'] as String,
        email: data['email'] as String,
        phoneNumber: data['phone_number'] as String?,
        status: data['status'] as String,
        inviteCode: data['invite_code'] as String,
        createdAt: DateTime.parse(data['created_at'] as String),
        expiresAt: DateTime.parse(data['expires_at'] as String),
      );
    } catch (e) {
      print('❌ Error updating invite status: $e');
      rethrow;
    }
  }

  /// Delete an invite
  Future<void> deleteInvite(String inviteId) async {
    try {
      final db = await _dbHelper.database;

      await db.delete(
        'trip_invites',
        where: 'id = ?',
        whereArgs: [inviteId],
      );

      print('✅ Invite deleted: $inviteId');
    } catch (e) {
      print('❌ Error deleting invite: $e');
      rethrow;
    }
  }

  /// Delete expired invites
  Future<void> deleteExpiredInvites({String? tripId}) async {
    try {
      final db = await _dbHelper.database;

      String whereClause = 'expires_at < ?';
      final whereArgs = <Object>[DateTime.now().toIso8601String()];

      if (tripId != null) {
        whereClause += ' AND trip_id = ?';
        whereArgs.add(tripId);
      }

      await db.delete(
        'trip_invites',
        where: whereClause,
        whereArgs: whereArgs,
      );

      print('✅ Expired invites deleted');
    } catch (e) {
      print('❌ Error deleting expired invites: $e');
      rethrow;
    }
  }

  /// Extend invite expiration (for resend)
  Future<InviteModel> extendInviteExpiration({
    required String inviteId,
    int additionalDays = 7,
  }) async {
    try {
      final db = await _dbHelper.database;
      final newExpiresAt = DateTime.now().add(Duration(days: additionalDays));

      await db.update(
        'trip_invites',
        {'expires_at': newExpiresAt.toIso8601String()},
        where: 'id = ?',
        whereArgs: [inviteId],
      );

      print('✅ Invite expiration extended');

      // Fetch and return updated invite
      final results = await db.query(
        'trip_invites',
        where: 'id = ?',
        whereArgs: [inviteId],
      );

      if (results.isEmpty) {
        throw Exception('Invite not found after update');
      }

      final data = results.first;
      return InviteModel(
        id: data['id'] as String,
        tripId: data['trip_id'] as String,
        invitedBy: data['invited_by'] as String,
        email: data['email'] as String,
        phoneNumber: data['phone_number'] as String?,
        status: data['status'] as String,
        inviteCode: data['invite_code'] as String,
        createdAt: DateTime.parse(data['created_at'] as String),
        expiresAt: DateTime.parse(data['expires_at'] as String),
      );
    } catch (e) {
      print('❌ Error extending invite expiration: $e');
      rethrow;
    }
  }

  /// Get invites sent by a user
  Future<List<InviteModel>> getInvitesSentByUser(String userId) async {
    try {
      final db = await _dbHelper.database;

      final results = await db.rawQuery('''
        SELECT
          i.*,
          t.name as trip_name,
          t.destination as trip_destination
        FROM trip_invites i
        INNER JOIN trips t ON i.trip_id = t.id
        WHERE i.invited_by = ?
        ORDER BY i.created_at DESC
      ''', [userId]);

      return results.map((data) => InviteModel(
        id: data['id'] as String,
        tripId: data['trip_id'] as String,
        invitedBy: data['invited_by'] as String,
        email: data['email'] as String,
        phoneNumber: data['phone_number'] as String?,
        status: data['status'] as String,
        inviteCode: data['invite_code'] as String,
        createdAt: DateTime.parse(data['created_at'] as String),
        expiresAt: DateTime.parse(data['expires_at'] as String),
        tripName: data['trip_name'] as String?,
        tripDestination: data['trip_destination'] as String?,
      )).toList();
    } catch (e) {
      print('❌ Error fetching user invites: $e');
      rethrow;
    }
  }
}
