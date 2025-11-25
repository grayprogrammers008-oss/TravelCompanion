import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:travel_crew/features/admin/data/models/admin_user_model.dart';
import 'package:travel_crew/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_user.dart';
import 'package:travel_crew/features/admin/domain/entities/user_role.dart';
import 'package:travel_crew/features/admin/domain/entities/user_status.dart';

import 'admin_repository_impl_test.mocks.dart';

@GenerateMocks([AdminRemoteDataSource])
void main() {
  late AdminRepositoryImpl repository;
  late MockAdminRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockAdminRemoteDataSource();
    repository = AdminRepositoryImpl(mockDataSource);
  });

  group('AdminRepositoryImpl', () {
    final tUserModel = AdminUserModel(
      id: 'user-123',
      email: 'test@example.com',
      fullName: 'Test User',
      role: UserRole.user,
      status: UserStatus.active,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      loginCount: 10,
      tripsCount: 5,
      messagesCount: 100,
      expensesCount: 20,
      totalExpenses: 500.0,
    );

    group('isAdmin', () {
      test('should return true when user is admin', () async {
        // Arrange
        when(mockDataSource.isAdmin()).thenAnswer((_) async => true);

        // Act
        final result = await repository.isAdmin();

        // Assert
        expect(result, true);
        verify(mockDataSource.isAdmin()).called(1);
        verifyNoMoreInteractions(mockDataSource);
      });

      test('should return false when user is not admin', () async {
        // Arrange
        when(mockDataSource.isAdmin()).thenAnswer((_) async => false);

        // Act
        final result = await repository.isAdmin();

        // Assert
        expect(result, false);
        verify(mockDataSource.isAdmin()).called(1);
      });

      test('should propagate exception from datasource', () async {
        // Arrange
        when(mockDataSource.isAdmin()).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(() => repository.isAdmin(), throwsException);
        verify(mockDataSource.isAdmin()).called(1);
      });
    });

    group('getAllUsers', () {
      test('should return list of users from datasource', () async {
        // Arrange
        final tUserModels = [tUserModel];
        when(mockDataSource.getAllUsers(
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
          search: anyNamed('search'),
          role: anyNamed('role'),
          status: anyNamed('status'),
        )).thenAnswer((_) async => tUserModels);

        // Act
        final result = await repository.getAllUsers();

        // Assert
        expect(result, isA<List<AdminUser>>());
        expect(result.length, 1);
        expect(result.first.id, tUserModel.id);
        verify(mockDataSource.getAllUsers(
          limit: 50,
          offset: 0,
          search: null,
          role: null,
          status: null,
        )).called(1);
      });

      test('should pass parameters to datasource', () async {
        // Arrange
        when(mockDataSource.getAllUsers(
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
          search: anyNamed('search'),
          role: anyNamed('role'),
          status: anyNamed('status'),
        )).thenAnswer((_) async => []);

        // Act
        await repository.getAllUsers(
          limit: 10,
          offset: 20,
          search: 'test',
          role: UserRole.admin,
          status: UserStatus.active,
        );

        // Assert
        verify(mockDataSource.getAllUsers(
          limit: 10,
          offset: 20,
          search: 'test',
          role: UserRole.admin,
          status: UserStatus.active,
        )).called(1);
      });

      test('should return empty list when no users found', () async {
        // Arrange
        when(mockDataSource.getAllUsers(
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
          search: anyNamed('search'),
          role: anyNamed('role'),
          status: anyNamed('status'),
        )).thenAnswer((_) async => []);

        // Act
        final result = await repository.getAllUsers();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('getUserById', () {
      test('should return user when found', () async {
        // Arrange
        when(mockDataSource.getUserById(any))
            .thenAnswer((_) async => tUserModel);

        // Act
        final result = await repository.getUserById('user-123');

        // Assert
        expect(result, isA<AdminUser>());
        expect(result.id, tUserModel.id);
        verify(mockDataSource.getUserById('user-123')).called(1);
      });

      test('should propagate exception when user not found', () async {
        // Arrange
        when(mockDataSource.getUserById(any))
            .thenThrow(Exception('User not found'));

        // Act & Assert
        expect(() => repository.getUserById('invalid'), throwsException);
      });
    });

    group('suspendUser', () {
      test('should suspend user successfully', () async {
        // Arrange
        when(mockDataSource.suspendUser(any, any))
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.suspendUser('user-123', 'Violation');

        // Assert
        expect(result, true);
        verify(mockDataSource.suspendUser('user-123', 'Violation')).called(1);
      });

      test('should return false when suspension fails', () async {
        // Arrange
        when(mockDataSource.suspendUser(any, any))
            .thenAnswer((_) async => false);

        // Act
        final result = await repository.suspendUser('user-123', 'Violation');

        // Assert
        expect(result, false);
      });
    });

    group('activateUser', () {
      test('should activate user successfully', () async {
        // Arrange
        when(mockDataSource.activateUser(any)).thenAnswer((_) async => true);

        // Act
        final result = await repository.activateUser('user-123');

        // Assert
        expect(result, true);
        verify(mockDataSource.activateUser('user-123')).called(1);
      });

      test('should return false when activation fails', () async {
        // Arrange
        when(mockDataSource.activateUser(any)).thenAnswer((_) async => false);

        // Act
        final result = await repository.activateUser('user-123');

        // Assert
        expect(result, false);
      });
    });

    group('updateUserRole', () {
      test('should update user role successfully', () async {
        // Arrange
        when(mockDataSource.updateUserRole(any, any))
            .thenAnswer((_) async => true);

        // Act
        final result =
            await repository.updateUserRole('user-123', UserRole.admin);

        // Assert
        expect(result, true);
        verify(mockDataSource.updateUserRole('user-123', UserRole.admin))
            .called(1);
      });

      test('should return false when update fails', () async {
        // Arrange
        when(mockDataSource.updateUserRole(any, any))
            .thenAnswer((_) async => false);

        // Act
        final result =
            await repository.updateUserRole('user-123', UserRole.admin);

        // Assert
        expect(result, false);
      });
    });

    group('updateUserProfile', () {
      test('should update user profile successfully', () async {
        // Arrange
        final updatedUserModel = AdminUserModel(
          id: tUserModel.id,
          email: tUserModel.email,
          fullName: 'New Name',
          avatarUrl: tUserModel.avatarUrl,
          role: tUserModel.role,
          status: tUserModel.status,
          createdAt: tUserModel.createdAt,
          updatedAt: tUserModel.updatedAt,
          lastLoginAt: tUserModel.lastLoginAt,
          lastActiveAt: tUserModel.lastActiveAt,
          accountLockedAt: tUserModel.accountLockedAt,
          accountLockedReason: tUserModel.accountLockedReason,
          loginCount: tUserModel.loginCount,
          tripsCount: tUserModel.tripsCount,
          messagesCount: tUserModel.messagesCount,
          expensesCount: tUserModel.expensesCount,
          totalExpenses: tUserModel.totalExpenses,
        );
        when(mockDataSource.updateUserProfile(
          any,
          fullName: anyNamed('fullName'),
          avatarUrl: anyNamed('avatarUrl'),
        )).thenAnswer((_) async => updatedUserModel);

        // Act
        final result = await repository.updateUserProfile(
          'user-123',
          fullName: 'New Name',
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        // Assert
        expect(result, isA<AdminUser>());
        expect(result.fullName, 'New Name');
        verify(mockDataSource.updateUserProfile(
          'user-123',
          fullName: 'New Name',
          avatarUrl: 'https://example.com/avatar.jpg',
        )).called(1);
      });

      test('should handle partial updates', () async {
        // Arrange
        final updatedUserModel = AdminUserModel(
          id: tUserModel.id,
          email: tUserModel.email,
          fullName: 'New Name',
          avatarUrl: tUserModel.avatarUrl,
          role: tUserModel.role,
          status: tUserModel.status,
          createdAt: tUserModel.createdAt,
          updatedAt: tUserModel.updatedAt,
          lastLoginAt: tUserModel.lastLoginAt,
          lastActiveAt: tUserModel.lastActiveAt,
          accountLockedAt: tUserModel.accountLockedAt,
          accountLockedReason: tUserModel.accountLockedReason,
          loginCount: tUserModel.loginCount,
          tripsCount: tUserModel.tripsCount,
          messagesCount: tUserModel.messagesCount,
          expensesCount: tUserModel.expensesCount,
          totalExpenses: tUserModel.totalExpenses,
        );
        when(mockDataSource.updateUserProfile(
          any,
          fullName: anyNamed('fullName'),
          avatarUrl: anyNamed('avatarUrl'),
        )).thenAnswer((_) async => updatedUserModel);

        // Act
        final result = await repository.updateUserProfile(
          'user-123',
          fullName: 'New Name',
        );

        // Assert
        expect(result, isA<AdminUser>());
        verify(mockDataSource.updateUserProfile(
          'user-123',
          fullName: 'New Name',
          avatarUrl: null,
        )).called(1);
      });
    });
  });
}
