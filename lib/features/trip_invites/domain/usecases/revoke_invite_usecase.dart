import '../repositories/invite_repository.dart';

/// Use case for revoking (canceling) trip invitations
class RevokeInviteUseCase {
  final InviteRepository _repository;

  RevokeInviteUseCase(this._repository);

  /// Revoke an invite
  ///
  /// Only the person who created the invite or trip admin can revoke
  ///
  /// Parameters:
  /// - [inviteId]: ID of the invite to revoke
  /// - [userId]: ID of the user revoking (for permission check)
  ///
  /// Throws:
  /// - Exception if invite ID is invalid
  /// - Exception if user doesn't have permission
  Future<void> call({
    required String inviteId,
    required String userId,
  }) async {
    // Validate inputs
    if (inviteId.isEmpty) {
      throw Exception('Invite ID cannot be empty');
    }

    if (userId.isEmpty) {
      throw Exception('User ID cannot be empty');
    }

    // Revoke the invite
    // Permission check is done in the repository
    await _repository.revokeInvite(
      inviteId: inviteId,
      userId: userId,
    );
  }
}
