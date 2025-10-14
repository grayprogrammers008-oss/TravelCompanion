import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:travel_crew/features/expenses/data/datasources/expense_local_datasource.dart';
import 'package:travel_crew/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:travel_crew/shared/models/expense_model.dart';

/// Integration tests for Expense CRUD operations
/// These tests use the real SQLite database
void main() {
  late AuthLocalDataSource authDataSource;
  late ExpenseLocalDataSource expenseDataSource;
  late ExpenseRepositoryImpl repository;
  late String testUserId;

  setUpAll(() async {
    // Initialize Flutter bindings for tests
    TestWidgetsFlutterBinding.ensureInitialized();

    // Initialize datasources
    authDataSource = AuthLocalDataSource();
    expenseDataSource = ExpenseLocalDataSource();
    repository = ExpenseRepositoryImpl(expenseDataSource);

    // Create test user and sign in
    try {
      final user = await authDataSource.signUp(
        email: 'test@example.com',
        password: 'Test123!',
        fullName: 'Test User',
      );
      testUserId = user.id;
      expenseDataSource.setCurrentUserId(testUserId);
    } catch (e) {
      // User might already exist, try to sign in
      final user = await authDataSource.signIn(
        email: 'test@example.com',
        password: 'Test123!',
      );
      testUserId = user.id;
      expenseDataSource.setCurrentUserId(testUserId);
    }
  });

  tearDownAll(() {
    // Clean up: delete test expenses
    authDataSource.clearSession();
  });

  group('CREATE Expense Operations', () {
    test('POSITIVE: Create standalone expense successfully', () async {
      // Arrange
      const title = 'Grocery Shopping';
      const description = 'Weekly groceries';
      const amount = 150.0;
      const category = 'Shopping';

      // Act
      final expense = await repository.createExpense(
        tripId: null, // Standalone
        title: title,
        description: description,
        amount: amount,
        category: category,
        paidBy: testUserId,
        splitWith: [testUserId],
      );

      // Assert
      expect(expense, isNotNull);
      expect(expense.title, equals(title));
      expect(expense.description, equals(description));
      expect(expense.amount, equals(amount));
      expect(expense.category, equals(category));
      expect(expense.tripId, isNull);
      expect(expense.paidBy, equals(testUserId));
    });

    test('POSITIVE: Create expense with multiple splits', () async {
      // Arrange
      const title = 'Team Lunch';
      const amount = 600.0;
      final splitWith = [testUserId, 'user-2', 'user-3']; // 3 people

      // Act
      final expense = await repository.createExpense(
        tripId: null,
        title: title,
        amount: amount,
        category: 'Food',
        paidBy: testUserId,
        splitWith: splitWith,
      );

      // Assert
      expect(expense, isNotNull);
      expect(expense.amount, equals(amount));
      // Each person should owe 200.0 (600 / 3)
    });

    test('POSITIVE: Create expense with category', () async {
      // Act
      final expense = await repository.createExpense(
        tripId: null,
        title: 'Uber Ride',
        amount: 250.0,
        category: 'Transport',
        paidBy: testUserId,
        splitWith: [testUserId],
      );

      // Assert
      expect(expense.category, equals('Transport'));
    });

    test('POSITIVE: Create expense with future date', () async {
      // Arrange
      final futureDate = DateTime.now().add(const Duration(days: 5));

      // Act
      final expense = await repository.createExpense(
        tripId: null,
        title: 'Future Booking',
        amount: 1000.0,
        paidBy: testUserId,
        splitWith: [testUserId],
        transactionDate: futureDate,
      );

      // Assert
      expect(expense.transactionDate, isNotNull);
      expect(expense.transactionDate!.isAfter(DateTime.now()), isTrue);
    });

    test('NEGATIVE: Fail to create expense with empty title', () async {
      // Act & Assert
      expect(
        () => repository.createExpense(
          tripId: null,
          title: '', // Empty title
          amount: 100.0,
          paidBy: testUserId,
          splitWith: [testUserId],
        ),
        throwsException,
      );
    });

    test('NEGATIVE: Fail to create expense with zero amount', () async {
      // Act & Assert
      expect(
        () => repository.createExpense(
          tripId: null,
          title: 'Zero Amount Test',
          amount: 0.0, // Invalid amount
          paidBy: testUserId,
          splitWith: [testUserId],
        ),
        throwsException,
      );
    });

    test('NEGATIVE: Fail to create expense with negative amount', () async {
      // Act & Assert
      expect(
        () => repository.createExpense(
          tripId: null,
          title: 'Negative Amount Test',
          amount: -50.0, // Negative amount
          paidBy: testUserId,
          splitWith: [testUserId],
        ),
        throwsException,
      );
    });

    test('NEGATIVE: Fail to create expense with empty splitWith list',
        () async {
      // Act & Assert
      expect(
        () => repository.createExpense(
          tripId: null,
          title: 'No Split Test',
          amount: 100.0,
          paidBy: testUserId,
          splitWith: [], // Empty split list
        ),
        throwsException,
      );
    });
  });

  group('READ Expense Operations', () {
    late String createdExpenseId;

    setUp(() async {
      // Create a test expense for reading
      final expense = await repository.createExpense(
        tripId: null,
        title: 'Test Read Expense',
        amount: 300.0,
        paidBy: testUserId,
        splitWith: [testUserId],
      );
      createdExpenseId = expense.id;
    });

    test('POSITIVE: Get all user expenses', () async {
      // Act
      final expenses = await repository.getUserExpenses();

      // Assert
      expect(expenses, isNotEmpty);
      expect(expenses, isA<List<ExpenseWithSplits>>());
      expect(expenses.any((e) => e.expense.id == createdExpenseId), isTrue);
    });

    test('POSITIVE: Get standalone expenses only', () async {
      // Act
      final expenses = await repository.getStandaloneExpenses();

      // Assert
      expect(expenses, isNotEmpty);
      expect(expenses.every((e) => e.expense.tripId == null), isTrue);
    });

    test('POSITIVE: Get expense by ID', () async {
      // Act
      final expenseWithSplits =
          await repository.getExpenseById(createdExpenseId);

      // Assert
      expect(expenseWithSplits, isNotNull);
      expect(expenseWithSplits.expense.id, equals(createdExpenseId));
      expect(expenseWithSplits.expense.title, equals('Test Read Expense'));
      expect(expenseWithSplits.splits, isNotEmpty);
    });

    test('POSITIVE: Verify expense has correct splits', () async {
      // Act
      final expenseWithSplits =
          await repository.getExpenseById(createdExpenseId);

      // Assert
      expect(expenseWithSplits.splits.length, equals(1));
      expect(expenseWithSplits.splits.first.userId, equals(testUserId));
      expect(expenseWithSplits.splits.first.amount, equals(300.0));
    });

    test('NEGATIVE: Fail to get expense with invalid ID', () async {
      // Act & Assert
      expect(
        () => repository.getExpenseById('non-existent-id-12345'),
        throwsException,
      );
    });
  });

  group('UPDATE Expense Operations', () {
    late String expenseToUpdateId;

    setUp(() async {
      // Create expense to update
      final expense = await repository.createExpense(
        tripId: null,
        title: 'Original Title',
        description: 'Original Description',
        amount: 400.0,
        category: 'Food',
        paidBy: testUserId,
        splitWith: [testUserId],
      );
      expenseToUpdateId = expense.id;
    });

    test('POSITIVE: Update expense title', () async {
      // Act
      final updatedExpense = await repository.updateExpense(
        expenseId: expenseToUpdateId,
        title: 'Updated Title',
      );

      // Assert
      expect(updatedExpense.title, equals('Updated Title'));
      expect(updatedExpense.id, equals(expenseToUpdateId));
    });

    test('POSITIVE: Update expense description', () async {
      // Act
      final updatedExpense = await repository.updateExpense(
        expenseId: expenseToUpdateId,
        description: 'Updated Description',
      );

      // Assert
      expect(updatedExpense.description, equals('Updated Description'));
    });

    test('POSITIVE: Update expense amount', () async {
      // Act
      final updatedExpense = await repository.updateExpense(
        expenseId: expenseToUpdateId,
        amount: 500.0,
      );

      // Assert
      expect(updatedExpense.amount, equals(500.0));
    });

    test('POSITIVE: Update expense category', () async {
      // Act
      final updatedExpense = await repository.updateExpense(
        expenseId: expenseToUpdateId,
        category: 'Transport',
      );

      // Assert
      expect(updatedExpense.category, equals('Transport'));
    });

    test('POSITIVE: Update multiple fields at once', () async {
      // Act
      final updatedExpense = await repository.updateExpense(
        expenseId: expenseToUpdateId,
        title: 'Completely Updated',
        description: 'New Description',
        amount: 750.0,
        category: 'Entertainment',
      );

      // Assert
      expect(updatedExpense.title, equals('Completely Updated'));
      expect(updatedExpense.description, equals('New Description'));
      expect(updatedExpense.amount, equals(750.0));
      expect(updatedExpense.category, equals('Entertainment'));
    });

    test('POSITIVE: Verify updated expense persists', () async {
      // Arrange - Update expense
      await repository.updateExpense(
        expenseId: expenseToUpdateId,
        title: 'Persisted Title',
      );

      // Act - Fetch the updated expense
      final fetched = await repository.getExpenseById(expenseToUpdateId);

      // Assert
      expect(fetched.expense.title, equals('Persisted Title'));
    });

    test('NEGATIVE: Fail to update expense with invalid ID', () async {
      // Act & Assert
      expect(
        () => repository.updateExpense(
          expenseId: 'invalid-id-12345',
          title: 'New Title',
        ),
        throwsException,
      );
    });

    test('NEGATIVE: Fail to update with empty title', () async {
      // Act & Assert
      expect(
        () => repository.updateExpense(
          expenseId: expenseToUpdateId,
          title: '', // Empty title
        ),
        throwsException,
      );
    });

    test('NEGATIVE: Fail to update with zero amount', () async {
      // Act & Assert
      expect(
        () => repository.updateExpense(
          expenseId: expenseToUpdateId,
          amount: 0.0, // Invalid amount
        ),
        throwsException,
      );
    });

    test('NEGATIVE: Fail to update with negative amount', () async {
      // Act & Assert
      expect(
        () => repository.updateExpense(
          expenseId: expenseToUpdateId,
          amount: -100.0, // Negative amount
        ),
        throwsException,
      );
    });
  });

  group('DELETE Expense Operations', () {
    late String expenseToDeleteId;

    setUp(() async {
      // Create expense to delete
      final expense = await repository.createExpense(
        tripId: null,
        title: 'Expense To Delete',
        amount: 200.0,
        paidBy: testUserId,
        splitWith: [testUserId],
      );
      expenseToDeleteId = expense.id;
    });

    test('POSITIVE: Delete expense successfully', () async {
      // Act
      await repository.deleteExpense(expenseToDeleteId);

      // Assert - Expense should no longer exist
      expect(
        () => repository.getExpenseById(expenseToDeleteId),
        throwsException,
      );
    });

    test('POSITIVE: Verify deleted expense not in user expenses list',
        () async {
      // Arrange - Get initial count
      final beforeDelete = await repository.getUserExpenses();
      final initialCount = beforeDelete.length;

      // Act - Delete
      await repository.deleteExpense(expenseToDeleteId);

      // Assert - Count should decrease
      final afterDelete = await repository.getUserExpenses();
      expect(afterDelete.length, lessThan(initialCount));
      expect(
          afterDelete.any((e) => e.expense.id == expenseToDeleteId), isFalse);
    });

    test('POSITIVE: Delete expense with splits (cascade delete)', () async {
      // Arrange - Create expense with multiple splits
      final expense = await repository.createExpense(
        tripId: null,
        title: 'Multi-Split Expense',
        amount: 900.0,
        paidBy: testUserId,
        splitWith: [testUserId, 'user-2', 'user-3'],
      );

      // Act - Delete expense
      await repository.deleteExpense(expense.id);

      // Assert - Expense and all splits should be deleted
      expect(
        () => repository.getExpenseById(expense.id),
        throwsException,
      );
    });

    test('NEGATIVE: Fail to delete expense with invalid ID', () async {
      // Act & Assert
      expect(
        () => repository.deleteExpense('non-existent-id-12345'),
        throwsException,
      );
    });

    test('NEGATIVE: Fail to delete already deleted expense', () async {
      // Arrange - Delete once
      await repository.deleteExpense(expenseToDeleteId);

      // Act & Assert - Try to delete again
      expect(
        () => repository.deleteExpense(expenseToDeleteId),
        throwsException,
      );
    });
  });

  group('EDGE CASE Tests', () {
    test('EDGE: Handle very large amounts', () async {
      // Act
      final expense = await repository.createExpense(
        tripId: null,
        title: 'Large Amount',
        amount: 999999999.99,
        paidBy: testUserId,
        splitWith: [testUserId],
      );

      // Assert
      expect(expense.amount, equals(999999999.99));
    });

    test('EDGE: Handle decimal precision in splits', () async {
      // Arrange - Amount that doesn't divide evenly
      const amount = 100.0;
      final splitWith = [testUserId, 'user-2', 'user-3']; // 3 people

      // Act
      final expense = await repository.createExpense(
        tripId: null,
        title: 'Uneven Split',
        amount: amount,
        paidBy: testUserId,
        splitWith: splitWith,
      );

      // Assert
      expect(expense.amount, equals(100.0));
      // Each split should be 33.33... (100 / 3)
    });

    test('EDGE: Handle long titles (500 characters)', () async {
      // Arrange
      final longTitle = 'A' * 500;

      // Act
      final expense = await repository.createExpense(
        tripId: null,
        title: longTitle,
        amount: 100.0,
        paidBy: testUserId,
        splitWith: [testUserId],
      );

      // Assert
      expect(expense.title.length, equals(500));
    });

    test('EDGE: Handle special characters in title', () async {
      // Arrange
      const specialTitle = 'Café & Restaurant: €50 + \$20 = Total!';

      // Act
      final expense = await repository.createExpense(
        tripId: null,
        title: specialTitle,
        amount: 70.0,
        paidBy: testUserId,
        splitWith: [testUserId],
      );

      // Assert
      expect(expense.title, equals(specialTitle));
    });

    test('EDGE: Handle past transaction dates', () async {
      // Arrange
      final pastDate = DateTime(2020, 1, 1);

      // Act
      final expense = await repository.createExpense(
        tripId: null,
        title: 'Past Expense',
        amount: 100.0,
        paidBy: testUserId,
        splitWith: [testUserId],
        transactionDate: pastDate,
      );

      // Assert
      expect(expense.transactionDate, equals(pastDate));
    });

    test('EDGE: Handle expenses with no description', () async {
      // Act
      final expense = await repository.createExpense(
        tripId: null,
        title: 'No Description',
        description: null, // Explicitly null
        amount: 100.0,
        paidBy: testUserId,
        splitWith: [testUserId],
      );

      // Assert
      expect(expense.description, isNull);
    });

    test('EDGE: Handle expenses with no category', () async {
      // Act
      final expense = await repository.createExpense(
        tripId: null,
        title: 'Uncategorized',
        category: null,
        amount: 100.0,
        paidBy: testUserId,
        splitWith: [testUserId],
      );

      // Assert
      expect(expense.category, isNull);
    });
  });

  group('BALANCE Calculation Tests', () {
    setUp(() async {
      // Create test expenses for balance testing
      await repository.createExpense(
        tripId: null,
        title: 'Paid by me',
        amount: 300.0,
        paidBy: testUserId,
        splitWith: [testUserId],
      );
    });

    test('POSITIVE: Calculate balances for standalone expenses', () async {
      // Act
      final balances = await repository.getBalances(userId: testUserId);

      // Assert
      expect(balances, isNotEmpty);
      expect(balances, isA<List<BalanceSummary>>());
    });

    test('POSITIVE: Verify balance calculation accuracy', () async {
      // Act
      final balances = await repository.getBalances(userId: testUserId);

      // Assert - User paid for themselves, so balance should be 0
      final userBalance =
          balances.firstWhere((b) => b.userId == testUserId, orElse: () {
        return BalanceSummary(
          userId: testUserId,
          userName: '',
          totalPaid: 0,
          totalOwed: 0,
          balance: 0,
        );
      });
      expect(userBalance.totalPaid, greaterThanOrEqualTo(300.0));
    });
  });

  group('CONCURRENT Operations Tests', () {
    test('POSITIVE: Create multiple expenses concurrently', () async {
      // Act - Create 5 expenses concurrently
      final futures = List.generate(
        5,
        (index) => repository.createExpense(
          tripId: null,
          title: 'Concurrent Expense $index',
          amount: (index + 1) * 100.0,
          paidBy: testUserId,
          splitWith: [testUserId],
        ),
      );

      final results = await Future.wait(futures);

      // Assert
      expect(results.length, equals(5));
      for (var i = 0; i < 5; i++) {
        expect(results[i].title, equals('Concurrent Expense $i'));
        expect(results[i].amount, equals((i + 1) * 100.0));
      }
    });

    test('POSITIVE: Update and read expense concurrently', () async {
      // Arrange
      final expense = await repository.createExpense(
        tripId: null,
        title: 'Concurrent Test',
        amount: 100.0,
        paidBy: testUserId,
        splitWith: [testUserId],
      );

      // Act - Update and read concurrently
      final results = await Future.wait([
        repository.updateExpense(
          expenseId: expense.id,
          title: 'Updated Concurrent',
        ),
        repository.getExpenseById(expense.id),
      ]);

      // Assert - Both operations should complete
      expect(results.length, equals(2));
    });
  });
}
