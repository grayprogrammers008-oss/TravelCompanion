import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../shared/models/emergency_contact_model.dart';
import '../../../../shared/models/emergency_alert_model.dart';
import '../../../../shared/models/location_share_model.dart';
import '../../../../shared/models/hospital_model.dart';
import '../../../../shared/models/emergency_number_model.dart';
import 'emergency_queries.dart';

/// Emergency Remote Data Source - Supabase Implementation
///
/// Handles all emergency-related operations with Supabase backend.
abstract class EmergencyRemoteDataSource {
  // Emergency Numbers
  Future<List<EmergencyNumberModel>> getEmergencyNumbers({
    String country = 'IN',
  });
  Future<List<EmergencyNumberModel>> getEmergencyNumbersByType({
    required EmergencyServiceType serviceType,
    String country = 'IN',
  });

  // Emergency Contacts
  Future<List<EmergencyContactModel>> getEmergencyContacts();
  Future<EmergencyContactModel?> getEmergencyContactById(String contactId);
  Future<EmergencyContactModel> addEmergencyContact({
    required String name,
    required String phoneNumber,
    String? email,
    required String relationship,
    bool isPrimary = false,
  });
  Future<EmergencyContactModel> updateEmergencyContact({
    required String contactId,
    String? name,
    String? phoneNumber,
    String? email,
    String? relationship,
    bool? isPrimary,
  });
  Future<void> deleteEmergencyContact(String contactId);
  Future<void> setPrimaryContact(String contactId);

  // Location Sharing
  Future<LocationShareModel> startLocationSharing({
    required List<String> contactIds,
    String? tripId,
    Duration? duration,
    String? message,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
  });
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
  Future<void> pauseLocationSharing(String sessionId);
  Future<void> resumeLocationSharing(String sessionId);
  Future<void> stopLocationSharing(String sessionId);
  Future<LocationShareModel?> getActiveLocationShare();
  Stream<LocationShareModel> watchLocationShare(String sessionId);
  Future<List<LocationShareModel>> getSharedLocations();

  // Emergency Alerts/SOS
  Future<EmergencyAlertModel> triggerEmergencyAlert({
    required EmergencyAlertType type,
    String? tripId,
    String? message,
    double? latitude,
    double? longitude,
    List<String>? contactIds,
  });
  Future<EmergencyAlertModel> acknowledgeAlert(String alertId);
  Future<EmergencyAlertModel> resolveAlert({
    required String alertId,
    String? resolution,
  });
  Future<EmergencyAlertModel> cancelAlert(String alertId);
  Future<EmergencyAlertModel?> getAlertById(String alertId);
  Future<List<EmergencyAlertModel>> getUserAlerts({
    EmergencyAlertStatus? status,
    DateTime? since,
  });
  Stream<List<EmergencyAlertModel>> watchActiveAlerts();
  Stream<List<EmergencyAlertModel>> watchReceivedAlerts();

  // Hospital/Medical Emergency Services
  Future<List<HospitalModel>> findNearestHospitals({
    required double latitude,
    required double longitude,
    double maxDistanceKm = 50.0,
    int limit = 10,
    bool onlyEmergency = true,
    bool only24_7 = false,
  });
  Future<List<HospitalModel>> searchHospitals({
    required String searchTerm,
    String? city,
    String? state,
    int limit = 20,
  });
  Future<HospitalModel?> getHospitalById({
    required String hospitalId,
    double? userLatitude,
    double? userLongitude,
  });
  Future<List<HospitalModel>> getHospitalsByLocation({
    String? city,
    String? state,
    int limit = 50,
  });
}

/// Implementation of [EmergencyRemoteDataSource].
///
/// All Supabase chain calls (`from(...).select()...`) and RPC calls are
/// routed through [EmergencyQueries], which is fakeable for unit tests.
/// The realtime stream methods (`watchLocationShare`, `watchActiveAlerts`,
/// `watchReceivedAlerts`) still attach a Supabase channel directly — they
/// are covered by integration / live tests rather than the unit suite.
class EmergencyRemoteDataSourceImpl implements EmergencyRemoteDataSource {
  EmergencyRemoteDataSourceImpl([
    SupabaseClient? supabase,
  ])  : _suppliedClient = supabase,
        _queries = EmergencyQueriesImpl(supabase ?? SupabaseClientWrapper.client),
        _currentUserId = (() => SupabaseClientWrapper.currentUserId),
        _now = DateTime.now;

