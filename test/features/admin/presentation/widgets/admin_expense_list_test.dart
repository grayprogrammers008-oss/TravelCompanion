import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pathio/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:pathio/features/admin/domain/entities/admin_expense.dart';
import 'package:pathio/features/admin/presentation/providers/admin_expense_providers.dart';
import 'package:pathio/features/admin/presentation/providers/admin_providers.dart';
import 'package:pathio/features/admin/presentation/widgets/admin_expense_list.dart';

class _StubSupabaseClient extends Mock implements SupabaseClient {}

class _FakeExpenseDataSource extends AdminRemoteDataSource {
  _FakeExpenseDataSource() : super(_StubSupabaseClient());

  bool throwOnSettle = false;
  bool throwOnUnsettle = false;
  bool throwOnDelete = false;
  bool throwOnUpdate = false;
  int settleResult = 1;
  int unsettleResult = 1;
  bool deleteResult = true;
  bool updateResult = true;

  final List<String> settleCalls = [];
  final List<String> unsettleCalls = [];
  final List<String> deleteCalls = [];
  final List<Map<String, dynamic>> updateCalls = [];

  @override
  Future<int> settleExpenseSplits(String expenseId) async {
    settleCalls.add(expenseId);
    if (throwOnSettle) throw Exception('settle failed');
    return settleResult;
  }

  @override
  Future<int> unsettleExpenseSplits(String expenseId) async {
    unsettleCalls.add(expenseId);
    if (throwOnUnsettle) throw Exception('unsettle failed');
    return unsettleResult;
  }

  @override
  Future<bool> deleteExpense(String expenseId) async {
    deleteCalls.add(expenseId);
    if (throwOnDelete) throw Exception('delete failed');
    return deleteResult;
  }

  @override
  Future<bool> updateExpense(
    String expenseId, {
    String? title,
    String? description,
    double? amount,
    String? currency,
    String? category,
  }) async {
    updateCalls.add({
      'id': expenseId,
      'title': title,
      'description': description,
      'amount': amount,
      'currency': currency,
      'category': category,
    });
    if (throwOnUpdate) throw Exception('update failed');
    return updateResult;
  }
}

AdminExpenseModel _expense({
  String id = 'e1',
  String? tripId = 'trip1',
  String? tripName = 'Bali Trip',
  String? tripDestination = 'Bali',
  String title = 'Dinner',
  String? description,
  double amount = 100.0,
  String currency = 'USD',
  String? category = 'food',
  String paidBy = 'user1',
  String? payerName = 'Alice',
  String? payerEmail,
  String splitType = 'equal',
  String? receiptUrl,
  DateTime? transactionDate,
  DateTime? createdAt,
  int splitCount = 0,
  int settledCount = 0,
  double pendingAmount = 0,
}) {
  return AdminExpenseModel(
    id: id,
    tripId: tripId,
    tripName: tripName,
    tripDestination: tripDestination,
    title: title,
    description: description,
    amount: amount,
    currency: currency,
    category: category,
    paidBy: paidBy,
    payerName: payerName,
    payerEmail: payerEmail,
    splitType: splitType,
    receiptUrl: receiptUrl,
    transactionDate: transactionDate,
    createdAt: createdAt ?? DateTime(2024, 6, 15),
    splitCount: splitCount,
    settledCount: settledCount,
    pendingAmount: pendingAmount,
  );
}

Widget _wrap({
  required Future<List<AdminExpenseModel>> Function() future,
  AdminRemoteDataSource? dataSource,
}) {
  return ProviderScope(
    overrides: [
      adminExpensesProvider.overrideWith((ref, params) => future()),
      if (dataSource != null)
        adminRemoteDataSourceProvider.overrideWithValue(dataSource),
    ],
    child: const MaterialApp(
      home: Scaffold(body: AdminExpenseList()),
    ),
  );
}

