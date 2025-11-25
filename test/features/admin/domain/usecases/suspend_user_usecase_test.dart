import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/admin/domain/repositories/admin_repository.dart';
import 'package:travel_crew/features/admin/domain/usecases/suspend_user_usecase.dart';

import 'suspend_user_usecase_test.mocks.dart';

@GenerateMocks([AdminRepository])
void main() {
  late SuspendUserUseCase useCase;
  late MockAdminRepository mockRepository;

  setUp(() {
    mockRepository = MockAdminRepository();
    useCase = SuspendUserUseCase(mockRepository);
  });

  group('SuspendUserUseCase', () {
    const tUserId = 'user-123';
    const tReason = 'Violation of terms';

    test('should suspend user successfully when valid parameters provided',
        () async {
      // Arrange
      when(mockRepository.suspendUser(any, any))
          .thenAnswer((_) async => true);

      // Act
      final result = await useCase(tUserId, tReason);

      // Assert
      expect(result, true);
      verify(mockRepository.suspendUser(tUserId, tReason)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should throw exception when userId is empty', () async {
      // Act & Assert
      expect(
        () => useCase('', tReason),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('User ID cannot be empty'),
        )),
      );
      verifyNever(mockRepository.suspendUser(any, any));
    });

    test('should throw exception when reason is empty', () async {
      // Act & Assert
      expect(
        () => useCase(tUserId, ''),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Reason for suspension cannot be empty'),
        )),
      );
      verifyNever(mockRepository.suspendUser(any, any));
    });

    test('should propagate exception when repository fails', () async {
      // Arrange
      when(mockRepository.suspendUser(any, any))
          .thenThrow(Exception('Database error'));

      // Act & Assert
      expect(() => useCase(tUserId, tReason), throwsException);
      verify(mockRepository.suspendUser(tUserId, tReason)).called(1);
    });
  });
}
