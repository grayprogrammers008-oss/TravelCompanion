import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/admin/data/models/admin_user_model.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_user.dart';
import 'package:travel_crew/features/admin/domain/entities/user_role.dart';
import 'package:travel_crew/features/admin/domain/entities/user_status.dart';

void main() {
  group('AdminUserModel', () {
    final tDateTime = DateTime(2024, 1, 1);
    final tLastLoginAt = DateTime(2024, 1, 15);
    final tLastActiveAt = DateTime(2024, 1, 20);

    final tJson = {
      'id': 'user-123',
      'email': 'test@example.com',
      'full_name': 'Test User',
      'avatar_url': 'https://example.com/avatar.jpg',
      'role': 'user',
      'status': 'active',
      'created_at': tDateTime.toIso8601String(),
      'updated_at': tDateTime.toIso8601String(),
      'last_login_at': tLastLoginAt.toIso8601String(),
      'last_active_at': tLastActiveAt.toIso8601String(),
      'account_locked_at': null,
      'account_locked_reason': null,
      'login_count': 10,
      'trips_count': 5,
      'messages_count': 100,
      'expenses_count': 20,
      'total_expenses': 500.0,
    };

    final tModel = AdminUserModel(
      id: 'user-123',
      email: 'test@example.com',
      fullName: 'Test User',
      avatarUrl: 'https://example.com/avatar.jpg',
      role: UserRole.user,
      status: UserStatus.active,
      createdAt: tDateTime,
      updatedAt: tDateTime,
      lastLoginAt: tLastLoginAt,
      lastActiveAt: tLastActiveAt,
      accountLockedAt: null,
      accountLockedReason: null,
      loginCount: 10,
      tripsCount: 5,
      messagesCount: 100,
      expensesCount: 20,
      totalExpenses: 500.0,
    );

    group('fromJson', () {
      test('should return valid model from JSON', () {
        final result = AdminUserModel.fromJson(tJson);

        expect(result.id, tModel.id);
        expect(result.email, tModel.email);
        expect(result.fullName, tModel.fullName);
        expect(result.avatarUrl, tModel.avatarUrl);
        expect(result.role, tModel.role);
        expect(result.status, tModel.status);
        expect(result.createdAt, tModel.createdAt);
        expect(result.updatedAt, tModel.updatedAt);
        expect(result.lastLoginAt, tModel.lastLoginAt);
        expect(result.lastActiveAt, tModel.lastActiveAt);
        expect(result.loginCount, tModel.loginCount);
        expect(result.tripsCount, tModel.tripsCount);
        expect(result.messagesCount, tModel.messagesCount);
        expect(result.expensesCount, tModel.expensesCount);
        expect(result.totalExpenses, tModel.totalExpenses);
      });

      test('should handle null optional fields', () {
        final jsonWithNulls = Map<String, dynamic>.from(tJson)
          ..['avatar_url'] = null
          ..['last_login_at'] = null
          ..['last_active_at'] = null;

        final result = AdminUserModel.fromJson(jsonWithNulls);

        expect(result.avatarUrl, isNull);
        expect(result.lastLoginAt, isNull);
        expect(result.lastActiveAt, isNull);
      });

      test('should handle locked account fields', () {
        final lockedAt = DateTime(2024, 2, 1);
        final jsonWithLock = Map<String, dynamic>.from(tJson)
          ..['account_locked_at'] = lockedAt.toIso8601String()
          ..['account_locked_reason'] = 'Violation of terms';

        final result = AdminUserModel.fromJson(jsonWithLock);

        expect(result.accountLockedAt, lockedAt);
        expect(result.accountLockedReason, 'Violation of terms');
      });

      test('should parse admin role correctly', () {
        final jsonWithAdmin = Map<String, dynamic>.from(tJson)
          ..['role'] = 'admin';

        final result = AdminUserModel.fromJson(jsonWithAdmin);

        expect(result.role, UserRole.admin);
      });

      test('should parse suspended status correctly', () {
        final jsonWithSuspended = Map<String, dynamic>.from(tJson)
          ..['status'] = 'suspended';

        final result = AdminUserModel.fromJson(jsonWithSuspended);

        expect(result.status, UserStatus.suspended);
      });
    });

    group('toJson', () {
      test('should return valid JSON map', () {
        final result = tModel.toJson();

        expect(result['id'], tModel.id);
        expect(result['email'], tModel.email);
        expect(result['full_name'], tModel.fullName);
        expect(result['avatar_url'], tModel.avatarUrl);
        expect(result['role'], 'user');
        expect(result['status'], 'active');
        expect(result['created_at'], tModel.createdAt.toIso8601String());
        expect(result['updated_at'], tModel.updatedAt.toIso8601String());
        expect(result['last_login_at'], tModel.lastLoginAt!.toIso8601String());
        expect(result['last_active_at'], tModel.lastActiveAt!.toIso8601String());
        expect(result['login_count'], tModel.loginCount);
        expect(result['trips_count'], tModel.tripsCount);
        expect(result['messages_count'], tModel.messagesCount);
        expect(result['expenses_count'], tModel.expensesCount);
        expect(result['total_expenses'], tModel.totalExpenses);
      });

      test('should include null values for optional fields', () {
        final modelWithNulls = AdminUserModel(
          id: tModel.id,
          email: tModel.email,
          fullName: tModel.fullName,
          avatarUrl: null,
          role: tModel.role,
          status: tModel.status,
          createdAt: tModel.createdAt,
          updatedAt: tModel.updatedAt,
          lastLoginAt: null,
          lastActiveAt: null,
          accountLockedAt: null,
          accountLockedReason: null,
          loginCount: tModel.loginCount,
          tripsCount: tModel.tripsCount,
          messagesCount: tModel.messagesCount,
          expensesCount: tModel.expensesCount,
          totalExpenses: tModel.totalExpenses,
        );

        final result = modelWithNulls.toJson();

        expect(result['avatar_url'], isNull);
        expect(result['last_login_at'], isNull);
        expect(result['last_active_at'], isNull);
      });
    });

    group('toEntity', () {
      test('should convert model to entity', () {
        final result = tModel.toEntity();

        expect(result, isA<AdminUser>());
        expect(result.id, tModel.id);
        expect(result.email, tModel.email);
        expect(result.fullName, tModel.fullName);
        expect(result.avatarUrl, tModel.avatarUrl);
        expect(result.role, tModel.role);
        expect(result.status, tModel.status);
      });
    });

    group('fromEntity', () {
      test('should convert entity to model', () {
        final entity = AdminUser(
          id: 'user-456',
          email: 'entity@example.com',
          fullName: 'Entity User',
          role: UserRole.admin,
          status: UserStatus.active,
          createdAt: tDateTime,
          updatedAt: tDateTime,
          loginCount: 5,
          tripsCount: 2,
          messagesCount: 50,
          expensesCount: 10,
          totalExpenses: 200.0,
        );

        final result = AdminUserModel.fromEntity(entity);

        expect(result, isA<AdminUserModel>());
        expect(result.id, entity.id);
        expect(result.email, entity.email);
        expect(result.fullName, entity.fullName);
        expect(result.role, entity.role);
        expect(result.status, entity.status);
      });
    });

    group('equality', () {
      test('should be equal when all fields are same', () {
        final model2 = AdminUserModel.fromJson(tJson);

        expect(model2, tModel);
      });

      test('should not be equal when fields differ', () {
        final model2 = tModel.copyWith(email: 'different@example.com');

        expect(model2, isNot(tModel));
      });
    });

    group('round trip conversion', () {
      test('should maintain data integrity through JSON round trip', () {
        final json = tModel.toJson();
        final model = AdminUserModel.fromJson(json);

        expect(model, tModel);
      });

      test('should maintain data integrity through entity round trip', () {
        final entity = tModel.toEntity();
        final model = AdminUserModel.fromEntity(entity);

        expect(model.id, tModel.id);
        expect(model.email, tModel.email);
        expect(model.fullName, tModel.fullName);
        expect(model.role, tModel.role);
        expect(model.status, tModel.status);
      });
    });
  });
}
