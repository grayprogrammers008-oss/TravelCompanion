import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/auth/domain/entities/user_entity.dart';
import 'package:travel_crew/features/auth/domain/repositories/auth_repository.dart';
import 'package:travel_crew/features/auth/domain/usecases/sign_up_usecase.dart';

import 'sign_up_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late SignUpUseCase useCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = SignUpUseCase(mockAuthRepository);
  });

  const testEmail = 'test@example.com';
  const testPassword = 'password123';
  const testFullName = 'Test User';
  final now = DateTime.now();
  final testUser = UserEntity(
    id: '123',
    email: testEmail,
    fullName: testFullName,
    createdAt: now,
  );

  group('SignUpUseCase', () {
    group('Positive Cases', () {
      test('should sign up user with valid data', () async {
        // Arrange
        when(mockAuthRepository.signUp(
          email: testEmail,
          password: testPassword,
          fullName: testFullName,
        )).thenAnswer((_) async => testUser);

        // Act
        final result = await useCase(
          email: testEmail,
          password: testPassword,
          fullName: testFullName,
        );

        // Assert
        expect(result, equals(testUser));
        verify(mockAuthRepository.signUp(
          email: testEmail,
          password: testPassword,
          fullName: testFullName,
        )).called(1);
        verifyNoMoreInteractions(mockAuthRepository);
      });

      test('should sign up user with phone number', () async {
        // Arrange
        const phoneNumber = '+1234567890';
        final userWithPhone = UserEntity(
          id: '123',
          email: testEmail,
          fullName: testFullName,
          phoneNumber: phoneNumber,
          createdAt: now,
        );
        when(mockAuthRepository.signUp(
          email: testEmail,
          password: testPassword,
          fullName: testFullName,
          phoneNumber: phoneNumber,
        )).thenAnswer((_) async => userWithPhone);

        // Act
        final result = await useCase(
          email: testEmail,
          password: testPassword,
          fullName: testFullName,
          phoneNumber: phoneNumber,
        );

        // Assert
        expect(result.phoneNumber, phoneNumber);
        verify(mockAuthRepository.signUp(
          email: testEmail,
          password: testPassword,
          fullName: testFullName,
          phoneNumber: phoneNumber,
        )).called(1);
      });

      test('should sign up with exactly 8 character password (minimum length)', () async {
        // Arrange
        const minPassword = '12345678';
        when(mockAuthRepository.signUp(
          email: testEmail,
          password: minPassword,
          fullName: testFullName,
        )).thenAnswer((_) async => testUser);

        // Act
        final result = await useCase(
          email: testEmail,
          password: minPassword,
          fullName: testFullName,
        );

        // Assert
        expect(result, testUser);
      });

      test('should sign up with long password', () async {
        // Arrange
        final longPassword = 'a' * 100;
        when(mockAuthRepository.signUp(
          email: testEmail,
          password: longPassword,
          fullName: testFullName,
        )).thenAnswer((_) async => testUser);

        // Act
        final result = await useCase(
          email: testEmail,
          password: longPassword,
          fullName: testFullName,
        );

        // Assert
        expect(result, testUser);
      });

      test('should sign up with email containing special characters', () async {
        // Arrange
        const specialEmail = 'test+tag@sub.example.com';
        final userWithSpecialEmail = UserEntity(
          id: '456',
          email: specialEmail,
          fullName: testFullName,
          createdAt: now,
        );
        when(mockAuthRepository.signUp(
          email: specialEmail,
          password: testPassword,
          fullName: testFullName,
        )).thenAnswer((_) async => userWithSpecialEmail);

        // Act
        final result = await useCase(
          email: specialEmail,
          password: testPassword,
          fullName: testFullName,
        );

        // Assert
        expect(result.email, specialEmail);
      });

      test('should sign up with unicode full name', () async {
        // Arrange
        const unicodeName = 'José García 日本語';
        final userWithUnicodeName = UserEntity(
          id: '789',
          email: testEmail,
          fullName: unicodeName,
          createdAt: now,
        );
        when(mockAuthRepository.signUp(
          email: testEmail,
          password: testPassword,
          fullName: unicodeName,
        )).thenAnswer((_) async => userWithUnicodeName);

        // Act
        final result = await useCase(
          email: testEmail,
          password: testPassword,
          fullName: unicodeName,
        );

        // Assert
        expect(result.fullName, unicodeName);
      });

      test('should sign up with single character full name', () async {
        // Arrange
        const singleCharName = 'A';
        final userWithSingleName = UserEntity(
          id: '101',
          email: testEmail,
          fullName: singleCharName,
          createdAt: now,
        );
        when(mockAuthRepository.signUp(
          email: testEmail,
          password: testPassword,
          fullName: singleCharName,
        )).thenAnswer((_) async => userWithSingleName);

        // Act
        final result = await useCase(
          email: testEmail,
          password: testPassword,
          fullName: singleCharName,
        );

        // Assert
        expect(result.fullName, singleCharName);
      });

      test('should sign up with password containing special characters', () async {
        // Arrange
        const specialPassword = r'P@ssw0rd!#$%^&*()_+-=[]{}|;:,.<>?';
        when(mockAuthRepository.signUp(
          email: testEmail,
          password: specialPassword,
          fullName: testFullName,
        )).thenAnswer((_) async => testUser);

        // Act
        final result = await useCase(
          email: testEmail,
          password: specialPassword,
          fullName: testFullName,
        );

        // Assert
        expect(result, testUser);
      });

      test('should sign up with null phone number', () async {
        // Arrange
        when(mockAuthRepository.signUp(
          email: testEmail,
          password: testPassword,
          fullName: testFullName,
          phoneNumber: null,
        )).thenAnswer((_) async => testUser);

        // Act
        final result = await useCase(
          email: testEmail,
          password: testPassword,
          fullName: testFullName,
          phoneNumber: null,
        );

        // Assert
        expect(result, testUser);
      });
    });

    group('Negative Cases - Validation Errors', () {
      test('should throw exception when email is empty', () async {
        // Act & Assert
        expect(
          () => useCase(
            email: '',
            password: testPassword,
            fullName: testFullName,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Email, password, and full name are required'),
          )),
        );
        verifyNever(mockAuthRepository.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          fullName: anyNamed('fullName'),
        ));
      });

      test('should throw exception when password is empty', () async {
        // Act & Assert
        expect(
          () => useCase(
            email: testEmail,
            password: '',
            fullName: testFullName,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Email, password, and full name are required'),
          )),
        );
      });

      test('should throw exception when full name is empty', () async {
        // Act & Assert
        expect(
          () => useCase(
            email: testEmail,
            password: testPassword,
            fullName: '',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Email, password, and full name are required'),
          )),
        );
      });

      test('should throw exception when all fields are empty', () async {
        // Act & Assert
        expect(
          () => useCase(
            email: '',
            password: '',
            fullName: '',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Email, password, and full name are required'),
          )),
        );
      });

      test('should throw exception when password is too short (7 characters)', () async {
        // Act & Assert
        expect(
          () => useCase(
            email: testEmail,
            password: '1234567', // 7 characters
            fullName: testFullName,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Password must be at least 8 characters'),
          )),
        );
      });

      test('should throw exception when password is 1 character', () async {
        // Act & Assert
        expect(
          () => useCase(
            email: testEmail,
            password: 'a',
            fullName: testFullName,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Password must be at least 8 characters'),
          )),
        );
      });

      test('should throw exception when password is 3 characters', () async {
        // Act & Assert
        expect(
          () => useCase(
            email: testEmail,
            password: '123',
            fullName: testFullName,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Password must be at least 8 characters'),
          )),
        );
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should throw exception when email is already in use', () async {
        // Arrange
        when(mockAuthRepository.signUp(
          email: testEmail,
          password: testPassword,
          fullName: testFullName,
        )).thenThrow(Exception('Email already in use'));

        // Act & Assert
        expect(
          () => useCase(
            email: testEmail,
            password: testPassword,
            fullName: testFullName,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Email already in use'),
          )),
        );
      });

      test('should propagate exception for network error', () async {
        // Arrange
        when(mockAuthRepository.signUp(
          email: testEmail,
          password: testPassword,
          fullName: testFullName,
        )).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => useCase(
            email: testEmail,
            password: testPassword,
            fullName: testFullName,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network error'),
          )),
        );
      });

      test('should propagate exception for server error', () async {
        // Arrange
        when(mockAuthRepository.signUp(
          email: testEmail,
          password: testPassword,
          fullName: testFullName,
        )).thenThrow(Exception('Internal server error'));

        // Act & Assert
        expect(
          () => useCase(
            email: testEmail,
            password: testPassword,
            fullName: testFullName,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Internal server error'),
          )),
        );
      });

      test('should propagate exception for invalid email format from server', () async {
        // Arrange
        when(mockAuthRepository.signUp(
          email: 'invalidemail',
          password: testPassword,
          fullName: testFullName,
        )).thenThrow(Exception('Invalid email format'));

        // Act & Assert
        expect(
          () => useCase(
            email: 'invalidemail',
            password: testPassword,
            fullName: testFullName,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid email format'),
          )),
        );
      });

      test('should propagate exception for timeout', () async {
        // Arrange
        when(mockAuthRepository.signUp(
          email: testEmail,
          password: testPassword,
          fullName: testFullName,
        )).thenThrow(Exception('Request timed out'));

        // Act & Assert
        expect(
          () => useCase(
            email: testEmail,
            password: testPassword,
            fullName: testFullName,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Request timed out'),
          )),
        );
      });

      test('should propagate exception for rate limiting', () async {
        // Arrange
        when(mockAuthRepository.signUp(
          email: testEmail,
          password: testPassword,
          fullName: testFullName,
        )).thenThrow(Exception('Too many requests'));

        // Act & Assert
        expect(
          () => useCase(
            email: testEmail,
            password: testPassword,
            fullName: testFullName,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Too many requests'),
          )),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle whitespace-only email (passes to repository)', () async {
        // Note: Current implementation checks for isEmpty, not isBlank
        when(mockAuthRepository.signUp(
          email: '   ',
          password: testPassword,
          fullName: testFullName,
        )).thenThrow(Exception('Invalid email'));

        expect(
          () => useCase(
            email: '   ',
            password: testPassword,
            fullName: testFullName,
          ),
          throwsA(isA<Exception>()),
        );
        verify(mockAuthRepository.signUp(
          email: '   ',
          password: testPassword,
          fullName: testFullName,
        )).called(1);
      });

      test('should handle whitespace-only full name (passes to repository)', () async {
        // Note: Current implementation checks for isEmpty, not isBlank
        when(mockAuthRepository.signUp(
          email: testEmail,
          password: testPassword,
          fullName: '   ',
        )).thenAnswer((_) async => testUser);

        final result = await useCase(
          email: testEmail,
          password: testPassword,
          fullName: '   ',
        );

        expect(result, testUser);
      });

      test('should handle email with leading/trailing spaces', () async {
        // Arrange
        const emailWithSpaces = ' test@example.com ';
        when(mockAuthRepository.signUp(
          email: emailWithSpaces,
          password: testPassword,
          fullName: testFullName,
        )).thenAnswer((_) async => testUser);

        // Act
        final result = await useCase(
          email: emailWithSpaces,
          password: testPassword,
          fullName: testFullName,
        );

        // Assert
        expect(result, testUser);
      });

      test('should handle full name with leading/trailing spaces', () async {
        // Arrange
        const nameWithSpaces = ' Test User ';
        when(mockAuthRepository.signUp(
          email: testEmail,
          password: testPassword,
          fullName: nameWithSpaces,
        )).thenAnswer((_) async => testUser);

        // Act
        final result = await useCase(
          email: testEmail,
          password: testPassword,
          fullName: nameWithSpaces,
        );

        // Assert
        expect(result, testUser);
      });

      test('should handle very long full name', () async {
        // Arrange
        final longName = 'A' * 500;
        final userWithLongName = UserEntity(
          id: '999',
          email: testEmail,
          fullName: longName,
          createdAt: now,
        );
        when(mockAuthRepository.signUp(
          email: testEmail,
          password: testPassword,
          fullName: longName,
        )).thenAnswer((_) async => userWithLongName);

        // Act
        final result = await useCase(
          email: testEmail,
          password: testPassword,
          fullName: longName,
        );

        // Assert
        expect(result.fullName, longName);
      });

      test('should handle phone number with different formats', () async {
        // Arrange
        const phoneFormats = [
          '+1-234-567-8901',
          '(123) 456-7890',
          '123.456.7890',
          '+44 20 7123 4567',
        ];

        for (final phone in phoneFormats) {
          when(mockAuthRepository.signUp(
            email: testEmail,
            password: testPassword,
            fullName: testFullName,
            phoneNumber: phone,
          )).thenAnswer((_) async => testUser);

          // Act
          await useCase(
            email: testEmail,
            password: testPassword,
            fullName: testFullName,
            phoneNumber: phone,
          );

          // Assert
          verify(mockAuthRepository.signUp(
            email: testEmail,
            password: testPassword,
            fullName: testFullName,
            phoneNumber: phone,
          )).called(1);
        }
      });
    });
  });
}
