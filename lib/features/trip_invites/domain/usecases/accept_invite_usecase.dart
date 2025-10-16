import '../entities/invite_entity.dart';
import '../repositories/invite_repository.dart';

/// Use case for accepting trip invitations
class AcceptInviteUseCase {
  final InviteRepository _repository;

  AcceptInviteUseCase(this._repository);

  /// Accept an invite and join the trip
  ///
  /// Validates the invite code, checks expiration, and adds user to trip
  ///
  /// Parameters:
  /// - [inviteCode]: The unique 6-character invite code
  /// - [userId]: ID of the user accepting the invite
  ///
  /// Throws:
  /// - Exception if invite code is invalid
  /// - Exception if invite is expired
  /// - Exception if invite was already accepted/rejected
  /// - Exception if user is already a member
  Future<InviteEntity> call({
    required String inviteCode,
    required String userId,
  }) async {
    // Validate inputs
    if (inviteCode.isEmpty) {
      throw Exception('Invite code cannot be empty');
    }

    if (inviteCode.length != 6) {
      throw Exception('Invalid invite code format');
    }

    if (userId.isEmpty) {
      throw Exception('User ID cannot be empty');
    }

    // Convert to uppercase for consistency
    final code = inviteCode.toUpperCase();

    // Get the invite first to validate
    final invite = await _repository.getInviteByCode(code);

    if (invite == null) {
      throw Exception('Invite not found. Please check the code and try again.');
    }

    // Check if expired
    if (invite.isExpired) {
      throw Exception('This invite has expired. Please request a new one.');
    }

    // Check if already used
    if (invite.status != 'pending') {
      if (invite.status == 'accepted') {
        throw Exception('This invite has already been accepted.');
      } else {
        throw Exception('This invite is no longer valid.');
      }
    }

    // Accept the invite
    return await _repository.acceptInvite(
      inviteCode: code,
      userId: userId,
    );
  }
}
