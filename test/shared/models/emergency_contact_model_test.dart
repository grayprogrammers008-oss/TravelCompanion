import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/shared/models/emergency_contact_model.dart';

void main() {
  group('EmergencyContactModel', () {
    final createdAt = DateTime(2024, 1, 15, 10, 30);
    final updatedAt = DateTime(2024, 1, 16, 12, 0);

    group('constructor', () {
      test('should create instance with required fields', () {
        final contact = EmergencyContactModel(
          id: 'c-1',
          userId: 'u-1',
          name: 'Jane',
          phoneNumber: '+15551234',
          relationship: 'Spouse',
          createdAt: createdAt,
        );

        expect(contact.id, 'c-1');
        expect(contact.userId, 'u-1');
        expect(contact.name, 'Jane');
        expect(contact.phoneNumber, '+15551234');
        expect(contact.relationship, 'Spouse');
        expect(contact.isPrimary, false);
        expect(contact.email, isNull);
        expect(contact.updatedAt, isNull);
      });

      test('should create instance with all fields', () {
        final contact = EmergencyContactModel(
          id: 'c-1',
          userId: 'u-1',
          name: 'Jane',
          phoneNumber: '+15551234',
          email: 'jane@example.com',
          relationship: 'Spouse',
          isPrimary: true,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

        expect(contact.email, 'jane@example.com');
        expect(contact.isPrimary, true);
        expect(contact.updatedAt, updatedAt);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON with all fields', () {
        final json = {
          'id': 'c-1',
          'user_id': 'u-1',
          'name': 'Jane',
          'phone_number': '+15551234',
          'email': 'jane@example.com',
          'relationship': 'Spouse',
          'is_primary': true,
          'created_at': '2024-01-15T10:30:00.000Z',
          'updated_at': '2024-01-16T12:00:00.000Z',
        };

        final contact = EmergencyContactModel.fromJson(json);

        expect(contact.id, 'c-1');
        expect(contact.userId, 'u-1');
        expect(contact.email, 'jane@example.com');
        expect(contact.isPrimary, true);
        expect(contact.updatedAt, isNotNull);
      });

      test('should default isPrimary to false when missing', () {
        final json = {
          'id': 'c-1',
          'user_id': 'u-1',
          'name': 'Jane',
          'phone_number': '+15551234',
          'relationship': 'Friend',
          'created_at': '2024-01-15T10:30:00.000Z',
        };

        final contact = EmergencyContactModel.fromJson(json);
        expect(contact.isPrimary, false);
        expect(contact.email, isNull);
        expect(contact.updatedAt, isNull);
      });
    });

    group('toJson', () {
      test('should convert to JSON', () {
        final contact = EmergencyContactModel(
          id: 'c-1',
          userId: 'u-1',
          name: 'Jane',
          phoneNumber: '+15551234',
          email: 'jane@example.com',
          relationship: 'Spouse',
          isPrimary: true,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

        final json = contact.toJson();

        expect(json['id'], 'c-1');
        expect(json['user_id'], 'u-1');
        expect(json['name'], 'Jane');
        expect(json['phone_number'], '+15551234');
        expect(json['email'], 'jane@example.com');
        expect(json['relationship'], 'Spouse');
        expect(json['is_primary'], true);
        expect(json['created_at'], createdAt.toIso8601String());
        expect(json['updated_at'], updatedAt.toIso8601String());
      });

      test('should handle null updatedAt and email', () {
        final contact = EmergencyContactModel(
          id: 'c-1',
          userId: 'u-1',
          name: 'Jane',
          phoneNumber: '+15551234',
          relationship: 'Friend',
          createdAt: createdAt,
        );

        final json = contact.toJson();

        expect(json['email'], isNull);
        expect(json['updated_at'], isNull);
      });

      test('round-trips fromJson + toJson preserving data', () {
        final original = EmergencyContactModel(
          id: 'c-1',
          userId: 'u-1',
          name: 'Jane',
          phoneNumber: '+15551234',
          email: 'jane@example.com',
          relationship: 'Spouse',
          isPrimary: true,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

        final reconstructed = EmergencyContactModel.fromJson(original.toJson());

        expect(reconstructed, equals(original));
      });
    });

    group('copyWith', () {
      test('should override specified fields', () {
        final original = EmergencyContactModel(
          id: 'c-1',
          userId: 'u-1',
          name: 'Jane',
          phoneNumber: '+15551234',
          relationship: 'Friend',
          createdAt: createdAt,
        );

        final copied = original.copyWith(
          name: 'John',
          isPrimary: true,
        );

        expect(copied.name, 'John');
        expect(copied.isPrimary, true);
        expect(copied.id, 'c-1');
        expect(copied.userId, 'u-1');
        expect(copied.phoneNumber, '+15551234');
      });

      test('should preserve all values when no overrides given', () {
        final original = EmergencyContactModel(
          id: 'c-1',
          userId: 'u-1',
          name: 'Jane',
          phoneNumber: '+15551234',
          email: 'jane@example.com',
          relationship: 'Spouse',
          isPrimary: true,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

        final copied = original.copyWith();

        expect(copied, equals(original));
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        final c1 = EmergencyContactModel(
          id: 'c-1',
          userId: 'u-1',
          name: 'Jane',
          phoneNumber: '+15551234',
          relationship: 'Spouse',
          createdAt: createdAt,
        );
        final c2 = EmergencyContactModel(
          id: 'c-1',
          userId: 'u-1',
          name: 'Jane',
          phoneNumber: '+15551234',
          relationship: 'Spouse',
          createdAt: createdAt,
        );

        expect(c1, equals(c2));
        expect(c1.hashCode, equals(c2.hashCode));
      });

      test('should not be equal when different id', () {
        final c1 = EmergencyContactModel(
          id: 'c-1',
          userId: 'u-1',
          name: 'Jane',
          phoneNumber: '+15551234',
          relationship: 'Spouse',
          createdAt: createdAt,
        );
        final c2 = EmergencyContactModel(
          id: 'c-2',
          userId: 'u-1',
          name: 'Jane',
          phoneNumber: '+15551234',
          relationship: 'Spouse',
          createdAt: createdAt,
        );

        expect(c1, isNot(equals(c2)));
      });
    });
  });
}
