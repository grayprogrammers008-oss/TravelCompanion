import '../../../../shared/models/emergency_contact_model.dart';
import '../../../../shared/models/emergency_alert_model.dart';
import '../../../../shared/models/location_share_model.dart';
import '../../../../shared/models/hospital_model.dart';
import '../../../../shared/models/emergency_number_model.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../datasources/emergency_remote_datasource.dart';

/// Implementation of emergency repository using Supabase as the data source
class EmergencyRepositoryImpl implements EmergencyRepository {
  final EmergencyRemoteDataSource _remoteDataSource;
  final LocationService _locationService;

  EmergencyRepositoryImpl(this._remoteDataSource, this._locationService);

  // ============================================
  // Emergency Numbers
  // ============================================

  @override
  Future<List<EmergencyNumberModel>> getEmergencyNumbers({
    String country = 'IN',
  }) async {
    try {
      return await _remoteDataSource.getEmergencyNumbers(country: country);
    } catch (e) {
      throw Exception('Failed to get emergency numbers: $e');
    }
  }

  @override
  Future<List<EmergencyNumberModel>> getEmergencyNumbersByType({
    required EmergencyServiceType serviceType,
    String country = 'IN',
  }) async {
    try {
      return await _remoteDataSource.getEmergencyNumbersByType(
        serviceType: serviceType,
        country: country,
      );
    } catch (e) {
      throw Exception('Failed to get emergency numbers by type: $e');
    }
  }

  // ============================================
  // Emergency Contacts
  // ============================================

  @override
  Future<List<EmergencyContactModel>> getEmergencyContacts() async {
    try {
      return await _remoteDataSource.getEmergencyContacts();
    } catch (e) {
      throw Exception('Failed to get emergency contacts: $e');
    }
  }

  @override
  Future<EmergencyContactModel?> getEmergencyContactById(
      String contactId) async {
    try {
      return await _remoteDataSource.getEmergencyContactById(contactId);
    } catch (e) {
      throw Exception('Failed to get emergency contact: $e');
    }
  }

  @override
  Future<EmergencyContactModel> addEmergencyContact({
    required String name,
    required String phoneNumber,
    String? email,
    required String relationship,
    bool isPrimary = false,
  }) async {
    try {
      return await _remoteDataSource.addEmergencyContact(
        name: name,
        phoneNumber: phoneNumber,
        email: email,
        relationship: relationship,
        isPrimary: isPrimary,
      );
    } catch (e) {
      throw Exception('Failed to add emergency contact: $e');
    }
  }

  @override
  Future<EmergencyContactModel> updateEmergencyContact({
    required String contactId,
    String? name,
    String? phoneNumber,
    String? email,
    String? relationship,
    bool? isPrimary,
  }) async {
    try {
      return await _remoteDataSource.updateEmergencyContact(
        contactId: contactId,
        name: name,
        phoneNumber: phoneNumber,
        email: email,
        relationship: relationship,
        isPrimary: isPrimary,
      );
    } catch (e) {
      throw Exception('Failed to update emergency contact: $e');
    }
  }

  @override
  Future<void> deleteEmergencyContact(String contactId) async {
    try {
      await _remoteDataSource.deleteEmergencyContact(contactId);
    } catch (e) {
      throw Exception('Failed to delete emergency contact: $e');
    }
  }

  @override
  Future<void> setPrimaryContact(String contactId) async {
    try {
      await _remoteDataSource.setPrimaryContact(contactId);
    } catch (e) {
      throw Exception('Failed to set primary contact: $e');
    }
  }

  // ============================================
  // Location Sharing
  // ============================================

