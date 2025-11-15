import '../../../../shared/models/emergency_contact_model.dart';
import '../repositories/emergency_repository.dart';

/// Use case for getting all emergency contacts
class GetEmergencyContactsUseCase {
  final EmergencyRepository _repository;

  GetEmergencyContactsUseCase(this._repository);

  Future<List<EmergencyContactModel>> call() async {
    final contacts = await _repository.getEmergencyContacts();

    // Sort contacts: primary first, then by name
    contacts.sort((a, b) {
      if (a.isPrimary && !b.isPrimary) return -1;
      if (!a.isPrimary && b.isPrimary) return 1;
      return a.name.compareTo(b.name);
    });

    return contacts;
  }
}
