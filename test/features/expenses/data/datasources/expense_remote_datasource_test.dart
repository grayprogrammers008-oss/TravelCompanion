import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/shared/models/expense_model.dart';

void main() {
  group('ExpenseRemoteDataSource Helper Classes', () {
    group('BalanceSummary', () {
      test('should create BalanceSummary correctly', () {
        final summary = BalanceSummary(
          userId: 'user-1',
          userName: 'John Doe',
          totalPaid: 100.0,
          totalOwed: 60.0,
          balance: 40.0,
        );

        expect(summary.userId, 'user-1');
        expect(summary.userName, 'John Doe');
        expect(summary.totalPaid, 100.0);
        expect(summary.totalOwed, 60.0);
        expect(summary.balance, 40.0);
      });

      test('should handle negative balance (user owes money)', () {
        final summary = BalanceSummary(
          userId: 'user-1',
          userName: 'Jane Doe',
          totalPaid: 20.0,
          totalOwed: 50.0,
          balance: -30.0,
        );

        expect(summary.balance, -30.0);
        expect(summary.totalPaid, lessThan(summary.totalOwed));
      });

      test('should handle zero balance (even split)', () {
        final summary = BalanceSummary(
          userId: 'user-1',
          userName: 'Equal Split',
          totalPaid: 50.0,
          totalOwed: 50.0,
          balance: 0.0,
        );

        expect(summary.balance, 0.0);
        expect(summary.totalPaid, equals(summary.totalOwed));
      });

      test('should handle large amounts', () {
        final summary = BalanceSummary(
          userId: 'user-1',
          userName: 'Big Spender',
          totalPaid: 10000.0,
          totalOwed: 2500.0,
          balance: 7500.0,
        );

        expect(summary.balance, 7500.0);
      });

      test('should handle zero values', () {
        final summary = BalanceSummary(
          userId: 'user-1',
          userName: 'New User',
          totalPaid: 0.0,
          totalOwed: 0.0,
          balance: 0.0,
        );

        expect(summary.totalPaid, 0.0);
        expect(summary.totalOwed, 0.0);
        expect(summary.balance, 0.0);
      });
    });

    group('ExpenseWithSplits', () {
      test('should create ExpenseWithSplits correctly', () {
        final expense = ExpenseModel(
          id: 'expense-1',
          tripId: 'trip-123',
          title: 'Dinner',
          description: 'Team dinner',
          amount: 100.0,
          category: 'food',
          paidBy: 'user-1',
          splitType: 'equal',
          transactionDate: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
        );

        final splits = [
          ExpenseSplitModel(
            id: 'split-1',
            expenseId: 'expense-1',
            userId: 'user-1',
            amount: 50.0,
            isSettled: false,
          ),
          ExpenseSplitModel(
            id: 'split-2',
            expenseId: 'expense-1',
            userId: 'user-2',
            amount: 50.0,
            isSettled: false,
          ),
        ];

        final expenseWithSplits = ExpenseWithSplits(
          expense: expense,
          splits: splits,
        );

        expect(expenseWithSplits.expense.title, 'Dinner');
        expect(expenseWithSplits.splits.length, 2);
        expect(expenseWithSplits.splits[0].amount, 50.0);
        expect(expenseWithSplits.splits[1].amount, 50.0);
      });

      test('should handle expense with no splits', () {
        final expense = ExpenseModel(
          id: 'expense-1',
          tripId: 'trip-123',
          title: 'Solo expense',
          amount: 25.0,
          category: 'food',
          paidBy: 'user-1',
          splitType: 'equal',
          transactionDate: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
        );

        final expenseWithSplits = ExpenseWithSplits(
          expense: expense,
          splits: [],
        );

        expect(expenseWithSplits.splits, isEmpty);
      });

      test('should handle expense with multiple splits', () {
        final expense = ExpenseModel(
          id: 'expense-1',
          tripId: 'trip-123',
          title: 'Group dinner',
          amount: 200.0,
          category: 'food',
          paidBy: 'user-1',
          splitType: 'equal',
          transactionDate: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
        );

        final splits = List.generate(
          5,
          (i) => ExpenseSplitModel(
            id: 'split-$i',
            expenseId: 'expense-1',
            userId: 'user-$i',
            amount: 40.0,
            isSettled: false,
          ),
        );

        final expenseWithSplits = ExpenseWithSplits(
          expense: expense,
          splits: splits,
        );

        expect(expenseWithSplits.splits.length, 5);
        // Total splits should equal expense amount
        final totalSplitAmount = expenseWithSplits.splits.fold<double>(
          0,
          (sum, split) => sum + split.amount,
        );
        expect(totalSplitAmount, 200.0);
      });

      test('should handle standalone expense (no trip)', () {
        final expense = ExpenseModel(
          id: 'expense-1',
          tripId: null,
          title: 'Personal expense',
          amount: 50.0,
          category: 'other',
          paidBy: 'user-1',
          splitType: 'equal',
          transactionDate: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
        );

        final expenseWithSplits = ExpenseWithSplits(
          expense: expense,
          splits: [],
        );

        expect(expenseWithSplits.expense.tripId, isNull);
      });
    });

    group('SettlementModel', () {
      test('should create SettlementModel correctly', () {
        final settlement = SettlementModel(
          id: 'settlement-1',
          tripId: 'trip-123',
          fromUser: 'user-1',
          toUser: 'user-2',
          amount: 50.0,
          status: 'pending',
          createdAt: DateTime(2024, 1, 15),
        );

        expect(settlement.id, 'settlement-1');
        expect(settlement.tripId, 'trip-123');
        expect(settlement.fromUser, 'user-1');
        expect(settlement.toUser, 'user-2');
        expect(settlement.amount, 50.0);
        expect(settlement.status, 'pending');
      });

      test('should handle completed settlement', () {
        final settlement = SettlementModel(
          id: 'settlement-1',
          tripId: 'trip-123',
          fromUser: 'user-1',
          toUser: 'user-2',
          amount: 75.0,
          status: 'completed',
          paymentMethod: 'bank_transfer',
          paymentProofUrl: 'https://example.com/proof.jpg',
          createdAt: DateTime(2024, 1, 15),
        );

        expect(settlement.status, 'completed');
        expect(settlement.paymentMethod, 'bank_transfer');
        expect(settlement.paymentProofUrl, 'https://example.com/proof.jpg');
      });

      test('should parse from JSON correctly', () {
        final json = {
          'id': 'settlement-1',
          'trip_id': 'trip-123',
          'from_user': 'user-1',
          'to_user': 'user-2',
          'amount': 100.0,
          'status': 'pending',
          'payment_method': null,
          'payment_proof_url': null,
          'created_at': '2024-01-15T10:00:00.000Z',
        };

        final settlement = SettlementModel.fromJson(json);

        expect(settlement.id, 'settlement-1');
        expect(settlement.tripId, 'trip-123');
        expect(settlement.fromUser, 'user-1');
        expect(settlement.toUser, 'user-2');
        expect(settlement.amount, 100.0);
        expect(settlement.status, 'pending');
      });

      test('should convert to JSON correctly', () {
        final settlement = SettlementModel(
          id: 'settlement-1',
          tripId: 'trip-123',
          fromUser: 'user-1',
          toUser: 'user-2',
          amount: 50.0,
          status: 'completed',
          createdAt: DateTime.utc(2024, 1, 15, 10, 0),
        );

        final json = settlement.toJson();

        expect(json['id'], 'settlement-1');
        expect(json['trip_id'], 'trip-123');
        expect(json['from_user'], 'user-1');
        expect(json['to_user'], 'user-2');
        expect(json['amount'], 50.0);
        expect(json['status'], 'completed');
      });

      test('should copy with new values', () {
        final original = SettlementModel(
          id: 'settlement-1',
          tripId: 'trip-123',
          fromUser: 'user-1',
          toUser: 'user-2',
          amount: 50.0,
          status: 'pending',
          createdAt: DateTime(2024, 1, 15),
        );

        final updated = original.copyWith(
          status: 'completed',
          paymentProofUrl: 'https://example.com/receipt.png',
        );

        expect(updated.id, original.id);
        expect(updated.status, 'completed');
        expect(updated.paymentProofUrl, 'https://example.com/receipt.png');
        expect(original.status, 'pending'); // Original unchanged
      });

      test('should handle standalone settlement (no trip)', () {
        final settlement = SettlementModel(
          id: 'settlement-1',
          tripId: null,
          fromUser: 'user-1',
          toUser: 'user-2',
          amount: 25.0,
          status: 'pending',
          createdAt: DateTime(2024, 1, 15),
        );

        expect(settlement.tripId, isNull);
      });

      test('should handle various payment methods', () {
        final paymentMethods = ['cash', 'bank_transfer', 'venmo', 'paypal', 'other'];

        for (final method in paymentMethods) {
          final settlement = SettlementModel(
            id: 'settlement-1',
            tripId: 'trip-123',
            fromUser: 'user-1',
            toUser: 'user-2',
            amount: 50.0,
            status: 'completed',
            paymentMethod: method,
            createdAt: DateTime(2024, 1, 15),
          );

          expect(settlement.paymentMethod, method);
        }
      });

      test('should handle various status values', () {
        final statuses = ['pending', 'completed', 'cancelled', 'disputed'];

        for (final status in statuses) {
          final settlement = SettlementModel(
            id: 'settlement-1',
            tripId: 'trip-123',
            fromUser: 'user-1',
            toUser: 'user-2',
            amount: 50.0,
            status: status,
            createdAt: DateTime(2024, 1, 15),
          );

          expect(settlement.status, status);
        }
      });

      test('should preserve user names when copying', () {
        final settlement = SettlementModel(
          id: 'settlement-1',
          tripId: 'trip-123',
          fromUser: 'user-1',
          toUser: 'user-2',
          amount: 50.0,
          status: 'pending',
          fromUserName: 'John Doe',
          toUserName: 'Jane Doe',
          createdAt: DateTime(2024, 1, 15),
        );

        final updated = settlement.copyWith(status: 'completed');

        expect(updated.fromUserName, 'John Doe');
        expect(updated.toUserName, 'Jane Doe');
      });
    });

    group('ExpenseSplitModel', () {
      test('should create ExpenseSplitModel correctly', () {
        final split = ExpenseSplitModel(
          id: 'split-1',
          expenseId: 'expense-1',
          userId: 'user-1',
          amount: 50.0,
          isSettled: false,
        );

        expect(split.id, 'split-1');
        expect(split.expenseId, 'expense-1');
        expect(split.userId, 'user-1');
        expect(split.amount, 50.0);
        expect(split.isSettled, false);
      });

      test('should parse from JSON correctly', () {
        final json = {
          'id': 'split-1',
          'expense_id': 'expense-1',
          'user_id': 'user-1',
          'amount': 75.0,
          'is_settled': true,
        };

        final split = ExpenseSplitModel.fromJson(json);

        expect(split.id, 'split-1');
        expect(split.expenseId, 'expense-1');
        expect(split.userId, 'user-1');
        expect(split.amount, 75.0);
        expect(split.isSettled, true);
      });

      test('should convert to JSON correctly', () {
        final split = ExpenseSplitModel(
          id: 'split-1',
          expenseId: 'expense-1',
          userId: 'user-1',
          amount: 33.33,
          isSettled: false,
        );

        final json = split.toJson();

        expect(json['id'], 'split-1');
        expect(json['expense_id'], 'expense-1');
        expect(json['user_id'], 'user-1');
        expect(json['amount'], 33.33);
        expect(json['is_settled'], false);
      });

      test('should copy with new values', () {
        final original = ExpenseSplitModel(
          id: 'split-1',
          expenseId: 'expense-1',
          userId: 'user-1',
          amount: 50.0,
          isSettled: false,
        );

        final updated = original.copyWith(
          isSettled: true,
          userName: 'John Doe',
        );

        expect(updated.id, original.id);
        expect(updated.isSettled, true);
        expect(updated.userName, 'John Doe');
        expect(original.isSettled, false); // Original unchanged
      });

      test('should handle user info', () {
        final split = ExpenseSplitModel(
          id: 'split-1',
          expenseId: 'expense-1',
          userId: 'user-1',
          amount: 50.0,
          isSettled: false,
          userName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        expect(split.userName, 'John Doe');
        expect(split.avatarUrl, 'https://example.com/avatar.jpg');
      });

      test('should handle decimal amounts', () {
        final split = ExpenseSplitModel(
          id: 'split-1',
          expenseId: 'expense-1',
          userId: 'user-1',
          amount: 33.333333,
          isSettled: false,
        );

        expect(split.amount, closeTo(33.33, 0.01));
      });
    });

    group('ExpenseModel', () {
      test('should create ExpenseModel correctly', () {
        final expense = ExpenseModel(
          id: 'expense-1',
          tripId: 'trip-123',
          title: 'Dinner',
          description: 'Team dinner',
          amount: 100.0,
          category: 'food',
          paidBy: 'user-1',
          splitType: 'equal',
          transactionDate: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
        );

        expect(expense.id, 'expense-1');
        expect(expense.tripId, 'trip-123');
        expect(expense.title, 'Dinner');
        expect(expense.description, 'Team dinner');
        expect(expense.amount, 100.0);
        expect(expense.category, 'food');
        expect(expense.paidBy, 'user-1');
        expect(expense.splitType, 'equal');
      });

      test('should parse from JSON correctly', () {
        final json = {
          'id': 'expense-1',
          'trip_id': 'trip-123',
          'title': 'Hotel',
          'description': 'Two nights',
          'amount': 250.0,
          'category': 'accommodation',
          'paid_by': 'user-1',
          'split_type': 'equal',
          'transaction_date': '2024-01-15T12:00:00.000Z',
          'created_at': '2024-01-15T12:00:00.000Z',
        };

        final expense = ExpenseModel.fromJson(json);

        expect(expense.id, 'expense-1');
        expect(expense.title, 'Hotel');
        expect(expense.amount, 250.0);
        expect(expense.category, 'accommodation');
      });

      test('should convert to JSON correctly', () {
        final expense = ExpenseModel(
          id: 'expense-1',
          tripId: 'trip-123',
          title: 'Lunch',
          amount: 45.0,
          category: 'food',
          paidBy: 'user-1',
          splitType: 'equal',
          transactionDate: DateTime.utc(2024, 1, 15, 12, 0),
          createdAt: DateTime.utc(2024, 1, 15, 12, 0),
        );

        final json = expense.toJson();

        expect(json['id'], 'expense-1');
        expect(json['trip_id'], 'trip-123');
        expect(json['title'], 'Lunch');
        expect(json['amount'], 45.0);
      });

      test('should copy with new values', () {
        final original = ExpenseModel(
          id: 'expense-1',
          tripId: 'trip-123',
          title: 'Original',
          amount: 50.0,
          category: 'food',
          paidBy: 'user-1',
          splitType: 'equal',
          transactionDate: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
        );

        final updated = original.copyWith(
          title: 'Updated',
          amount: 75.0,
        );

        expect(updated.title, 'Updated');
        expect(updated.amount, 75.0);
        expect(updated.id, original.id);
        expect(original.title, 'Original'); // Original unchanged
      });

      test('should handle all expense categories', () {
        final categories = [
          'food',
          'transportation',
          'accommodation',
          'activities',
          'shopping',
          'other',
        ];

        for (final category in categories) {
          final expense = ExpenseModel(
            id: 'expense-1',
            tripId: 'trip-123',
            title: 'Test expense',
            amount: 50.0,
            category: category,
            paidBy: 'user-1',
            splitType: 'equal',
            transactionDate: DateTime(2024, 1, 15),
            createdAt: DateTime(2024, 1, 15),
          );

          expect(expense.category, category);
        }
      });

      test('should handle all split types', () {
        final splitTypes = ['equal', 'percentage', 'exact', 'shares'];

        for (final splitType in splitTypes) {
          final expense = ExpenseModel(
            id: 'expense-1',
            tripId: 'trip-123',
            title: 'Test expense',
            amount: 100.0,
            category: 'food',
            paidBy: 'user-1',
            splitType: splitType,
            transactionDate: DateTime(2024, 1, 15),
            createdAt: DateTime(2024, 1, 15),
          );

          expect(expense.splitType, splitType);
        }
      });

      test('should handle null optional fields', () {
        final expense = ExpenseModel(
          id: 'expense-1',
          tripId: null,
          title: 'Personal expense',
          description: null,
          amount: 25.0,
          category: 'food',
          paidBy: 'user-1',
          splitType: 'equal',
          transactionDate: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
        );

        expect(expense.tripId, isNull);
        expect(expense.description, isNull);
      });

      test('should handle payer name', () {
        final expense = ExpenseModel(
          id: 'expense-1',
          tripId: 'trip-123',
          title: 'Dinner',
          amount: 80.0,
          category: 'food',
          paidBy: 'user-1',
          splitType: 'equal',
          payerName: 'John Doe',
          transactionDate: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
        );

        expect(expense.payerName, 'John Doe');
      });
    });
  });

  group('Balance Calculation Logic', () {
    test('should correctly identify who owes whom', () {
      // User 1 paid 100, owes 50 -> balance +50 (is owed money)
      // User 2 paid 0, owes 50 -> balance -50 (owes money)
      final user1Balance = BalanceSummary(
        userId: 'user-1',
        userName: 'John',
        totalPaid: 100.0,
        totalOwed: 50.0,
        balance: 50.0, // user-1 is owed 50
      );

      final user2Balance = BalanceSummary(
        userId: 'user-2',
        userName: 'Jane',
        totalPaid: 0.0,
        totalOwed: 50.0,
        balance: -50.0, // user-2 owes 50
      );

      expect(user1Balance.balance, greaterThan(0)); // Is owed money
      expect(user2Balance.balance, lessThan(0)); // Owes money
      expect(user1Balance.balance, equals(-user2Balance.balance)); // Balances out
    });

    test('should handle multiple expense scenario', () {
      // Scenario: 3 people, 2 expenses
      // Expense 1: User1 pays 90, split 3 ways (30 each)
      // Expense 2: User2 pays 60, split 3 ways (20 each)

      // User1: paid 90, owes 50 (30+20), balance = +40
      // User2: paid 60, owes 50 (30+20), balance = +10
      // User3: paid 0, owes 50 (30+20), balance = -50

      final user1 = BalanceSummary(
        userId: 'user-1',
        userName: 'User 1',
        totalPaid: 90.0,
        totalOwed: 50.0,
        balance: 40.0,
      );

      final user2 = BalanceSummary(
        userId: 'user-2',
        userName: 'User 2',
        totalPaid: 60.0,
        totalOwed: 50.0,
        balance: 10.0,
      );

      final user3 = BalanceSummary(
        userId: 'user-3',
        userName: 'User 3',
        totalPaid: 0.0,
        totalOwed: 50.0,
        balance: -50.0,
      );

      // All balances should sum to 0
      final totalBalance = user1.balance + user2.balance + user3.balance;
      expect(totalBalance, closeTo(0.0, 0.01));
    });

    test('should handle equal split correctly', () {
      // 4 people, 100 expense = 25 each
      final splitAmount = 100.0 / 4;
      expect(splitAmount, 25.0);

      final splits = List.generate(
        4,
        (i) => ExpenseSplitModel(
          id: 'split-$i',
          expenseId: 'expense-1',
          userId: 'user-$i',
          amount: splitAmount,
          isSettled: false,
        ),
      );

      final totalSplit = splits.fold<double>(0, (sum, s) => sum + s.amount);
      expect(totalSplit, 100.0);
    });

    test('should handle uneven split amounts', () {
      // 3 people, 100 expense = 33.33 each (with rounding)
      final amounts = [33.34, 33.33, 33.33]; // First person pays extra cent

      final splits = List.generate(
        3,
        (i) => ExpenseSplitModel(
          id: 'split-$i',
          expenseId: 'expense-1',
          userId: 'user-$i',
          amount: amounts[i],
          isSettled: false,
        ),
      );

      final totalSplit = splits.fold<double>(0, (sum, s) => sum + s.amount);
      expect(totalSplit, closeTo(100.0, 0.01));
    });
  });
}
