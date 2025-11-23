import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/services/email_service.dart';

/// Test suite for Brevo email service integration
///
/// These tests verify:
/// 1. Brevo API connection
/// 2. Email sending functionality
/// 3. Error handling
void main() {
  group('EmailService - Brevo Integration', () {
    late EmailService emailService;

    setUp(() {
      emailService = EmailService();
    });

    test('testConnection should successfully connect to Brevo API', () async {
      // Act
      final result = await emailService.testConnection();

      // Assert
      expect(result, true, reason: 'Should successfully connect to Brevo API');
    });

    test('sendTripInvite should send email successfully', () async {
      // Arrange
      const toEmail = 'test@example.com';
      const toName = 'Test User';
      const tripName = 'Bali Adventure 2024';
      const inviterName = 'Jane Smith';
      const inviteCode = 'TEST123';

      // Act
      final result = await emailService.sendTripInvite(
        toEmail: toEmail,
        toName: toName,
        tripName: tripName,
        inviterName: inviterName,
        inviteCode: inviteCode,
        tripDestination: 'Bali, Indonesia',
        tripStartDate: 'Dec 15, 2024',
        tripEndDate: 'Dec 22, 2024',
      );

      // Assert
      expect(result, true, reason: 'Should successfully send trip invitation email');
    });

    test('sendEmail should send generic email successfully', () async {
      // Arrange
      const toEmail = 'test@example.com';
      const subject = 'Test Email';
      const htmlContent = '<h1>Hello World</h1><p>This is a test email.</p>';
      const textContent = 'Hello World\nThis is a test email.';

      // Act
      final result = await emailService.sendEmail(
        toEmail: toEmail,
        subject: subject,
        htmlContent: htmlContent,
        textContent: textContent,
        toName: 'Test User',
      );

      // Assert
      expect(result, true, reason: 'Should successfully send generic email');
    });

    test('sendBulkEmail should send to multiple recipients', () async {
      // Arrange
      const toEmails = ['test1@example.com', 'test2@example.com'];
      const subject = 'Bulk Test Email';
      const htmlContent = '<h1>Bulk Email</h1><p>This is a bulk test email.</p>';

      // Act
      final result = await emailService.sendBulkEmail(
        toEmails: toEmails,
        subject: subject,
        htmlContent: htmlContent,
      );

      // Assert
      expect(result, true, reason: 'Should successfully send bulk email');
    });
  });
}
