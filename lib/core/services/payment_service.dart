import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Payment Service
/// Handles UPI payment integration for settlements
/// Supports Paytm, PhonePe, GPay, and generic UPI apps
class PaymentService {
  /// Supported UPI payment apps
  static const List<UPIApp> supportedApps = [
    UPIApp.googlePay,
    UPIApp.phonePe,
    UPIApp.paytm,
    UPIApp.bhim,
    UPIApp.genericUPI,
  ];

  /// Generate UPI payment deep link
  ///
  /// Format: upi://pay?pa={UPI_ID}&pn={NAME}&am={AMOUNT}&cu=INR&tn={NOTE}
  ///
  /// Parameters:
  /// - [upiId]: Recipient's UPI ID (e.g., user@paytm)
  /// - [recipientName]: Recipient's name
  /// - [amount]: Amount to be paid
  /// - [note]: Transaction note/description
  /// - [app]: Specific UPI app to open (optional)
  String generateUPILink({
    required String upiId,
    required String recipientName,
    required double amount,
    required String note,
    UPIApp? app,
  }) {
    // Validate inputs
    if (upiId.isEmpty) {
      throw ArgumentError('UPI ID cannot be empty');
    }
    if (recipientName.isEmpty) {
      throw ArgumentError('Recipient name cannot be empty');
    }
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than 0');
    }

    // Encode parameters for URL
    final encodedName = Uri.encodeComponent(recipientName);
    final encodedNote = Uri.encodeComponent(note);

    // Format amount to 2 decimal places
    final formattedAmount = amount.toStringAsFixed(2);

    // Build UPI URI based on app
    String upiUri;

    switch (app) {
      case UPIApp.googlePay:
        // Google Pay specific format
        upiUri = 'gpay://upi/pay?pa=$upiId&pn=$encodedName&am=$formattedAmount&cu=INR&tn=$encodedNote';
        break;

      case UPIApp.phonePe:
        // PhonePe specific format
        upiUri = 'phonepe://pay?pa=$upiId&pn=$encodedName&am=$formattedAmount&cu=INR&tn=$encodedNote';
        break;

      case UPIApp.paytm:
        // Paytm specific format
        upiUri = 'paytmmp://upi/pay?pa=$upiId&pn=$encodedName&am=$formattedAmount&cu=INR&tn=$encodedNote';
        break;

      case UPIApp.bhim:
        // BHIM specific format
        upiUri = 'bhim://upi/pay?pa=$upiId&pn=$encodedName&am=$formattedAmount&cu=INR&tn=$encodedNote';
        break;

      case UPIApp.genericUPI:
      case null:
      default:
        // Generic UPI format (works with most UPI apps)
        upiUri = 'upi://pay?pa=$upiId&pn=$encodedName&am=$formattedAmount&cu=INR&tn=$encodedNote';
        break;
    }

    if (kDebugMode) {
      print('Generated UPI Link: $upiUri');
    }

