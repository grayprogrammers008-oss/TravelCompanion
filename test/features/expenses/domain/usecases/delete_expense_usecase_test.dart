import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/expenses/domain/repositories/expense_repository.dart';
import 'package:travel_crew/features/expenses/domain/usecases/delete_expense_usecase.dart';

@GenerateMocks([ExpenseRepository])
import 'delete_expense_usecase_test.mocks.dart';

void main() {
  late DeleteExpenseUseCase useCase;
  late MockExpenseRepository mockRepository;

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = DeleteExpenseUseCase(mockRepository);
  });

  group('DeleteExpenseUseCase', () {
    group('positive cases', () {
      test('should delete expense with valid ID', () async {
        // Arrange
        when(mockRepository.deleteExpense(any))
            .thenAnswer((_) async => {});

        // Act
        await useCase('expense-123');

        // Assert
        verify(mockRepository.deleteExpense('expense-123')).called(1);
      });

      test('should delete expense with UUID format ID', () async {
        // Arrange
        const expenseId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        when(mockRepository.deleteExpense(any))
            .thenAnswer((_) async => {});

        // Act
        await useCase(expenseId);

        // Assert
        verify(mockRepository.deleteExpense(expenseId)).called(1);
      });

      test('should complete successfully for existing expense', () async {
        // Arrange
        when(mockRepository.deleteExpense(any))
            .thenAnswer((_) async => {});

        // Act & Assert
        expect(() => useCase('expense-456'), returnsNormally);
      });
    });

    group('negative cases', () {
      test('should throw exception for empty expense ID', () async {
        // Act & Assert
        expect(
          () => useCase(''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Expense ID cannot be empty'),
          )),
        );
        verifyNever(mockRepository.deleteExpense(any));
      });

      test('should propagate repository exception for non-existent expense', () async {
        // Arrange
        when(mockRepository.deleteExpense(any))
            .thenThrow(Exception('Expense not found'));

        // Act & Assert
        expect(
          () => useCase('non-existent-id'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Expense not found'),
          )),
        );
      });

      test('should propagate repository exception for database error', () async {
        // Arrange
        when(mockRepository.deleteExpense(any))
            .thenThrow(Exception('Database connection failed'));

        // Act & Assert
        expect(
          () => useCase('expense-789'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Database connection failed'),
          )),
        );
      });

      test('should propagate repository exception for permission denied', () async {
        // Arrange
        when(mockRepository.deleteExpense(any))
            .thenThrow(Exception('Permission denied: Not the expense creator'));

        // Act & Assert
        expect(
          () => useCase('expense-owned-by-other'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Permission denied'),
          )),
        );
      });
    });
  });
}
