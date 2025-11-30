import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserEntity', () {
    final now = DateTime.now();

    group('constructor', () {
      test('should create instance with required fields only', () {
        const user = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
        );

        expect(user.id, 'user-123');
        expect(user.email, 'test@example.com');
        expect(user.fullName, isNull);
        expect(user.avatarUrl, isNull);
        expect(user.phoneNumber, isNull);
        expect(user.bio, isNull);
        expect(user.createdAt, isNull);
        expect(user.updatedAt, isNull);
      });

      test('should create instance with all fields', () {
        final user = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          phoneNumber: '+1234567890',
          bio: 'Travel enthusiast',
          createdAt: now,
          updatedAt: now,
        );

        expect(user.id, 'user-123');
        expect(user.email, 'test@example.com');
        expect(user.fullName, 'John Doe');
        expect(user.avatarUrl, 'https://example.com/avatar.jpg');
        expect(user.phoneNumber, '+1234567890');
        expect(user.bio, 'Travel enthusiast');
        expect(user.createdAt, now);
        expect(user.updatedAt, now);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON with all fields', () {
        final json = {
          'id': 'user-123',
          'email': 'test@example.com',
          'full_name': 'John Doe',
          'avatar_url': 'https://example.com/avatar.jpg',
          'phone_number': '+1234567890',
          'bio': 'Travel enthusiast',
          'created_at': '2024-01-15T10:30:00.000Z',
          'updated_at': '2024-01-16T10:30:00.000Z',
        };

        final user = UserEntity.fromJson(json);

        expect(user.id, 'user-123');
        expect(user.email, 'test@example.com');
        expect(user.fullName, 'John Doe');
        expect(user.avatarUrl, 'https://example.com/avatar.jpg');
        expect(user.phoneNumber, '+1234567890');
        expect(user.bio, 'Travel enthusiast');
        expect(user.createdAt, DateTime.parse('2024-01-15T10:30:00.000Z'));
        expect(user.updatedAt, DateTime.parse('2024-01-16T10:30:00.000Z'));
      });

      test('should parse JSON with required fields only', () {
        final json = {
          'id': 'user-123',
          'email': 'test@example.com',
        };

        final user = UserEntity.fromJson(json);

        expect(user.id, 'user-123');
        expect(user.email, 'test@example.com');
        expect(user.fullName, isNull);
        expect(user.avatarUrl, isNull);
        expect(user.phoneNumber, isNull);
        expect(user.bio, isNull);
        expect(user.createdAt, isNull);
        expect(user.updatedAt, isNull);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'user-123',
          'email': 'test@example.com',
          'full_name': null,
          'avatar_url': null,
          'phone_number': null,
          'bio': null,
          'created_at': null,
          'updated_at': null,
        };

        final user = UserEntity.fromJson(json);

        expect(user.id, 'user-123');
        expect(user.email, 'test@example.com');
        expect(user.fullName, isNull);
        expect(user.avatarUrl, isNull);
        expect(user.phoneNumber, isNull);
        expect(user.bio, isNull);
        expect(user.createdAt, isNull);
        expect(user.updatedAt, isNull);
      });
    });

    group('toJson', () {
      test('should convert to JSON with all fields', () {
        final user = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          phoneNumber: '+1234567890',
          bio: 'Travel enthusiast',
          createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
          updatedAt: DateTime.parse('2024-01-16T10:30:00.000Z'),
        );

        final json = user.toJson();

        expect(json['id'], 'user-123');
        expect(json['email'], 'test@example.com');
        expect(json['full_name'], 'John Doe');
        expect(json['avatar_url'], 'https://example.com/avatar.jpg');
        expect(json['phone_number'], '+1234567890');
        expect(json['bio'], 'Travel enthusiast');
        expect(json['created_at'], '2024-01-15T10:30:00.000Z');
        expect(json['updated_at'], '2024-01-16T10:30:00.000Z');
      });

      test('should convert to JSON with null optional fields', () {
        const user = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
        );

        final json = user.toJson();

        expect(json['id'], 'user-123');
        expect(json['email'], 'test@example.com');
        expect(json['full_name'], isNull);
        expect(json['avatar_url'], isNull);
        expect(json['phone_number'], isNull);
        expect(json['bio'], isNull);
        expect(json['created_at'], isNull);
        expect(json['updated_at'], isNull);
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        final original = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          phoneNumber: '+1234567890',
          bio: 'Travel enthusiast',
          createdAt: now,
          updatedAt: now,
        );

        final copied = original.copyWith(
          fullName: 'Jane Doe',
          bio: 'Adventure lover',
        );

        expect(copied.id, 'user-123');
        expect(copied.email, 'test@example.com');
        expect(copied.fullName, 'Jane Doe');
        expect(copied.avatarUrl, 'https://example.com/avatar.jpg');
        expect(copied.phoneNumber, '+1234567890');
        expect(copied.bio, 'Adventure lover');
        expect(copied.createdAt, now);
        expect(copied.updatedAt, now);
      });

      test('should keep original values when not specified', () {
        final original = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          phoneNumber: '+1234567890',
          bio: 'Travel enthusiast',
          createdAt: now,
          updatedAt: now,
        );

        final copied = original.copyWith();

        expect(copied, original);
      });

      test('should copy all fields', () {
        const original = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
        );

        final newTime = DateTime.now();
        final copied = original.copyWith(
          id: 'user-456',
          email: 'new@example.com',
          fullName: 'New Name',
          avatarUrl: 'https://new.com/avatar.jpg',
          phoneNumber: '+9876543210',
          bio: 'New bio',
          createdAt: newTime,
          updatedAt: newTime,
        );

        expect(copied.id, 'user-456');
        expect(copied.email, 'new@example.com');
        expect(copied.fullName, 'New Name');
        expect(copied.avatarUrl, 'https://new.com/avatar.jpg');
        expect(copied.phoneNumber, '+9876543210');
        expect(copied.bio, 'New bio');
        expect(copied.createdAt, newTime);
        expect(copied.updatedAt, newTime);
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        final user1 = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          phoneNumber: '+1234567890',
          bio: 'Travel enthusiast',
          createdAt: now,
          updatedAt: now,
        );

        final user2 = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          phoneNumber: '+1234567890',
          bio: 'Travel enthusiast',
          createdAt: now,
          updatedAt: now,
        );

        expect(user1, user2);
        expect(user1.hashCode, user2.hashCode);
      });

      test('should not be equal when different id', () {
        const user1 = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
        );

        const user2 = UserEntity(
          id: 'user-456',
          email: 'test@example.com',
        );

        expect(user1, isNot(user2));
      });

      test('should not be equal when different email', () {
        const user1 = UserEntity(
          id: 'user-123',
          email: 'test1@example.com',
        );

        const user2 = UserEntity(
          id: 'user-123',
          email: 'test2@example.com',
        );

        expect(user1, isNot(user2));
      });

      test('should be identical to itself', () {
        final user = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
          fullName: 'John Doe',
          createdAt: now,
        );

        expect(user == user, true);
      });
    });

    group('toString', () {
      test('should return string representation', () {
        const user = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
          fullName: 'John Doe',
        );

        final str = user.toString();

        expect(str, contains('UserEntity'));
        expect(str, contains('user-123'));
        expect(str, contains('test@example.com'));
        expect(str, contains('John Doe'));
      });
    });
  });
}