  @override
  Future<LocationShareModel> startLocationSharing({
    required List<String> contactIds,
    String? tripId,
    Duration? duration,
    String? message,
  }) async {
    try {
      // Get current location using location service
      final coordinates = await _locationService.getCurrentCoordinates();
      final double latitude = coordinates?['latitude'] ?? 0.0;
      final double longitude = coordinates?['longitude'] ?? 0.0;

      return await _remoteDataSource.startLocationSharing(
        contactIds: contactIds,
        tripId: tripId,
        duration: duration,
        message: message,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      throw Exception('Failed to start location sharing: $e');
    }
  }

  @override
  Future<LocationShareModel> updateSharedLocation({
    required String sessionId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    String? message,
  }) async {
    try {
      return await _remoteDataSource.updateSharedLocation(
        sessionId: sessionId,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        altitude: altitude,
        speed: speed,
        heading: heading,
        message: message,
      );
    } catch (e) {
      throw Exception('Failed to update shared location: $e');
    }
  }

  @override
  Future<void> pauseLocationSharing(String sessionId) async {
    try {
      await _remoteDataSource.pauseLocationSharing(sessionId);
    } catch (e) {
      throw Exception('Failed to pause location sharing: $e');
    }
  }

  @override
  Future<void> resumeLocationSharing(String sessionId) async {
    try {
      await _remoteDataSource.resumeLocationSharing(sessionId);
    } catch (e) {
      throw Exception('Failed to resume location sharing: $e');
    }
  }

  @override
  Future<void> stopLocationSharing(String sessionId) async {
    try {
      await _remoteDataSource.stopLocationSharing(sessionId);
    } catch (e) {
      throw Exception('Failed to stop location sharing: $e');
    }
  }

  @override
  Future<LocationShareModel?> getActiveLocationShare() async {
    try {
      return await _remoteDataSource.getActiveLocationShare();
    } catch (e) {
      throw Exception('Failed to get active location share: $e');
    }
  }

  @override
  Stream<LocationShareModel> watchLocationShare(String sessionId) {
    return _remoteDataSource.watchLocationShare(sessionId).handleError((error) {
      throw Exception('Failed to watch location share: $error');
    });
  }

  @override
  Future<List<LocationShareModel>> getSharedLocations() async {
    try {
      return await _remoteDataSource.getSharedLocations();
    } catch (e) {
      throw Exception('Failed to get shared locations: $e');
    }
  }

  // ============================================
  // Emergency Alerts/SOS
  // ============================================

  @override
  Future<EmergencyAlertModel> triggerEmergencyAlert({
    required EmergencyAlertType type,
    String? tripId,
    String? message,
    double? latitude,
    double? longitude,
    List<String>? contactIds,
  }) async {
    try {
      return await _remoteDataSource.triggerEmergencyAlert(
        type: type,
        tripId: tripId,
        message: message,
        latitude: latitude,
        longitude: longitude,
        contactIds: contactIds,
      );
    } catch (e) {
      throw Exception('Failed to trigger emergency alert: $e');
    }
  }

  @override
  Future<EmergencyAlertModel> acknowledgeAlert(String alertId) async {
    try {
      return await _remoteDataSource.acknowledgeAlert(alertId);
    } catch (e) {
      throw Exception('Failed to acknowledge alert: $e');
    }
  }

  @override
  Future<EmergencyAlertModel> resolveAlert({
    required String alertId,
    String? resolution,
  }) async {
    try {
      return await _remoteDataSource.resolveAlert(
        alertId: alertId,
        resolution: resolution,
      );
    } catch (e) {
      throw Exception('Failed to resolve alert: $e');
    }
  }

  @override
  Future<EmergencyAlertModel> cancelAlert(String alertId) async {
    try {
      return await _remoteDataSource.cancelAlert(alertId);
    } catch (e) {
      throw Exception('Failed to cancel alert: $e');
    }
  }

  @override
  Future<EmergencyAlertModel?> getAlertById(String alertId) async {
    try {
      return await _remoteDataSource.getAlertById(alertId);
    } catch (e) {
      throw Exception('Failed to get alert: $e');
    }
  }

  @override
  Future<List<EmergencyAlertModel>> getUserAlerts({
    EmergencyAlertStatus? status,
    DateTime? since,
  }) async {
    try {
      return await _remoteDataSource.getUserAlerts(
        status: status,
        since: since,
      );
    } catch (e) {
      throw Exception('Failed to get user alerts: $e');
    }
  }

  @override
  Stream<List<EmergencyAlertModel>> watchActiveAlerts() {
    return _remoteDataSource.watchActiveAlerts().handleError((error) {
      throw Exception('Failed to watch active alerts: $error');
    });
  }

  @override
  Stream<List<EmergencyAlertModel>> watchReceivedAlerts() {
    return _remoteDataSource.watchReceivedAlerts().handleError((error) {
      throw Exception('Failed to watch received alerts: $error');
    });
  }

  // ============================================
  // Hospital/Medical Emergency Services
  // ============================================

  @override
  Future<List<HospitalModel>> findNearestHospitals({
    required double latitude,
    required double longitude,
    double maxDistanceKm = 50.0,
    int limit = 10,
    bool onlyEmergency = true,
    bool only24_7 = false,
  }) async {
    try {
      return await _remoteDataSource.findNearestHospitals(
        latitude: latitude,
        longitude: longitude,
        maxDistanceKm: maxDistanceKm,
        limit: limit,
        onlyEmergency: onlyEmergency,
        only24_7: only24_7,
      );
    } catch (e) {
      throw Exception('Failed to find nearest hospitals: $e');
    }
  }

  @override
  Future<List<HospitalModel>> searchHospitals({
    required String searchTerm,
    String? city,
    String? state,
    int limit = 20,
  }) async {
    try {
      return await _remoteDataSource.searchHospitals(
        searchTerm: searchTerm,
        city: city,
        state: state,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Failed to search hospitals: $e');
    }
  }

  @override
  Future<HospitalModel?> getHospitalById({
    required String hospitalId,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      return await _remoteDataSource.getHospitalById(
        hospitalId: hospitalId,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );
    } catch (e) {
      throw Exception('Failed to get hospital by ID: $e');
    }
  }

  @override
  Future<List<HospitalModel>> getHospitalsByLocation({
    String? city,
    String? state,
    int limit = 50,
  }) async {
    try {
      return await _remoteDataSource.getHospitalsByLocation(
        city: city,
        state: state,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Failed to get hospitals by location: $e');
    }
  }
}
