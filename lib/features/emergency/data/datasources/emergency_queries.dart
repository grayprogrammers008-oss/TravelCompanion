import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin abstraction over the Supabase PostgREST chain calls used by
/// [EmergencyRemoteDataSourceImpl].
///
/// The Supabase fluent builders are not mockable through Mockito — their
/// generic types are fixed per method and `Mock` cannot intercept the
/// awaited `then()`. Wrapping the chain calls in this interface lets tests
/// substitute a fake while the production [EmergencyQueriesImpl] carries
/// the (untestable) Supabase code.
///
/// Realtime subscription methods (channels) are NOT covered by this
/// abstraction — they still go through `_client.channel(...)` directly
/// and are exercised by integration / live tests.
abstract class EmergencyQueries {
  // ============================================
  // Emergency Numbers (RPC)
  // ============================================

  /// Get all emergency numbers for a country via RPC.
  Future<dynamic> getAllEmergencyNumbersRpc(String country);

  /// Get emergency numbers filtered by service type via RPC.
  Future<dynamic> getEmergencyNumbersByTypeRpc({
    required String serviceType,
    required String country,
  });

  // ============================================
  // Emergency Contacts (table: emergency_contacts)
  // ============================================

  /// Get all emergency contacts for the user, ordered primary-first then
  /// by created_at ascending.
  Future<List<Map<String, dynamic>>> findEmergencyContactsForUser(
      String userId);

  /// Get a single contact by id constrained to the owning user (or null).
  Future<Map<String, dynamic>?> findEmergencyContactById({
    required String contactId,
    required String userId,
  });

  /// Unset the `is_primary` flag for all currently-primary contacts of a
  /// user. Used before creating/updating a primary contact.
  Future<void> unsetPrimaryContactsForUser(String userId);

  /// Insert a new emergency contact and return the inserted row.
  Future<Map<String, dynamic>> insertEmergencyContact(
      Map<String, dynamic> data);

  /// Update fields on an emergency contact constrained to the user;
  /// returns the updated row (single).
  Future<Map<String, dynamic>> updateEmergencyContact({
    required String contactId,
    required String userId,
    required Map<String, dynamic> data,
  });

  /// Delete an emergency contact constrained to the user.
  Future<void> deleteEmergencyContact({
    required String contactId,
    required String userId,
  });

  /// Set a specific contact as primary (assumes others have been cleared).
  Future<void> setContactAsPrimary({
    required String contactId,
    required String userId,
    required String updatedAtIso,
  });

  // ============================================
  // Location Sharing (table: location_shares)
  // ============================================

  /// Insert a new location_shares row and return the inserted row.
  Future<Map<String, dynamic>> insertLocationShare(Map<String, dynamic> data);

  /// Update a location_shares row constrained to the user; returns the
  /// updated row.
  Future<Map<String, dynamic>> updateLocationShare({
    required String sessionId,
    required String userId,
    required Map<String, dynamic> data,
  });

  /// Patch the status of a location_shares row constrained to the user.
  Future<void> updateLocationShareStatus({
    required String sessionId,
    required String userId,
    required String status,
  });

  /// Get the active location share for a user (or null).
  Future<Map<String, dynamic>?> findActiveLocationShareForUser(String userId);

  /// Fetch a single location_shares row by id.
  Future<Map<String, dynamic>> findLocationShareById(String sessionId);

  /// Get all active location shares (used to filter shares the user is in).
  Future<List<Map<String, dynamic>>> findAllActiveLocationShares();

  // ============================================
  // Emergency Alerts (table: emergency_alerts)
  // ============================================

  /// Insert a new emergency_alerts row and return the inserted row.
  Future<Map<String, dynamic>> insertEmergencyAlert(Map<String, dynamic> data);

  /// Update an emergency_alerts row by id (no user constraint); returns
  /// the updated row.
  Future<Map<String, dynamic>> updateEmergencyAlertById({
    required String alertId,
    required Map<String, dynamic> data,
  });

  /// Update an emergency_alerts row by id, constrained to the user;
  /// returns the updated row.
  Future<Map<String, dynamic>> updateEmergencyAlertByIdAndUser({
    required String alertId,
    required String userId,
    required Map<String, dynamic> data,
  });