    return upiUri;
  }

  /// Launch UPI payment app
  ///
  /// Returns true if app was launched successfully, false otherwise
  Future<bool> launchPayment({
    required String upiId,
    required String recipientName,
    required double amount,
    required String note,
    UPIApp? app,
  }) async {
    try {
      final upiLink = generateUPILink(
        upiId: upiId,
        recipientName: recipientName,
        amount: amount,
        note: note,
        app: app,
      );

      final uri = Uri.parse(upiLink);

      // Check if the app can be launched
      final canLaunch = await canLaunchUrl(uri);

      if (!canLaunch) {
        if (kDebugMode) {
          print('Cannot launch ${app?.name ?? "UPI app"}: App not installed');
        }
        return false;
      }

      // Launch the app
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (kDebugMode) {
        if (launched) {
          print('✅ Successfully launched ${app?.name ?? "UPI app"}');
        } else {
          print('❌ Failed to launch ${app?.name ?? "UPI app"}');
        }
      }

      return launched;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error launching payment: $e');
      }
      return false;
    }
  }

  /// Check if a specific UPI app is installed
  Future<bool> isAppInstalled(UPIApp app) async {
    try {
      final testUri = generateUPILink(
        upiId: 'test@upi',
        recipientName: 'Test',
        amount: 1.0,
        note: 'Test',
        app: app,
      );

      final uri = Uri.parse(testUri);
      return await canLaunchUrl(uri);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking app installation: $e');
      }
      return false;
    }
  }

  /// Get list of installed UPI apps
  Future<List<UPIApp>> getInstalledApps() async {
    final installedApps = <UPIApp>[];

    for (final app in supportedApps) {
      final isInstalled = await isAppInstalled(app);
      if (isInstalled) {
        installedApps.add(app);
      }
    }

    if (kDebugMode) {
      print('Installed UPI apps: ${installedApps.map((a) => a.name).join(", ")}');
    }

    return installedApps;
  }

  /// Launch payment with fallback to other apps if primary fails
  ///
  /// Tries to launch the preferred app first, then falls back to other installed apps
  Future<PaymentResult> launchPaymentWithFallback({
    required String upiId,
    required String recipientName,
    required double amount,
    required String note,
    UPIApp? preferredApp,
  }) async {
    try {
      // Try preferred app first
      if (preferredApp != null) {
        final success = await launchPayment(
          upiId: upiId,
          recipientName: recipientName,
          amount: amount,
          note: note,
          app: preferredApp,
        );

        if (success) {
          return PaymentResult(
            success: true,
            appUsed: preferredApp,
          );
        }
      }

      // Get all installed apps
      final installedApps = await getInstalledApps();

      if (installedApps.isEmpty) {
        return PaymentResult(
          success: false,
          errorMessage: 'No UPI apps installed. Please install GPay, PhonePe, or Paytm.',
        );
      }

      // Try each installed app
      for (final app in installedApps) {
        if (app == preferredApp) continue; // Already tried

        final success = await launchPayment(
          upiId: upiId,
          recipientName: recipientName,
          amount: amount,
          note: note,
          app: app,
        );

        if (success) {
          return PaymentResult(
            success: true,
            appUsed: app,
          );
        }
      }

      // If all apps failed, try generic UPI
      final genericSuccess = await launchPayment(
        upiId: upiId,
        recipientName: recipientName,
        amount: amount,
        note: note,
        app: UPIApp.genericUPI,
      );

      if (genericSuccess) {
        return PaymentResult(
          success: true,
          appUsed: UPIApp.genericUPI,
        );
      }

      return PaymentResult(
        success: false,
        errorMessage: 'Failed to launch any UPI app. Please try manually.',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: 'Error launching payment: ${e.toString()}',
      );
    }
  }

  /// Format amount for display (with currency symbol)
  String formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  /// Validate UPI ID format
  ///
  /// Valid formats:
  /// - username@bank (e.g., john@paytm, 9876543210@ybl)
  /// - phone@provider (e.g., 9876543210@upi)
  bool isValidUPIId(String upiId) {
    if (upiId.isEmpty) return false;

    // UPI ID format: username@provider
    final upiRegex = RegExp(r'^[\w\.\-]{3,}@[\w]{3,}$');
    return upiRegex.hasMatch(upiId);
  }

  /// Parse UPI ID from string
  ///
  /// Extracts UPI ID if embedded in text
  String? extractUPIId(String text) {
    final upiRegex = RegExp(r'[\w\.\-]{3,}@[\w]{3,}');
    final match = upiRegex.firstMatch(text);
    return match?.group(0);
  }
}

/// UPI Apps
enum UPIApp {
  googlePay('Google Pay', 'GPay', 'assets/icons/gpay.png'),
  phonePe('PhonePe', 'PhonePe', 'assets/icons/phonepe.png'),
  paytm('Paytm', 'Paytm', 'assets/icons/paytm.png'),
  bhim('BHIM', 'BHIM', 'assets/icons/bhim.png'),
  genericUPI('Other UPI', 'UPI', 'assets/icons/upi.png');

  final String displayName;
  final String shortName;
  final String iconPath;

  const UPIApp(this.displayName, this.shortName, this.iconPath);
}

/// Payment Result
class PaymentResult {
  final bool success;
  final UPIApp? appUsed;
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    this.appUsed,
    this.errorMessage,
  });

  @override
  String toString() {
    if (success) {
      return 'Payment launched successfully with ${appUsed?.displayName ?? "UPI app"}';
    } else {
      return 'Payment failed: $errorMessage';
    }
  }
}

/// Payment Transaction Details
class PaymentTransaction {
  final String transactionId;
  final String upiId;
  final String recipientName;
  final double amount;
  final String note;
  final DateTime timestamp;
  final PaymentStatus status;
  final String? proofImageUrl;

  const PaymentTransaction({
    required this.transactionId,
    required this.upiId,
    required this.recipientName,
    required this.amount,
    required this.note,
    required this.timestamp,
    required this.status,
    this.proofImageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'upi_id': upiId,
      'recipient_name': recipientName,
      'amount': amount,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'proof_image_url': proofImageUrl,
    };
  }

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      transactionId: json['transaction_id'] as String,
      upiId: json['upi_id'] as String,
      recipientName: json['recipient_name'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      proofImageUrl: json['proof_image_url'] as String?,
    );
  }
}

/// Payment Status
enum PaymentStatus {
  pending,
  completed,
  failed,
  verified,
}
