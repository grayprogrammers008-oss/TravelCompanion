import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:travel_crew/features/expenses/domain/repositories/expense_repository.dart';
import 'package:travel_crew/features/expenses/domain/usecases/get_user_expenses_usecase.dart';
import 'package:travel_crew/features/expenses/domain/usecases/get_standalone_expenses_usecase.dart';
import 'package:travel_crew/features/expenses/domain/usecases/create_expense_usecase.dart';
import 'package:travel_crew/features/expenses/domain/usecases/delete_expense_usecase.dart';
import 'package:travel_crew/shared/models/expense_model.dart';

@GenerateMocks([ExpenseRepository])
import 'expense_usecases_test.mocks.dart';

void main() {
  late MockExpenseRepository mockRepository;

  setUp(() {
    mockRepository = MockExpenseRepository();
  });

  // Helper function to create test expense
  ExpenseWithSplits createTestExpenseWithSplits({
    String id = 'expense-1',
    String title = 'Test Expense',
    double amount = 100.0,
  }) {
    final expense = ExpenseModel(
      id: id,
      tripId: 'trip-1',
      title: title,
      amount: amount,
      paidBy: 'user-1',
      createdAt: DateTime(2024, 1, 15),
    );
    return ExpenseWithSplits(
      expense: expense,
      splits: [
        ExpenseSplitModel(
          id: 'split-1',
          expenseId: id,
          userId: 'user-1',
          amount: amount / 2,
          isSettled: false,
        ),
        ExpenseSplitModel(
          id: 'split-2',
          expenseId: id,
          userId: 'user-2',
          amount: amount / 2,
          isSettled: false,
        ),
      ],
    );
  }

  group('GetUserExpensesUseCase', () {
    late GetUserExpensesUseCase useCase;

    setUp(() {
      useCase = GetUserExpensesUseCase(mockRepository);
    });

    test('should return list of expenses from repository', () async {
      // Arrange
      final expenses = [
        createTestExpenseWithSplits(id: 'expense-1', title: 'Dinner'),
        createTestExpenseWithSplits(id: 'expense-2', title: 'Taxi'),
      ];
      when(mockRepository.getUserExpenses()).thenAnswer((_) async => expenses);

      // Act
      final result = await useCase();

      // Assert
      expect(result, expenses);
      expect(result.length, 2);
      verify(mockRepository.getUserExpenses()).called(1);
    });

    test('should return empty list when no expenses exist', () async {
      // Arrange
      when(mockRepository.getUserExpenses()).thenAnswer((_) async => []);

      // Act
      final result = await useCase();

      // Assert
      expect(result, isEmpty);
      verify(mockRepository.getUserExpenses()).called(1);
    });

    test('should propagate exception from repository', () async {
      // Arrange
      when(mockRepository.getUserExpenses())
          .thenThrow(Exception('Database error'));

      // Act & Assert
      expect(() => useCase(), throwsException);
      verify(mockRepository.getUserExpenses()).called(1);
    });
  });

  group('GetStandaloneExpensesUseCase', () {
    late GetStandaloneExpensesUseCase useCase;

    setUp(() {
      useCase = GetStandaloneExpensesUseCase(mockRepository);
    });

    test('should return standalone expenses from repository', () async {
      // Arrange
      final standaloneExpense = ExpenseWithSplits(
        expense: ExpenseModel(
          id: 'expense-1',
          tripId: null, // No trip - standalone
          title: 'Coffee with friend',
          amount: 15.0,
          paidBy: 'user-1',
          createdAt: DateTime(2024, 1, 15),
        ),
        splits: [],
      );
      when(mockRepository.getStandaloneExpenses())
          .thenAnswer((_) async => [standaloneExpense]);

      // Act
      final result = await useCase();

      // Assert
      expect(result, [standaloneExpense]);
      expect(result.first.expense.tripId, isNull);
      verify(mockRepository.getStandaloneExpenses()).called(1);
    });

    test('should return empty list when no standalone expenses exist', () async {
      // Arrange
      when(mockRepository.getStandaloneExpenses()).thenAnswer((_) async => []);

      // Act
      final result = await useCase();

      // Assert
      expect(result, isEmpty);
    });

    test('should propagate exception from repository', () async {
      // Arrange
      when(mockRepository.getStandaloneExpenses())
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(() => useCase(), throwsException);
    });
  });

  group('CreateExpenseUseCase', () {
    late CreateExpenseUseCase useCase;

    setUp(() {
      useCase = CreateExpenseUseCase(mockRepository);
    });

    test('should create expense with valid data', () async {
      // Arrange
      final createdExpense = ExpenseModel(
        id: 'expense-new',
        tripId: 'trip-1',
        title: 'Dinner',
        description: 'Team dinner',
        amount: 150.0,
        category: 'food',
        paidBy: 'user-1',
        createdAt: DateTime.now(),
      );

      when(mockRepository.createExpense(
        tripId: anyNamed('tripId'),
        title: anyNamed('title'),
        description: anyNamed('description'),
        amount: anyNamed('amount'),
        category: anyNamed('category'),
        paidBy: anyNamed('paidBy'),
        splitWith: anyNamed('splitWith'),
        splitType: anyNamed('splitType'),
        transactionDate: anyNamed('transactionDate'),
      )).thenAnswer((_) async => createdExpense);

      // Act
      final result = await useCase(
        tripId: 'trip-1',
        title: 'Dinner',
        description: 'Team dinner',
        amount: 150.0,
        category: 'food',
        paidBy: 'user-1',
        splitWith: ['user-1', 'user-2'],
      );

      // Assert
      expect(result.id, 'expense-new');
      expect(result.title, 'Dinner');
      expect(result.amount, 150.0);
      verify(mockRepository.createExpense(
        tripId: 'trip-1',
        title: 'Dinner',
        description: 'Team dinner',
        amount: 150.0,
        category: 'food',
        paidBy: 'user-1',
        splitWith: ['user-1', 'user-2'],
        splitType: 'equal',
        transactionDate: null,
      )).called(1);
    });

    test('should create standalone expense without tripId', () async {
      // Arrange
      final standaloneExpense = ExpenseModel(
        id: 'expense-standalone',
        tripId: null,
        title: 'Coffee',
        amount: 10.0,
        paidBy: 'user-1',
        createdAt: DateTime.now(),
      );

      when(mockRepository.createExpense(
        tripId: anyNamed('tripId'),
        title: anyNamed('title'),
        description: anyNamed('description'),
        amount: anyNamed('amount'),
        category: anyNamed('category'),
        paidBy: anyNamed('paidBy'),
        splitWith: anyNamed('splitWith'),
        splitType: anyNamed('splitType'),
        transactionDate: anyNamed('transactionDate'),
      )).thenAnswer((_) async => standaloneExpense);

      // Act
      final result = await useCase(
        tripId: null,
        title: 'Coffee',
        amount: 10.0,
        paidBy: 'user-1',
        splitWith: ['user-1', 'user-2'],
      );

      // Assert
      expect(result.tripId, isNull);
    });

    test('should throw exception for empty title', () async {
      // Act & Assert
      expect(
        () => useCase(
          title: '',
          amount: 100.0,
          paidBy: 'user-1',
          splitWith: ['user-1'],
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Title cannot be empty'),
        )),
      );
      verifyNever(mockRepository.createExpense(
        title: anyNamed('title'),
        amount: anyNamed('amount'),
        paidBy: anyNamed('paidBy'),
        splitWith: anyNamed('splitWith'),
      ));
    });

    test('should throw exception for whitespace-only title', () async {
      // Act & Assert
      expect(
        () => useCase(
          title: '   ',
          amount: 100.0,
          paidBy: 'user-1',
          splitWith: ['user-1'],
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Title cannot be empty'),
        )),
      );
    });

    test('should throw exception for zero amount', () async {
      // Act & Assert
      expect(
        () => useCase(
          title: 'Test',
          amount: 0.0,
          paidBy: 'user-1',
          splitWith: ['user-1'],
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Amount must be greater than 0'),
        )),
      );
    });

    test('should throw exception for negative amount', () async {
      // Act & Assert
      expect(
        () => useCase(
          title: 'Test',
          amount: -50.0,
          paidBy: 'user-1',
          splitWith: ['user-1'],
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Amount must be greater than 0'),
        )),
      );
    });

    test('should throw exception for empty splitWith list', () async {
      // Act & Assert
      expect(
        () => useCase(
          title: 'Test',
          amount: 100.0,
          paidBy: 'user-1',
          splitWith: [],
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Must split with at least one person'),
        )),
      );
    });

    test('should pass transactionDate to repository', () async {
      // Arrange
      final transactionDate = DateTime(2024, 1, 15);
      final expense = ExpenseModel(
        id: 'expense-1',
        tripId: 'trip-1',
        title: 'Test',
        amount: 100.0,
        paidBy: 'user-1',
        transactionDate: transactionDate,
        createdAt: DateTime.now(),
      );

      when(mockRepository.createExpense(
        tripId: anyNamed('tripId'),
        title: anyNamed('title'),
        description: anyNamed('description'),
        amount: anyNamed('amount'),
        category: anyNamed('category'),
        paidBy: anyNamed('paidBy'),
        splitWith: anyNamed('splitWith'),
        splitType: anyNamed('splitType'),
        transactionDate: anyNamed('transactionDate'),
      )).thenAnswer((_) async => expense);

      // Act
      await useCase(
        tripId: 'trip-1',
        title: 'Test',
        amount: 100.0,
        paidBy: 'user-1',
        splitWith: ['user-1'],
        transactionDate: transactionDate,
      );

      // Assert
      verify(mockRepository.createExpense(
        tripId: 'trip-1',
        title: 'Test',
        description: null,
        amount: 100.0,
        category: null,
        paidBy: 'user-1',
        splitWith: ['user-1'],
        splitType: 'equal',
        transactionDate: transactionDate,
      )).called(1);
    });

    test('should use custom split type', () async {
      // Arrange
      final expense = ExpenseModel(
        id: 'expense-1',
        tripId: 'trip-1',
        title: 'Test',
        amount: 100.0,
        paidBy: 'user-1',
        createdAt: DateTime.now(),
      );

      when(mockRepository.createExpense(
        tripId: anyNamed('tripId'),
        title: anyNamed('title'),
        description: anyNamed('description'),
        amount: anyNamed('amount'),
        category: anyNamed('category'),
        paidBy: anyNamed('paidBy'),
        splitWith: anyNamed('splitWith'),
        splitType: anyNamed('splitType'),
        transactionDate: anyNamed('transactionDate'),
      )).thenAnswer((_) async => expense);

      // Act
      await useCase(
        tripId: 'trip-1',
        title: 'Test',
        amount: 100.0,
        paidBy: 'user-1',
        splitWith: ['user-1', 'user-2'],
        splitType: 'percentage',
      );

      // Assert
      verify(mockRepository.createExpense(
        tripId: 'trip-1',
        title: 'Test',
        description: null,
        amount: 100.0,
        category: null,
        paidBy: 'user-1',
        splitWith: ['user-1', 'user-2'],
        splitType: 'percentage',
        transactionDate: null,
      )).called(1);
    });
  });

  group('DeleteExpenseUseCase', () {
    late DeleteExpenseUseCase useCase;

    setUp(() {
      useCase = DeleteExpenseUseCase(mockRepository);
    });

    test('should delete expense with valid ID', () async {
      // Arrange
      when(mockRepository.deleteExpense(any)).thenAnswer((_) async {});

      // Act
      await useCase('expense-1');

      // Assert
      verify(mockRepository.deleteExpense('expense-1')).called(1);
    });

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

    test('should propagate exception from repository', () async {
      // Arrange
      when(mockRepository.deleteExpense(any))
          .thenThrow(Exception('Expense not found'));

      // Act & Assert
      expect(() => useCase('non-existent'), throwsException);
    });

    test('should handle network errors', () async {
      // Arrange
      when(mockRepository.deleteExpense(any))
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(() => useCase('expense-1'), throwsException);
    });
  });
}