  /// Get a single emergency_alerts row by id (or null).
  Future<Map<String, dynamic>?> findEmergencyAlertById(String alertId);

  /// Get emergency alerts for a user with optional status / since filters.
  Future<List<Map<String, dynamic>>> findUserEmergencyAlerts({
    required String userId,
    String? status,
    DateTime? since,
  });

  /// Get all alerts with the given status (used by received-alerts filter).
  Future<List<Map<String, dynamic>>> findAlertsByStatus(String status);

  // ============================================
  // Hospital / Medical (RPC + table)
  // ============================================

  /// Find nearest hospitals via RPC.
  Future<dynamic> findNearestHospitalsRpc({
    required double latitude,
    required double longitude,
    required double maxDistanceKm,
    required int limit,
    required bool onlyEmergency,
    required bool only24_7,
  });

  /// Search hospitals via RPC.
  Future<dynamic> searchHospitalsRpc({
    required String searchTerm,
    String? city,
    String? state,
    required int limit,
  });

  /// Get hospital by id with optional user location for distance via RPC.
  Future<dynamic> getHospitalWithDistanceRpc({
    required String hospitalId,
    double? userLatitude,
    double? userLongitude,
  });

  /// Get hospitals by location filters with optional city/state and limit.
  Future<List<Map<String, dynamic>>> findHospitalsByLocation({
    String? city,
    String? state,
    required int limit,
  });
}

/// Production implementation that talks to Supabase. Each method is a
/// minimal pass-through to the PostgREST chain and is exercised end-to-end
/// by integration / live tests, not unit tests.
class EmergencyQueriesImpl implements EmergencyQueries {
  EmergencyQueriesImpl(this._client);
  final SupabaseClient _client;

  // ============================================
  // Emergency Numbers
  // ============================================

  @override
  Future<dynamic> getAllEmergencyNumbersRpc(String country) {
    return _client.rpc(
      'get_all_emergency_numbers',
      params: {'p_country': country},
    );
  }

  @override
  Future<dynamic> getEmergencyNumbersByTypeRpc({
    required String serviceType,
    required String country,
  }) {
    return _client.rpc(
      'get_emergency_numbers_by_type',
      params: {
        'p_service_type': serviceType,
        'p_country': country,
      },
    );
  }

  // ============================================
  // Emergency Contacts
  // ============================================

