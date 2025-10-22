import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Singleton Supabase client wrapper
class SupabaseClientWrapper {
  static bool _initialized = false;

  /// Initialize Supabase
  static Future<void> initialize() async {
    if (_initialized) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase already initialized');
      }
      return;
    }

    try {
      SupabaseConfig.validateConfig();

      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: kDebugMode ? RealtimeLogLevel.info : RealtimeLogLevel.error,
        ),
      );

      _initialized = true;
      if (kDebugMode) {
        debugPrint('✅ Supabase initialized successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Supabase initialization failed: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Get Supabase client instance
  static SupabaseClient get client {
    if (!_initialized) {
      throw Exception(
        'Supabase not initialized. Call SupabaseClientWrapper.initialize() first.',
      );
    }
    return Supabase.instance.client;
  }

  /// Get current user
  static User? get currentUser => client.auth.currentUser;

  /// Get current user ID
  static String? get currentUserId {
    final userId = currentUser?.id;
    if (kDebugMode && userId == null) {
      debugPrint('⚠️  WARNING: currentUserId is null! User might not be authenticated.');
      debugPrint('   Current session: ${client.auth.currentSession}');
    }
    return userId;
  }

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get auth state stream
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  /// Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Storage buckets
  static SupabaseStorageClient get storage => client.storage;

  /// Realtime
  static RealtimeClient get realtime => client.realtime;
}
