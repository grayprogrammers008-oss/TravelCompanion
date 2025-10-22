// Email Existence Paradox Diagnostic Tool
// Run with: dart diagnose_email_issue.dart <your-email@example.com>
//
// This script investigates why an email appears to "already exist" in Supabase
// even though it's not visible in the database or dashboard.

import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://ckgaoxajvonazdwpsmai.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNrZ2FveGFqdm9uYXpkd3BzbWFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4NTE0OTIsImV4cCI6MjA3NTQyNzQ5Mn0.poUiysXLCNjZHHTCEOM3CgKgnna32phQXT_Ob6fx7Hg';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ ERROR: Please provide an email address as argument');
    print('Usage: dart diagnose_email_issue.dart <email@example.com>');
    return;
  }

  final emailToCheck = args[0];

  print('═' * 70);
  print('🔍 EMAIL EXISTENCE PARADOX DIAGNOSTIC TOOL');
  print('═' * 70);
  print('');
  print('📧 Investigating: $emailToCheck');
  print('🕐 Time: ${DateTime.now()}');
  print('');

  try {
    // Initialize Supabase
    print('📡 Initializing Supabase...');
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    final client = Supabase.instance.client;
    print('✅ Connected to Supabase\n');

    // Test 1: Check Current Auth Session
    print('─' * 70);
    print('TEST 1: CURRENT AUTH SESSION');
    print('─' * 70);

    final currentUser = client.auth.currentUser;
    if (currentUser != null) {
      print('✅ Active session found');
      print('   User ID: ${currentUser.id}');
      print('   Email: ${currentUser.email}');
      print('   Email Confirmed: ${currentUser.emailConfirmedAt != null}');
      print('   Created: ${currentUser.createdAt}');
      print('   Last Sign In: ${currentUser.lastSignInAt}');

      if (currentUser.email == emailToCheck) {
        print('');
        print('✅ FINDING: You are currently logged in with this email!');
        print('   This is why signup fails - you\'re already authenticated.');
        print('');
        print('💡 SOLUTION: Sign out first before trying to signup again.');
      }
    } else {
      print('ℹ️  No active session (not logged in)');
    }
    print('');

    // Test 2: Check Profiles Table
    print('─' * 70);
    print('TEST 2: PROFILES TABLE CHECK');
    print('─' * 70);

    try {
      final profiles = await client
          .from('profiles')
          .select()
          .eq('email', emailToCheck);

      if (profiles.isEmpty) {
        print('❌ Email NOT found in profiles table');
        print('   This means no profile record exists in app database');
      } else {
        print('✅ Found ${profiles.length} profile(s):');
        for (var profile in profiles) {
          print('   - ID: ${profile['id']}');
          print('   - Email: ${profile['email']}');
          print('   - Full Name: ${profile['full_name'] ?? 'Not set'}');
          print('   - Created: ${profile['created_at']}');
          print('   - Updated: ${profile['updated_at']}');
        }
      }
    } catch (e) {
      print('❌ Error querying profiles table: $e');
      print('   (This might be a permissions issue)');
    }
    print('');

    // Test 3: Try Password Reset (Tests if email exists in Auth)
    print('─' * 70);
    print('TEST 3: AUTH EXISTENCE CHECK (Password Reset Test)');
    print('─' * 70);
    print('ℹ️  Testing if Supabase Auth recognizes this email...');
    print('   (This will send a password reset email if it exists)');
    print('');

    try {
      await client.auth.resetPasswordForEmail(emailToCheck);
      print('✅ SUCCESS: Supabase Auth accepted the email!');
      print('');
      print('🎯 FINDING: Email EXISTS in Supabase Auth (auth.users table)');
      print('   Even though you can\'t see it, the email is registered.');
      print('');
      print('📧 A password reset email has been sent to: $emailToCheck');
      print('   Check your inbox (including spam folder)');
    } on AuthException catch (e) {
      print('❌ AUTH ERROR: ${e.message}');

      if (e.message.toLowerCase().contains('not found') ||
          e.message.toLowerCase().contains('invalid')) {
        print('');
        print('🎯 FINDING: Email does NOT exist in Supabase Auth');
        print('   The "already exists" error might be from somewhere else.');
      } else if (e.message.toLowerCase().contains('rate limit')) {
        print('');
        print('⚠️  Rate limited - too many requests');
        print('   Wait a few minutes and try again');
      }
    } catch (e) {
      print('❌ Unexpected error: $e');
    }
    print('');

    // Test 4: Attempt Signup (Controlled test)
    print('─' * 70);
    print('TEST 4: SIGNUP ATTEMPT TEST');
    print('─' * 70);
    print('ℹ️  Attempting signup with test password...');
    print('   (This will fail if email exists, confirming the issue)');
    print('');

    try {
      await client.auth.signUp(
        email: emailToCheck,
        password: 'TestPassword123!@#', // Dummy password for testing
      );

      print('❌ UNEXPECTED: Signup succeeded!');
      print('   This means the email did NOT previously exist.');
      print('');
      print('⚠️  WARNING: A new account was just created!');
      print('   You should delete this test account from Supabase dashboard.');
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already') ||
          e.message.toLowerCase().contains('exists') ||
          e.message.toLowerCase().contains('registered')) {
        print('✅ CONFIRMED: Signup failed with "already exists" error');
        print('   Error message: ${e.message}');
        print('');
        print('🎯 FINDING: Email DEFINITELY exists in Supabase Auth!');
      } else if (e.message.toLowerCase().contains('email') &&
          e.message.toLowerCase().contains('confirm')) {
        print('✅ Signup succeeded but requires email confirmation');
        print('   Error message: ${e.message}');
        print('');
        print('🎯 FINDING: Email exists but is unconfirmed');
      } else {
        print('❓ UNCLEAR: Different error occurred');
        print('   Error message: ${e.message}');
      }
    } catch (e) {
      print('❌ Unexpected error: $e');
    }
    print('');

    // Summary and Recommendations
    print('═' * 70);
    print('📊 DIAGNOSTIC SUMMARY');
    print('═' * 70);
    print('');
    print('🔍 Possible Scenarios:');
    print('');
    print('Scenario 1: ALREADY LOGGED IN');
    print('   - You have an active session with this email');
    print('   - Solution: Sign out, then try signup or login');
    print('   - Command: Check app settings or use logout button');
    print('');
    print('Scenario 2: ORPHANED AUTH USER (No Profile)');
    print('   - Email exists in auth.users (Supabase Auth)');
    print('   - But no profile in public.profiles (app database)');
    print('   - Solution: Login with existing credentials, profile will be created');
    print('   - Alternative: Manually create profile in database');
    print('');
    print('Scenario 3: UNCONFIRMED EMAIL');
    print('   - Account created but email not confirmed');
    print('   - Solution: Check email for confirmation link');
    print('   - Alternative: Resend confirmation email');
    print('');
    print('Scenario 4: CACHED SESSION');
    print('   - Old session stored locally by Supabase SDK');
    print('   - Solution: Clear app data/cache');
    print('   - On web: Clear browser cookies/localStorage');
    print('   - On mobile: Clear app data or reinstall');
    print('');
    print('Scenario 5: DELETED BUT NOT PURGED');
    print('   - User was deleted but still in auth system');
    print('   - Solution: Contact Supabase support or use admin API');
    print('');
    print('─' * 70);
    print('💡 RECOMMENDED ACTIONS (Try in order):');
    print('─' * 70);
    print('');
    print('1. Sign out from the app');
    print('   - Open app → Settings → Logout');
    print('   - Or manually: await Supabase.instance.client.auth.signOut()');
    print('');
    print('2. Clear local storage/cache');
    print('   - Web: Clear browser cookies and localStorage');
    print('   - Mobile: Clear app data or reinstall app');
    print('');
    print('3. Try logging in (not signup)');
    print('   - If account exists, use login instead of signup');
    print('   - Use the password you originally set');
    print('');
    print('4. Check spam folder for confirmation email');
    print('   - Email from: noreply@mail.app.supabase.io');
    print('   - Subject: "Confirm your signup"');
    print('');
    print('5. Use password reset to access account');
    print('   - A reset email was sent during this diagnostic');
    print('   - Click link in email to set new password');
    print('   - Then login with new password');
    print('');
    print('6. Manual database cleanup (Advanced)');
    print('   - Go to Supabase Dashboard → Authentication → Users');
    print('   - Find and delete the problematic user');
    print('   - Then try signup again');
    print('');
    print('─' * 70);
    print('🔧 DEVELOPER NOTES');
    print('─' * 70);
    print('');
    print('Why this happens:');
    print('• Supabase Auth (auth.users) is separate from app DB (public.profiles)');
    print('• Signup creates user in auth.users immediately');
    print('• Profile creation in public.profiles might fail silently');
    print('• Result: Email exists in auth but no profile in app');
    print('');
    print('How to prevent:');
    print('1. Use database triggers to auto-create profiles:');
    print('   CREATE TRIGGER on_auth_user_created');
    print('   AFTER INSERT ON auth.users');
    print('   FOR EACH ROW EXECUTE PROCEDURE handle_new_user();');
    print('');
    print('2. Add error handling in signup code:');
    print('   - Verify profile creation succeeded');
    print('   - Retry profile creation on failure');
    print('   - Show clear error messages to user');
    print('');
    print('3. Implement auto-recovery in getCurrentUser():');
    print('   - If auth user exists but no profile');
    print('   - Automatically create missing profile');
    print('');
    print('═' * 70);
    print('📝 DIAGNOSTIC COMPLETE');
    print('═' * 70);
    print('');
    print('Generated: ${DateTime.now()}');
    print('Email checked: $emailToCheck');
    print('');
    print('💬 Next steps: Review the scenarios above and try recommended actions.');
    print('');

  } catch (e, stackTrace) {
    print('');
    print('❌ FATAL ERROR: $e');
    print('');
    print('Stack trace:');
    print(stackTrace);
    print('');
    print('This error prevented the diagnostic from completing.');
    print('Please check your Supabase configuration and internet connection.');
  }
}
