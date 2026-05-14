import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:pathio/core/services/email_service.dart';
import 'package:pathio/features/trip_invites/data/datasources/invite_queries.dart';
import 'package:pathio/features/trip_invites/data/datasources/invite_remote_datasource.dart';

/// Comprehensive unit tests for [InviteRemoteDataSource].
///
/// All Supabase chain calls go through [InviteQueries] which is faked here.
/// EmailService is also faked. We exercise every public method on the
/// happy path AND the error path, asserting both the args passed to the
/// queries layer and the model returned.

class _FakeQueries implements InviteQueries {
  Map<String, dynamic>? lastInsertedInvite;
  String? lastTripDetailsRequestedFor;
  String? lastProfileRequestedFor;
  String? lastInviteCodeStrict;
  String? lastInviteCodeMaybe;
  String? lastUpdateByIdId;
  Map<String, dynamic>? lastUpdateByIdData;
  String? lastUpdateByCodeCode;
  Map<String, dynamic>? lastUpdateByCodeData;
  String? lastUpdateReturningId;
  Map<String, dynamic>? lastUpdateReturningData;
  Map<String, dynamic>? lastTripMember;
  String? lastFindInvitesForTripId;
  String? lastFindInvitesForTripGte;
  String? lastFindInvitesByInviterUserId;
  String? lastPendingEmailEmail;
  String? lastPendingEmailGte;
  String? lastDeleteExpiredAtLt;
  String? lastDeleteExpiredTripId;

  Map<String, dynamic>? insertInviteResponse;
  Map<String, dynamic>? tripDetailsResponse;
  Map<String, dynamic>? profileResponse;
  Map<String, dynamic>? findStrictResponse;
  Map<String, dynamic>? findMaybeResponse; // null = not found
  bool _findMaybeReturnNull = false;
  Map<String, dynamic>? updateReturningResponse;
  List<Map<String, dynamic>> findInvitesForTripResponse = const [];
  List<Map<String, dynamic>> findInvitesByInviterResponse = const [];
  List<Map<String, dynamic>> pendingForEmailResponse = const [];

  Object? throwOnInsert;
  Object? throwOnTripDetails;
  Object? throwOnProfile;
  Object? throwOnFindStrict;
  Object? throwOnFindMaybe;
  Object? throwOnUpdateById;
  Object? throwOnUpdateByCode;
  Object? throwOnUpdateReturning;
  Object? throwOnAddMember;
  Object? throwOnFindInvitesForTrip;
  Object? throwOnFindInvitesByInviter;
  Object? throwOnPendingForEmail;
  Object? throwOnDeleteExpired;

  void setFindMaybeReturnNull() => _findMaybeReturnNull = true;

  @override
  Future<Map<String, dynamic>> insertInvite(Map<String, dynamic> data) async {
    if (throwOnInsert != null) throw throwOnInsert!;
    lastInsertedInvite = data;
    return insertInviteResponse ?? data;
  }

  @override
  Future<Map<String, dynamic>> getTripDetailsById(String tripId) async {
    if (throwOnTripDetails != null) throw throwOnTripDetails!;
    lastTripDetailsRequestedFor = tripId;
    return tripDetailsResponse ?? const {};
  }

  @override
  Future<Map<String, dynamic>> getProfileById(String userId) async {
    if (throwOnProfile != null) throw throwOnProfile!;
    lastProfileRequestedFor = userId;
    return profileResponse ?? const {};
  }

  @override
  Future<Map<String, dynamic>> findInviteByCodeStrict(String code) async {
    if (throwOnFindStrict != null) throw throwOnFindStrict!;
    lastInviteCodeStrict = code;
    return findStrictResponse ?? const {};
  }

  @override
  Future<Map<String, dynamic>?> findInviteByCodeMaybe(String code) async {
    if (throwOnFindMaybe != null) throw throwOnFindMaybe!;
    lastInviteCodeMaybe = code;
    if (_findMaybeReturnNull) return null;
    return findMaybeResponse;
  }

  @override
  Future<void> updateInviteById(String id, Map<String, dynamic> data) async {
    if (throwOnUpdateById != null) throw throwOnUpdateById!;
    lastUpdateByIdId = id;
    lastUpdateByIdData = data;
  }

  @override
  Future<void> updateInviteByCode(
      String code, Map<String, dynamic> data) async {
    if (throwOnUpdateByCode != null) throw throwOnUpdateByCode!;
    lastUpdateByCodeCode = code;
    lastUpdateByCodeData = data;
  }

