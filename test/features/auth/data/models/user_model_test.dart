import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/auth/data/models/user_model.dart';
import 'package:travel_crew/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserModel', () {
    final now = DateTime.now();

    group('constructor', () {
      test('should create instance with required fields only', () {
        const user = UserModel(
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
        final user = UserModel(
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

        final user = UserModel.fromJson(json);

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

        final user = UserModel.fromJson(json);

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

        final user = UserModel.fromJson(json);

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
        final user = UserModel(
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

      test('should handle null optional fields', () {
        const user = UserModel(
          id: 'user-123',
          email: 'test@example.com',
        );

        final json = user.toJson();

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
        final original = UserModel(
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
      });

      test('should keep original values when not specified', () {
        final original = UserModel(
          id: 'user-123',
          email: 'test@example.com',
          fullName: 'John Doe',
          createdAt: now,
        );

        final copied = original.copyWith();

        expect(copied, original);
      });
    });

    group('toEntity', () {
      test('should convert to UserEntity with all fields', () {
        final model = UserModel(
          id: 'user-123',
          email: 'test@example.com',
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          phoneNumber: '+1234567890',
          bio: 'Travel enthusiast',
          createdAt: now,
          updatedAt: now,
        );

        final entity = model.toEntity();

        expect(entity, isA<UserEntity>());
        expect(entity.id, 'user-123');
        expect(entity.email, 'test@example.com');
        expect(entity.fullName, 'John Doe');
        expect(entity.avatarUrl, 'https://example.com/avatar.jpg');
        expect(entity.phoneNumber, '+1234567890');
        expect(entity.bio, 'Travel enthusiast');
        expect(entity.createdAt, now);
        expect(entity.updatedAt, now);
      });

      test('should convert to UserEntity with null optional fields', () {
        const model = UserModel(
          id: 'user-123',
          email: 'test@example.com',
        );

        final entity = model.toEntity();

        expect(entity, isA<UserEntity>());
        expect(entity.id, 'user-123');
        expect(entity.email, 'test@example.com');
        expect(entity.fullName, isNull);
        expect(entity.avatarUrl, isNull);
        expect(entity.phoneNumber, isNull);
        expect(entity.bio, isNull);
      });
    });

    group('fromEntity', () {
      test('should create from UserEntity with all fields', () {
        final entity = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          phoneNumber: '+1234567890',
          bio: 'Travel enthusiast',
          createdAt: now,
          updatedAt: now,
        );

        final model = UserModel.fromEntity(entity);

        expect(model, isA<UserModel>());
        expect(model.id, 'user-123');
        expect(model.email, 'test@example.com');
        expect(model.fullName, 'John Doe');
        expect(model.avatarUrl, 'https://example.com/avatar.jpg');
        expect(model.phoneNumber, '+1234567890');
        expect(model.bio, 'Travel enthusiast');
        expect(model.createdAt, now);
        expect(model.updatedAt, now);
      });

      test('should create from UserEntity with null optional fields', () {
        const entity = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
        );

        final model = UserModel.fromEntity(entity);

        expect(model, isA<UserModel>());
        expect(model.id, 'user-123');
        expect(model.email, 'test@example.com');
        expect(model.fullName, isNull);
        expect(model.avatarUrl, isNull);
      });

      test('should round-trip entity -> model -> entity', () {
        final originalEntity = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          phoneNumber: '+1234567890',
          bio: 'Travel enthusiast',
          createdAt: now,
          updatedAt: now,
        );

        final model = UserModel.fromEntity(originalEntity);
        final roundTrippedEntity = model.toEntity();

        expect(roundTrippedEntity, originalEntity);
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        final user1 = UserModel(
          id: 'user-123',
          email: 'test@example.com',
          fullName: 'John Doe',
          createdAt: now,
        );

        final user2 = UserModel(
          id: 'user-123',
          email: 'test@example.com',
          fullName: 'John Doe',
          createdAt: now,
        );

        expect(user1, user2);
        expect(user1.hashCode, user2.hashCode);
      });

      test('should not be equal when different values', () {
        const user1 = UserModel(
          id: 'user-123',
          email: 'test@example.com',
        );

        const user2 = UserModel(
          id: 'user-456',
          email: 'test@example.com',
        );

        expect(user1, isNot(user2));
      });

      test('should be identical to itself', () {
        final user = UserModel(
          id: 'user-123',
          email: 'test@example.com',
          createdAt: now,
        );

        expect(user == user, true);
      });
    });

    group('toString', () {
      test('should return string representation', () {
        const user = UserModel(
          id: 'user-123',
          email: 'test@example.com',
          fullName: 'John Doe',
        );

        final str = user.toString();

        expect(str, contains('UserModel'));
        expect(str, contains('user-123'));
        expect(str, contains('test@example.com'));
        expect(str, contains('John Doe'));
      });
    });
  });
}
