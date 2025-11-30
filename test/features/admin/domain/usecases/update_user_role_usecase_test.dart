import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/admin/domain/entities/user_role.dart';
import 'package:travel_crew/features/admin/domain/repositories/admin_repository.dart';
import 'package:travel_crew/features/admin/domain/usecases/update_user_role_usecase.dart';

import 'update_user_role_usecase_test.mocks.dart';

@GenerateMocks([AdminRepository])
void main() {
  late UpdateUserRoleUseCase useCase;
  late MockAdminRepository mockRepository;

  setUp(() {
    mockRepository = MockAdminRepository();
    useCase = UpdateUserRoleUseCase(mockRepository);
  });

  group('UpdateUserRoleUseCase', () {
    group('Positive Cases', () {
      test('should update user role to admin successfully', () async {
        // Arrange
        when(mockRepository.updateUserRole(any, any))
            .thenAnswer((_) async => true);

        // Act
        final result = await useCase('user-123', UserRole.admin);

        // Assert
        expect(result, true);
        verify(mockRepository.updateUserRole('user-123', UserRole.admin))
            .called(1);
      });

      test('should update user role to user successfully', () async {
        // Arrange
        when(mockRepository.updateUserRole(any, any))
            .thenAnswer((_) async => true);

        // Act
        final result = await useCase('user-123', UserRole.user);

        // Assert
        expect(result, true);
        verify(mockRepository.updateUserRole('user-123', UserRole.user))
            .called(1);
      });

      test('should update user role to superAdmin successfully', () async {
        // Arrange
        when(mockRepository.updateUserRole(any, any))
            .thenAnswer((_) async => true);

        // Act
        final result = await useCase('user-123', UserRole.superAdmin);

        // Assert
        expect(result, true);
        verify(mockRepository.updateUserRole('user-123', UserRole.superAdmin))
            .called(1);
      });

      test('should promote user from user to admin', () async {
        // Arrange
        when(mockRepository.updateUserRole(any, any))
            .thenAnswer((_) async => true);

        // Act
        final result = await useCase('regular-user', UserRole.admin);

        // Assert
        expect(result, true);
      });

      test('should demote admin to user', () async {
        // Arrange
        when(mockRepository.updateUserRole(any, any))
            .thenAnswer((_) async => true);

        // Act
        final result = await useCase('admin-user', UserRole.user);

        // Assert
        expect(result, true);
      });

      test('should promote admin to superAdmin', () async {
        // Arrange
        when(mockRepository.updateUserRole(any, any))
            .thenAnswer((_) async => true);

        // Act
        final result = await useCase('admin-user', UserRole.superAdmin);

        // Assert
        expect(result, true);
      });

      test('should handle UUID format user ID', () async {
        // Arrange
        const uuidUserId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        when(mockRepository.updateUserRole(any, any))
            .thenAnswer((_) async => true);

        // Act
        final result = await useCase(uuidUserId, UserRole.admin);

        // Assert
        expect(result, true);
        verify(mockRepository.updateUserRole(uuidUserId, UserRole.admin))
            .called(1);
      });

      test('should set same role (idempotent)', () async {
        // Arrange
        when(mockRepository.updateUserRole(any, any))
            .thenAnswer((_) async => true);

        // Act
        final result = await useCase('admin-user', UserRole.admin);

        // Assert
        expect(result, true);
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw Exception for empty user ID', () async {
        // Act & Assert
        expect(
          () => useCase('', UserRole.admin),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User ID cannot be empty'),
          )),
        );
        verifyNever(mockRepository.updateUserRole(any, any));
      });

      test('should not call repository when user ID is empty', () async {
        // Act
        try {
          await useCase('', UserRole.user);
        } catch (_) {}

        // Assert
        verifyNever(mockRepository.updateUserRole(any, any));
      });

      test('should throw for empty user ID with any role', () async {
        for (final role in UserRole.values) {
          expect(
            () => useCase('', role),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('User ID cannot be empty'),
            )),
          );
        }
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should propagate repository exception', () async {
        // Arrange
        when(mockRepository.updateUserRole(any, any))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => useCase('user-123', UserRole.admin),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Database error'),
          )),
        );
      });

      test('should handle network error', () async {
        // Arrange
        when(mockRepository.updateUserRole(any, any))
            .thenThrow(Exception('Network unavailable'));

        // Act & Assert
        expect(
          () => useCase('user-123', UserRole.admin),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network unavailable'),
          )),
        );
      });

      test('should handle user not found error', () async {
        // Arrange
        when(mockRepository.updateUserRole(any, any))
            .thenThrow(Exception('User not found'));

        // Act & Assert
        expect(
          () => useCase('nonexistent-user', UserRole.admin),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User not found'),
          )),
        );
      });

      test('should handle permission denied error (non-super-admin)', () async {
        // Arrange
        when(mockRepository.updateUserRole(any, any))
            .thenThrow(Exception('Permission denied: Super Admin access required'));

        // Act & Assert
        expect(
          () => useCase('user-123', UserRole.admin),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Permission denied'),
          )),
        );
      });

      test('should handle cannot modify own role error', () async {
        // Arrange
        when(mockRepository.updateUserRole(any, any))
            .thenThrow(Exception('Cannot modify your own role'));

        // Act & Assert
        expect(
          () => useCase('self-user-id', UserRole.user),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Cannot modify your own role'),
          )),
        );
      });

      test('should handle last super admin error', () async {
        // Arrange
        when(mockRepository.updateUserRole(any, any))
            .thenThrow(Exception('Cannot demote the last super admin'));

        // Act & Assert
        expect(
          () => useCase('last-super-admin', UserRole.user),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('last super admin'),
          )),
        );
      });

      test('should return false when update fails', () async {
        // Arrange
        when(mockRepository.updateUserRole(any, any))
            .thenAnswer((_) async => false);

        // Act
        final result = await useCase('user-123', UserRole.admin);

        // Assert
        expect(result, false);
      });
    });

    group('Edge Cases', () {
      test('should handle very long user ID', () async {
        // Arrange
        final longUserId = 'user-${'a' * 500}';
        when(mockRepository.updateUserRole(any, any))
            .thenAnswer((_) async => true);

        // Act
        final result = await useCase(longUserId, UserRole.admin);

        // Assert
        expect(result, true);
        verify(mockRepository.updateUserRole(longUserId, UserRole.admin))
            .called(1);
      });

      test('should handle user ID with special characters', () async {
        // Arrange
        const specialUserId = 'user_123-abc@domain.com';
        when(mockRepository.updateUserRole(any, any))
            .thenAnswer((_) async => true);

        // Act
        final result = await useCase(specialUserId, UserRole.admin);

        // Assert
        expect(result, true);
      });

      test('should handle rapid role changes', () async {
        // Arrange
        when(mockRepository.updateUserRole(any, any))
            .thenAnswer((_) async => true);

        // Act
        await useCase('user-123', UserRole.admin);
        await useCase('user-123', UserRole.superAdmin);
        await useCase('user-123', UserRole.user);

        // Assert
        verify(mockRepository.updateUserRole('user-123', UserRole.admin))
            .called(1);
        verify(mockRepository.updateUserRole('user-123', UserRole.superAdmin))
            .called(1);
        verify(mockRepository.updateUserRole('user-123', UserRole.user))
            .called(1);
      });

      test('should handle bulk role updates', () async {
        // Arrange
        when(mockRepository.updateUserRole(any, any))
            .thenAnswer((_) async => true);

        // Act
        final results = await Future.wait([
          useCase('user-1', UserRole.admin),
          useCase('user-2', UserRole.superAdmin),
          useCase('user-3', UserRole.user),
        ]);

        // Assert
        expect(results, [true, true, true]);
      });

      test('should handle updating same user to same role multiple times', () async {
        // Arrange
        when(mockRepository.updateUserRole(any, any))
            .thenAnswer((_) async => true);

        // Act
        await useCase('user-123', UserRole.admin);
        await useCase('user-123', UserRole.admin);
        await useCase('user-123', UserRole.admin);

        // Assert
        verify(mockRepository.updateUserRole('user-123', UserRole.admin))
            .called(3);
      });

      test('should handle numeric user ID', () async {
        // Arrange
        const numericUserId = '12345678';
        when(mockRepository.updateUserRole(any, any))
            .thenAnswer((_) async => true);

        // Act
        final result = await useCase(numericUserId, UserRole.admin);

        // Assert
        expect(result, true);
      });
    });

    group('UserRole Enum Properties', () {
      test('UserRole.user should not have admin privileges', () {
        expect(UserRole.user.isAdmin, false);
        expect(UserRole.user.canManageAdmins, false);
      });

      test('UserRole.admin should have admin privileges', () {
        expect(UserRole.admin.isAdmin, true);
        expect(UserRole.admin.canManageAdmins, false);
      });

      test('UserRole.superAdmin should have all privileges', () {
        expect(UserRole.superAdmin.isAdmin, true);
        expect(UserRole.superAdmin.canManageAdmins, true);
      });

      test('UserRole display names should be correct', () {
        expect(UserRole.user.displayName, 'User');
        expect(UserRole.admin.displayName, 'Admin');
        expect(UserRole.superAdmin.displayName, 'Super Admin');
      });

      test('UserRole values should be correct', () {
        expect(UserRole.user.value, 'user');
        expect(UserRole.admin.value, 'admin');
        expect(UserRole.superAdmin.value, 'super_admin');
      });

      test('UserRole.fromString should parse correctly', () {
        expect(UserRole.fromString('user'), UserRole.user);
        expect(UserRole.fromString('admin'), UserRole.admin);
        expect(UserRole.fromString('super_admin'), UserRole.superAdmin);
      });

      test('UserRole.fromString should default to user for unknown values', () {
        expect(UserRole.fromString('unknown'), UserRole.user);
        expect(UserRole.fromString(''), UserRole.user);
        expect(UserRole.fromString('ADMIN'), UserRole.user);
      });
    });
  });
}
