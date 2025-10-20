// Quick diagnostic script to check user data sources
// Run with: dart check_user_data.dart

import 'package:supabase_flutter/supabase_flutter.dart';

// TODO: Update these with your Supabase credentials
const supabaseUrl = 'https://ckgaoxajvonazdwpsmai.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNrZ2FveGFqdm9uYXpkd3BzbWFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4NTE0OTIsImV4cCI6MjA3NTQyNzQ5Mn0.poUiysXLCNjZHHTCEOM3CgKgnna32phQXT_Ob6fx7Hg';

void main() async {
  print('='.padRight(60, '='));
  print('🔍 USER DATA DIAGNOSTIC TOOL');
  print('='.padRight(60, '='));
  print('');

  try {
    // Initialize Supabase
    print('📡 Initializing Supabase...');
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    print('✅ Supabase initialized\n');

    final client = Supabase.instance.client;

    // Check 1: Auth Session
    print('1️⃣  CHECKING SUPABASE AUTH SESSION');
    print('-'.padRight(60, '-'));

    final currentUser = client.auth.currentUser;
    if (currentUser != null) {
      print('✅ Auth user found!');
      print('   User ID: ${currentUser.id}');
      print('   Email: ${currentUser.email}');
      print('   Email Verified: ${currentUser.emailConfirmedAt != null}');
      print('   Created: ${currentUser.createdAt}');
      print('   Last Sign In: ${currentUser.lastSignInAt}');
      print('');

      // Extract username from email
      final email = currentUser.email ?? '';
      final username = email.isNotEmpty ? email.split('@')[0] : 'N/A';
      print('   📌 DERIVED USERNAME: "$username"');
      print('   (This is what the app displays)');
      print('');

      // Check 2: Profiles Table
      print('2️⃣  CHECKING PROFILES TABLE');
      print('-'.padRight(60, '-'));

      try {
        final profileData = await client
            .from('profiles')
            .select()
            .eq('id', currentUser.id)
            .single();

        print('✅ Profile found in database!');
        print('   Profile Data:');
        print('   - ID: ${profileData['id']}');
        print('   - Email: ${profileData['email']}');
        print('   - Full Name: ${profileData['full_name'] ?? 'Not set'}');
        print('   - Phone: ${profileData['phone_number'] ?? 'Not set'}');
        print('   - Avatar URL: ${profileData['avatar_url'] ?? 'Not set'}');
        print('   - Created: ${profileData['created_at']}');
        print('   - Updated: ${profileData['updated_at']}');
      } catch (e) {
        print('❌ Profile NOT found in database!');
        print('   Error: $e');
        print('');
        print('⚠️  THIS IS THE ISSUE!');
        print('   Your auth user exists, but profile is missing.');
        print('   Username still shows because it comes from auth email.');
      }
      print('');

      // Check 3: All Profiles (for debugging)
      print('3️⃣  ALL PROFILES IN DATABASE');
      print('-'.padRight(60, '-'));
      try {
        final allProfiles = await client
            .from('profiles')
            .select()
            .limit(10);

        if (allProfiles.isEmpty) {
          print('❌ No profiles found in database');
          print('   Database might be empty or not initialized');
        } else {
          print('✅ Found ${allProfiles.length} profile(s):');
          for (var profile in allProfiles) {
            print('   - ${profile['email']} (ID: ${profile['id']})');
          }
        }
      } catch (e) {
        print('❌ Error fetching profiles: $e');
      }
      print('');

    } else {
      print('❌ No authenticated user found');
      print('   You need to log in first');
      print('');
    }

    // Summary
    print('='.padRight(60, '='));
    print('📊 SUMMARY');
    print('='.padRight(60, '='));

    if (currentUser != null) {
      final email = currentUser.email ?? '';
      final username = email.isNotEmpty ? email.split('@')[0] : 'N/A';

      print('✅ Auth Session: ACTIVE');
      print('✅ Email Available: ${currentUser.email}');
      print('✅ Username Displayed: "$username"');
      print('📍 Source: Supabase Auth (session cache)');
      print('');
      print('💡 KEY INSIGHT:');
      print('   The username "$username" comes from your email address,');
      print('   not from the profiles table. Even if the profiles table');
      print('   is empty, the app can still show your username by');
      print('   extracting it from the email in your auth session.');
    } else {
      print('❌ No active session');
      print('   Log in to the app first, then run this script');
    }

    print('');
    print('='.padRight(60, '='));

  } catch (e, stackTrace) {
    print('❌ ERROR: $e');
    print('Stack trace: $stackTrace');
  }
}
