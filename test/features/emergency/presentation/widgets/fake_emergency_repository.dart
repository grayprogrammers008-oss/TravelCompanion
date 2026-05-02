import 'package:travel_crew/features/emergency/domain/repositories/emergency_repository.dart';
import 'package:travel_crew/shared/models/emergency_alert_model.dart';
import 'package:travel_crew/shared/models/emergency_contact_model.dart';
import 'package:travel_crew/shared/models/emergency_number_model.dart';
import 'package:travel_crew/shared/models/hospital_model.dart';
import 'package:travel_crew/shared/models/location_share_model.dart';

/// A no-op fake EmergencyRepository for widget tests that don't interact
/// with the network. All methods return empty/default values without
/// touching Supabase.
class FakeEmergencyRepository implements EmergencyRepository {
  @override
  Future<List<EmergencyNumberModel>> getEmergencyNumbers({
    String country = 'IN',
  }) async => [];

  @override
  Future<List<EmergencyNumberModel>> getEmergencyNumbersByType({
    required EmergencyServiceType serviceType,
    String country = 'IN',
  }) async => [];

  @override
  Future<List<EmergencyContactModel>> getEmergencyContacts() async => [];

  @override
  Future<EmergencyContactModel?> getEmergencyContactById(String contactId) async => null;

  @override
  Future<EmergencyContactModel> addEmergencyContact({
    required String name,
    required String phoneNumber,
    String? email,
    required String relationship,
    bool isPrimary = false,
  }) async {
    return EmergencyContactModel(
      id: 'fake',
      userId: 'fake',
      name: name,
      phoneNumber: phoneNumber,
      relationship: relationship,
      isPrimary: isPrimary,
      createdAt: DateTime.now(),
    );
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
    return EmergencyContactModel(
      id: contactId,
      userId: 'fake',
      name: name ?? '',
      phoneNumber: phoneNumber ?? '',
      relationship: relationship ?? '',
      isPrimary: isPrimary ?? false,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteEmergencyContact(String contactId) async {}

  @override
  Future<void> setPrimaryContact(String contactId) async {}

  @override
  Future<LocationShareModel> startLocationSharing({
    required List<String> contactIds,
    String? tripId,
    Duration? duration,
    String? message,
  }) async {
    throw UnimplementedError('Not used in widget tests');
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
    throw UnimplementedError('Not used in widget tests');
  }

  @override
  Future<void> pauseLocationSharing(String sessionId) async {}

  @override
  Future<void> resumeLocationSharing(String sessionId) async {}

  @override
  Future<void> stopLocationSharing(String sessionId) async {}

  @override
  Future<LocationShareModel?> getActiveLocationShare() async => null;

  @override
  Stream<LocationShareModel> watchLocationShare(String sessionId) =>
      const Stream.empty();

  @override
  Future<List<LocationShareModel>> getSharedLocations() async => [];

  @override
  Future<EmergencyAlertModel> triggerEmergencyAlert({
    required EmergencyAlertType type,
    String? tripId,
    String? message,
    double? latitude,
    double? longitude,
    List<String>? contactIds,
  }) async {
    return EmergencyAlertModel(
      id: 'fake-alert',
      userId: 'fake-user',
      tripId: tripId,
      type: type,
      status: EmergencyAlertStatus.active,
      message: message,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
      notifiedContactIds: const [],
    );
  }

  @override
  Future<EmergencyAlertModel> acknowledgeAlert(String alertId) async {
    throw UnimplementedError('Not used in widget tests');
  }

  @override
  Future<EmergencyAlertModel> resolveAlert({
    required String alertId,
    String? resolution,
  }) async {
    throw UnimplementedError('Not used in widget tests');
  }

  @override
  Future<EmergencyAlertModel> cancelAlert(String alertId) async {
    throw UnimplementedError('Not used in widget tests');
  }

  @override
  Future<EmergencyAlertModel?> getAlertById(String alertId) async => null;

  @override
  Future<List<EmergencyAlertModel>> getUserAlerts({
    EmergencyAlertStatus? status,
    DateTime? since,
  }) async => [];

  @override
  Stream<List<EmergencyAlertModel>> watchActiveAlerts() =>
      Stream.value(const <EmergencyAlertModel>[]);

  @override
  Stream<List<EmergencyAlertModel>> watchReceivedAlerts() =>
      Stream.value(const <EmergencyAlertModel>[]);

  @override
  Future<List<HospitalModel>> findNearestHospitals({
    required double latitude,
    required double longitude,
    double maxDistanceKm = 50.0,
    int limit = 10,
    bool onlyEmergency = true,
    bool only24_7 = false,
  }) async => [];

  @override
  Future<List<HospitalModel>> searchHospitals({
    required String searchTerm,
    String? city,
    String? state,
    int limit = 20,
  }) async => [];

  @override
  Future<HospitalModel?> getHospitalById({
    required String hospitalId,
    double? userLatitude,
    double? userLongitude,
  }) async => null;

  @override
  Future<List<HospitalModel>> getHospitalsByLocation({
    String? city,
    String? state,
    int limit = 50,
  }) async => [];
}
