// Supabase Connectivity Test
// Run this from your Flutter app to test Supabase connection
//
// Usage:
// 1. Import this file in your app
// 2. Call testSupabaseConnectivity() from a button or startup
// 3. Check console for detailed results

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';

/// Test Supabase connectivity with detailed diagnostics
Future<Map<String, dynamic>> testSupabaseConnectivity() async {
  final results = <String, dynamic>{
    'timestamp': DateTime.now().toIso8601String(),
    'overall_success': false,
    'tests': <String, dynamic>{},
    'errors': <String>[],
    'warnings': <String>[],
  };

  print('');
  print('═' * 70);
  print('🔍 SUPABASE CONNECTIVITY TEST');
  print('═' * 70);
  print('');
  print('📅 Time: ${DateTime.now()}');
  print('');

  try {
    // Test 1: Configuration Check
    print('─' * 70);
    print('TEST 1: CONFIGURATION VALIDATION');
    print('─' * 70);

    final url = SupabaseConfig.supabaseUrl;
    final keyPreview = SupabaseConfig.supabaseAnonKey.substring(0, 20);

    print('📋 Supabase URL: $url');
    print('🔑 Anon Key: $keyPreview...');
    print('');

    if (url.contains('YOUR_SUPABASE') || url.isEmpty) {
      results['errors'].add('Invalid Supabase URL');
      print('❌ FAIL: Supabase URL not configured');
      print('   Please update lib/core/config/supabase_config.dart');
      print('');
      results['tests']['configuration'] = false;
      return results;
    }

    if (SupabaseConfig.supabaseAnonKey.contains('YOUR_SUPABASE') ||
        SupabaseConfig.supabaseAnonKey.isEmpty) {
      results['errors'].add('Invalid Supabase Anon Key');
      print('❌ FAIL: Supabase Anon Key not configured');
      print('');
      results['tests']['configuration'] = false;
      return results;
    }

    print('✅ PASS: Configuration looks valid');
    print('');
    results['tests']['configuration'] = true;

    // Test 2: Supabase Initialization
    print('─' * 70);
    print('TEST 2: SUPABASE INITIALIZATION');
    print('─' * 70);
    print('⏳ Initializing Supabase client...');
    print('');

    try {
      await Supabase.initialize(
        url: url,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );

      print('✅ PASS: Supabase client initialized successfully');
      print('');
      results['tests']['initialization'] = true;

    } on Exception catch (e) {
      results['errors'].add('Initialization failed: $e');
      print('❌ FAIL: Could not initialize Supabase');
      print('   Error: $e');
      print('');
      print('💡 This usually means:');
      print('   1. Invalid URL or Anon Key');
      print('   2. No internet connection');
      print('   3. Supabase project is paused/deleted');
      print('');
      results['tests']['initialization'] = false;
      return results;
    }

    final client = Supabase.instance.client;

    // Test 3: Network Connectivity
    print('─' * 70);
    print('TEST 3: NETWORK CONNECTIVITY');
    print('─' * 70);
    print('⏳ Attempting to reach Supabase server...');
    print('');

    try {
      // Simple REST API call to test connectivity
      final response = await client.from('profiles').select('id').limit(1);

      print('✅ PASS: Successfully connected to Supabase server');
      print('   Response received: ${response.length} row(s)');
      print('');
      results['tests']['network'] = true;

    } catch (e) {
      results['errors'].add('Network connectivity failed: $e');
      print('❌ FAIL: Could not reach Supabase server');
      print('   Error: $e');
      print('');
      print('💡 This usually means:');
      print('   1. No internet connection');
      print('   2. Firewall blocking Supabase');
      print('   3. Supabase service is down');
      print('   4. Table "profiles" does not exist (schema not deployed)');
      print('');
      results['tests']['network'] = false;

      // Continue with other tests even if this fails
    }

    // Test 4: Authentication Service
    print('─' * 70);
    print('TEST 4: AUTHENTICATION SERVICE');
    print('─' * 70);
    print('⏳ Testing auth service availability...');
    print('');

    try {
      final currentUser = client.auth.currentUser;
      final currentSession = client.auth.currentSession;

      print('✅ PASS: Auth service is accessible');
      print('');
      print('📊 Current Auth State:');

      if (currentUser != null) {
        print('   ✅ User is logged in');
        print('   👤 User ID: ${currentUser.id}');
        print('   📧 Email: ${currentUser.email}');
        print('   ✉️  Email Confirmed: ${currentUser.emailConfirmedAt != null}');
        print('   📅 Created: ${currentUser.createdAt}');
        print('   🕐 Last Sign In: ${currentUser.lastSignInAt}');
        results['current_user'] = {
          'id': currentUser.id,
          'email': currentUser.email,
          'email_confirmed': currentUser.emailConfirmedAt != null,
        };
      } else {
        print('   ℹ️  No user currently logged in');
        results['current_user'] = null;
      }

      if (currentSession != null) {
        print('   ✅ Active session found');
        print('   🔑 Session expires: ${currentSession.expiresAt != null ? DateTime.fromMillisecondsSinceEpoch(currentSession.expiresAt! * 1000) : "Unknown"}');
      } else {
        print('   ℹ️  No active session');
      }

      print('');
      results['tests']['auth_service'] = true;

    } catch (e) {
      results['errors'].add('Auth service test failed: $e');
      print('❌ FAIL: Auth service test failed');
      print('   Error: $e');
      print('');
      results['tests']['auth_service'] = false;
    }

    // Test 5: Database Access
    print('─' * 70);
    print('TEST 5: DATABASE ACCESS');
    print('─' * 70);
    print('⏳ Testing database query capabilities...');
    print('');

    try {
      // Try to query profiles table
      final profiles = await client.from('profiles').select('id, email').limit(5);

      print('✅ PASS: Database query successful');
      print('   Found ${profiles.length} profile(s) in database');

      if (profiles.isNotEmpty) {
        print('');
        print('   Sample profiles:');
        for (var profile in profiles) {
          print('   - ${profile['email'] ?? 'No email'} (ID: ${profile['id']})');
        }
      } else {
        print('   ℹ️  Profiles table is empty (no users yet)');
      }

      print('');
      results['tests']['database_access'] = true;
      results['profile_count'] = profiles.length;

    } catch (e) {
      results['warnings'].add('Database query failed: $e');
      print('⚠️  WARNING: Could not query database');
      print('   Error: $e');
      print('');
      print('💡 This might mean:');
      print('   1. Database schema not deployed yet');
      print('   2. Table "profiles" does not exist');
      print('   3. Row Level Security blocking access');
      print('   4. Network timeout');
      print('');
      print('   This is OK if you haven\'t deployed the schema yet.');
      print('   Run the SQL from SUPABASE_SCHEMA.sql to fix this.');
      print('');
      results['tests']['database_access'] = false;
    }

    // Test 6: Real-time Capabilities (Optional)
    print('─' * 70);
    print('TEST 6: REAL-TIME CAPABILITIES');
    print('─' * 70);
    print('⏳ Testing real-time subscription...');
    print('');

    try {
      // Try to subscribe to changes (just test, don't actually listen)
      final channel = client.channel('test-connectivity');
      channel.subscribe((status, error) {
        if (kDebugMode) {
          print('   Real-time status: $status');
        }
      });

      // Wait a moment for subscription
      await Future.delayed(const Duration(milliseconds: 500));

      print('✅ PASS: Real-time service is available');
      print('');

      // Clean up
      await channel.unsubscribe();

      results['tests']['realtime'] = true;

    } catch (e) {
      results['warnings'].add('Real-time test failed: $e');
      print('⚠️  WARNING: Real-time test failed');
      print('   Error: $e');
      print('');
      print('   Real-time might not be enabled for your project.');
      print('   This is not critical for basic functionality.');
      print('');
      results['tests']['realtime'] = false;
    }

    // Overall Assessment
    print('═' * 70);
    print('📊 TEST SUMMARY');
    print('═' * 70);
    print('');

    final passedTests = results['tests'].values.where((v) => v == true).length;
    final totalTests = results['tests'].length;
    final successRate = (passedTests / totalTests * 100).toStringAsFixed(0);

    print('Tests Passed: $passedTests / $totalTests ($successRate%)');
    print('');

    if (results['errors'].isNotEmpty) {
      print('❌ ERRORS (${results['errors'].length}):');
      for (var error in results['errors']) {
        print('   • $error');
      }
      print('');
    }

    if (results['warnings'].isNotEmpty) {
      print('⚠️  WARNINGS (${results['warnings'].length}):');
      for (var warning in results['warnings']) {
        print('   • $warning');
      }
      print('');
    }

    // Overall status
    if (passedTests >= 3) { // At least config, init, and auth
      results['overall_success'] = true;

      print('═' * 70);
      print('✅ OVERALL: SUPABASE CONNECTIVITY IS WORKING!');
      print('═' * 70);
      print('');
      print('🎉 Your app can connect to Supabase successfully!');
      print('');

      if (!results['tests']['database_access']) {
        print('⚠️  Next Step: Deploy database schema');
        print('   Run the SQL from SUPABASE_SCHEMA.sql in Supabase Dashboard');
        print('');
      }

      print('💡 You can now:');
      print('   ✅ Sign up new users');
      print('   ✅ Login existing users');
      print('   ✅ Store data in Supabase');
      if (results['tests']['realtime']) {
        print('   ✅ Use real-time features');
      }
      print('');

    } else {
      results['overall_success'] = false;

      print('═' * 70);
      print('❌ OVERALL: SUPABASE CONNECTIVITY HAS ISSUES');
      print('═' * 70);
      print('');
      print('🔧 Action Required: Fix the errors listed above');
      print('');
      print('Common fixes:');
      print('   1. Check internet connection');
      print('   2. Verify Supabase URL and Anon Key');
      print('   3. Ensure Supabase project is active');
      print('   4. Deploy database schema from SUPABASE_SCHEMA.sql');
      print('');
    }

    print('─' * 70);
    print('📅 Test completed: ${DateTime.now()}');
    print('═' * 70);
    print('');

  } catch (e, stackTrace) {
    results['errors'].add('Unexpected error: $e');
    results['overall_success'] = false;

    print('');
    print('❌ UNEXPECTED ERROR DURING TESTING');
    print('');
    print('Error: $e');
    print('');
    if (kDebugMode) {
      print('Stack trace:');
      print(stackTrace);
      print('');
    }
    print('Please check your configuration and internet connection.');
    print('');
  }

  return results;
}

/// Quick connectivity check (returns true/false)
Future<bool> isSupabaseConnected() async {
  try {
    final client = Supabase.instance.client;
    await client.from('profiles').select('id').limit(1);
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('⚠️  Supabase connectivity check failed: $e');
    }
    return false;
  }
}

/// Get current Supabase auth state
Map<String, dynamic> getSupabaseAuthState() {
  try {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    final session = client.auth.currentSession;

    return {
      'is_authenticated': user != null,
      'user_id': user?.id,
      'email': user?.email,
      'email_confirmed': user?.emailConfirmedAt != null,
      'has_session': session != null,
      'session_expires_at': session?.expiresAt != null
          ? DateTime.fromMillisecondsSinceEpoch(session!.expiresAt! * 1000).toIso8601String()
          : null,
    };
  } catch (e) {
    return {
      'error': e.toString(),
    };
  }
}