  /// Internal constructor for tests — accepts injected queries / clock /
  /// user-id supplier without touching [SupabaseClientWrapper].
  @visibleForTesting
  EmergencyRemoteDataSourceImpl.test({
    required EmergencyQueries queries,
    SupabaseClient? supabase,
    String? Function()? currentUserId,
    DateTime Function()? clock,
  })  : _suppliedClient = supabase,
        _queries = queries,
        _currentUserId =
            currentUserId ?? (() => SupabaseClientWrapper.currentUserId),
        _now = clock ?? DateTime.now;

  final SupabaseClient? _suppliedClient;
  final EmergencyQueries _queries;
  final String? Function() _currentUserId;
  final DateTime Function() _now;

  /// Lazy access to the underlying Supabase client.
  ///
  /// Only the realtime stream methods (`watchLocationShare`,
  /// `watchActiveAlerts`, `watchReceivedAlerts`) need direct channel
  /// access; non-stream methods route everything via [EmergencyQueries]
  /// and never touch this getter, which lets unit tests inject only a
  /// fake [EmergencyQueries] without initializing Supabase.
  SupabaseClient get _client =>
      _suppliedClient ?? SupabaseClientWrapper.client;

  // ============================================
  // Emergency Numbers Implementation
  // ============================================

  @override
  Future<List<EmergencyNumberModel>> getEmergencyNumbers({
    String country = 'IN',
  }) async {
    try {
      final response = await _queries.getAllEmergencyNumbersRpc(country);

      if (response == null) {
        return [];
      }

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => EmergencyNumberModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching emergency numbers: $e');
      }
      throw Exception('Failed to get emergency numbers: $e');
    }
  }

  @override
  Future<List<EmergencyNumberModel>> getEmergencyNumbersByType({
    required EmergencyServiceType serviceType,
    String country = 'IN',
  }) async {
    try {
      final response = await _queries.getEmergencyNumbersByTypeRpc(
        serviceType: serviceType.name,
        country: country,
      );

      if (response == null) {
        return [];
      }

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => EmergencyNumberModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching emergency numbers by type: $e');
      }
      throw Exception('Failed to get emergency numbers by type: $e');
    }
  }

  // ============================================
  // Emergency Contacts Implementation
  // ============================================

  @override
  Future<List<EmergencyContactModel>> getEmergencyContacts() async {
    try {
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final rows = await _queries.findEmergencyContactsForUser(userId);
      return rows.map(EmergencyContactModel.fromJson).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching emergency contacts: $e');
      }
      throw Exception('Failed to get emergency contacts: $e');
    }
  }

  @override
  Future<EmergencyContactModel?> getEmergencyContactById(
      String contactId) async {
    try {
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final row = await _queries.findEmergencyContactById(
        contactId: contactId,
        userId: userId,
      );

      if (row == null) return null;
      return EmergencyContactModel.fromJson(row);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching emergency contact: $e');
      }
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
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // If setting as primary, unset other primary contacts first
      if (isPrimary) {
        await _queries.unsetPrimaryContactsForUser(userId);
      }

      final data = {
        'user_id': userId,
        'name': name,
        'phone_number': phoneNumber,
        'email': email,
        'relationship': relationship,
        'is_primary': isPrimary,
      };

      final response = await _queries.insertEmergencyContact(data);

      return EmergencyContactModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error adding emergency contact: $e');
      }
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
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // If setting as primary, unset other primary contacts first
      if (isPrimary == true) {
        await _queries.unsetPrimaryContactsForUser(userId);
      }

      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phoneNumber != null) data['phone_number'] = phoneNumber;
      if (email != null) data['email'] = email;
      if (relationship != null) data['relationship'] = relationship;
      if (isPrimary != null) data['is_primary'] = isPrimary;
      data['updated_at'] = _now().toIso8601String();

      final response = await _queries.updateEmergencyContact(
        contactId: contactId,
        userId: userId,
        data: data,
      );

      return EmergencyContactModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating emergency contact: $e');
      }
      throw Exception('Failed to update emergency contact: $e');
    }
  }

  @override
  Future<void> deleteEmergencyContact(String contactId) async {
    try {
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _queries.deleteEmergencyContact(
        contactId: contactId,
        userId: userId,
      );

      if (kDebugMode) {
        debugPrint('✅ Emergency contact deleted: $contactId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting emergency contact: $e');
      }
      throw Exception('Failed to delete emergency contact: $e');
    }
  }

  @override
  Future<void> setPrimaryContact(String contactId) async {
    try {
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Unset all primary contacts first
      await _queries.unsetPrimaryContactsForUser(userId);

      // Set the specified contact as primary
      await _queries.setContactAsPrimary(
        contactId: contactId,
        userId: userId,
        updatedAtIso: _now().toIso8601String(),
      );

      if (kDebugMode) {
        debugPrint('✅ Primary contact set: $contactId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error setting primary contact: $e');
      }
      throw Exception('Failed to set primary contact: $e');
    }
  }

  // ============================================
  // Location Sharing Implementation
  // ============================================

  @override
  Future<LocationShareModel> startLocationSharing({
    required List<String> contactIds,
    String? tripId,
    Duration? duration,
    String? message,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
  }) async {
    try {
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final now = _now();
      final data = {
        'user_id': userId,
        'trip_id': tripId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'status': LocationShareStatus.active.name,
        'started_at': now.toIso8601String(),
        'expires_at':
            duration != null ? now.add(duration).toIso8601String() : null,
        'last_updated_at': now.toIso8601String(),
        'shared_with_contact_ids': contactIds,
        'message': message,
      };

      final response = await _queries.insertLocationShare(data);

      if (kDebugMode) {
        debugPrint('✅ Location sharing started');
      }

      return LocationShareModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error starting location sharing: $e');
      }
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
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final data = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'last_updated_at': _now().toIso8601String(),
      };

      if (message != null) {
        data['message'] = message;
      }

      final response = await _queries.updateLocationShare(
        sessionId: sessionId,
        userId: userId,
        data: data,
      );

      return LocationShareModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating shared location: $e');
      }
      throw Exception('Failed to update shared location: $e');
    }
  }

  @override
  Future<void> pauseLocationSharing(String sessionId) async {
    try {
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _queries.updateLocationShareStatus(
        sessionId: sessionId,
        userId: userId,
        status: LocationShareStatus.paused.name,
      );

      if (kDebugMode) {
        debugPrint('✅ Location sharing paused');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error pausing location sharing: $e');
      }
      throw Exception('Failed to pause location sharing: $e');
    }
  }

  @override
  Future<void> resumeLocationSharing(String sessionId) async {
    try {
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _queries.updateLocationShareStatus(
        sessionId: sessionId,
        userId: userId,
        status: LocationShareStatus.active.name,
      );

      if (kDebugMode) {
        debugPrint('✅ Location sharing resumed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error resuming location sharing: $e');
      }
      throw Exception('Failed to resume location sharing: $e');
    }
  }

  @override
  Future<void> stopLocationSharing(String sessionId) async {
    try {
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _queries.updateLocationShareStatus(
        sessionId: sessionId,
        userId: userId,
        status: LocationShareStatus.stopped.name,
      );

      if (kDebugMode) {
        debugPrint('✅ Location sharing stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error stopping location sharing: $e');
      }
      throw Exception('Failed to stop location sharing: $e');
    }
  }

  @override
  Future<LocationShareModel?> getActiveLocationShare() async {
    try {
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final row = await _queries.findActiveLocationShareForUser(userId);
      if (row == null) return null;
      return LocationShareModel.fromJson(row);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting active location share: $e');
      }
      throw Exception('Failed to get active location share: $e');
    }
  }

  // Realtime: stream method — keeps direct Supabase channel subscription.
  // Covered by integration / live tests, not the unit suite.
  @override
  Stream<LocationShareModel> watchLocationShare(String sessionId) {
    final userId = _currentUserId();
    if (userId == null) {
      return Stream.error(Exception('User not authenticated'));
    }

    final controller = StreamController<LocationShareModel>.broadcast();

    // Subscribe to real-time changes
    final channel = _client.channel('location_share:$sessionId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'location_shares',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: sessionId,
          ),
          callback: (payload) async {
            try {
              final newRecord = payload.newRecord;
              if (newRecord.isNotEmpty) {
                final location = LocationShareModel.fromJson(newRecord);
                if (!controller.isClosed) {
                  controller.add(location);
                }
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint('❌ Error processing location share update: $e');
              }
            }
          },
        )
        .subscribe();

    // Initial load
    _queries
        .findLocationShareById(sessionId)
        .then((response) {
      final location = LocationShareModel.fromJson(response);
      if (!controller.isClosed) {
        controller.add(location);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    // Cleanup
    controller.onCancel = () {
      channel.unsubscribe();
    };

    return controller.stream;
  }

  @override
  Future<List<LocationShareModel>> getSharedLocations() async {
    try {
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Note: Currently returns all active location shares for the user
      // Could be filtered by emergency contact IDs if needed in the future

      final rows = await _queries.findAllActiveLocationShares();

      return rows
          .map((json) => LocationShareModel.fromJson(json))
          .where((share) => share.sharedWithContactIds.contains(userId))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting shared locations: $e');
      }
      throw Exception('Failed to get shared locations: $e');
    }
  }

  // ============================================
  // Emergency Alerts/SOS Implementation
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
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // If no contact IDs specified, get all emergency contacts
      List<String> notifiedContacts = contactIds ?? [];
      if (notifiedContacts.isEmpty) {
        final contacts = await getEmergencyContacts();
        notifiedContacts = contacts.map((c) => c.id).toList();
      }

      final data = {
        'user_id': userId,
        'trip_id': tripId,
        'type': type.name,
        'status': EmergencyAlertStatus.active.name,
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
        'notified_contact_ids': notifiedContacts,
        'created_at': _now().toIso8601String(),
      };

      final response = await _queries.insertEmergencyAlert(data);

      if (kDebugMode) {
        debugPrint('🚨 Emergency alert triggered: ${type.name}');
      }

      return EmergencyAlertModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error triggering emergency alert: $e');
      }
      throw Exception('Failed to trigger emergency alert: $e');
    }
  }

  @override
  Future<EmergencyAlertModel> acknowledgeAlert(String alertId) async {
    try {
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final data = {
        'status': EmergencyAlertStatus.acknowledged.name,
        'acknowledged_at': _now().toIso8601String(),
        'acknowledged_by': userId,
      };

      final response = await _queries.updateEmergencyAlertById(
        alertId: alertId,
        data: data,
      );

      if (kDebugMode) {
        debugPrint('✅ Emergency alert acknowledged: $alertId');
      }

      return EmergencyAlertModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error acknowledging alert: $e');
      }
      throw Exception('Failed to acknowledge alert: $e');
    }
  }

  @override
  Future<EmergencyAlertModel> resolveAlert({
    required String alertId,
    String? resolution,
  }) async {
    try {
      final data = <String, dynamic>{
        'status': EmergencyAlertStatus.resolved.name,
        'resolved_at': _now().toIso8601String(),
      };

      if (resolution != null) {
        data['metadata'] = <String, dynamic>{'resolution': resolution};
      }

      final response = await _queries.updateEmergencyAlertById(
        alertId: alertId,
        data: data,
      );

      if (kDebugMode) {
        debugPrint('✅ Emergency alert resolved: $alertId');
      }

      return EmergencyAlertModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error resolving alert: $e');
      }
      throw Exception('Failed to resolve alert: $e');
    }
  }

  @override
  Future<EmergencyAlertModel> cancelAlert(String alertId) async {
    try {
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final data = {
        'status': EmergencyAlertStatus.cancelled.name,
        'resolved_at': _now().toIso8601String(),
      };

      final response = await _queries.updateEmergencyAlertByIdAndUser(
        alertId: alertId,
        userId: userId,
        data: data,
      );

      if (kDebugMode) {
        debugPrint('✅ Emergency alert cancelled: $alertId');
      }

      return EmergencyAlertModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error cancelling alert: $e');
      }
      throw Exception('Failed to cancel alert: $e');
    }
  }

  @override
  Future<EmergencyAlertModel?> getAlertById(String alertId) async {
    try {
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final row = await _queries.findEmergencyAlertById(alertId);
      if (row == null) return null;
      return EmergencyAlertModel.fromJson(row);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting alert by ID: $e');
      }
      throw Exception('Failed to get alert: $e');
    }
  }

  @override
  Future<List<EmergencyAlertModel>> getUserAlerts({
    EmergencyAlertStatus? status,
    DateTime? since,
  }) async {
    try {
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final rows = await _queries.findUserEmergencyAlerts(
        userId: userId,
        status: status?.name,
        since: since,
      );

      return rows.map(EmergencyAlertModel.fromJson).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting user alerts: $e');
      }
      throw Exception('Failed to get user alerts: $e');
    }
  }

  // Realtime: stream method — keeps direct Supabase channel subscription.
  // Covered by integration / live tests, not the unit suite.
  @override
  Stream<List<EmergencyAlertModel>> watchActiveAlerts() {
    final userId = _currentUserId();
    if (userId == null) {
      return Stream.error(Exception('User not authenticated'));
    }

    final controller = StreamController<List<EmergencyAlertModel>>.broadcast();

    Future<void> refetchAlerts() async {
      try {
        final alerts =
            await getUserAlerts(status: EmergencyAlertStatus.active);
        if (!controller.isClosed) {
          controller.add(alerts);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error fetching active alerts: $e');
        }
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    // Subscribe to real-time changes
    final channel = _client.channel('active_alerts:$userId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'emergency_alerts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            refetchAlerts();
          },
        )
        .subscribe();

    // Initial load
    refetchAlerts();

    // Cleanup
    controller.onCancel = () {
      channel.unsubscribe();
    };

    return controller.stream;
  }

  // Realtime: stream method — keeps direct Supabase channel subscription.
  // Covered by integration / live tests, not the unit suite.
  @override
  Stream<List<EmergencyAlertModel>> watchReceivedAlerts() {
    final userId = _currentUserId();
    if (userId == null) {
      return Stream.error(Exception('User not authenticated'));
    }

    final controller = StreamController<List<EmergencyAlertModel>>.broadcast();

    Future<void> refetchAlerts() async {
      try {
        // Get emergency contacts where current user is a contact
        final contacts = await getEmergencyContacts();
        final contactIds = contacts.map((c) => c.id).toList();

        if (contactIds.isEmpty) {
          if (!controller.isClosed) {
            controller.add([]);
          }
          return;
        }

        final rows = await _queries
            .findAlertsByStatus(EmergencyAlertStatus.active.name);

        final alerts = rows
            .map(EmergencyAlertModel.fromJson)
            .where((alert) => alert.notifiedContactIds
                .any((id) => contactIds.contains(id)))
            .toList();

        if (!controller.isClosed) {
          controller.add(alerts);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error fetching received alerts: $e');
        }
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    // Subscribe to real-time changes for all alerts
    final channel = _client.channel('received_alerts:$userId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'emergency_alerts',
          callback: (payload) {
            refetchAlerts();
          },
        )
        .subscribe();

    // Initial load
    refetchAlerts();

    // Cleanup
    controller.onCancel = () {
      channel.unsubscribe();
    };

    return controller.stream;
  }

  // ============================================
  // Hospital/Medical Emergency Services Implementation
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
      // Call the PostgreSQL function find_nearest_hospitals
      final response = await _queries.findNearestHospitalsRpc(
        latitude: latitude,
        longitude: longitude,
        maxDistanceKm: maxDistanceKm,
        limit: limit,
        onlyEmergency: onlyEmergency,
        only24_7: only24_7,
      );

      if (response == null) {
        return [];
      }

      // Convert response to list of HospitalModel
      final List<dynamic> data = response as List<dynamic>;
      debugPrint('Received ${data.length} hospitals from database');

      final hospitals = <HospitalModel>[];
      for (var i = 0; i < data.length; i++) {
        try {
          final json = data[i] as Map<String, dynamic>;
          debugPrint('Hospital $i JSON keys: ${json.keys.toList()}');
          debugPrint('Hospital $i data: $json');
          final hospital = HospitalModel.fromJson(json);
          hospitals.add(hospital);
        } catch (e, stack) {
          debugPrint('Error parsing hospital $i: $e');
          debugPrint('Stack trace: $stack');
          debugPrint('Raw data: ${data[i]}');
          // Continue to next hospital instead of failing completely
        }
      }

      return hospitals;
    } catch (e, stack) {
      debugPrint('Error finding nearest hospitals: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
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
      // Call the PostgreSQL function search_hospitals
      final response = await _queries.searchHospitalsRpc(
        searchTerm: searchTerm,
        city: city,
        state: state,
        limit: limit,
      );

      if (response == null) {
        return [];
      }

      // Convert response to list of HospitalModel
      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => HospitalModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error searching hospitals: $e');
      rethrow;
    }
  }

  @override
  Future<HospitalModel?> getHospitalById({
    required String hospitalId,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      // Call the PostgreSQL function get_hospital_with_distance
      final response = await _queries.getHospitalWithDistanceRpc(
        hospitalId: hospitalId,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );

      // The function returns a table, so we get the first row
      final List<dynamic> data = response;
      if (data.isEmpty) {
        return null;
      }

      return HospitalModel.fromJson(data.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error getting hospital by ID: $e');
      rethrow;
    }
  }

  @override
  Future<List<HospitalModel>> getHospitalsByLocation({
    String? city,
    String? state,
    int limit = 50,
  }) async {
    try {
      final rows = await _queries.findHospitalsByLocation(
        city: city,
        state: state,
        limit: limit,
      );
      return rows.map(HospitalModel.fromJson).toList();
    } catch (e) {
      debugPrint('Error getting hospitals by location: $e');
      rethrow;
    }
  }
}
