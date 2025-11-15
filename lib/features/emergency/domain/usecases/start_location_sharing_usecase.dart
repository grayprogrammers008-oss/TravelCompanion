import '../../../../shared/models/location_share_model.dart';
import '../repositories/emergency_repository.dart';

/// Use case for starting location sharing with emergency contacts
class StartLocationSharingUseCase {
  final EmergencyRepository _repository;

  StartLocationSharingUseCase(this._repository);

  Future<LocationShareModel> call({
    required List<String> contactIds,
    String? tripId,
    Duration? duration,
    String? message,
  }) async {
    // Validate inputs
    if (contactIds.isEmpty) {
      throw ArgumentError('Must share location with at least one contact');
    }

    // Validate duration if provided
    if (duration != null) {
      if (duration.inMinutes < 1) {
        throw ArgumentError('Duration must be at least 1 minute');
      }
      if (duration.inHours > 24) {
        throw ArgumentError('Duration cannot exceed 24 hours');
      }
    }

    return await _repository.startLocationSharing(
      contactIds: contactIds,
      tripId: tripId,
      duration: duration,
      message: message?.trim(),
    );
  }
}
