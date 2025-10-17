import '../entities/invite_entity.dart';

/// Repository interface for trip invite operations
///
/// Defines all the operations that can be performed on trip invites
abstract class InviteRepository {
  /// Generate a new invite for a trip
  ///
  /// Creates a unique invite code and sends invitation
  /// [tripId] - ID of the trip to invite to
  /// [email] - Email address of the invitee
  /// [phoneNumber] - Optional phone number
  /// [expiresInDays] - Number of days until invite expires (default: 7)
  ///
  /// Returns the created invite entity
  Future<InviteEntity> generateInvite({
    required String tripId,
    required String email,
    String? phoneNumber,
    int expiresInDays = 7,
  });

  /// Accept an invite using invite code
  ///
  /// Validates the invite code, checks expiration, and adds user to trip
  /// [inviteCode] - The unique invite code
  /// [userId] - ID of the user accepting the invite
  ///
  /// Returns the updated invite entity
  Future<InviteEntity> acceptInvite({
    required String inviteCode,
    required String userId,
  });

  /// Reject an invite
  ///
  /// [inviteCode] - The unique invite code
  /// [userId] - ID of the user rejecting the invite
  Future<void> rejectInvite({
    required String inviteCode,
    required String userId,
  });

  /// Revoke an invite (cancel it)
  ///
  /// Can only be done by the inviter or trip admin
  /// [inviteId] - ID of the invite to revoke
  /// [userId] - ID of the user revoking (for permission check)
  Future<void> revokeInvite({
    required String inviteId,
    required String userId,
  });

  /// Get all invites for a trip
  ///
  /// [tripId] - ID of the trip
  /// [includeExpired] - Whether to include expired invites (default: false)
  Future<List<InviteEntity>> getTripInvites({
    required String tripId,
    bool includeExpired = false,
  });

  /// Get an invite by invite code
  ///
  /// [inviteCode] - The unique invite code
  /// Returns null if not found
  Future<InviteEntity?> getInviteByCode(String inviteCode);

  /// Get all invites sent by a user
  ///
  /// [userId] - ID of the user who sent the invites
  Future<List<InviteEntity>> getInvitesSentByUser(String userId);

  /// Get all pending invites for an email
  ///
  /// Used to show user any pending invites when they log in
  /// [email] - Email address to check
  Future<List<InviteEntity>> getPendingInvitesForEmail(String email);

  /// Resend an invite
  ///
  /// Extends expiration and sends notification again
  /// [inviteId] - ID of the invite to resend
  Future<InviteEntity> resendInvite(String inviteId);

  /// Delete expired invites (cleanup)
  ///
  /// [tripId] - Optional trip ID to clean up specific trip
  Future<void> deleteExpiredInvites({String? tripId});
}
