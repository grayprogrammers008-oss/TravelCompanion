import 'package:flutter/foundation.dart';

/// Supabase Configuration
///
/// IMPORTANT: Before running the app, you need to:
/// 1. Create a Supabase project at https://supabase.com
/// 2. Copy your project URL and anon key from the Supabase dashboard
/// 3. Replace the placeholder values below with your actual credentials
/// 4. Alternatively, use environment variables or a config file (not committed to git)
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ckgaoxajvonazdwpsmai.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNrZ2FveGFqdm9uYXpkd3BzbWFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4NTE0OTIsImV4cCI6MjA3NTQyNzQ5Mn0.poUiysXLCNjZHHTCEOM3CgKgnna32phQXT_Ob6fx7Hg',
  );

  /// Claude API Configuration for Autopilot
  static const String claudeApiKey = String.fromEnvironment(
    'CLAUDE_API_KEY',
    defaultValue:
        'YOUR_CLAUDE_API_KEY_HERE', // Replace with your Claude API key
  );

  /// Mailgun API Configuration for Email Invites
  static const String mailgunApiKey = String.fromEnvironment(
    'MAILGUN_API_KEY',
    defaultValue: 'a90e871ea23589e2e548d10cd52a4c02-5e1ffd43-ac389ec0',
  );

  static const String mailgunDomain = String.fromEnvironment(
    'MAILGUN_DOMAIN',
    defaultValue: 'sandboxea0ac54e12f242219a426c2219f44e12.mailgun.org',
  );

  static const String mailgunFromEmail = String.fromEnvironment(
    'MAILGUN_FROM_EMAIL',
    defaultValue: 'Travel Crew <postmaster@sandboxea0ac54e12f242219a426c2219f44e12.mailgun.org>',
  );

  /// Validate configuration
  static void validateConfig() {
    if (supabaseUrl.contains('YOUR_SUPABASE') ||
        supabaseAnonKey.contains('YOUR_SUPABASE')) {
      if (kDebugMode) {
        print('⚠️ Warning: Supabase credentials not configured!');
        print('Please update lib/core/config/supabase_config.dart');
      }
    }

    if (mailgunDomain.contains('YOUR_MAILGUN')) {
      if (kDebugMode) {
        print('⚠️ Warning: Mailgun domain not configured!');
        print('Email invites will not work until Mailgun is configured.');
      }
    }
  }
}
