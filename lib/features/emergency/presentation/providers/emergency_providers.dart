import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/emergency_contact_model.dart';
import '../../../../shared/models/emergency_alert_model.dart';
import '../../../../shared/models/location_share_model.dart';
import '../../../../core/services/location_service.dart';
import '../../data/datasources/emergency_remote_datasource.dart';
import '../../data/repositories/emergency_repository_impl.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../../domain/usecases/trigger_emergency_alert_usecase.dart';
import '../../domain/usecases/add_emergency_contact_usecase.dart';
import '../../domain/usecases/get_emergency_contacts_usecase.dart';
import '../../domain/usecases/start_location_sharing_usecase.dart';
import '../../domain/usecases/update_shared_location_usecase.dart';

// ============================================
// Service Providers
// ============================================

/// Location Service Provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// ============================================
// Data Source and Repository Providers
// ============================================

/// Emergency Remote Data Source Provider
final emergencyRemoteDataSourceProvider =
    Provider<EmergencyRemoteDataSource>((ref) {
  return EmergencyRemoteDataSourceImpl();
});

/// Emergency Repository Provider
final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  final remoteDataSource = ref.watch(emergencyRemoteDataSourceProvider);
  final locationService = ref.watch(locationServiceProvider);
  return EmergencyRepositoryImpl(remoteDataSource, locationService);
});

// ============================================
// Use Case Providers
// ============================================

/// Trigger Emergency Alert Use Case Provider
final triggerEmergencyAlertUseCaseProvider =
    Provider<TriggerEmergencyAlertUseCase>((ref) {
  final repository = ref.watch(emergencyRepositoryProvider);
  return TriggerEmergencyAlertUseCase(repository);
});

/// Add Emergency Contact Use Case Provider
final addEmergencyContactUseCaseProvider =
    Provider<AddEmergencyContactUseCase>((ref) {
  final repository = ref.watch(emergencyRepositoryProvider);
  return AddEmergencyContactUseCase(repository);
});

/// Get Emergency Contacts Use Case Provider
final getEmergencyContactsUseCaseProvider =
    Provider<GetEmergencyContactsUseCase>((ref) {
  final repository = ref.watch(emergencyRepositoryProvider);
  return GetEmergencyContactsUseCase(repository);
});

/// Start Location Sharing Use Case Provider
final startLocationSharingUseCaseProvider =
    Provider<StartLocationSharingUseCase>((ref) {
  final repository = ref.watch(emergencyRepositoryProvider);
  return StartLocationSharingUseCase(repository);
});

/// Update Shared Location Use Case Provider
final updateSharedLocationUseCaseProvider =
    Provider<UpdateSharedLocationUseCase>((ref) {
  final repository = ref.watch(emergencyRepositoryProvider);
  return UpdateSharedLocationUseCase(repository);
});

// ============================================
// State Providers
// ============================================

/// Emergency Contacts Provider - REAL-TIME stream
final emergencyContactsProvider =
    FutureProvider<List<EmergencyContactModel>>((ref) async {
  final repository = ref.watch(emergencyRepositoryProvider);
  return await repository.getEmergencyContacts();
});

/// Active Emergency Alerts Provider - REAL-TIME stream
final activeAlertsProvider =
    StreamProvider<List<EmergencyAlertModel>>((ref) {
  final repository = ref.watch(emergencyRepositoryProvider);
  return repository.watchActiveAlerts();
});

/// Received Emergency Alerts Provider - Alerts sent to current user
final receivedAlertsProvider =
    StreamProvider<List<EmergencyAlertModel>>((ref) {
  final repository = ref.watch(emergencyRepositoryProvider);
  return repository.watchReceivedAlerts();
});

/// Active Location Share Provider
final activeLocationShareProvider =
    FutureProvider<LocationShareModel?>((ref) async {
  final repository = ref.watch(emergencyRepositoryProvider);
  return await repository.getActiveLocationShare();
});

/// Shared Locations Provider - Locations shared with current user
final sharedLocationsProvider =
    FutureProvider<List<LocationShareModel>>((ref) async {
  final repository = ref.watch(emergencyRepositoryProvider);
  return await repository.getSharedLocations();
});

// ============================================
// Emergency Controller State
// ============================================

class EmergencyState {
  final bool isLoading;
  final bool isTriggeringAlert;
  final EmergencyAlertModel? activeAlert;
  final LocationShareModel? activeLocationShare;
  final List<EmergencyContactModel>? contacts;
  final String? error;

  EmergencyState({
    this.isLoading = false,
    this.isTriggeringAlert = false,
    this.activeAlert,
    this.activeLocationShare,
    this.contacts,
    this.error,
  });

