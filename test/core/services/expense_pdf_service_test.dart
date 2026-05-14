// Tests for ExpensePdfService.
//
// Exercises the PDF byte generation (does not assert against pixel-perfect
// output, but verifies that the service produces a non-empty %PDF document
// for representative inputs and handles edge cases gracefully).

import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/core/services/expense_pdf_service.dart';
import 'package:pathio/shared/models/expense_model.dart';
import 'package:pathio/shared/models/trip_model.dart';

TripModel _trip({
  String name = 'Bali Trip',
  String? destination = 'Bali',
  DateTime? start,
  DateTime? end,
  String currency = 'INR',
}) {
  return TripModel(
    id: 't1',
    name: name,
    destination: destination,
    startDate: start ?? DateTime(2024, 6, 1),
    endDate: end ?? DateTime(2024, 6, 7),
    createdBy: 'user-1',
    currency: currency,
  );
}

ExpenseModel _expense({
  String id = 'e',
  double amount = 100,
  String category = 'food',
  String? payer = 'Alice',
  DateTime? date,
  String currency = 'INR',
  String title = 'Lunch',
}) {
  return ExpenseModel(
    id: id,
    title: title,
    amount: amount,
    currency: currency,
    category: category,
    paidBy: 'user-1',
    payerName: payer,
    transactionDate: date ?? DateTime(2024, 6, 1),
  );
}

bool _isPdfBytes(List<int> bytes) {
  if (bytes.length < 4) return false;
  return bytes[0] == 0x25 && // %
      bytes[1] == 0x50 && // P
      bytes[2] == 0x44 && // D
      bytes[3] == 0x46; // F
}

