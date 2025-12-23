import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../shared/models/expense_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/expense_providers.dart';
import '../widgets/payment_options_sheet.dart';

/// Settlement Summary Page
/// Shows a clear report of all balances and who owes whom
class SettlementSummaryPage extends ConsumerWidget {
  final String tripId;

  const SettlementSummaryPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(tripBalancesProvider(tripId));
    final settlementsAsync = ref.watch(tripSettlementsProvider(tripId));
    final currentUserId = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/trips/$tripId/expenses');
            }
          },
        ),
        title: const Text('Settlement Summary'),
      ),
      body: balancesAsync.when(
        data: (balances) => _buildContent(
          context,
          ref,
          balances,
          settlementsAsync,
          currentUserId,
        ),
        loading: () => const Center(
          child: AppLoadingIndicator(message: 'Loading balances...'),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: context.errorColor),
              const SizedBox(height: 16),
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(tripBalancesProvider(tripId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<BalanceSummary> balances,
    AsyncValue<List<SettlementModel>> settlementsAsync,
    String? currentUserId,
  ) {
    // Calculate simplified debts
    final debts = _calculateSimplifiedDebts(balances);
    final isAllSettled = debts.isEmpty && balances.every((b) => b.balance.abs() < 0.01);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status card
          _buildStatusCard(context, isAllSettled, debts.length),

          const SizedBox(height: 24),

          // Who Owes Whom section
          if (!isAllSettled) ...[
            _buildSectionHeader(context, 'Who Owes Whom', Icons.swap_horiz_rounded),
            const SizedBox(height: 12),
            ...debts.map((debt) => _buildDebtCard(context, debt, currentUserId)),
            const SizedBox(height: 24),
          ],

          // Individual Balances section
          _buildSectionHeader(context, 'Individual Balances', Icons.account_balance_wallet),
          const SizedBox(height: 12),
          ...balances.map((balance) => _buildBalanceCard(context, balance, currentUserId)),

          const SizedBox(height: 24),

          // Past Settlements section
          settlementsAsync.when(
            data: (settlements) {
              if (settlements.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, 'Past Settlements', Icons.history),
                  const SizedBox(height: 12),
                  ...settlements.map((s) => _buildSettlementCard(context, s)),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, bool isAllSettled, int pendingCount) {
    if (isAllSettled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.successColor,
              context.successColor.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.successColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.celebration,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'All Settled Up! 🎉',
              style: context.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Everyone is square. No pending payments.',
              style: context.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.errorColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.pending_actions,
              color: context.errorColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$pendingCount Pending Payment${pendingCount > 1 ? 's' : ''}',
                  style: context.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.errorColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Complete the payments below to settle up',
                  style: context.bodySmall.copyWith(
                    color: context.textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: context.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDebtCard(BuildContext context, _DebtInfo debt, String? currentUserId) {
    final isCurrentUserDebtor = debt.fromUserId == currentUserId;
    final isCurrentUserCreditor = debt.toUserId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUserDebtor
            ? context.errorColor.withValues(alpha: 0.05)
            : isCurrentUserCreditor
                ? context.successColor.withValues(alpha: 0.05)
                : context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUserDebtor
              ? context.errorColor.withValues(alpha: 0.3)
              : isCurrentUserCreditor
                  ? context.successColor.withValues(alpha: 0.3)
                  : context.textColor.withValues(alpha: 0.1),
          width: isCurrentUserDebtor || isCurrentUserCreditor ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // From user
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: context.errorColor.withValues(alpha: 0.2),
                      child: Text(
                        debt.fromUserName.isNotEmpty
                            ? debt.fromUserName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: context.errorColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isCurrentUserDebtor ? 'You' : debt.fromUserName,
                      style: context.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isCurrentUserDebtor)
                      Text(
                        '(owes)',
                        style: context.bodySmall.copyWith(
                          color: context.errorColor,
                        ),
                      ),
                  ],
                ),
              ),

              // Arrow and amount
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      color: context.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        debt.amount.toINR(),
                        style: context.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // To user
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: context.successColor.withValues(alpha: 0.2),
                      child: Text(
                        debt.toUserName.isNotEmpty
                            ? debt.toUserName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: context.successColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isCurrentUserCreditor ? 'You' : debt.toUserName,
                      style: context.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isCurrentUserCreditor)
                      Text(
                        '(gets back)',
                        style: context.bodySmall.copyWith(
                          color: context.successColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Pay button for current user who owes
          if (isCurrentUserDebtor) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final upiId = await _showUPIInputDialog(context, debt.toUserName);
                  if (upiId != null && upiId.isNotEmpty && context.mounted) {
                    PaymentOptionsSheet.show(
                      context,
                      recipientUPIId: upiId,
                      recipientName: debt.toUserName,
                      amount: debt.amount,
                      note: 'Settlement for trip expenses',
                    );
                  }
                },
                icon: const Icon(Icons.payment),
                label: Text('Pay ${debt.amount.toINR()}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.successColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, BalanceSummary balance, String? currentUserId) {
    final isPositive = balance.balance > 0;
    final isZero = balance.balance.abs() < 0.01;
    final isCurrentUser = balance.userId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? context.primaryColor.withValues(alpha: 0.05)
            : context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: context.primaryColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isZero
                ? context.textColor.withValues(alpha: 0.1)
                : isPositive
                    ? context.successColor.withValues(alpha: 0.2)
                    : context.errorColor.withValues(alpha: 0.2),
            child: Text(
              balance.userName.isNotEmpty ? balance.userName[0].toUpperCase() : '?',
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
                Row(
                  children: [
                    Text(
                      'Paid: ${balance.totalPaid.toINR()}',
                      style: context.bodySmall.copyWith(
                        color: context.textColor.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: context.textColor.withValues(alpha: 0.3)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Share: ${balance.totalOwed.toINR()}',
                      style: context.bodySmall.copyWith(
                        color: context.textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isZero)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: context.successColor),
                    const SizedBox(width: 4),
                    Text(
                      'Settled',
                      style: context.bodySmall.copyWith(
                        color: context.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  '${isPositive ? '+' : '-'}${balance.balance.abs().toINR()}',
                  style: context.titleMedium.copyWith(
                    color: isPositive ? context.successColor : context.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (!isZero)
                Text(
                  isPositive ? 'gets back' : 'owes',
                  style: context.bodySmall.copyWith(
                    color: isPositive ? context.successColor : context.errorColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementCard(BuildContext context, SettlementModel settlement) {
    final isPending = settlement.status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.textColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPending ? Icons.pending : Icons.check_circle,
            color: isPending ? Colors.orange : context.successColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${settlement.fromUserName ?? 'User'} → ${settlement.toUserName ?? 'User'}',
                  style: context.titleSmall.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  settlement.createdAt?.toFormattedDate() ?? '',
                  style: context.bodySmall.copyWith(
                    color: context.textColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                settlement.amount.toINR(),
                style: context.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPending
                      ? Colors.orange.withValues(alpha: 0.1)
                      : context.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  settlement.status.toUpperCase(),
                  style: context.labelSmall.copyWith(
                    color: isPending ? Colors.orange : context.successColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<String?> _showUPIInputDialog(BuildContext context, String userName) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter UPI ID for $userName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please enter the UPI ID to send payment',
              style: context.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'UPI ID',
                hintText: 'name@upi',
                prefixIcon: Icon(Icons.account_balance),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 8),
            Text(
              'Example: username@paytm, username@ybl',
              style: context.bodySmall.copyWith(
                color: context.textColor.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final upiId = controller.text.trim();
              if (upiId.isNotEmpty) {
                Navigator.pop(context, upiId);
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  /// Calculate simplified debts from balances
  List<_DebtInfo> _calculateSimplifiedDebts(List<BalanceSummary> balances) {
    final creditors = balances.where((b) => b.balance > 0.01).toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));

    final debtors = balances.where((b) => b.balance < -0.01).toList()
      ..sort((a, b) => a.balance.compareTo(b.balance));

    final debts = <_DebtInfo>[];

    final creditorAmounts = <String, double>{
      for (var c in creditors) c.userId: c.balance
    };
    final debtorAmounts = <String, double>{
      for (var d in debtors) d.userId: d.balance.abs()
    };

    for (var debtor in debtors) {
      var remainingDebt = debtorAmounts[debtor.userId] ?? 0;

      for (var creditor in creditors) {
        if (remainingDebt <= 0.01) break;

        final creditAvailable = creditorAmounts[creditor.userId] ?? 0;
        if (creditAvailable <= 0.01) continue;

        final payAmount = remainingDebt < creditAvailable ? remainingDebt : creditAvailable;

        if (payAmount > 0.01) {
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
