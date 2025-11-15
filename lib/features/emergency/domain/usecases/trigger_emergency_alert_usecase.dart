import '../../../../shared/models/emergency_alert_model.dart';
import '../repositories/emergency_repository.dart';

/// Use case for triggering an emergency alert/SOS
class TriggerEmergencyAlertUseCase {
  final EmergencyRepository _repository;

  TriggerEmergencyAlertUseCase(this._repository);

  Future<EmergencyAlertModel> call({
    required EmergencyAlertType type,
    String? tripId,
    String? message,
    double? latitude,
    double? longitude,
    List<String>? contactIds,
  }) async {
    // Validate location coordinates if provided
    if ((latitude != null && longitude == null) || (latitude == null && longitude != null)) {
      throw ArgumentError('Both latitude and longitude must be provided together');
    }

    if (latitude != null) {
      if (latitude < -90 || latitude > 90) {
        throw ArgumentError('Latitude must be between -90 and 90');
      }
    }

    if (longitude != null) {
      if (longitude < -180 || longitude > 180) {
        throw ArgumentError('Longitude must be between -180 and 180');
      }
    }

    return await _repository.triggerEmergencyAlert(
      type: type,
      tripId: tripId,
      message: message?.trim(),
      latitude: latitude,
      longitude: longitude,
      contactIds: contactIds,
    );
  }
}
