import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/features/admin/domain/entities/user_role.dart';

void main() {
  group('UserRole', () {
    test('enum values have correct underlying string', () {
      expect(UserRole.user.value, 'user');
      expect(UserRole.admin.value, 'admin');
      expect(UserRole.superAdmin.value, 'super_admin');
    });

    test('displayName returns human readable strings', () {
      expect(UserRole.user.displayName, 'User');
      expect(UserRole.admin.displayName, 'Admin');
      expect(UserRole.superAdmin.displayName, 'Super Admin');
    });

    group('isAdmin', () {
      test('user is not admin', () => expect(UserRole.user.isAdmin, false));
      test('admin is admin', () => expect(UserRole.admin.isAdmin, true));
      test('superAdmin is admin',
          () => expect(UserRole.superAdmin.isAdmin, true));
    });

    group('canManageAdmins', () {
      test('user cannot manage admins',
          () => expect(UserRole.user.canManageAdmins, false));
      test('admin cannot manage admins',
          () => expect(UserRole.admin.canManageAdmins, false));
      test('superAdmin can manage admins',
          () => expect(UserRole.superAdmin.canManageAdmins, true));
    });

    group('fromString', () {
      test('parses known string values', () {
        expect(UserRole.fromString('user'), UserRole.user);
        expect(UserRole.fromString('admin'), UserRole.admin);
        expect(UserRole.fromString('super_admin'), UserRole.superAdmin);
      });

      test('returns user for unknown values', () {
        expect(UserRole.fromString(''), UserRole.user);
        expect(UserRole.fromString('UNKNOWN'), UserRole.user);
        expect(UserRole.fromString('Admin'), UserRole.user); // case sensitive
      });
    });

    test('values list contains exactly three roles', () {
      expect(UserRole.values.length, 3);
    });
  });
}
