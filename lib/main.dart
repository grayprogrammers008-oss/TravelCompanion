import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/network/supabase_client.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/theme_access.dart';
import 'features/messaging/data/initialization/messaging_initialization.dart';

void main() async {
  // Catch any uncaught errors in the app
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('❌ Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for premium look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Hive for local storage
  try {
    await Hive.initFlutter();
    debugPrint('✅ Hive initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ Failed to initialize Hive: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue anyway - app might work with limited functionality
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

  runApp(
    // ProviderScope enables Riverpod state management
    const ProviderScope(child: TravelCrewApp()),
  );
}

class TravelCrewApp extends ConsumerWidget {
  const TravelCrewApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeData = ref.watch(currentThemeDataProvider);

    return AppThemeProvider(
      themeData: themeData,
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: themeData.toThemeData(),
        // Premium scrolling physics
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: const MaterialScrollBehavior().copyWith(
              physics: const BouncingScrollPhysics(),
              scrollbars: false,
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