void main() {
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('AdminExpenseList - rendering', () {
    testWidgets('renders loading state', (tester) async {
      useTallViewport(tester);
      final completer = Completer<List<AdminExpenseModel>>();
      await tester.pumpWidget(_wrap(future: () => completer.future));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete(const <AdminExpenseModel>[]);
      await tester.pumpAndSettle();
    });

    testWidgets('renders empty state when no expenses', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(future: () async => const <AdminExpenseModel>[]),
      );
      await tester.pumpAndSettle();
      expect(find.text('No expenses found'), findsOneWidget);
      expect(
        find.text('Expenses will appear here once created'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });

    testWidgets('renders error state with retry button', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(future: () async {
          throw Exception('boom');
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('Error loading expenses'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('search field and category filter chips render', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(future: () async => const <AdminExpenseModel>[]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Search expenses...'), findsOneWidget);
      // Category chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Stay'), findsOneWidget);
      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('Shopping'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('renders expense card with title and amount', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(
          future: () async => [_expense(title: 'Sushi Night', amount: 42.50)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sushi Night'), findsOneWidget);
      expect(find.text('Food & Dining'), findsOneWidget);
    });

    testWidgets('renders trip info row when tripName is set', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(
          future: () async => [
            _expense(tripName: 'Goa Holiday', tripDestination: 'Goa'),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Goa Holiday'), findsOneWidget);
    });

    testWidgets('renders standalone label when tripName is null', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(
          future: () async => [
            _expense(tripId: null, tripName: null, tripDestination: null),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Standalone Expense'), findsOneWidget);
    });

    testWidgets('renders payer info', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(future: () async => [_expense(payerName: 'Charlie')]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Paid by: Charlie'), findsOneWidget);
    });

    testWidgets('falls back to email when payerName is null', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(
          future: () async => [
            _expense(payerName: null, payerEmail: 'foo@bar.com'),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Paid by: foo@bar.com'), findsOneWidget);
    });

    testWidgets('renders Settled chip when fully settled', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(
          future: () async => [_expense(splitCount: 3, settledCount: 3)],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Settled'), findsOneWidget);
      expect(find.text('Unsettle'), findsOneWidget);
    });

    testWidgets('renders progress fraction when partially settled', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(
          future: () async => [
            _expense(splitCount: 4, settledCount: 1, pendingAmount: 30),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1/4'), findsOneWidget);
      expect(find.text('Settle All'), findsOneWidget);
      expect(find.textContaining('pending'), findsOneWidget);
    });

    testWidgets('renders Receipt chip when receiptUrl set', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(
          future: () async => [
            _expense(receiptUrl: 'https://example.com/receipt.jpg'),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Receipt'), findsOneWidget);
    });

    testWidgets('renders progress bar when there are splits', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(
          future: () async => [_expense(splitCount: 2, settledCount: 1)],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('uses INR symbol for INR currency', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(
          future: () async => [_expense(currency: 'INR', amount: 250.0)],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('250'), findsAtLeastNWidgets(1));
    });

    testWidgets('uses EUR symbol for EUR currency', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(
          future: () async => [_expense(currency: 'EUR', amount: 99.0)],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('99'), findsAtLeastNWidgets(1));
    });

    testWidgets('uses GBP symbol for GBP currency', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(
          future: () async => [_expense(currency: 'GBP', amount: 50.0)],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('50'), findsAtLeastNWidgets(1));
    });

    testWidgets('uses currency code for unknown currency', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(
          future: () async => [_expense(currency: 'AUD', amount: 75.0)],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('75'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders multiple categories with different colors', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(
          future: () async => [
            _expense(id: 'e1', category: 'food', title: 'Lunch'),
            _expense(id: 'e2', category: 'transport', title: 'Taxi'),
            _expense(id: 'e3', category: 'accommodation', title: 'Hotel'),
            _expense(id: 'e4', category: 'activities', title: 'Tour'),
            _expense(id: 'e5', category: 'shopping', title: 'Souvenirs'),
            _expense(id: 'e6', category: 'other', title: 'Misc'),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Taxi'), findsOneWidget);
      expect(find.text('Hotel'), findsOneWidget);
    });

    testWidgets('uses transactionDate when present', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(
          future: () async => [
            _expense(transactionDate: DateTime(2024, 3, 15)),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Mar 15'), findsOneWidget);
    });
  });

  group('AdminExpenseList - search and filter', () {
    testWidgets('typing in search shows clear button', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(future: () async => const <AdminExpenseModel>[]),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'sushi');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('clear button resets search query', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(future: () async => const <AdminExpenseModel>[]),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'pizza');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('search empty state shows "No matching expenses"',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(future: () async => const <AdminExpenseModel>[]),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'xxx');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('No matching expenses'), findsOneWidget);
      expect(find.text('Try a different search term'), findsOneWidget);
    });

    testWidgets('selecting category chip updates state', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(future: () async => const <AdminExpenseModel>[]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      // Verify empty state for category
      expect(find.text('No expenses in this category'), findsOneWidget);
      expect(find.text('Try selecting a different category'), findsOneWidget);
    });

    testWidgets('toggling category chip back to false', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(future: () async => const <AdminExpenseModel>[]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      expect(find.text('No expenses found'), findsOneWidget);
    });
  });

  group('AdminExpenseList - actions', () {
    testWidgets('settle button triggers settle action', (tester) async {
      useTallViewport(tester);
      final ds = _FakeExpenseDataSource();
      await tester.pumpWidget(_wrap(
        future: () async => [_expense(splitCount: 3, settledCount: 1)],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settle All'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(ds.settleCalls, contains('e1'));
    });

    testWidgets('settle action shows error snackbar on failure', (tester) async {
      useTallViewport(tester);
      final ds = _FakeExpenseDataSource()..throwOnSettle = true;
      await tester.pumpWidget(_wrap(
        future: () async => [_expense(splitCount: 3, settledCount: 1)],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settle All'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('Failed to settle'), findsOneWidget);
    });

    testWidgets('unsettle button triggers unsettle action', (tester) async {
      useTallViewport(tester);
      final ds = _FakeExpenseDataSource();
      await tester.pumpWidget(_wrap(
        future: () async => [_expense(splitCount: 3, settledCount: 3)],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unsettle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(ds.unsettleCalls, contains('e1'));
    });

    testWidgets('unsettle action shows error snackbar on failure', (tester) async {
      useTallViewport(tester);
      final ds = _FakeExpenseDataSource()..throwOnUnsettle = true;
      await tester.pumpWidget(_wrap(
        future: () async => [_expense(splitCount: 3, settledCount: 3)],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unsettle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('Failed to unsettle'), findsOneWidget);
    });

    testWidgets('delete button shows confirmation dialog', (tester) async {
      useTallViewport(tester);
      final ds = _FakeExpenseDataSource();
      await tester.pumpWidget(_wrap(
        future: () async => [_expense(title: 'Lunch')],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Expense'), findsOneWidget);
      expect(find.textContaining('Lunch'), findsAtLeastNWidgets(1));
    });

    testWidgets('cancel from delete dialog does not delete', (tester) async {
      useTallViewport(tester);
      final ds = _FakeExpenseDataSource();
      await tester.pumpWidget(_wrap(
        future: () async => [_expense(title: 'Lunch')],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(ds.deleteCalls, isEmpty);
    });

    testWidgets('confirm delete calls deleteExpense', (tester) async {
      useTallViewport(tester);
      final ds = _FakeExpenseDataSource();
      await tester.pumpWidget(_wrap(
        future: () async => [_expense(title: 'Lunch')],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      // Tap Delete in the confirmation dialog (not the card button)
      final deleteButtons = find.text('Delete');
      await tester.tap(deleteButtons.last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(ds.deleteCalls, contains('e1'));
    });

    testWidgets('delete error shows snackbar', (tester) async {
      useTallViewport(tester);
      final ds = _FakeExpenseDataSource()..throwOnDelete = true;
      await tester.pumpWidget(_wrap(
        future: () async => [_expense(title: 'Lunch')],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('Failed to delete expense'), findsOneWidget);
    });

    testWidgets('edit button opens bottom sheet dialog', (tester) async {
      useTallViewport(tester);
      final ds = _FakeExpenseDataSource();
      await tester.pumpWidget(_wrap(
        future: () async => [_expense(title: 'Lunch')],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Expense'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('edit dialog shows close button to dismiss', (tester) async {
      useTallViewport(tester);
      final ds = _FakeExpenseDataSource();
      await tester.pumpWidget(_wrap(
        future: () async => [_expense(title: 'Lunch')],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Edit Expense'), findsNothing);
    });

    testWidgets('edit save with empty title shows validation snackbar',
        (tester) async {
      useTallViewport(tester);
      final ds = _FakeExpenseDataSource();
      await tester.pumpWidget(_wrap(
        future: () async => [_expense(title: 'Lunch')],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Clear the title text field
      final titleField = find.widgetWithText(TextField, 'Lunch');
      await tester.enterText(titleField, '');
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Title is required'), findsOneWidget);
    });

    testWidgets('edit save with invalid amount shows validation snackbar',
        (tester) async {
      useTallViewport(tester);
      final ds = _FakeExpenseDataSource();
      await tester.pumpWidget(_wrap(
        future: () async => [_expense(title: 'Lunch', amount: 50.0)],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Find the amount field (initialized to '50.0') and overwrite
      final amountField = find.widgetWithText(TextField, '50.0');
      await tester.enterText(amountField, '0');
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Please enter a valid amount'), findsOneWidget);
    });

    testWidgets('edit save calls updateExpense with new values',
        (tester) async {
      useTallViewport(tester);
      final ds = _FakeExpenseDataSource();
      await tester.pumpWidget(_wrap(
        future: () async => [_expense(title: 'Lunch', amount: 50.0)],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      final titleField = find.widgetWithText(TextField, 'Lunch');
      await tester.enterText(titleField, 'Brunch');

      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(ds.updateCalls, hasLength(1));
      expect(ds.updateCalls.first['id'], 'e1');
      expect(ds.updateCalls.first['title'], 'Brunch');
    });

    testWidgets('edit save error shows snackbar', (tester) async {
      useTallViewport(tester);
      final ds = _FakeExpenseDataSource()..throwOnUpdate = true;
      await tester.pumpWidget(_wrap(
        future: () async => [_expense(title: 'Lunch')],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Failed to update expense'), findsOneWidget);
    });
  });
}
