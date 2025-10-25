import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/auth/domain/entities/user_entity.dart';
import 'package:travel_crew/features/auth/domain/repositories/auth_repository.dart';
import 'package:travel_crew/features/auth/domain/usecases/update_profile_usecase.dart';

import 'update_profile_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late UpdateProfileUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = UpdateProfileUseCase(mockRepository);
  });

  group('UpdateProfileUseCase', () {
    const tUserId = 'user123';
    const tEmail = 'test@example.com';
    const tFullName = 'John Doe';
    const tPhoneNumber = '+1234567890';
    const tAvatarUrl = 'https://example.com/avatar.jpg';

    final tUserEntity = UserEntity(
      id: tUserId,
      email: tEmail,
      fullName: tFullName,
      phoneNumber: tPhoneNumber,
      avatarUrl: tAvatarUrl,
      createdAt: DateTime.now(),
    );

    test('should update profile successfully with all parameters', () async {
      // arrange
      when(mockRepository.updateProfile(
        fullName: anyNamed('fullName'),
        phoneNumber: anyNamed('phoneNumber'),
        avatarUrl: anyNamed('avatarUrl'),
      )).thenAnswer((_) async => tUserEntity);

      // act
      final result = await useCase(
        fullName: tFullName,
        phoneNumber: tPhoneNumber,
        avatarUrl: tAvatarUrl,
      );

      // assert
      expect(result, equals(tUserEntity));
      verify(mockRepository.updateProfile(
        fullName: tFullName,
        phoneNumber: tPhoneNumber,
        avatarUrl: tAvatarUrl,
      ));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should update profile with only full name', () async {
      // arrange
      when(mockRepository.updateProfile(
        fullName: anyNamed('fullName'),
        phoneNumber: anyNamed('phoneNumber'),
        avatarUrl: anyNamed('avatarUrl'),
      )).thenAnswer((_) async => tUserEntity);

      // act
      final result = await useCase(fullName: tFullName);

      // assert
      expect(result, equals(tUserEntity));
      verify(mockRepository.updateProfile(
        fullName: tFullName,
        phoneNumber: null,
        avatarUrl: null,
      ));
    });

    test('should throw exception when full name is empty', () async {
      // act & assert
      expect(
        () => useCase(fullName: '   '),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Full name cannot be empty'),
        )),
      );
      verifyNever(mockRepository.updateProfile(
        fullName: anyNamed('fullName'),
        phoneNumber: anyNamed('phoneNumber'),
        avatarUrl: anyNamed('avatarUrl'),
      ));
    });

    test('should throw exception when phone number format is invalid', () async {
      // act & assert
      expect(
        () => useCase(phoneNumber: '123'), // Too short
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid phone number format'),
        )),
      );

      expect(
        () => useCase(phoneNumber: 'abc1234567890'), // Contains letters
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid phone number format'),
        )),
      );

      verifyNever(mockRepository.updateProfile(
        fullName: anyNamed('fullName'),
        phoneNumber: anyNamed('phoneNumber'),
        avatarUrl: anyNamed('avatarUrl'),
      ));
    });

    test('should accept valid phone number formats', () async {
      // arrange
      when(mockRepository.updateProfile(
        fullName: anyNamed('fullName'),
        phoneNumber: anyNamed('phoneNumber'),
        avatarUrl: anyNamed('avatarUrl'),
      )).thenAnswer((_) async => tUserEntity);

      // Test various valid formats
      final validPhoneNumbers = [
        '+1234567890',
        '1234567890',
        '+12345678901234',
        '1234 5678 90', // With spaces
        '123-456-7890', // With dashes
      ];

      for (final phone in validPhoneNumbers) {
        // act
        await useCase(phoneNumber: phone);

        // assert
        verify(mockRepository.updateProfile(
          fullName: null,
          phoneNumber: phone,
          avatarUrl: null,
        ));
      }
    });

    test('should update avatar URL', () async {
      // arrange
      when(mockRepository.updateProfile(
        fullName: anyNamed('fullName'),
        phoneNumber: anyNamed('phoneNumber'),
        avatarUrl: anyNamed('avatarUrl'),
      )).thenAnswer((_) async => tUserEntity);

      // act
      final result = await useCase(avatarUrl: tAvatarUrl);

      // assert
      expect(result, equals(tUserEntity));
      verify(mockRepository.updateProfile(
        fullName: null,
        phoneNumber: null,
        avatarUrl: tAvatarUrl,
      ));
    });

    test('should propagate repository exceptions', () async {
      // arrange
      when(mockRepository.updateProfile(
        fullName: anyNamed('fullName'),
        phoneNumber: anyNamed('phoneNumber'),
        avatarUrl: anyNamed('avatarUrl'),
      )).thenThrow(Exception('Repository error'));

      // act & assert
      expect(
        () => useCase(fullName: tFullName),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Repository error'),
        )),
      );
    });
  });
}
