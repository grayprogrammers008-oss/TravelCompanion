import '../entities/invite_entity.dart';
import '../repositories/invite_repository.dart';

/// Use case for getting all invites for a trip
class GetTripInvitesUseCase {
  final InviteRepository _repository;

  GetTripInvitesUseCase(this._repository);

  /// Get all invites for a trip
  ///
  /// Parameters:
  /// - [tripId]: ID of the trip
  /// - [includeExpired]: Whether to include expired invites (default: false)
  Future<List<InviteEntity>> call({
    required String tripId,
    bool includeExpired = false,
  }) async {
    if (tripId.isEmpty) {
      throw Exception('Trip ID cannot be empty');
    }

    return await _repository.getTripInvites(
      tripId: tripId,
      includeExpired: includeExpired,
    );
  }
}
