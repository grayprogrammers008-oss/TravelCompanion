import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_user.dart';
import 'package:travel_crew/features/admin/domain/entities/user_role.dart';
import 'package:travel_crew/features/admin/domain/entities/user_status.dart';

void main() {
  group('AdminUser', () {
    final tUser = AdminUser(
      id: 'user-123',
      email: 'test@example.com',
      fullName: 'Test User',
      role: UserRole.user,
      status: UserStatus.active,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 15),
      loginCount: 10,
      tripsCount: 5,
      messagesCount: 100,
      expensesCount: 20,
      totalExpenses: 500.0,
    );

    group('isAdmin', () {
      test('should return false for regular user', () {
        expect(tUser.isAdmin, false);
      });

      test('should return true for admin', () {
        final admin = tUser.copyWith(role: UserRole.admin);
        expect(admin.isAdmin, true);
      });

      test('should return true for super admin', () {
        final superAdmin = tUser.copyWith(role: UserRole.superAdmin);
        expect(superAdmin.isAdmin, true);
      });
    });

    group('canManageAdmins', () {
      test('should return false for regular user', () {
        expect(tUser.canManageAdmins, false);
      });

      test('should return false for admin', () {
        final admin = tUser.copyWith(role: UserRole.admin);
        expect(admin.canManageAdmins, false);
      });

      test('should return true for super admin', () {
        final superAdmin = tUser.copyWith(role: UserRole.superAdmin);
        expect(superAdmin.canManageAdmins, true);
      });
    });

    group('isActive', () {
      test('should return true when status is active', () {
        expect(tUser.isActive, true);
      });

      test('should return false when status is suspended', () {
        final suspended = tUser.copyWith(status: UserStatus.suspended);
        expect(suspended.isActive, false);
      });
    });

    group('isSuspended', () {
      test('should return false when status is active', () {
        expect(tUser.isSuspended, false);
      });

      test('should return true when status is suspended', () {
        final suspended = tUser.copyWith(status: UserStatus.suspended);
        expect(suspended.isSuspended, true);
      });
    });

    group('isLocked', () {
      test('should return false when account is not locked', () {
        expect(tUser.isLocked, false);
      });

      test('should return true when account is locked', () {
        final locked = tUser.copyWith(
          accountLockedAt: DateTime.now(),
        );
        expect(locked.isLocked, true);
      });
    });

    group('initials', () {
      test('should return first letter of full name for single word', () {
        final user = tUser.copyWith(fullName: 'John');
        expect(user.initials, 'J');
      });

      test('should return first and last initials for multiple words', () {
        final user = tUser.copyWith(fullName: 'John Doe');
        expect(user.initials, 'JD');
      });

      test('should handle names with multiple spaces', () {
        final user = tUser.copyWith(fullName: 'John Middle Doe');
        expect(user.initials, 'JD');
      });

      test('should return ? for empty name', () {
        final user = tUser.copyWith(fullName: '');
        expect(user.initials, '?');
      });
    });

    group('displayName', () {
      test('should return full name when available', () {
        expect(tUser.displayName, 'Test User');
      });

      test('should return email username when full name is empty', () {
        final user = tUser.copyWith(fullName: '');
        expect(user.displayName, 'test');
      });
    });

    group('activityLevel', () {
      test('should return "Never Active" when lastActiveAt is null', () {
        expect(tUser.activityLevel, 'Never Active');
      });

      test('should return "Active Today" for today', () {
        final user = tUser.copyWith(lastActiveAt: DateTime.now());
        expect(user.activityLevel, 'Active Today');
      });

      test('should return "Active Yesterday" for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final user = tUser.copyWith(lastActiveAt: yesterday);
        expect(user.activityLevel, 'Active Yesterday');
      });

      test('should return "Active This Week" for within 7 days', () {
        final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));
        final user = tUser.copyWith(lastActiveAt: fiveDaysAgo);
        expect(user.activityLevel, 'Active This Week');
      });

      test('should return "Active This Month" for within 30 days', () {
        final twentyDaysAgo = DateTime.now().subtract(const Duration(days: 20));
        final user = tUser.copyWith(lastActiveAt: twentyDaysAgo);
        expect(user.activityLevel, 'Active This Month');
      });

      test('should return "Inactive" for more than 30 days', () {
        final longAgo = DateTime.now().subtract(const Duration(days: 60));
        final user = tUser.copyWith(lastActiveAt: longAgo);
        expect(user.activityLevel, 'Inactive');
      });
    });

    group('copyWith', () {
      test('should return same instance when no parameters provided', () {
        final copy = tUser.copyWith();
        expect(copy, tUser);
      });

      test('should update specified fields only', () {
        final updated = tUser.copyWith(
          fullName: 'Updated Name',
          loginCount: 20,
        );

        expect(updated.fullName, 'Updated Name');
        expect(updated.loginCount, 20);
        expect(updated.email, tUser.email);
        expect(updated.id, tUser.id);
      });
    });

    group('equality', () {
      test('should be equal when all fields are same', () {
        final user2 = AdminUser(
          id: tUser.id,
          email: tUser.email,
          fullName: tUser.fullName,
          role: tUser.role,
          status: tUser.status,
          createdAt: tUser.createdAt,
          updatedAt: tUser.updatedAt,
          loginCount: tUser.loginCount,
          tripsCount: tUser.tripsCount,
          messagesCount: tUser.messagesCount,
          expensesCount: tUser.expensesCount,
          totalExpenses: tUser.totalExpenses,
        );

        expect(user2, tUser);
      });

      test('should not be equal when fields differ', () {
        final user2 = tUser.copyWith(email: 'different@example.com');
        expect(user2, isNot(tUser));
      });
    });
  });
}
