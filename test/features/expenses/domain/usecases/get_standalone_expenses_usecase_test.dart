import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/expenses/domain/repositories/expense_repository.dart';
import 'package:travel_crew/features/expenses/domain/usecases/get_standalone_expenses_usecase.dart';
import 'package:travel_crew/shared/models/expense_model.dart';

import 'get_standalone_expenses_usecase_test.mocks.dart';

@GenerateMocks([ExpenseRepository])
void main() {
  late GetStandaloneExpensesUseCase useCase;
  late MockExpenseRepository mockRepository;

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = GetStandaloneExpensesUseCase(mockRepository);
  });

  final now = DateTime.now();

  // Standalone expense has null tripId
  final standaloneExpense = ExpenseModel(
    id: 'expense-standalone',
    tripId: null, // Key characteristic of standalone expense
    title: 'Personal Purchase',
    description: 'Bought something for the group',
    amount: 75.0,
    currency: 'USD',
    category: 'Shopping',
    paidBy: 'user-123',
    splitType: 'equal',
    transactionDate: now,
    createdAt: now,
  );

  final testSplit = ExpenseSplitModel(
    id: 'split-1',
    expenseId: 'expense-standalone',
    userId: 'user-456',
    amount: 37.50,
    isSettled: false,
    createdAt: now,
    userName: 'John Doe',
  );

  final standaloneExpenseWithSplits = ExpenseWithSplits(
    expense: standaloneExpense,
    splits: [testSplit],
  );

  group('GetStandaloneExpensesUseCase', () {
    group('Positive Cases', () {
      test('should return list of standalone expenses with splits', () async {
        // Arrange
        when(mockRepository.getStandaloneExpenses()).thenAnswer(
          (_) async => [standaloneExpenseWithSplits],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result.length, 1);
        expect(result.first.expense, standaloneExpense);
        expect(result.first.expense.tripId, isNull);
        expect(result.first.splits, [testSplit]);
        verify(mockRepository.getStandaloneExpenses()).called(1);
      });

      test('should return empty list when user has no standalone expenses', () async {
        // Arrange
        when(mockRepository.getStandaloneExpenses()).thenAnswer(
          (_) async => [],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result, isEmpty);
        verify(mockRepository.getStandaloneExpenses()).called(1);
      });

      test('should return multiple standalone expenses', () async {
        // Arrange
        final expense2 = standaloneExpense.copyWith(
          id: 'expense-standalone-2',
          title: 'Group Gift',
          amount: 200.0,
          category: 'Gifts',
        );
        final expenseWithSplits2 = ExpenseWithSplits(
          expense: expense2,
          splits: [],
        );

        when(mockRepository.getStandaloneExpenses()).thenAnswer(
          (_) async => [standaloneExpenseWithSplits, expenseWithSplits2],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result.length, 2);
        expect(result[0].expense.title, 'Personal Purchase');
        expect(result[1].expense.title, 'Group Gift');
        // All should be standalone (no tripId)
        expect(result[0].expense.tripId, isNull);
        expect(result[1].expense.tripId, isNull);
      });

      test('should return standalone expenses with multiple splits', () async {
        // Arrange
        final split2 = ExpenseSplitModel(
          id: 'split-2',
          expenseId: 'expense-standalone',
          userId: 'user-789',
          amount: 37.50,
          isSettled: true,
          settledAt: now,
          createdAt: now,
          userName: 'Jane Doe',
        );
        final expenseWithMultipleSplits = ExpenseWithSplits(
          expense: standaloneExpense,
          splits: [testSplit, split2],
        );

        when(mockRepository.getStandaloneExpenses()).thenAnswer(
          (_) async => [expenseWithMultipleSplits],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result.first.splits.length, 2);
        expect(result.first.splits[0].isSettled, false);
        expect(result.first.splits[1].isSettled, true);
      });

      test('should return standalone expenses with different currencies', () async {
        // Arrange
        final usdExpense = standaloneExpense.copyWith(
          id: 'exp-1',
          currency: 'USD',
        );
        final eurExpense = standaloneExpense.copyWith(
          id: 'exp-2',
          currency: 'EUR',
        );
        final inrExpense = standaloneExpense.copyWith(
          id: 'exp-3',
          currency: 'INR',
        );

        when(mockRepository.getStandaloneExpenses()).thenAnswer(
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

      test('should return standalone expenses with various split types', () async {
        // Arrange
        final equalSplit = standaloneExpense.copyWith(
          id: 'exp-1',
          splitType: 'equal',
        );
        final percentSplit = standaloneExpense.copyWith(
          id: 'exp-2',
          splitType: 'percentage',
        );
        final exactSplit = standaloneExpense.copyWith(
          id: 'exp-3',
          splitType: 'exact',
        );

        when(mockRepository.getStandaloneExpenses()).thenAnswer(
          (_) async => [
            ExpenseWithSplits(expense: equalSplit, splits: []),
            ExpenseWithSplits(expense: percentSplit, splits: []),
            ExpenseWithSplits(expense: exactSplit, splits: []),
          ],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result[0].expense.splitType, 'equal');
        expect(result[1].expense.splitType, 'percentage');
        expect(result[2].expense.splitType, 'exact');
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should throw exception when repository fails', () async {
        // Arrange
        when(mockRepository.getStandaloneExpenses()).thenThrow(
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
        when(mockRepository.getStandaloneExpenses()).thenThrow(
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
        when(mockRepository.getStandaloneExpenses()).thenThrow(
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
      test('should handle standalone expenses with zero amount', () async {
        // Arrange
        final zeroAmountExpense = standaloneExpense.copyWith(amount: 0.0);
        final zeroAmountWithSplits = ExpenseWithSplits(
          expense: zeroAmountExpense,
          splits: [],
        );

        when(mockRepository.getStandaloneExpenses()).thenAnswer(
          (_) async => [zeroAmountWithSplits],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result.first.expense.amount, 0.0);
      });

      test('should handle standalone expenses with large amounts', () async {
        // Arrange
        final largeAmountExpense = standaloneExpense.copyWith(
          amount: 999999999.99,
        );
        final largeAmountWithSplits = ExpenseWithSplits(
          expense: largeAmountExpense,
          splits: [],
        );

        when(mockRepository.getStandaloneExpenses()).thenAnswer(
          (_) async => [largeAmountWithSplits],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result.first.expense.amount, 999999999.99);
      });

      test('should handle standalone expenses without category', () async {
        // Arrange - Create new expense without category (copyWith can't set to null)
        final uncategorizedExpense = ExpenseModel(
          id: 'expense-no-cat',
          title: 'No Category',
          amount: 50.0,
          paidBy: 'user-123',
          category: null,
          createdAt: now,
        );
        final uncategorizedWithSplits = ExpenseWithSplits(
          expense: uncategorizedExpense,
          splits: [],
        );

        when(mockRepository.getStandaloneExpenses()).thenAnswer(
          (_) async => [uncategorizedWithSplits],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result.first.expense.category, isNull);
      });

      test('should handle standalone expenses without description', () async {
        // Arrange - Create new expense without description (copyWith can't set to null)
        final noDescExpense = ExpenseModel(
          id: 'expense-no-desc',
          title: 'No Description',
          amount: 50.0,
          paidBy: 'user-123',
          description: null,
          createdAt: now,
        );
        final noDescWithSplits = ExpenseWithSplits(
          expense: noDescExpense,
          splits: [],
        );

        when(mockRepository.getStandaloneExpenses()).thenAnswer(
          (_) async => [noDescWithSplits],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result.first.expense.description, isNull);
      });

      test('should handle settled splits correctly', () async {
        // Arrange
        final settledSplit = ExpenseSplitModel(
          id: 'split-settled',
          expenseId: 'expense-standalone',
          userId: 'user-456',
          amount: 75.0,
          isSettled: true,
          settledAt: now,
          createdAt: now,
          userName: 'Settled User',
        );
        final expenseWithSettledSplit = ExpenseWithSplits(
          expense: standaloneExpense,
          splits: [settledSplit],
        );

        when(mockRepository.getStandaloneExpenses()).thenAnswer(
          (_) async => [expenseWithSettledSplit],
        );

        // Act
        final result = await useCase();

        // Assert
        expect(result.first.splits.first.isSettled, true);
        expect(result.first.splits.first.settledAt, isNotNull);
      });
    });
  });
}
