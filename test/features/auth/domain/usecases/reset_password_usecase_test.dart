import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/auth/domain/repositories/auth_repository.dart';
import 'package:travel_crew/features/auth/domain/usecases/reset_password_usecase.dart';

import 'reset_password_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late ResetPasswordUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = ResetPasswordUseCase(mockRepository);
  });

  group('ResetPasswordUseCase', () {
    const testEmail = 'test@example.com';

    test('should call repository resetPassword with correct email', () async {
      // Arrange
      when(mockRepository.resetPassword(any))
          .thenAnswer((_) async => Future.value());

      // Act
      await useCase(testEmail);

      // Assert
      verify(mockRepository.resetPassword(testEmail)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should trim email before calling repository', () async {
      // Arrange
      const emailWithSpaces = '  test@example.com  ';
      when(mockRepository.resetPassword(any))
          .thenAnswer((_) async => Future.value());

      // Act
      await useCase(emailWithSpaces);

      // Assert
      verify(mockRepository.resetPassword(testEmail)).called(1);
    });

    test('should throw exception when email is empty', () async {
      // Act & Assert
      expect(
        () => useCase(''),
        throwsA(predicate((e) =>
            e is Exception && e.toString().contains('Email cannot be empty'))),
      );

      verifyNever(mockRepository.resetPassword(any));
    });

    test('should throw exception when email is only whitespace', () async {
      // Act & Assert
      expect(
        () => useCase('   '),
        throwsA(predicate((e) =>
            e is Exception && e.toString().contains('Email cannot be empty'))),
      );

      verifyNever(mockRepository.resetPassword(any));
    });

    test('should throw exception when email format is invalid', () async {
      // Arrange
      const invalidEmails = [
        'notanemail',
        'missing@domain',
        '@nodomain.com',
        'no@domain@extra.com',
        'spaces in@email.com',
      ];

      for (final invalidEmail in invalidEmails) {
        // Act & Assert
        expect(
          () => useCase(invalidEmail),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('Invalid email format'))),
          reason: 'Failed for email: $invalidEmail',
        );
      }

      verifyNever(mockRepository.resetPassword(any));
    });

    test('should accept valid email formats', () async {
      // Arrange
      const validEmails = [
        'test@example.com',
        'user.name@example.co.uk',
        'first+last@subdomain.example.org',
        'numbers123@test.io',
      ];

      when(mockRepository.resetPassword(any))
          .thenAnswer((_) async => Future.value());

      for (final validEmail in validEmails) {
        // Act
        await useCase(validEmail);

        // Assert
        verify(mockRepository.resetPassword(validEmail)).called(1);
      }
    });

    test('should propagate repository exceptions', () async {
      // Arrange
      final exception = Exception('Network error');
      when(mockRepository.resetPassword(any)).thenThrow(exception);

      // Act & Assert
      expect(
        () => useCase(testEmail),
        throwsA(exception),
      );
    });

    test('should handle Supabase-specific errors', () async {
      // Arrange
      final exception = Exception('Password reset failed: User not found');
      when(mockRepository.resetPassword(any)).thenThrow(exception);

      // Act & Assert
      expect(
        () => useCase(testEmail),
        throwsA(predicate((e) =>
            e is Exception && e.toString().contains('User not found'))),
      );
    });
  });
}
