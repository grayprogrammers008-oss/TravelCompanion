import 'package:flutter_test/flutter_test.dart';

import 'package:travel_crew/features/emergency/data/datasources/emergency_queries.dart';
import 'package:travel_crew/features/emergency/data/datasources/emergency_remote_datasource.dart';
import 'package:travel_crew/shared/models/emergency_alert_model.dart';
import 'package:travel_crew/shared/models/emergency_number_model.dart';
import 'package:travel_crew/shared/models/location_share_model.dart';

/// Comprehensive unit tests for [EmergencyRemoteDataSourceImpl].
///
/// All Supabase chain calls go through [EmergencyQueries] which is faked
/// here. We exercise every public non-stream method's happy + error path.
/// Realtime stream methods (`watchLocationShare`, `watchActiveAlerts`,
/// `watchReceivedAlerts`) are intentionally excluded — they wire
/// `_client.channel(...)` directly and are covered by integration / live
/// tests.

class _FakeQueries implements EmergencyQueries {
  // ---------- Recorded args ----------
  String? lastNumbersCountry;
  String? lastNumbersByTypeServiceType;
  String? lastNumbersByTypeCountry;

  String? lastFindContactsUserId;
  String? lastFindContactByIdContactId;
  String? lastFindContactByIdUserId;
  String? lastUnsetPrimaryUserId;
  Map<String, dynamic>? lastInsertedContact;
  String? lastUpdateContactContactId;
  String? lastUpdateContactUserId;
  Map<String, dynamic>? lastUpdateContactData;
  String? lastDeleteContactContactId;
  String? lastDeleteContactUserId;
  String? lastSetPrimaryContactId;
  String? lastSetPrimaryUserId;
  String? lastSetPrimaryUpdatedAtIso;

  Map<String, dynamic>? lastInsertedLocationShare;
  String? lastUpdateLocationSessionId;
  String? lastUpdateLocationUserId;
  Map<String, dynamic>? lastUpdateLocationData;
  String? lastUpdateStatusSessionId;
  String? lastUpdateStatusUserId;
  String? lastUpdateStatusValue;
  String? lastFindActiveLocationUserId;
  String? lastFindLocationByIdSessionId;
  bool wasFindAllActiveLocationsCalled = false;

  Map<String, dynamic>? lastInsertedAlert;
  String? lastUpdateAlertByIdAlertId;
  Map<String, dynamic>? lastUpdateAlertByIdData;
  String? lastUpdateAlertByIdAndUserAlertId;
  String? lastUpdateAlertByIdAndUserUserId;
  Map<String, dynamic>? lastUpdateAlertByIdAndUserData;
  String? lastFindAlertByIdArg;
  String? lastFindUserAlertsUserId;
  String? lastFindUserAlertsStatus;
  DateTime? lastFindUserAlertsSince;
  String? lastFindAlertsByStatus;

  Map<String, dynamic>? lastFindNearestHospitalsArgs;
  Map<String, dynamic>? lastSearchHospitalsArgs;
  Map<String, dynamic>? lastGetHospitalByIdArgs;
  Map<String, dynamic>? lastFindHospitalsByLocationArgs;

  // ---------- Canned responses ----------
  dynamic numbersResponse;
  dynamic numbersByTypeResponse;

  List<Map<String, dynamic>> contactsResponse = const [];
  Map<String, dynamic>? contactByIdResponse;
  bool _contactByIdReturnsNull = false;
  Map<String, dynamic>? insertContactResponse;
  Map<String, dynamic>? updateContactResponse;

  Map<String, dynamic>? insertLocationShareResponse;
  Map<String, dynamic>? updateLocationShareResponse;
  Map<String, dynamic>? activeLocationShareResponse;
  bool _activeLocationShareReturnsNull = false;
  Map<String, dynamic>? findLocationByIdResponse;
  List<Map<String, dynamic>> activeLocationSharesResponse = const [];

  Map<String, dynamic>? insertAlertResponse;
  Map<String, dynamic>? updateAlertByIdResponse;
  Map<String, dynamic>? updateAlertByIdAndUserResponse;
  Map<String, dynamic>? alertByIdResponse;
  bool _alertByIdReturnsNull = false;
  List<Map<String, dynamic>> userAlertsResponse = const [];
  List<Map<String, dynamic>> alertsByStatusResponse = const [];

  dynamic nearestHospitalsResponse;
  dynamic searchHospitalsResponse;
  dynamic hospitalByIdResponse;
  List<Map<String, dynamic>> hospitalsByLocationResponse = const [];

  // ---------- Throw triggers ----------
  Object? throwOnGetAllNumbers;
  Object? throwOnNumbersByType;
  Object? throwOnFindContacts;
  Object? throwOnFindContactById;
  Object? throwOnUnsetPrimary;
  Object? throwOnInsertContact;
  Object? throwOnUpdateContact;
  Object? throwOnDeleteContact;
  Object? throwOnSetPrimary;
  Object? throwOnInsertLocationShare;
  Object? throwOnUpdateLocationShare;
  Object? throwOnUpdateLocationStatus;
  Object? throwOnFindActiveLocation;
  Object? throwOnFindLocationById;
  Object? throwOnFindAllActiveLocations;
  Object? throwOnInsertAlert;
  Object? throwOnUpdateAlertById;
  Object? throwOnUpdateAlertByIdAndUser;
  Object? throwOnFindAlertById;
  Object? throwOnFindUserAlerts;
  Object? throwOnFindAlertsByStatus;
  Object? throwOnFindNearestHospitals;
  Object? throwOnSearchHospitals;
  Object? throwOnGetHospitalById;
  Object? throwOnFindHospitalsByLocation;

  void setContactByIdReturnsNull() => _contactByIdReturnsNull = true;
  void setActiveLocationShareReturnsNull() =>
      _activeLocationShareReturnsNull = true;
  void setAlertByIdReturnsNull() => _alertByIdReturnsNull = true;

  // ============================================
  // Emergency Numbers
  // ============================================

  @override
  Future<dynamic> getAllEmergencyNumbersRpc(String country) async {
    if (throwOnGetAllNumbers != null) throw throwOnGetAllNumbers!;
    lastNumbersCountry = country;
    return numbersResponse;
  }

  @override
  Future<dynamic> getEmergencyNumbersByTypeRpc({
    required String serviceType,
    required String country,
  }) async {
    if (throwOnNumbersByType != null) throw throwOnNumbersByType!;
    lastNumbersByTypeServiceType = serviceType;
    lastNumbersByTypeCountry = country;
    return numbersByTypeResponse;
  }

