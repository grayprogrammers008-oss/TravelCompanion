import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for updating user profile
class UpdateProfileUseCase {
  final AuthRepository _repository;

  UpdateProfileUseCase(this._repository);

  /// Execute profile update
  ///
  /// Parameters:
  /// - [fullName]: Optional new full name
  /// - [phoneNumber]: Optional new phone number
  /// - [avatarUrl]: Optional new avatar URL
  /// - [bio]: Optional bio/description
  ///
  /// Returns updated [UserEntity]
  ///
  /// Throws [Exception] if update fails
  Future<UserEntity> call({
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
  }) async {
    // Validate inputs
    if (fullName != null && fullName.trim().isEmpty) {
      throw Exception('Full name cannot be empty');
    }

    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      // Basic phone number validation (10-15 digits)
      final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
      if (!phoneRegex.hasMatch(phoneNumber.replaceAll(RegExp(r'[\s-]'), ''))) {
        throw Exception('Invalid phone number format');
      }
    }

    if (bio != null && bio.length > 500) {
      throw Exception('Bio must be 500 characters or less');
    }

    return await _repository.updateProfile(
      fullName: fullName,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
      bio: bio,
    );
  }
}
