import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/services/payment_service.dart';

/// Unit tests for PaymentService
/// Tests all UPI payment functionality including:
/// - UPI link generation
/// - UPI ID validation
/// - Amount formatting
/// - App detection
void main() {
  late PaymentService paymentService;

  setUp(() {
    paymentService = PaymentService();
  });

  group('PaymentService - UPI Link Generation', () {
    test('should generate valid generic UPI link', () {
      // Arrange
      const upiId = 'john@paytm';
      const recipientName = 'John Doe';
      const amount = 500.0;
      const note = 'Trip settlement';

      // Act
      final link = paymentService.generateUPILink(
        upiId: upiId,
        recipientName: recipientName,
        amount: amount,
        note: note,
      );

      // Assert
      expect(link, startsWith('upi://pay?'));
      expect(link, contains('pa=john@paytm'));
      expect(link, contains('pn=John%20Doe'));
      expect(link, contains('am=500.00'));
      expect(link, contains('cu=INR'));
      expect(link, contains('tn=Trip%20settlement'));
    });

    test('should generate Google Pay specific link', () {
      // Arrange
      const upiId = 'user@paytm';
      const recipientName = 'Test User';
      const amount = 100.0;
      const note = 'Payment';

      // Act
      final link = paymentService.generateUPILink(
        upiId: upiId,
        recipientName: recipientName,
        amount: amount,
        note: note,
        app: UPIApp.googlePay,
      );

      // Assert
      expect(link, startsWith('gpay://upi/pay?'));
      expect(link, contains('pa=user@paytm'));
      expect(link, contains('am=100.00'));
    });

    test('should generate PhonePe specific link', () {
      // Arrange
      const upiId = 'merchant@ybl';
      const recipientName = 'Merchant';
      const amount = 250.0;
      const note = 'Purchase';

      // Act
      final link = paymentService.generateUPILink(
        upiId: upiId,
        recipientName: recipientName,
        amount: amount,
        note: note,
        app: UPIApp.phonePe,
      );

      // Assert
      expect(link, startsWith('phonepe://pay?'));
      expect(link, contains('pa=merchant@ybl'));
    });

    test('should generate Paytm specific link', () {
      // Arrange
      const upiId = '9876543210@paytm';
      const recipientName = 'Shop Owner';
      const amount = 999.99;
      const note = 'Bill payment';

      // Act
      final link = paymentService.generateUPILink(
        upiId: upiId,
        recipientName: recipientName,
        amount: amount,
        note: note,
        app: UPIApp.paytm,
      );

      // Assert
      expect(link, startsWith('paytmmp://upi/pay?'));
      expect(link, contains('pa=9876543210@paytm'));
      expect(link, contains('am=999.99'));
    });

    test('should generate BHIM specific link', () {
      // Arrange
      const upiId = 'user@sbi';
      const recipientName = 'BHIM User';
      const amount = 1500.0;
      const note = 'Transfer';

      // Act
      final link = paymentService.generateUPILink(
        upiId: upiId,
        recipientName: recipientName,
        amount: amount,
        note: note,
        app: UPIApp.bhim,
      );

      // Assert
      expect(link, startsWith('bhim://upi/pay?'));
      expect(link, contains('pa=user@sbi'));
    });

    test('should properly URL encode recipient name with spaces', () {
      // Arrange
      const upiId = 'user@paytm';
      const recipientName = 'John Michael Doe';
      const amount = 100.0;
      const note = 'Test';

      // Act
      final link = paymentService.generateUPILink(
        upiId: upiId,
        recipientName: recipientName,
        amount: amount,
        note: note,
      );

      // Assert
      expect(link, contains('pn=John%20Michael%20Doe'));
      expect(link, isNot(contains('pn=John Michael Doe')));
    });

    test('should properly URL encode note with special characters', () {
      // Arrange
      const upiId = 'user@paytm';
      const recipientName = 'User';
      const amount = 100.0;
      const note = 'Settlement for Goa Trip 2024!';

      // Act
      final link = paymentService.generateUPILink(
        upiId: upiId,
        recipientName: recipientName,
        amount: amount,
        note: note,
      );

      // Assert - Note: '!' is allowed in URLs and doesn't need encoding
      expect(link, contains('tn=Settlement%20for%20Goa%20Trip%202024'));
      expect(link, contains('Goa%20Trip'));
    });

    test('should format amount to 2 decimal places', () {
      // Arrange
      const upiId = 'user@paytm';
      const recipientName = 'User';
      const note = 'Test';

      // Act - Test whole number
      final link1 = paymentService.generateUPILink(
        upiId: upiId,
        recipientName: recipientName,
        amount: 500,
        note: note,
      );

      // Act - Test decimal number
      final link2 = paymentService.generateUPILink(
        upiId: upiId,
        recipientName: recipientName,
        amount: 123.5,
        note: note,
      );

      // Assert
      expect(link1, contains('am=500.00'));
      expect(link2, contains('am=123.50'));
    });
  });

  group('PaymentService - Input Validation', () {
    test('should throw error when UPI ID is empty', () {
      // Assert
      expect(
        () => paymentService.generateUPILink(
          upiId: '',
          recipientName: 'User',
          amount: 100.0,
          note: 'Test',
        ),
        throwsArgumentError,
      );
    });

    test('should throw error when recipient name is empty', () {
      // Assert
      expect(
        () => paymentService.generateUPILink(
          upiId: 'user@paytm',
          recipientName: '',
          amount: 100.0,
          note: 'Test',
        ),
        throwsArgumentError,
      );
    });

    test('should throw error when amount is zero', () {
      // Assert
      expect(
        () => paymentService.generateUPILink(
          upiId: 'user@paytm',
          recipientName: 'User',
          amount: 0,
          note: 'Test',
        ),
        throwsArgumentError,
      );
    });

    test('should throw error when amount is negative', () {
      // Assert
      expect(
        () => paymentService.generateUPILink(
          upiId: 'user@paytm',
          recipientName: 'User',
          amount: -100.0,
          note: 'Test',
        ),
        throwsArgumentError,
      );
    });
  });

  group('PaymentService - UPI ID Validation', () {
    test('should validate correct UPI ID formats', () {
      // Arrange & Act & Assert
      expect(paymentService.isValidUPIId('user@paytm'), isTrue);
      expect(paymentService.isValidUPIId('john.doe@paytm'), isTrue);
      expect(paymentService.isValidUPIId('9876543210@ybl'), isTrue);
      expect(paymentService.isValidUPIId('merchant-123@upi'), isTrue);
      expect(paymentService.isValidUPIId('user_name@bank'), isTrue);
      expect(paymentService.isValidUPIId('abc123@xyz'), isTrue);
    });

    test('should reject invalid UPI ID formats', () {
      // Arrange & Act & Assert
      expect(paymentService.isValidUPIId(''), isFalse);
      expect(paymentService.isValidUPIId('invalidupiid'), isFalse);
      expect(paymentService.isValidUPIId('user@'), isFalse);
      expect(paymentService.isValidUPIId('@paytm'), isFalse);
      expect(paymentService.isValidUPIId('ab@xy'), isFalse); // Too short
      expect(paymentService.isValidUPIId('user paytm'), isFalse); // No @
      expect(paymentService.isValidUPIId('user@@paytm'), isFalse); // Double @
    });

    test('should extract UPI ID from text', () {
      // Arrange
      const text1 = 'My UPI ID is user@paytm please pay there';
      const text2 = 'Send payment to 9876543210@ybl';
      const text3 = 'No UPI ID here';

      // Act & Assert
      expect(paymentService.extractUPIId(text1), equals('user@paytm'));
      expect(paymentService.extractUPIId(text2), equals('9876543210@ybl'));
      expect(paymentService.extractUPIId(text3), isNull);
    });
  });

  group('PaymentService - Amount Formatting', () {
    test('should format amounts with rupee symbol', () {
      // Act & Assert
      expect(paymentService.formatAmount(100), equals('₹100.00'));
      expect(paymentService.formatAmount(500.5), equals('₹500.50'));
      expect(paymentService.formatAmount(1234.56), equals('₹1234.56'));
      expect(paymentService.formatAmount(0.99), equals('₹0.99'));
      expect(paymentService.formatAmount(1000000), equals('₹1000000.00'));
    });

    test('should always show 2 decimal places', () {
      // Act & Assert
      expect(paymentService.formatAmount(50), equals('₹50.00'));
      expect(paymentService.formatAmount(50.1), equals('₹50.10'));
      expect(paymentService.formatAmount(50.99), equals('₹50.99'));
    });
  });

  group('PaymentService - Edge Cases', () {
    test('should handle very small amounts', () {
      // Act
      final link = paymentService.generateUPILink(
        upiId: 'user@paytm',
        recipientName: 'User',
        amount: 0.01,
        note: 'Test',
      );

      // Assert
      expect(link, contains('am=0.01'));
    });

    test('should handle very large amounts', () {
      // Act
      final link = paymentService.generateUPILink(
        upiId: 'user@paytm',
        recipientName: 'User',
        amount: 999999.99,
        note: 'Test',
      );

      // Assert
      expect(link, contains('am=999999.99'));
    });

    test('should handle long recipient names', () {
      // Arrange
      const longName = 'John Michael Robert Alexander Christopher Smith';

      // Act
      final link = paymentService.generateUPILink(
        upiId: 'user@paytm',
        recipientName: longName,
        amount: 100.0,
        note: 'Test',
      );

      // Assert
      expect(link, contains('pn='));
      expect(link, isNot(contains(longName))); // Should be URL encoded
    });

    test('should handle long notes', () {
      // Arrange
      const longNote = 'This is a very long payment note that describes '
          'the purpose of the payment in great detail for clarity';

      // Act
      final link = paymentService.generateUPILink(
        upiId: 'user@paytm',
        recipientName: 'User',
        amount: 100.0,
        note: longNote,
      );

      // Assert
      expect(link, contains('tn='));
      expect(link, isNot(contains(longNote))); // Should be URL encoded
    });

    test('should handle special characters in UPI ID', () {
      // Act
      final link = paymentService.generateUPILink(
        upiId: 'user.name-123@bank_name',
        recipientName: 'User',
        amount: 100.0,
        note: 'Test',
      );

      // Assert
      expect(link, contains('pa=user.name-123@bank_name'));
    });
  });

  group('PaymentService - UPI App Enum', () {
    test('should have correct display names', () {
      expect(UPIApp.googlePay.displayName, equals('Google Pay'));
      expect(UPIApp.phonePe.displayName, equals('PhonePe'));
      expect(UPIApp.paytm.displayName, equals('Paytm'));
      expect(UPIApp.bhim.displayName, equals('BHIM'));
      expect(UPIApp.genericUPI.displayName, equals('Other UPI'));
    });

    test('should have correct short names', () {
      expect(UPIApp.googlePay.shortName, equals('GPay'));
      expect(UPIApp.phonePe.shortName, equals('PhonePe'));
      expect(UPIApp.paytm.shortName, equals('Paytm'));
      expect(UPIApp.bhim.shortName, equals('BHIM'));
      expect(UPIApp.genericUPI.shortName, equals('UPI'));
    });

    test('should have correct icon paths', () {
      expect(UPIApp.googlePay.iconPath, contains('gpay.png'));
      expect(UPIApp.phonePe.iconPath, contains('phonepe.png'));
      expect(UPIApp.paytm.iconPath, contains('paytm.png'));
      expect(UPIApp.bhim.iconPath, contains('bhim.png'));
      expect(UPIApp.genericUPI.iconPath, contains('upi.png'));
    });
  });

  group('PaymentService - PaymentResult', () {
    test('should create successful result', () {
      // Arrange
      const result = PaymentResult(
        success: true,
        appUsed: UPIApp.googlePay,
      );

      // Assert
      expect(result.success, isTrue);
      expect(result.appUsed, equals(UPIApp.googlePay));
      expect(result.errorMessage, isNull);
    });

    test('should create failure result', () {
      // Arrange
      const result = PaymentResult(
        success: false,
        errorMessage: 'App not installed',
      );

      // Assert
      expect(result.success, isFalse);
      expect(result.appUsed, isNull);
      expect(result.errorMessage, equals('App not installed'));
    });

    test('should have correct toString for success', () {
      // Arrange
      const result = PaymentResult(
        success: true,
        appUsed: UPIApp.googlePay,
      );

      // Assert
      expect(result.toString(), contains('successfully'));
      expect(result.toString(), contains('Google Pay'));
    });

    test('should have correct toString for failure', () {
      // Arrange
      const result = PaymentResult(
        success: false,
        errorMessage: 'Test error',
      );

      // Assert
      expect(result.toString(), contains('failed'));
      expect(result.toString(), contains('Test error'));
    });
  });

  group('PaymentService - PaymentTransaction', () {
    test('should create transaction from JSON', () {
      // Arrange
      final json = {
        'transaction_id': 'txn-123',
        'upi_id': 'user@paytm',
        'recipient_name': 'John Doe',
        'amount': 500.0,
        'note': 'Settlement',
        'timestamp': '2025-10-25T10:30:00.000Z',
        'status': 'completed',
        'proof_image_url': 'https://example.com/proof.jpg',
      };

      // Act
      final transaction = PaymentTransaction.fromJson(json);

      // Assert
      expect(transaction.transactionId, equals('txn-123'));
      expect(transaction.upiId, equals('user@paytm'));
      expect(transaction.recipientName, equals('John Doe'));
      expect(transaction.amount, equals(500.0));
      expect(transaction.note, equals('Settlement'));
      expect(transaction.status, equals(PaymentStatus.completed));
      expect(transaction.proofImageUrl, equals('https://example.com/proof.jpg'));
    });

    test('should convert transaction to JSON', () {
      // Arrange
      final transaction = PaymentTransaction(
        transactionId: 'txn-456',
        upiId: 'merchant@ybl',
        recipientName: 'Merchant',
        amount: 250.0,
        note: 'Purchase',
        timestamp: DateTime(2025, 10, 25, 10, 30),
        status: PaymentStatus.pending,
      );

      // Act
      final json = transaction.toJson();

      // Assert
      expect(json['transaction_id'], equals('txn-456'));
      expect(json['upi_id'], equals('merchant@ybl'));
      expect(json['recipient_name'], equals('Merchant'));
      expect(json['amount'], equals(250.0));
      expect(json['note'], equals('Purchase'));
      expect(json['status'], equals('pending'));
      expect(json['proof_image_url'], isNull);
    });
  });

  group('PaymentService - PaymentStatus Enum', () {
    test('should have correct status values', () {
      expect(PaymentStatus.values, contains(PaymentStatus.pending));
      expect(PaymentStatus.values, contains(PaymentStatus.completed));
      expect(PaymentStatus.values, contains(PaymentStatus.failed));
      expect(PaymentStatus.values, contains(PaymentStatus.verified));
    });

    test('should have correct status names', () {
      expect(PaymentStatus.pending.name, equals('pending'));
      expect(PaymentStatus.completed.name, equals('completed'));
      expect(PaymentStatus.failed.name, equals('failed'));
      expect(PaymentStatus.verified.name, equals('verified'));
    });
  });

  group('PaymentService - Integration Tests', () {
    test('should generate valid link for complete payment flow', () {
      // Arrange
      const upiId = 'john.doe@paytm';
      const recipientName = 'John Doe';
      const amount = 500.0;
      const note = 'Trip settlement for Goa 2024';

      // Act - Generate link
      final link = paymentService.generateUPILink(
        upiId: upiId,
        recipientName: recipientName,
        amount: amount,
        note: note,
        app: UPIApp.googlePay,
      );

      // Assert - Verify all components
      expect(link, isNotEmpty);
      expect(link, startsWith('gpay://'));
      expect(link, contains('pa=john.doe@paytm'));
      expect(link, contains('pn=John%20Doe'));
      expect(link, contains('am=500.00'));
      expect(link, contains('cu=INR'));
      expect(link, contains('tn='));

      // Validate UPI ID
      expect(paymentService.isValidUPIId(upiId), isTrue);

      // Format amount
      final formattedAmount = paymentService.formatAmount(amount);
      expect(formattedAmount, equals('₹500.00'));
    });

    test('should handle complete error scenario', () {
      // Assert - Invalid UPI ID
      expect(paymentService.isValidUPIId('invalid'), isFalse);

      // Assert - Invalid amount
      expect(
        () => paymentService.generateUPILink(
          upiId: 'user@paytm',
          recipientName: 'User',
          amount: -100,
          note: 'Test',
        ),
        throwsArgumentError,
      );

      // Assert - Empty recipient
      expect(
        () => paymentService.generateUPILink(
          upiId: 'user@paytm',
          recipientName: '',
          amount: 100,
          note: 'Test',
        ),
        throwsArgumentError,
      );
    });
  });
}
