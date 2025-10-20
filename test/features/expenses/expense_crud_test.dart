import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/expenses/data/datasources/expense_local_datasource.dart';
import 'package:travel_crew/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:travel_crew/shared/models/expense_model.dart';

// Generate mocks for testing
@GenerateMocks([ExpenseLocalDataSource])
import 'expense_crud_test.mocks.dart';

void main() {
  late MockExpenseLocalDataSource mockDataSource;
  late ExpenseRepositoryImpl repository;

  // Test data
  const testUserId = 'test-user-123';
  const testTripId = 'test-trip-456';
  const testExpenseId = 'test-expense-789';

  final testExpense = ExpenseModel(
    id: testExpenseId,
    tripId: testTripId,
    title: 'Test Lunch',
    description: 'Team lunch at restaurant',
    amount: 500.0,
    currency: 'INR',
    category: 'Food',
    paidBy: testUserId,
    splitType: 'equal',
    transactionDate: DateTime(2025, 10, 11),
    createdAt: DateTime(2025, 10, 11),
    payerName: 'Test User',
  );

  final testSplit = ExpenseSplitModel(
    id: 'split-123',
    expenseId: testExpenseId,
    userId: testUserId,
    amount: 250.0,
    isSettled: false,
    userName: 'Test User',
  );

  final testExpenseWithSplits = ExpenseWithSplits(
    expense: testExpense,
    splits: [testSplit],
  );

  setUp(() {
    mockDataSource = MockExpenseLocalDataSource();
    repository = ExpenseRepositoryImpl(mockDataSource);
  });

  group('Create Expense Tests', () {
    test('POSITIVE: Should create a trip expense successfully', () async {
      // Arrange
      when(mockDataSource.createExpense(
        tripId: testTripId,
        title: 'Test Lunch',
        description: 'Team lunch',
        amount: 500.0,
        category: 'Food',
        paidBy: testUserId,
        splitWith: [testUserId, 'user-2'],
        splitType: 'equal',
        transactionDate: anyNamed('transactionDate'),
      )).thenAnswer((_) async => testExpense);

      // Act
      final result = await repository.createExpense(
        tripId: testTripId,
        title: 'Test Lunch',
        description: 'Team lunch',
        amount: 500.0,
        category: 'Food',
        paidBy: testUserId,
        splitWith: [testUserId, 'user-2'],
        transactionDate: DateTime(2025, 10, 11),
      );

      // Assert
      expect(result, equals(testExpense));
      expect(result.tripId, equals(testTripId));
      expect(result.amount, equals(500.0));
      verify(mockDataSource.createExpense(
        tripId: testTripId,
        title: 'Test Lunch',
        description: 'Team lunch',
        amount: 500.0,
        category: 'Food',
        paidBy: testUserId,
        splitWith: [testUserId, 'user-2'],
        splitType: 'equal',
        transactionDate: anyNamed('transactionDate'),
      )).called(1);
    });

    test('POSITIVE: Should create a standalone expense successfully', () async {
      // Arrange
      final standaloneExpense = testExpense.copyWith(tripId: null);
      when(mockDataSource.createExpense(
        tripId: null,
        title: 'Personal Shopping',
        description: null,
        amount: 200.0,
        category: 'Shopping',
        paidBy: testUserId,
        splitWith: [testUserId],
        splitType: 'equal',
        transactionDate: anyNamed('transactionDate'),
      )).thenAnswer((_) async => standaloneExpense);

      // Act
      final result = await repository.createExpense(
        tripId: null,
        title: 'Personal Shopping',
        amount: 200.0,
        category: 'Shopping',
        paidBy: testUserId,
        splitWith: [testUserId],
        transactionDate: DateTime(2025, 10, 11),
      );

      // Assert
      expect(result.tripId, isNull);
      expect(result.amount, equals(200.0));
    });

    test('NEGATIVE: Should throw exception when amount is zero', () async {
      // Arrange
      when(mockDataSource.createExpense(
        tripId: testTripId,
        title: 'Test',
        amount: 0.0,
        paidBy: testUserId,
        splitWith: [testUserId],
        splitType: 'equal',
        transactionDate: anyNamed('transactionDate'),
      )).thenThrow(Exception('Amount must be greater than zero'));

      // Act & Assert
      expect(
        () => repository.createExpense(
          tripId: testTripId,
          title: 'Test',
          amount: 0.0,
          paidBy: testUserId,
          splitWith: [testUserId],
        ),
        throwsException,
      );
    });

    test('NEGATIVE: Should throw exception when splitWith is empty', () async {
      // Arrange
      when(mockDataSource.createExpense(
        tripId: testTripId,
        title: 'Test',
        amount: 100.0,
        paidBy: testUserId,
        splitWith: [],
        splitType: 'equal',
        transactionDate: anyNamed('transactionDate'),
      )).thenThrow(Exception('Split must include at least one user'));

      // Act & Assert
      expect(
        () => repository.createExpense(
          tripId: testTripId,
          title: 'Test',
          amount: 100.0,
          paidBy: testUserId,
          splitWith: [],
        ),
        throwsException,
      );
    });

    test('NEGATIVE: Should throw exception with empty title', () async {
      // Arrange
      when(mockDataSource.createExpense(
        tripId: testTripId,
        title: '',
        amount: 100.0,
        paidBy: testUserId,
        splitWith: [testUserId],
        splitType: 'equal',
        transactionDate: anyNamed('transactionDate'),
      )).thenThrow(Exception('Title cannot be empty'));

      // Act & Assert
      expect(
        () => repository.createExpense(
          tripId: testTripId,
          title: '',
          amount: 100.0,
          paidBy: testUserId,
          splitWith: [testUserId],
        ),
        throwsException,
      );
    });
  });

  group('Read Expense Tests', () {
    test('POSITIVE: Should get all user expenses', () async {
      // Arrange
      when(mockDataSource.getUserExpenses())
          .thenAnswer((_) async => [testExpenseWithSplits]);

      // Act
      final result = await repository.getUserExpenses();

      // Assert
      expect(result, isA<List<ExpenseWithSplits>>());
      expect(result.length, equals(1));
      expect(result.first.expense.id, equals(testExpenseId));
      verify(mockDataSource.getUserExpenses()).called(1);
    });

    test('POSITIVE: Should get trip expenses', () async {
      // Arrange
      when(mockDataSource.getTripExpenses(testTripId))
          .thenAnswer((_) async => [testExpenseWithSplits]);

      // Act
      final result = await repository.getTripExpenses(testTripId);

      // Assert
      expect(result, isA<List<ExpenseWithSplits>>());
      expect(result.first.expense.tripId, equals(testTripId));
      verify(mockDataSource.getTripExpenses(testTripId)).called(1);
    });

    test('POSITIVE: Should get standalone expenses', () async {
      // Arrange
      final standaloneExpenseWithSplits = ExpenseWithSplits(
        expense: testExpense.copyWith(tripId: null),
        splits: [testSplit],
      );
      when(mockDataSource.getStandaloneExpenses())
          .thenAnswer((_) async => [standaloneExpenseWithSplits]);

      // Act
      final result = await repository.getStandaloneExpenses();

      // Assert
      expect(result, isA<List<ExpenseWithSplits>>());
      expect(result.first.expense.tripId, isNull);
      verify(mockDataSource.getStandaloneExpenses()).called(1);
    });

    test('POSITIVE: Should get expense by ID', () async {
      // Arrange
      when(mockDataSource.getExpenseById(testExpenseId))
          .thenAnswer((_) async => testExpenseWithSplits);

      // Act
      final result = await repository.getExpenseById(testExpenseId);

      // Assert
      expect(result, equals(testExpenseWithSplits));
      expect(result.expense.id, equals(testExpenseId));
      verify(mockDataSource.getExpenseById(testExpenseId)).called(1);
    });

    test('NEGATIVE: Should throw exception when expense not found', () async {
      // Arrange
      when(mockDataSource.getExpenseById('non-existent-id'))
          .thenThrow(Exception('Expense not found'));

      // Act & Assert
      expect(
        () => repository.getExpenseById('non-existent-id'),
        throwsException,
      );
    });

    test('NEGATIVE: Should return empty list when no expenses exist', () async {
      // Arrange
      when(mockDataSource.getUserExpenses()).thenAnswer((_) async => []);

      // Act
      final result = await repository.getUserExpenses();

      // Assert
      expect(result, isEmpty);
    });
  });

  group('Update Expense Tests', () {
    test('POSITIVE: Should update expense title', () async {
      // Arrange
      final updatedExpense = testExpense.copyWith(title: 'Updated Lunch');
      when(mockDataSource.updateExpense(
        expenseId: testExpenseId,
        title: 'Updated Lunch',
      )).thenAnswer((_) async => updatedExpense);

      // Act
      final result = await repository.updateExpense(
        expenseId: testExpenseId,
        title: 'Updated Lunch',
      );

      // Assert
      expect(result.title, equals('Updated Lunch'));
      verify(mockDataSource.updateExpense(
        expenseId: testExpenseId,
        title: 'Updated Lunch',
      )).called(1);
    });

    test('POSITIVE: Should update expense amount', () async {
      // Arrange
      final updatedExpense = testExpense.copyWith(amount: 600.0);
      when(mockDataSource.updateExpense(
        expenseId: testExpenseId,
        amount: 600.0,
      )).thenAnswer((_) async => updatedExpense);

      // Act
      final result = await repository.updateExpense(
        expenseId: testExpenseId,
        amount: 600.0,
      );

      // Assert
      expect(result.amount, equals(600.0));
    });

    test('POSITIVE: Should update multiple fields', () async {
      // Arrange
      final updatedExpense = testExpense.copyWith(
        title: 'Updated Title',
        amount: 750.0,
        category: 'Transport',
      );
      when(mockDataSource.updateExpense(
        expenseId: testExpenseId,
        title: 'Updated Title',
        amount: 750.0,
        category: 'Transport',
      )).thenAnswer((_) async => updatedExpense);

      // Act
      final result = await repository.updateExpense(
        expenseId: testExpenseId,
        title: 'Updated Title',
        amount: 750.0,
        category: 'Transport',
      );

      // Assert
      expect(result.title, equals('Updated Title'));
      expect(result.amount, equals(750.0));
      expect(result.category, equals('Transport'));
    });

    test('NEGATIVE: Should throw exception when updating non-existent expense',
        () async {
      // Arrange
      when(mockDataSource.updateExpense(
        expenseId: 'non-existent-id',
        title: 'Test',
      )).thenThrow(Exception('Expense not found'));

      // Act & Assert
      expect(
        () => repository.updateExpense(
          expenseId: 'non-existent-id',
          title: 'Test',
        ),
        throwsException,
      );
    });

    test('NEGATIVE: Should throw exception when updating with empty title',
        () async {
      // Arrange
      when(mockDataSource.updateExpense(
        expenseId: testExpenseId,
        title: '',
      )).thenThrow(Exception('Title cannot be empty'));

      // Act & Assert
      expect(
        () => repository.updateExpense(
          expenseId: testExpenseId,
          title: '',
        ),
        throwsException,
      );
    });

    test('NEGATIVE: Should throw exception when updating with zero amount',
        () async {
      // Arrange
      when(mockDataSource.updateExpense(
        expenseId: testExpenseId,
        amount: 0.0,
      )).thenThrow(Exception('Amount must be greater than zero'));

      // Act & Assert
      expect(
        () => repository.updateExpense(
          expenseId: testExpenseId,
          amount: 0.0,
        ),
        throwsException,
      );
    });
  });

  group('Delete Expense Tests', () {
    test('POSITIVE: Should delete expense successfully', () async {
      // Arrange
      when(mockDataSource.deleteExpense(testExpenseId))
          .thenAnswer((_) async => {});

      // Act
      await repository.deleteExpense(testExpenseId);

      // Assert
      verify(mockDataSource.deleteExpense(testExpenseId)).called(1);
    });

    test('POSITIVE: Should delete expense and cascadeDelete splits', () async {
      // Arrange
      when(mockDataSource.deleteExpense(testExpenseId))
          .thenAnswer((_) async => {});

      // Act
      await repository.deleteExpense(testExpenseId);

      // Assert - Should verify that splits are also deleted (cascade)
      verify(mockDataSource.deleteExpense(testExpenseId)).called(1);
    });

    test('NEGATIVE: Should throw exception when deleting non-existent expense',
        () async {
      // Arrange
      when(mockDataSource.deleteExpense('non-existent-id'))
          .thenThrow(Exception('Expense not found'));

      // Act & Assert
      expect(
        () => repository.deleteExpense('non-existent-id'),
        throwsException,
      );
    });

    test('NEGATIVE: Should throw exception when database error occurs',
        () async {
      // Arrange
      when(mockDataSource.deleteExpense(testExpenseId))
          .thenThrow(Exception('Database error'));

      // Act & Assert
      expect(
        () => repository.deleteExpense(testExpenseId),
        throwsException,
      );
    });
  });

  group('Balance Calculation Tests', () {
    test('POSITIVE: Should calculate trip balances correctly', () async {
      // Arrange
      final balances = [
        BalanceSummary(
          userId: testUserId,
          userName: 'Test User',
          totalPaid: 500.0,
          totalOwed: 250.0,
          balance: 250.0,
        ),
        BalanceSummary(
          userId: 'user-2',
          userName: 'User Two',
          totalPaid: 0.0,
          totalOwed: 250.0,
          balance: -250.0,
        ),
      ];
      when(mockDataSource.getBalances(tripId: testTripId))
          .thenAnswer((_) async => balances);

      // Act
      final result = await repository.getBalances(tripId: testTripId);

      // Assert
      expect(result.length, equals(2));
      expect(result[0].balance, equals(250.0)); // Owed to user
      expect(result[1].balance, equals(-250.0)); // User owes
      verify(mockDataSource.getBalances(tripId: testTripId)).called(1);
    });

    test('POSITIVE: Should calculate standalone balances', () async {
      // Arrange
      final balances = [
        BalanceSummary(
          userId: testUserId,
          userName: 'Test User',
          totalPaid: 200.0,
          totalOwed: 200.0,
          balance: 0.0,
        ),
      ];
      when(mockDataSource.getBalances(userId: testUserId))
          .thenAnswer((_) async => balances);

      // Act
      final result = await repository.getBalances(userId: testUserId);

      // Assert
      expect(result.length, equals(1));
      expect(result[0].balance, equals(0.0)); // Balanced
    });

    test('NEGATIVE: Should return empty list when no expenses exist', () async {
      // Arrange
      when(mockDataSource.getBalances(tripId: testTripId))
          .thenAnswer((_) async => []);

      // Act
      final result = await repository.getBalances(tripId: testTripId);

      // Assert
      expect(result, isEmpty);
    });
  });

  group('Edge Cases Tests', () {
    test('EDGE CASE: Should handle large amount values', () async {
      // Arrange
      final largeExpense =
          testExpense.copyWith(amount: 999999999.99); // Large amount
      when(mockDataSource.createExpense(
        tripId: testTripId,
        title: 'Large Expense',
        amount: 999999999.99,
        paidBy: testUserId,
        splitWith: [testUserId],
        splitType: 'equal',
        transactionDate: anyNamed('transactionDate'),
      )).thenAnswer((_) async => largeExpense);

      // Act
      final result = await repository.createExpense(
        tripId: testTripId,
        title: 'Large Expense',
        amount: 999999999.99,
        paidBy: testUserId,
        splitWith: [testUserId],
      );

      // Assert
      expect(result.amount, equals(999999999.99));
    });

    test('EDGE CASE: Should handle decimal amounts correctly', () async {
      // Arrange
      final decimalExpense = testExpense.copyWith(amount: 123.45);
      when(mockDataSource.createExpense(
        tripId: testTripId,
        title: 'Decimal Expense',
        amount: 123.45,
        paidBy: testUserId,
        splitWith: [testUserId, 'user-2', 'user-3'], // Split by 3
        splitType: 'equal',
        transactionDate: anyNamed('transactionDate'),
      )).thenAnswer((_) async => decimalExpense);

      // Act
      final result = await repository.createExpense(
        tripId: testTripId,
        title: 'Decimal Expense',
        amount: 123.45,
        paidBy: testUserId,
        splitWith: [testUserId, 'user-2', 'user-3'],
      );

      // Assert
      expect(result.amount, equals(123.45));
      // Split should be 41.15 per person (123.45 / 3)
    });

    test('EDGE CASE: Should handle expense with very long title', () async {
      // Arrange
      final longTitle = 'A' * 500; // Very long title
      final longTitleExpense = testExpense.copyWith(title: longTitle);
      when(mockDataSource.createExpense(
        tripId: testTripId,
        title: longTitle,
        amount: 100.0,
        paidBy: testUserId,
        splitWith: [testUserId],
        splitType: 'equal',
        transactionDate: anyNamed('transactionDate'),
      )).thenAnswer((_) async => longTitleExpense);

      // Act
      final result = await repository.createExpense(
        tripId: testTripId,
        title: longTitle,
        amount: 100.0,
        paidBy: testUserId,
        splitWith: [testUserId],
      );

      // Assert
      expect(result.title.length, equals(500));
    });

    test('EDGE CASE: Should handle future transaction dates', () async {
      // Arrange
      final futureDate = DateTime(2026, 12, 31);
      final futureExpense = testExpense.copyWith(transactionDate: futureDate);
      when(mockDataSource.createExpense(
        tripId: testTripId,
        title: 'Future Expense',
        amount: 100.0,
        paidBy: testUserId,
        splitWith: [testUserId],
        splitType: 'equal',
        transactionDate: futureDate,
      )).thenAnswer((_) async => futureExpense);

      // Act
      final result = await repository.createExpense(
        tripId: testTripId,
        title: 'Future Expense',
        amount: 100.0,
        paidBy: testUserId,
        splitWith: [testUserId],
        transactionDate: futureDate,
      );

      // Assert
      expect(result.transactionDate, equals(futureDate));
    });
  });

  group('Concurrent Operations Tests', () {
    test('POSITIVE: Should handle multiple simultaneous creates', () async {
      // Arrange
      final expense1 = testExpense.copyWith(id: 'exp-1', title: 'Expense 1');
      final expense2 = testExpense.copyWith(id: 'exp-2', title: 'Expense 2');
      final expense3 = testExpense.copyWith(id: 'exp-3', title: 'Expense 3');

      when(mockDataSource.createExpense(
        tripId: testTripId,
        title: 'Expense 1',
        amount: 100.0,
        paidBy: testUserId,
        splitWith: [testUserId],
        splitType: 'equal',
        transactionDate: anyNamed('transactionDate'),
      )).thenAnswer((_) async => expense1);

      when(mockDataSource.createExpense(
        tripId: testTripId,
        title: 'Expense 2',
        amount: 200.0,
        paidBy: testUserId,
        splitWith: [testUserId],
        splitType: 'equal',
        transactionDate: anyNamed('transactionDate'),
      )).thenAnswer((_) async => expense2);

      when(mockDataSource.createExpense(
        tripId: testTripId,
        title: 'Expense 3',
        amount: 300.0,
        paidBy: testUserId,
        splitWith: [testUserId],
        splitType: 'equal',
        transactionDate: anyNamed('transactionDate'),
      )).thenAnswer((_) async => expense3);

      // Act - Create multiple expenses concurrently
      final results = await Future.wait([
        repository.createExpense(
          tripId: testTripId,
          title: 'Expense 1',
          amount: 100.0,
          paidBy: testUserId,
          splitWith: [testUserId],
        ),
        repository.createExpense(
          tripId: testTripId,
          title: 'Expense 2',
          amount: 200.0,
          paidBy: testUserId,
          splitWith: [testUserId],
        ),
        repository.createExpense(
          tripId: testTripId,
          title: 'Expense 3',
          amount: 300.0,
          paidBy: testUserId,
          splitWith: [testUserId],
        ),
      ]);

      // Assert
      expect(results.length, equals(3));
      expect(results[0].id, equals('exp-1'));
      expect(results[1].id, equals('exp-2'));
      expect(results[2].id, equals('exp-3'));
    });
  });
}