void main() {
  group('ExpensePdfService.generateExpenseReport', () {
    test('produces a non-empty PDF with no expenses', () async {
      final bytes = await ExpensePdfService.generateExpenseReport(
        trip: _trip(),
        expenses: const [],
      );
      expect(bytes, isNotEmpty);
      expect(_isPdfBytes(bytes), isTrue);
    });

    test('produces a PDF with single expense', () async {
      final bytes = await ExpensePdfService.generateExpenseReport(
        trip: _trip(),
        expenses: [_expense()],
      );
      expect(bytes, isNotEmpty);
      expect(_isPdfBytes(bytes), isTrue);
    });

    test('handles multiple categories and payers', () async {
      final bytes = await ExpensePdfService.generateExpenseReport(
        trip: _trip(),
        expenses: [
          _expense(id: 'a', category: 'food', payer: 'Alice', amount: 200),
          _expense(id: 'b', category: 'transport', payer: 'Bob', amount: 150),
          _expense(id: 'c', category: 'stay', payer: 'Charlie', amount: 800),
          _expense(id: 'd', category: 'activities', payer: 'Alice', amount: 75),
          _expense(id: 'e', category: 'shopping', payer: 'Bob', amount: 100),
          _expense(id: 'f', category: 'other', payer: 'Charlie', amount: 25),
        ],
      );
      expect(_isPdfBytes(bytes), isTrue);
    });

    test('includes budget when provided', () async {
      final bytes = await ExpensePdfService.generateExpenseReport(
        trip: _trip(),
        expenses: [_expense(amount: 500)],
        budget: 1000,
      );
      expect(_isPdfBytes(bytes), isTrue);
    });

    test('handles over-budget scenario', () async {
      final bytes = await ExpensePdfService.generateExpenseReport(
        trip: _trip(),
        expenses: [_expense(amount: 2000)],
        budget: 1000,
      );
      expect(_isPdfBytes(bytes), isTrue);
    });

    test('handles trip with only start date', () async {
      final bytes = await ExpensePdfService.generateExpenseReport(
        trip: TripModel(
          id: 't',
          name: 'X',
          createdBy: 'u',
          startDate: DateTime(2024, 1, 1),
        ),
        expenses: [_expense()],
      );
      expect(_isPdfBytes(bytes), isTrue);
    });

    test('handles trip with no dates', () async {
      final bytes = await ExpensePdfService.generateExpenseReport(
        trip: TripModel(id: 't', name: 'X', createdBy: 'u'),
        expenses: [_expense()],
      );
      expect(_isPdfBytes(bytes), isTrue);
    });

    test('handles trip with no destination', () async {
      final bytes = await ExpensePdfService.generateExpenseReport(
        trip: _trip(destination: null),
        expenses: [_expense()],
      );
      expect(_isPdfBytes(bytes), isTrue);
    });

    test('renders different currency symbols correctly', () async {
      for (final cur in ['INR', 'USD', 'EUR', 'GBP', 'SGD', 'MYR', 'THB', 'JPY']) {
        final bytes = await ExpensePdfService.generateExpenseReport(
          trip: _trip(currency: cur),
          expenses: [_expense(currency: cur)],
        );
        expect(_isPdfBytes(bytes), isTrue, reason: 'should render $cur');
      }
    });

    test('handles unknown payer name', () async {
      final bytes = await ExpensePdfService.generateExpenseReport(
        trip: _trip(),
        expenses: [
          _expense(payer: null), // Falls back to 'Unknown'
          _expense(id: 'b', payer: 'Bob'),
        ],
      );
      expect(_isPdfBytes(bytes), isTrue);
    });

    test('handles single payer (no settlement section)', () async {
      final bytes = await ExpensePdfService.generateExpenseReport(
        trip: _trip(),
        expenses: [
          _expense(id: 'a', payer: 'Solo', amount: 100),
          _expense(id: 'b', payer: 'Solo', amount: 200),
        ],
      );
      expect(_isPdfBytes(bytes), isTrue);
    });

    test('handles missing transaction dates and falls back to createdAt',
        () async {
      final bytes = await ExpensePdfService.generateExpenseReport(
        trip: _trip(),
        expenses: [
          ExpenseModel(
            id: 'a',
            title: 'X',
            amount: 100,
            paidBy: 'u',
            payerName: 'Alice',
            createdAt: DateTime(2024, 1, 1),
          ),
        ],
      );
      expect(_isPdfBytes(bytes), isTrue);
    });

    test('handles expenses with no category (defaults to other)', () async {
      final bytes = await ExpensePdfService.generateExpenseReport(
        trip: _trip(),
        expenses: [
          ExpenseModel(
            id: 'a',
            title: 'X',
            amount: 100,
            paidBy: 'u',
            payerName: 'A',
            // No category
          ),
        ],
      );
      expect(_isPdfBytes(bytes), isTrue);
    });

    test('handles unknown category gracefully', () async {
      final bytes = await ExpensePdfService.generateExpenseReport(
        trip: _trip(),
        expenses: [_expense(category: 'random_unknown_category')],
      );
      expect(_isPdfBytes(bytes), isTrue);
    });

    test('renders very large amounts (Cr/Lakh formatting)', () async {
      final bytes = await ExpensePdfService.generateExpenseReport(
        trip: _trip(),
        expenses: [
          _expense(amount: 50000000), // 5 Cr
          _expense(id: 'b', amount: 200000), // 2 L
          _expense(id: 'c', amount: 5000), // formatted with commas
          _expense(id: 'd', amount: 99), // simple decimal
        ],
      );
      expect(_isPdfBytes(bytes), isTrue);
    });

    test('settlement triggers when payers have unequal totals', () async {
      // Alice paid 300, Bob paid 0, Charlie paid 0 => Alice is owed money.
      final bytes = await ExpensePdfService.generateExpenseReport(
        trip: _trip(),
        expenses: [
          _expense(id: 'a', payer: 'Alice', amount: 300),
          // Bob and Charlie spent 0 but show up via... hmm, only payers in
          // payerTotals. To force settlement we use 3 different payers with
          // unequal values.
          _expense(id: 'b', payer: 'Bob', amount: 100),
          _expense(id: 'c', payer: 'Charlie', amount: 50),
        ],
      );
      expect(_isPdfBytes(bytes), isTrue);
    });
  });
}
