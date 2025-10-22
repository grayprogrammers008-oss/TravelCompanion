import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Diagnostic script to troubleshoot login issues for remote collaborators
///
/// Run this with: dart diagnose_login_issue.dart
void main() async {
  if (kDebugMode) {
    debugPrint('🔍 Travel Crew Login Diagnostics');
    debugPrint('=' * 60);
  }

  // Configuration
  const supabaseUrl = 'https://ckgaoxajvonazdwpsmai.supabase.co';
  const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNrZ2FveGFqdm9uYXpkd3BzbWFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4NTE0OTIsImV4cCI6MjA3NTQyNzQ5Mn0.poUiysXLCNjZHHTCEOM3CgKgnna32phQXT_Ob6fx7Hg';

  try {
    // Test 1: Initialize Supabase
    if (kDebugMode) {
      debugPrint('\n📡 Test 1: Supabase Connection');
    }
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    if (kDebugMode) {
      debugPrint('✅ Supabase initialized successfully');
      debugPrint('   URL: $supabaseUrl');
    }

    final client = Supabase.instance.client;

    // Test 2: Check network connectivity to Supabase
    if (kDebugMode) {
      debugPrint('\n🌐 Test 2: Network Connectivity');
    }
    try {
      final response = await client.from('profiles').select().limit(1);
      if (kDebugMode) {
        debugPrint('✅ Can connect to Supabase database');
        debugPrint('   Response: ${response.length} records');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Cannot connect to Supabase database');
        debugPrint('   Error: $e');
      }
    }

    // Test 3: Check if email confirmation is required
    if (kDebugMode) {
      debugPrint('\n📧 Test 3: Auth Settings Check');
      debugPrint('⚠️  NOTE: You need to verify these in Supabase Dashboard:');
      debugPrint('   1. Go to: Authentication > Settings');
      debugPrint('   2. Check "Enable email confirmations" setting');
      debugPrint('   3. Check "Email Auth" provider is enabled');
      debugPrint('   4. Check "Site URL" and "Redirect URLs" settings');
    }

    // Test 4: List existing users (if you have permissions)
    if (kDebugMode) {
      debugPrint('\n👥 Test 4: User Accounts');
      debugPrint('⚠️  To check existing users:');
      debugPrint('   1. Go to Supabase Dashboard > Authentication > Users');
      debugPrint('   2. Verify the user account exists');
      debugPrint('   3. Check if "Email Confirmed" = Yes');
      debugPrint('   4. If No, manually confirm the email');
    }

    // Test 5: Try a test login (REPLACE WITH ACTUAL CREDENTIALS TO TEST)
    if (kDebugMode) {
      debugPrint('\n🔐 Test 5: Login Attempt');
      debugPrint('⚠️  IMPORTANT: Update this script with test credentials');
    }

    // Uncomment and replace with actual test credentials:
    /*
    try {
      final email = 'test@example.com'; // REPLACE
      final password = 'test123456'; // REPLACE

      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        if (kDebugMode) {
          debugPrint('✅ Login successful!');
          debugPrint('   User ID: ${response.user!.id}');
          debugPrint('   Email: ${response.user!.email}');
          debugPrint('   Email Confirmed: ${response.user!.emailConfirmedAt != null}');
        }
      }
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Login failed with AuthException');
        debugPrint('   Message: ${e.message}');
        debugPrint('   Status Code: ${e.statusCode}');
      }

      // Common error codes and solutions
      if (e.message.contains('Invalid login credentials')) {
        if (kDebugMode) {
          debugPrint('\n💡 Possible Solutions:');
          debugPrint('   1. User account does not exist - Sign up first');
          debugPrint('   2. Password is incorrect');
          debugPrint('   3. Email is not confirmed (check Supabase dashboard)');
          debugPrint('   4. User was deleted or disabled');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Login failed with error: $e');
      }
    }
    */

    // Test 6: Common issues for international users
    if (kDebugMode) {
      debugPrint('\n🌍 Test 6: International Access Issues');
      debugPrint('For users in India (or other regions), check:');
      debugPrint('   1. Firewall/VPN blocking Supabase (*.supabase.co)');
      debugPrint('   2. Corporate network restrictions');
      debugPrint('   3. Try mobile hotspot to rule out network issues');
      debugPrint('   4. Check if Supabase is accessible: https://status.supabase.com');
      debugPrint('   5. Try accessing Supabase Dashboard from India');
    }

    // Test 7: Check Supabase project settings
    if (kDebugMode) {
      debugPrint('\n⚙️  Test 7: Supabase Project Settings to Verify');
      debugPrint('In Supabase Dashboard, check:');
      debugPrint('   1. Authentication > Providers > Email');
      debugPrint('      - "Enable Email provider" = ON');
      debugPrint('      - "Confirm email" = OFF (for testing)');
      debugPrint('   2. Authentication > URL Configuration');
      debugPrint('      - Site URL matches your app');
      debugPrint('      - Redirect URLs include your app scheme');
      debugPrint('   3. Authentication > Email Templates');
      debugPrint('      - Check if confirmation emails are being sent');
      debugPrint('   4. Project Settings > API');
      debugPrint('      - Verify anon key matches app config');
    }

    if (kDebugMode) {
      debugPrint('\n' + '=' * 60);
      debugPrint('✅ Diagnostics Complete!');
      debugPrint('=' * 60);
    }

  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('❌ CRITICAL ERROR: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
}
