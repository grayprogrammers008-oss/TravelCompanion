import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/shared/models/expense_model.dart';
import 'package:travel_crew/features/expenses/domain/repositories/expense_repository.dart';
import 'package:travel_crew/features/expenses/domain/usecases/create_expense_usecase.dart';

// Mock will be generated with: flutter pub run build_runner build
import 'create_expense_usecase_test.mocks.dart';

@GenerateMocks([ExpenseRepository])
void main() {
  late CreateExpenseUseCase useCase;
  late MockExpenseRepository mockExpenseRepository;

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    useCase = CreateExpenseUseCase(mockExpenseRepository);
  });

  const testTripId = 'trip123';
  const testTitle = 'Dinner';
  const testDescription = 'Dinner at restaurant';
  const testAmount = 100.0;
  const testCategory = 'Food';
  const testPaidBy = 'user123';
  const testSplitMembers = ['user123', 'user456'];

  final testExpense = ExpenseModel(
    id: 'expense123',
    tripId: testTripId,
    title: testTitle,
    description: testDescription,
    amount: testAmount,
    category: testCategory,
    paidBy: testPaidBy,
    splitType: 'equal',
    transactionDate: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('CreateExpenseUseCase', () {
    test('should create expense with valid data', () async {
      // Arrange
      when(mockExpenseRepository.createExpense(
        tripId: testTripId,
        title: testTitle,
        description: testDescription,
        amount: testAmount,
        category: testCategory,
        paidBy: testPaidBy,
        splitWith: testSplitMembers,
        splitType: 'equal',
        transactionDate: anyNamed('transactionDate'),
      )).thenAnswer((_) async => testExpense);

      // Act
      final result = await useCase(
        tripId: testTripId,
        title: testTitle,
        description: testDescription,
        amount: testAmount,
        category: testCategory,
        paidBy: testPaidBy,
        splitWith: testSplitMembers,
      );

      // Assert
      expect(result, equals(testExpense));
      verify(mockExpenseRepository.createExpense(
        tripId: testTripId,
        title: testTitle,
        description: testDescription,
        amount: testAmount,
        category: testCategory,
        paidBy: testPaidBy,
        splitWith: testSplitMembers,
        splitType: 'equal',
        transactionDate: anyNamed('transactionDate'),
      )).called(1);
    });

    test('should throw exception when title is empty', () async {
      // Arrange & Act & Assert
      expect(
        () => useCase(
          tripId: testTripId,
          title: '',
          description: testDescription,
          amount: testAmount,
          category: testCategory,
          paidBy: testPaidBy,
          splitWith: testSplitMembers,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception when amount is zero or negative', () async {
      // Arrange & Act & Assert
      expect(
        () => useCase(
          tripId: testTripId,
          title: testTitle,
          description: testDescription,
          amount: 0,
          category: testCategory,
          paidBy: testPaidBy,
          splitWith: testSplitMembers,
        ),
        throwsA(isA<Exception>()),
      );

      expect(
        () => useCase(
          tripId: testTripId,
          title: testTitle,
          description: testDescription,
          amount: -10,
          category: testCategory,
          paidBy: testPaidBy,
          splitWith: testSplitMembers,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception when split members list is empty', () async {
      // Arrange & Act & Assert
      expect(
        () => useCase(
          tripId: testTripId,
          title: testTitle,
          description: testDescription,
          amount: testAmount,
          category: testCategory,
          paidBy: testPaidBy,
          splitWith: [],
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception when paidBy is empty', () async {
      // Arrange & Act & Assert
      expect(
        () => useCase(
          tripId: testTripId,
          title: testTitle,
          description: testDescription,
          amount: testAmount,
          category: testCategory,
          paidBy: '',
          splitWith: testSplitMembers,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
