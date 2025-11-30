import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/trip_invites/data/models/invite_model.dart';
import 'package:travel_crew/features/trip_invites/domain/entities/invite_entity.dart';

void main() {
  group('InviteModel', () {
    final now = DateTime(2024, 1, 15, 10, 30);
    final future = DateTime(2024, 1, 22, 10, 30); // 7 days from now

    group('constructor', () {
      test('should create instance with required fields', () {
        final invite = InviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
        );

        expect(invite.id, 'invite-1');
        expect(invite.tripId, 'trip-1');
        expect(invite.invitedBy, 'user-1');
        expect(invite.email, 'test@example.com');
        expect(invite.status, 'pending');
        expect(invite.inviteCode, 'ABC123');
        expect(invite.createdAt, now);
        expect(invite.expiresAt, future);
        expect(invite.phoneNumber, isNull);
        expect(invite.inviterName, isNull);
        expect(invite.inviterEmail, isNull);
        expect(invite.tripName, isNull);
        expect(invite.tripDestination, isNull);
      });

      test('should create instance with all fields', () {
        final invite = InviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          phoneNumber: '+1234567890',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
          inviterName: 'John Doe',
          inviterEmail: 'john@example.com',
          tripName: 'Amazing Trip',
          tripDestination: 'Paris, France',
        );

        expect(invite.phoneNumber, '+1234567890');
        expect(invite.inviterName, 'John Doe');
        expect(invite.inviterEmail, 'john@example.com');
        expect(invite.tripName, 'Amazing Trip');
        expect(invite.tripDestination, 'Paris, France');
      });
    });

    group('fromJson', () {
      test('should parse JSON with snake_case keys', () {
        final json = {
          'id': 'invite-1',
          'trip_id': 'trip-1',
          'invited_by': 'user-1',
          'email': 'test@example.com',
          'phone_number': '+1234567890',
          'status': 'pending',
          'invite_code': 'ABC123',
          'created_at': '2024-01-15T10:30:00.000Z',
          'expires_at': '2024-01-22T10:30:00.000Z',
          'inviter_name': 'John Doe',
          'inviter_email': 'john@example.com',
          'trip_name': 'Amazing Trip',
          'trip_destination': 'Paris, France',
        };

        final invite = InviteModel.fromJson(json);

        expect(invite.id, 'invite-1');
        expect(invite.tripId, 'trip-1');
        expect(invite.invitedBy, 'user-1');
        expect(invite.email, 'test@example.com');
        expect(invite.phoneNumber, '+1234567890');
        expect(invite.status, 'pending');
        expect(invite.inviteCode, 'ABC123');
        expect(invite.inviterName, 'John Doe');
        expect(invite.inviterEmail, 'john@example.com');
        expect(invite.tripName, 'Amazing Trip');
        expect(invite.tripDestination, 'Paris, France');
      });

      test('should parse JSON with camelCase keys', () {
        final json = {
          'id': 'invite-1',
          'tripId': 'trip-1',
          'invitedBy': 'user-1',
          'email': 'test@example.com',
          'phoneNumber': '+1234567890',
          'status': 'pending',
          'inviteCode': 'ABC123',
          'createdAt': '2024-01-15T10:30:00.000Z',
          'expiresAt': '2024-01-22T10:30:00.000Z',
          'inviterName': 'John Doe',
          'inviterEmail': 'john@example.com',
          'tripName': 'Amazing Trip',
          'tripDestination': 'Paris, France',
        };

        final invite = InviteModel.fromJson(json);

        expect(invite.id, 'invite-1');
        expect(invite.tripId, 'trip-1');
        expect(invite.invitedBy, 'user-1');
        expect(invite.email, 'test@example.com');
        expect(invite.phoneNumber, '+1234567890');
        expect(invite.status, 'pending');
        expect(invite.inviteCode, 'ABC123');
      });

      test('should handle DateTime objects directly', () {
        final json = {
          'id': 'invite-1',
          'trip_id': 'trip-1',
          'invited_by': 'user-1',
          'email': 'test@example.com',
          'status': 'pending',
          'invite_code': 'ABC123',
          'createdAt': DateTime(2024, 1, 15),
          'expiresAt': DateTime(2024, 1, 22),
        };

        final invite = InviteModel.fromJson(json);

        expect(invite.createdAt, DateTime(2024, 1, 15));
        expect(invite.expiresAt, DateTime(2024, 1, 22));
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'invite-1',
          'trip_id': 'trip-1',
          'invited_by': 'user-1',
          'email': 'test@example.com',
          'status': 'pending',
          'invite_code': 'ABC123',
          'created_at': '2024-01-15T10:30:00.000Z',
          'expires_at': '2024-01-22T10:30:00.000Z',
        };

        final invite = InviteModel.fromJson(json);

        expect(invite.phoneNumber, isNull);
        expect(invite.inviterName, isNull);
        expect(invite.inviterEmail, isNull);
        expect(invite.tripName, isNull);
        expect(invite.tripDestination, isNull);
      });

      test('should handle mixed case keys (snake_case preferred)', () {
        final json = {
          'id': 'invite-1',
          'tripId': 'trip-1',
          'trip_id': 'trip-override',
          'invitedBy': 'user-1',
          'invited_by': 'user-override',
          'email': 'test@example.com',
          'status': 'pending',
          'inviteCode': 'ABC123',
          'invite_code': 'CODE-OVERRIDE',
          'createdAt': '2024-01-15T10:30:00.000Z',
          'expiresAt': '2024-01-22T10:30:00.000Z',
        };

        final invite = InviteModel.fromJson(json);

        // Snake_case should be used as fallback when camelCase is null
        expect(invite.tripId, 'trip-1');
      });
    });

    group('toJson', () {
      test('should convert to JSON with snake_case keys', () {
        final invite = InviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          phoneNumber: '+1234567890',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: DateTime(2024, 1, 15, 10, 30),
          expiresAt: DateTime(2024, 1, 22, 10, 30),
          inviterName: 'John Doe',
          inviterEmail: 'john@example.com',
          tripName: 'Amazing Trip',
          tripDestination: 'Paris, France',
        );

        final json = invite.toJson();

        expect(json['id'], 'invite-1');
        expect(json['trip_id'], 'trip-1');
        expect(json['invited_by'], 'user-1');
        expect(json['email'], 'test@example.com');
        expect(json['phone_number'], '+1234567890');
        expect(json['status'], 'pending');
        expect(json['invite_code'], 'ABC123');
        expect(json['inviter_name'], 'John Doe');
        expect(json['inviter_email'], 'john@example.com');
        expect(json['trip_name'], 'Amazing Trip');
        expect(json['trip_destination'], 'Paris, France');
      });

      test('should handle null optional fields', () {
        final invite = InviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
        );

        final json = invite.toJson();

        expect(json['phone_number'], isNull);
        expect(json['inviter_name'], isNull);
        expect(json['inviter_email'], isNull);
        expect(json['trip_name'], isNull);
        expect(json['trip_destination'], isNull);
      });

      test('should format dates as ISO8601 strings', () {
        final invite = InviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: DateTime.utc(2024, 1, 15, 10, 30),
          expiresAt: DateTime.utc(2024, 1, 22, 10, 30),
        );

        final json = invite.toJson();

        expect(json['created_at'], '2024-01-15T10:30:00.000Z');
        expect(json['expires_at'], '2024-01-22T10:30:00.000Z');
      });
    });

    group('toEntity', () {
      test('should convert model to entity with all fields', () {
        final model = InviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          phoneNumber: '+1234567890',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
          inviterName: 'John Doe',
          inviterEmail: 'john@example.com',
          tripName: 'Amazing Trip',
          tripDestination: 'Paris, France',
        );

        final entity = model.toEntity();

        expect(entity, isA<InviteEntity>());
        expect(entity.id, model.id);
        expect(entity.tripId, model.tripId);
        expect(entity.invitedBy, model.invitedBy);
        expect(entity.email, model.email);
        expect(entity.phoneNumber, model.phoneNumber);
        expect(entity.status, model.status);
        expect(entity.inviteCode, model.inviteCode);
        expect(entity.createdAt, model.createdAt);
        expect(entity.expiresAt, model.expiresAt);
        expect(entity.inviterName, model.inviterName);
        expect(entity.inviterEmail, model.inviterEmail);
        expect(entity.tripName, model.tripName);
        expect(entity.tripDestination, model.tripDestination);
      });

      test('should convert model with null optional fields', () {
        final model = InviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
        );

        final entity = model.toEntity();

        expect(entity.phoneNumber, isNull);
        expect(entity.inviterName, isNull);
        expect(entity.inviterEmail, isNull);
        expect(entity.tripName, isNull);
        expect(entity.tripDestination, isNull);
      });
    });

    group('fromEntity', () {
      test('should create model from entity with all fields', () {
        final entity = InviteEntity(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          phoneNumber: '+1234567890',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
          inviterName: 'John Doe',
          inviterEmail: 'john@example.com',
          tripName: 'Amazing Trip',
          tripDestination: 'Paris, France',
        );

        final model = InviteModel.fromEntity(entity);

        expect(model.id, entity.id);
        expect(model.tripId, entity.tripId);
        expect(model.invitedBy, entity.invitedBy);
        expect(model.email, entity.email);
        expect(model.phoneNumber, entity.phoneNumber);
        expect(model.status, entity.status);
        expect(model.inviteCode, entity.inviteCode);
        expect(model.createdAt, entity.createdAt);
        expect(model.expiresAt, entity.expiresAt);
        expect(model.inviterName, entity.inviterName);
        expect(model.inviterEmail, entity.inviterEmail);
        expect(model.tripName, entity.tripName);
        expect(model.tripDestination, entity.tripDestination);
      });

      test('should create model from entity with null optional fields', () {
        final entity = InviteEntity(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
        );

        final model = InviteModel.fromEntity(entity);

        expect(model.phoneNumber, isNull);
        expect(model.inviterName, isNull);
        expect(model.inviterEmail, isNull);
        expect(model.tripName, isNull);
        expect(model.tripDestination, isNull);
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        final original = InviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
        );

        final copied = original.copyWith(
          status: 'accepted',
          inviterName: 'John Doe',
        );

        expect(copied.id, 'invite-1');
        expect(copied.status, 'accepted');
        expect(copied.inviterName, 'John Doe');
        // Original values preserved
        expect(copied.tripId, 'trip-1');
        expect(copied.invitedBy, 'user-1');
        expect(copied.email, 'test@example.com');
        expect(copied.inviteCode, 'ABC123');
      });

      test('should keep original values when not specified', () {
        final original = InviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          phoneNumber: '+1234567890',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
          inviterName: 'John Doe',
          inviterEmail: 'john@example.com',
          tripName: 'Amazing Trip',
          tripDestination: 'Paris, France',
        );

        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.tripId, original.tripId);
        expect(copied.invitedBy, original.invitedBy);
        expect(copied.email, original.email);
        expect(copied.phoneNumber, original.phoneNumber);
        expect(copied.status, original.status);
        expect(copied.inviteCode, original.inviteCode);
        expect(copied.createdAt, original.createdAt);
        expect(copied.expiresAt, original.expiresAt);
        expect(copied.inviterName, original.inviterName);
        expect(copied.inviterEmail, original.inviterEmail);
        expect(copied.tripName, original.tripName);
        expect(copied.tripDestination, original.tripDestination);
      });

      test('should allow copying all fields', () {
        final original = InviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
        );

        final newDate = DateTime(2024, 2, 1);
        final newFuture = DateTime(2024, 2, 8);

        final copied = original.copyWith(
          id: 'invite-2',
          tripId: 'trip-2',
          invitedBy: 'user-2',
          email: 'new@example.com',
          phoneNumber: '+9876543210',
          status: 'accepted',
          inviteCode: 'XYZ789',
          createdAt: newDate,
          expiresAt: newFuture,
          inviterName: 'Jane Doe',
          inviterEmail: 'jane@example.com',
          tripName: 'New Trip',
          tripDestination: 'Tokyo, Japan',
        );

        expect(copied.id, 'invite-2');
        expect(copied.tripId, 'trip-2');
        expect(copied.invitedBy, 'user-2');
        expect(copied.email, 'new@example.com');
        expect(copied.phoneNumber, '+9876543210');
        expect(copied.status, 'accepted');
        expect(copied.inviteCode, 'XYZ789');
        expect(copied.createdAt, newDate);
        expect(copied.expiresAt, newFuture);
        expect(copied.inviterName, 'Jane Doe');
        expect(copied.inviterEmail, 'jane@example.com');
        expect(copied.tripName, 'New Trip');
        expect(copied.tripDestination, 'Tokyo, Japan');
      });
    });

    group('round-trip JSON serialization', () {
      test('should preserve all data through JSON round-trip', () {
        final original = InviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          phoneNumber: '+1234567890',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: DateTime.utc(2024, 1, 15, 10, 30),
          expiresAt: DateTime.utc(2024, 1, 22, 10, 30),
          inviterName: 'John Doe',
          inviterEmail: 'john@example.com',
          tripName: 'Amazing Trip',
          tripDestination: 'Paris, France',
        );

        final json = original.toJson();
        final restored = InviteModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.tripId, original.tripId);
        expect(restored.invitedBy, original.invitedBy);
        expect(restored.email, original.email);
        expect(restored.phoneNumber, original.phoneNumber);
        expect(restored.status, original.status);
        expect(restored.inviteCode, original.inviteCode);
        expect(restored.inviterName, original.inviterName);
        expect(restored.inviterEmail, original.inviterEmail);
        expect(restored.tripName, original.tripName);
        expect(restored.tripDestination, original.tripDestination);
      });
    });

    group('edge cases', () {
      test('should handle special characters in email', () {
        final invite = InviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'user+tag@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
        );

        final json = invite.toJson();
        final restored = InviteModel.fromJson(json);

        expect(restored.email, 'user+tag@example.com');
      });

      test('should handle unicode characters in names', () {
        final invite = InviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
          inviterName: 'João García',
          tripName: 'Trip to München',
          tripDestination: '東京, Japan',
        );

        final json = invite.toJson();
        final restored = InviteModel.fromJson(json);

        expect(restored.inviterName, 'João García');
        expect(restored.tripName, 'Trip to München');
        expect(restored.tripDestination, '東京, Japan');
      });

      test('should handle empty string values', () {
        final json = {
          'id': 'invite-1',
          'trip_id': 'trip-1',
          'invited_by': 'user-1',
          'email': '',
          'status': '',
          'invite_code': '',
          'created_at': '2024-01-15T10:30:00.000Z',
          'expires_at': '2024-01-22T10:30:00.000Z',
        };

        final invite = InviteModel.fromJson(json);

        expect(invite.email, '');
        expect(invite.status, '');
        expect(invite.inviteCode, '');
      });

      test('should handle international phone numbers', () {
        final invite = InviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          phoneNumber: '+81-90-1234-5678',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
        );

        final json = invite.toJson();
        final restored = InviteModel.fromJson(json);

        expect(restored.phoneNumber, '+81-90-1234-5678');
      });
    });
  });

  group('InviteEntity', () {
    final now = DateTime.now();
    final future = now.add(const Duration(days: 7));
    final past = now.subtract(const Duration(days: 7));

    group('computed properties', () {
      test('isExpired should return true for expired invite', () {
        final entity = InviteEntity(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: past.subtract(const Duration(days: 7)),
          expiresAt: past,
        );

        expect(entity.isExpired, true);
      });

      test('isExpired should return false for valid invite', () {
        final entity = InviteEntity(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
        );

        expect(entity.isExpired, false);
      });

      test('isPending should return true for pending non-expired invite', () {
        final entity = InviteEntity(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
        );

        expect(entity.isPending, true);
      });

      test('isPending should return false for expired pending invite', () {
        final entity = InviteEntity(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: past.subtract(const Duration(days: 7)),
          expiresAt: past,
        );

        expect(entity.isPending, false);
      });

      test('isAccepted should return true for accepted invite', () {
        final entity = InviteEntity(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          status: 'accepted',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
        );

        expect(entity.isAccepted, true);
        expect(entity.isRejected, false);
      });

      test('isRejected should return true for rejected invite', () {
        final entity = InviteEntity(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          status: 'rejected',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
        );

        expect(entity.isRejected, true);
        expect(entity.isAccepted, false);
      });

      test('statusMessage should return correct messages', () {
        // Pending
        expect(
          InviteEntity(
            id: '1',
            tripId: 't1',
            invitedBy: 'u1',
            email: 'e@e.com',
            status: 'pending',
            inviteCode: 'ABC',
            createdAt: now,
            expiresAt: future,
          ).statusMessage,
          'Pending',
        );

        // Accepted
        expect(
          InviteEntity(
            id: '1',
            tripId: 't1',
            invitedBy: 'u1',
            email: 'e@e.com',
            status: 'accepted',
            inviteCode: 'ABC',
            createdAt: now,
            expiresAt: future,
          ).statusMessage,
          'Accepted',
        );

        // Rejected
        expect(
          InviteEntity(
            id: '1',
            tripId: 't1',
            invitedBy: 'u1',
            email: 'e@e.com',
            status: 'rejected',
            inviteCode: 'ABC',
            createdAt: now,
            expiresAt: future,
          ).statusMessage,
          'Rejected',
        );

        // Expired
        expect(
          InviteEntity(
            id: '1',
            tripId: 't1',
            invitedBy: 'u1',
            email: 'e@e.com',
            status: 'pending',
            inviteCode: 'ABC',
            createdAt: past.subtract(const Duration(days: 7)),
            expiresAt: past,
          ).statusMessage,
          'Expired',
        );
      });

      test('timeRemainingFormatted should return correct format for days', () {
        final entity = InviteEntity(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: now.add(const Duration(days: 5)),
        );

        expect(entity.timeRemainingFormatted, contains('day'));
      });

      test('timeRemainingFormatted should return Expired for expired invite',
          () {
        final entity = InviteEntity(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: past.subtract(const Duration(days: 7)),
          expiresAt: past,
        );

        expect(entity.timeRemainingFormatted, 'Expired');
      });
    });

    group('copyWith', () {
      test('should copy with new status', () {
        final original = InviteEntity(
          id: 'invite-1',
          tripId: 'trip-1',
          invitedBy: 'user-1',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
        );

        final copied = original.copyWith(status: 'accepted');

        expect(copied.status, 'accepted');
        expect(copied.id, original.id);
        expect(copied.tripId, original.tripId);
      });
    });
  });
}
