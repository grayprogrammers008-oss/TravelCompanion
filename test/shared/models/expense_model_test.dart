import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/shared/models/expense_model.dart';

void main() {
  group('ExpenseModel', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);

    group('constructor', () {
      test('should create instance with required fields', () {
        const expense = ExpenseModel(
          id: 'expense-1',
          title: 'Dinner',
          amount: 1500.0,
          paidBy: 'user-1',
        );

        expect(expense.id, 'expense-1');
        expect(expense.title, 'Dinner');
        expect(expense.amount, 1500.0);
        expect(expense.paidBy, 'user-1');
        expect(expense.currency, 'INR');
        expect(expense.splitType, 'equal');
        expect(expense.tripId, isNull);
      });

      test('should create instance with all fields', () {
        final expense = ExpenseModel(
          id: 'expense-1',
          tripId: 'trip-1',
          title: 'Hotel Stay',
          description: 'Resort booking',
          amount: 10000.0,
          currency: 'USD',
          category: 'accommodation',
          paidBy: 'user-1',
          splitType: 'percentage',
          receiptUrl: 'https://example.com/receipt.jpg',
          transactionDate: testDate,
          createdAt: testDate,
          updatedAt: testDate,
          payerName: 'John Doe',
        );

        expect(expense.tripId, 'trip-1');
        expect(expense.description, 'Resort booking');
        expect(expense.currency, 'USD');
        expect(expense.category, 'accommodation');
        expect(expense.splitType, 'percentage');
        expect(expense.receiptUrl, 'https://example.com/receipt.jpg');
        expect(expense.transactionDate, testDate);
        expect(expense.createdAt, testDate);
        expect(expense.updatedAt, testDate);
        expect(expense.payerName, 'John Doe');
      });
    });

    group('fromJson', () {
      test('should parse valid JSON with all fields', () {
        final json = {
          'id': 'expense-1',
          'trip_id': 'trip-1',
          'title': 'Hotel Stay',
          'description': 'Resort booking',
          'amount': 10000,
          'currency': 'USD',
          'category': 'accommodation',
          'paid_by': 'user-1',
          'split_type': 'percentage',
          'receipt_url': 'https://example.com/receipt.jpg',
          'transaction_date': '2024-01-15T10:30:00.000Z',
          'created_at': '2024-01-15T10:30:00.000Z',
          'updated_at': '2024-01-16T10:30:00.000Z',
          'payer_name': 'John Doe',
        };

        final expense = ExpenseModel.fromJson(json);

        expect(expense.id, 'expense-1');
        expect(expense.tripId, 'trip-1');
        expect(expense.title, 'Hotel Stay');
        expect(expense.description, 'Resort booking');
        expect(expense.amount, 10000);
        expect(expense.currency, 'USD');
        expect(expense.category, 'accommodation');
        expect(expense.paidBy, 'user-1');
        expect(expense.splitType, 'percentage');
        expect(expense.receiptUrl, 'https://example.com/receipt.jpg');
        expect(expense.payerName, 'John Doe');
      });

      test('should use default currency when missing', () {
        final json = {
          'id': 'expense-1',
          'title': 'Test',
          'amount': 100,
          'paid_by': 'user-1',
        };

        final expense = ExpenseModel.fromJson(json);
        expect(expense.currency, 'INR');
      });

      test('should use default split_type when missing', () {
        final json = {
          'id': 'expense-1',
          'title': 'Test',
          'amount': 100,
          'paid_by': 'user-1',
        };

        final expense = ExpenseModel.fromJson(json);
        expect(expense.splitType, 'equal');
      });

      test('should handle null dates', () {
        final json = {
          'id': 'expense-1',
          'title': 'Test',
          'amount': 100,
          'paid_by': 'user-1',
        };

        final expense = ExpenseModel.fromJson(json);
        expect(expense.transactionDate, isNull);
        expect(expense.createdAt, isNull);
        expect(expense.updatedAt, isNull);
      });
    });

    group('toJson', () {
      test('should convert to JSON with all fields', () {
        final expense = ExpenseModel(
          id: 'expense-1',
          tripId: 'trip-1',
          title: 'Hotel Stay',
          description: 'Resort booking',
          amount: 10000.0,
          currency: 'USD',
          category: 'accommodation',
          paidBy: 'user-1',
          splitType: 'percentage',
          receiptUrl: 'https://example.com/receipt.jpg',
          transactionDate: DateTime(2024, 1, 15, 10, 30),
          createdAt: DateTime(2024, 1, 15, 10, 30),
          updatedAt: DateTime(2024, 1, 16, 10, 30),
          payerName: 'John Doe',
        );

        final json = expense.toJson();

        expect(json['id'], 'expense-1');
        expect(json['trip_id'], 'trip-1');
        expect(json['title'], 'Hotel Stay');
        expect(json['description'], 'Resort booking');
        expect(json['amount'], 10000.0);
        expect(json['currency'], 'USD');
        expect(json['category'], 'accommodation');
        expect(json['paid_by'], 'user-1');
        expect(json['split_type'], 'percentage');
        expect(json['receipt_url'], 'https://example.com/receipt.jpg');
        expect(json['payer_name'], 'John Doe');
      });

      test('should handle null optional fields', () {
        const expense = ExpenseModel(
          id: 'expense-1',
          title: 'Test',
          amount: 100.0,
          paidBy: 'user-1',
        );

        final json = expense.toJson();

        expect(json['trip_id'], isNull);
        expect(json['description'], isNull);
        expect(json['category'], isNull);
        expect(json['receipt_url'], isNull);
        expect(json['transaction_date'], isNull);
        expect(json['created_at'], isNull);
        expect(json['updated_at'], isNull);
        expect(json['payer_name'], isNull);
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        const original = ExpenseModel(
          id: 'expense-1',
          title: 'Original',
          amount: 100.0,
          paidBy: 'user-1',
        );

        final copied = original.copyWith(
          title: 'Updated',
          amount: 200.0,
        );

        expect(copied.id, 'expense-1');
        expect(copied.title, 'Updated');
        expect(copied.amount, 200.0);
        expect(copied.paidBy, 'user-1');
      });

      test('should keep original values when not specified', () {
        final original = ExpenseModel(
          id: 'expense-1',
          tripId: 'trip-1',
          title: 'Original',
          description: 'Description',
          amount: 100.0,
          currency: 'USD',
          category: 'food',
          paidBy: 'user-1',
          splitType: 'percentage',
          receiptUrl: 'https://example.com',
          transactionDate: testDate,
          createdAt: testDate,
          updatedAt: testDate,
          payerName: 'John',
        );

        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.tripId, original.tripId);
        expect(copied.title, original.title);
        expect(copied.description, original.description);
        expect(copied.amount, original.amount);
        expect(copied.currency, original.currency);
        expect(copied.category, original.category);
        expect(copied.paidBy, original.paidBy);
        expect(copied.splitType, original.splitType);
        expect(copied.receiptUrl, original.receiptUrl);
        expect(copied.transactionDate, original.transactionDate);
        expect(copied.createdAt, original.createdAt);
        expect(copied.updatedAt, original.updatedAt);
        expect(copied.payerName, original.payerName);
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        final expense1 = ExpenseModel(
          id: 'expense-1',
          title: 'Dinner',
          amount: 1500.0,
          paidBy: 'user-1',
          createdAt: testDate,
        );

        final expense2 = ExpenseModel(
          id: 'expense-1',
          title: 'Dinner',
          amount: 1500.0,
          paidBy: 'user-1',
          createdAt: testDate,
        );

        expect(expense1, equals(expense2));
      });

      test('should not be equal when different id', () {
        const expense1 = ExpenseModel(
          id: 'expense-1',
          title: 'Dinner',
          amount: 1500.0,
          paidBy: 'user-1',
        );

        const expense2 = ExpenseModel(
          id: 'expense-2',
          title: 'Dinner',
          amount: 1500.0,
          paidBy: 'user-1',
        );

        expect(expense1, isNot(equals(expense2)));
      });

      test('should be identical to itself', () {
        const expense = ExpenseModel(
          id: 'expense-1',
          title: 'Dinner',
          amount: 1500.0,
          paidBy: 'user-1',
        );

        expect(expense == expense, true);
      });
    });

    group('hashCode', () {
      test('should have same hashCode for equal objects', () {
        final expense1 = ExpenseModel(
          id: 'expense-1',
          title: 'Dinner',
          amount: 1500.0,
          paidBy: 'user-1',
          createdAt: testDate,
        );

        final expense2 = ExpenseModel(
          id: 'expense-1',
          title: 'Dinner',
          amount: 1500.0,
          paidBy: 'user-1',
          createdAt: testDate,
        );

        expect(expense1.hashCode, equals(expense2.hashCode));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        const expense = ExpenseModel(
          id: 'expense-1',
          title: 'Dinner',
          amount: 1500.0,
          paidBy: 'user-1',
        );

        final str = expense.toString();
        expect(str, contains('ExpenseModel'));
        expect(str, contains('expense-1'));
        expect(str, contains('Dinner'));
        expect(str, contains('1500'));
      });
    });
  });

  group('ExpenseSplitModel', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);

    group('constructor', () {
      test('should create instance with required fields', () {
        const split = ExpenseSplitModel(
          id: 'split-1',
          expenseId: 'expense-1',
          userId: 'user-1',
          amount: 500.0,
        );

        expect(split.id, 'split-1');
        expect(split.expenseId, 'expense-1');
        expect(split.userId, 'user-1');
        expect(split.amount, 500.0);
        expect(split.isSettled, false);
      });

      test('should create instance with all fields', () {
        final split = ExpenseSplitModel(
          id: 'split-1',
          expenseId: 'expense-1',
          userId: 'user-1',
          amount: 500.0,
          isSettled: true,
          settledAt: testDate,
          createdAt: testDate,
          userName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        expect(split.isSettled, true);
        expect(split.settledAt, testDate);
        expect(split.createdAt, testDate);
        expect(split.userName, 'John Doe');
        expect(split.avatarUrl, 'https://example.com/avatar.jpg');
      });
    });

    group('fromJson', () {
      test('should parse valid JSON', () {
        final json = {
          'id': 'split-1',
          'expense_id': 'expense-1',
          'user_id': 'user-1',
          'amount': 500,
          'is_settled': true,
          'settled_at': '2024-01-15T10:30:00.000Z',
          'created_at': '2024-01-15T10:30:00.000Z',
          'user_name': 'John Doe',
          'avatar_url': 'https://example.com/avatar.jpg',
        };

        final split = ExpenseSplitModel.fromJson(json);

        expect(split.id, 'split-1');
        expect(split.expenseId, 'expense-1');
        expect(split.userId, 'user-1');
        expect(split.amount, 500);
        expect(split.isSettled, true);
        expect(split.userName, 'John Doe');
        expect(split.avatarUrl, 'https://example.com/avatar.jpg');
      });

      test('should handle is_settled as int', () {
        final json = {
          'id': 'split-1',
          'expense_id': 'expense-1',
          'user_id': 'user-1',
          'amount': 500,
          'is_settled': 1,
        };

        final split = ExpenseSplitModel.fromJson(json);
        expect(split.isSettled, true);
      });

      test('should handle is_settled as int 0', () {
        final json = {
          'id': 'split-1',
          'expense_id': 'expense-1',
          'user_id': 'user-1',
          'amount': 500,
          'is_settled': 0,
        };

        final split = ExpenseSplitModel.fromJson(json);
        expect(split.isSettled, false);
      });

      test('should default is_settled to false when null', () {
        final json = {
          'id': 'split-1',
          'expense_id': 'expense-1',
          'user_id': 'user-1',
          'amount': 500,
        };

        final split = ExpenseSplitModel.fromJson(json);
        expect(split.isSettled, false);
      });
    });

    group('toJson', () {
      test('should convert to JSON', () {
        final split = ExpenseSplitModel(
          id: 'split-1',
          expenseId: 'expense-1',
          userId: 'user-1',
          amount: 500.0,
          isSettled: true,
          settledAt: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
          userName: 'John',
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        final json = split.toJson();

        expect(json['id'], 'split-1');
        expect(json['expense_id'], 'expense-1');
        expect(json['user_id'], 'user-1');
        expect(json['amount'], 500.0);
        expect(json['is_settled'], true);
        expect(json['user_name'], 'John');
        expect(json['avatar_url'], 'https://example.com/avatar.jpg');
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        const original = ExpenseSplitModel(
          id: 'split-1',
          expenseId: 'expense-1',
          userId: 'user-1',
          amount: 500.0,
          isSettled: false,
        );

        final copied = original.copyWith(
          isSettled: true,
          amount: 600.0,
        );

        expect(copied.id, 'split-1');
        expect(copied.isSettled, true);
        expect(copied.amount, 600.0);
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        final split1 = ExpenseSplitModel(
          id: 'split-1',
          expenseId: 'expense-1',
          userId: 'user-1',
          amount: 500.0,
          createdAt: testDate,
        );

        final split2 = ExpenseSplitModel(
          id: 'split-1',
          expenseId: 'expense-1',
          userId: 'user-1',
          amount: 500.0,
          createdAt: testDate,
        );

        expect(split1, equals(split2));
      });
    });
  });

  group('ExpenseWithSplits', () {
    test('should create instance with expense and splits', () {
      const expense = ExpenseModel(
        id: 'expense-1',
        title: 'Dinner',
        amount: 1500.0,
        paidBy: 'user-1',
      );

      const split1 = ExpenseSplitModel(
        id: 'split-1',
        expenseId: 'expense-1',
        userId: 'user-1',
        amount: 500.0,
      );

      const split2 = ExpenseSplitModel(
        id: 'split-2',
        expenseId: 'expense-1',
        userId: 'user-2',
        amount: 500.0,
      );

      const expenseWithSplits = ExpenseWithSplits(
        expense: expense,
        splits: [split1, split2],
      );

      expect(expenseWithSplits.expense, expense);
      expect(expenseWithSplits.splits.length, 2);
      expect(expenseWithSplits.splits[0], split1);
      expect(expenseWithSplits.splits[1], split2);
    });

    group('fromJson', () {
      test('should parse valid JSON', () {
        final json = {
          'expense': {
            'id': 'expense-1',
            'title': 'Dinner',
            'amount': 1500,
            'paid_by': 'user-1',
          },
          'splits': [
            {
              'id': 'split-1',
              'expense_id': 'expense-1',
              'user_id': 'user-1',
              'amount': 500,
            },
            {
              'id': 'split-2',
              'expense_id': 'expense-1',
              'user_id': 'user-2',
              'amount': 500,
            },
          ],
        };

        final expenseWithSplits = ExpenseWithSplits.fromJson(json);

        expect(expenseWithSplits.expense.id, 'expense-1');
        expect(expenseWithSplits.splits.length, 2);
        expect(expenseWithSplits.splits[0].id, 'split-1');
        expect(expenseWithSplits.splits[1].id, 'split-2');
      });
    });

    group('toJson', () {
      test('should convert to JSON', () {
        const expenseWithSplits = ExpenseWithSplits(
          expense: ExpenseModel(
            id: 'expense-1',
            title: 'Dinner',
            amount: 1500.0,
            paidBy: 'user-1',
          ),
          splits: [
            ExpenseSplitModel(
              id: 'split-1',
              expenseId: 'expense-1',
              userId: 'user-1',
              amount: 500.0,
            ),
          ],
        );

        final json = expenseWithSplits.toJson();

        expect(json['expense']['id'], 'expense-1');
        expect((json['splits'] as List).length, 1);
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        const original = ExpenseWithSplits(
          expense: ExpenseModel(
            id: 'expense-1',
            title: 'Dinner',
            amount: 1500.0,
            paidBy: 'user-1',
          ),
          splits: [],
        );

        final newExpense = original.expense.copyWith(title: 'Lunch');
        final copied = original.copyWith(expense: newExpense);

        expect(copied.expense.title, 'Lunch');
        expect(copied.expense.id, 'expense-1');
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        const expenseWithSplits1 = ExpenseWithSplits(
          expense: ExpenseModel(
            id: 'expense-1',
            title: 'Dinner',
            amount: 1500.0,
            paidBy: 'user-1',
          ),
          splits: [
            ExpenseSplitModel(
              id: 'split-1',
              expenseId: 'expense-1',
              userId: 'user-1',
              amount: 500.0,
            ),
          ],
        );

        const expenseWithSplits2 = ExpenseWithSplits(
          expense: ExpenseModel(
            id: 'expense-1',
            title: 'Dinner',
            amount: 1500.0,
            paidBy: 'user-1',
          ),
          splits: [
            ExpenseSplitModel(
              id: 'split-1',
              expenseId: 'expense-1',
              userId: 'user-1',
              amount: 500.0,
            ),
          ],
        );

        expect(expenseWithSplits1, equals(expenseWithSplits2));
      });

      test('should not be equal when different splits', () {
        const expenseWithSplits1 = ExpenseWithSplits(
          expense: ExpenseModel(
            id: 'expense-1',
            title: 'Dinner',
            amount: 1500.0,
            paidBy: 'user-1',
          ),
          splits: [],
        );

        const expenseWithSplits2 = ExpenseWithSplits(
          expense: ExpenseModel(
            id: 'expense-1',
            title: 'Dinner',
            amount: 1500.0,
            paidBy: 'user-1',
          ),
          splits: [
            ExpenseSplitModel(
              id: 'split-1',
              expenseId: 'expense-1',
              userId: 'user-1',
              amount: 500.0,
            ),
          ],
        );

        expect(expenseWithSplits1, isNot(equals(expenseWithSplits2)));
      });
    });
  });

  group('SettlementModel', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);

    group('constructor', () {
      test('should create instance with required fields', () {
        const settlement = SettlementModel(
          id: 'settlement-1',
          fromUser: 'user-1',
          toUser: 'user-2',
          amount: 500.0,
        );

        expect(settlement.id, 'settlement-1');
        expect(settlement.fromUser, 'user-1');
        expect(settlement.toUser, 'user-2');
        expect(settlement.amount, 500.0);
        expect(settlement.currency, 'INR');
        expect(settlement.status, 'pending');
      });

      test('should create instance with all fields', () {
        final settlement = SettlementModel(
          id: 'settlement-1',
          tripId: 'trip-1',
          fromUser: 'user-1',
          toUser: 'user-2',
          amount: 500.0,
          currency: 'USD',
          paymentMethod: 'UPI',
          paymentProofUrl: 'https://example.com/proof.jpg',
          status: 'completed',
          transactionDate: testDate,
          createdAt: testDate,
          fromUserName: 'John',
          toUserName: 'Jane',
        );

        expect(settlement.tripId, 'trip-1');
        expect(settlement.currency, 'USD');
        expect(settlement.paymentMethod, 'UPI');
        expect(settlement.paymentProofUrl, 'https://example.com/proof.jpg');
        expect(settlement.status, 'completed');
        expect(settlement.fromUserName, 'John');
        expect(settlement.toUserName, 'Jane');
      });
    });

    group('fromJson', () {
      test('should parse valid JSON', () {
        final json = {
          'id': 'settlement-1',
          'trip_id': 'trip-1',
          'from_user': 'user-1',
          'to_user': 'user-2',
          'amount': 500,
          'currency': 'USD',
          'payment_method': 'UPI',
          'payment_proof_url': 'https://example.com/proof.jpg',
          'status': 'completed',
          'transaction_date': '2024-01-15T10:30:00.000Z',
          'created_at': '2024-01-15T10:30:00.000Z',
          'from_user_name': 'John',
          'to_user_name': 'Jane',
        };

        final settlement = SettlementModel.fromJson(json);

        expect(settlement.id, 'settlement-1');
        expect(settlement.tripId, 'trip-1');
        expect(settlement.fromUser, 'user-1');
        expect(settlement.toUser, 'user-2');
        expect(settlement.amount, 500);
        expect(settlement.currency, 'USD');
        expect(settlement.paymentMethod, 'UPI');
        expect(settlement.status, 'completed');
        expect(settlement.fromUserName, 'John');
        expect(settlement.toUserName, 'Jane');
      });

      test('should use defaults when missing', () {
        final json = {
          'id': 'settlement-1',
          'from_user': 'user-1',
          'to_user': 'user-2',
          'amount': 500,
        };

        final settlement = SettlementModel.fromJson(json);
        expect(settlement.currency, 'INR');
        expect(settlement.status, 'pending');
      });
    });

    group('toJson', () {
      test('should convert to JSON', () {
        final settlement = SettlementModel(
          id: 'settlement-1',
          tripId: 'trip-1',
          fromUser: 'user-1',
          toUser: 'user-2',
          amount: 500.0,
          currency: 'USD',
          paymentMethod: 'UPI',
          status: 'completed',
          transactionDate: DateTime(2024, 1, 15),
          fromUserName: 'John',
          toUserName: 'Jane',
        );

        final json = settlement.toJson();

        expect(json['id'], 'settlement-1');
        expect(json['trip_id'], 'trip-1');
        expect(json['from_user'], 'user-1');
        expect(json['to_user'], 'user-2');
        expect(json['amount'], 500.0);
        expect(json['currency'], 'USD');
        expect(json['payment_method'], 'UPI');
        expect(json['status'], 'completed');
        expect(json['from_user_name'], 'John');
        expect(json['to_user_name'], 'Jane');
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        const original = SettlementModel(
          id: 'settlement-1',
          fromUser: 'user-1',
          toUser: 'user-2',
          amount: 500.0,
          status: 'pending',
        );

        final copied = original.copyWith(
          status: 'completed',
          amount: 600.0,
        );

        expect(copied.id, 'settlement-1');
        expect(copied.status, 'completed');
        expect(copied.amount, 600.0);
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        final settlement1 = SettlementModel(
          id: 'settlement-1',
          fromUser: 'user-1',
          toUser: 'user-2',
          amount: 500.0,
          createdAt: testDate,
        );

        final settlement2 = SettlementModel(
          id: 'settlement-1',
          fromUser: 'user-1',
          toUser: 'user-2',
          amount: 500.0,
          createdAt: testDate,
        );

        expect(settlement1, equals(settlement2));
      });
    });
  });

  group('BalanceSummary', () {
    test('should create instance', () {
      final summary = BalanceSummary(
        userId: 'user-1',
        userName: 'John Doe',
        totalPaid: 5000.0,
        totalOwed: 3000.0,
        balance: 2000.0,
      );

      expect(summary.userId, 'user-1');
      expect(summary.userName, 'John Doe');
      expect(summary.totalPaid, 5000.0);
      expect(summary.totalOwed, 3000.0);
      expect(summary.balance, 2000.0);
    });

    test('should handle negative balance', () {
      final summary = BalanceSummary(
        userId: 'user-1',
        userName: 'Jane Doe',
        totalPaid: 1000.0,
        totalOwed: 3000.0,
        balance: -2000.0,
      );

      expect(summary.balance, -2000.0);
    });
  });
}
