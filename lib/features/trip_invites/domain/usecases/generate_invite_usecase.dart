import '../entities/invite_entity.dart';
import '../repositories/invite_repository.dart';

/// Use case for generating trip invitations
class GenerateInviteUseCase {
  final InviteRepository _repository;

  GenerateInviteUseCase(this._repository);

  /// Generate a new invite for a trip
  ///
  /// Validates input and creates a unique invite code
  ///
  /// Parameters:
  /// - [tripId]: ID of the trip to invite to
  /// - [email]: Email address of the person to invite
  /// - [phoneNumber]: Optional phone number
  /// - [expiresInDays]: Number of days until invite expires (default: 7)
  ///
  /// Throws:
  /// - Exception if email is invalid
  /// - Exception if tripId is empty
  Future<InviteEntity> call({
    required String tripId,
    required String email,
    String? phoneNumber,
    int expiresInDays = 7,
  }) async {
    // Validate inputs
    if (tripId.isEmpty) {
      throw Exception('Trip ID cannot be empty');
    }

    if (email.isEmpty) {
      throw Exception('Email cannot be empty');
    }

    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      throw Exception('Invalid email format');
    }

    if (expiresInDays < 1) {
      throw Exception('Expiration must be at least 1 day');
    }

    if (expiresInDays > 365) {
      throw Exception('Expiration cannot exceed 365 days');
    }

    // Generate the invite
    return await _repository.generateInvite(
      tripId: tripId,
      email: email,
      phoneNumber: phoneNumber,
      expiresInDays: expiresInDays,
    );
  }
}
