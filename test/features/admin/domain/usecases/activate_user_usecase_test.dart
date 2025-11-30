import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/admin/domain/repositories/admin_repository.dart';
import 'package:travel_crew/features/admin/domain/usecases/activate_user_usecase.dart';

import 'activate_user_usecase_test.mocks.dart';

@GenerateMocks([AdminRepository])
void main() {
  late ActivateUserUseCase useCase;
  late MockAdminRepository mockRepository;

  setUp(() {
    mockRepository = MockAdminRepository();
    useCase = ActivateUserUseCase(mockRepository);
  });

  group('ActivateUserUseCase', () {
    group('Positive Cases', () {
      test('should activate user successfully', () async {
        // Arrange
        when(mockRepository.activateUser(any)).thenAnswer((_) async => true);

        // Act
        final result = await useCase('user-123');

        // Assert
        expect(result, true);
        verify(mockRepository.activateUser('user-123')).called(1);
      });

      test('should activate previously suspended user', () async {
        // Arrange
        when(mockRepository.activateUser(any)).thenAnswer((_) async => true);

        // Act
        final result = await useCase('suspended-user-456');

        // Assert
        expect(result, true);
        verify(mockRepository.activateUser('suspended-user-456')).called(1);
      });

      test('should return true for already active user (idempotent)', () async {
        // Arrange
        when(mockRepository.activateUser(any)).thenAnswer((_) async => true);

        // Act
        final result = await useCase('already-active-user');

        // Assert
        expect(result, true);
      });

      test('should handle UUID format user ID', () async {
        // Arrange
        const uuidUserId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        when(mockRepository.activateUser(any)).thenAnswer((_) async => true);

        // Act
        final result = await useCase(uuidUserId);

        // Assert
        expect(result, true);
        verify(mockRepository.activateUser(uuidUserId)).called(1);
      });

      test('should handle short user ID', () async {
        // Arrange
        when(mockRepository.activateUser(any)).thenAnswer((_) async => true);

        // Act
        final result = await useCase('u1');

        // Assert
        expect(result, true);
      });

      test('should handle user ID with special characters', () async {
        // Arrange
        const userId = 'user_123-abc';
        when(mockRepository.activateUser(any)).thenAnswer((_) async => true);

        // Act
        final result = await useCase(userId);

        // Assert
        expect(result, true);
        verify(mockRepository.activateUser(userId)).called(1);
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw Exception for empty user ID', () async {
        // Act & Assert
        expect(
          () => useCase(''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User ID cannot be empty'),
          )),
        );
        verifyNever(mockRepository.activateUser(any));
      });

      test('should not call repository when user ID is empty', () async {
        // Act
        try {
          await useCase('');
        } catch (_) {}

        // Assert
        verifyNever(mockRepository.activateUser(any));
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should propagate repository exception', () async {
        // Arrange
        when(mockRepository.activateUser(any))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => useCase('user-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Database error'),
          )),
        );
      });

      test('should handle network error', () async {
        // Arrange
        when(mockRepository.activateUser(any))
            .thenThrow(Exception('Network unavailable'));

        // Act & Assert
        expect(
          () => useCase('user-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network unavailable'),
          )),
        );
      });

      test('should handle user not found error', () async {
        // Arrange
        when(mockRepository.activateUser(any))
            .thenThrow(Exception('User not found'));

        // Act & Assert
        expect(
          () => useCase('nonexistent-user'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User not found'),
          )),
        );
      });

      test('should handle permission denied error', () async {
        // Arrange
        when(mockRepository.activateUser(any))
            .thenThrow(Exception('Permission denied: Admin access required'));

        // Act & Assert
        expect(
          () => useCase('user-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Permission denied'),
          )),
        );
      });

      test('should handle already deleted user error', () async {
        // Arrange
        when(mockRepository.activateUser(any))
            .thenThrow(Exception('User has been permanently deleted'));

        // Act & Assert
        expect(
          () => useCase('deleted-user'),
          throwsA(isA<Exception>()),
        );
      });

      test('should return false when activation fails', () async {
        // Arrange
        when(mockRepository.activateUser(any)).thenAnswer((_) async => false);

        // Act
        final result = await useCase('user-123');

        // Assert
        expect(result, false);
      });
    });

    group('Edge Cases', () {
      test('should handle very long user ID', () async {
        // Arrange
        final longUserId = 'user-${'a' * 500}';
        when(mockRepository.activateUser(any)).thenAnswer((_) async => true);

        // Act
        final result = await useCase(longUserId);

        // Assert
        expect(result, true);
        verify(mockRepository.activateUser(longUserId)).called(1);
      });

      test('should handle user ID with leading/trailing spaces (not trimmed)', () async {
        // Arrange - note: usecase does not trim, passes as-is
        const userIdWithSpaces = '  user-123  ';
        when(mockRepository.activateUser(any)).thenAnswer((_) async => true);

        // Act
        final result = await useCase(userIdWithSpaces);

        // Assert
        expect(result, true);
        verify(mockRepository.activateUser(userIdWithSpaces)).called(1);
      });

      test('should handle numeric user ID', () async {
        // Arrange
        const numericUserId = '12345678';
        when(mockRepository.activateUser(any)).thenAnswer((_) async => true);

        // Act
        final result = await useCase(numericUserId);

        // Assert
        expect(result, true);
      });

      test('should handle rapid successive activations', () async {
        // Arrange
        when(mockRepository.activateUser(any)).thenAnswer((_) async => true);

        // Act
        final results = await Future.wait([
          useCase('user-1'),
          useCase('user-2'),
          useCase('user-3'),
        ]);

        // Assert
        expect(results, [true, true, true]);
        verify(mockRepository.activateUser('user-1')).called(1);
        verify(mockRepository.activateUser('user-2')).called(1);
        verify(mockRepository.activateUser('user-3')).called(1);
      });

      test('should handle activating same user multiple times', () async {
        // Arrange
        when(mockRepository.activateUser(any)).thenAnswer((_) async => true);

        // Act
        await useCase('user-123');
        await useCase('user-123');
        await useCase('user-123');

        // Assert
        verify(mockRepository.activateUser('user-123')).called(3);
      });
    });
  });
}
