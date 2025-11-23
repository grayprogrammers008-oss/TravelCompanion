import '../../../../shared/models/emergency_contact_model.dart';
import '../../../../shared/models/location_share_model.dart';
import '../../../../shared/models/emergency_alert_model.dart';
import '../../../../shared/models/hospital_model.dart';
import '../../../../shared/models/emergency_number_model.dart';

/// Abstract repository for emergency service operations
abstract class EmergencyRepository {
  // ============================================
  // Emergency Numbers
  // ============================================

  /// Get all emergency numbers for a specific country
  Future<List<EmergencyNumberModel>> getEmergencyNumbers({
    String country = 'IN',
  });

  /// Get emergency numbers filtered by service type
  Future<List<EmergencyNumberModel>> getEmergencyNumbersByType({
    required EmergencyServiceType serviceType,
    String country = 'IN',
  });

  // ============================================
  // Emergency Contacts Management
  // ============================================

  /// Get all emergency contacts for the current user
  Future<List<EmergencyContactModel>> getEmergencyContacts();

  /// Get a specific emergency contact by ID
  Future<EmergencyContactModel?> getEmergencyContactById(String contactId);

  /// Add a new emergency contact
  Future<EmergencyContactModel> addEmergencyContact({
    required String name,
    required String phoneNumber,
    String? email,
    required String relationship,
    bool isPrimary = false,
  });

  /// Update an existing emergency contact
  Future<EmergencyContactModel> updateEmergencyContact({
    required String contactId,
    String? name,
    String? phoneNumber,
    String? email,
    String? relationship,
    bool? isPrimary,
  });

  /// Delete an emergency contact
  Future<void> deleteEmergencyContact(String contactId);

  /// Set a contact as primary emergency contact
  Future<void> setPrimaryContact(String contactId);

  // ============================================
  // Location Sharing
  // ============================================

  /// Start sharing location with specified contacts
  Future<LocationShareModel> startLocationSharing({
    required List<String> contactIds,
    String? tripId,
    Duration? duration, // How long to share (null = indefinite)
    String? message,
  });

  /// Update current location in an active sharing session
  Future<LocationShareModel> updateSharedLocation({
    required String sessionId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    String? message,
  });

  /// Pause location sharing
  Future<void> pauseLocationSharing(String sessionId);

  /// Resume location sharing
  Future<void> resumeLocationSharing(String sessionId);

  /// Stop location sharing
  Future<void> stopLocationSharing(String sessionId);

  /// Get active location sharing session for current user
  Future<LocationShareModel?> getActiveLocationShare();

  /// Watch location updates from a specific user (for contacts)
  Stream<LocationShareModel> watchLocationShare(String sessionId);

  /// Get all location shares being shared with the current user
  Future<List<LocationShareModel>> getSharedLocations();

  // ============================================
  // Emergency Alerts/SOS
  // ============================================

  /// Trigger an emergency alert/SOS
  Future<EmergencyAlertModel> triggerEmergencyAlert({
    required EmergencyAlertType type,
    String? tripId,
    String? message,
    double? latitude,
    double? longitude,
    List<String>? contactIds, // If null, notify all emergency contacts
  });

  /// Acknowledge an emergency alert
  Future<EmergencyAlertModel> acknowledgeAlert(String alertId);

  /// Resolve/close an emergency alert
  Future<EmergencyAlertModel> resolveAlert({
    required String alertId,
    String? resolution,
  });

  /// Cancel an emergency alert (user-initiated)
  Future<EmergencyAlertModel> cancelAlert(String alertId);

  /// Get alert by ID
  Future<EmergencyAlertModel?> getAlertById(String alertId);

  /// Get all alerts for the current user
  Future<List<EmergencyAlertModel>> getUserAlerts({
    EmergencyAlertStatus? status,
    DateTime? since,
  });

  /// Watch active emergency alerts for current user
  Stream<List<EmergencyAlertModel>> watchActiveAlerts();

  /// Watch emergency alerts that the current user has been notified about
  Stream<List<EmergencyAlertModel>> watchReceivedAlerts();

  // ============================================
  // Hospital/Medical Emergency Services
  // ============================================

  /// Find nearest hospitals to a given location
  ///
  /// Parameters:
  /// - [latitude]: User's current latitude
  /// - [longitude]: User's current longitude
  /// - [maxDistanceKm]: Maximum search radius in kilometers (default: 50)
  /// - [limit]: Maximum number of results to return (default: 10)
  /// - [onlyEmergency]: Filter only hospitals with emergency rooms (default: true)
  /// - [only24_7]: Filter only 24/7 hospitals (default: false)
  Future<List<HospitalModel>> findNearestHospitals({
    required double latitude,
    required double longitude,
    double maxDistanceKm = 50.0,
    int limit = 10,
    bool onlyEmergency = true,
    bool only24_7 = false,
  });

  /// Search hospitals by name, city, or address
  ///
  /// Parameters:
  /// - [searchTerm]: Search query string
  /// - [city]: Optional city filter
  /// - [state]: Optional state filter
  /// - [limit]: Maximum number of results (default: 20)
  Future<List<HospitalModel>> searchHospitals({
    required String searchTerm,
    String? city,
    String? state,
    int limit = 20,
  });

  /// Get a specific hospital by ID with optional distance calculation
  ///
  /// Parameters:
  /// - [hospitalId]: The hospital's unique identifier
  /// - [userLatitude]: Optional user latitude for distance calculation
  /// - [userLongitude]: Optional user longitude for distance calculation
  Future<HospitalModel?> getHospitalById({
    required String hospitalId,
    double? userLatitude,
    double? userLongitude,
  });

  /// Get all hospitals in a specific city/state
  Future<List<HospitalModel>> getHospitalsByLocation({
    String? city,
    String? state,
    int limit = 50,
  });
}
