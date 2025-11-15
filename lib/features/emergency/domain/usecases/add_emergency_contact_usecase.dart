import '../../../../shared/models/emergency_contact_model.dart';
import '../repositories/emergency_repository.dart';

/// Use case for adding an emergency contact
class AddEmergencyContactUseCase {
  final EmergencyRepository _repository;

  AddEmergencyContactUseCase(this._repository);

  Future<EmergencyContactModel> call({
    required String name,
    required String phoneNumber,
    String? email,
    required String relationship,
    bool isPrimary = false,
  }) async {
    // Validate inputs
    if (name.trim().isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }

    if (phoneNumber.trim().isEmpty) {
      throw ArgumentError('Phone number cannot be empty');
    }

    // Basic phone number validation (at least 10 digits)
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10) {
      throw ArgumentError('Invalid phone number');
    }

    if (relationship.trim().isEmpty) {
      throw ArgumentError('Relationship cannot be empty');
    }

    // Validate email if provided
    if (email != null && email.trim().isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email.trim())) {
        throw ArgumentError('Invalid email address');
      }
    }

    return await _repository.addEmergencyContact(
      name: name.trim(),
      phoneNumber: phoneNumber.trim(),
      email: email?.trim(),
      relationship: relationship.trim(),
      isPrimary: isPrimary,
    );
  }
}
