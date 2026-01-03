import 'package:flutter/material.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/models/expense_model.dart';

/// Simplified "Who Owes Whom" card that shows clear payment directions
/// Shows: "A owes B ₹500" format for easy understanding
class WhoOwesWhomCard extends StatelessWidget {
  final List<BalanceSummary> balances;
  final String? currentUserId;
  final String currency;
  final VoidCallback? onSettlePressed;
  final Function(String recipientName, double amount)? onPayPressed;

  const WhoOwesWhomCard({
    super.key,
    required this.balances,
    this.currentUserId,
    this.currency = 'INR',
    this.onSettlePressed,
    this.onPayPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate simplified debts (who owes whom)
    final debts = _calculateSimplifiedDebts();

    if (debts.isEmpty && balances.every((b) => b.balance == 0)) {
      return _buildAllSettledCard(context);
    }

    if (debts.isEmpty) {
      // No clear debts but uneven balances - show balance view
      return _buildBalanceOnlyCard(context);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  color: context.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Who Owes Whom',
                    style: context.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.primaryColor,
                    ),
                  ),
                ),
                if (onSettlePressed != null)
                  TextButton.icon(
                    onPressed: onSettlePressed,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Settle Up'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
              ],
            ),
          ),

          // Debt list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: debts.map((debt) {
                final isCurrentUserDebtor = debt.fromUserId == currentUserId;
                final isCurrentUserCreditor = debt.toUserId == currentUserId;

                return _DebtRow(
                  debt: debt,
                  isCurrentUserDebtor: isCurrentUserDebtor,
                  isCurrentUserCreditor: isCurrentUserCreditor,
                  currency: currency,
                  onPayPressed: isCurrentUserDebtor && onPayPressed != null
                      ? () => onPayPressed!(debt.toUserName, debt.amount)
                      : null,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllSettledCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.successColor.withValues(alpha: 0.1),
            context.successColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.successColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            color: context.successColor,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'All Settled Up! 🎉',
            style: context.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: context.successColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Everyone is square. No pending payments.',
            style: context.bodyMedium.copyWith(
              color: context.textColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceOnlyCard(BuildContext context) {
    // Sort balances: show who gets money first, then who owes
    final sortedBalances = List<BalanceSummary>.from(balances)
      ..sort((a, b) => b.balance.compareTo(a.balance));

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: context.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Balance Summary',
                    style: context.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Balance list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: sortedBalances.map((balance) {
                final isPositive = balance.balance > 0;
                final isZero = balance.balance == 0;
                final isCurrentUser = balance.userId == currentUserId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? context.primaryColor.withValues(alpha: 0.05)
                        : context.textColor.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrentUser
                        ? Border.all(color: context.primaryColor.withValues(alpha: 0.2))
                        : null,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isZero
                            ? context.textColor.withValues(alpha: 0.1)
                            : isPositive
                                ? context.successColor.withValues(alpha: 0.2)
                                : context.errorColor.withValues(alpha: 0.2),
                        child: Text(
                          balance.userName.isNotEmpty
                              ? balance.userName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: isZero
                                ? context.textColor.withValues(alpha: 0.5)
                                : isPositive
                                    ? context.successColor
                                    : context.errorColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCurrentUser ? '${balance.userName} (You)' : balance.userName,
                              style: context.titleSmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isZero
                                  ? 'All settled'
                                  : isPositive
                                      ? 'Gets back'
                                      : 'Owes',
                              style: context.bodySmall.copyWith(
                                color: isZero
                                    ? context.textColor.withValues(alpha: 0.5)
                                    : isPositive
                                        ? context.successColor
                                        : context.errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isZero)
                        Text(
                          balance.balance.abs().toCurrency(currency),
                          style: context.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPositive ? context.successColor : context.errorColor,
                          ),
                        ),
                      if (isZero)
                        Icon(
                          Icons.check_circle,
                          color: context.successColor,
                          size: 20,
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate simplified debts from balances
  /// Returns a list of who should pay whom
  List<_DebtInfo> _calculateSimplifiedDebts() {
    // Separate creditors (positive balance - get money) and debtors (negative balance - owe money)
    final creditors = balances.where((b) => b.balance > 0).toList()
      ..sort((a, b) => b.balance.compareTo(a.balance)); // Highest credit first

    final debtors = balances.where((b) => b.balance < 0).toList()
      ..sort((a, b) => a.balance.compareTo(b.balance)); // Largest debt first

    final debts = <_DebtInfo>[];

    // Create mutable copies of amounts
    final creditorAmounts = <String, double>{
      for (var c in creditors) c.userId: c.balance
    };
    final debtorAmounts = <String, double>{
      for (var d in debtors) d.userId: d.balance.abs()
    };

    // Match debtors with creditors to minimize transactions
    for (var debtor in debtors) {
      var remainingDebt = debtorAmounts[debtor.userId] ?? 0;

      for (var creditor in creditors) {
        if (remainingDebt <= 0) break;

        final creditAvailable = creditorAmounts[creditor.userId] ?? 0;
        if (creditAvailable <= 0) continue;

        final payAmount = remainingDebt < creditAvailable ? remainingDebt : creditAvailable;

        if (payAmount > 0.01) {  // Ignore very small amounts
          debts.add(_DebtInfo(
            fromUserId: debtor.userId,
            fromUserName: debtor.userName,
            toUserId: creditor.userId,
            toUserName: creditor.userName,
            amount: payAmount,
          ));

          remainingDebt -= payAmount;
          creditorAmounts[creditor.userId] = creditAvailable - payAmount;
        }
      }
    }

    return debts;
  }
}

/// Information about a single debt
class _DebtInfo {
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final double amount;

  const _DebtInfo({
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
  });
}

/// Single debt row widget
class _DebtRow extends StatelessWidget {
  final _DebtInfo debt;
  final bool isCurrentUserDebtor;
  final bool isCurrentUserCreditor;
  final String currency;
  final VoidCallback? onPayPressed;

  const _DebtRow({
    required this.debt,
    this.isCurrentUserDebtor = false,
    this.isCurrentUserCreditor = false,
    this.currency = 'INR',
    this.onPayPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUserDebtor
            ? context.errorColor.withValues(alpha: 0.05)
            : isCurrentUserCreditor
                ? context.successColor.withValues(alpha: 0.05)
                : context.textColor.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUserDebtor
              ? context.errorColor.withValues(alpha: 0.2)
              : isCurrentUserCreditor
                  ? context.successColor.withValues(alpha: 0.2)
                  : context.textColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // From user avatar
          _buildAvatar(context, debt.fromUserName, isDebtor: true),

          const SizedBox(width: 8),

          // Arrow and amount
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isCurrentUserDebtor ? 'You' : debt.fromUserName,
                        style: context.bodyMedium.copyWith(
                          fontWeight: isCurrentUserDebtor ? FontWeight.bold : FontWeight.w500,
                          color: isCurrentUserDebtor ? context.errorColor : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: context.textColor.withValues(alpha: 0.5),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        isCurrentUserCreditor ? 'You' : debt.toUserName,
                        style: context.bodyMedium.copyWith(
                          fontWeight: isCurrentUserCreditor ? FontWeight.bold : FontWeight.w500,
                          color: isCurrentUserCreditor ? context.successColor : null,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'owes ${debt.amount.toCurrency(currency)}',
                    style: context.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // To user avatar
          _buildAvatar(context, debt.toUserName, isDebtor: false),

          // Pay button for current user
          if (onPayPressed != null) ...[
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: onPayPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(60, 32),
              ),
              child: const Text('Pay', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, String name, {required bool isDebtor}) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isDebtor
          ? context.errorColor.withValues(alpha: 0.2)
          : context.successColor.withValues(alpha: 0.2),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDebtor ? context.errorColor : context.successColor,
        ),
      ),
    );
  }
}
