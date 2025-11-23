import 'package:travel_crew/core/services/email_service.dart';

/// Send a test trip invitation email to verify Brevo integration
///
/// Run with: dart run scripts/send_test_email.dart
void main() async {
  print('📧 Sending test email to vinothvsbe@gmail.com...\n');

  final emailService = EmailService();

  // First, test connection
  print('🔍 Testing Brevo API connection...');
  final isConnected = await emailService.testConnection();

  if (!isConnected) {
    print('❌ Failed to connect to Brevo API');
    return;
  }

  print('✅ Connection successful!\n');

  // Send trip invitation email
  print('📨 Sending trip invitation email...');
  final result = await emailService.sendTripInvite(
    toEmail: 'vinothvsbe@gmail.com',
    toName: 'Vinoth',
    tripName: 'TravelCompanion Integration Test',
    inviterName: 'Claude (Development Team)',
    inviteCode: 'TEST2024',
    tripDestination: 'Brevo Email Service',
    tripStartDate: 'November 15, 2025',
    tripEndDate: 'November 15, 2025',
  );

  if (result) {
    print('\n✅ SUCCESS! Email sent to vinothvsbe@gmail.com');
    print('📬 Please check your inbox (and spam folder)');
    print('');
    print('Email Details:');
    print('  To: vinothvsbe@gmail.com');
    print('  Subject: 🎉 You\'re invited to TravelCompanion Integration Test!');
    print('  From: TravelCompanion <palkarfoods224@gmail.com>');
    print('');
    print('The email includes:');
    print('  ✨ Beautiful Brilliant purple gradient header');
    print('  📍 Trip destination: Brevo Email Service');
    print('  📅 Trip dates: November 15, 2025');
    print('  🔑 Invite code: TEST2024');
    print('  🔗 Deep link button to accept invitation');
  } else {
    print('\n❌ FAILED to send email');
    print('Please check the debug output above for error details');
  }
}
