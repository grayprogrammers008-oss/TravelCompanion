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
  final testUser = UserEntity(
    id: '123',
    email: testEmail,
    fullName: 'Test User',
    createdAt: DateTime.now(),
  );

  group('SignInUseCase', () {
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

    test('should throw exception when email is empty', () async {
      // Arrange & Act & Assert
      expect(
        () => useCase(email: '', password: testPassword),
        throwsA(isA<Exception>()),
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
        throwsA(isA<Exception>()),
      );
      verifyNever(mockAuthRepository.signIn(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ));
    });

    test('should throw exception when credentials are invalid', () async {
      // Arrange
      when(mockAuthRepository.signIn(
        email: testEmail,
        password: testPassword,
      )).thenThrow(Exception('Invalid credentials'));

      // Act & Assert
      expect(
        () => useCase(email: testEmail, password: testPassword),
        throwsA(isA<Exception>()),
      );
      verify(mockAuthRepository.signIn(
        email: testEmail,
        password: testPassword,
      )).called(1);
    });
  });
}
