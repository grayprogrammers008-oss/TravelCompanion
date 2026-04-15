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
    defaultValue: 'https://uaqscrewwupellvtqlfx.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVhcXNjcmV3d3VwZWxsdnRxbGZ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzMjgxNDcsImV4cCI6MjA4OTkwNDE0N30.VsUSMq0_QG81SzjI203qCfpUjyk20ED46CwCXV8mPvg',
  );

  /// Claude API Configuration for Autopilot
  static const String claudeApiKey = String.fromEnvironment(
    'CLAUDE_API_KEY',
    defaultValue:
        'YOUR_CLAUDE_API_KEY_HERE', // Replace with your Claude API key
  );

  /// Brevo (SendinBlue) API Configuration for Email Invites
  static const String brevoApiKey = String.fromEnvironment(
    'BREVO_API_KEY',
    defaultValue: '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',
  );

  static const String brevoSenderEmail = String.fromEnvironment(
    'BREVO_SENDER_EMAIL',
    defaultValue: 'palkarfoods224@gmail.com',
  );

  static const String brevoSenderName = String.fromEnvironment(
    'BREVO_SENDER_NAME',
    defaultValue: 'TravelCompanion',
  );

  /// Validate configuration
  static void validateConfig() {
    if (supabaseUrl.contains('YOUR_SUPABASE') ||
        supabaseAnonKey.contains('YOUR_SUPABASE')) {
      if (kDebugMode) {
        debugPrint('⚠️ Warning: Supabase credentials not configured!');
        debugPrint('Please update lib/core/config/supabase_config.dart');
      }
    }

    if (brevoApiKey.contains('YOUR_BREVO')) {
      if (kDebugMode) {
        debugPrint('⚠️ Warning: Brevo API key not configured!');
        debugPrint('Email invites will not work until Brevo is configured.');
      }
    }
  }
}
