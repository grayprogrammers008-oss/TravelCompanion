import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_user.dart';
import 'package:travel_crew/features/admin/domain/entities/user_role.dart';
import 'package:travel_crew/features/admin/domain/entities/user_status.dart';
import 'package:travel_crew/features/admin/domain/repositories/admin_repository.dart';
import 'package:travel_crew/features/admin/domain/usecases/get_all_users_usecase.dart';

import 'get_all_users_usecase_test.mocks.dart';

@GenerateMocks([AdminRepository])
void main() {
  late GetAllUsersUseCase useCase;
  late MockAdminRepository mockRepository;

  setUp(() {
    mockRepository = MockAdminRepository();
    useCase = GetAllUsersUseCase(mockRepository);
  });

  group('GetAllUsersUseCase', () {
    final tUsers = [
      AdminUser(
        id: 'user-1',
        email: 'user1@example.com',
        fullName: 'User One',
        role: UserRole.user,
        status: UserStatus.active,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        loginCount: 10,
        tripsCount: 5,
        messagesCount: 100,
        expensesCount: 20,
        totalExpenses: 500.0,
      ),
      AdminUser(
        id: 'user-2',
        email: 'admin@example.com',
        fullName: 'Admin User',
        role: UserRole.admin,
        status: UserStatus.active,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        loginCount: 50,
        tripsCount: 2,
        messagesCount: 200,
        expensesCount: 10,
        totalExpenses: 300.0,
      ),
    ];

    test('should get all users with default parameters', () async {
      // Arrange
      when(mockRepository.getAllUsers(
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
        search: anyNamed('search'),
        role: anyNamed('role'),
        status: anyNamed('status'),
      )).thenAnswer((_) async => tUsers);

      // Act
      final result = await useCase();

      // Assert
      expect(result, tUsers);
      expect(result.length, 2);
      verify(mockRepository.getAllUsers(
        limit: 50,
        offset: 0,
        search: null,
        role: null,
        status: null,
      )).called(1);
    });

    test('should get users with search filter', () async {
      // Arrange
      const tSearch = 'admin';
      final tFilteredUsers = [tUsers[1]];

      when(mockRepository.getAllUsers(
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
        search: anyNamed('search'),
        role: anyNamed('role'),
        status: anyNamed('status'),
      )).thenAnswer((_) async => tFilteredUsers);

      // Act
      final result = await useCase(search: tSearch);

      // Assert
      expect(result, tFilteredUsers);
      expect(result.length, 1);
      verify(mockRepository.getAllUsers(
        limit: 50,
        offset: 0,
        search: tSearch,
        role: null,
        status: null,
      )).called(1);
    });

    test('should get users with role filter', () async {
      // Arrange
      final tFilteredUsers = [tUsers[1]];

      when(mockRepository.getAllUsers(
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
        search: anyNamed('search'),
        role: anyNamed('role'),
        status: anyNamed('status'),
      )).thenAnswer((_) async => tFilteredUsers);

      // Act
      final result = await useCase(role: UserRole.admin);

      // Assert
      expect(result, tFilteredUsers);
      verify(mockRepository.getAllUsers(
        limit: 50,
        offset: 0,
        search: null,
        role: UserRole.admin,
        status: null,
      )).called(1);
    });

    test('should get users with pagination', () async {
      // Arrange
      when(mockRepository.getAllUsers(
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
        search: anyNamed('search'),
        role: anyNamed('role'),
        status: anyNamed('status'),
      )).thenAnswer((_) async => tUsers);

      // Act
      final result = await useCase(limit: 10, offset: 20);

      // Assert
      expect(result, tUsers);
      verify(mockRepository.getAllUsers(
        limit: 10,
        offset: 20,
        search: null,
        role: null,
        status: null,
      )).called(1);
    });

    test('should return empty list when no users found', () async {
      // Arrange
      when(mockRepository.getAllUsers(
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
        search: anyNamed('search'),
        role: anyNamed('role'),
        status: anyNamed('status'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await useCase();

      // Assert
      expect(result, isEmpty);
      verify(mockRepository.getAllUsers(
        limit: 50,
        offset: 0,
        search: null,
        role: null,
        status: null,
      )).called(1);
    });

    test('should throw exception when repository fails', () async {
      // Arrange
      when(mockRepository.getAllUsers(
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
        search: anyNamed('search'),
        role: anyNamed('role'),
        status: anyNamed('status'),
      )).thenThrow(Exception('Database error'));

      // Act & Assert
      expect(() => useCase(), throwsException);
    });
  });
}
