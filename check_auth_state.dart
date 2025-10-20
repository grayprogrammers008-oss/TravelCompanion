// Auth State Checker
// Run with: dart check_auth_state.dart
//
// This script checks the current authentication state and session details.
// Use this to see if you have an active session even though the user
// doesn't appear in Supabase Auth Users table.

import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://ckgaoxajvonazdwpsmai.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNrZ2FveGFqdm9uYXpkd3BzbWFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4NTE0OTIsImV4cCI6MjA3NTQyNzQ5Mn0.poUiysXLCNjZHHTCEOM3CgKgnna32phQXT_Ob6fx7Hg';

void main() async {
  print('═' * 70);
  print('🔍 AUTH STATE CHECKER');
  print('═' * 70);
  print('');
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

    // Check current session
    print('─' * 70);
    print('1. CURRENT AUTH SESSION');
    print('─' * 70);

    final session = client.auth.currentSession;
    final user = client.auth.currentUser;

    if (session == null) {
      print('❌ No active session found');
      print('');
      print('📋 This means:');
      print('   • You are NOT currently logged in');
      print('   • No cached authentication data');
      print('   • Fresh state for signup/login');
      print('');
      print('✅ GOOD NEWS: You can try signing up now!');
      print('   The "already exists" error must be from something else.');
      print('');
    } else {
      print('✅ Active session found!');
      print('');
      print('📊 Session Details:');
      print('   Access Token: ${session.accessToken.substring(0, 20)}...');
      print('   Refresh Token: ${session.refreshToken?.substring(0, 20) ?? 'None'}...');
      print('   Token Type: ${session.tokenType}');
      print('   Expires At: ${session.expiresAt != null ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000) : 'Unknown'}');
      print('');

      if (user != null) {
        print('👤 User Details:');
        print('   User ID: ${user.id}');
        print('   Email: ${user.email ?? 'Not set'}');
        print('   Email Confirmed: ${user.emailConfirmedAt != null ? 'Yes (${user.emailConfirmedAt})' : 'No'}');
        print('   Phone: ${user.phone ?? 'Not set'}');
        print('   Created: ${user.createdAt}');
        print('   Last Sign In: ${user.lastSignInAt ?? 'Never'}');
        print('   Updated: ${user.updatedAt ?? 'Never'}');
        print('');

        // User metadata
        if (user.userMetadata != null && user.userMetadata!.isNotEmpty) {
          print('📝 User Metadata:');
          user.userMetadata!.forEach((key, value) {
            print('   $key: $value');
          });
          print('');
        }

        // App metadata
        if (user.appMetadata != null && user.appMetadata!.isNotEmpty) {
          print('🔧 App Metadata:');
          user.appMetadata!.forEach((key, value) {
            print('   $key: $value');
          });
          print('');
        }

        print('🎯 FINDING: You ARE logged in with email: ${user.email}');
        print('');
        print('❗ This explains the "already exists" error!');
        print('   You can\'t signup because you\'re already authenticated.');
        print('');
      }
    }

    // Check profiles table
    print('─' * 70);
    print('2. PROFILES TABLE CHECK');
    print('─' * 70);

    if (user != null) {
      print('Checking for profile with user ID: ${user.id}');
      print('');

      try {
        final profile = await client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (profile == null) {
          print('❌ No profile found in profiles table');
          print('');
          print('📋 This is the ORPHANED USER scenario:');
          print('   • Auth user exists (you\'re logged in)');
          print('   • But no profile in app database');
          print('   • This causes issues in the app');
          print('');
          print('💡 SOLUTION: Create the missing profile');
          print('');
        } else {
          print('✅ Profile found:');
          print('   ID: ${profile['id']}');
          print('   Email: ${profile['email'] ?? 'Not set'}');
          print('   Full Name: ${profile['full_name'] ?? 'Not set'}');
          print('   Phone: ${profile['phone_number'] ?? 'Not set'}');
          print('   Avatar: ${profile['avatar_url'] ?? 'Not set'}');
          print('   Created: ${profile['created_at']}');
          print('   Updated: ${profile['updated_at']}');
          print('');
          print('✅ Everything looks good! Profile exists.');
          print('');
        }
      } catch (e) {
        print('❌ Error checking profiles table: $e');
        print('');
      }
    } else {
      print('⏭️  Skipping (no active session)');
      print('');

      // Try to find ANY profiles
      print('Checking if ANY profiles exist in the table...');
      try {
        final allProfiles = await client
            .from('profiles')
            .select('id, email, created_at')
            .limit(5);

        if (allProfiles.isEmpty) {
          print('❌ Profiles table is completely empty');
          print('');
          print('📋 This means:');
          print('   • No users have profiles in the app database');
          print('   • Fresh installation or database reset');
          print('   • First signup will create the first profile');
          print('');
        } else {
          print('✅ Found ${allProfiles.length} profile(s):');
          for (var profile in allProfiles) {
            print('   - ${profile['email'] ?? 'No email'} (created ${profile['created_at']})');
          }
          print('');
        }
      } catch (e) {
        print('❌ Error checking profiles: $e');
        print('   (This might be a permissions issue)');
        print('');
      }
    }

    // Summary
    print('═' * 70);
    print('📊 SUMMARY & RECOMMENDATIONS');
    print('═' * 70);
    print('');

    if (session != null && user != null) {
      print('🎯 FINDING: You are currently logged in');
      print('');
      print('Email: ${user.email}');
      print('User ID: ${user.id}');
      print('');
      print('❗ This is why signup fails with "already exists"');
      print('');
      print('💡 RECOMMENDED ACTIONS:');
      print('');
      print('Option 1: Sign out and try signup again');
      print('─────────────────────────────────────────');
      print('await Supabase.instance.client.auth.signOut();');
      print('// Then try signup');
      print('');
      print('Option 2: Just use the app (you\'re already in!)');
      print('─────────────────────────────────────────────────');
      print('You don\'t need to signup - you\'re already authenticated.');
      print('Just open the app and it should work.');
      print('');
      print('Option 3: If profile is missing, create it');
      print('──────────────────────────────────────────────');
      print('Run this in Supabase SQL Editor:');
      print('');
      print('INSERT INTO public.profiles (id, email, created_at, updated_at)');
      print('VALUES (');
      print('  \'${user.id}\',');
      print('  \'${user.email}\',');
      print('  NOW(),');
      print('  NOW()');
      print(');');
      print('');
    } else {
      print('🎯 FINDING: No active session');
      print('');
      print('✅ You are NOT logged in');
      print('✅ No cached authentication');
      print('✅ Fresh state for signup');
      print('');
      print('❓ BUT you\'re getting "already exists" error?');
      print('');
      print('This is VERY unusual. Possible explanations:');
      print('');
      print('1. Email exists but you can\'t see it (permissions issue)');
      print('2. Different Supabase project (check URL/keys)');
      print('3. App is using different credentials than this script');
      print('4. Browser/app has separate cached session');
      print('');
      print('💡 RECOMMENDED ACTIONS:');
      print('');
      print('1. Clear all app data/cache');
      print('   - Web: Clear browser cookies, localStorage, sessionStorage');
      print('   - Mobile: Clear app data or reinstall');
      print('');
      print('2. Verify Supabase project');
      print('   - Check that app uses same URL: $supabaseUrl');
      print('   - Verify in lib/core/config/supabase_config.dart');
      print('');
      print('3. Try signing up with a DIFFERENT email');
      print('   - Use a test email to see if signup works at all');
      print('   - This helps identify if it\'s email-specific or system-wide');
      print('');
      print('4. Check Supabase dashboard logs');
      print('   - Go to Supabase Dashboard → Logs → Auth');
      print('   - Look for recent signup attempts with nithyaganesan53@gmail.com');
      print('   - Check what error is returned');
      print('');
    }

    print('═' * 70);
    print('✅ CHECK COMPLETE');
    print('═' * 70);
    print('');

  } catch (e, stackTrace) {
    print('');
    print('❌ ERROR: $e');
    print('');
    print('Stack trace:');
    print(stackTrace);
    print('');
    print('This error prevented the check from completing.');
    print('Please verify your Supabase configuration and internet connection.');
    print('');
  }
}
