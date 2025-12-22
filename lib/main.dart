import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/network/supabase_client.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/theme_access.dart';
import 'core/theme/easy_mode_provider.dart';
import 'core/services/notification_initialization.dart';
import 'core/services/shared_location_handler.dart';
import 'features/messaging/data/initialization/messaging_initialization.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📬 [FCM] Background message received');
  debugPrint('   Message ID: ${message.messageId}');
  debugPrint('   Title: ${message.notification?.title}');
  debugPrint('   Body: ${message.notification?.body}');
  debugPrint('   Data: ${message.data}');
}

void main() async {
  // Catch any uncaught errors in the app
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('❌ Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Ensure bindings are initialized first (critical for all subsequent operations)
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('✅ WidgetsFlutterBinding initialized');
  } catch (e) {
    debugPrint('❌ Failed to initialize WidgetsFlutterBinding: $e');
    // Can't continue without bindings - this is fatal
    return;
  }

  // Initialize Firebase (skip on web - requires separate configuration)
  if (!kIsWeb) {
    try {
      // Check if Firebase is already initialized (handles hot restart in debug mode)
      try {
        Firebase.app();
        debugPrint('ℹ️ Firebase already initialized (reusing existing instance)');
      } catch (_) {
        // Not initialized yet, initialize now
        await Firebase.initializeApp();
        debugPrint('✅ Firebase initialized successfully');
      }

      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      debugPrint('✅ Background message handler registered');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize Firebase: $e');
      debugPrint('Stack trace: $stackTrace');
      // Continue anyway - push notifications will be disabled
    }
  } else {
    debugPrint('ℹ️ Firebase skipped on web (not configured)');
  }

  // Set system UI overlay style for premium look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFF8FAFC), // AppTheme.neutral50
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Hive for local storage
  try {
    // First, try to close any stale Hive instances from previous crash
    try {
      await Hive.close();
    } catch (_) {
      // Ignore - Hive might not be initialized yet
    }

    await Hive.initFlutter();
    debugPrint('✅ Hive initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ Failed to initialize Hive: $e');
    debugPrint('Stack trace: $stackTrace');
    // Try to recover by clearing Hive data
    try {
      debugPrint('🔄 Attempting Hive recovery...');
      try {
        await Hive.close();
      } catch (_) {}
      await Hive.initFlutter();
      debugPrint('✅ Hive recovered successfully');
    } catch (recoveryError) {
      debugPrint('❌ Hive recovery failed: $recoveryError');
      // Continue anyway - app might work with limited functionality
    }
  }

  // Initialize messaging module (opens Hive boxes for messages)
  try {
    await MessagingInitialization.initialize();
    debugPrint('✅ Messaging initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ Failed to initialize messaging: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue anyway - messaging features will be disabled
  }

  // Initialize Supabase Backend (online-only mode)
  try {
    await SupabaseClientWrapper.initialize();
    debugPrint('✅ Supabase initialized successfully (online-only mode)');
  } catch (e, stackTrace) {
    debugPrint('❌ Failed to initialize Supabase: $e');
    debugPrint('Stack trace: $stackTrace');
    debugPrint('⚠️  App requires internet connection to function');
    // Continue anyway - will show error screen in app
  }

  // Initialize FCM notification services
  try {
    await NotificationInitialization.initialize();
    debugPrint('✅ Notification services initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ Failed to initialize notification services: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue anyway - notifications will be disabled
  }

  // Run the app
  runApp(
    // ProviderScope enables Riverpod state management
    const ProviderScope(child: TravelCrewApp()),
  );
}

class TravelCrewApp extends ConsumerStatefulWidget {
  const TravelCrewApp({super.key});

  @override
  ConsumerState<TravelCrewApp> createState() => _TravelCrewAppState();
}

class _TravelCrewAppState extends ConsumerState<TravelCrewApp> {
  @override
  void initState() {
    super.initState();
    // Initialize shared location handler for receiving Google Maps shares
    try {
      SharedLocationHandler.initialize();
      debugPrint('✅ Shared location handler initialized');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize SharedLocationHandler: $e');
      debugPrint('Stack trace: $stackTrace');
      // Continue anyway - sharing feature will be disabled
    }
  }

  @override
  void dispose() {
    SharedLocationHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeData = ref.watch(currentThemeDataProvider);

    // Watch Easy Mode state for text scaling
    final easyModeConfig = ref.watch(easyModeConfigProvider);

    // Set context for SharedLocationHandler
    SharedLocationHandler.setContext(context);

    return AppThemeProvider(
      themeData: themeData,
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: themeData.toThemeData(),
        // Premium scrolling physics and Easy Mode text scaling
        builder: (context, child) {
          // Apply Easy Mode text scale factor
          final mediaQuery = MediaQuery.of(context);
          final scaledMediaQuery = mediaQuery.copyWith(
            textScaler: TextScaler.linear(
              mediaQuery.textScaler.scale(1.0) * easyModeConfig.textScaleFactor,
            ),
          );

          // Update context for SharedLocationHandler with the inner context
          SharedLocationHandler.setContext(context);

          return MediaQuery(
            data: scaledMediaQuery,
            child: ScrollConfiguration(
              behavior: const MaterialScrollBehavior().copyWith(
                physics: const BouncingScrollPhysics(),
                scrollbars: false,
              ),
              child: child!,
            ),
          );
        },
      ),
    );
  }
}
