import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/config/supabase_config.dart';

void main() {
  group('SupabaseConfig', () {
    test('supabaseUrl is non-empty', () {
      expect(SupabaseConfig.supabaseUrl, isNotEmpty);
    });

    test('supabaseAnonKey is non-empty', () {
      expect(SupabaseConfig.supabaseAnonKey, isNotEmpty);
    });

    test('claudeApiKey is a string (may be a placeholder)', () {
      expect(SupabaseConfig.claudeApiKey, isA<String>());
    });

    test('brevoApiKey is non-empty', () {
      expect(SupabaseConfig.brevoApiKey, isNotEmpty);
    });

    test('brevoSenderEmail is non-empty', () {
      expect(SupabaseConfig.brevoSenderEmail, isNotEmpty);
    });

    test('brevoSenderName is non-empty', () {
      expect(SupabaseConfig.brevoSenderName, isNotEmpty);
    });

    test('validateConfig completes without throwing', () {
      // Should not throw even with placeholder values
      expect(() => SupabaseConfig.validateConfig(), returnsNormally);
    });
  });
}
