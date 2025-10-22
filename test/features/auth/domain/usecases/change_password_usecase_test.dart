import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/auth/domain/repositories/auth_repository.dart';
import 'package:travel_crew/features/auth/domain/usecases/change_password_usecase.dart';

import 'change_password_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late ChangePasswordUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = ChangePasswordUseCase(mockRepository);
  });

  group('ChangePasswordUseCase', () {
    const tCurrentPassword = 'OldPassword123';
    const tNewPassword = 'NewPassword456';

    test('should change password successfully with valid inputs', () async {
      // arrange
      when(mockRepository.changePassword(
        currentPassword: anyNamed('currentPassword'),
        newPassword: anyNamed('newPassword'),
      )).thenAnswer((_) async => Future.value());

      // act
      await useCase(
        currentPassword: tCurrentPassword,
        newPassword: tNewPassword,
      );

      // assert
      verify(mockRepository.changePassword(
        currentPassword: tCurrentPassword,
        newPassword: tNewPassword,
      ));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should throw exception when current password is empty', () async {
      // act & assert
      expect(
        () => useCase(
          currentPassword: '',
          newPassword: tNewPassword,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Current password is required'),
        )),
      );

      verifyNever(mockRepository.changePassword(
        currentPassword: anyNamed('currentPassword'),
        newPassword: anyNamed('newPassword'),
      ));
    });

    test('should throw exception when new password is empty', () async {
      // act & assert
      expect(
        () => useCase(
          currentPassword: tCurrentPassword,
          newPassword: '',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('New password is required'),
        )),
      );

      verifyNever(mockRepository.changePassword(
        currentPassword: anyNamed('currentPassword'),
        newPassword: anyNamed('newPassword'),
      ));
    });

    test('should throw exception when new password is too short', () async {
      // act & assert
      expect(
        () => useCase(
          currentPassword: tCurrentPassword,
          newPassword: 'Ab1', // Only 3 characters
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('must be at least 6 characters'),
        )),
      );

      verifyNever(mockRepository.changePassword(
        currentPassword: anyNamed('currentPassword'),
        newPassword: anyNamed('newPassword'),
      ));
    });

    test('should throw exception when new password same as current', () async {
      // act & assert
      expect(
        () => useCase(
          currentPassword: tCurrentPassword,
          newPassword: tCurrentPassword, // Same as current
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('must be different from current password'),
        )),
      );

      verifyNever(mockRepository.changePassword(
        currentPassword: anyNamed('currentPassword'),
        newPassword: anyNamed('newPassword'),
      ));
    });

    test('should throw exception when password lacks uppercase', () async {
      // act & assert
      expect(
        () => useCase(
          currentPassword: tCurrentPassword,
          newPassword: 'newpassword123', // No uppercase
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('uppercase'),
        )),
      );

      verifyNever(mockRepository.changePassword(
        currentPassword: anyNamed('currentPassword'),
        newPassword: anyNamed('newPassword'),
      ));
    });

    test('should throw exception when password lacks lowercase', () async {
      // act & assert
      expect(
        () => useCase(
          currentPassword: tCurrentPassword,
          newPassword: 'NEWPASSWORD123', // No lowercase
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('lowercase'),
        )),
      );

      verifyNever(mockRepository.changePassword(
        currentPassword: anyNamed('currentPassword'),
        newPassword: anyNamed('newPassword'),
      ));
    });

    test('should throw exception when password lacks number', () async {
      // act & assert
      expect(
        () => useCase(
          currentPassword: tCurrentPassword,
          newPassword: 'NewPassword', // No number
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('number'),
        )),
      );

      verifyNever(mockRepository.changePassword(
        currentPassword: anyNamed('currentPassword'),
        newPassword: anyNamed('newPassword'),
      ));
    });

    test('should accept password with uppercase, lowercase, and number', () async {
      // arrange
      when(mockRepository.changePassword(
        currentPassword: anyNamed('currentPassword'),
        newPassword: anyNamed('newPassword'),
      )).thenAnswer((_) async => Future.value());

      final validPasswords = [
        'Password1',
        'MyPass123',
        'Secure9Pass',
        'Test1234Password',
        '1NewPass',
      ];

      for (final password in validPasswords) {
        // act
        await useCase(
          currentPassword: tCurrentPassword,
          newPassword: password,
        );

        // assert
        verify(mockRepository.changePassword(
          currentPassword: tCurrentPassword,
          newPassword: password,
        ));
      }
    });

    test('should propagate repository exceptions', () async {
      // arrange
      when(mockRepository.changePassword(
        currentPassword: anyNamed('currentPassword'),
        newPassword: anyNamed('newPassword'),
      )).throwError(Exception('Current password is incorrect'));

      // act & assert
      expect(
        () => useCase(
          currentPassword: tCurrentPassword,
          newPassword: tNewPassword,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Current password is incorrect'),
        )),
      );
    });
  });
}