  @override
  Future<List<Map<String, dynamic>>> findEmergencyContactsForUser(
      String userId) async {
    final response = await _client
        .from('emergency_contacts')
        .select()
        .eq('user_id', userId)
        .order('is_primary', ascending: false)
        .order('created_at', ascending: true);
    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> findEmergencyContactById({
    required String contactId,
    required String userId,
  }) async {
    final response = await _client
        .from('emergency_contacts')
        .select()
        .eq('id', contactId)
        .eq('user_id', userId)
        .maybeSingle();
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<void> unsetPrimaryContactsForUser(String userId) async {
    await _client
        .from('emergency_contacts')
        .update({'is_primary': false})
        .eq('user_id', userId)
        .eq('is_primary', true);
  }

  @override
  Future<Map<String, dynamic>> insertEmergencyContact(
      Map<String, dynamic> data) async {
    final response = await _client
        .from('emergency_contacts')
        .insert(data)
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>> updateEmergencyContact({
    required String contactId,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client
        .from('emergency_contacts')
        .update(data)
        .eq('id', contactId)
        .eq('user_id', userId)
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<void> deleteEmergencyContact({
    required String contactId,
    required String userId,
  }) async {
    await _client
        .from('emergency_contacts')
        .delete()
        .eq('id', contactId)
        .eq('user_id', userId);
  }

  @override
  Future<void> setContactAsPrimary({
    required String contactId,
    required String userId,
    required String updatedAtIso,
  }) async {
    await _client
        .from('emergency_contacts')
        .update({
          'is_primary': true,
          'updated_at': updatedAtIso,
        })
        .eq('id', contactId)
        .eq('user_id', userId);
  }

  // ============================================
  // Location Sharing
  // ============================================

  @override
  Future<Map<String, dynamic>> insertLocationShare(
      Map<String, dynamic> data) async {
    final response = await _client
        .from('location_shares')
        .insert(data)
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>> updateLocationShare({
    required String sessionId,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client
        .from('location_shares')
        .update(data)
        .eq('id', sessionId)
        .eq('user_id', userId)
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<void> updateLocationShareStatus({
    required String sessionId,
    required String userId,
    required String status,
  }) async {
    await _client
        .from('location_shares')
        .update({'status': status})
        .eq('id', sessionId)
        .eq('user_id', userId);
  }

  @override
  Future<Map<String, dynamic>?> findActiveLocationShareForUser(
      String userId) async {
    final response = await _client
        .from('location_shares')
        .select()
        .eq('user_id', userId)
        .eq('status', 'active')
        .maybeSingle();
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>> findLocationShareById(String sessionId) async {
    final response = await _client
        .from('location_shares')
        .select()
        .eq('id', sessionId)
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> findAllActiveLocationShares() async {
    final response = await _client
        .from('location_shares')
        .select()
        .eq('status', 'active')
        .order('last_updated_at', ascending: false);
    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ============================================
  // Emergency Alerts
  // ============================================

  @override
  Future<Map<String, dynamic>> insertEmergencyAlert(
      Map<String, dynamic> data) async {
    final response = await _client
        .from('emergency_alerts')
        .insert(data)
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>> updateEmergencyAlertById({
    required String alertId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client
        .from('emergency_alerts')
        .update(data)
        .eq('id', alertId)
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>> updateEmergencyAlertByIdAndUser({
    required String alertId,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client
        .from('emergency_alerts')
        .update(data)
        .eq('id', alertId)
        .eq('user_id', userId)
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>?> findEmergencyAlertById(String alertId) async {
    final response = await _client
        .from('emergency_alerts')
        .select()
        .eq('id', alertId)
        .maybeSingle();
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> findUserEmergencyAlerts({
    required String userId,
    String? status,
    DateTime? since,
  }) async {
    var query = _client.from('emergency_alerts').select().eq('user_id', userId);
    if (status != null) {
      query = query.eq('status', status);
    }
    if (since != null) {
      query = query.gte('created_at', since.toIso8601String());
    }
    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> findAlertsByStatus(String status) async {
    final response = await _client
        .from('emergency_alerts')
        .select()
        .eq('status', status)
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ============================================
  // Hospital / Medical
  // ============================================

  @override
  Future<dynamic> findNearestHospitalsRpc({
    required double latitude,
    required double longitude,
    required double maxDistanceKm,
    required int limit,
    required bool onlyEmergency,
    required bool only24_7,
  }) {
    return _client.rpc(
      'find_nearest_hospitals',
      params: {
        'user_lat': latitude,
        'user_lng': longitude,
        'max_distance_km': maxDistanceKm,
        'result_limit': limit,
        'only_emergency': onlyEmergency,
        'only_24_7': only24_7,
      },
    );
  }

  @override
  Future<dynamic> searchHospitalsRpc({
    required String searchTerm,
    String? city,
    String? state,
    required int limit,
  }) {
    return _client.rpc(
      'search_hospitals',
      params: {
        'search_term': searchTerm,
        'search_city': city,
        'search_state': state,
        'result_limit': limit,
      },
    );
  }

  @override
  Future<dynamic> getHospitalWithDistanceRpc({
    required String hospitalId,
    double? userLatitude,
    double? userLongitude,
  }) {
    return _client.rpc(
      'get_hospital_with_distance',
      params: {
        'hospital_id': hospitalId,
        'user_lat': userLatitude,
        'user_lng': userLongitude,
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> findHospitalsByLocation({
    String? city,
    String? state,
    required int limit,
  }) async {
    var query = _client.from('hospitals').select().eq('is_active', true);
    if (city != null) {
      query = query.ilike('city', city);
    }
    if (state != null) {
      query = query.ilike('state', state);
    }
    final response = await query.limit(limit);
    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}
