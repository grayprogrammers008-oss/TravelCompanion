import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Payment Options Bottom Sheet
/// Shows available UPI payment apps and handles payment launch
class PaymentOptionsSheet extends StatefulWidget {
  final String recipientUPIId;
  final String recipientName;
  final double amount;
  final String note;
  final Function(PaymentResult)? onPaymentLaunched;
  final Function(bool confirmed)? onPaymentConfirmed;

  const PaymentOptionsSheet({
    super.key,
    required this.recipientUPIId,
    required this.recipientName,
    required this.amount,
    required this.note,
    this.onPaymentLaunched,
    this.onPaymentConfirmed,
  });

  /// Show payment options and return whether payment was confirmed
  static Future<bool?> show(
    BuildContext context, {
    required String recipientUPIId,
    required String recipientName,
    required double amount,
    required String note,
    Function(PaymentResult)? onPaymentLaunched,
    Function(bool confirmed)? onPaymentConfirmed,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentOptionsSheet(
        recipientUPIId: recipientUPIId,
        recipientName: recipientName,
        amount: amount,
        note: note,
        onPaymentLaunched: onPaymentLaunched,
        onPaymentConfirmed: onPaymentConfirmed,
      ),
    );
  }

  @override
  State<PaymentOptionsSheet> createState() => _PaymentOptionsSheetState();
}

class _PaymentOptionsSheetState extends State<PaymentOptionsSheet> {
  final PaymentService _paymentService = PaymentService();
  List<UPIApp> _installedApps = [];
  bool _isLoading = true;
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    setState(() {
      _isLoading = true;
    });

    final apps = await _paymentService.getInstalledApps();

    setState(() {
      _installedApps = apps;
      _isLoading = false;
    });
  }

  Future<void> _launchPayment(UPIApp? app) async {
    if (_isLaunching) return;

    setState(() {
      _isLaunching = true;
    });

    try {
      final result = await _paymentService.launchPaymentWithFallback(
        upiId: widget.recipientUPIId,
        recipientName: widget.recipientName,
        amount: widget.amount,
        note: widget.note,
        preferredApp: app,
      );

      if (mounted) {
        if (result.success) {
          // Call callback for app launched
          widget.onPaymentLaunched?.call(result);

          // Show confirmation dialog after returning from UPI app
          final confirmed = await _showPaymentConfirmationDialog(
            context,
            appName: result.appUsed?.displayName ?? 'UPI',
          );

          if (mounted) {
            // Call confirmation callback
            widget.onPaymentConfirmed?.call(confirmed);

            // Close sheet and return result
            Navigator.of(context).pop(confirmed);
          }
        } else {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Failed to launch payment'),
              backgroundColor: AppTheme.error,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _launchPayment(app),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLaunching = false;
        });
      }
    }
  }

  /// Show confirmation dialog after UPI app returns
  Future<bool> _showPaymentConfirmationDialog(
    BuildContext context, {
    required String appName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.payment,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Payment Status',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Did you complete the payment of ${_paymentService.formatAmount(widget.amount)} to ${widget.recipientName}?',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.neutral100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppTheme.neutral600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Confirming will mark this as settled between you and ${widget.recipientName}.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Not Yet',
              style: TextStyle(color: AppTheme.neutral600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Yes, Paid'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _copyUPIId() {
    Clipboard.setData(ClipboardData(text: widget.recipientUPIId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('UPI ID copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              child: Column(
                children: [
                  const Text(
                    'Choose Payment Method',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutral900,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.neutral50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Amount:',
                              style: TextStyle(
                                color: AppTheme.neutral600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _paymentService.formatAmount(widget.amount),
                              style: const TextStyle(
                                color: AppTheme.neutral900,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'To:',
                              style: TextStyle(
                                color: AppTheme.neutral600,
                                fontSize: 14,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                widget.recipientName,
                                style: const TextStyle(
                                  color: AppTheme.neutral900,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'UPI ID:',
                              style: TextStyle(
                                color: AppTheme.neutral600,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  widget.recipientUPIId,
                                  style: const TextStyle(
                                    color: AppTheme.neutral900,
                                    fontSize: 14,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 16),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                  onPressed: _copyUPIId,
                                  tooltip: 'Copy UPI ID',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // Payment apps list
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(AppTheme.spacing2xl),
                child: CircularProgressIndicator(),
              )
            else if (_installedApps.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    const Text(
                      'No UPI Apps Found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neutral900,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    const Text(
                      'Please install GPay, PhonePe, or Paytm to make payments',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.neutral600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Try launching with generic UPI
                        _launchPayment(UPIApp.genericUPI);
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text('Try Anyway'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select a UPI app:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.neutral600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    ...PaymentService.supportedApps.map((app) {
                      final isInstalled = _installedApps.contains(app);

                      return _PaymentAppTile(
                        app: app,
                        isInstalled: isInstalled,
                        isLoading: _isLaunching,
                        onTap: isInstalled ? () => _launchPayment(app) : null,
                      );
                    }),
                  ],
                ),
              ),

            const SizedBox(height: AppTheme.spacingLg),

            // Close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),

            const SizedBox(height: AppTheme.spacingSm),
          ],
        ),
      ),
    );
  }
}

/// Payment App Tile
class _PaymentAppTile extends StatelessWidget {
  final UPIApp app;
  final bool isInstalled;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PaymentAppTile({
    required this.app,
    required this.isInstalled,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        border: Border.all(
          color: isInstalled ? AppTheme.primaryTeal : AppTheme.neutral300,
          width: isInstalled ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        enabled: isInstalled && !isLoading,
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isInstalled ? AppTheme.primaryTeal.withOpacity(0.1) : AppTheme.neutral100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getAppIcon(app),
            color: isInstalled ? AppTheme.primaryTeal : AppTheme.neutral400,
          ),
        ),
        title: Text(
          app.displayName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isInstalled ? AppTheme.neutral900 : AppTheme.neutral400,
          ),
        ),
        subtitle: Text(
          isInstalled ? 'Tap to pay' : 'Not installed',
          style: TextStyle(
            fontSize: 12,
            color: isInstalled ? AppTheme.success : AppTheme.neutral400,
          ),
        ),
        trailing: isInstalled
            ? const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.primaryTeal,
              )
            : const Icon(
                Icons.block,
                size: 16,
                color: AppTheme.neutral400,
              ),
      ),
    );
  }

  IconData _getAppIcon(UPIApp app) {
    switch (app) {
      case UPIApp.googlePay:
        return Icons.g_mobiledata;
      case UPIApp.phonePe:
        return Icons.phone_android;
      case UPIApp.paytm:
        return Icons.payment;
      case UPIApp.bhim:
        return Icons.account_balance;
      case UPIApp.genericUPI:
        return Icons.credit_card;
    }
  }
}
