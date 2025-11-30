import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/expenses/domain/repositories/expense_repository.dart';
import 'package:travel_crew/features/expenses/domain/usecases/get_user_expenses_usecase.dart';
import 'package:travel_crew/shared/models/expense_model.dart';

import 'get_user_expenses_usecase_test.mocks.dart';

@GenerateMocks([ExpenseRepository])
void main() {
  late GetUserExpensesUseCase useCase;
  late MockExpenseRepository mockRepository;

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = GetUserExpensesUseCase(mockRepository);
  });

  final now = DateTime.now();

  final testExpense = ExpenseModel(
    id: 'expense-123',
    tripId: 'trip-123',
    title: 'Dinner',
    description: 'Group dinner',
    amount: 150.0,
    currency: 'USD',
    category: 'Food',
    paidBy: 'user-123',
    splitType: 'equal',
    transactionDate: now,
    createdAt: now,
  );

  final testSplit = ExpenseSplitModel(
    id: 'split-1',
    expenseId: 'expense-123',
    userId: 'user-456',
    amount: 75.0,
    isSettled: false,
    createdAt: now,
    userName: 'John Doe',
  );

  final testExpenseWithSplits = ExpenseWithSplits(
    expense: testExpense,
    splits: [testSplit],
  );

  group('GetUserExpensesUseCase', () {
    group('Positive Cases', () {
      test('should return list of expenses with splits from repository', () async {
        // Arrange
        when(mockRepository.getUserExpenses()).thenAnswer(
          (_) async => [testExpenseWithSplits],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result.length, 1);
        expect(result.first.expense, testExpense);
        expect(result.first.splits, [testSplit]);
        verify(mockRepository.getUserExpenses()).called(1);
      });

      test('should return empty list when user has no expenses', () async {
        // Arrange
        when(mockRepository.getUserExpenses()).thenAnswer(
          (_) async => [],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result, isEmpty);
        verify(mockRepository.getUserExpenses()).called(1);
      });

      test('should return multiple expenses', () async {
        // Arrange
        final expense2 = testExpense.copyWith(
          id: 'expense-456',
          title: 'Hotel',
          amount: 500.0,
          category: 'Accommodation',
        );
        final expenseWithSplits2 = ExpenseWithSplits(
          expense: expense2,
          splits: [],
        );

        when(mockRepository.getUserExpenses()).thenAnswer(
          (_) async => [testExpenseWithSplits, expenseWithSplits2],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result.length, 2);
        expect(result[0].expense.title, 'Dinner');
        expect(result[1].expense.title, 'Hotel');
      });

      test('should return expenses with multiple splits', () async {
        // Arrange
        final split2 = ExpenseSplitModel(
          id: 'split-2',
          expenseId: 'expense-123',
          userId: 'user-789',
          amount: 75.0,
          isSettled: true,
          settledAt: now,
          createdAt: now,
          userName: 'Jane Doe',
        );
        final expenseWithMultipleSplits = ExpenseWithSplits(
          expense: testExpense,
          splits: [testSplit, split2],
        );

        when(mockRepository.getUserExpenses()).thenAnswer(
          (_) async => [expenseWithMultipleSplits],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result.first.splits.length, 2);
        expect(result.first.splits[0].userName, 'John Doe');
        expect(result.first.splits[1].userName, 'Jane Doe');
      });

      test('should return standalone expenses (no tripId)', () async {
        // Arrange
        final standaloneExpense = ExpenseModel(
          id: 'expense-standalone',
          tripId: null, // standalone expense
          title: 'Personal Purchase',
          amount: 50.0,
          currency: 'USD',
          paidBy: 'user-123',
          splitType: 'equal',
          createdAt: now,
        );
        final standaloneWithSplits = ExpenseWithSplits(
          expense: standaloneExpense,
          splits: [],
        );

        when(mockRepository.getUserExpenses()).thenAnswer(
          (_) async => [standaloneWithSplits],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result.first.expense.tripId, isNull);
      });

      test('should return expenses with different currencies', () async {
        // Arrange
        final usdExpense = testExpense.copyWith(id: 'exp-1', currency: 'USD');
        final eurExpense = testExpense.copyWith(id: 'exp-2', currency: 'EUR');
        final inrExpense = testExpense.copyWith(id: 'exp-3', currency: 'INR');

        when(mockRepository.getUserExpenses()).thenAnswer(
          (_) async => [
            ExpenseWithSplits(expense: usdExpense, splits: []),
            ExpenseWithSplits(expense: eurExpense, splits: []),
            ExpenseWithSplits(expense: inrExpense, splits: []),
          ],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result.length, 3);
        expect(result[0].expense.currency, 'USD');
        expect(result[1].expense.currency, 'EUR');
        expect(result[2].expense.currency, 'INR');
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should throw exception when repository fails', () async {
        // Arrange
        when(mockRepository.getUserExpenses()).thenThrow(
          Exception('Database error'),
        );

        // Act & Assert
        expect(
          () => useCase(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Database error'),
          )),
        );
      });

      test('should propagate network errors', () async {
        // Arrange
        when(mockRepository.getUserExpenses()).thenThrow(
          Exception('Network unavailable'),
        );

        // Act & Assert
        try {
          await useCase();
          fail('Should have thrown exception');
        } catch (e) {
          expect(e.toString(), contains('Network unavailable'));
        }
      });

      test('should propagate authentication errors', () async {
        // Arrange
        when(mockRepository.getUserExpenses()).thenThrow(
          Exception('User not authenticated'),
        );

        // Act & Assert
        expect(
          () => useCase(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User not authenticated'),
          )),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle expenses with zero amount', () async {
        // Arrange
        final zeroAmountExpense = testExpense.copyWith(amount: 0.0);
        final zeroAmountWithSplits = ExpenseWithSplits(
          expense: zeroAmountExpense,
          splits: [],
        );

        when(mockRepository.getUserExpenses()).thenAnswer(
          (_) async => [zeroAmountWithSplits],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result.first.expense.amount, 0.0);
      });

      test('should handle expenses with large amounts', () async {
        // Arrange
        final largeAmountExpense = testExpense.copyWith(amount: 999999999.99);
        final largeAmountWithSplits = ExpenseWithSplits(
          expense: largeAmountExpense,
          splits: [],
        );

        when(mockRepository.getUserExpenses()).thenAnswer(
          (_) async => [largeAmountWithSplits],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result.first.expense.amount, 999999999.99);
      });

      test('should handle expenses with all split types', () async {
        // Arrange
        final equalSplitExpense = testExpense.copyWith(splitType: 'equal');
        final percentSplitExpense = testExpense.copyWith(
          id: 'exp-2',
          splitType: 'percentage',
        );
        final exactSplitExpense = testExpense.copyWith(
          id: 'exp-3',
          splitType: 'exact',
        );

        when(mockRepository.getUserExpenses()).thenAnswer(
          (_) async => [
            ExpenseWithSplits(expense: equalSplitExpense, splits: []),
            ExpenseWithSplits(expense: percentSplitExpense, splits: []),
            ExpenseWithSplits(expense: exactSplitExpense, splits: []),
          ],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result[0].expense.splitType, 'equal');
        expect(result[1].expense.splitType, 'percentage');
        expect(result[2].expense.splitType, 'exact');
      });

      test('should handle expenses with various categories', () async {
        // Arrange
        final foodExpense = testExpense.copyWith(id: 'exp-1', category: 'Food');
        final transportExpense = testExpense.copyWith(
          id: 'exp-2',
          category: 'Transport',
        );
        // Create new expense without category (copyWith can't set to null)
        final uncategorizedExpense = ExpenseModel(
          id: 'exp-3',
          title: 'Uncategorized',
          amount: 50.0,
          paidBy: 'user-123',
          category: null,
          createdAt: now,
        );

        when(mockRepository.getUserExpenses()).thenAnswer(
          (_) async => [
            ExpenseWithSplits(expense: foodExpense, splits: []),
            ExpenseWithSplits(expense: transportExpense, splits: []),
            ExpenseWithSplits(expense: uncategorizedExpense, splits: []),
          ],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result[0].expense.category, 'Food');
        expect(result[1].expense.category, 'Transport');
        expect(result[2].expense.category, isNull);
      });
    });
  });
}
