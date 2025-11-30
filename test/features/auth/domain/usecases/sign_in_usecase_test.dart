import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/auth/domain/entities/user_entity.dart';
import 'package:travel_crew/features/auth/domain/repositories/auth_repository.dart';
import 'package:travel_crew/features/auth/domain/usecases/sign_in_usecase.dart';

import 'sign_in_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late SignInUseCase useCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = SignInUseCase(mockAuthRepository);
  });

  const testEmail = 'test@example.com';
  const testPassword = 'password123';
  final now = DateTime.now();
  final testUser = UserEntity(
    id: '123',
    email: testEmail,
    fullName: 'Test User',
    createdAt: now,
  );

  group('SignInUseCase', () {
    group('Positive Cases', () {
      test('should sign in user with valid credentials', () async {
        // Arrange
        when(mockAuthRepository.signIn(
          email: testEmail,
          password: testPassword,
        )).thenAnswer((_) async => testUser);

        // Act
        final result = await useCase(
          email: testEmail,
          password: testPassword,
        );

        // Assert
        expect(result, equals(testUser));
        verify(mockAuthRepository.signIn(
          email: testEmail,
          password: testPassword,
        )).called(1);
        verifyNoMoreInteractions(mockAuthRepository);
      });

      test('should sign in with email containing special characters', () async {
        // Arrange
        const specialEmail = 'test+tag@sub.example.com';
        final userWithSpecialEmail = UserEntity(
          id: 'user-456',
          email: specialEmail,
          createdAt: now,
        );
        when(mockAuthRepository.signIn(
          email: specialEmail,
          password: testPassword,
        )).thenAnswer((_) async => userWithSpecialEmail);

        // Act
        final result = await useCase(
          email: specialEmail,
          password: testPassword,
        );

        // Assert
        expect(result.email, specialEmail);
        verify(mockAuthRepository.signIn(
          email: specialEmail,
          password: testPassword,
        )).called(1);
      });

      test('should sign in with long password', () async {
        // Arrange
        final longPassword = 'a' * 100;
        when(mockAuthRepository.signIn(
          email: testEmail,
          password: longPassword,
        )).thenAnswer((_) async => testUser);

        // Act
        final result = await useCase(
          email: testEmail,
          password: longPassword,
        );

        // Assert
        expect(result, testUser);
        verify(mockAuthRepository.signIn(
          email: testEmail,
          password: longPassword,
        )).called(1);
      });

      test('should sign in with password containing special characters', () async {
        // Arrange
        const specialPassword = r'P@ssw0rd!#$%^&*()';
        when(mockAuthRepository.signIn(
          email: testEmail,
          password: specialPassword,
        )).thenAnswer((_) async => testUser);

        // Act
        final result = await useCase(
          email: testEmail,
          password: specialPassword,
        );

        // Assert
        expect(result, testUser);
        verify(mockAuthRepository.signIn(
          email: testEmail,
          password: specialPassword,
        )).called(1);
      });

      test('should return user with minimal fields populated', () async {
        // Arrange
        const minimalUser = UserEntity(
          id: 'user-789',
          email: 'minimal@example.com',
        );
        when(mockAuthRepository.signIn(
          email: 'minimal@example.com',
          password: testPassword,
        )).thenAnswer((_) async => minimalUser);

        // Act
        final result = await useCase(
          email: 'minimal@example.com',
          password: testPassword,
        );

        // Assert
        expect(result.id, 'user-789');
        expect(result.email, 'minimal@example.com');
        expect(result.fullName, isNull);
        expect(result.avatarUrl, isNull);
      });

      test('should return user with all fields populated', () async {
        // Arrange
        final fullUser = UserEntity(
          id: 'user-full',
          email: 'full@example.com',
          fullName: 'Full Name User',
          avatarUrl: 'https://example.com/avatar.jpg',
          phoneNumber: '+1234567890',
          bio: 'Travel enthusiast',
          createdAt: now,
          updatedAt: now,
        );
        when(mockAuthRepository.signIn(
          email: 'full@example.com',
          password: testPassword,
        )).thenAnswer((_) async => fullUser);

        // Act
        final result = await useCase(
          email: 'full@example.com',
          password: testPassword,
        );

        // Assert
        expect(result.id, 'user-full');
        expect(result.fullName, 'Full Name User');
        expect(result.avatarUrl, 'https://example.com/avatar.jpg');
        expect(result.phoneNumber, '+1234567890');
        expect(result.bio, 'Travel enthusiast');
      });

      test('should sign in with unicode email domain', () async {
        // Arrange
        const unicodeEmail = 'user@beispiel.de';
        const unicodeUser = UserEntity(
          id: 'user-unicode',
          email: unicodeEmail,
        );
        when(mockAuthRepository.signIn(
          email: unicodeEmail,
          password: testPassword,
        )).thenAnswer((_) async => unicodeUser);

        // Act
        final result = await useCase(
          email: unicodeEmail,
          password: testPassword,
        );

        // Assert
        expect(result.email, unicodeEmail);
      });

      test('should sign in with very short password (1 character)', () async {
        // Arrange - no min length validation in SignInUseCase
        const shortPassword = 'a';
        when(mockAuthRepository.signIn(
          email: testEmail,
          password: shortPassword,
        )).thenAnswer((_) async => testUser);

        // Act
        final result = await useCase(
          email: testEmail,
          password: shortPassword,
        );

        // Assert
        expect(result, testUser);
      });
    });

    group('Negative Cases - Validation Errors', () {
      test('should throw exception when email is empty', () async {
        // Arrange & Act & Assert
        expect(
          () => useCase(email: '', password: testPassword),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Email and password are required'),
          )),
        );
        verifyNever(mockAuthRepository.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ));
      });

      test('should throw exception when password is empty', () async {
        // Arrange & Act & Assert
        expect(
          () => useCase(email: testEmail, password: ''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Email and password are required'),
          )),
        );
        verifyNever(mockAuthRepository.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ));
      });

      test('should throw exception when both email and password are empty', () async {
        // Act & Assert
        expect(
          () => useCase(email: '', password: ''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Email and password are required'),
          )),
        );
        verifyNever(mockAuthRepository.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ));
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should throw exception when credentials are invalid', () async {
        // Arrange
        when(mockAuthRepository.signIn(
          email: testEmail,
          password: testPassword,
        )).thenThrow(Exception('Invalid credentials'));

        // Act & Assert
        expect(
          () => useCase(email: testEmail, password: testPassword),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid credentials'),
          )),
        );
        verify(mockAuthRepository.signIn(
          email: testEmail,
          password: testPassword,
        )).called(1);
      });

      test('should propagate exception for non-existent user', () async {
        // Arrange
        when(mockAuthRepository.signIn(
          email: 'nonexistent@example.com',
          password: testPassword,
        )).thenThrow(Exception('User not found'));

        // Act & Assert
        expect(
          () => useCase(email: 'nonexistent@example.com', password: testPassword),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User not found'),
          )),
        );
      });

      test('should propagate exception for network error', () async {
        // Arrange
        when(mockAuthRepository.signIn(
          email: testEmail,
          password: testPassword,
        )).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => useCase(email: testEmail, password: testPassword),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network error'),
          )),
        );
      });

      test('should propagate exception for server error', () async {
        // Arrange
        when(mockAuthRepository.signIn(
          email: testEmail,
          password: testPassword,
        )).thenThrow(Exception('Internal server error'));

        // Act & Assert
        expect(
          () => useCase(email: testEmail, password: testPassword),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Internal server error'),
          )),
        );
      });

      test('should propagate exception for account locked', () async {
        // Arrange
        when(mockAuthRepository.signIn(
          email: 'locked@example.com',
          password: testPassword,
        )).thenThrow(Exception('Account is locked'));

        // Act & Assert
        expect(
          () => useCase(email: 'locked@example.com', password: testPassword),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Account is locked'),
          )),
        );
      });

      test('should propagate exception for email not verified', () async {
        // Arrange
        when(mockAuthRepository.signIn(
          email: 'unverified@example.com',
          password: testPassword,
        )).thenThrow(Exception('Email not verified'));

        // Act & Assert
        expect(
          () => useCase(email: 'unverified@example.com', password: testPassword),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Email not verified'),
          )),
        );
      });

      test('should propagate exception for timeout', () async {
        // Arrange
        when(mockAuthRepository.signIn(
          email: testEmail,
          password: testPassword,
        )).thenThrow(Exception('Request timed out'));

        // Act & Assert
        expect(
          () => useCase(email: testEmail, password: testPassword),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Request timed out'),
          )),
        );
      });

      test('should propagate exception for rate limiting', () async {
        // Arrange
        when(mockAuthRepository.signIn(
          email: testEmail,
          password: testPassword,
        )).thenThrow(Exception('Too many requests'));

        // Act & Assert
        expect(
          () => useCase(email: testEmail, password: testPassword),
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
        // Whitespace-only strings are NOT caught by isEmpty
        when(mockAuthRepository.signIn(
          email: '   ',
          password: testPassword,
        )).thenThrow(Exception('Invalid email format'));

        // Since '   '.isEmpty is false, it will pass validation and call repository
        expect(
          () => useCase(email: '   ', password: testPassword),
          throwsA(isA<Exception>()),
        );
        verify(mockAuthRepository.signIn(
          email: '   ',
          password: testPassword,
        )).called(1);
      });

      test('should handle whitespace-only password (passes to repository)', () async {
        // Note: Current implementation checks for isEmpty, not isBlank
        when(mockAuthRepository.signIn(
          email: testEmail,
          password: '   ',
        )).thenThrow(Exception('Invalid password'));

        expect(
          () => useCase(email: testEmail, password: '   '),
          throwsA(isA<Exception>()),
        );
        verify(mockAuthRepository.signIn(
          email: testEmail,
          password: '   ',
        )).called(1);
      });

      test('should handle email with leading/trailing spaces', () async {
        // Arrange - the implementation does not trim emails
        const emailWithSpaces = ' test@example.com ';
        when(mockAuthRepository.signIn(
          email: emailWithSpaces,
          password: testPassword,
        )).thenAnswer((_) async => testUser);

        // Act
        final result = await useCase(
          email: emailWithSpaces,
          password: testPassword,
        );

        // Assert
        expect(result, testUser);
        verify(mockAuthRepository.signIn(
          email: emailWithSpaces,
          password: testPassword,
        )).called(1);
      });

      test('should handle password with leading/trailing spaces', () async {
        // Arrange
        const passwordWithSpaces = ' password123 ';
        when(mockAuthRepository.signIn(
          email: testEmail,
          password: passwordWithSpaces,
        )).thenAnswer((_) async => testUser);

        // Act
        final result = await useCase(
          email: testEmail,
          password: passwordWithSpaces,
        );

        // Assert
        expect(result, testUser);
      });

      test('should handle uppercase email', () async {
        // Arrange
        const uppercaseEmail = 'TEST@EXAMPLE.COM';
        when(mockAuthRepository.signIn(
          email: uppercaseEmail,
          password: testPassword,
        )).thenAnswer((_) async => testUser);

        // Act
        final result = await useCase(
          email: uppercaseEmail,
          password: testPassword,
        );

        // Assert
        expect(result, testUser);
      });

      test('should handle mixed case email', () async {
        // Arrange
        const mixedCaseEmail = 'TeSt@ExAmPlE.cOm';
        when(mockAuthRepository.signIn(
          email: mixedCaseEmail,
          password: testPassword,
        )).thenAnswer((_) async => testUser);

        // Act
        final result = await useCase(
          email: mixedCaseEmail,
          password: testPassword,
        );

        // Assert
        expect(result, testUser);
      });
    });
  });
}
