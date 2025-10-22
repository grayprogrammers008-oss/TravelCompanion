// Password Reset Helper
// Run with: dart reset_password_helper.dart <your-email@example.com>
//
// Sends a password reset email to the specified address.
// Use this if you can't login and want to reset your password.

import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://ckgaoxajvonazdwpsmai.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNrZ2FveGFqdm9uYXpkd3BzbWFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4NTE0OTIsImV4cCI6MjA3NTQyNzQ5Mn0.poUiysXLCNjZHHTCEOM3CgKgnna32phQXT_Ob6fx7Hg';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ ERROR: Please provide an email address');
    print('');
    print('Usage:');
    print('  dart reset_password_helper.dart <email@example.com>');
    print('');
    print('Example:');
    print('  dart reset_password_helper.dart john.doe@gmail.com');
    print('');
    return;
  }

  final email = args[0];

  // Basic email validation
  if (!email.contains('@') || !email.contains('.')) {
    print('❌ ERROR: Invalid email format');
    print('   Email must contain @ and domain (e.g., user@example.com)');
    return;
  }

  print('════════════════════════════════════════════════════════');
  print('🔑 PASSWORD RESET HELPER');
  print('════════════════════════════════════════════════════════');
  print('');
  print('📧 Email: $email');
  print('🕐 Time: ${DateTime.now()}');
  print('');

  try {
    // Initialize Supabase
    print('📡 Connecting to Supabase...');
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    final client = Supabase.instance.client;
    print('✅ Connected\n');

    // Send password reset email
    print('📨 Sending password reset email...');
    print('');

    await client.auth.resetPasswordForEmail(email);

    print('✅ SUCCESS!');
    print('');
    print('════════════════════════════════════════════════════════');
    print('📬 PASSWORD RESET EMAIL SENT');
    print('════════════════════════════════════════════════════════');
    print('');
    print('A password reset email has been sent to:');
    print('   📧 $email');
    print('');
    print('📋 What to do next:');
    print('');
    print('1. Check your email inbox');
    print('   - Look for email from: noreply@mail.app.supabase.io');
    print('   - Subject: "Reset your password"');
    print('   - Also check spam/junk folder');
    print('');
    print('2. Click the reset link in the email');
    print('   - Link expires in 1 hour');
    print('   - Opens password reset page');
    print('');
    print('3. Set your new password');
    print('   - Choose a strong password');
    print('   - Confirm the password');
    print('   - Submit the form');
    print('');
    print('4. Login with new password');
    print('   - Open the app');
    print('   - Enter your email: $email');
    print('   - Enter your NEW password');
    print('   - Click "Sign In"');
    print('');
    print('════════════════════════════════════════════════════════');
    print('');
    print('⏰ If email doesn\'t arrive in 5 minutes:');
    print('   1. Check spam/junk folder');
    print('   2. Run this script again');
    print('   3. Try a different email address');
    print('');
    print('⚠️  If you get rate limited:');
    print('   Wait 1 hour before trying again');
    print('   Supabase limits password reset attempts');
    print('');
    print('💡 Alternative solutions:');
    print('   - Try logging in with your current password');
    print('   - Use the diagnostic tool: dart diagnose_email_issue.dart $email');
    print('   - Sign out and try signup again');
    print('');
    print('════════════════════════════════════════════════════════');
    print('✅ DONE');
    print('════════════════════════════════════════════════════════');
    print('');

  } on AuthException catch (e) {
    print('');
    print('════════════════════════════════════════════════════════');
    print('❌ PASSWORD RESET FAILED');
    print('════════════════════════════════════════════════════════');
    print('');
    print('Error: ${e.message}');
    print('');

    // Provide specific guidance based on error
    if (e.message.toLowerCase().contains('rate limit')) {
      print('🚫 RATE LIMITED');
      print('');
      print('You\'ve made too many password reset attempts.');
      print('');
      print('What to do:');
      print('  1. Wait 1 hour before trying again');
      print('  2. Check your email - reset email may have been sent earlier');
      print('  3. Try logging in instead of resetting password');
      print('');
    } else if (e.message.toLowerCase().contains('not found') ||
        e.message.toLowerCase().contains('invalid')) {
      print('❓ EMAIL NOT FOUND');
      print('');
      print('This email address is not registered in Supabase Auth.');
      print('');
      print('What to do:');
      print('  1. Double-check the email address for typos');
      print('  2. Try signing up instead of resetting password');
      print('  3. Use a different email address');
      print('');
    } else if (e.message.toLowerCase().contains('email')) {
      print('📧 EMAIL ISSUE');
      print('');
      print('There was a problem with the email address.');
      print('');
      print('What to do:');
      print('  1. Check that email format is correct');
      print('  2. Try a different email provider (Gmail, Outlook, etc.)');
      print('  3. Contact support if problem persists');
      print('');
    } else {
      print('🔧 UNKNOWN ERROR');
      print('');
      print('An unexpected error occurred.');
      print('');
      print('What to do:');
      print('  1. Check your internet connection');
      print('  2. Verify Supabase credentials in supabase_config.dart');
      print('  3. Run diagnostic: dart diagnose_email_issue.dart $email');
      print('  4. Contact support with this error message');
      print('');
    }

    print('════════════════════════════════════════════════════════');
    print('');

  } catch (e, stackTrace) {
    print('');
    print('════════════════════════════════════════════════════════');
    print('❌ UNEXPECTED ERROR');
    print('════════════════════════════════════════════════════════');
    print('');
    print('Error: $e');
    print('');
    print('Stack trace:');
    print(stackTrace);
    print('');
    print('What to do:');
    print('  1. Check your internet connection');
    print('  2. Verify Supabase configuration');
    print('  3. Run: dart test_supabase_connection.dart');
    print('  4. Contact support if problem persists');
    print('');
    print('════════════════════════════════════════════════════════');
    print('');
  }
}