  EmergencyState copyWith({
    bool? isLoading,
    bool? isTriggeringAlert,
    EmergencyAlertModel? activeAlert,
    LocationShareModel? activeLocationShare,
    List<EmergencyContactModel>? contacts,
    String? error,
  }) {
    return EmergencyState(
      isLoading: isLoading ?? this.isLoading,
      isTriggeringAlert: isTriggeringAlert ?? this.isTriggeringAlert,
      activeAlert: activeAlert ?? this.activeAlert,
      activeLocationShare: activeLocationShare ?? this.activeLocationShare,
      contacts: contacts ?? this.contacts,
      error: error,
    );
  }
}

// ============================================
// Emergency Controller - Updated for Riverpod 3.0
// ============================================

class EmergencyController extends Notifier<EmergencyState> {
  late final EmergencyRepository _repository;
  late final TriggerEmergencyAlertUseCase _triggerAlertUseCase;
  late final AddEmergencyContactUseCase _addContactUseCase;
  late final StartLocationSharingUseCase _startLocationSharingUseCase;

  @override
  EmergencyState build() {
    // Initialize dependencies from ref
    _repository = ref.read(emergencyRepositoryProvider);
    _triggerAlertUseCase = ref.read(triggerEmergencyAlertUseCaseProvider);
    _addContactUseCase = ref.read(addEmergencyContactUseCaseProvider);
    _startLocationSharingUseCase =
        ref.read(startLocationSharingUseCaseProvider);

    return EmergencyState();
  }

  /// Trigger an emergency SOS alert
  Future<EmergencyAlertModel> triggerSOS({
    String? tripId,
    String? message,
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(isTriggeringAlert: true, error: null);
    try {
      final alert = await _triggerAlertUseCase(
        type: EmergencyAlertType.sos,
        tripId: tripId,
        message: message,
        latitude: latitude,
        longitude: longitude,
      );
      state = state.copyWith(
        isTriggeringAlert: false,
        activeAlert: alert,
      );
      return alert;
    } catch (e) {
      state = state.copyWith(
        isTriggeringAlert: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Trigger a help alert
  Future<EmergencyAlertModel> triggerHelpAlert({
    String? tripId,
    String? message,
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(isTriggeringAlert: true, error: null);
    try {
      final alert = await _triggerAlertUseCase(
        type: EmergencyAlertType.help,
        tripId: tripId,
        message: message,
        latitude: latitude,
        longitude: longitude,
      );
      state = state.copyWith(
        isTriggeringAlert: false,
        activeAlert: alert,
      );
      return alert;
    } catch (e) {
      state = state.copyWith(
        isTriggeringAlert: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Trigger a medical emergency alert
  Future<EmergencyAlertModel> triggerMedicalAlert({
    String? tripId,
    String? message,
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(isTriggeringAlert: true, error: null);
    try {
      final alert = await _triggerAlertUseCase(
        type: EmergencyAlertType.medical,
        tripId: tripId,
        message: message,
        latitude: latitude,
        longitude: longitude,
      );
      state = state.copyWith(
        isTriggeringAlert: false,
        activeAlert: alert,
      );
      return alert;
    } catch (e) {
      state = state.copyWith(
        isTriggeringAlert: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Cancel an active alert
  Future<void> cancelAlert(String alertId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.cancelAlert(alertId);
      state = state.copyWith(
        isLoading: false,
        activeAlert: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Resolve an alert
  Future<void> resolveAlert(String alertId, {String? resolution}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.resolveAlert(
        alertId: alertId,
        resolution: resolution,
      );
      state = state.copyWith(
        isLoading: false,
        activeAlert: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Add an emergency contact
  Future<EmergencyContactModel> addContact({
    required String name,
    required String phoneNumber,
    String? email,
    required String relationship,
    bool isPrimary = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final contact = await _addContactUseCase(
        name: name,
        phoneNumber: phoneNumber,
        email: email,
        relationship: relationship,
        isPrimary: isPrimary,
      );
      state = state.copyWith(isLoading: false);
      // Refresh contacts list
      ref.invalidate(emergencyContactsProvider);
      return contact;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Delete an emergency contact
  Future<void> deleteContact(String contactId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteEmergencyContact(contactId);
      state = state.copyWith(isLoading: false);
      // Refresh contacts list
      ref.invalidate(emergencyContactsProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Start location sharing
  Future<LocationShareModel> startLocationSharing({
    required List<String> contactIds,
    String? tripId,
    Duration? duration,
    String? message,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final locationShare = await _startLocationSharingUseCase(
        contactIds: contactIds,
        tripId: tripId,
        duration: duration,
        message: message,
      );
      state = state.copyWith(
        isLoading: false,
        activeLocationShare: locationShare,
      );
      return locationShare;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Stop location sharing
  Future<void> stopLocationSharing(String sessionId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.stopLocationSharing(sessionId);
      state = state.copyWith(
        isLoading: false,
        activeLocationShare: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

/// Emergency Controller Provider - Updated for Riverpod 3.0
final emergencyControllerProvider =
    NotifierProvider<EmergencyController, EmergencyState>(() {
  return EmergencyController();
});
