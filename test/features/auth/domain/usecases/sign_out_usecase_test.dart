import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/auth/domain/repositories/auth_repository.dart';
import 'package:travel_crew/features/auth/domain/usecases/sign_out_usecase.dart';

import 'sign_out_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late SignOutUseCase useCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = SignOutUseCase(mockAuthRepository);
  });

  group('SignOutUseCase', () {
    group('Positive Cases', () {
      test('should sign out user successfully', () async {
        // Arrange
        when(mockAuthRepository.signOut()).thenAnswer((_) async => {});

        // Act
        await useCase();

        // Assert
        verify(mockAuthRepository.signOut()).called(1);
        verifyNoMoreInteractions(mockAuthRepository);
      });

      test('should complete without returning a value', () async {
        // Arrange
        when(mockAuthRepository.signOut()).thenAnswer((_) async => {});

        // Act
        final result = useCase();

        // Assert
        expect(result, isA<Future<void>>());
        await result; // Ensure it completes
      });

      test('should call repository signOut only once', () async {
        // Arrange
        when(mockAuthRepository.signOut()).thenAnswer((_) async => {});

        // Act
        await useCase();
        await useCase();
        await useCase();

        // Assert
        verify(mockAuthRepository.signOut()).called(3);
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should propagate exception for network error', () async {
        // Arrange
        when(mockAuthRepository.signOut())
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => useCase(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network error'),
          )),
        );
        verify(mockAuthRepository.signOut()).called(1);
      });

      test('should propagate exception for server error', () async {
        // Arrange
        when(mockAuthRepository.signOut())
            .thenThrow(Exception('Internal server error'));

        // Act & Assert
        expect(
          () => useCase(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Internal server error'),
          )),
        );
      });

      test('should propagate exception for session expired', () async {
        // Arrange
        when(mockAuthRepository.signOut())
            .thenThrow(Exception('Session expired'));

        // Act & Assert
        expect(
          () => useCase(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Session expired'),
          )),
        );
      });

      test('should propagate exception for unauthorized', () async {
        // Arrange
        when(mockAuthRepository.signOut())
            .thenThrow(Exception('Unauthorized'));

        // Act & Assert
        expect(
          () => useCase(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Unauthorized'),
          )),
        );
      });

      test('should propagate exception for timeout', () async {
        // Arrange
        when(mockAuthRepository.signOut())
            .thenThrow(Exception('Request timed out'));

        // Act & Assert
        expect(
          () => useCase(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Request timed out'),
          )),
        );
      });

      test('should propagate exception for local storage error', () async {
        // Arrange
        when(mockAuthRepository.signOut())
            .thenThrow(Exception('Failed to clear local storage'));

        // Act & Assert
        expect(
          () => useCase(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to clear local storage'),
          )),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle multiple concurrent sign out calls', () async {
        // Arrange
        when(mockAuthRepository.signOut()).thenAnswer((_) async => {});

        // Act - Call sign out multiple times concurrently
        await Future.wait([
          useCase(),
          useCase(),
          useCase(),
        ]);

        // Assert
        verify(mockAuthRepository.signOut()).called(3);
      });

      test('should handle sign out when already signed out', () async {
        // Arrange - Some implementations may throw when already signed out
        when(mockAuthRepository.signOut()).thenAnswer((_) async => {});

        // Act
        await useCase();
        await useCase();

        // Assert - Both should complete successfully
        verify(mockAuthRepository.signOut()).called(2);
      });

      test('should handle delayed sign out', () async {
        // Arrange
        when(mockAuthRepository.signOut()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return;
        });

        // Act
        final stopwatch = Stopwatch()..start();
        await useCase();
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
        verify(mockAuthRepository.signOut()).called(1);
      });
    });
  });
}
