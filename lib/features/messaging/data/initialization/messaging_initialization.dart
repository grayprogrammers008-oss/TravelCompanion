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

      // Skip Hive initialization here - it's done in main.dart
      // Just open messaging boxes
      await _openMessagingBoxes();

      _isInitialized = true;
      debugPrint('✅ [MessagingInit] Messaging module initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ [MessagingInit] Initialization failed');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      // Don't rethrow - allow app to continue without messaging
      // Messaging features will be disabled but app will still work
    }
  }

  /// Open messaging-related Hive boxes
  static Future<void> _openMessagingBoxes() async {
    debugPrint('   🔵 Opening messaging boxes...');

    // Open each box with recovery on corruption
    await _openBoxSafely('messages');
    await _openBoxSafely('message_queue');
    await _openBoxSafely('message_metadata');

    debugPrint('   ✅ Messaging boxes initialization complete');
  }

  /// Safely open a Hive box with recovery on corruption
  static Future<void> _openBoxSafely(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        debugPrint('      ℹ️ $boxName box already open');
        return;
      }
      await Hive.openBox<Map>(boxName);
      debugPrint('      ✅ Opened $boxName box');
    } catch (e) {
      debugPrint('      ⚠️ Failed to open $boxName box: $e');
      // Try to delete corrupted box and recreate
      try {
        debugPrint('      🔄 Attempting to recover $boxName box...');
        await Hive.deleteBoxFromDisk(boxName);
        await Hive.openBox<Map>(boxName);
        debugPrint('      ✅ Recovered $boxName box (data was reset)');
      } catch (recoveryError) {
        debugPrint('      ❌ Could not recover $boxName box: $recoveryError');
        // Continue anyway - this box will be unavailable
      }
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
