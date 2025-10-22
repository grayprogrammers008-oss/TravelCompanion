import 'package:flutter/foundation.dart';
import 'lib/core/network/supabase_client.dart';
import 'lib/core/config/supabase_config.dart';

/// Test script to verify Supabase connection
/// Run with: dart run test_supabase_connection.dart
void main() async {
  print('🔍 Testing Supabase Connection...\n');

  print('📋 Configuration:');
  print('   URL: ${SupabaseConfig.supabaseUrl}');
  print('   Anon Key: ${SupabaseConfig.supabaseAnonKey.substring(0, 20)}...\n');

  try {
    print('⏳ Initializing Supabase...');
    await SupabaseClientWrapper.initialize();

    print('✅ Supabase initialized successfully!\n');

    print('🔐 Testing Authentication:');
    final isAuth = SupabaseClientWrapper.isAuthenticated;
    print('   Authenticated: $isAuth');
    print('   Current User: ${SupabaseClientWrapper.currentUser?.email ?? "None"}\n');

    print('🎉 SUCCESS! Supabase is properly configured and connected.');
    print('   You can now use Supabase in your application.\n');

    print('📝 Next Steps:');
    print('   1. Deploy the database schema from SUPABASE_SCHEMA.sql');
    print('   2. Run the app and test authentication');
    print('   3. Start using Supabase data sources instead of SQLite\n');

  } catch (e, stackTrace) {
    print('❌ ERROR: Failed to connect to Supabase');
    print('   Error: $e');
    if (kDebugMode) {
      print('   Stack trace: $stackTrace');
    }
    print('\n🔧 Troubleshooting:');
    print('   1. Check your Supabase URL and Anon Key in supabase_config.dart');
    print('   2. Verify your Supabase project is active at https://supabase.com');
    print('   3. Ensure your internet connection is working\n');
  }
}
