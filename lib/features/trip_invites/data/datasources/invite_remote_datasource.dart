import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/invite_model.dart';
import '../../../../core/services/email_service.dart';

/// Remote data source for trip invites using Supabase
class InviteRemoteDataSource {
  final SupabaseClient _supabase;
  final Uuid _uuid = const Uuid();
  final EmailService _emailService = EmailService();

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

      // Insert invite into database (only core fields, not extended join fields)
      final response = await _supabase
          .from('trip_invites')
          .insert({
            'id': invite.id,
            'trip_id': invite.tripId,
            'invited_by': invite.invitedBy,
            'email': invite.email,
            'phone_number': invite.phoneNumber,
            'status': invite.status,
            'invite_code': invite.inviteCode,
            'created_at': invite.createdAt.toIso8601String(),
            'expires_at': invite.expiresAt.toIso8601String(),
          })
          .select()
          .single();

      final createdInvite = InviteModel.fromJson(response);

      // Get trip details for email
      final tripResponse = await _supabase
          .from('trips')
          .select('name, destination, start_date, end_date')
          .eq('id', tripId)
          .single();

      // Get inviter details
      final inviterResponse = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', invitedBy)
          .single();

      final tripName = tripResponse['name'] as String? ?? 'Trip';
      final tripDestination = tripResponse['destination'] as String?;
      final tripStartDate = tripResponse['start_date'] as String?;
      final tripEndDate = tripResponse['end_date'] as String?;
      final inviterName = inviterResponse['full_name'] as String? ?? 'Someone';

      // Extract recipient name from email (before @)
      final recipientName = email.split('@').first.replaceAll('.', ' ').replaceAll('_', ' ');
      final capitalizedName = recipientName.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');

      // Send email invitation
      try {
        final emailSent = await _emailService.sendTripInvite(
          toEmail: email,
          toName: capitalizedName,
          tripName: tripName,
          inviterName: inviterName,
          inviteCode: inviteCode,
          tripDestination: tripDestination,
          tripStartDate: tripStartDate != null ? _formatDate(tripStartDate) : null,
          tripEndDate: tripEndDate != null ? _formatDate(tripEndDate) : null,
        );

        if (!emailSent) {
          if (kDebugMode) {
            debugPrint('⚠️ Warning: Failed to send email to $email for invite $inviteCode');
          }
          // Don't throw error - invite is created, email is optional
        } else {
          if (kDebugMode) {
            debugPrint('✅ Invitation email sent to $email for trip $tripName');
          }
        }
      } catch (emailError) {
        if (kDebugMode) {
          debugPrint('⚠️ Email sending error: $emailError');
        }
        // Don't throw error - invite is created, email is optional
      }

      return createdInvite;
    } catch (e) {
      throw Exception('Failed to create invite: $e');
    }
  }

  /// Format ISO date string to readable format
  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return isoDate;
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
