import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../shared/models/emergency_contact_model.dart';
import '../../../../shared/models/emergency_alert_model.dart';
import '../../../../shared/models/location_share_model.dart';

/// Emergency Remote Data Source - Supabase Implementation
///
/// Handles all emergency-related operations with Supabase backend.
abstract class EmergencyRemoteDataSource {
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
}

class EmergencyRemoteDataSourceImpl implements EmergencyRemoteDataSource {
  final SupabaseClient _client;

  EmergencyRemoteDataSourceImpl() : _client = SupabaseClientWrapper.client;

  // ============================================
  // Emergency Contacts Implementation
  // ============================================

  @override
  Future<List<EmergencyContactModel>> getEmergencyContacts() async {
    try {
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('emergency_contacts')
          .select()
          .eq('user_id', userId)
          .order('is_primary', ascending: false)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => EmergencyContactModel.fromJson(json))
          .toList();
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
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('emergency_contacts')
          .select()
          .eq('id', contactId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return EmergencyContactModel.fromJson(response);
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
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // If setting as primary, unset other primary contacts first
      if (isPrimary) {
        await _client
            .from('emergency_contacts')
            .update({'is_primary': false})
            .eq('user_id', userId)
            .eq('is_primary', true);
      }

      final data = {
        'user_id': userId,
        'name': name,
        'phone_number': phoneNumber,
        'email': email,
        'relationship': relationship,
        'is_primary': isPrimary,
      };

      final response = await _client
          .from('emergency_contacts')
          .insert(data)
          .select()
          .single();

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
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // If setting as primary, unset other primary contacts first
      if (isPrimary == true) {
        await _client
            .from('emergency_contacts')
            .update({'is_primary': false})
            .eq('user_id', userId)
            .eq('is_primary', true);
      }

      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phoneNumber != null) data['phone_number'] = phoneNumber;
      if (email != null) data['email'] = email;
      if (relationship != null) data['relationship'] = relationship;
      if (isPrimary != null) data['is_primary'] = isPrimary;
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('emergency_contacts')
          .update(data)
          .eq('id', contactId)
          .eq('user_id', userId)
          .select()
          .single();

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
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from('emergency_contacts')
          .delete()
          .eq('id', contactId)
          .eq('user_id', userId);

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
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Unset all primary contacts first
      await _client
          .from('emergency_contacts')
          .update({'is_primary': false})
          .eq('user_id', userId)
          .eq('is_primary', true);

      // Set the specified contact as primary
      await _client
          .from('emergency_contacts')
          .update({
            'is_primary': true,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', contactId)
          .eq('user_id', userId);

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
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
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

      final response =
          await _client.from('location_shares').insert(data).select().single();

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
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final data = {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'last_updated_at': DateTime.now().toIso8601String(),
      };

      if (message != null) {
        data['message'] = message;
      }

      final response = await _client
          .from('location_shares')
          .update(data)
          .eq('id', sessionId)
          .eq('user_id', userId)
          .select()
          .single();

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
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from('location_shares')
          .update({'status': LocationShareStatus.paused.name})
          .eq('id', sessionId)
          .eq('user_id', userId);

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
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from('location_shares')
          .update({'status': LocationShareStatus.active.name})
          .eq('id', sessionId)
          .eq('user_id', userId);

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
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from('location_shares')
          .update({'status': LocationShareStatus.stopped.name})
          .eq('id', sessionId)
          .eq('user_id', userId);

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
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('location_shares')
          .select()
          .eq('user_id', userId)
          .eq('status', LocationShareStatus.active.name)
          .maybeSingle();

      if (response == null) return null;
      return LocationShareModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting active location share: $e');
      }
      throw Exception('Failed to get active location share: $e');
    }
  }

  @override
  Stream<LocationShareModel> watchLocationShare(String sessionId) {
    final userId = SupabaseClientWrapper.currentUserId;
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
    _client
        .from('location_shares')
        .select()
        .eq('id', sessionId)
        .single()
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
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get user's emergency contact IDs to find shares
      final contacts = await getEmergencyContacts();
      final contactUserIds =
          contacts.map((c) => c.userId).toList(); // Simplified for now

      final response = await _client
          .from('location_shares')
          .select()
          .eq('status', LocationShareStatus.active.name)
          .order('last_updated_at', ascending: false);

      return (response as List)
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
      final userId = SupabaseClientWrapper.currentUserId;
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
        'created_at': DateTime.now().toIso8601String(),
      };

      final response =
          await _client.from('emergency_alerts').insert(data).select().single();

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
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final data = {
        'status': EmergencyAlertStatus.acknowledged.name,
        'acknowledged_at': DateTime.now().toIso8601String(),
        'acknowledged_by': userId,
      };

      final response = await _client
          .from('emergency_alerts')
          .update(data)
          .eq('id', alertId)
          .select()
          .single();

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
        'resolved_at': DateTime.now().toIso8601String(),
      };

      if (resolution != null) {
        data['metadata'] = <String, dynamic>{'resolution': resolution};
      }

      final response = await _client
          .from('emergency_alerts')
          .update(data)
          .eq('id', alertId)
          .select()
          .single();

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
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final data = {
        'status': EmergencyAlertStatus.cancelled.name,
        'resolved_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('emergency_alerts')
          .update(data)
          .eq('id', alertId)
          .eq('user_id', userId)
          .select()
          .single();

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
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('emergency_alerts')
          .select()
          .eq('id', alertId)
          .maybeSingle();

      if (response == null) return null;
      return EmergencyAlertModel.fromJson(response);
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
      final userId = SupabaseClientWrapper.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      var query =
          _client.from('emergency_alerts').select().eq('user_id', userId);

      if (status != null) {
        query = query.eq('status', status.name);
      }

      if (since != null) {
        query = query.gte('created_at', since.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => EmergencyAlertModel.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting user alerts: $e');
      }
      throw Exception('Failed to get user alerts: $e');
    }
  }

  @override
  Stream<List<EmergencyAlertModel>> watchActiveAlerts() {
    final userId = SupabaseClientWrapper.currentUserId;
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

  @override
  Stream<List<EmergencyAlertModel>> watchReceivedAlerts() {
    final userId = SupabaseClientWrapper.currentUserId;
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

        final response = await _client
            .from('emergency_alerts')
            .select()
            .eq('status', EmergencyAlertStatus.active.name)
            .order('created_at', ascending: false);

        final alerts = (response as List)
            .map((json) => EmergencyAlertModel.fromJson(json))
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
}
