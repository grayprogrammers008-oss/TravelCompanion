import '../../domain/entities/invite_entity.dart';
import '../../domain/repositories/invite_repository.dart';
import '../datasources/invite_remote_datasource.dart';

/// Implementation of InviteRepository using Supabase remote datasource
class InviteRepositoryImpl implements InviteRepository {
  final InviteRemoteDataSource _remoteDataSource;

  InviteRepositoryImpl(this._remoteDataSource);

  @override
  Future<InviteEntity> generateInvite({
    required String tripId,
    required String email,
    String? phoneNumber,
    int expiresInDays = 7,
  }) async {
    try {
      final inviteModel = await _remoteDataSource.createInvite(
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
      final inviteModel = await _remoteDataSource.acceptInvite(
        inviteCode: inviteCode,
        userId: userId,
      );

      return inviteModel.toEntity();
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
      await _remoteDataSource.rejectInvite(
        inviteCode: inviteCode,
        userId: userId,
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
      await _remoteDataSource.revokeInvite(
        inviteId: inviteId,
        userId: userId,
      );
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
      final inviteModels = await _remoteDataSource.getTripInvites(
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
      final inviteModel = await _remoteDataSource.getInviteByCode(inviteCode);
      return inviteModel?.toEntity();
    } catch (e) {
      throw Exception('Failed to get invite: $e');
    }
  }

  @override
  Future<List<InviteEntity>> getInvitesSentByUser(String userId) async {
    try {
      final inviteModels = await _remoteDataSource.getInvitesSentByUser(userId);
      return inviteModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get user invites: $e');
    }
  }

  @override
  Future<List<InviteEntity>> getPendingInvitesForEmail(String email) async {
    try {
      final inviteModels = await _remoteDataSource.getPendingInvitesForEmail(email);
      return inviteModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get pending invites: $e');
    }
  }

  @override
  Future<InviteEntity> resendInvite(String inviteId) async {
    try {
      final updatedInvite = await _remoteDataSource.resendInvite(inviteId);
      return updatedInvite.toEntity();
    } catch (e) {
      throw Exception('Failed to resend invite: $e');
    }
  }

  @override
  Future<void> deleteExpiredInvites({String? tripId}) async {
    try {
      await _remoteDataSource.deleteExpiredInvites(tripId: tripId);
    } catch (e) {
      throw Exception('Failed to delete expired invites: $e');
    }
  }
}
