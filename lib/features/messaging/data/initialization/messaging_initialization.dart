import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Messaging Module Initialization
/// Handles initialization of Hive boxes and messaging infrastructure
class MessagingInitialization {
  static bool _isInitialized = false;

  /// Initialize messaging module
  /// Call this in main() before runApp()
  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ [MessagingInit] Already initialized');
      return;
    }

    try {
      debugPrint('🔵 [MessagingInit] Initializing messaging module...');

      // Initialize Hive (if not already initialized)
      await _initializeHive();

      // Open messaging boxes
      await _openMessagingBoxes();

      _isInitialized = true;
      debugPrint('✅ [MessagingInit] Messaging module initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ [MessagingInit] Initialization failed');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// Initialize Hive
  static Future<void> _initializeHive() async {
    try {
      // Check if Hive is already initialized
      if (Hive.isBoxOpen('test_box')) {
        debugPrint('   ℹ️ Hive already initialized');
        return;
      }

      // Initialize Hive Flutter
      await Hive.initFlutter();
      debugPrint('   ✅ Hive initialized');
    } catch (e) {
      // If Hive is already initialized, this will throw
      // We can safely ignore this error
      if (e.toString().contains('already initialized')) {
        debugPrint('   ℹ️ Hive already initialized');
        return;
      }
      rethrow;
    }
  }

  /// Open messaging-related Hive boxes
  static Future<void> _openMessagingBoxes() async {
    try {
      debugPrint('   🔵 Opening messaging boxes...');

      // Open messages box
      if (!Hive.isBoxOpen('messages')) {
        await Hive.openBox<Map>('messages');
        debugPrint('      ✅ Opened messages box');
      }

      // Open message queue box
      if (!Hive.isBoxOpen('message_queue')) {
        await Hive.openBox<Map>('message_queue');
        debugPrint('      ✅ Opened message_queue box');
      }

      // Open message metadata box
      if (!Hive.isBoxOpen('message_metadata')) {
        await Hive.openBox<Map>('message_metadata');
        debugPrint('      ✅ Opened message_metadata box');
      }

      debugPrint('   ✅ All messaging boxes opened');
    } catch (e) {
      debugPrint('   ❌ Failed to open messaging boxes: $e');
      rethrow;
    }
  }

  /// Close all messaging boxes
  /// Call this when app is closing or during cleanup
  static Future<void> dispose() async {
    try {
      debugPrint('🔵 [MessagingInit] Closing messaging boxes...');

      if (Hive.isBoxOpen('messages')) {
        await Hive.box<Map>('messages').close();
      }

      if (Hive.isBoxOpen('message_queue')) {
        await Hive.box<Map>('message_queue').close();
      }

      if (Hive.isBoxOpen('message_metadata')) {
        await Hive.box<Map>('message_metadata').close();
      }

      _isInitialized = false;
      debugPrint('✅ [MessagingInit] Messaging boxes closed');
    } catch (e) {
      debugPrint('❌ [MessagingInit] Failed to close boxes: $e');
    }
  }

  /// Check if messaging module is initialized
  static bool get isInitialized => _isInitialized;

  /// Reset initialization state (for testing)
  @visibleForTesting
  static void resetInitialization() {
    _isInitialized = false;
  }
}
