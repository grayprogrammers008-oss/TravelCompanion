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
  final testUser = UserEntity(
    id: '123',
    email: testEmail,
    fullName: testFullName,
    createdAt: DateTime.now(),
  );

  group('SignUpUseCase', () {
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

    test('should throw exception when email is empty', () async {
      // Arrange & Act & Assert
      expect(
        () => useCase(
          email: '',
          password: testPassword,
          fullName: testFullName,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception when password is too short', () async {
      // Arrange & Act & Assert
      expect(
        () => useCase(
          email: testEmail,
          password: '123',
          fullName: testFullName,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception when full name is empty', () async {
      // Arrange & Act & Assert
      expect(
        () => useCase(
          email: testEmail,
          password: testPassword,
          fullName: '',
        ),
        throwsA(isA<Exception>()),
      );
    });

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
        throwsA(isA<Exception>()),
      );
    });
  });
}
