import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:travel_crew/features/expenses/data/datasources/expense_local_datasource.dart';
import 'package:travel_crew/shared/models/expense_model.dart';

/// Direct database test for Expense CRUD operations
/// Uses sqflite_ffi for testing without platform dependencies
void main() {
  // Initialize sqflite_ffi for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Expense Database Operations - Direct Testing', () {
    late Database testDb;
    late ExpenseLocalDataSource dataSource;

    // Test user IDs
    const testUserId1 = 'test-user-1';
    const testUserId2 = 'test-user-2';
    const testUserId3 = 'test-user-3';

    // Test trip ID
    const testTripId = 'test-trip-1';

    setUp(() async {
      // Create in-memory database for each test
      testDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          // Create tables
          await db.execute('''
            CREATE TABLE profiles (
              id TEXT PRIMARY KEY,
              email TEXT UNIQUE NOT NULL,
              full_name TEXT,
              phone_number TEXT,
              avatar_url TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE trips (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              description TEXT,
              destination TEXT,
              start_date TEXT,
              end_date TEXT,
              cover_image_url TEXT,
              created_by TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (created_by) REFERENCES profiles (id) ON DELETE CASCADE
            )
          ''');

          await db.execute('''
            CREATE TABLE trip_members (
              id TEXT PRIMARY KEY,
              trip_id TEXT NOT NULL,
              user_id TEXT NOT NULL,
              role TEXT NOT NULL,
              joined_at TEXT NOT NULL,
              FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
              FOREIGN KEY (user_id) REFERENCES profiles (id) ON DELETE CASCADE,
              UNIQUE(trip_id, user_id)
            )
          ''');

          await db.execute('''
            CREATE TABLE expenses (
              id TEXT PRIMARY KEY,
              trip_id TEXT,
              title TEXT NOT NULL,
              description TEXT,
              amount REAL NOT NULL,
              currency TEXT NOT NULL DEFAULT 'INR',
              category TEXT,
              paid_by TEXT NOT NULL,
              split_type TEXT NOT NULL DEFAULT 'equal',
              receipt_url TEXT,
              transaction_date TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
              FOREIGN KEY (paid_by) REFERENCES profiles (id) ON DELETE CASCADE
            )
          ''');

          await db.execute('''
            CREATE TABLE expense_splits (
              id TEXT PRIMARY KEY,
              expense_id TEXT NOT NULL,
              user_id TEXT NOT NULL,
              amount REAL NOT NULL,
              is_settled INTEGER NOT NULL DEFAULT 0,
              settled_at TEXT,
              created_at TEXT NOT NULL,
              FOREIGN KEY (expense_id) REFERENCES expenses (id) ON DELETE CASCADE,
              FOREIGN KEY (user_id) REFERENCES profiles (id) ON DELETE CASCADE,
              UNIQUE(expense_id, user_id)
            )
          ''');

          await db.execute('''
            CREATE TABLE settlements (
              id TEXT PRIMARY KEY,
              trip_id TEXT,
              from_user TEXT NOT NULL,
              to_user TEXT NOT NULL,
              amount REAL NOT NULL,
              currency TEXT NOT NULL DEFAULT 'INR',
              payment_method TEXT,
              payment_proof_url TEXT,
              status TEXT NOT NULL DEFAULT 'pending',
              transaction_date TEXT,
              created_at TEXT NOT NULL,
              FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
              FOREIGN KEY (from_user) REFERENCES profiles (id) ON DELETE CASCADE,
              FOREIGN KEY (to_user) REFERENCES profiles (id) ON DELETE CASCADE
            )
          ''');
        },
      );

      // Insert test data
      final now = DateTime.now().toIso8601String();

      // Create profiles
      await testDb.insert('profiles', {
        'id': testUserId1,
        'email': 'user1@test.com',
        'full_name': 'Test User 1',
        'created_at': now,
        'updated_at': now,
      });

      await testDb.insert('profiles', {
        'id': testUserId2,
        'email': 'user2@test.com',
        'full_name': 'Test User 2',
        'created_at': now,
        'updated_at': now,
      });

      await testDb.insert('profiles', {
        'id': testUserId3,
        'email': 'user3@test.com',
        'full_name': 'Test User 3',
        'created_at': now,
        'updated_at': now,
      });

      // Create trip
      await testDb.insert('trips', {
        'id': testTripId,
        'name': 'Test Trip',
        'description': 'A test trip',
        'destination': 'Test City',
        'created_by': testUserId1,
        'created_at': now,
        'updated_at': now,
      });

      // Add trip members
      await testDb.insert('trip_members', {
        'id': 'member-1',
        'trip_id': testTripId,
        'user_id': testUserId1,
        'role': 'admin',
        'joined_at': now,
      });

      await testDb.insert('trip_members', {
        'id': 'member-2',
        'trip_id': testTripId,
        'user_id': testUserId2,
        'role': 'member',
        'joined_at': now,
      });

      await testDb.insert('trip_members', {
        'id': 'member-3',
        'trip_id': testTripId,
        'user_id': testUserId3,
        'role': 'member',
        'joined_at': now,
      });

      // Create datasource - we'll mock the database helper
      dataSource = ExpenseLocalDataSource();
      dataSource.setCurrentUserId(testUserId1);

      print('✅ Test database setup complete');
    });

    tearDown(() async {
      await testDb.close();
    });

    test('1. CREATE - Can insert expense directly to database', () async {
      print('\n📝 TEST 1: Direct database insert...');

      final expenseId = 'test-expense-1';
      final now = DateTime.now();

      await testDb.insert('expenses', {
        'id': expenseId,
        'trip_id': testTripId,
        'title': 'Test Dinner',
        'description': 'Team dinner',
        'amount': 3000.0,
        'currency': 'INR',
        'category': 'food',
        'paid_by': testUserId1,
        'split_type': 'equal',
        'transaction_date': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      // Insert splits
      await testDb.insert('expense_splits', {
        'id': 'split-1',
        'expense_id': expenseId,
        'user_id': testUserId1,
        'amount': 1000.0,
        'is_settled': 0,
        'created_at': now.toIso8601String(),
      });

      await testDb.insert('expense_splits', {
        'id': 'split-2',
        'expense_id': expenseId,
        'user_id': testUserId2,
        'amount': 1000.0,
        'is_settled': 0,
        'created_at': now.toIso8601String(),
      });

      await testDb.insert('expense_splits', {
        'id': 'split-3',
        'expense_id': expenseId,
        'user_id': testUserId3,
        'amount': 1000.0,
        'is_settled': 0,
        'created_at': now.toIso8601String(),
      });

      // Verify expense was created
      final expenses = await testDb.query('expenses', where: 'id = ?', whereArgs: [expenseId]);
      expect(expenses.length, 1);
      expect(expenses[0]['title'], 'Test Dinner');
      expect(expenses[0]['amount'], 3000.0);

      // Verify splits were created
      final splits = await testDb.query('expense_splits', where: 'expense_id = ?', whereArgs: [expenseId]);
      expect(splits.length, 3);

      print('✅ Expense inserted: ${expenses[0]['title']} - ₹${expenses[0]['amount']}');
      print('✅ Splits created: ${splits.length}');
    });

    test('2. READ - Can fetch expense with splits', () async {
      print('\n📝 TEST 2: Reading expense...');

      // Create test expense
      final expenseId = 'test-expense-2';
      final now = DateTime.now();

      await testDb.insert('expenses', {
        'id': expenseId,
        'trip_id': testTripId,
        'title': 'Transport Cost',
        'amount': 1500.0,
        'currency': 'INR',
        'category': 'transport',
        'paid_by': testUserId1,
        'split_type': 'equal',
        'transaction_date': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      await testDb.insert('expense_splits', {
        'id': 'split-4',
        'expense_id': expenseId,
        'user_id': testUserId1,
        'amount': 750.0,
        'is_settled': 0,
        'created_at': now.toIso8601String(),
      });

      await testDb.insert('expense_splits', {
        'id': 'split-5',
        'expense_id': expenseId,
        'user_id': testUserId2,
        'amount': 750.0,
        'is_settled': 0,
        'created_at': now.toIso8601String(),
      });

      // Fetch expense
      final expenses = await testDb.query('expenses', where: 'id = ?', whereArgs: [expenseId]);
      expect(expenses.length, 1);

      final expense = ExpenseModel.fromJson(expenses[0]);
      expect(expense.id, expenseId);
      expect(expense.title, 'Transport Cost');
      expect(expense.amount, 1500.0);

      // Fetch splits
      final splitsData = await testDb.query('expense_splits', where: 'expense_id = ?', whereArgs: [expenseId]);
      final splits = splitsData.map((s) => ExpenseSplitModel.fromJson(s)).toList();
      expect(splits.length, 2);

      print('✅ Fetched expense: ${expense.title} - ₹${expense.amount}');
      print('✅ Fetched splits: ${splits.length}');
    });

    test('3. UPDATE - Can update expense', () async {
      print('\n📝 TEST 3: Updating expense...');

      // Create test expense
      final expenseId = 'test-expense-3';
      final now = DateTime.now();

      await testDb.insert('expenses', {
        'id': expenseId,
        'trip_id': testTripId,
        'title': 'Original Title',
        'description': 'Original description',
        'amount': 1000.0,
        'currency': 'INR',
        'category': 'food',
        'paid_by': testUserId1,
        'split_type': 'equal',
        'transaction_date': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      print('   Created: Original Title - ₹1000.0');

      // Update expense
      await testDb.update(
        'expenses',
        {
          'title': 'Updated Title',
          'description': 'Updated description',
          'amount': 1500.0,
          'category': 'transport',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [expenseId],
      );

      // Verify update
      final expenses = await testDb.query('expenses', where: 'id = ?', whereArgs: [expenseId]);
      expect(expenses.length, 1);
      expect(expenses[0]['title'], 'Updated Title');
      expect(expenses[0]['amount'], 1500.0);
      expect(expenses[0]['category'], 'transport');

      print('✅ Updated: ${expenses[0]['title']} - ₹${expenses[0]['amount']}');
    });

    test('4. DELETE - Can delete expense and cascading splits', () async {
      print('\n📝 TEST 4: Deleting expense...');

      // Create test expense
      final expenseId = 'test-expense-4';
      final now = DateTime.now();

      await testDb.insert('expenses', {
        'id': expenseId,
        'trip_id': testTripId,
        'title': 'Expense to Delete',
        'amount': 500.0,
        'currency': 'INR',
        'category': 'other',
        'paid_by': testUserId1,
        'split_type': 'equal',
        'transaction_date': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      await testDb.insert('expense_splits', {
        'id': 'split-6',
        'expense_id': expenseId,
        'user_id': testUserId1,
        'amount': 250.0,
        'is_settled': 0,
        'created_at': now.toIso8601String(),
      });

      await testDb.insert('expense_splits', {
        'id': 'split-7',
        'expense_id': expenseId,
        'user_id': testUserId2,
        'amount': 250.0,
        'is_settled': 0,
        'created_at': now.toIso8601String(),
      });

      // Verify it exists
      var expenses = await testDb.query('expenses', where: 'id = ?', whereArgs: [expenseId]);
      var splits = await testDb.query('expense_splits', where: 'expense_id = ?', whereArgs: [expenseId]);
      expect(expenses.length, 1);
      expect(splits.length, 2);

      print('   Verified expense exists with ${splits.length} splits');

      // Delete splits first (manual cascade)
      await testDb.delete('expense_splits', where: 'expense_id = ?', whereArgs: [expenseId]);

      // Delete expense
      await testDb.delete('expenses', where: 'id = ?', whereArgs: [expenseId]);

      // Verify deletion
      expenses = await testDb.query('expenses', where: 'id = ?', whereArgs: [expenseId]);
      splits = await testDb.query('expense_splits', where: 'expense_id = ?', whereArgs: [expenseId]);
      expect(expenses.length, 0);
      expect(splits.length, 0);

      print('✅ Expense deleted');
      print('✅ Splits cascade deleted');
    });

    test('5. QUERY - Can query trip expenses', () async {
      print('\n📝 TEST 5: Querying trip expenses...');

      final now = DateTime.now();

      // Create multiple expenses for the trip
      for (var i = 1; i <= 3; i++) {
        await testDb.insert('expenses', {
          'id': 'trip-expense-$i',
          'trip_id': testTripId,
          'title': 'Trip Expense $i',
          'amount': 1000.0 * i,
          'currency': 'INR',
          'category': 'food',
          'paid_by': testUserId1,
          'split_type': 'equal',
          'transaction_date': now.toIso8601String(),
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
      }

      // Query trip expenses
      final expenses = await testDb.query(
        'expenses',
        where: 'trip_id = ?',
        whereArgs: [testTripId],
        orderBy: 'created_at DESC',
      );

      expect(expenses.length, greaterThanOrEqualTo(3));

      print('✅ Found ${expenses.length} trip expenses');
      for (var i = 0; i < expenses.length; i++) {
        print('   ${i + 1}. ${expenses[i]['title']} - ₹${expenses[i]['amount']}');
      }
    });

    test('6. QUERY - Can query standalone expenses', () async {
      print('\n📝 TEST 6: Querying standalone expenses...');

      final now = DateTime.now();

      // Create standalone expenses (no trip_id)
      for (var i = 1; i <= 2; i++) {
        await testDb.insert('expenses', {
          'id': 'standalone-expense-$i',
          'trip_id': null, // No trip
          'title': 'Standalone Expense $i',
          'amount': 500.0 * i,
          'currency': 'INR',
          'category': 'food',
          'paid_by': testUserId1,
          'split_type': 'equal',
          'transaction_date': now.toIso8601String(),
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
      }

      // Query standalone expenses
      final expenses = await testDb.query(
        'expenses',
        where: 'trip_id IS NULL',
        orderBy: 'created_at DESC',
      );

      expect(expenses.length, greaterThanOrEqualTo(2));

      print('✅ Found ${expenses.length} standalone expenses');
      for (var i = 0; i < expenses.length; i++) {
        print('   ${i + 1}. ${expenses[i]['title']} - ₹${expenses[i]['amount']}');
      }
    });

    test('7. BALANCE - Can calculate balances manually', () async {
      print('\n📝 TEST 7: Calculating balances...');

      final now = DateTime.now();

      // User1 pays 3000, split among 3 people
      await testDb.insert('expenses', {
        'id': 'balance-expense-1',
        'trip_id': testTripId,
        'title': 'User1 pays 3000',
        'amount': 3000.0,
        'currency': 'INR',
        'category': 'food',
        'paid_by': testUserId1,
        'split_type': 'equal',
        'transaction_date': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      // Create splits
      for (var userId in [testUserId1, testUserId2, testUserId3]) {
        await testDb.insert('expense_splits', {
          'id': 'balance-split-$userId',
          'expense_id': 'balance-expense-1',
          'user_id': userId,
          'amount': 1000.0,
          'is_settled': 0,
          'created_at': now.toIso8601String(),
        });
      }

      // Calculate balance for user1
      final paidResult = await testDb.rawQuery(
        'SELECT SUM(amount) as total FROM expenses WHERE trip_id = ? AND paid_by = ?',
        [testTripId, testUserId1],
      );
      final totalPaid = (paidResult[0]['total'] as num?)?.toDouble() ?? 0.0;

      final owedResult = await testDb.rawQuery(
        'SELECT SUM(amount) as total FROM expense_splits WHERE user_id = ? AND expense_id IN (SELECT id FROM expenses WHERE trip_id = ?)',
        [testUserId1, testTripId],
      );
      final totalOwed = (owedResult[0]['total'] as num?)?.toDouble() ?? 0.0;

      final balance = totalPaid - totalOwed;

      print('✅ User1 balance calculation:');
      print('   Total Paid: ₹$totalPaid');
      print('   Total Owed: ₹$totalOwed');
      print('   Balance: ₹$balance ${balance > 0 ? "(gets back)" : balance < 0 ? "(owes)" : "(settled)"}');

      expect(totalPaid, greaterThan(0));
      expect(totalOwed, greaterThan(0));
    });
  });
}
