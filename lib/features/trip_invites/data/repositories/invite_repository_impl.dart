import '../../domain/entities/invite_entity.dart';
import '../../domain/repositories/invite_repository.dart';
import '../datasources/invite_local_datasource.dart';
import '../../../trips/data/datasources/trip_local_datasource.dart';

/// Implementation of InviteRepository using local SQLite datasource
class InviteRepositoryImpl implements InviteRepository {
  final InviteLocalDataSource _localDataSource;
  final TripLocalDataSource _tripDataSource;

  InviteRepositoryImpl(this._localDataSource, this._tripDataSource);

  @override
  Future<InviteEntity> generateInvite({
    required String tripId,
    required String email,
    String? phoneNumber,
    int expiresInDays = 7,
  }) async {
    try {
      final inviteModel = await _localDataSource.createInvite(
        tripId: tripId,
        email: email,
        phoneNumber: phoneNumber,
        expiresInDays: expiresInDays,
      );

      return inviteModel.toEntity();
    } catch (e) {
      throw Exception('Failed to generate invite: $e');
    }
  }

  @override
  Future<InviteEntity> acceptInvite({
    required String inviteCode,
    required String userId,
  }) async {
    try {
      // Get the invite
      final inviteModel = await _localDataSource.getInviteByCode(inviteCode);

      if (inviteModel == null) {
        throw Exception('Invite not found');
      }

      final invite = inviteModel.toEntity();

      // Check if expired
      if (invite.isExpired) {
        throw Exception('Invite has expired');
      }

      // Check if already accepted or rejected
      if (invite.status != 'pending') {
        throw Exception('Invite is no longer valid (${invite.status})');
      }

      // Add user as trip member
      await _tripDataSource.addMember(
        tripId: invite.tripId,
        userId: userId,
        role: 'member',
      );

      // Update invite status to accepted
      final updatedInvite = await _localDataSource.updateInviteStatus(
        inviteId: invite.id,
        status: 'accepted',
      );

      return updatedInvite.toEntity();
    } catch (e) {
      throw Exception('Failed to accept invite: $e');
    }
  }

  @override
  Future<void> rejectInvite({
    required String inviteCode,
    required String userId,
  }) async {
    try {
      // Get the invite
      final inviteModel = await _localDataSource.getInviteByCode(inviteCode);

      if (inviteModel == null) {
        throw Exception('Invite not found');
      }

      final invite = inviteModel.toEntity();

      // Check if already accepted or rejected
      if (invite.status != 'pending') {
        throw Exception('Invite is no longer valid (${invite.status})');
      }

      // Update invite status to rejected
      await _localDataSource.updateInviteStatus(
        inviteId: invite.id,
        status: 'rejected',
      );
    } catch (e) {
      throw Exception('Failed to reject invite: $e');
    }
  }

  @override
  Future<void> revokeInvite({
    required String inviteId,
    required String userId,
  }) async {
    try {
      // TODO: Add permission check - only inviter or trip admin can revoke

      // Delete the invite
      await _localDataSource.deleteInvite(inviteId);
    } catch (e) {
      throw Exception('Failed to revoke invite: $e');
    }
  }

  @override
  Future<List<InviteEntity>> getTripInvites({
    required String tripId,
    bool includeExpired = false,
  }) async {
    try {
      final inviteModels = await _localDataSource.getTripInvites(
        tripId: tripId,
        includeExpired: includeExpired,
      );

      return inviteModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get trip invites: $e');
    }
  }

  @override
  Future<InviteEntity?> getInviteByCode(String inviteCode) async {
    try {
      final inviteModel = await _localDataSource.getInviteByCode(inviteCode);
      return inviteModel?.toEntity();
    } catch (e) {
      throw Exception('Failed to get invite: $e');
    }
  }

  @override
  Future<List<InviteEntity>> getInvitesSentByUser(String userId) async {
    try {
      final inviteModels = await _localDataSource.getInvitesSentByUser(userId);
      return inviteModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get user invites: $e');
    }
  }

  @override
  Future<List<InviteEntity>> getPendingInvitesForEmail(String email) async {
    try {
      final inviteModels = await _localDataSource.getPendingInvitesForEmail(email);
      return inviteModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get pending invites: $e');
    }
  }

  @override
  Future<InviteEntity> resendInvite(String inviteId) async {
    try {
      // Extend expiration by 7 days
      final updatedInvite = await _localDataSource.extendInviteExpiration(
        inviteId: inviteId,
        additionalDays: 7,
      );

      // TODO: Send notification/email again

      return updatedInvite.toEntity();
    } catch (e) {
      throw Exception('Failed to resend invite: $e');
    }
  }

  @override
  Future<void> deleteExpiredInvites({String? tripId}) async {
    try {
      await _localDataSource.deleteExpiredInvites(tripId: tripId);
    } catch (e) {
      throw Exception('Failed to delete expired invites: $e');
    }
  }
}
