import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/database/database_helper.dart';
import 'package:travel_crew/features/expenses/data/datasources/expense_local_datasource.dart';
import 'package:travel_crew/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:travel_crew/shared/models/expense_model.dart';

/// End-to-End test for Expense CRUD operations
/// Tests against actual SQLite database (no mocking)
void main() {
  late DatabaseHelper dbHelper;
  late ExpenseLocalDataSource dataSource;
  late ExpenseRepositoryImpl repository;

  // Test user IDs
  const testUserId1 = 'test-user-1';
  const testUserId2 = 'test-user-2';
  const testUserId3 = 'test-user-3';

  // Test trip ID
  const testTripId = 'test-trip-1';

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Initialize database
    dbHelper = DatabaseHelper.instance;
    await dbHelper.database; // Ensure database is created

    // Initialize datasource and repository
    dataSource = ExpenseLocalDataSource();
    dataSource.setCurrentUserId(testUserId1);
    repository = ExpenseRepositoryImpl(dataSource);

    // Setup test data - create test users
    final db = await dbHelper.database;

    // Clear existing test data
    await db.delete('expense_splits');
    await db.delete('expenses');
    await db.delete('trip_members');
    await db.delete('trips');
    await db.delete('profiles');

    // Create test profiles
    final now = DateTime.now().toIso8601String();
    await db.insert('profiles', {
      'id': testUserId1,
      'email': 'user1@test.com',
      'full_name': 'Test User 1',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('profiles', {
      'id': testUserId2,
      'email': 'user2@test.com',
      'full_name': 'Test User 2',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('profiles', {
      'id': testUserId3,
      'email': 'user3@test.com',
      'full_name': 'Test User 3',
      'created_at': now,
      'updated_at': now,
    });

    // Create test trip
    await db.insert('trips', {
      'id': testTripId,
      'name': 'Test Trip',
      'description': 'A test trip for expense testing',
      'destination': 'Test Destination',
      'created_by': testUserId1,
      'created_at': now,
      'updated_at': now,
    });

    // Add trip members
    await db.insert('trip_members', {
      'id': 'member-1',
      'trip_id': testTripId,
      'user_id': testUserId1,
      'role': 'admin',
      'joined_at': now,
    });

    await db.insert('trip_members', {
      'id': 'member-2',
      'trip_id': testTripId,
      'user_id': testUserId2,
      'role': 'member',
      'joined_at': now,
    });

    await db.insert('trip_members', {
      'id': 'member-3',
      'trip_id': testTripId,
      'user_id': testUserId3,
      'role': 'member',
      'joined_at': now,
    });

    print('✅ Test setup complete - Database initialized with test users and trip');
  });

  tearDownAll(() async {
    // Clean up test data
    final db = await dbHelper.database;
    await db.delete('expense_splits');
    await db.delete('expenses');
    await db.delete('trip_members');
    await db.delete('trips');
    await db.delete('profiles');

    print('✅ Test cleanup complete');
  });

  group('Expense CRUD Operations E2E Tests', () {

    test('1. CREATE - Should create trip expense with splits', () async {
      print('\n📝 TEST 1: Creating trip expense...');

      // Create expense
      final expense = await repository.createExpense(
        tripId: testTripId,
        title: 'Dinner at Restaurant',
        description: 'Team dinner',
        amount: 3000.0,
        category: 'food',
        paidBy: testUserId1,
        splitWith: [testUserId1, testUserId2, testUserId3],
        transactionDate: DateTime.now(),
      );

      // Verify expense created
      expect(expense.id, isNotEmpty);
      expect(expense.tripId, testTripId);
      expect(expense.title, 'Dinner at Restaurant');
      expect(expense.amount, 3000.0);
      expect(expense.paidBy, testUserId1);

      print('✅ Expense created: ${expense.id}');
      print('   Title: ${expense.title}');
      print('   Amount: ₹${expense.amount}');
      print('   Paid by: ${expense.paidBy}');

      // Verify splits were created
      final expenseWithSplits = await repository.getExpenseById(expense.id);
      expect(expenseWithSplits.splits.length, 3);
      expect(expenseWithSplits.splits[0].amount, 1000.0); // 3000/3

      print('✅ Splits created: ${expenseWithSplits.splits.length}');
      print('   Split amount each: ₹${expenseWithSplits.splits[0].amount}');
    });

    test('2. CREATE - Should create standalone expense (no trip)', () async {
      print('\n📝 TEST 2: Creating standalone expense...');

      // Create standalone expense
      final expense = await repository.createExpense(
        tripId: null, // No trip
        title: 'Coffee with Friends',
        description: 'Casual meetup',
        amount: 600.0,
        category: 'food',
        paidBy: testUserId1,
        splitWith: [testUserId1, testUserId2],
        transactionDate: DateTime.now(),
      );

      // Verify expense created
      expect(expense.id, isNotEmpty);
      expect(expense.tripId, isNull);
      expect(expense.title, 'Coffee with Friends');
      expect(expense.amount, 600.0);

      print('✅ Standalone expense created: ${expense.id}');
      print('   Title: ${expense.title}');
      print('   Amount: ₹${expense.amount}');
      print('   Trip ID: ${expense.tripId ?? "None (standalone)"}');

      // Verify splits
      final expenseWithSplits = await repository.getExpenseById(expense.id);
      expect(expenseWithSplits.splits.length, 2);
      expect(expenseWithSplits.splits[0].amount, 300.0); // 600/2

      print('✅ Splits: ${expenseWithSplits.splits.length} people, ₹${expenseWithSplits.splits[0].amount} each');
    });

    test('3. READ - Should fetch all user expenses', () async {
      print('\n📝 TEST 3: Fetching all user expenses...');

      final expenses = await repository.getUserExpenses();

      // Should have at least the 2 expenses we created
      expect(expenses.length, greaterThanOrEqualTo(2));

      print('✅ Found ${expenses.length} expenses for user');
      for (var i = 0; i < expenses.length; i++) {
        final exp = expenses[i];
        print('   ${i + 1}. ${exp.expense.title} - ₹${exp.expense.amount} (${exp.expense.tripId != null ? "Trip" : "Standalone"})');
      }
    });

    test('4. READ - Should fetch trip expenses only', () async {
      print('\n📝 TEST 4: Fetching trip expenses...');

      final expenses = await repository.getTripExpenses(testTripId);

      // Should have only trip expenses
      expect(expenses.length, greaterThanOrEqualTo(1));

      // All should have tripId
      for (var expenseWithSplits in expenses) {
        expect(expenseWithSplits.expense.tripId, testTripId);
      }

      print('✅ Found ${expenses.length} trip expenses');
      for (var i = 0; i < expenses.length; i++) {
        final exp = expenses[i];
        print('   ${i + 1}. ${exp.expense.title} - ₹${exp.expense.amount}');
      }
    });

    test('5. READ - Should fetch standalone expenses only', () async {
      print('\n📝 TEST 5: Fetching standalone expenses...');

      final expenses = await repository.getStandaloneExpenses();

      // Should have only standalone expenses
      expect(expenses.length, greaterThanOrEqualTo(1));

      // All should have null tripId
      for (var expenseWithSplits in expenses) {
        expect(expenseWithSplits.expense.tripId, isNull);
      }

      print('✅ Found ${expenses.length} standalone expenses');
      for (var i = 0; i < expenses.length; i++) {
        final exp = expenses[i];
        print('   ${i + 1}. ${exp.expense.title} - ₹${exp.expense.amount}');
      }
    });

    test('6. READ - Should get expense by ID with splits', () async {
      print('\n📝 TEST 6: Fetching expense by ID...');

      // Create a test expense
      final createdExpense = await repository.createExpense(
        tripId: testTripId,
        title: 'Test Expense for ID fetch',
        amount: 1500.0,
        category: 'transport',
        paidBy: testUserId1,
        splitWith: [testUserId1, testUserId2],
      );

      // Fetch by ID
      final expenseWithSplits = await repository.getExpenseById(createdExpense.id);

      // Verify
      expect(expenseWithSplits.expense.id, createdExpense.id);
      expect(expenseWithSplits.expense.title, 'Test Expense for ID fetch');
      expect(expenseWithSplits.expense.amount, 1500.0);
      expect(expenseWithSplits.splits.length, 2);

      print('✅ Fetched expense by ID: ${expenseWithSplits.expense.id}');
      print('   Title: ${expenseWithSplits.expense.title}');
      print('   Splits: ${expenseWithSplits.splits.length}');
    });

    test('7. UPDATE - Should update expense details', () async {
      print('\n📝 TEST 7: Updating expense...');

      // Create an expense first
      final createdExpense = await repository.createExpense(
        tripId: testTripId,
        title: 'Original Title',
        description: 'Original description',
        amount: 1000.0,
        category: 'food',
        paidBy: testUserId1,
        splitWith: [testUserId1, testUserId2],
      );

      print('   Created expense: ${createdExpense.title} - ₹${createdExpense.amount}');

      // Update the expense
      final updatedExpense = await repository.updateExpense(
        expenseId: createdExpense.id,
        title: 'Updated Title',
        description: 'Updated description',
        amount: 1500.0,
        category: 'transport',
      );

      // Verify updates
      expect(updatedExpense.id, createdExpense.id);
      expect(updatedExpense.title, 'Updated Title');
      expect(updatedExpense.description, 'Updated description');
      expect(updatedExpense.amount, 1500.0);
      expect(updatedExpense.category, 'transport');

      print('✅ Expense updated successfully');
      print('   New title: ${updatedExpense.title}');
      print('   New amount: ₹${updatedExpense.amount}');
      print('   New category: ${updatedExpense.category}');

      // Verify in database
      final fetchedExpense = await repository.getExpenseById(createdExpense.id);
      expect(fetchedExpense.expense.title, 'Updated Title');
      expect(fetchedExpense.expense.amount, 1500.0);

      print('✅ Verified updates in database');
    });

    test('8. DELETE - Should delete expense and its splits', () async {
      print('\n📝 TEST 8: Deleting expense...');

      // Create an expense to delete
      final expenseToDelete = await repository.createExpense(
        tripId: testTripId,
        title: 'Expense to Delete',
        amount: 500.0,
        category: 'other',
        paidBy: testUserId1,
        splitWith: [testUserId1, testUserId2],
      );

      print('   Created expense to delete: ${expenseToDelete.id}');

      // Verify it exists
      final beforeDelete = await repository.getExpenseById(expenseToDelete.id);
      expect(beforeDelete.expense.id, expenseToDelete.id);
      expect(beforeDelete.splits.length, 2);

      print('   Confirmed expense exists with ${beforeDelete.splits.length} splits');

      // Delete the expense
      await repository.deleteExpense(expenseToDelete.id);

      print('✅ Expense deleted');

      // Verify it's gone
      try {
        await repository.getExpenseById(expenseToDelete.id);
        fail('Expected expense to be deleted');
      } catch (e) {
        expect(e.toString(), contains('not found'));
        print('✅ Confirmed expense no longer exists');
      }

      // Verify splits are also gone (cascade delete)
      final db = await dbHelper.database;
      final splits = await db.query(
        'expense_splits',
        where: 'expense_id = ?',
        whereArgs: [expenseToDelete.id],
      );
      expect(splits, isEmpty);

      print('✅ Confirmed splits were cascade deleted');
    });

    test('9. BALANCE - Should calculate balances correctly', () async {
      print('\n📝 TEST 9: Calculating balances...');

      // Create expenses for balance calculation
      // User1 pays 3000, split among 3 people = 1000 each
      await repository.createExpense(
        tripId: testTripId,
        title: 'User1 pays 3000',
        amount: 3000.0,
        category: 'food',
        paidBy: testUserId1,
        splitWith: [testUserId1, testUserId2, testUserId3],
      );

      // User2 pays 1500, split among 3 people = 500 each
      await repository.createExpense(
        tripId: testTripId,
        title: 'User2 pays 1500',
        amount: 1500.0,
        category: 'transport',
        paidBy: testUserId2,
        splitWith: [testUserId1, testUserId2, testUserId3],
      );

      // Calculate balances
      final balances = await repository.getBalances(tripId: testTripId);

      expect(balances.length, 3);

      print('✅ Balance calculation complete:');
      for (var balance in balances) {
        print('   User ${balance.userId}:');
        print('     - Total Paid: ₹${balance.totalPaid}');
        print('     - Total Owed: ₹${balance.totalOwed}');
        print('     - Balance: ₹${balance.balance} ${balance.balance > 0 ? "(gets back)" : balance.balance < 0 ? "(owes)" : "(settled)"}');
      }

      // User1: paid 3000, owes 1000 + 500 = 1500, balance = +1500
      final user1Balance = balances.firstWhere((b) => b.userId == testUserId1);
      expect(user1Balance.balance, greaterThan(0)); // Should get money back

      // User2: paid 1500, owes 1000 + 500 = 1500, balance = 0
      final user2Balance = balances.firstWhere((b) => b.userId == testUserId2);
      expect(user2Balance.balance, closeTo(0, 1)); // Should be close to settled

      // User3: paid 0, owes 1000 + 500 = 1500, balance = -1500
      final user3Balance = balances.firstWhere((b) => b.userId == testUserId3);
      expect(user3Balance.balance, lessThan(0)); // Should owe money
    });

    test('10. SETTLEMENT - Should create and track settlements', () async {
      print('\n📝 TEST 10: Creating settlement...');

      // Create settlement
      final settlement = await repository.createSettlement(
        tripId: testTripId,
        fromUser: testUserId3,
        toUser: testUserId1,
        amount: 1000.0,
        paymentMethod: 'UPI',
      );

      // Verify settlement
      expect(settlement.id, isNotEmpty);
      expect(settlement.tripId, testTripId);
      expect(settlement.fromUser, testUserId3);
      expect(settlement.toUser, testUserId1);
      expect(settlement.amount, 1000.0);
      expect(settlement.status, 'pending');

      print('✅ Settlement created: ${settlement.id}');
      print('   From: ${settlement.fromUser}');
      print('   To: ${settlement.toUser}');
      print('   Amount: ₹${settlement.amount}');
      print('   Status: ${settlement.status}');

      // Update settlement status
      final updatedSettlement = await repository.updateSettlementStatus(
        settlementId: settlement.id,
        status: 'completed',
      );

      expect(updatedSettlement.status, 'completed');
      print('✅ Settlement status updated to: ${updatedSettlement.status}');

      // Fetch settlements
      final settlements = await repository.getSettlements(tripId: testTripId);
      expect(settlements.length, greaterThanOrEqualTo(1));

      print('✅ Found ${settlements.length} settlements for trip');
    });
  });

  group('Edge Cases and Error Handling', () {

    test('11. Should handle non-existent expense ID', () async {
      print('\n📝 TEST 11: Testing non-existent expense...');

      try {
        await repository.getExpenseById('non-existent-id');
        fail('Should throw exception');
      } catch (e) {
        expect(e.toString(), contains('not found'));
        print('✅ Correctly threw exception for non-existent expense');
      }
    });

    test('12. Should handle empty split list', () async {
      print('\n📝 TEST 12: Testing empty split list...');

      try {
        await repository.createExpense(
          tripId: testTripId,
          title: 'Invalid Expense',
          amount: 100.0,
          category: 'test',
          paidBy: testUserId1,
          splitWith: [], // Empty list
        );
        fail('Should handle empty split list');
      } catch (e) {
        print('✅ Handled empty split list (${e.toString().substring(0, 50)}...)');
      }
    });

    test('13. Should handle zero amount', () async {
      print('\n📝 TEST 13: Testing zero amount...');

      final expense = await repository.createExpense(
        tripId: testTripId,
        title: 'Free Event',
        amount: 0.0,
        category: 'activity',
        paidBy: testUserId1,
        splitWith: [testUserId1],
      );

      expect(expense.amount, 0.0);
      print('✅ Handled zero amount expense');
    });
  });

  group('Data Integrity Tests', () {

    test('14. Should maintain data consistency across operations', () async {
      print('\n📝 TEST 14: Testing data consistency...');

      // Get initial count
      final initialExpenses = await repository.getUserExpenses();
      final initialCount = initialExpenses.length;

      print('   Initial expense count: $initialCount');

      // Create new expense
      final newExpense = await repository.createExpense(
        tripId: testTripId,
        title: 'Consistency Test',
        amount: 100.0,
        category: 'test',
        paidBy: testUserId1,
        splitWith: [testUserId1],
      );

      // Verify count increased
      final afterCreate = await repository.getUserExpenses();
      expect(afterCreate.length, initialCount + 1);
      print('✅ Count increased after create: ${afterCreate.length}');

      // Delete expense
      await repository.deleteExpense(newExpense.id);

      // Verify count decreased
      final afterDelete = await repository.getUserExpenses();
      expect(afterDelete.length, initialCount);
      print('✅ Count restored after delete: ${afterDelete.length}');
    });

    test('15. Should handle concurrent operations', () async {
      print('\n📝 TEST 15: Testing concurrent operations...');

      // Create multiple expenses concurrently
      final futures = <Future<ExpenseModel>>[];
      for (var i = 0; i < 5; i++) {
        futures.add(
          repository.createExpense(
            tripId: testTripId,
            title: 'Concurrent Expense $i',
            amount: 100.0 * (i + 1),
            category: 'test',
            paidBy: testUserId1,
            splitWith: [testUserId1, testUserId2],
          ),
        );
      }

      final expenses = await Future.wait(futures);

      expect(expenses.length, 5);
      print('✅ Created 5 expenses concurrently');

      // Verify all have unique IDs
      final ids = expenses.map((e) => e.id).toSet();
      expect(ids.length, 5);
      print('✅ All expenses have unique IDs');

      // Clean up
      for (var expense in expenses) {
        await repository.deleteExpense(expense.id);
      }
      print('✅ Cleaned up concurrent test expenses');
    });
  });
}
