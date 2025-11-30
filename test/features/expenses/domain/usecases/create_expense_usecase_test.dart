import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/expenses/domain/repositories/expense_repository.dart';
import 'package:travel_crew/features/expenses/domain/usecases/create_expense_usecase.dart';
import 'package:travel_crew/shared/models/expense_model.dart';

@GenerateMocks([ExpenseRepository])
import 'create_expense_usecase_test.mocks.dart';

void main() {
  late CreateExpenseUseCase useCase;
  late MockExpenseRepository mockRepository;

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = CreateExpenseUseCase(mockRepository);
  });

  final testExpense = ExpenseModel(
    id: 'expense-1',
    tripId: 'trip-1',
    title: 'Dinner',
    amount: 1500.0,
    currency: 'INR',
    category: 'food',
    paidBy: 'user-1',
    splitType: 'equal',
    createdAt: DateTime.now(),
  );

  group('CreateExpenseUseCase', () {
    group('positive cases', () {
      test('should create expense with valid data', () async {
        // Arrange
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
        )).thenAnswer((_) async => testExpense);

        // Act
        final result = await useCase(
          tripId: 'trip-1',
          title: 'Dinner',
          amount: 1500.0,
          category: 'food',
          paidBy: 'user-1',
          splitWith: ['user-1', 'user-2'],
        );

        // Assert
        expect(result.id, testExpense.id);
        expect(result.title, testExpense.title);
        verify(mockRepository.createExpense(
          tripId: 'trip-1',
          title: 'Dinner',
          description: null,
          amount: 1500.0,
          category: 'food',
          paidBy: 'user-1',
          splitWith: ['user-1', 'user-2'],
          splitType: 'equal',
          transactionDate: null,
        )).called(1);
      });

      test('should create expense without tripId (standalone)', () async {
        // Arrange
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
        )).thenAnswer((_) async => testExpense);

        // Act
        final result = await useCase(
          title: 'Lunch',
          amount: 500.0,
          paidBy: 'user-1',
          splitWith: ['user-1'],
        );

        // Assert
        expect(result, isNotNull);
        verify(mockRepository.createExpense(
          tripId: null,
          title: 'Lunch',
          description: null,
          amount: 500.0,
          category: null,
          paidBy: 'user-1',
          splitWith: ['user-1'],
          splitType: 'equal',
          transactionDate: null,
        )).called(1);
      });

      test('should create expense with custom split type', () async {
        // Arrange
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
        )).thenAnswer((_) async => testExpense);

        // Act
        await useCase(
          title: 'Hotel',
          amount: 10000.0,
          paidBy: 'user-1',
          splitWith: ['user-1', 'user-2', 'user-3'],
          splitType: 'percentage',
        );

        // Assert
        verify(mockRepository.createExpense(
          tripId: null,
          title: 'Hotel',
          description: null,
          amount: 10000.0,
          category: null,
          paidBy: 'user-1',
          splitWith: ['user-1', 'user-2', 'user-3'],
          splitType: 'percentage',
          transactionDate: null,
        )).called(1);
      });

      test('should create expense with transaction date', () async {
        // Arrange
        final transactionDate = DateTime(2024, 1, 15);
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
        )).thenAnswer((_) async => testExpense);

        // Act
        await useCase(
          title: 'Shopping',
          amount: 2000.0,
          paidBy: 'user-1',
          splitWith: ['user-1', 'user-2'],
          transactionDate: transactionDate,
        );

        // Assert
        verify(mockRepository.createExpense(
          tripId: null,
          title: 'Shopping',
          description: null,
          amount: 2000.0,
          category: null,
          paidBy: 'user-1',
          splitWith: ['user-1', 'user-2'],
          splitType: 'equal',
          transactionDate: transactionDate,
        )).called(1);
      });

      test('should create expense with description', () async {
        // Arrange
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
        )).thenAnswer((_) async => testExpense);

        // Act
        await useCase(
          title: 'Taxi',
          description: 'Airport to hotel transfer',
          amount: 800.0,
          paidBy: 'user-1',
          splitWith: ['user-1', 'user-2'],
        );

        // Assert
        verify(mockRepository.createExpense(
          tripId: null,
          title: 'Taxi',
          description: 'Airport to hotel transfer',
          amount: 800.0,
          category: null,
          paidBy: 'user-1',
          splitWith: ['user-1', 'user-2'],
          splitType: 'equal',
          transactionDate: null,
        )).called(1);
      });
    });

    group('negative cases', () {
      test('should throw exception for empty title', () async {
        // Act & Assert
        expect(
          () => useCase(
            title: '',
            amount: 1500.0,
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
          tripId: anyNamed('tripId'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          amount: anyNamed('amount'),
          category: anyNamed('category'),
          paidBy: anyNamed('paidBy'),
          splitWith: anyNamed('splitWith'),
          splitType: anyNamed('splitType'),
          transactionDate: anyNamed('transactionDate'),
        ));
      });

      test('should throw exception for whitespace-only title', () async {
        // Act & Assert
        expect(
          () => useCase(
            title: '   ',
            amount: 1500.0,
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
            title: 'Dinner',
            amount: 0,
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
            title: 'Dinner',
            amount: -100,
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
            title: 'Dinner',
            amount: 1500.0,
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

      test('should propagate repository exception', () async {
        // Arrange
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
        )).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => useCase(
            title: 'Dinner',
            amount: 1500.0,
            paidBy: 'user-1',
            splitWith: ['user-1'],
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Database error'),
          )),
        );
      });
    });
  });
}
