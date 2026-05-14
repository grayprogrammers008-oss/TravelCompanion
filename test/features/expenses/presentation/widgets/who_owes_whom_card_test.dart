// Widget tests for `WhoOwesWhomCard`.
//
// The widget renders one of three states based on the `balances` argument:
//   1. All-settled card (every balance is exactly 0)
//   2. Balance-only card (uneven balances but no clear creditor/debtor pairs)
//   3. Debt list (one or more debtor → creditor rows with amounts)
//
// We exercise each branch and verify the headline text + key UI elements.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/features/expenses/presentation/widgets/who_owes_whom_card.dart';
import 'package:pathio/shared/models/expense_model.dart';

BalanceSummary _bal(
  String userId,
  String userName,
  double balance, {
  double totalPaid = 0,
  double totalOwed = 0,
}) {
  return BalanceSummary(
    userId: userId,
    userName: userName,
    totalPaid: totalPaid,
    totalOwed: totalOwed,
    balance: balance,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData.light(),
    home: Scaffold(body: SizedBox(width: 360, height: 800, child: child)),
  );
}

void main() {
  group('WhoOwesWhomCard - all settled', () {
    testWidgets('renders all-settled card when every balance is zero',
        (tester) async {
      await tester.pumpWidget(_wrap(WhoOwesWhomCard(
        balances: [
          _bal('u1', 'Alice', 0),
          _bal('u2', 'Bob', 0),
        ],
      )));
      await tester.pump();

      // Headline includes the celebration emoji
      expect(find.textContaining('All Settled Up'), findsOneWidget);
      expect(
        find.text('Everyone is square. No pending payments.'),
        findsOneWidget,
      );
      // No "Who Owes Whom" header
      expect(find.text('Who Owes Whom'), findsNothing);
    });

    testWidgets('renders all-settled card when balances list is empty',
        (tester) async {
      await tester.pumpWidget(_wrap(WhoOwesWhomCard(balances: const [])));
      await tester.pump();

      expect(find.textContaining('All Settled Up'), findsOneWidget);
    });
  });

  group('WhoOwesWhomCard - debt rows', () {
    testWidgets(
        'renders debt header and at least one debtor → creditor pairing',
        (tester) async {
      await tester.pumpWidget(_wrap(WhoOwesWhomCard(
        balances: [
          _bal('u1', 'Alice', 100),  // creditor
          _bal('u2', 'Bob', -100),    // debtor
        ],
        currency: 'INR',
      )));
      await tester.pump();

      expect(find.text('Who Owes Whom'), findsOneWidget);
      // Debtor and creditor names appear in a debt row.
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      // The owed-amount pill renders with currency-formatted amount.
      expect(find.textContaining('owes'), findsOneWidget);
    });

    testWidgets(
        'replaces current-user debtor name with "You" when isCurrentUser matches',
        (tester) async {
      await tester.pumpWidget(_wrap(WhoOwesWhomCard(
        balances: [
          _bal('u1', 'Alice', 100),
          _bal('u2', 'Bob', -100),
        ],
        currentUserId: 'u2',
      )));
      await tester.pump();

      // Bob is the current user and is the debtor → should show "You".
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets(
        'replaces current-user creditor name with "You"',
        (tester) async {
      await tester.pumpWidget(_wrap(WhoOwesWhomCard(
        balances: [
          _bal('u1', 'Alice', 100),
          _bal('u2', 'Bob', -100),
        ],
        currentUserId: 'u1',
      )));
      await tester.pump();

      // Alice is the current user and is the creditor → should show "You".
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('shows Settle Up button only when onSettlePressed is provided',
        (tester) async {
      var settled = false;
      await tester.pumpWidget(_wrap(WhoOwesWhomCard(
        balances: [
          _bal('u1', 'Alice', 100),
          _bal('u2', 'Bob', -100),
        ],
        onSettlePressed: () => settled = true,
      )));
      await tester.pump();

      // `TextButton.icon` wraps the children inside a private subclass, so
      // matching by displayed text is the simplest stable lookup.
      final btn = find.text('Settle Up');
      expect(btn, findsOneWidget);

      await tester.tap(btn);
      await tester.pump();
      expect(settled, isTrue);
    });

    testWidgets('hides Settle Up button when onSettlePressed is null',
        (tester) async {
      await tester.pumpWidget(_wrap(WhoOwesWhomCard(
        balances: [
          _bal('u1', 'Alice', 100),
          _bal('u2', 'Bob', -100),
        ],
      )));
      await tester.pump();

      expect(find.text('Settle Up'), findsNothing);
    });

    testWidgets(
        'shows Pay button only when current user is debtor and onPayPressed is set',
        (tester) async {
      String? recipient;
      double? amount;
      await tester.pumpWidget(_wrap(WhoOwesWhomCard(
        balances: [
          _bal('u1', 'Alice', 100),
          _bal('u2', 'Bob', -100),
        ],
        currentUserId: 'u2', // Bob is debtor
        onPayPressed: (r, a) {
          recipient = r;
          amount = a;
        },
      )));
      await tester.pump();

      final pay = find.widgetWithText(ElevatedButton, 'Pay');
      expect(pay, findsOneWidget);

      await tester.tap(pay);
      await tester.pump();
      expect(recipient, 'Alice');
      expect(amount, 100.0);
    });

    testWidgets(
        'hides Pay button when current user is the creditor',
        (tester) async {
      await tester.pumpWidget(_wrap(WhoOwesWhomCard(
        balances: [
          _bal('u1', 'Alice', 100),
          _bal('u2', 'Bob', -100),
        ],
        currentUserId: 'u1', // Alice is creditor
        onPayPressed: (_, __) {},
      )));
      await tester.pump();

      expect(find.widgetWithText(ElevatedButton, 'Pay'), findsNothing);
    });

    testWidgets(
        'matches multiple debtors against multiple creditors greedily',
        (tester) async {
      await tester.pumpWidget(_wrap(WhoOwesWhomCard(
        balances: [
          _bal('a', 'Alice', 200),  // creditor: 200
          _bal('b', 'Bob', -150),    // debtor: 150
          _bal('c', 'Carol', -50),   // debtor: 50
        ],
      )));
      await tester.pump();

      // Should produce two debt rows, both pointing at Alice.
      expect(find.text('Alice'), findsNWidgets(2));
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Carol'), findsOneWidget);
    });

    testWidgets(
        'ignores micro-debts under 0.01',
        (tester) async {
      await tester.pumpWidget(_wrap(WhoOwesWhomCard(
        balances: [
          _bal('a', 'Alice', 0.005),
          _bal('b', 'Bob', -0.005),
        ],
      )));
      await tester.pump();

      // 0.005 < 0.01 threshold → debts list is empty → falls back to balance-only card.
      // (Not all-settled because balances aren't exactly zero.)
      expect(find.text('Balance Summary'), findsOneWidget);
    });
  });

  group('WhoOwesWhomCard - balance-only fallback', () {
    testWidgets(
        'renders Balance Summary when there are uneven balances but no debt pairs',
        (tester) async {
      // All positive balances → no debtors → debts list is empty → fallback.
      await tester.pumpWidget(_wrap(WhoOwesWhomCard(
        balances: [
          _bal('u1', 'Alice', 50),
          _bal('u2', 'Bob', 30),
        ],
      )));
      await tester.pump();

      expect(find.text('Balance Summary'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      // Both have positive balance → 'Gets back' label appears for each.
      expect(find.text('Gets back'), findsNWidgets(2));
    });

    testWidgets(
        'shows "Owes" label for users with negative balance in fallback view',
        (tester) async {
      await tester.pumpWidget(_wrap(WhoOwesWhomCard(
        balances: [
          _bal('u1', 'Alice', -50),
          _bal('u2', 'Bob', -30),
        ],
      )));
      await tester.pump();

      expect(find.text('Balance Summary'), findsOneWidget);
      expect(find.text('Owes'), findsNWidgets(2));
    });

    testWidgets('appends "(You)" to the current user in fallback view',
        (tester) async {
      await tester.pumpWidget(_wrap(WhoOwesWhomCard(
        balances: [
          _bal('u1', 'Alice', 50),
          _bal('u2', 'Bob', 30),
        ],
        currentUserId: 'u1',
      )));
      await tester.pump();

      expect(find.text('Alice (You)'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets(
        'shows "?" for users with empty name in fallback view',
        (tester) async {
      await tester.pumpWidget(_wrap(WhoOwesWhomCard(
        balances: [
          _bal('u1', '', 50),
          _bal('u2', 'Bob', 30),
        ],
      )));
      await tester.pump();

      expect(find.text('?'), findsOneWidget);
    });
  });
}
