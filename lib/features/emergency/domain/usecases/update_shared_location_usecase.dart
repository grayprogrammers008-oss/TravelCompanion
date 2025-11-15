import '../../../../shared/models/location_share_model.dart';
import '../repositories/emergency_repository.dart';

/// Use case for updating shared location in an active session
class UpdateSharedLocationUseCase {
  final EmergencyRepository _repository;

  UpdateSharedLocationUseCase(this._repository);

  Future<LocationShareModel> call({
    required String sessionId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    String? message,
  }) async {
    // Validate session ID
    if (sessionId.trim().isEmpty) {
      throw ArgumentError('Session ID cannot be empty');
    }

    // Validate coordinates
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError('Latitude must be between -90 and 90');
    }

    if (longitude < -180 || longitude > 180) {
      throw ArgumentError('Longitude must be between -180 and 180');
    }

    // Validate optional parameters
    if (accuracy != null && accuracy < 0) {
      throw ArgumentError('Accuracy cannot be negative');
    }

    if (speed != null && speed < 0) {
      throw ArgumentError('Speed cannot be negative');
    }

    if (heading != null && (heading < 0 || heading >= 360)) {
      throw ArgumentError('Heading must be between 0 and 360 degrees');
    }

    return await _repository.updateSharedLocation(
      sessionId: sessionId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      altitude: altitude,
      speed: speed,
      heading: heading,
      message: message?.trim(),
    );
  }
}
