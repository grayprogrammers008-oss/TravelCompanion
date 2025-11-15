import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/expenses/domain/repositories/expense_repository.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_trip_cost_usecase.dart';
import 'package:travel_crew/shared/models/expense_model.dart';

import 'get_trip_cost_usecase_test.mocks.dart';

@GenerateMocks([ExpenseRepository])
void main() {
  late GetTripCostUseCase useCase;
  late MockExpenseRepository mockRepository;

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = GetTripCostUseCase(mockRepository);
  });

  group('GetTripCostUseCase', () {
    const tripId = 'trip123';

    // Helper to create test expense
    ExpenseModel createExpense({
      required String id,
      required String title,
      required double amount,
      String? category,
      String paidBy = 'user1',
      DateTime? transactionDate,
    }) {
      return ExpenseModel(
        id: id,
        tripId: tripId,
        title: title,
        description: 'Test expense',
        amount: amount,
        currency: 'INR',
        category: category,
        paidBy: paidBy,
        transactionDate: transactionDate,
        createdAt: DateTime(2024, 1, 1),
      );
    }

    // Helper to create ExpenseWithSplits
    ExpenseWithSplits createExpenseWithSplits(ExpenseModel expense) {
      return ExpenseWithSplits(
        expense: expense,
        splits: [
          ExpenseSplitModel(
            id: 'split1',
            expenseId: expense.id,
            userId: 'user1',
            amount: expense.amount,
            isSettled: true,
          ),
        ],
      );
    }

    group('Basic functionality', () {
      test('should return zero cost summary when trip has no expenses',
          () async {
        // Arrange
        when(mockRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => []);

        // Act
        final result = await useCase(tripId);

        // Assert
        expect(result.tripId, tripId);
        expect(result.totalCost, 0.0);
        expect(result.currency, 'INR');
        expect(result.expenseCount, 0);
        expect(result.categoryBreakdown, isEmpty);
        expect(result.userSpending, isEmpty);
        expect(result.lastExpenseDate, isNull);
        verify(mockRepository.getTripExpenses(tripId)).called(1);
      });

      test('should calculate total cost for single expense', () async {
        // Arrange
        final expense = createExpense(
          id: 'exp1',
          title: 'Hotel',
          amount: 5000.0,
          category: 'Accommodation',
        );
        when(mockRepository.getTripExpenses(tripId)).thenAnswer(
          (_) async => [createExpenseWithSplits(expense)],
        );

        // Act
        final result = await useCase(tripId);

        // Assert
        expect(result.tripId, tripId);
        expect(result.totalCost, 5000.0);
        expect(result.currency, 'INR');
        expect(result.expenseCount, 1);
        verify(mockRepository.getTripExpenses(tripId)).called(1);
      });

      test('should calculate total cost for multiple expenses', () async {
        // Arrange
        final expenses = [
          createExpenseWithSplits(
            createExpense(id: 'exp1', title: 'Hotel', amount: 5000.0),
          ),
          createExpenseWithSplits(
            createExpense(id: 'exp2', title: 'Food', amount: 2000.0),
          ),
          createExpenseWithSplits(
            createExpense(id: 'exp3', title: 'Transport', amount: 1500.0),
          ),
        ];
        when(mockRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final result = await useCase(tripId);

        // Assert
        expect(result.totalCost, 8500.0);
        expect(result.expenseCount, 3);
      });
    });

    group('Category breakdown', () {
      test('should aggregate expenses by category', () async {
        // Arrange
        final expenses = [
          createExpenseWithSplits(
            createExpense(
              id: 'exp1',
              title: 'Hotel',
              amount: 5000.0,
              category: 'Accommodation',
            ),
          ),
          createExpenseWithSplits(
            createExpense(
              id: 'exp2',
              title: 'Dinner',
              amount: 1500.0,
              category: 'Food',
            ),
          ),
          createExpenseWithSplits(
            createExpense(
              id: 'exp3',
              title: 'Breakfast',
              amount: 500.0,
              category: 'Food',
            ),
          ),
          createExpenseWithSplits(
            createExpense(
              id: 'exp4',
              title: 'Taxi',
              amount: 800.0,
              category: 'Transport',
            ),
          ),
        ];
        when(mockRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final result = await useCase(tripId);

        // Assert
        expect(result.categoryBreakdown['Accommodation'], 5000.0);
        expect(result.categoryBreakdown['Food'], 2000.0);
        expect(result.categoryBreakdown['Transport'], 800.0);
        expect(result.getCategorySpending('Accommodation'), 5000.0);
        expect(result.getCategorySpending('Food'), 2000.0);
      });

      test('should handle expenses without category as Uncategorized',
          () async {
        // Arrange
        final expenses = [
          createExpenseWithSplits(
            createExpense(id: 'exp1', title: 'Misc', amount: 500.0),
          ),
          createExpenseWithSplits(
            createExpense(id: 'exp2', title: 'Other', amount: 300.0),
          ),
        ];
        when(mockRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final result = await useCase(tripId);

        // Assert
        expect(result.categoryBreakdown['Uncategorized'], 800.0);
        expect(result.getCategorySpending('Uncategorized'), 800.0);
      });

      test('should list all categories with spending', () async {
        // Arrange
        final expenses = [
          createExpenseWithSplits(
            createExpense(
                id: 'exp1', title: 'Hotel', amount: 1000.0, category: 'Accommodation'),
          ),
          createExpenseWithSplits(
            createExpense(id: 'exp2', title: 'Food', amount: 500.0, category: 'Food'),
          ),
          createExpenseWithSplits(
            createExpense(
                id: 'exp3', title: 'Transport', amount: 300.0, category: 'Transport'),
          ),
        ];
        when(mockRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final result = await useCase(tripId);

        // Assert
        expect(result.categoriesWithSpending.length, 3);
        expect(result.categoriesWithSpending,
            containsAll(['Accommodation', 'Food', 'Transport']));
      });
    });

    group('User spending', () {
      test('should aggregate expenses by user who paid', () async {
        // Arrange
        final expenses = [
          createExpenseWithSplits(
            createExpense(id: 'exp1', title: 'Hotel', amount: 5000.0, paidBy: 'user1'),
          ),
          createExpenseWithSplits(
            createExpense(id: 'exp2', title: 'Food', amount: 2000.0, paidBy: 'user2'),
          ),
          createExpenseWithSplits(
            createExpense(id: 'exp3', title: 'Taxi', amount: 500.0, paidBy: 'user1'),
          ),
          createExpenseWithSplits(
            createExpense(id: 'exp4', title: 'Snacks', amount: 300.0, paidBy: 'user2'),
          ),
        ];
        when(mockRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final result = await useCase(tripId);

        // Assert
        expect(result.userSpending['user1'], 5500.0);
        expect(result.userSpending['user2'], 2300.0);
        expect(result.getUserSpending('user1'), 5500.0);
        expect(result.getUserSpending('user2'), 2300.0);
      });

      test('should list all users with spending', () async {
        // Arrange
        final expenses = [
          createExpenseWithSplits(
            createExpense(id: 'exp1', title: 'Expense', amount: 100.0, paidBy: 'user1'),
          ),
          createExpenseWithSplits(
            createExpense(id: 'exp2', title: 'Expense', amount: 200.0, paidBy: 'user2'),
          ),
          createExpenseWithSplits(
            createExpense(id: 'exp3', title: 'Expense', amount: 300.0, paidBy: 'user3'),
          ),
        ];
        when(mockRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final result = await useCase(tripId);

        // Assert
        expect(result.usersWithSpending.length, 3);
        expect(result.usersWithSpending, containsAll(['user1', 'user2', 'user3']));
      });

      test('should return 0 for users who have not spent', () async {
        // Arrange
        final expenses = [
          createExpenseWithSplits(
            createExpense(id: 'exp1', title: 'Expense', amount: 100.0, paidBy: 'user1'),
          ),
        ];
        when(mockRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final result = await useCase(tripId);

        // Assert
        expect(result.getUserSpending('user2'), 0.0);
        expect(result.getUserSpending('nonexistent'), 0.0);
      });
    });

    group('Date tracking', () {
      test('should track last expense transaction date', () async {
        // Arrange
        final date1 = DateTime(2024, 1, 15);
        final date2 = DateTime(2024, 1, 20);
        final date3 = DateTime(2024, 1, 10);

        final expenses = [
          createExpenseWithSplits(
            createExpense(
              id: 'exp1',
              title: 'Expense 1',
              amount: 100.0,
              transactionDate: date1,
            ),
          ),
          createExpenseWithSplits(
            createExpense(
              id: 'exp2',
              title: 'Expense 2',
              amount: 200.0,
              transactionDate: date2,
            ),
          ),
          createExpenseWithSplits(
            createExpense(
              id: 'exp3',
              title: 'Expense 3',
              amount: 300.0,
              transactionDate: date3,
            ),
          ),
        ];
        when(mockRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final result = await useCase(tripId);

        // Assert
        expect(result.lastExpenseDate, date2);
      });

      test('should use createdAt when transactionDate is null', () async {
        // Arrange
        final createdDate = DateTime(2024, 1, 25);
        final expense = ExpenseModel(
          id: 'exp1',
          tripId: tripId,
          title: 'Test',
          amount: 100.0,
          currency: 'INR',
          paidBy: 'user1',
          transactionDate: null,
          createdAt: createdDate,
        );
        when(mockRepository.getTripExpenses(tripId)).thenAnswer(
          (_) async => [createExpenseWithSplits(expense)],
        );

        // Act
        final result = await useCase(tripId);

        // Assert
        expect(result.lastExpenseDate, createdDate);
      });

      test('should handle expenses without any dates', () async {
        // Arrange
        final expense = ExpenseModel(
          id: 'exp1',
          tripId: tripId,
          title: 'Test',
          amount: 100.0,
          currency: 'INR',
          paidBy: 'user1',
          transactionDate: null,
          createdAt: null,
        );
        when(mockRepository.getTripExpenses(tripId)).thenAnswer(
          (_) async => [createExpenseWithSplits(expense)],
        );

        // Act
        final result = await useCase(tripId);

        // Assert
        expect(result.lastExpenseDate, isNull);
      });
    });

    group('Statistics', () {
      test('should calculate average expense amount', () async {
        // Arrange
        final expenses = [
          createExpenseWithSplits(
            createExpense(id: 'exp1', title: 'Expense 1', amount: 1000.0),
          ),
          createExpenseWithSplits(
            createExpense(id: 'exp2', title: 'Expense 2', amount: 2000.0),
          ),
          createExpenseWithSplits(
            createExpense(id: 'exp3', title: 'Expense 3', amount: 3000.0),
          ),
        ];
        when(mockRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final result = await useCase(tripId);

        // Assert
        expect(result.averageExpenseAmount, 2000.0);
      });

      test('should return 0 average when no expenses', () async {
        // Arrange
        when(mockRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => []);

        // Act
        final result = await useCase(tripId);

        // Assert
        expect(result.averageExpenseAmount, 0.0);
      });
    });

    group('Edge cases', () {
      test('should handle large number of expenses', () async {
        // Arrange
        final expenses = List.generate(
          100,
          (i) => createExpenseWithSplits(
            createExpense(
              id: 'exp$i',
              title: 'Expense $i',
              amount: 100.0,
              category: 'Category ${i % 5}',
              paidBy: 'user${i % 3}',
            ),
          ),
        );
        when(mockRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final result = await useCase(tripId);

        // Assert
        expect(result.totalCost, 10000.0);
        expect(result.expenseCount, 100);
        expect(result.categoryBreakdown.length, 5);
        expect(result.userSpending.length, 3);
      });

      test('should handle expenses with zero amount', () async {
        // Arrange
        final expenses = [
          createExpenseWithSplits(
            createExpense(id: 'exp1', title: 'Zero expense', amount: 0.0),
          ),
          createExpenseWithSplits(
            createExpense(id: 'exp2', title: 'Normal expense', amount: 100.0),
          ),
        ];
        when(mockRepository.getTripExpenses(tripId))
            .thenAnswer((_) async => expenses);

        // Act
        final result = await useCase(tripId);

        // Assert
        expect(result.totalCost, 100.0);
        expect(result.expenseCount, 2);
      });

      test('should propagate repository exceptions', () async {
        // Arrange
        when(mockRepository.getTripExpenses(tripId))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(() => useCase(tripId), throwsException);
      });
    });

    group('Currency handling', () {
      test('should use currency from first expense', () async {
        // Arrange
        final expense = ExpenseModel(
          id: 'exp1',
          tripId: tripId,
          title: 'Test',
          amount: 100.0,
          currency: 'USD',
          paidBy: 'user1',
        );
        when(mockRepository.getTripExpenses(tripId)).thenAnswer(
          (_) async => [createExpenseWithSplits(expense)],
        );

        // Act
        final result = await useCase(tripId);

        // Assert
        expect(result.currency, 'USD');
      });
    });
  });
}
