import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'package:travel_crew/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:travel_crew/features/auth/data/models/user_model.dart';
import 'package:travel_crew/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:travel_crew/features/auth/domain/entities/user_entity.dart';

import 'auth_repository_impl_test.mocks.dart';

@GenerateMocks([AuthRemoteDataSource, User])
void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(mockRemoteDataSource);
  });

  final now = DateTime.now();
  final testUserModel = UserModel(
    id: 'user-123',
    email: 'test@example.com',
    fullName: 'John Doe',
    avatarUrl: 'https://example.com/avatar.jpg',
    phoneNumber: '+1234567890',
    bio: 'Travel enthusiast',
    createdAt: now,
    updatedAt: now,
  );

  group('AuthRepositoryImpl', () {
    group('signUp', () {
      group('Positive Cases', () {
        test('should sign up user successfully and return UserEntity', () async {
          // Arrange
          when(mockRemoteDataSource.signUp(
            email: 'test@example.com',
            password: 'password123',
            fullName: 'John Doe',
            phoneNumber: null,
          )).thenAnswer((_) async => testUserModel);

          // Act
          final result = await repository.signUp(
            email: 'test@example.com',
            password: 'password123',
            fullName: 'John Doe',
          );

          // Assert
          expect(result, isA<UserEntity>());
          expect(result.id, 'user-123');
          expect(result.email, 'test@example.com');
          expect(result.fullName, 'John Doe');
          verify(mockRemoteDataSource.signUp(
            email: 'test@example.com',
            password: 'password123',
            fullName: 'John Doe',
            phoneNumber: null,
          )).called(1);
        });

        test('should sign up user with phone number', () async {
          // Arrange
          when(mockRemoteDataSource.signUp(
            email: 'test@example.com',
            password: 'password123',
            fullName: 'John Doe',
            phoneNumber: '+1234567890',
          )).thenAnswer((_) async => testUserModel);

          // Act
          final result = await repository.signUp(
            email: 'test@example.com',
            password: 'password123',
            fullName: 'John Doe',
            phoneNumber: '+1234567890',
          );

          // Assert
          expect(result.phoneNumber, '+1234567890');
        });
      });

      group('Negative Cases', () {
        test('should throw exception when remote data source fails', () async {
          // Arrange
          when(mockRemoteDataSource.signUp(
            email: anyNamed('email'),
            password: anyNamed('password'),
            fullName: anyNamed('fullName'),
            phoneNumber: anyNamed('phoneNumber'),
          )).thenThrow(Exception('Network error'));

          // Act & Assert
          expect(
            () => repository.signUp(
              email: 'test@example.com',
              password: 'password123',
              fullName: 'John Doe',
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to sign up'),
            )),
          );
        });

        test('should throw exception when email already in use', () async {
          // Arrange
          when(mockRemoteDataSource.signUp(
            email: anyNamed('email'),
            password: anyNamed('password'),
            fullName: anyNamed('fullName'),
            phoneNumber: anyNamed('phoneNumber'),
          )).thenThrow(Exception('Email already in use'));

          // Act & Assert
          expect(
            () => repository.signUp(
              email: 'existing@example.com',
              password: 'password123',
              fullName: 'John Doe',
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to sign up'),
            )),
          );
        });
      });
    });

    group('signIn', () {
      group('Positive Cases', () {
        test('should sign in user successfully and return UserEntity', () async {
          // Arrange
          when(mockRemoteDataSource.signIn(
            email: 'test@example.com',
            password: 'password123',
          )).thenAnswer((_) async => testUserModel);

          // Act
          final result = await repository.signIn(
            email: 'test@example.com',
            password: 'password123',
          );

          // Assert
          expect(result, isA<UserEntity>());
          expect(result.id, 'user-123');
          expect(result.email, 'test@example.com');
          verify(mockRemoteDataSource.signIn(
            email: 'test@example.com',
            password: 'password123',
          )).called(1);
        });

        test('should return user with all fields populated', () async {
          // Arrange
          when(mockRemoteDataSource.signIn(
            email: 'test@example.com',
            password: 'password123',
          )).thenAnswer((_) async => testUserModel);

          // Act
          final result = await repository.signIn(
            email: 'test@example.com',
            password: 'password123',
          );

          // Assert
          expect(result.fullName, 'John Doe');
          expect(result.avatarUrl, 'https://example.com/avatar.jpg');
          expect(result.phoneNumber, '+1234567890');
          expect(result.bio, 'Travel enthusiast');
        });
      });

      group('Negative Cases', () {
        test('should throw exception for invalid credentials', () async {
          // Arrange
          when(mockRemoteDataSource.signIn(
            email: anyNamed('email'),
            password: anyNamed('password'),
          )).thenThrow(Exception('Invalid credentials'));

          // Act & Assert
          expect(
            () => repository.signIn(
              email: 'test@example.com',
              password: 'wrongpassword',
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to sign in'),
            )),
          );
        });

        test('should throw exception for network error', () async {
          // Arrange
          when(mockRemoteDataSource.signIn(
            email: anyNamed('email'),
            password: anyNamed('password'),
          )).thenThrow(Exception('Network error'));

          // Act & Assert
          expect(
            () => repository.signIn(
              email: 'test@example.com',
              password: 'password123',
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to sign in'),
            )),
          );
        });
      });
    });

    group('signOut', () {
      group('Positive Cases', () {
        test('should sign out user successfully', () async {
          // Arrange
          when(mockRemoteDataSource.signOut()).thenAnswer((_) async => {});

          // Act
          await repository.signOut();

          // Assert
          verify(mockRemoteDataSource.signOut()).called(1);
        });
      });

      group('Negative Cases', () {
        test('should throw exception when sign out fails', () async {
          // Arrange
          when(mockRemoteDataSource.signOut())
              .thenThrow(Exception('Sign out failed'));

          // Act & Assert
          expect(
            () => repository.signOut(),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to sign out'),
            )),
          );
        });
      });
    });

    group('getCurrentUser', () {
      group('Positive Cases', () {
        test('should return current user when logged in', () async {
          // Arrange
          when(mockRemoteDataSource.getCurrentUser())
              .thenAnswer((_) async => testUserModel);

          // Act
          final result = await repository.getCurrentUser();

          // Assert
          expect(result, isA<UserEntity>());
          expect(result?.id, 'user-123');
          expect(result?.email, 'test@example.com');
        });

        test('should return null when no user is logged in', () async {
          // Arrange
          when(mockRemoteDataSource.getCurrentUser())
              .thenAnswer((_) async => null);

          // Act
          final result = await repository.getCurrentUser();

          // Assert
          expect(result, isNull);
        });
      });

      group('Negative Cases', () {
        test('should return null when exception occurs', () async {
          // Arrange
          when(mockRemoteDataSource.getCurrentUser())
              .thenThrow(Exception('Network error'));

          // Act
          final result = await repository.getCurrentUser();

          // Assert
          expect(result, isNull);
        });
      });
    });

    group('authStateChanges', () {
      test('should emit user ID when auth state changes', () async {
        // Arrange
        final mockUser = MockUser();
        when(mockUser.id).thenReturn('user-123');

        final controller = StreamController<User?>();
        when(mockRemoteDataSource.authStateChanges)
            .thenAnswer((_) => controller.stream);

        // Act
        final stream = repository.authStateChanges;

        // Assert
        controller.add(mockUser);
        expect(await stream.first, 'user-123');

        await controller.close();
      });

      test('should emit null when user signs out', () async {
        // Arrange
        final controller = StreamController<User?>();
        when(mockRemoteDataSource.authStateChanges)
            .thenAnswer((_) => controller.stream);

        // Act
        final stream = repository.authStateChanges;

        // Assert
        controller.add(null);
        expect(await stream.first, isNull);

        await controller.close();
      });
    });

    group('updateProfile', () {
      group('Positive Cases', () {
        test('should update profile successfully', () async {
          // Arrange
          when(mockRemoteDataSource.getCurrentUser())
              .thenAnswer((_) async => testUserModel);

          final updatedModel = UserModel(
            id: 'user-123',
            email: 'test@example.com',
            fullName: 'Jane Doe',
            avatarUrl: 'https://example.com/new-avatar.jpg',
            phoneNumber: '+9876543210',
            bio: 'Updated bio',
            createdAt: now,
            updatedAt: now,
          );

          when(mockRemoteDataSource.updateProfile(
            userId: 'user-123',
            fullName: 'Jane Doe',
            phoneNumber: '+9876543210',
            avatarUrl: 'https://example.com/new-avatar.jpg',
            bio: 'Updated bio',
          )).thenAnswer((_) async => updatedModel);

          // Act
          final result = await repository.updateProfile(
            fullName: 'Jane Doe',
            phoneNumber: '+9876543210',
            avatarUrl: 'https://example.com/new-avatar.jpg',
            bio: 'Updated bio',
          );

          // Assert
          expect(result.fullName, 'Jane Doe');
          expect(result.avatarUrl, 'https://example.com/new-avatar.jpg');
        });

        test('should update only specified fields', () async {
          // Arrange
          when(mockRemoteDataSource.getCurrentUser())
              .thenAnswer((_) async => testUserModel);

          when(mockRemoteDataSource.updateProfile(
            userId: 'user-123',
            fullName: 'New Name',
            phoneNumber: null,
            avatarUrl: null,
            bio: null,
          )).thenAnswer((_) async => testUserModel.copyWith(fullName: 'New Name'));

          // Act
          final result = await repository.updateProfile(fullName: 'New Name');

          // Assert
          expect(result.fullName, 'New Name');
        });
      });

      group('Negative Cases', () {
        test('should throw exception when no user is logged in', () async {
          // Arrange
          when(mockRemoteDataSource.getCurrentUser())
              .thenAnswer((_) async => null);

          // Act & Assert
          expect(
            () => repository.updateProfile(fullName: 'New Name'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('No user logged in'),
            )),
          );
        });

        test('should throw exception when update fails', () async {
          // Arrange
          when(mockRemoteDataSource.getCurrentUser())
              .thenAnswer((_) async => testUserModel);
          when(mockRemoteDataSource.updateProfile(
            userId: anyNamed('userId'),
            fullName: anyNamed('fullName'),
            phoneNumber: anyNamed('phoneNumber'),
            avatarUrl: anyNamed('avatarUrl'),
            bio: anyNamed('bio'),
          )).thenThrow(Exception('Update failed'));

          // Act & Assert
          expect(
            () => repository.updateProfile(fullName: 'New Name'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to update profile'),
            )),
          );
        });
      });
    });

    group('resetPassword', () {
      group('Positive Cases', () {
        test('should send reset password email successfully', () async {
          // Arrange
          when(mockRemoteDataSource.resetPassword('test@example.com'))
              .thenAnswer((_) async => {});

          // Act
          await repository.resetPassword('test@example.com');

          // Assert
          verify(mockRemoteDataSource.resetPassword('test@example.com'))
              .called(1);
        });
      });

      group('Negative Cases', () {
        test('should throw exception when reset password fails', () async {
          // Arrange
          when(mockRemoteDataSource.resetPassword(any))
              .thenThrow(Exception('Email not found'));

          // Act & Assert
          expect(
            () => repository.resetPassword('nonexistent@example.com'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to reset password'),
            )),
          );
        });
      });
    });

    group('changePassword', () {
      group('Positive Cases', () {
        test('should change password successfully', () async {
          // Arrange
          when(mockRemoteDataSource.changePassword(
            currentPassword: 'oldPassword123',
            newPassword: 'newPassword456',
          )).thenAnswer((_) async => {});

          // Act
          await repository.changePassword(
            currentPassword: 'oldPassword123',
            newPassword: 'newPassword456',
          );

          // Assert
          verify(mockRemoteDataSource.changePassword(
            currentPassword: 'oldPassword123',
            newPassword: 'newPassword456',
          )).called(1);
        });
      });

      group('Negative Cases', () {
        test('should rethrow exception when change password fails', () async {
          // Arrange
          when(mockRemoteDataSource.changePassword(
            currentPassword: anyNamed('currentPassword'),
            newPassword: anyNamed('newPassword'),
          )).thenThrow(Exception('Current password is incorrect'));

          // Act & Assert
          expect(
            () => repository.changePassword(
              currentPassword: 'wrongPassword',
              newPassword: 'newPassword456',
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Current password is incorrect'),
            )),
          );
        });
      });
    });

    group('updatePassword', () {
      group('Positive Cases', () {
        test('should update password successfully via reset link', () async {
          // Arrange
          when(mockRemoteDataSource.updatePassword(newPassword: 'newPassword123'))
              .thenAnswer((_) async => {});

          // Act
          await repository.updatePassword(newPassword: 'newPassword123');

          // Assert
          verify(mockRemoteDataSource.updatePassword(newPassword: 'newPassword123'))
              .called(1);
        });
      });

      group('Negative Cases', () {
        test('should rethrow exception when update password fails', () async {
          // Arrange
          when(mockRemoteDataSource.updatePassword(newPassword: anyNamed('newPassword')))
              .thenThrow(Exception('Session expired'));

          // Act & Assert
          expect(
            () => repository.updatePassword(newPassword: 'newPassword123'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Session expired'),
            )),
          );
        });
      });
    });

    group('verifyOtpAndUpdatePassword', () {
      group('Positive Cases', () {
        test('should verify OTP and update password successfully', () async {
          // Arrange
          when(mockRemoteDataSource.verifyOtpAndUpdatePassword(
            token: 'valid-otp-token',
            newPassword: 'newPassword123',
          )).thenAnswer((_) async => {});

          // Act
          await repository.verifyOtpAndUpdatePassword(
            token: 'valid-otp-token',
            newPassword: 'newPassword123',
          );

          // Assert
          verify(mockRemoteDataSource.verifyOtpAndUpdatePassword(
            token: 'valid-otp-token',
            newPassword: 'newPassword123',
          )).called(1);
        });
      });

      group('Negative Cases', () {
        test('should rethrow exception for invalid token', () async {
          // Arrange
          when(mockRemoteDataSource.verifyOtpAndUpdatePassword(
            token: anyNamed('token'),
            newPassword: anyNamed('newPassword'),
          )).thenThrow(Exception('Invalid or expired token'));

          // Act & Assert
          expect(
            () => repository.verifyOtpAndUpdatePassword(
              token: 'invalid-token',
              newPassword: 'newPassword123',
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Invalid or expired token'),
            )),
          );
        });
      });
    });

    group('isAuthenticated', () {
      test('should return true when user is authenticated', () {
        // Arrange
        when(mockRemoteDataSource.isAuthenticated).thenReturn(true);

        // Act
        final result = repository.isAuthenticated;

        // Assert
        expect(result, true);
      });

      test('should return false when user is not authenticated', () {
        // Arrange
        when(mockRemoteDataSource.isAuthenticated).thenReturn(false);

        // Act
        final result = repository.isAuthenticated;

        // Assert
        expect(result, false);
      });
    });
  });
}