  @override
  Future<Map<String, dynamic>> updateInviteByIdReturning(
      String id, Map<String, dynamic> data) async {
    if (throwOnUpdateReturning != null) throw throwOnUpdateReturning!;
    lastUpdateReturningId = id;
    lastUpdateReturningData = data;
    return updateReturningResponse ?? const {};
  }

  @override
  Future<void> addTripMember(Map<String, dynamic> data) async {
    if (throwOnAddMember != null) throw throwOnAddMember!;
    lastTripMember = data;
  }

  @override
  Future<List<Map<String, dynamic>>> findInvitesForTrip(
    String tripId, {
    String? expiresAtGte,
  }) async {
    if (throwOnFindInvitesForTrip != null) throw throwOnFindInvitesForTrip!;
    lastFindInvitesForTripId = tripId;
    lastFindInvitesForTripGte = expiresAtGte;
    return findInvitesForTripResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findInvitesByInviter(
      String userId) async {
    if (throwOnFindInvitesByInviter != null) {
      throw throwOnFindInvitesByInviter!;
    }
    lastFindInvitesByInviterUserId = userId;
    return findInvitesByInviterResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findPendingInvitesForEmail(
      String email, String expiresAtGte) async {
    if (throwOnPendingForEmail != null) throw throwOnPendingForEmail!;
    lastPendingEmailEmail = email;
    lastPendingEmailGte = expiresAtGte;
    return pendingForEmailResponse;
  }

  @override
  Future<void> deleteInvitesExpiredBefore(
    String expiresAtLt, {
    String? tripId,
  }) async {
    if (throwOnDeleteExpired != null) throw throwOnDeleteExpired!;
    lastDeleteExpiredAtLt = expiresAtLt;
    lastDeleteExpiredTripId = tripId;
  }
}

class _FakeEmailService extends Fake implements EmailService {
  bool succeed = true;
  Object? throwOnSend;
  String? lastToEmail;
  String? lastToName;
  String? lastTripName;
  String? lastInviterName;
  String? lastInviteCode;
  String? lastDestination;
  String? lastStartDate;
  String? lastEndDate;

  @override
  Future<bool> sendTripInvite({
    required String toEmail,
    required String toName,
    required String tripName,
    required String inviterName,
    required String inviteCode,
    String? tripDestination,
    String? tripStartDate,
    String? tripEndDate,
  }) async {
    if (throwOnSend != null) throw throwOnSend!;
    lastToEmail = toEmail;
    lastToName = toName;
    lastTripName = tripName;
    lastInviterName = inviterName;
    lastInviteCode = inviteCode;
    lastDestination = tripDestination;
    lastStartDate = tripStartDate;
    lastEndDate = tripEndDate;
    return succeed;
  }
}

class _FakeAuth extends Mock implements GoTrueClient {
  _FakeAuth([this._user]);
  final User? _user;
  @override
  User? get currentUser => _user;
}

class _FakeUser extends Fake implements User {
  _FakeUser(this._id);
  final String _id;
  @override
  String get id => _id;
}

class _FakeSupabase extends Fake implements SupabaseClient {
  _FakeSupabase(this._auth);
  final GoTrueClient _auth;
  @override
  GoTrueClient get auth => _auth;
}

void main() {
  late _FakeQueries queries;
  late _FakeEmailService email;
  late _FakeSupabase supabase;
  late InviteRemoteDataSource ds;
  final fixedClock = DateTime.utc(2024, 6, 1, 12, 0, 0);

  void setUpDs({User? user, String? code}) {
    supabase = _FakeSupabase(_FakeAuth(user ?? _FakeUser('inviter-1')));
    ds = InviteRemoteDataSource(
      supabase,
      queries: queries,
      emailService: email,
      uuid: const Uuid(),
      clock: () => fixedClock,
      codeGenerator: code != null ? () => code : null,
    );
  }

  setUp(() {
    queries = _FakeQueries();
    email = _FakeEmailService();
    setUpDs();
  });

  group('createInvite', () {
    test('throws when no user authenticated', () async {
      setUpDs(user: null);
      // No-op _FakeUser=null; but our setUpDs signature takes a User? so:
      supabase = _FakeSupabase(_FakeAuth(null));
      ds = InviteRemoteDataSource(supabase,
          queries: queries, emailService: email, clock: () => fixedClock);
      await expectLater(
        ds.createInvite(tripId: 't', email: 'a@b.com'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('User not authenticated'))),
      );
    });

    test('inserts the invite with all expected fields', () async {
      setUpDs(code: 'CODE1234');
      queries.insertInviteResponse = {
        'id': 'inv-1',
        'trip_id': 't',
        'invited_by': 'inviter-1',
        'email': 'a@b.com',
        'phone_number': null,
        'status': 'pending',
        'invite_code': 'CODE1234',
        'created_at': fixedClock.toIso8601String(),
        'expires_at':
            fixedClock.add(const Duration(days: 7)).toIso8601String(),
      };
      queries.tripDetailsResponse = {
        'name': 'Bali Trip',
        'destination': 'Bali',
        'start_date': '2024-07-01T00:00:00.000',
        'end_date': '2024-07-08T00:00:00.000',
      };
      queries.profileResponse = {'full_name': 'Alice'};

      final result = await ds.createInvite(
        tripId: 't',
        email: 'first.second@example.com',
      );

      expect(queries.lastInsertedInvite!['trip_id'], 't');
      expect(queries.lastInsertedInvite!['invited_by'], 'inviter-1');
      expect(queries.lastInsertedInvite!['email'], 'first.second@example.com');
      expect(queries.lastInsertedInvite!['status'], 'pending');
      expect(queries.lastInsertedInvite!['invite_code'], 'CODE1234');
      expect(result.id, 'inv-1');
      expect(result.inviteCode, 'CODE1234');
    });

    test('forwards email with capitalized recipient name and formatted dates',
        () async {
      setUpDs(code: 'CODE9999');
      queries.insertInviteResponse = {
        'id': 'inv-1',
        'trip_id': 't',
        'invited_by': 'inviter-1',
        'email': 'first.second@example.com',
        'status': 'pending',
        'invite_code': 'CODE9999',
        'created_at': fixedClock.toIso8601String(),
        'expires_at':
            fixedClock.add(const Duration(days: 7)).toIso8601String(),
      };
      queries.tripDetailsResponse = {
        'name': 'Bali Trip',
        'destination': 'Bali',
        'start_date': '2024-07-01T00:00:00.000',
        'end_date': '2024-07-08T00:00:00.000',
      };
      queries.profileResponse = {'full_name': 'Alice Wonder'};

      await ds.createInvite(
          tripId: 't', email: 'first.second@example.com');

      expect(email.lastToEmail, 'first.second@example.com');
      expect(email.lastToName, 'First Second');
      expect(email.lastTripName, 'Bali Trip');
      expect(email.lastInviterName, 'Alice Wonder');
      expect(email.lastInviteCode, 'CODE9999');
      expect(email.lastDestination, 'Bali');
      expect(email.lastStartDate, 'Jul 1, 2024');
      expect(email.lastEndDate, 'Jul 8, 2024');
    });

    test('uses defaults "Trip" / "Someone" when name fields are missing',
        () async {
      queries.insertInviteResponse = {
        'id': 'i',
        'trip_id': 't',
        'invited_by': 'inviter-1',
        'email': 'x@y.com',
        'status': 'pending',
        'invite_code': 'C',
        'created_at': fixedClock.toIso8601String(),
        'expires_at':
            fixedClock.add(const Duration(days: 7)).toIso8601String(),
      };
      queries.tripDetailsResponse = const <String, dynamic>{};
      queries.profileResponse = const <String, dynamic>{};

      await ds.createInvite(tripId: 't', email: 'x@y.com');

      expect(email.lastTripName, 'Trip');
      expect(email.lastInviterName, 'Someone');
      expect(email.lastDestination, isNull);
      expect(email.lastStartDate, isNull);
      expect(email.lastEndDate, isNull);
    });

    test('returns the created invite even if email send returns false',
        () async {
      queries.insertInviteResponse = {
        'id': 'inv-1',
        'trip_id': 't',
        'invited_by': 'inviter-1',
        'email': 'x@y.com',
        'status': 'pending',
        'invite_code': 'C',
        'created_at': fixedClock.toIso8601String(),
        'expires_at':
            fixedClock.add(const Duration(days: 7)).toIso8601String(),
      };
      queries.tripDetailsResponse = {'name': 'T'};
      queries.profileResponse = {'full_name': 'A'};
      email.succeed = false;

      final result = await ds.createInvite(tripId: 't', email: 'x@y.com');
      expect(result.id, 'inv-1');
    });

    test('returns the created invite even if email send throws', () async {
      queries.insertInviteResponse = {
        'id': 'inv-1',
        'trip_id': 't',
        'invited_by': 'inviter-1',
        'email': 'x@y.com',
        'status': 'pending',
        'invite_code': 'C',
        'created_at': fixedClock.toIso8601String(),
        'expires_at':
            fixedClock.add(const Duration(days: 7)).toIso8601String(),
      };
      queries.tripDetailsResponse = {'name': 'T'};
      queries.profileResponse = {'full_name': 'A'};
      email.throwOnSend = Exception('SMTP down');

      final result = await ds.createInvite(tripId: 't', email: 'x@y.com');
      expect(result.id, 'inv-1');
    });

    test('respects custom expiresInDays', () async {
      queries.insertInviteResponse = {
        'id': 'inv-1',
        'trip_id': 't',
        'invited_by': 'inviter-1',
        'email': 'x@y.com',
        'status': 'pending',
        'invite_code': 'C',
        'created_at': fixedClock.toIso8601String(),
        'expires_at':
            fixedClock.add(const Duration(days: 30)).toIso8601String(),
      };
      queries.tripDetailsResponse = {'name': 'T'};
      queries.profileResponse = {'full_name': 'A'};

      await ds.createInvite(
          tripId: 't', email: 'x@y.com', expiresInDays: 30);

      final expires =
          DateTime.parse(queries.lastInsertedInvite!['expires_at'] as String);
      expect(
          expires.difference(fixedClock), const Duration(days: 30));
    });

    test('wraps query errors with "Failed to create invite"', () async {
      queries.throwOnInsert = Exception('boom');
      await expectLater(
        ds.createInvite(tripId: 't', email: 'x@y.com'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to create invite'))),
      );
    });

    test('formats malformed dates as the original string', () async {
      queries.insertInviteResponse = {
        'id': 'inv-1',
        'trip_id': 't',
        'invited_by': 'inviter-1',
        'email': 'x@y.com',
        'status': 'pending',
        'invite_code': 'C',
        'created_at': fixedClock.toIso8601String(),
        'expires_at':
            fixedClock.add(const Duration(days: 7)).toIso8601String(),
      };
      queries.tripDetailsResponse = {
        'name': 'T',
        'start_date': 'NOT-A-DATE',
        'end_date': '2024-07-08T00:00:00.000',
      };
      queries.profileResponse = {'full_name': 'A'};

      await ds.createInvite(tripId: 't', email: 'x@y.com');

      expect(email.lastStartDate, 'NOT-A-DATE');
      expect(email.lastEndDate, 'Jul 8, 2024');
    });

    test('handles email with underscore in local part', () async {
      queries.insertInviteResponse = {
        'id': 'inv-1',
        'trip_id': 't',
        'invited_by': 'inviter-1',
        'email': 'jane_doe@x.com',
        'status': 'pending',
        'invite_code': 'C',
        'created_at': fixedClock.toIso8601String(),
        'expires_at':
            fixedClock.add(const Duration(days: 7)).toIso8601String(),
      };
      queries.tripDetailsResponse = {'name': 'T'};
      queries.profileResponse = {'full_name': 'A'};

      await ds.createInvite(tripId: 't', email: 'jane_doe@x.com');

      expect(email.lastToName, 'Jane Doe');
    });
  });

  group('acceptInvite', () {
    Map<String, dynamic> validInvite() => {
          'id': 'inv-1',
          'trip_id': 't-1',
          'invited_by': 'inviter-1',
          'email': 'x@y.com',
          'status': 'pending',
          'invite_code': 'C123',
          'created_at': fixedClock.toIso8601String(),
          'expires_at':
              fixedClock.add(const Duration(days: 1)).toIso8601String(),
        };

    test('updates status, adds member, returns refreshed invite', () async {
      queries.findStrictResponse = validInvite();

      final result = await ds.acceptInvite(
          inviteCode: 'C123', userId: 'user-2');

      expect(queries.lastUpdateByIdId, 'inv-1');
      expect(queries.lastUpdateByIdData, {'status': 'accepted'});
      expect(queries.lastTripMember!['trip_id'], 't-1');
      expect(queries.lastTripMember!['user_id'], 'user-2');
      expect(queries.lastTripMember!['role'], 'member');
      expect(queries.lastTripMember!['joined_at'],
          fixedClock.toIso8601String());
      expect(result.id, 'inv-1');
    });

    test('rejects an expired invite', () async {
      final expired = validInvite();
      expired['expires_at'] =
          fixedClock.subtract(const Duration(days: 1)).toIso8601String();
      queries.findStrictResponse = expired;

      await expectLater(
        ds.acceptInvite(inviteCode: 'C123', userId: 'u'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('expired'))),
      );
    });

    test('rejects an already-used invite', () async {
      final used = validInvite()..['status'] = 'accepted';
      queries.findStrictResponse = used;

      await expectLater(
        ds.acceptInvite(inviteCode: 'C123', userId: 'u'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('already'))),
      );
    });

    test('wraps query errors', () async {
      queries.throwOnFindStrict = Exception('boom');
      await expectLater(
        ds.acceptInvite(inviteCode: 'C', userId: 'u'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to accept'))),
      );
    });
  });

  group('rejectInvite', () {
    test('issues an update by code', () async {
      await ds.rejectInvite(inviteCode: 'C123', userId: 'u');
      expect(queries.lastUpdateByCodeCode, 'C123');
      expect(queries.lastUpdateByCodeData, {'status': 'rejected'});
    });

    test('wraps query errors', () async {
      queries.throwOnUpdateByCode = Exception('boom');
      await expectLater(
        ds.rejectInvite(inviteCode: 'C', userId: 'u'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to reject'))),
      );
    });
  });

  group('revokeInvite', () {
    test('issues an update by id', () async {
      await ds.revokeInvite(inviteId: 'inv-1', userId: 'u');
      expect(queries.lastUpdateByIdId, 'inv-1');
      expect(queries.lastUpdateByIdData, {'status': 'revoked'});
    });

    test('wraps query errors', () async {
      queries.throwOnUpdateById = Exception('boom');
      await expectLater(
        ds.revokeInvite(inviteId: 'i', userId: 'u'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to revoke'))),
      );
    });
  });

  group('getTripInvites', () {
    test('passes expires_at gte clock when not includeExpired (default)',
        () async {
      queries.findInvitesForTripResponse = [];
      await ds.getTripInvites(tripId: 't');
      expect(queries.lastFindInvitesForTripId, 't');
      expect(queries.lastFindInvitesForTripGte,
          fixedClock.toIso8601String());
    });

    test('omits gte filter when includeExpired is true', () async {
      queries.findInvitesForTripResponse = [];
      await ds.getTripInvites(tripId: 't', includeExpired: true);
      expect(queries.lastFindInvitesForTripGte, isNull);
    });

    test('returns mapped models', () async {
      queries.findInvitesForTripResponse = [
        {
          'id': 'inv-1',
          'trip_id': 't',
          'invited_by': 'u',
          'email': 'x@y.com',
          'status': 'pending',
          'invite_code': 'C',
          'created_at': fixedClock.toIso8601String(),
          'expires_at': fixedClock
              .add(const Duration(days: 7))
              .toIso8601String(),
        },
      ];
      final result = await ds.getTripInvites(tripId: 't');
      expect(result, hasLength(1));
      expect(result.single.id, 'inv-1');
    });

    test('wraps errors', () async {
      queries.throwOnFindInvitesForTrip = Exception('boom');
      await expectLater(
        ds.getTripInvites(tripId: 't'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to get trip invites'))),
      );
    });
  });

  group('getInviteByCode', () {
    test('returns null when query returns null', () async {
      queries.setFindMaybeReturnNull();
      expect(await ds.getInviteByCode('C'), isNull);
    });

    test('returns parsed model when found', () async {
      queries.findMaybeResponse = {
        'id': 'inv-1',
        'trip_id': 't',
        'invited_by': 'u',
        'email': 'x@y.com',
        'status': 'pending',
        'invite_code': 'C',
        'created_at': fixedClock.toIso8601String(),
        'expires_at':
            fixedClock.add(const Duration(days: 7)).toIso8601String(),
      };
      final result = await ds.getInviteByCode('C');
      expect(result, isNotNull);
      expect(result!.id, 'inv-1');
    });

    test('wraps errors', () async {
      queries.throwOnFindMaybe = Exception('boom');
      await expectLater(
        ds.getInviteByCode('C'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to get invite'))),
      );
    });
  });

  group('getInvitesSentByUser', () {
    test('returns mapped list', () async {
      queries.findInvitesByInviterResponse = [
        {
          'id': 'inv-1',
          'trip_id': 't',
          'invited_by': 'u',
          'email': 'x@y.com',
          'status': 'pending',
          'invite_code': 'C',
          'created_at': fixedClock.toIso8601String(),
          'expires_at': fixedClock
              .add(const Duration(days: 7))
              .toIso8601String(),
        },
      ];
      final result = await ds.getInvitesSentByUser('u');
      expect(result, hasLength(1));
      expect(queries.lastFindInvitesByInviterUserId, 'u');
    });

    test('wraps errors', () async {
      queries.throwOnFindInvitesByInviter = Exception('boom');
      await expectLater(
        ds.getInvitesSentByUser('u'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to get user invites'))),
      );
    });
  });

  group('getPendingInvitesForEmail', () {
    test('passes through email and gte clock', () async {
      queries.pendingForEmailResponse = [];
      await ds.getPendingInvitesForEmail('x@y.com');
      expect(queries.lastPendingEmailEmail, 'x@y.com');
      expect(queries.lastPendingEmailGte, fixedClock.toIso8601String());
    });

    test('wraps errors', () async {
      queries.throwOnPendingForEmail = Exception('boom');
      await expectLater(
        ds.getPendingInvitesForEmail('x@y.com'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to get pending invites'))),
      );
    });
  });

  group('resendInvite', () {
    test('updates created_at and expires_at by id, returns parsed model',
        () async {
      queries.updateReturningResponse = {
        'id': 'inv-1',
        'trip_id': 't',
        'invited_by': 'u',
        'email': 'x@y.com',
        'status': 'pending',
        'invite_code': 'C',
        'created_at': fixedClock.toIso8601String(),
        'expires_at':
            fixedClock.add(const Duration(days: 7)).toIso8601String(),
      };
      final result = await ds.resendInvite('inv-1');
      expect(queries.lastUpdateReturningId, 'inv-1');
      expect(queries.lastUpdateReturningData!['created_at'],
          fixedClock.toIso8601String());
      expect(queries.lastUpdateReturningData!['expires_at'],
          fixedClock.add(const Duration(days: 7)).toIso8601String());
      expect(result.id, 'inv-1');
    });

    test('wraps errors', () async {
      queries.throwOnUpdateReturning = Exception('boom');
      await expectLater(
        ds.resendInvite('inv-1'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to resend invite'))),
      );
    });
  });

  group('deleteExpiredInvites', () {
    test('deletes with clock as expires_at threshold and no trip filter',
        () async {
      await ds.deleteExpiredInvites();
      expect(queries.lastDeleteExpiredAtLt, fixedClock.toIso8601String());
      expect(queries.lastDeleteExpiredTripId, isNull);
    });

    test('passes through tripId filter when provided', () async {
      await ds.deleteExpiredInvites(tripId: 't-1');
      expect(queries.lastDeleteExpiredTripId, 't-1');
    });

    test('wraps errors', () async {
      queries.throwOnDeleteExpired = Exception('boom');
      await expectLater(
        ds.deleteExpiredInvites(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to delete expired invites'))),
      );
    });
  });

  group('Default invite-code generator', () {
    test('produces an 8-char code from chars in [A-Z2-9 minus I,O,0,1]',
        () async {
      // Use the no-codeGenerator path and assert the inserted code matches
      // the expected character set + length.
      ds = InviteRemoteDataSource(supabase,
          queries: queries,
          emailService: email,
          uuid: const Uuid(),
          clock: () => fixedClock);
      queries.insertInviteResponse = {
        'id': 'i',
        'trip_id': 't',
        'invited_by': 'inviter-1',
        'email': 'x@y.com',
        'status': 'pending',
        'invite_code': 'WHATEVER',
        'created_at': fixedClock.toIso8601String(),
        'expires_at':
            fixedClock.add(const Duration(days: 7)).toIso8601String(),
      };
      queries.tripDetailsResponse = {'name': 'T'};
      queries.profileResponse = {'full_name': 'A'};

      await ds.createInvite(tripId: 't', email: 'x@y.com');

      final generated = queries.lastInsertedInvite!['invite_code'] as String;
      expect(generated, hasLength(8));
      expect(generated, matches(RegExp(r'^[A-HJ-NP-Z2-9]+$')));
    });
  });
}
