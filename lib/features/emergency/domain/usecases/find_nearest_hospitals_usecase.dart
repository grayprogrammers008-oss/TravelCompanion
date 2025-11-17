import '../../../../shared/models/hospital_model.dart';
import '../repositories/emergency_repository.dart';

/// Use case for finding nearest hospitals to a given location
class FindNearestHospitalsUseCase {
  final EmergencyRepository _repository;

  FindNearestHospitalsUseCase(this._repository);

  Future<List<HospitalModel>> call({
    required double latitude,
    required double longitude,
    double maxDistanceKm = 50.0,
    int limit = 10,
    bool onlyEmergency = true,
    bool only24_7 = false,
  }) async {
    // Validate coordinates
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError('Latitude must be between -90 and 90');
    }

    if (longitude < -180 || longitude > 180) {
      throw ArgumentError('Longitude must be between -180 and 180');
    }

    if (maxDistanceKm <= 0) {
      throw ArgumentError('Max distance must be greater than 0');
    }

    if (limit <= 0) {
      throw ArgumentError('Limit must be greater than 0');
    }

    final hospitals = await _repository.findNearestHospitals(
      latitude: latitude,
      longitude: longitude,
      maxDistanceKm: maxDistanceKm,
      limit: limit,
      onlyEmergency: onlyEmergency,
      only24_7: only24_7,
    );

    // Sort by emergency priority score (distance + other factors)
    hospitals.sort((a, b) =>
      b.emergencyPriorityScore.compareTo(a.emergencyPriorityScore)
    );

    return hospitals;
  }
}
