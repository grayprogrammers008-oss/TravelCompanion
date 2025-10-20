import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/invite_model.dart';

/// Remote data source for trip invites using Supabase
class InviteRemoteDataSource {
  final SupabaseClient _supabase;
  final Uuid _uuid = const Uuid();

  InviteRemoteDataSource(this._supabase);

  /// Create a new invite
  Future<InviteModel> createInvite({
    required String tripId,
    required String email,
    String? phoneNumber,
    int expiresInDays = 7,
  }) async {
    try {
      final invitedBy = _supabase.auth.currentUser?.id;
      if (invitedBy == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final inviteCode = _generateInviteCode();

      final invite = InviteModel(
        id: _uuid.v4(),
        tripId: tripId,
        invitedBy: invitedBy,
        email: email,
        phoneNumber: phoneNumber,
        status: 'pending',
        inviteCode: inviteCode,
        createdAt: now,
        expiresAt: now.add(Duration(days: expiresInDays)),
      );

      final response = await _supabase
          .from('trip_invites')
          .insert(invite.toJson())
          .select()
          .single();

      return InviteModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create invite: $e');
    }
  }

  /// Accept an invite
  Future<InviteModel> acceptInvite({
    required String inviteCode,
    required String userId,
  }) async {
    try {
      // First, get the invite
      final inviteResponse = await _supabase
          .from('trip_invites')
          .select()
          .eq('invite_code', inviteCode)
          .single();

      final invite = InviteModel.fromJson(inviteResponse);

      // Check if expired
      if (invite.expiresAt.isBefore(DateTime.now())) {
        throw Exception('Invite has expired');
      }

      // Check if already used
      if (invite.status != 'pending') {
        throw Exception('Invite has already been used');
      }

      // Update invite status
      await _supabase
          .from('trip_invites')
          .update({'status': 'accepted'})
          .eq('id', invite.id);

      // Add user to trip_members
      await _supabase.from('trip_members').insert({
        'id': _uuid.v4(),
        'trip_id': invite.tripId,
        'user_id': userId,
        'role': 'member',
        'joined_at': DateTime.now().toIso8601String(),
      });

      // Get updated invite
      final updated = await _supabase
          .from('trip_invites')
          .select()
          .eq('id', invite.id)
          .single();

      return InviteModel.fromJson(updated);
    } catch (e) {
      throw Exception('Failed to accept invite: $e');
    }
  }

  /// Reject an invite
  Future<void> rejectInvite({
    required String inviteCode,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('trip_invites')
          .update({'status': 'rejected'})
          .eq('invite_code', inviteCode);
    } catch (e) {
      throw Exception('Failed to reject invite: $e');
    }
  }

  /// Revoke an invite (only by inviter or trip creator)
  Future<void> revokeInvite({
    required String inviteId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('trip_invites')
          .update({'status': 'revoked'})
          .eq('id', inviteId);
    } catch (e) {
      throw Exception('Failed to revoke invite: $e');
    }
  }

  /// Get all invites for a trip
  Future<List<InviteModel>> getTripInvites({
    required String tripId,
    bool includeExpired = false,
  }) async {
    try {
      dynamic query = _supabase
          .from('trip_invites')
          .select()
          .eq('trip_id', tripId);

      if (!includeExpired) {
        query = query.gte('expires_at', DateTime.now().toIso8601String());
      }

      query = query.order('created_at', ascending: false);

      final response = await query;
      return (response as List)
          .map((json) => InviteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get trip invites: $e');
    }
  }

  /// Get invite by code
  Future<InviteModel?> getInviteByCode(String inviteCode) async {
    try {
      final response = await _supabase
          .from('trip_invites')
          .select()
          .eq('invite_code', inviteCode)
          .maybeSingle();

      if (response == null) return null;
      return InviteModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get invite: $e');
    }
  }

  /// Get invites sent by a user
  Future<List<InviteModel>> getInvitesSentByUser(String userId) async {
    try {
      final response = await _supabase
          .from('trip_invites')
          .select()
          .eq('invited_by', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => InviteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user invites: $e');
    }
  }

  /// Get pending invites for an email
  Future<List<InviteModel>> getPendingInvitesForEmail(String email) async {
    try {
      final response = await _supabase
          .from('trip_invites')
          .select()
          .eq('email', email)
          .eq('status', 'pending')
          .gte('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => InviteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending invites: $e');
    }
  }

  /// Resend an invite (updates created_at and extends expiry)
  Future<InviteModel> resendInvite(String inviteId) async {
    try {
      final now = DateTime.now();
      final response = await _supabase
          .from('trip_invites')
          .update({
            'created_at': now.toIso8601String(),
            'expires_at': now.add(const Duration(days: 7)).toIso8601String(),
          })
          .eq('id', inviteId)
          .select()
          .single();

      return InviteModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to resend invite: $e');
    }
  }

  /// Delete expired invites
  Future<void> deleteExpiredInvites({String? tripId}) async {
    try {
      var query = _supabase
          .from('trip_invites')
          .delete()
          .lt('expires_at', DateTime.now().toIso8601String());

      if (tripId != null) {
        query = query.eq('trip_id', tripId);
      }

      await query;
    } catch (e) {
      throw Exception('Failed to delete expired invites: $e');
    }
  }

  /// Generate a unique invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var code = '';
    var tempRandom = random;

    for (int i = 0; i < 8; i++) {
      code += chars[tempRandom % chars.length];
      tempRandom ~/= chars.length;
    }

    return code;
  }
}
