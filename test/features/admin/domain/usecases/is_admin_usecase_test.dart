import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/admin/domain/repositories/admin_repository.dart';
import 'package:travel_crew/features/admin/domain/usecases/is_admin_usecase.dart';

import 'is_admin_usecase_test.mocks.dart';

@GenerateMocks([AdminRepository])
void main() {
  late IsAdminUseCase useCase;
  late MockAdminRepository mockRepository;

  setUp(() {
    mockRepository = MockAdminRepository();
    useCase = IsAdminUseCase(mockRepository);
  });

  group('IsAdminUseCase', () {
    test('should return true when user is admin', () async {
      // Arrange
      when(mockRepository.isAdmin()).thenAnswer((_) async => true);

      // Act
      final result = await useCase();

      // Assert
      expect(result, true);
      verify(mockRepository.isAdmin()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return false when user is not admin', () async {
      // Arrange
      when(mockRepository.isAdmin()).thenAnswer((_) async => false);

      // Act
      final result = await useCase();

      // Assert
      expect(result, false);
      verify(mockRepository.isAdmin()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should throw exception when repository fails', () async {
      // Arrange
      when(mockRepository.isAdmin()).thenThrow(Exception('Database error'));

      // Act & Assert
      expect(() => useCase(), throwsException);
      verify(mockRepository.isAdmin()).called(1);
    });
  });
}
