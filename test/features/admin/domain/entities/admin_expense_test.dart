import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_expense.dart';

void main() {
  group('AdminExpenseModel', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);

    group('constructor', () {
      test('should create instance with required fields', () {
        final expense = AdminExpenseModel(
          id: 'expense-1',
          title: 'Dinner',
          amount: 1500.0,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 3,
          settledCount: 1,
          pendingAmount: 1000.0,
        );

        expect(expense.id, 'expense-1');
        expect(expense.title, 'Dinner');
        expect(expense.amount, 1500.0);
        expect(expense.currency, 'INR');
        expect(expense.paidBy, 'user-1');
        expect(expense.splitType, 'equal');
        expect(expense.splitCount, 3);
        expect(expense.settledCount, 1);
        expect(expense.pendingAmount, 1000.0);
      });

      test('should create instance with all fields', () {
        final expense = AdminExpenseModel(
          id: 'expense-1',
          tripId: 'trip-1',
          tripName: 'Beach Vacation',
          tripDestination: 'Goa',
          title: 'Hotel Stay',
          description: 'Resort booking',
          amount: 10000.0,
          currency: 'INR',
          category: 'accommodation',
          paidBy: 'user-1',
          payerName: 'John Doe',
          payerEmail: 'john@example.com',
          splitType: 'percentage',
          receiptUrl: 'https://example.com/receipt.jpg',
          transactionDate: testDate,
          createdAt: testDate,
          updatedAt: testDate,
          splitCount: 4,
          settledCount: 2,
          pendingAmount: 5000.0,
        );

        expect(expense.tripId, 'trip-1');
        expect(expense.tripName, 'Beach Vacation');
        expect(expense.tripDestination, 'Goa');
        expect(expense.description, 'Resort booking');
        expect(expense.category, 'accommodation');
        expect(expense.payerName, 'John Doe');
        expect(expense.payerEmail, 'john@example.com');
        expect(expense.receiptUrl, 'https://example.com/receipt.jpg');
        expect(expense.transactionDate, testDate);
        expect(expense.updatedAt, testDate);
      });
    });

    group('isStandalone', () {
      test('should return true when tripId is null', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Lunch',
          amount: 500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 1,
          settledCount: 0,
          pendingAmount: 500,
        );
        expect(expense.isStandalone, true);
      });

      test('should return false when tripId is set', () {
        final expense = AdminExpenseModel(
          id: '1',
          tripId: 'trip-1',
          title: 'Lunch',
          amount: 500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 1,
          settledCount: 0,
          pendingAmount: 500,
        );
        expect(expense.isStandalone, false);
      });
    });

    group('isFullySettled', () {
      test('should return true when all splits settled', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 3,
          settledCount: 3,
          pendingAmount: 0,
        );
        expect(expense.isFullySettled, true);
      });

      test('should return false when not all splits settled', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 3,
          settledCount: 1,
          pendingAmount: 1000,
        );
        expect(expense.isFullySettled, false);
      });

      test('should return false when no splits', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 0,
          settledCount: 0,
          pendingAmount: 0,
        );
        expect(expense.isFullySettled, false);
      });
    });

    group('hasPendingSplits', () {
      test('should return true when splits pending', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 3,
          settledCount: 1,
          pendingAmount: 1000,
        );
        expect(expense.hasPendingSplits, true);
      });

      test('should return false when all splits settled', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 3,
          settledCount: 3,
          pendingAmount: 0,
        );
        expect(expense.hasPendingSplits, false);
      });

      test('should return false when no splits', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 0,
          settledCount: 0,
          pendingAmount: 0,
        );
        expect(expense.hasPendingSplits, false);
      });
    });

    group('hasNoSplits', () {
      test('should return true when splitCount is 0', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 0,
          settledCount: 0,
          pendingAmount: 0,
        );
        expect(expense.hasNoSplits, true);
      });

      test('should return false when splitCount > 0', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 3,
          settledCount: 0,
          pendingAmount: 1500,
        );
        expect(expense.hasNoSplits, false);
      });
    });

    group('settlementPercentage', () {
      test('should return 0 when no splits', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 0,
          settledCount: 0,
          pendingAmount: 0,
        );
        expect(expense.settlementPercentage, 0);
      });

      test('should return 100 when all settled', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 4,
          settledCount: 4,
          pendingAmount: 0,
        );
        expect(expense.settlementPercentage, 100);
      });

      test('should return 50 when half settled', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 4,
          settledCount: 2,
          pendingAmount: 750,
        );
        expect(expense.settlementPercentage, 50);
      });
    });

    group('pendingSplitCount', () {
      test('should return correct pending count', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 5,
          settledCount: 2,
          pendingAmount: 900,
        );
        expect(expense.pendingSplitCount, 3);
      });
    });

    group('hasReceipt', () {
      test('should return true when receiptUrl is set', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          receiptUrl: 'https://example.com/receipt.jpg',
          createdAt: testDate,
          splitCount: 0,
          settledCount: 0,
          pendingAmount: 0,
        );
        expect(expense.hasReceipt, true);
      });

      test('should return false when receiptUrl is null', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 0,
          settledCount: 0,
          pendingAmount: 0,
        );
        expect(expense.hasReceipt, false);
      });

      test('should return false when receiptUrl is empty', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          receiptUrl: '',
          createdAt: testDate,
          splitCount: 0,
          settledCount: 0,
          pendingAmount: 0,
        );
        expect(expense.hasReceipt, false);
      });
    });

    group('payerDisplayName', () {
      test('should return payerName if set', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          payerName: 'John Doe',
          payerEmail: 'john@example.com',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 0,
          settledCount: 0,
          pendingAmount: 0,
        );
        expect(expense.payerDisplayName, 'John Doe');
      });

      test('should return payerEmail if name is null', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          payerEmail: 'john@example.com',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 0,
          settledCount: 0,
          pendingAmount: 0,
        );
        expect(expense.payerDisplayName, 'john@example.com');
      });

      test('should return Unknown if both are null', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 0,
          settledCount: 0,
          pendingAmount: 0,
        );
        expect(expense.payerDisplayName, 'Unknown');
      });
    });

    group('categoryDisplayName', () {
      test('should return Food & Dining for food', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Lunch',
          amount: 500,
          currency: 'INR',
          paidBy: 'user-1',
          category: 'food',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 0,
          settledCount: 0,
          pendingAmount: 0,
        );
        expect(expense.categoryDisplayName, 'Food & Dining');
      });

      test('should return Transportation for transport', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Taxi',
          amount: 300,
          currency: 'INR',
          paidBy: 'user-1',
          category: 'transport',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 0,
          settledCount: 0,
          pendingAmount: 0,
        );
        expect(expense.categoryDisplayName, 'Transportation');
      });

      test('should return Accommodation for accommodation', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Hotel',
          amount: 5000,
          currency: 'INR',
          paidBy: 'user-1',
          category: 'accommodation',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 0,
          settledCount: 0,
          pendingAmount: 0,
        );
        expect(expense.categoryDisplayName, 'Accommodation');
      });

      test('should return Activities for activities', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Scuba',
          amount: 2000,
          currency: 'INR',
          paidBy: 'user-1',
          category: 'activities',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 0,
          settledCount: 0,
          pendingAmount: 0,
        );
        expect(expense.categoryDisplayName, 'Activities');
      });

      test('should return Shopping for shopping', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Souvenirs',
          amount: 1000,
          currency: 'INR',
          paidBy: 'user-1',
          category: 'shopping',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 0,
          settledCount: 0,
          pendingAmount: 0,
        );
        expect(expense.categoryDisplayName, 'Shopping');
      });

      test('should return Other for other', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Misc',
          amount: 200,
          currency: 'INR',
          paidBy: 'user-1',
          category: 'other',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 0,
          settledCount: 0,
          pendingAmount: 0,
        );
        expect(expense.categoryDisplayName, 'Other');
      });

      test('should return Uncategorized when null', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Something',
          amount: 100,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 0,
          settledCount: 0,
          pendingAmount: 0,
        );
        expect(expense.categoryDisplayName, 'Uncategorized');
      });

      test('should return category as-is for unknown category', () {
        final expense = AdminExpenseModel(
          id: '1',
          title: 'Custom',
          amount: 100,
          currency: 'INR',
          paidBy: 'user-1',
          category: 'custom_category',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 0,
          settledCount: 0,
          pendingAmount: 0,
        );
        expect(expense.categoryDisplayName, 'custom_category');
      });
    });

    group('fromJson', () {
      test('should parse valid JSON with all fields', () {
        final json = {
          'id': 'expense-1',
          'trip_id': 'trip-1',
          'trip_name': 'Beach Vacation',
          'trip_destination': 'Goa',
          'title': 'Hotel Stay',
          'description': 'Resort booking',
          'amount': 10000,
          'currency': 'INR',
          'category': 'accommodation',
          'paid_by': 'user-1',
          'payer_name': 'John Doe',
          'payer_email': 'john@example.com',
          'split_type': 'percentage',
          'receipt_url': 'https://example.com/receipt.jpg',
          'transaction_date': '2024-01-15T10:30:00.000Z',
          'created_at': '2024-01-15T10:30:00.000Z',
          'updated_at': '2024-01-16T10:30:00.000Z',
          'split_count': 4,
          'settled_count': 2,
          'pending_amount': 5000,
        };

        final expense = AdminExpenseModel.fromJson(json);

        expect(expense.id, 'expense-1');
        expect(expense.tripId, 'trip-1');
        expect(expense.tripName, 'Beach Vacation');
        expect(expense.tripDestination, 'Goa');
        expect(expense.title, 'Hotel Stay');
        expect(expense.description, 'Resort booking');
        expect(expense.amount, 10000);
        expect(expense.currency, 'INR');
        expect(expense.category, 'accommodation');
        expect(expense.paidBy, 'user-1');
        expect(expense.payerName, 'John Doe');
        expect(expense.payerEmail, 'john@example.com');
        expect(expense.splitType, 'percentage');
        expect(expense.receiptUrl, 'https://example.com/receipt.jpg');
        expect(expense.transactionDate, DateTime.parse('2024-01-15T10:30:00.000Z'));
        expect(expense.createdAt, DateTime.parse('2024-01-15T10:30:00.000Z'));
        expect(expense.updatedAt, DateTime.parse('2024-01-16T10:30:00.000Z'));
        expect(expense.splitCount, 4);
        expect(expense.settledCount, 2);
        expect(expense.pendingAmount, 5000);
      });

      test('should use default currency when missing', () {
        final json = {
          'id': 'expense-1',
          'title': 'Test',
          'amount': 100,
          'paid_by': 'user-1',
          'created_at': '2024-01-15T10:30:00.000Z',
        };

        final expense = AdminExpenseModel.fromJson(json);
        expect(expense.currency, 'INR');
      });

      test('should use default split_type when missing', () {
        final json = {
          'id': 'expense-1',
          'title': 'Test',
          'amount': 100,
          'paid_by': 'user-1',
          'currency': 'INR',
          'created_at': '2024-01-15T10:30:00.000Z',
        };

        final expense = AdminExpenseModel.fromJson(json);
        expect(expense.splitType, 'equal');
      });

      test('should handle null counts with 0', () {
        final json = {
          'id': 'expense-1',
          'title': 'Test',
          'amount': 100,
          'paid_by': 'user-1',
          'currency': 'INR',
          'split_type': 'equal',
          'created_at': '2024-01-15T10:30:00.000Z',
        };

        final expense = AdminExpenseModel.fromJson(json);
        expect(expense.splitCount, 0);
        expect(expense.settledCount, 0);
        expect(expense.pendingAmount, 0);
      });
    });

    group('toJson', () {
      test('should convert to JSON with all fields', () {
        final expense = AdminExpenseModel(
          id: 'expense-1',
          tripId: 'trip-1',
          tripName: 'Beach Vacation',
          tripDestination: 'Goa',
          title: 'Hotel Stay',
          description: 'Resort booking',
          amount: 10000.0,
          currency: 'INR',
          category: 'accommodation',
          paidBy: 'user-1',
          payerName: 'John Doe',
          payerEmail: 'john@example.com',
          splitType: 'percentage',
          receiptUrl: 'https://example.com/receipt.jpg',
          transactionDate: DateTime(2024, 1, 15, 10, 30),
          createdAt: DateTime(2024, 1, 15, 10, 30),
          updatedAt: DateTime(2024, 1, 16, 10, 30),
          splitCount: 4,
          settledCount: 2,
          pendingAmount: 5000.0,
        );

        final json = expense.toJson();

        expect(json['id'], 'expense-1');
        expect(json['trip_id'], 'trip-1');
        expect(json['trip_name'], 'Beach Vacation');
        expect(json['trip_destination'], 'Goa');
        expect(json['title'], 'Hotel Stay');
        expect(json['description'], 'Resort booking');
        expect(json['amount'], 10000.0);
        expect(json['currency'], 'INR');
        expect(json['category'], 'accommodation');
        expect(json['paid_by'], 'user-1');
        expect(json['payer_name'], 'John Doe');
        expect(json['payer_email'], 'john@example.com');
        expect(json['split_type'], 'percentage');
        expect(json['receipt_url'], 'https://example.com/receipt.jpg');
        expect(json['split_count'], 4);
        expect(json['settled_count'], 2);
        expect(json['pending_amount'], 5000.0);
      });
    });

    group('equality (Equatable)', () {
      test('should be equal when same values', () {
        final expense1 = AdminExpenseModel(
          id: 'expense-1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 3,
          settledCount: 1,
          pendingAmount: 1000,
        );

        final expense2 = AdminExpenseModel(
          id: 'expense-1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 3,
          settledCount: 1,
          pendingAmount: 1000,
        );

        expect(expense1, equals(expense2));
      });

      test('should not be equal when different id', () {
        final expense1 = AdminExpenseModel(
          id: 'expense-1',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 3,
          settledCount: 1,
          pendingAmount: 1000,
        );

        final expense2 = AdminExpenseModel(
          id: 'expense-2',
          title: 'Dinner',
          amount: 1500,
          currency: 'INR',
          paidBy: 'user-1',
          splitType: 'equal',
          createdAt: testDate,
          splitCount: 3,
          settledCount: 1,
          pendingAmount: 1000,
        );

        expect(expense1, isNot(equals(expense2)));
      });
    });
  });

  group('ExpenseListParams', () {
    group('constructor', () {
      test('should create with default values', () {
        const params = ExpenseListParams();
        expect(params.limit, 50);
        expect(params.offset, 0);
        expect(params.search, isNull);
        expect(params.category, isNull);
        expect(params.tripId, isNull);
      });

      test('should create with specified values', () {
        const params = ExpenseListParams(
          limit: 20,
          offset: 10,
          search: 'hotel',
          category: 'accommodation',
          tripId: 'trip-1',
        );
        expect(params.limit, 20);
        expect(params.offset, 10);
        expect(params.search, 'hotel');
        expect(params.category, 'accommodation');
        expect(params.tripId, 'trip-1');
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        const original = ExpenseListParams(
          limit: 50,
          offset: 0,
          search: 'test',
        );

        final copied = original.copyWith(
          limit: 100,
          search: 'updated',
        );

        expect(copied.limit, 100);
        expect(copied.offset, 0);
        expect(copied.search, 'updated');
      });

      test('should keep original values when not specified', () {
        const original = ExpenseListParams(
          limit: 20,
          offset: 10,
          search: 'test',
          category: 'food',
          tripId: 'trip-1',
        );

        final copied = original.copyWith();

        expect(copied.limit, original.limit);
        expect(copied.offset, original.offset);
        expect(copied.search, original.search);
        expect(copied.category, original.category);
        expect(copied.tripId, original.tripId);
      });
    });

    group('equality (Equatable)', () {
      test('should be equal when same values', () {
        const params1 = ExpenseListParams(limit: 20, category: 'food');
        const params2 = ExpenseListParams(limit: 20, category: 'food');
        expect(params1, equals(params2));
      });

      test('should not be equal when different values', () {
        const params1 = ExpenseListParams(limit: 20, category: 'food');
        const params2 = ExpenseListParams(limit: 20, category: 'transport');
        expect(params1, isNot(equals(params2)));
      });
    });
  });

  group('AdminExpenseStatsModel', () {
    group('constructor', () {
      test('should create with required values', () {
        const stats = AdminExpenseStatsModel(
          totalExpenses: 100,
          totalAmount: 500000,
          totalSettled: 300000,
          totalPending: 200000,
          settlementRate: 60.0,
          expensesWithReceipts: 80,
          standaloneExpenses: 20,
          tripExpenses: 80,
          categoryBreakdown: {'food': 30, 'transport': 20},
        );

        expect(stats.totalExpenses, 100);
        expect(stats.totalAmount, 500000);
        expect(stats.totalSettled, 300000);
        expect(stats.totalPending, 200000);
        expect(stats.settlementRate, 60.0);
        expect(stats.expensesWithReceipts, 80);
        expect(stats.standaloneExpenses, 20);
        expect(stats.tripExpenses, 80);
        expect(stats.categoryBreakdown['food'], 30);
        expect(stats.categoryBreakdown['transport'], 20);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON', () {
        final json = {
          'total_expenses': 100,
          'total_amount': 500000.0,
          'total_settled': 300000.0,
          'total_pending': 200000.0,
          'settlement_rate': 60.0,
          'expenses_with_receipts': 80,
          'standalone_expenses': 20,
          'trip_expenses': 80,
          'category_breakdown': {'food': 30, 'transport': 20, 'accommodation': 50},
        };

        final stats = AdminExpenseStatsModel.fromJson(json);

        expect(stats.totalExpenses, 100);
        expect(stats.totalAmount, 500000.0);
        expect(stats.totalSettled, 300000.0);
        expect(stats.totalPending, 200000.0);
        expect(stats.settlementRate, 60.0);
        expect(stats.expensesWithReceipts, 80);
        expect(stats.standaloneExpenses, 20);
        expect(stats.tripExpenses, 80);
        expect(stats.categoryBreakdown['food'], 30);
        expect(stats.categoryBreakdown['transport'], 20);
        expect(stats.categoryBreakdown['accommodation'], 50);
      });

      test('should handle null values with defaults', () {
        final json = <String, dynamic>{};

        final stats = AdminExpenseStatsModel.fromJson(json);

        expect(stats.totalExpenses, 0);
        expect(stats.totalAmount, 0);
        expect(stats.totalSettled, 0);
        expect(stats.totalPending, 0);
        expect(stats.settlementRate, 0);
        expect(stats.expensesWithReceipts, 0);
        expect(stats.standaloneExpenses, 0);
        expect(stats.tripExpenses, 0);
        expect(stats.categoryBreakdown, isEmpty);
      });

      test('should handle null category_breakdown', () {
        final json = {
          'total_expenses': 10,
          'total_amount': 1000,
          'total_settled': 500,
          'total_pending': 500,
          'settlement_rate': 50.0,
          'expenses_with_receipts': 5,
          'standalone_expenses': 2,
          'trip_expenses': 8,
          'category_breakdown': null,
        };

        final stats = AdminExpenseStatsModel.fromJson(json);
        expect(stats.categoryBreakdown, isEmpty);
      });

      test('should handle non-map category_breakdown', () {
        final json = {
          'total_expenses': 10,
          'total_amount': 1000,
          'total_settled': 500,
          'total_pending': 500,
          'settlement_rate': 50.0,
          'expenses_with_receipts': 5,
          'standalone_expenses': 2,
          'trip_expenses': 8,
          'category_breakdown': 'invalid',
        };

        final stats = AdminExpenseStatsModel.fromJson(json);
        expect(stats.categoryBreakdown, isEmpty);
      });
    });

    group('equality (Equatable)', () {
      test('should be equal when same values', () {
        const stats1 = AdminExpenseStatsModel(
          totalExpenses: 100,
          totalAmount: 50000,
          totalSettled: 30000,
          totalPending: 20000,
          settlementRate: 60.0,
          expensesWithReceipts: 80,
          standaloneExpenses: 20,
          tripExpenses: 80,
          categoryBreakdown: {},
        );

        const stats2 = AdminExpenseStatsModel(
          totalExpenses: 100,
          totalAmount: 50000,
          totalSettled: 30000,
          totalPending: 20000,
          settlementRate: 60.0,
          expensesWithReceipts: 80,
          standaloneExpenses: 20,
          tripExpenses: 80,
          categoryBreakdown: {},
        );

        expect(stats1, equals(stats2));
      });
    });
  });
}