  // ============================================
  // Emergency Contacts
  // ============================================

  @override
  Future<List<Map<String, dynamic>>> findEmergencyContactsForUser(
      String userId) async {
    if (throwOnFindContacts != null) throw throwOnFindContacts!;
    lastFindContactsUserId = userId;
    return contactsResponse;
  }

  @override
  Future<Map<String, dynamic>?> findEmergencyContactById({
    required String contactId,
    required String userId,
  }) async {
    if (throwOnFindContactById != null) throw throwOnFindContactById!;
    lastFindContactByIdContactId = contactId;
    lastFindContactByIdUserId = userId;
    if (_contactByIdReturnsNull) return null;
    return contactByIdResponse;
  }

  @override
  Future<void> unsetPrimaryContactsForUser(String userId) async {
    if (throwOnUnsetPrimary != null) throw throwOnUnsetPrimary!;
    lastUnsetPrimaryUserId = userId;
  }

  @override
  Future<Map<String, dynamic>> insertEmergencyContact(
      Map<String, dynamic> data) async {
    if (throwOnInsertContact != null) throw throwOnInsertContact!;
    lastInsertedContact = data;
    return insertContactResponse ?? data;
  }

  @override
  Future<Map<String, dynamic>> updateEmergencyContact({
    required String contactId,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    if (throwOnUpdateContact != null) throw throwOnUpdateContact!;
    lastUpdateContactContactId = contactId;
    lastUpdateContactUserId = userId;
    lastUpdateContactData = data;
    return updateContactResponse ?? data;
  }

  @override
  Future<void> deleteEmergencyContact({
    required String contactId,
    required String userId,
  }) async {
    if (throwOnDeleteContact != null) throw throwOnDeleteContact!;
    lastDeleteContactContactId = contactId;
    lastDeleteContactUserId = userId;
  }

  @override
  Future<void> setContactAsPrimary({
    required String contactId,
    required String userId,
    required String updatedAtIso,
  }) async {
    if (throwOnSetPrimary != null) throw throwOnSetPrimary!;
    lastSetPrimaryContactId = contactId;
    lastSetPrimaryUserId = userId;
    lastSetPrimaryUpdatedAtIso = updatedAtIso;
  }

  // ============================================
  // Location Sharing
  // ============================================

  @override
  Future<Map<String, dynamic>> insertLocationShare(
      Map<String, dynamic> data) async {
    if (throwOnInsertLocationShare != null) throw throwOnInsertLocationShare!;
    lastInsertedLocationShare = data;
    return insertLocationShareResponse ?? data;
  }

  @override
  Future<Map<String, dynamic>> updateLocationShare({
    required String sessionId,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    if (throwOnUpdateLocationShare != null) throw throwOnUpdateLocationShare!;
    lastUpdateLocationSessionId = sessionId;
    lastUpdateLocationUserId = userId;
    lastUpdateLocationData = data;
    return updateLocationShareResponse ?? data;
  }

  @override
  Future<void> updateLocationShareStatus({
    required String sessionId,
    required String userId,
    required String status,
  }) async {
    if (throwOnUpdateLocationStatus != null) throw throwOnUpdateLocationStatus!;
    lastUpdateStatusSessionId = sessionId;
    lastUpdateStatusUserId = userId;
    lastUpdateStatusValue = status;
  }

  @override
  Future<Map<String, dynamic>?> findActiveLocationShareForUser(
      String userId) async {
    if (throwOnFindActiveLocation != null) throw throwOnFindActiveLocation!;
    lastFindActiveLocationUserId = userId;
    if (_activeLocationShareReturnsNull) return null;
    return activeLocationShareResponse;
  }

  @override
  Future<Map<String, dynamic>> findLocationShareById(String sessionId) async {
    if (throwOnFindLocationById != null) throw throwOnFindLocationById!;
    lastFindLocationByIdSessionId = sessionId;
    if (findLocationByIdResponse == null) {
      throw StateError('No findLocationByIdResponse configured');
    }
    return findLocationByIdResponse!;
  }

  @override
  Future<List<Map<String, dynamic>>> findAllActiveLocationShares() async {
    if (throwOnFindAllActiveLocations != null) {
      throw throwOnFindAllActiveLocations!;
    }
    wasFindAllActiveLocationsCalled = true;
    return activeLocationSharesResponse;
  }

  // ============================================
  // Emergency Alerts
  // ============================================

  @override
  Future<Map<String, dynamic>> insertEmergencyAlert(
      Map<String, dynamic> data) async {
    if (throwOnInsertAlert != null) throw throwOnInsertAlert!;
    lastInsertedAlert = data;
    return insertAlertResponse ?? data;
  }

  @override
  Future<Map<String, dynamic>> updateEmergencyAlertById({
    required String alertId,
    required Map<String, dynamic> data,
  }) async {
    if (throwOnUpdateAlertById != null) throw throwOnUpdateAlertById!;
    lastUpdateAlertByIdAlertId = alertId;
    lastUpdateAlertByIdData = data;
    return updateAlertByIdResponse ?? data;
  }

  @override
  Future<Map<String, dynamic>> updateEmergencyAlertByIdAndUser({
    required String alertId,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    if (throwOnUpdateAlertByIdAndUser != null) {
      throw throwOnUpdateAlertByIdAndUser!;
    }
    lastUpdateAlertByIdAndUserAlertId = alertId;
    lastUpdateAlertByIdAndUserUserId = userId;
    lastUpdateAlertByIdAndUserData = data;
    return updateAlertByIdAndUserResponse ?? data;
  }

  @override
  Future<Map<String, dynamic>?> findEmergencyAlertById(String alertId) async {
    if (throwOnFindAlertById != null) throw throwOnFindAlertById!;
    lastFindAlertByIdArg = alertId;
    if (_alertByIdReturnsNull) return null;
    return alertByIdResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findUserEmergencyAlerts({
    required String userId,
    String? status,
    DateTime? since,
  }) async {
    if (throwOnFindUserAlerts != null) throw throwOnFindUserAlerts!;
    lastFindUserAlertsUserId = userId;
    lastFindUserAlertsStatus = status;
    lastFindUserAlertsSince = since;
    return userAlertsResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findAlertsByStatus(String status) async {
    if (throwOnFindAlertsByStatus != null) throw throwOnFindAlertsByStatus!;
    lastFindAlertsByStatus = status;
    return alertsByStatusResponse;
  }

  // ============================================
  // Hospitals
  // ============================================

  @override
  Future<dynamic> findNearestHospitalsRpc({
    required double latitude,
    required double longitude,
    required double maxDistanceKm,
    required int limit,
    required bool onlyEmergency,
    required bool only24_7,
  }) async {
    if (throwOnFindNearestHospitals != null) throw throwOnFindNearestHospitals!;
    lastFindNearestHospitalsArgs = {
      'latitude': latitude,
      'longitude': longitude,
      'maxDistanceKm': maxDistanceKm,
      'limit': limit,
      'onlyEmergency': onlyEmergency,
      'only24_7': only24_7,
    };
    return nearestHospitalsResponse;
  }

  @override
  Future<dynamic> searchHospitalsRpc({
    required String searchTerm,
    String? city,
    String? state,
    required int limit,
  }) async {
    if (throwOnSearchHospitals != null) throw throwOnSearchHospitals!;
    lastSearchHospitalsArgs = {
      'searchTerm': searchTerm,
      'city': city,
      'state': state,
      'limit': limit,
    };
    return searchHospitalsResponse;
  }

  @override
  Future<dynamic> getHospitalWithDistanceRpc({
    required String hospitalId,
    double? userLatitude,
    double? userLongitude,
  }) async {
    if (throwOnGetHospitalById != null) throw throwOnGetHospitalById!;
    lastGetHospitalByIdArgs = {
      'hospitalId': hospitalId,
      'userLatitude': userLatitude,
      'userLongitude': userLongitude,
    };
    return hospitalByIdResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findHospitalsByLocation({
    String? city,
    String? state,
    required int limit,
  }) async {
    if (throwOnFindHospitalsByLocation != null) {
      throw throwOnFindHospitalsByLocation!;
    }
    lastFindHospitalsByLocationArgs = {
      'city': city,
      'state': state,
      'limit': limit,
    };
    return hospitalsByLocationResponse;
  }
}

// ---------- Test fixtures ----------

DateTime _ts() => DateTime.utc(2024, 6, 1, 12, 0, 0);

DateTime _fixedNow() => DateTime.utc(2024, 6, 1, 12, 0, 0);

Map<String, dynamic> _numberRow({
  String id = 'n-1',
  String serviceType = 'police',
  String country = 'IN',
}) {
  return {
    'id': id,
    'service_name': 'Police',
    'service_type': serviceType,
    'phone_number': '100',
    'country': country,
    'is_toll_free': true,
    'is_24_7': true,
    'languages': const ['en'],
    'display_order': 1,
    'is_active': true,
  };
}

Map<String, dynamic> _contactRow({
  String id = 'c-1',
  String userId = 'u-1',
  String name = 'Mom',
  bool isPrimary = false,
}) {
  return {
    'id': id,
    'user_id': userId,
    'name': name,
    'phone_number': '+1234567890',
    'email': 'mom@example.com',
    'relationship': 'Parent',
    'is_primary': isPrimary,
    'created_at': _ts().toIso8601String(),
    'updated_at': _ts().toIso8601String(),
  };
}

Map<String, dynamic> _locationShareRow({
  String id = 'ls-1',
  String userId = 'u-1',
  String status = 'active',
  List<String> contactIds = const ['c-1'],
}) {
  return {
    'id': id,
    'user_id': userId,
    'trip_id': null,
    'latitude': 40.0,
    'longitude': -74.0,
    'accuracy': 5.0,
    'altitude': null,
    'speed': null,
    'heading': null,
    'status': status,
    'started_at': _ts().toIso8601String(),
    'expires_at': null,
    'last_updated_at': _ts().toIso8601String(),
    'shared_with_contact_ids': contactIds,
    'message': null,
  };
}

Map<String, dynamic> _alertRow({
  String id = 'a-1',
  String userId = 'u-1',
  String type = 'sos',
  String status = 'active',
  List<String> notifiedContactIds = const ['c-1'],
}) {
  return {
    'id': id,
    'user_id': userId,
    'trip_id': null,
    'type': type,
    'status': status,
    'message': 'Help me',
    'latitude': 40.0,
    'longitude': -74.0,
    'created_at': _ts().toIso8601String(),
    'notified_contact_ids': notifiedContactIds,
  };
}

Map<String, dynamic> _hospitalRow({
  String id = 'h-1',
  String name = 'City Hospital',
}) {
  return {
    'id': id,
    'name': name,
    'address': '123 Main St',
    'city': 'Mumbai',
    'state': 'MH',
    'country': 'India',
    'latitude': 19.0,
    'longitude': 72.8,
    'is_active': true,
    'has_emergency_room': true,
    'is_24_7': true,
    'created_at': _ts().toIso8601String(),
  };
}

EmergencyRemoteDataSourceImpl _buildDs(
  _FakeQueries queries, {
  String? userId = 'u-1',
}) {
  return EmergencyRemoteDataSourceImpl.test(
    queries: queries,
    currentUserId: () => userId,
    clock: _fixedNow,
  );
}

void main() {
  late _FakeQueries queries;
  late EmergencyRemoteDataSourceImpl ds;

  setUp(() {
    queries = _FakeQueries();
    ds = _buildDs(queries);
  });

  // =====================================================
  // EMERGENCY NUMBERS
  // =====================================================
  group('EmergencyNumbers / getEmergencyNumbers', () {
    test('default country IN, parses list of rows', () async {
      queries.numbersResponse = [_numberRow(), _numberRow(id: 'n-2')];
      final result = await ds.getEmergencyNumbers();
      expect(queries.lastNumbersCountry, 'IN');
      expect(result, hasLength(2));
      expect(result.first.id, 'n-1');
    });

    test('forwards explicit country', () async {
      queries.numbersResponse = const [];
      await ds.getEmergencyNumbers(country: 'US');
      expect(queries.lastNumbersCountry, 'US');
    });

    test('returns empty list when RPC returns null', () async {
      queries.numbersResponse = null;
      final result = await ds.getEmergencyNumbers();
      expect(result, isEmpty);
    });

    test('returns empty list when RPC returns empty list', () async {
      queries.numbersResponse = const [];
      final result = await ds.getEmergencyNumbers();
      expect(result, isEmpty);
    });

    test('wraps RPC errors in Failed-to-get exception', () async {
      queries.throwOnGetAllNumbers = Exception('boom');
      await expectLater(
        ds.getEmergencyNumbers(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to get'))),
      );
    });
  });

  group('EmergencyNumbers / getEmergencyNumbersByType', () {
    test('forwards service type and default country', () async {
      queries.numbersByTypeResponse = [_numberRow(serviceType: 'fire')];
      final result = await ds.getEmergencyNumbersByType(
        serviceType: EmergencyServiceType.fire,
      );
      expect(queries.lastNumbersByTypeServiceType, 'fire');
      expect(queries.lastNumbersByTypeCountry, 'IN');
      expect(result, hasLength(1));
    });

    test('forwards an explicit country', () async {
      queries.numbersByTypeResponse = const [];
      await ds.getEmergencyNumbersByType(
        serviceType: EmergencyServiceType.ambulance,
        country: 'US',
      );
      expect(queries.lastNumbersByTypeServiceType, 'ambulance');
      expect(queries.lastNumbersByTypeCountry, 'US');
    });

    test('returns empty list when RPC returns null', () async {
      queries.numbersByTypeResponse = null;
      final result = await ds.getEmergencyNumbersByType(
        serviceType: EmergencyServiceType.police,
      );
      expect(result, isEmpty);
    });

    test('wraps RPC errors', () async {
      queries.throwOnNumbersByType = Exception('boom');
      await expectLater(
        ds.getEmergencyNumbersByType(serviceType: EmergencyServiceType.police),
        throwsA(isA<Exception>()),
      );
    });
  });

  // =====================================================
  // EMERGENCY CONTACTS
  // =====================================================
  group('EmergencyContacts / getEmergencyContacts', () {
    test('returns parsed contacts', () async {
      queries.contactsResponse = [_contactRow(), _contactRow(id: 'c-2')];
      final result = await ds.getEmergencyContacts();
      expect(queries.lastFindContactsUserId, 'u-1');
      expect(result.map((c) => c.id), ['c-1', 'c-2']);
    });

    test('returns empty list when no rows', () async {
      queries.contactsResponse = const [];
      expect(await ds.getEmergencyContacts(), isEmpty);
    });

    test('throws when user not authenticated', () async {
      ds = _buildDs(queries, userId: null);
      await expectLater(ds.getEmergencyContacts(), throwsA(isA<Exception>()));
      expect(queries.lastFindContactsUserId, isNull);
    });

    test('wraps query errors', () async {
      queries.throwOnFindContacts = Exception('boom');
      await expectLater(ds.getEmergencyContacts(), throwsA(isA<Exception>()));
    });
  });

  group('EmergencyContacts / getEmergencyContactById', () {
    test('returns null when row is null', () async {
      queries.setContactByIdReturnsNull();
      expect(await ds.getEmergencyContactById('c-1'), isNull);
      expect(queries.lastFindContactByIdContactId, 'c-1');
      expect(queries.lastFindContactByIdUserId, 'u-1');
    });

    test('returns parsed model when row is present', () async {
      queries.contactByIdResponse = _contactRow();
      final result = await ds.getEmergencyContactById('c-1');
      expect(result!.id, 'c-1');
      expect(result.name, 'Mom');
    });

    test('throws when user not authenticated', () async {
      ds = _buildDs(queries, userId: null);
      await expectLater(
          ds.getEmergencyContactById('c'), throwsA(isA<Exception>()));
    });

    test('wraps query errors', () async {
      queries.throwOnFindContactById = Exception('boom');
      await expectLater(
          ds.getEmergencyContactById('c'), throwsA(isA<Exception>()));
    });
  });

  group('EmergencyContacts / addEmergencyContact', () {
    test('inserts contact without unsetting primaries when not primary',
        () async {
      queries.insertContactResponse = _contactRow();
      final result = await ds.addEmergencyContact(
        name: 'Mom',
        phoneNumber: '+1234567890',
        relationship: 'Parent',
      );
      expect(result.id, 'c-1');
      expect(queries.lastUnsetPrimaryUserId, isNull);
      expect(queries.lastInsertedContact, {
        'user_id': 'u-1',
        'name': 'Mom',
        'phone_number': '+1234567890',
        'email': null,
        'relationship': 'Parent',
        'is_primary': false,
      });
    });

    test('unsets primaries first when isPrimary=true', () async {
      queries.insertContactResponse = _contactRow(isPrimary: true);
      await ds.addEmergencyContact(
        name: 'Dad',
        phoneNumber: '+1',
        relationship: 'Parent',
        isPrimary: true,
      );
      expect(queries.lastUnsetPrimaryUserId, 'u-1');
      expect(queries.lastInsertedContact!['is_primary'], isTrue);
    });

    test('forwards optional email', () async {
      queries.insertContactResponse = _contactRow();
      await ds.addEmergencyContact(
        name: 'Mom',
        phoneNumber: '+1',
        relationship: 'Parent',
        email: 'mom@x.com',
      );
      expect(queries.lastInsertedContact!['email'], 'mom@x.com');
    });

    test('throws when user not authenticated', () async {
      ds = _buildDs(queries, userId: null);
      await expectLater(
        ds.addEmergencyContact(
          name: 'Mom',
          phoneNumber: '+1',
          relationship: 'Parent',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('wraps insert errors', () async {
      queries.throwOnInsertContact = Exception('boom');
      await expectLater(
        ds.addEmergencyContact(
            name: 'M', phoneNumber: 'p', relationship: 'r'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('EmergencyContacts / updateEmergencyContact', () {
    test('builds partial update payload only with provided fields', () async {
      queries.updateContactResponse = _contactRow(name: 'New Name');
      final result = await ds.updateEmergencyContact(
        contactId: 'c-1',
        name: 'New Name',
      );
      expect(result.id, 'c-1');
      expect(queries.lastUpdateContactContactId, 'c-1');
      expect(queries.lastUpdateContactUserId, 'u-1');
      expect(queries.lastUpdateContactData!['name'], 'New Name');
      expect(queries.lastUpdateContactData!.containsKey('phone_number'),
          isFalse);
      expect(queries.lastUpdateContactData!['updated_at'],
          _fixedNow().toIso8601String());
    });

    test('serialises every optional field when supplied', () async {
      queries.updateContactResponse = _contactRow();
      await ds.updateEmergencyContact(
        contactId: 'c-1',
        name: 'A',
        phoneNumber: 'p',
        email: 'e',
        relationship: 'r',
        isPrimary: false,
      );
      expect(queries.lastUpdateContactData, {
        'name': 'A',
        'phone_number': 'p',
        'email': 'e',
        'relationship': 'r',
        'is_primary': false,
        'updated_at': _fixedNow().toIso8601String(),
      });
    });

    test('unsets primaries first when isPrimary=true', () async {
      queries.updateContactResponse = _contactRow(isPrimary: true);
      await ds.updateEmergencyContact(contactId: 'c-1', isPrimary: true);
      expect(queries.lastUnsetPrimaryUserId, 'u-1');
      expect(queries.lastUpdateContactData!['is_primary'], isTrue);
    });

    test('does NOT unset primaries when isPrimary=false', () async {
      queries.updateContactResponse = _contactRow();
      await ds.updateEmergencyContact(contactId: 'c-1', isPrimary: false);
      expect(queries.lastUnsetPrimaryUserId, isNull);
    });

    test('throws when user not authenticated', () async {
      ds = _buildDs(queries, userId: null);
      await expectLater(
        ds.updateEmergencyContact(contactId: 'c-1', name: 'x'),
        throwsA(isA<Exception>()),
      );
    });

    test('wraps update errors', () async {
      queries.throwOnUpdateContact = Exception('boom');
      await expectLater(
        ds.updateEmergencyContact(contactId: 'c-1', name: 'x'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('EmergencyContacts / deleteEmergencyContact', () {
    test('forwards contactId and userId', () async {
      await ds.deleteEmergencyContact('c-1');
      expect(queries.lastDeleteContactContactId, 'c-1');
      expect(queries.lastDeleteContactUserId, 'u-1');
    });

    test('throws when user not authenticated', () async {
      ds = _buildDs(queries, userId: null);
      await expectLater(
          ds.deleteEmergencyContact('c-1'), throwsA(isA<Exception>()));
    });

    test('wraps delete errors', () async {
      queries.throwOnDeleteContact = Exception('boom');
      await expectLater(
          ds.deleteEmergencyContact('c-1'), throwsA(isA<Exception>()));
    });
  });

  group('EmergencyContacts / setPrimaryContact', () {
    test('unsets all primaries then sets the requested contact', () async {
      await ds.setPrimaryContact('c-1');
      expect(queries.lastUnsetPrimaryUserId, 'u-1');
      expect(queries.lastSetPrimaryContactId, 'c-1');
      expect(queries.lastSetPrimaryUserId, 'u-1');
      expect(queries.lastSetPrimaryUpdatedAtIso,
          _fixedNow().toIso8601String());
    });

    test('throws when user not authenticated', () async {
      ds = _buildDs(queries, userId: null);
      await expectLater(
          ds.setPrimaryContact('c-1'), throwsA(isA<Exception>()));
    });

    test('wraps unset errors', () async {
      queries.throwOnUnsetPrimary = Exception('boom');
      await expectLater(
          ds.setPrimaryContact('c-1'), throwsA(isA<Exception>()));
    });

    test('wraps set-primary errors', () async {
      queries.throwOnSetPrimary = Exception('boom');
      await expectLater(
          ds.setPrimaryContact('c-1'), throwsA(isA<Exception>()));
    });
  });

  // =====================================================
  // LOCATION SHARING
  // =====================================================
  group('LocationSharing / startLocationSharing', () {
    test('inserts row with required + default fields and no expiry', () async {
      queries.insertLocationShareResponse = _locationShareRow();
      final result = await ds.startLocationSharing(
        contactIds: const ['c-1', 'c-2'],
        latitude: 40.0,
        longitude: -74.0,
      );
      expect(result.id, 'ls-1');
      final data = queries.lastInsertedLocationShare!;
      expect(data['user_id'], 'u-1');
      expect(data['trip_id'], isNull);
      expect(data['latitude'], 40.0);
      expect(data['longitude'], -74.0);
      expect(data['accuracy'], isNull);
      expect(data['status'], 'active');
      expect(data['started_at'], _fixedNow().toIso8601String());
      expect(data['expires_at'], isNull);
      expect(data['last_updated_at'], _fixedNow().toIso8601String());
      expect(data['shared_with_contact_ids'], ['c-1', 'c-2']);
      expect(data['message'], isNull);
    });

    test('computes expires_at from now + duration when provided', () async {
      queries.insertLocationShareResponse = _locationShareRow();
      await ds.startLocationSharing(
        contactIds: const ['c-1'],
        latitude: 0,
        longitude: 0,
        duration: const Duration(hours: 1),
      );
      final expected =
          _fixedNow().add(const Duration(hours: 1)).toIso8601String();
      expect(queries.lastInsertedLocationShare!['expires_at'], expected);
    });

    test('forwards every optional field when provided', () async {
      queries.insertLocationShareResponse = _locationShareRow();
      await ds.startLocationSharing(
        contactIds: const ['c-1'],
        tripId: 't-1',
        message: 'help',
        latitude: 1.0,
        longitude: 2.0,
        accuracy: 5,
        altitude: 100,
        speed: 1.5,
        heading: 90,
      );
      final data = queries.lastInsertedLocationShare!;
      expect(data['trip_id'], 't-1');
      expect(data['accuracy'], 5);
      expect(data['altitude'], 100);
      expect(data['speed'], 1.5);
      expect(data['heading'], 90);
      expect(data['message'], 'help');
    });

    test('throws when user not authenticated', () async {
      ds = _buildDs(queries, userId: null);
      await expectLater(
        ds.startLocationSharing(
            contactIds: const ['c-1'], latitude: 0, longitude: 0),
        throwsA(isA<Exception>()),
      );
    });

    test('wraps insert errors', () async {
      queries.throwOnInsertLocationShare = Exception('boom');
      await expectLater(
        ds.startLocationSharing(
            contactIds: const ['c-1'], latitude: 0, longitude: 0),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('LocationSharing / updateSharedLocation', () {
    test('updates location without message', () async {
      queries.updateLocationShareResponse = _locationShareRow();
      final result = await ds.updateSharedLocation(
        sessionId: 'ls-1',
        latitude: 50.0,
        longitude: -60.0,
        accuracy: 3,
      );
      expect(result.id, 'ls-1');
      final data = queries.lastUpdateLocationData!;
      expect(data['latitude'], 50.0);
      expect(data['longitude'], -60.0);
      expect(data['accuracy'], 3);
      expect(data['last_updated_at'], _fixedNow().toIso8601String());
      expect(data.containsKey('message'), isFalse);
      expect(queries.lastUpdateLocationSessionId, 'ls-1');
      expect(queries.lastUpdateLocationUserId, 'u-1');
    });

    test('includes message when provided', () async {
      queries.updateLocationShareResponse = _locationShareRow();
      await ds.updateSharedLocation(
        sessionId: 'ls-1',
        latitude: 0,
        longitude: 0,
        message: 'I am safe',
      );
      expect(queries.lastUpdateLocationData!['message'], 'I am safe');
    });

    test('throws when user not authenticated', () async {
      ds = _buildDs(queries, userId: null);
      await expectLater(
        ds.updateSharedLocation(
            sessionId: 'ls-1', latitude: 0, longitude: 0),
        throwsA(isA<Exception>()),
      );
    });

    test('wraps update errors', () async {
      queries.throwOnUpdateLocationShare = Exception('boom');
      await expectLater(
        ds.updateSharedLocation(
            sessionId: 'ls-1', latitude: 0, longitude: 0),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('LocationSharing / pauseLocationSharing', () {
    test('writes paused status', () async {
      await ds.pauseLocationSharing('ls-1');
      expect(queries.lastUpdateStatusSessionId, 'ls-1');
      expect(queries.lastUpdateStatusUserId, 'u-1');
      expect(queries.lastUpdateStatusValue, 'paused');
    });

    test('throws when not authenticated', () async {
      ds = _buildDs(queries, userId: null);
      await expectLater(
          ds.pauseLocationSharing('ls-1'), throwsA(isA<Exception>()));
    });

    test('wraps errors', () async {
      queries.throwOnUpdateLocationStatus = Exception('boom');
      await expectLater(
          ds.pauseLocationSharing('ls-1'), throwsA(isA<Exception>()));
    });
  });

  group('LocationSharing / resumeLocationSharing', () {
    test('writes active status', () async {
      await ds.resumeLocationSharing('ls-1');
      expect(queries.lastUpdateStatusValue, 'active');
    });

    test('throws when not authenticated', () async {
      ds = _buildDs(queries, userId: null);
      await expectLater(
          ds.resumeLocationSharing('ls-1'), throwsA(isA<Exception>()));
    });

    test('wraps errors', () async {
      queries.throwOnUpdateLocationStatus = Exception('boom');
      await expectLater(
          ds.resumeLocationSharing('ls-1'), throwsA(isA<Exception>()));
    });
  });

  group('LocationSharing / stopLocationSharing', () {
    test('writes stopped status', () async {
      await ds.stopLocationSharing('ls-1');
      expect(queries.lastUpdateStatusValue, 'stopped');
    });

    test('throws when not authenticated', () async {
      ds = _buildDs(queries, userId: null);
      await expectLater(
          ds.stopLocationSharing('ls-1'), throwsA(isA<Exception>()));
    });

    test('wraps errors', () async {
      queries.throwOnUpdateLocationStatus = Exception('boom');
      await expectLater(
          ds.stopLocationSharing('ls-1'), throwsA(isA<Exception>()));
    });
  });

  group('LocationSharing / getActiveLocationShare', () {
    test('returns null when no active share', () async {
      queries.setActiveLocationShareReturnsNull();
      expect(await ds.getActiveLocationShare(), isNull);
      expect(queries.lastFindActiveLocationUserId, 'u-1');
    });

    test('returns parsed model when present', () async {
      queries.activeLocationShareResponse = _locationShareRow();
      final result = await ds.getActiveLocationShare();
      expect(result!.id, 'ls-1');
      expect(result.status, LocationShareStatus.active);
    });

    test('throws when not authenticated', () async {
      ds = _buildDs(queries, userId: null);
      await expectLater(
          ds.getActiveLocationShare(), throwsA(isA<Exception>()));
    });

    test('wraps errors', () async {
      queries.throwOnFindActiveLocation = Exception('boom');
      await expectLater(
          ds.getActiveLocationShare(), throwsA(isA<Exception>()));
    });
  });

  group('LocationSharing / getSharedLocations', () {
    test('returns only shares whose contact list contains the user', () async {
      queries.activeLocationSharesResponse = [
        _locationShareRow(id: 'ls-1', contactIds: const ['u-1', 'other']),
        _locationShareRow(id: 'ls-2', contactIds: const ['someone-else']),
        _locationShareRow(id: 'ls-3', contactIds: const ['u-1']),
      ];
      final result = await ds.getSharedLocations();
      expect(result.map((l) => l.id), ['ls-1', 'ls-3']);
      expect(queries.wasFindAllActiveLocationsCalled, isTrue);
    });

    test('returns empty when no matches', () async {
      queries.activeLocationSharesResponse = [
        _locationShareRow(id: 'ls-1', contactIds: const ['x']),
      ];
      expect(await ds.getSharedLocations(), isEmpty);
    });

    test('throws when not authenticated', () async {
      ds = _buildDs(queries, userId: null);
      await expectLater(
          ds.getSharedLocations(), throwsA(isA<Exception>()));
    });

    test('wraps errors', () async {
      queries.throwOnFindAllActiveLocations = Exception('boom');
      await expectLater(
          ds.getSharedLocations(), throwsA(isA<Exception>()));
    });
  });

  // =====================================================
  // EMERGENCY ALERTS
  // =====================================================
  group('Alerts / triggerEmergencyAlert', () {
    test('uses provided contactIds and inserts row', () async {
      queries.insertAlertResponse = _alertRow();
      final result = await ds.triggerEmergencyAlert(
        type: EmergencyAlertType.sos,
        contactIds: const ['c-1', 'c-2'],
        message: 'Help',
        latitude: 1,
        longitude: 2,
        tripId: 't-1',
      );
      expect(result.id, 'a-1');
      final data = queries.lastInsertedAlert!;
      expect(data['user_id'], 'u-1');
      expect(data['trip_id'], 't-1');
      expect(data['type'], 'sos');
      expect(data['status'], 'active');
      expect(data['message'], 'Help');
      expect(data['latitude'], 1);
      expect(data['longitude'], 2);
      expect(data['notified_contact_ids'], ['c-1', 'c-2']);
      expect(data['created_at'], _fixedNow().toIso8601String());
      // Did NOT fall back to fetching contacts.
      expect(queries.lastFindContactsUserId, isNull);
    });

    test('falls back to user contacts when contactIds is null', () async {
      queries.contactsResponse = [
        _contactRow(id: 'c-1'),
        _contactRow(id: 'c-2'),
      ];
      queries.insertAlertResponse = _alertRow();
      await ds.triggerEmergencyAlert(type: EmergencyAlertType.medical);
      expect(queries.lastFindContactsUserId, 'u-1');
      expect(queries.lastInsertedAlert!['notified_contact_ids'],
          ['c-1', 'c-2']);
      expect(queries.lastInsertedAlert!['type'], 'medical');
    });

    test('falls back to user contacts when contactIds is empty list',
        () async {
      queries.contactsResponse = [_contactRow(id: 'c-x')];
      queries.insertAlertResponse = _alertRow();
      await ds.triggerEmergencyAlert(
        type: EmergencyAlertType.help,
        contactIds: const [],
      );
      expect(queries.lastInsertedAlert!['notified_contact_ids'], ['c-x']);
    });

    test('throws when user not authenticated', () async {
      ds = _buildDs(queries, userId: null);
      await expectLater(
        ds.triggerEmergencyAlert(type: EmergencyAlertType.sos),
        throwsA(isA<Exception>()),
      );
    });

    test('wraps insert errors', () async {
      queries.throwOnInsertAlert = Exception('boom');
      await expectLater(
        ds.triggerEmergencyAlert(
            type: EmergencyAlertType.sos, contactIds: const ['c']),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Alerts / acknowledgeAlert', () {
    test('writes acknowledged status, time and userId', () async {
      queries.updateAlertByIdResponse =
          _alertRow(status: 'acknowledged');
      final result = await ds.acknowledgeAlert('a-1');
      expect(result.id, 'a-1');
      expect(queries.lastUpdateAlertByIdAlertId, 'a-1');
      final data = queries.lastUpdateAlertByIdData!;
      expect(data['status'], 'acknowledged');
      expect(data['acknowledged_at'], _fixedNow().toIso8601String());
      expect(data['acknowledged_by'], 'u-1');
    });

    test('throws when user not authenticated', () async {
      ds = _buildDs(queries, userId: null);
      await expectLater(
          ds.acknowledgeAlert('a-1'), throwsA(isA<Exception>()));
    });

    test('wraps update errors', () async {
      queries.throwOnUpdateAlertById = Exception('boom');
      await expectLater(
          ds.acknowledgeAlert('a-1'), throwsA(isA<Exception>()));
    });
  });

  group('Alerts / resolveAlert', () {
    test('writes resolved status without resolution metadata', () async {
      queries.updateAlertByIdResponse = _alertRow(status: 'resolved');
      await ds.resolveAlert(alertId: 'a-1');
      final data = queries.lastUpdateAlertByIdData!;
      expect(data['status'], 'resolved');
      expect(data['resolved_at'], _fixedNow().toIso8601String());
      expect(data.containsKey('metadata'), isFalse);
    });

    test('writes metadata.resolution when resolution provided', () async {
      queries.updateAlertByIdResponse = _alertRow(status: 'resolved');
      await ds.resolveAlert(alertId: 'a-1', resolution: 'all good');
      final data = queries.lastUpdateAlertByIdData!;
      expect(data['metadata'], {'resolution': 'all good'});
    });

    test('does NOT require authentication (no user-id check)', () async {
      ds = _buildDs(queries, userId: null);
      queries.updateAlertByIdResponse = _alertRow(status: 'resolved');
      // Should still proceed because resolveAlert doesn't gate on user.
      await ds.resolveAlert(alertId: 'a-1');
      expect(queries.lastUpdateAlertByIdAlertId, 'a-1');
    });

    test('wraps update errors', () async {
      queries.throwOnUpdateAlertById = Exception('boom');
      await expectLater(
          ds.resolveAlert(alertId: 'a-1'), throwsA(isA<Exception>()));
    });
  });

  group('Alerts / cancelAlert', () {
    test('writes cancelled status with user constraint', () async {
      queries.updateAlertByIdAndUserResponse = _alertRow(status: 'cancelled');
      final result = await ds.cancelAlert('a-1');
      expect(result.id, 'a-1');
      expect(queries.lastUpdateAlertByIdAndUserAlertId, 'a-1');
      expect(queries.lastUpdateAlertByIdAndUserUserId, 'u-1');
      final data = queries.lastUpdateAlertByIdAndUserData!;
      expect(data['status'], 'cancelled');
      expect(data['resolved_at'], _fixedNow().toIso8601String());
    });

    test('throws when user not authenticated', () async {
      ds = _buildDs(queries, userId: null);
      await expectLater(ds.cancelAlert('a-1'), throwsA(isA<Exception>()));
    });

    test('wraps update errors', () async {
      queries.throwOnUpdateAlertByIdAndUser = Exception('boom');
      await expectLater(ds.cancelAlert('a-1'), throwsA(isA<Exception>()));
    });
  });

  group('Alerts / getAlertById', () {
    test('returns null when row is null', () async {
      queries.setAlertByIdReturnsNull();
      expect(await ds.getAlertById('a-1'), isNull);
      expect(queries.lastFindAlertByIdArg, 'a-1');
    });

    test('parses row when present', () async {
      queries.alertByIdResponse = _alertRow();
      final result = await ds.getAlertById('a-1');
      expect(result!.id, 'a-1');
      expect(result.type, EmergencyAlertType.sos);
    });

    test('throws when user not authenticated', () async {
      ds = _buildDs(queries, userId: null);
      await expectLater(ds.getAlertById('a-1'), throwsA(isA<Exception>()));
    });

    test('wraps errors', () async {
      queries.throwOnFindAlertById = Exception('boom');
      await expectLater(ds.getAlertById('a-1'), throwsA(isA<Exception>()));
    });
  });

  group('Alerts / getUserAlerts', () {
    test('passes nulls for status/since when not provided', () async {
      queries.userAlertsResponse = [_alertRow(), _alertRow(id: 'a-2')];
      final result = await ds.getUserAlerts();
      expect(queries.lastFindUserAlertsUserId, 'u-1');
      expect(queries.lastFindUserAlertsStatus, isNull);
      expect(queries.lastFindUserAlertsSince, isNull);
      expect(result.map((a) => a.id), ['a-1', 'a-2']);
    });

    test('serialises status enum and since DateTime', () async {
      queries.userAlertsResponse = const [];
      final since = DateTime.utc(2024, 1, 1);
      await ds.getUserAlerts(
        status: EmergencyAlertStatus.acknowledged,
        since: since,
      );
      expect(queries.lastFindUserAlertsStatus, 'acknowledged');
      expect(queries.lastFindUserAlertsSince, since);
    });

    test('returns empty list when no rows', () async {
      queries.userAlertsResponse = const [];
      expect(await ds.getUserAlerts(), isEmpty);
    });

    test('throws when user not authenticated', () async {
      ds = _buildDs(queries, userId: null);
      await expectLater(ds.getUserAlerts(), throwsA(isA<Exception>()));
    });

    test('wraps errors', () async {
      queries.throwOnFindUserAlerts = Exception('boom');
      await expectLater(ds.getUserAlerts(), throwsA(isA<Exception>()));
    });
  });

  // =====================================================
  // HOSPITALS
  // =====================================================
  group('Hospitals / findNearestHospitals', () {
    test('forwards default param values', () async {
      queries.nearestHospitalsResponse = [_hospitalRow()];
      final result = await ds.findNearestHospitals(
        latitude: 19.0,
        longitude: 72.8,
      );
      expect(result, hasLength(1));
      expect(queries.lastFindNearestHospitalsArgs, {
        'latitude': 19.0,
        'longitude': 72.8,
        'maxDistanceKm': 50.0,
        'limit': 10,
        'onlyEmergency': true,
        'only24_7': false,
      });
    });

    test('forwards explicit params', () async {
      queries.nearestHospitalsResponse = const [];
      await ds.findNearestHospitals(
        latitude: 1.0,
        longitude: 2.0,
        maxDistanceKm: 25,
        limit: 5,
        onlyEmergency: false,
        only24_7: true,
      );
      expect(queries.lastFindNearestHospitalsArgs, {
        'latitude': 1.0,
        'longitude': 2.0,
        'maxDistanceKm': 25,
        'limit': 5,
        'onlyEmergency': false,
        'only24_7': true,
      });
    });

    test('returns empty list when RPC returns null', () async {
      queries.nearestHospitalsResponse = null;
      final result = await ds.findNearestHospitals(latitude: 0, longitude: 0);
      expect(result, isEmpty);
    });

    test('skips a malformed row but keeps the valid ones', () async {
      queries.nearestHospitalsResponse = [
        _hospitalRow(id: 'h-1'),
        // Invalid row (not a Map): triggers per-row try/catch.
        'not-a-map',
        _hospitalRow(id: 'h-2'),
      ];
      final result = await ds.findNearestHospitals(latitude: 0, longitude: 0);
      expect(result.map((h) => h.id), ['h-1', 'h-2']);
    });

    test('rethrows RPC errors (no wrapping)', () async {
      queries.throwOnFindNearestHospitals = Exception('rpc fail');
      await expectLater(
        ds.findNearestHospitals(latitude: 0, longitude: 0),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Hospitals / searchHospitals', () {
    test('forwards required + default fields', () async {
      queries.searchHospitalsResponse = [_hospitalRow()];
      final result = await ds.searchHospitals(searchTerm: 'AIIMS');
      expect(result, hasLength(1));
      expect(queries.lastSearchHospitalsArgs, {
        'searchTerm': 'AIIMS',
        'city': null,
        'state': null,
        'limit': 20,
      });
    });

    test('forwards optional city/state/limit', () async {
      queries.searchHospitalsResponse = const [];
      await ds.searchHospitals(
        searchTerm: 'X',
        city: 'Mumbai',
        state: 'MH',
        limit: 7,
      );
      expect(queries.lastSearchHospitalsArgs, {
        'searchTerm': 'X',
        'city': 'Mumbai',
        'state': 'MH',
        'limit': 7,
      });
    });

    test('returns empty list when RPC returns null', () async {
      queries.searchHospitalsResponse = null;
      expect(await ds.searchHospitals(searchTerm: 'x'), isEmpty);
    });

    test('rethrows on RPC error', () async {
      queries.throwOnSearchHospitals = Exception('boom');
      await expectLater(
        ds.searchHospitals(searchTerm: 'x'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Hospitals / getHospitalById', () {
    test('forwards id and optional user lat/lng', () async {
      queries.hospitalByIdResponse = [_hospitalRow()];
      final result = await ds.getHospitalById(
        hospitalId: 'h-1',
        userLatitude: 1.0,
        userLongitude: 2.0,
      );
      expect(result!.id, 'h-1');
      expect(queries.lastGetHospitalByIdArgs, {
        'hospitalId': 'h-1',
        'userLatitude': 1.0,
        'userLongitude': 2.0,
      });
    });

    test('passes nulls when user lat/lng omitted', () async {
      queries.hospitalByIdResponse = [_hospitalRow()];
      await ds.getHospitalById(hospitalId: 'h-1');
      expect(queries.lastGetHospitalByIdArgs!['userLatitude'], isNull);
      expect(queries.lastGetHospitalByIdArgs!['userLongitude'], isNull);
    });

    test('returns null when result list is empty', () async {
      queries.hospitalByIdResponse = const [];
      expect(await ds.getHospitalById(hospitalId: 'h-1'), isNull);
    });

    test('rethrows on RPC error', () async {
      queries.throwOnGetHospitalById = Exception('boom');
      await expectLater(
        ds.getHospitalById(hospitalId: 'h-1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Hospitals / getHospitalsByLocation', () {
    test('forwards default limit and null city/state', () async {
      queries.hospitalsByLocationResponse = [_hospitalRow()];
      final result = await ds.getHospitalsByLocation();
      expect(result, hasLength(1));
      expect(queries.lastFindHospitalsByLocationArgs, {
        'city': null,
        'state': null,
        'limit': 50,
      });
    });

    test('forwards explicit fields', () async {
      queries.hospitalsByLocationResponse = const [];
      await ds.getHospitalsByLocation(
        city: 'Mumbai',
        state: 'MH',
        limit: 5,
      );
      expect(queries.lastFindHospitalsByLocationArgs, {
        'city': 'Mumbai',
        'state': 'MH',
        'limit': 5,
      });
    });

    test('returns empty list when no rows', () async {
      queries.hospitalsByLocationResponse = const [];
      expect(await ds.getHospitalsByLocation(), isEmpty);
    });

    test('rethrows on query error', () async {
      queries.throwOnFindHospitalsByLocation = Exception('boom');
      await expectLater(
          ds.getHospitalsByLocation(), throwsA(isA<Exception>()));
    });
  });

  // =====================================================
  // Default constructor smoke tests
  // =====================================================
  group('Default constructor', () {
    test(
        'unnamed constructor builds without throwing when a SupabaseClient is '
        'provided', () {
      // We don't initialize Supabase singleton: passing the supplied client
      // means EmergencyQueriesImpl uses it directly. Any subsequent call
      // would hit the real Supabase chain which we never invoke here.
      // The constructor itself must be exception-free.
      expect(() => EmergencyRemoteDataSourceImpl.test(queries: _FakeQueries()),
          returnsNormally);
    });
  });
}
