import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/expenses/data/datasources/expense_remote_datasource.dart';
import 'package:travel_crew/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:travel_crew/shared/models/expense_model.dart';

import 'expense_repository_impl_test.mocks.dart';

@GenerateMocks([ExpenseRemoteDataSource])
void main() {
  late ExpenseRepositoryImpl repository;
  late MockExpenseRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockExpenseRemoteDataSource();
    repository = ExpenseRepositoryImpl(mockDataSource);
  });

  final now = DateTime.now();

  final testExpense = ExpenseModel(
    id: 'expense-123',
    tripId: 'trip-123',
    title: 'Dinner',
    description: 'Group dinner at restaurant',
    amount: 150.0,
    currency: 'USD',
    category: 'Food',
    paidBy: 'user-123',
    splitType: 'equal',
    transactionDate: now,
    createdAt: now,
  );

  final testSplit = ExpenseSplitModel(
    id: 'split-1',
    expenseId: 'expense-123',
    userId: 'user-456',
    amount: 75.0,
    isSettled: false,
    createdAt: now,
    userName: 'John Doe',
  );

  final testExpenseWithSplits = ExpenseWithSplits(
    expense: testExpense,
    splits: [testSplit],
  );

  final testBalanceSummary = BalanceSummary(
    userId: 'user-123',
    userName: 'Test User',
    totalPaid: 150.0,
    totalOwed: 75.0,
    balance: 75.0,
  );

  final testSettlement = SettlementModel(
    id: 'settlement-123',
    tripId: 'trip-123',
    fromUser: 'user-456',
    toUser: 'user-123',
    amount: 75.0,
    status: 'pending',
    createdAt: now,
  );

  group('ExpenseRepositoryImpl', () {
    group('getTripExpenses', () {
      group('Positive Cases', () {
        test('should return list of expenses for trip', () async {
          // Arrange
          when(mockDataSource.getTripExpenses('trip-123')).thenAnswer(
            (_) async => [testExpenseWithSplits],
          );

          // Act
          final result = await repository.getTripExpenses('trip-123');

          // Assert
          expect(result.length, 1);
          expect(result.first.expense, testExpense);
          expect(result.first.splits, [testSplit]);
          verify(mockDataSource.getTripExpenses('trip-123')).called(1);
        });

        test('should return empty list when trip has no expenses', () async {
          // Arrange
          when(mockDataSource.getTripExpenses('trip-456')).thenAnswer(
            (_) async => [],
          );

          // Act
          final result = await repository.getTripExpenses('trip-456');

          // Assert
          expect(result, isEmpty);
          verify(mockDataSource.getTripExpenses('trip-456')).called(1);
        });

        test('should return multiple expenses for trip', () async {
          // Arrange
          final expense2 = testExpense.copyWith(
            id: 'expense-456',
            title: 'Hotel',
            amount: 500.0,
          );
          final expenseWithSplits2 = ExpenseWithSplits(
            expense: expense2,
            splits: [],
          );

          when(mockDataSource.getTripExpenses('trip-123')).thenAnswer(
            (_) async => [testExpenseWithSplits, expenseWithSplits2],
          );

          // Act
          final result = await repository.getTripExpenses('trip-123');

          // Assert
          expect(result.length, 2);
          expect(result[0].expense.title, 'Dinner');
          expect(result[1].expense.title, 'Hotel');
        });
      });

      group('Negative Cases', () {
        test('should throw exception when datasource fails', () async {
          // Arrange
          when(mockDataSource.getTripExpenses('trip-123')).thenThrow(
            Exception('Database error'),
          );

          // Act & Assert
          expect(
            () => repository.getTripExpenses('trip-123'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to get trip expenses'),
            )),
          );
        });

        test('should throw exception for network error', () async {
          // Arrange
          when(mockDataSource.getTripExpenses('trip-123')).thenThrow(
            Exception('Network unavailable'),
          );

          // Act & Assert
          expect(
            () => repository.getTripExpenses('trip-123'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to get trip expenses'),
            )),
          );
        });
      });
    });

    group('getExpenseById', () {
      group('Positive Cases', () {
        test('should return expense by ID', () async {
          // Arrange
          when(mockDataSource.getExpenseById('expense-123')).thenAnswer(
            (_) async => testExpenseWithSplits,
          );

          // Act
          final result = await repository.getExpenseById('expense-123');

          // Assert
          expect(result.expense.id, 'expense-123');
          expect(result.expense.title, 'Dinner');
          verify(mockDataSource.getExpenseById('expense-123')).called(1);
        });

        test('should return expense with splits', () async {
          // Arrange
          when(mockDataSource.getExpenseById('expense-123')).thenAnswer(
            (_) async => testExpenseWithSplits,
          );

          // Act
          final result = await repository.getExpenseById('expense-123');

          // Assert
          expect(result.splits.length, 1);
          expect(result.splits.first.userId, 'user-456');
        });
      });

      group('Negative Cases', () {
        test('should throw exception when expense not found', () async {
          // Arrange
          when(mockDataSource.getExpenseById('non-existent')).thenThrow(
            Exception('Expense not found'),
          );

          // Act & Assert
          expect(
            () => repository.getExpenseById('non-existent'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to get expense'),
            )),
          );
        });
      });
    });

    group('createExpense', () {
      group('Positive Cases', () {
        test('should create expense with all parameters', () async {
          // Arrange
          when(mockDataSource.createExpense(
            tripId: anyNamed('tripId'),
            title: anyNamed('title'),
            description: anyNamed('description'),
            amount: anyNamed('amount'),
            category: anyNamed('category'),
            paidBy: anyNamed('paidBy'),
            splitWith: anyNamed('splitWith'),
            splitType: anyNamed('splitType'),
            transactionDate: anyNamed('transactionDate'),
          )).thenAnswer((_) async => testExpense);

          // Act
          final result = await repository.createExpense(
            tripId: 'trip-123',
            title: 'Dinner',
            description: 'Group dinner',
            amount: 150.0,
            category: 'Food',
            paidBy: 'user-123',
            splitWith: ['user-123', 'user-456'],
            splitType: 'equal',
            transactionDate: now,
          );

          // Assert
          expect(result.id, testExpense.id);
          expect(result.title, testExpense.title);
          verify(mockDataSource.createExpense(
            tripId: 'trip-123',
            title: 'Dinner',
            description: 'Group dinner',
            amount: 150.0,
            category: 'Food',
            paidBy: 'user-123',
            splitWith: ['user-123', 'user-456'],
            splitType: 'equal',
            transactionDate: now,
          )).called(1);
        });

        test('should create standalone expense (no tripId)', () async {
          // Arrange
          when(mockDataSource.createExpense(
            tripId: anyNamed('tripId'),
            title: anyNamed('title'),
            description: anyNamed('description'),
            amount: anyNamed('amount'),
            category: anyNamed('category'),
            paidBy: anyNamed('paidBy'),
            splitWith: anyNamed('splitWith'),
            splitType: anyNamed('splitType'),
            transactionDate: anyNamed('transactionDate'),
          )).thenAnswer((_) async => testExpense);

          // Act
          final result = await repository.createExpense(
            title: 'Personal Purchase',
            amount: 50.0,
            paidBy: 'user-123',
            splitWith: ['user-123', 'user-456'],
          );

          // Assert
          expect(result, isNotNull);
          verify(mockDataSource.createExpense(
            tripId: null,
            title: 'Personal Purchase',
            description: null,
            amount: 50.0,
            category: null,
            paidBy: 'user-123',
            splitWith: ['user-123', 'user-456'],
            splitType: 'equal',
            transactionDate: null,
          )).called(1);
        });

        test('should create expense with percentage split', () async {
          // Arrange
          when(mockDataSource.createExpense(
            tripId: anyNamed('tripId'),
            title: anyNamed('title'),
            description: anyNamed('description'),
            amount: anyNamed('amount'),
            category: anyNamed('category'),
            paidBy: anyNamed('paidBy'),
            splitWith: anyNamed('splitWith'),
            splitType: anyNamed('splitType'),
            transactionDate: anyNamed('transactionDate'),
          )).thenAnswer((_) async => testExpense);

          // Act
          await repository.createExpense(
            title: 'Dinner',
            amount: 100.0,
            paidBy: 'user-123',
            splitWith: ['user-123', 'user-456'],
            splitType: 'percentage',
          );

          // Assert
          verify(mockDataSource.createExpense(
            tripId: null,
            title: 'Dinner',
            description: null,
            amount: 100.0,
            category: null,
            paidBy: 'user-123',
            splitWith: ['user-123', 'user-456'],
            splitType: 'percentage',
            transactionDate: null,
          )).called(1);
        });
      });

      group('Negative Cases', () {
        test('should throw exception when datasource fails', () async {
          // Arrange
          when(mockDataSource.createExpense(
            tripId: anyNamed('tripId'),
            title: anyNamed('title'),
            description: anyNamed('description'),
            amount: anyNamed('amount'),
            category: anyNamed('category'),
            paidBy: anyNamed('paidBy'),
            splitWith: anyNamed('splitWith'),
            splitType: anyNamed('splitType'),
            transactionDate: anyNamed('transactionDate'),
          )).thenThrow(Exception('Database error'));

          // Act & Assert
          expect(
            () => repository.createExpense(
              title: 'Dinner',
              amount: 150.0,
              paidBy: 'user-123',
              splitWith: ['user-123'],
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to create expense'),
            )),
          );
        });
      });
    });

    group('updateExpense', () {
      group('Positive Cases', () {
        test('should update expense title', () async {
          // Arrange
          final updatedExpense = testExpense.copyWith(title: 'Updated Dinner');
          when(mockDataSource.updateExpense(
            expenseId: anyNamed('expenseId'),
            title: anyNamed('title'),
            description: anyNamed('description'),
            amount: anyNamed('amount'),
            category: anyNamed('category'),
            transactionDate: anyNamed('transactionDate'),
          )).thenAnswer((_) async => updatedExpense);

          // Act
          final result = await repository.updateExpense(
            expenseId: 'expense-123',
            title: 'Updated Dinner',
          );

          // Assert
          expect(result.title, 'Updated Dinner');
          verify(mockDataSource.updateExpense(
            expenseId: 'expense-123',
            title: 'Updated Dinner',
            description: null,
            amount: null,
            category: null,
            transactionDate: null,
          )).called(1);
        });

        test('should update expense amount', () async {
          // Arrange
          final updatedExpense = testExpense.copyWith(amount: 200.0);
          when(mockDataSource.updateExpense(
            expenseId: anyNamed('expenseId'),
            title: anyNamed('title'),
            description: anyNamed('description'),
            amount: anyNamed('amount'),
            category: anyNamed('category'),
            transactionDate: anyNamed('transactionDate'),
          )).thenAnswer((_) async => updatedExpense);

          // Act
          final result = await repository.updateExpense(
            expenseId: 'expense-123',
            amount: 200.0,
          );

          // Assert
          expect(result.amount, 200.0);
        });

        test('should update multiple fields', () async {
          // Arrange
          final updatedExpense = testExpense.copyWith(
            title: 'Updated',
            amount: 300.0,
            category: 'Entertainment',
          );
          when(mockDataSource.updateExpense(
            expenseId: anyNamed('expenseId'),
            title: anyNamed('title'),
            description: anyNamed('description'),
            amount: anyNamed('amount'),
            category: anyNamed('category'),
            transactionDate: anyNamed('transactionDate'),
          )).thenAnswer((_) async => updatedExpense);

          // Act
          final result = await repository.updateExpense(
            expenseId: 'expense-123',
            title: 'Updated',
            amount: 300.0,
            category: 'Entertainment',
          );

          // Assert
          expect(result.title, 'Updated');
          expect(result.amount, 300.0);
          expect(result.category, 'Entertainment');
        });
      });

      group('Negative Cases', () {
        test('should throw exception when expense not found', () async {
          // Arrange
          when(mockDataSource.updateExpense(
            expenseId: anyNamed('expenseId'),
            title: anyNamed('title'),
            description: anyNamed('description'),
            amount: anyNamed('amount'),
            category: anyNamed('category'),
            transactionDate: anyNamed('transactionDate'),
          )).thenThrow(Exception('Expense not found'));

          // Act & Assert
          expect(
            () => repository.updateExpense(
              expenseId: 'non-existent',
              title: 'Updated',
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to update expense'),
            )),
          );
        });
      });
    });

    group('deleteExpense', () {
      group('Positive Cases', () {
        test('should delete expense successfully', () async {
          // Arrange
          when(mockDataSource.deleteExpense('expense-123')).thenAnswer(
            (_) async {
              return;
            },
          );

          // Act
          await repository.deleteExpense('expense-123');

          // Assert
          verify(mockDataSource.deleteExpense('expense-123')).called(1);
        });
      });

      group('Negative Cases', () {
        test('should throw exception when expense not found', () async {
          // Arrange
          when(mockDataSource.deleteExpense('non-existent')).thenThrow(
            Exception('Expense not found'),
          );

          // Act & Assert
          expect(
            () => repository.deleteExpense('non-existent'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to delete expense'),
            )),
          );
        });

        test('should throw exception for permission denied', () async {
          // Arrange
          when(mockDataSource.deleteExpense('expense-123')).thenThrow(
            Exception('Permission denied'),
          );

          // Act & Assert
          expect(
            () => repository.deleteExpense('expense-123'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to delete expense'),
            )),
          );
        });
      });
    });

    group('getBalances', () {
      group('Positive Cases', () {
        test('should return balances for trip', () async {
          // Arrange
          when(mockDataSource.getBalances(
            tripId: anyNamed('tripId'),
            userId: anyNamed('userId'),
          )).thenAnswer((_) async => [testBalanceSummary]);

          // Act
          final result = await repository.getBalances(tripId: 'trip-123');

          // Assert
          expect(result.length, 1);
          expect(result.first.userId, 'user-123');
          expect(result.first.balance, 75.0);
          verify(mockDataSource.getBalances(tripId: 'trip-123', userId: null))
              .called(1);
        });

        test('should return balances for user', () async {
          // Arrange
          when(mockDataSource.getBalances(
            tripId: anyNamed('tripId'),
            userId: anyNamed('userId'),
          )).thenAnswer((_) async => [testBalanceSummary]);

          // Act
          final result = await repository.getBalances(userId: 'user-123');

          // Assert
          expect(result.length, 1);
          verify(mockDataSource.getBalances(tripId: null, userId: 'user-123'))
              .called(1);
        });

        test('should return empty list when no balances', () async {
          // Arrange
          when(mockDataSource.getBalances(
            tripId: anyNamed('tripId'),
            userId: anyNamed('userId'),
          )).thenAnswer((_) async => []);

          // Act
          final result = await repository.getBalances(tripId: 'trip-123');

          // Assert
          expect(result, isEmpty);
        });

        test('should return multiple balances', () async {
          // Arrange
          final balance2 = BalanceSummary(
            userId: 'user-456',
            userName: 'Another User',
            totalPaid: 50.0,
            totalOwed: 125.0,
            balance: -75.0,
          );
          when(mockDataSource.getBalances(
            tripId: anyNamed('tripId'),
            userId: anyNamed('userId'),
          )).thenAnswer((_) async => [testBalanceSummary, balance2]);

          // Act
          final result = await repository.getBalances(tripId: 'trip-123');

          // Assert
          expect(result.length, 2);
          expect(result[0].balance, 75.0);
          expect(result[1].balance, -75.0);
        });
      });

      group('Negative Cases', () {
        test('should throw exception when datasource fails', () async {
          // Arrange
          when(mockDataSource.getBalances(
            tripId: anyNamed('tripId'),
            userId: anyNamed('userId'),
          )).thenThrow(Exception('Database error'));

          // Act & Assert
          expect(
            () => repository.getBalances(tripId: 'trip-123'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to get balances'),
            )),
          );
        });
      });
    });

    group('createSettlement', () {
      group('Positive Cases', () {
        test('should create settlement with all parameters', () async {
          // Arrange
          when(mockDataSource.createSettlement(
            tripId: anyNamed('tripId'),
            fromUser: anyNamed('fromUser'),
            toUser: anyNamed('toUser'),
            amount: anyNamed('amount'),
            paymentMethod: anyNamed('paymentMethod'),
          )).thenAnswer((_) async => testSettlement);

          // Act
          final result = await repository.createSettlement(
            tripId: 'trip-123',
            fromUser: 'user-456',
            toUser: 'user-123',
            amount: 75.0,
            paymentMethod: 'cash',
          );

          // Assert
          expect(result.id, testSettlement.id);
          expect(result.amount, 75.0);
          verify(mockDataSource.createSettlement(
            tripId: 'trip-123',
            fromUser: 'user-456',
            toUser: 'user-123',
            amount: 75.0,
            paymentMethod: 'cash',
          )).called(1);
        });

        test('should create settlement without tripId', () async {
          // Arrange
          final standaloneSettlement = SettlementModel(
            id: 'settlement-456',
            fromUser: 'user-456',
            toUser: 'user-123',
            amount: 50.0,
            status: 'pending',
            createdAt: now,
          );
          when(mockDataSource.createSettlement(
            tripId: anyNamed('tripId'),
            fromUser: anyNamed('fromUser'),
            toUser: anyNamed('toUser'),
            amount: anyNamed('amount'),
            paymentMethod: anyNamed('paymentMethod'),
          )).thenAnswer((_) async => standaloneSettlement);

          // Act
          final result = await repository.createSettlement(
            fromUser: 'user-456',
            toUser: 'user-123',
            amount: 50.0,
          );

          // Assert
          expect(result.tripId, isNull);
          verify(mockDataSource.createSettlement(
            tripId: null,
            fromUser: 'user-456',
            toUser: 'user-123',
            amount: 50.0,
            paymentMethod: null,
          )).called(1);
        });
      });

      group('Negative Cases', () {
        test('should throw exception when datasource fails', () async {
          // Arrange
          when(mockDataSource.createSettlement(
            tripId: anyNamed('tripId'),
            fromUser: anyNamed('fromUser'),
            toUser: anyNamed('toUser'),
            amount: anyNamed('amount'),
            paymentMethod: anyNamed('paymentMethod'),
          )).thenThrow(Exception('Database error'));

          // Act & Assert
          expect(
            () => repository.createSettlement(
              fromUser: 'user-456',
              toUser: 'user-123',
              amount: 75.0,
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to create settlement'),
            )),
          );
        });
      });
    });

    group('getSettlements', () {
      group('Positive Cases', () {
        test('should return settlements for trip', () async {
          // Arrange
          when(mockDataSource.getSettlements(
            tripId: anyNamed('tripId'),
            userId: anyNamed('userId'),
          )).thenAnswer((_) async => [testSettlement]);

          // Act
          final result = await repository.getSettlements(tripId: 'trip-123');

          // Assert
          expect(result.length, 1);
          expect(result.first.tripId, 'trip-123');
          verify(mockDataSource.getSettlements(tripId: 'trip-123', userId: null))
              .called(1);
        });

        test('should return settlements for user', () async {
          // Arrange
          when(mockDataSource.getSettlements(
            tripId: anyNamed('tripId'),
            userId: anyNamed('userId'),
          )).thenAnswer((_) async => [testSettlement]);

          // Act
          final result = await repository.getSettlements(userId: 'user-123');

          // Assert
          expect(result.length, 1);
          verify(mockDataSource.getSettlements(tripId: null, userId: 'user-123'))
              .called(1);
        });

        test('should return empty list when no settlements', () async {
          // Arrange
          when(mockDataSource.getSettlements(
            tripId: anyNamed('tripId'),
            userId: anyNamed('userId'),
          )).thenAnswer((_) async => []);

          // Act
          final result = await repository.getSettlements(tripId: 'trip-123');

          // Assert
          expect(result, isEmpty);
        });
      });

      group('Negative Cases', () {
        test('should throw exception when datasource fails', () async {
          // Arrange
          when(mockDataSource.getSettlements(
            tripId: anyNamed('tripId'),
            userId: anyNamed('userId'),
          )).thenThrow(Exception('Database error'));

          // Act & Assert
          expect(
            () => repository.getSettlements(tripId: 'trip-123'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to get settlements'),
            )),
          );
        });
      });
    });

    group('updateSettlementStatus', () {
      group('Positive Cases', () {
        test('should update settlement status to confirmed', () async {
          // Arrange
          final updatedSettlement = SettlementModel(
            id: 'settlement-123',
            tripId: 'trip-123',
            fromUser: 'user-456',
            toUser: 'user-123',
            amount: 75.0,
            status: 'confirmed',
            createdAt: now,
          );
          when(mockDataSource.updateSettlementStatus(
            settlementId: anyNamed('settlementId'),
            status: anyNamed('status'),
            paymentProofUrl: anyNamed('paymentProofUrl'),
          )).thenAnswer((_) async => updatedSettlement);

          // Act
          final result = await repository.updateSettlementStatus(
            settlementId: 'settlement-123',
            status: 'confirmed',
          );

          // Assert
          expect(result.status, 'confirmed');
          verify(mockDataSource.updateSettlementStatus(
            settlementId: 'settlement-123',
            status: 'confirmed',
            paymentProofUrl: null,
          )).called(1);
        });

        test('should update settlement with payment proof', () async {
          // Arrange
          final updatedSettlement = SettlementModel(
            id: 'settlement-123',
            tripId: 'trip-123',
            fromUser: 'user-456',
            toUser: 'user-123',
            amount: 75.0,
            status: 'confirmed',
            paymentProofUrl: 'https://example.com/proof.jpg',
            createdAt: now,
          );
          when(mockDataSource.updateSettlementStatus(
            settlementId: anyNamed('settlementId'),
            status: anyNamed('status'),
            paymentProofUrl: anyNamed('paymentProofUrl'),
          )).thenAnswer((_) async => updatedSettlement);

          // Act
          final result = await repository.updateSettlementStatus(
            settlementId: 'settlement-123',
            status: 'confirmed',
            paymentProofUrl: 'https://example.com/proof.jpg',
          );

          // Assert
          expect(result.paymentProofUrl, 'https://example.com/proof.jpg');
        });
      });

      group('Negative Cases', () {
        test('should throw exception when settlement not found', () async {
          // Arrange
          when(mockDataSource.updateSettlementStatus(
            settlementId: anyNamed('settlementId'),
            status: anyNamed('status'),
            paymentProofUrl: anyNamed('paymentProofUrl'),
          )).thenThrow(Exception('Settlement not found'));

          // Act & Assert
          expect(
            () => repository.updateSettlementStatus(
              settlementId: 'non-existent',
              status: 'confirmed',
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to update settlement'),
            )),
          );
        });
      });
    });

    group('watchTripExpenses', () {
      group('Positive Cases', () {
        test('should return stream of trip expenses', () {
          // Arrange
          when(mockDataSource.watchTripExpenses('trip-123')).thenAnswer(
            (_) => Stream.value([testExpenseWithSplits]),
          );

          // Act
          final result = repository.watchTripExpenses('trip-123');

          // Assert
          expect(result, isA<Stream<List<ExpenseWithSplits>>>());
          verify(mockDataSource.watchTripExpenses('trip-123')).called(1);
        });

        test('should emit expenses from stream', () async {
          // Arrange
          when(mockDataSource.watchTripExpenses('trip-123')).thenAnswer(
            (_) => Stream.value([testExpenseWithSplits]),
          );

          // Act
          final stream = repository.watchTripExpenses('trip-123');
          final result = await stream.first;

          // Assert
          expect(result.length, 1);
          expect(result.first.expense.title, 'Dinner');
        });
      });

      group('Negative Cases', () {
        test('should throw exception when datasource throws', () {
          // Arrange
          when(mockDataSource.watchTripExpenses('trip-123')).thenThrow(
            Exception('Stream error'),
          );

          // Act & Assert
          expect(
            () => repository.watchTripExpenses('trip-123'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to watch trip expenses'),
            )),
          );
        });
      });
    });

    group('watchUserExpenses', () {
      group('Positive Cases', () {
        test('should return stream of user expenses', () {
          // Arrange
          when(mockDataSource.watchUserExpenses()).thenAnswer(
            (_) => Stream.value([testExpenseWithSplits]),
          );

          // Act
          final result = repository.watchUserExpenses();

          // Assert
          expect(result, isA<Stream<List<ExpenseWithSplits>>>());
          verify(mockDataSource.watchUserExpenses()).called(1);
        });

        test('should emit expenses from stream', () async {
          // Arrange
          when(mockDataSource.watchUserExpenses()).thenAnswer(
            (_) => Stream.value([testExpenseWithSplits]),
          );

          // Act
          final stream = repository.watchUserExpenses();
          final result = await stream.first;

          // Assert
          expect(result.length, 1);
          expect(result.first.expense.id, 'expense-123');
        });
      });

      group('Negative Cases', () {
        test('should throw exception when datasource throws', () {
          // Arrange
          when(mockDataSource.watchUserExpenses()).thenThrow(
            Exception('Stream error'),
          );

          // Act & Assert
          expect(
            () => repository.watchUserExpenses(),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to watch user expenses'),
            )),
          );
        });
      });
    });

    group('Edge Cases', () {
      test('should handle expense with zero amount', () async {
        // Arrange
        final zeroExpense = testExpense.copyWith(amount: 0.0);
        final zeroExpenseWithSplits = ExpenseWithSplits(
          expense: zeroExpense,
          splits: [],
        );
        when(mockDataSource.getTripExpenses('trip-123')).thenAnswer(
          (_) async => [zeroExpenseWithSplits],
        );

        // Act
        final result = await repository.getTripExpenses('trip-123');

        // Assert
        expect(result.first.expense.amount, 0.0);
      });

      test('should handle expense with large amount', () async {
        // Arrange
        final largeExpense = testExpense.copyWith(amount: 999999999.99);
        final largeExpenseWithSplits = ExpenseWithSplits(
          expense: largeExpense,
          splits: [],
        );
        when(mockDataSource.getTripExpenses('trip-123')).thenAnswer(
          (_) async => [largeExpenseWithSplits],
        );

        // Act
        final result = await repository.getTripExpenses('trip-123');

        // Assert
        expect(result.first.expense.amount, 999999999.99);
      });

      test('should handle expense with many splits', () async {
        // Arrange
        final manySplits = List.generate(
          10,
          (i) => ExpenseSplitModel(
            id: 'split-$i',
            expenseId: 'expense-123',
            userId: 'user-$i',
            amount: 15.0,
            isSettled: false,
            createdAt: now,
            userName: 'User $i',
          ),
        );
        final expenseWithManySplits = ExpenseWithSplits(
          expense: testExpense,
          splits: manySplits,
        );
        when(mockDataSource.getTripExpenses('trip-123')).thenAnswer(
          (_) async => [expenseWithManySplits],
        );

        // Act
        final result = await repository.getTripExpenses('trip-123');

        // Assert
        expect(result.first.splits.length, 10);
      });

      test('should handle negative balance', () async {
        // Arrange
        final negativeBalance = BalanceSummary(
          userId: 'user-456',
          userName: 'Debtor User',
          totalPaid: 0.0,
          totalOwed: 100.0,
          balance: -100.0,
        );
        when(mockDataSource.getBalances(
          tripId: anyNamed('tripId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => [negativeBalance]);

        // Act
        final result = await repository.getBalances(tripId: 'trip-123');

        // Assert
        expect(result.first.balance, -100.0);
      });
    });
  });
}
